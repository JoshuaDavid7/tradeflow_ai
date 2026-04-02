import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const DEEPGRAM_API_KEY = Deno.env.get('DEEPGRAM_API_KEY')

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const supabase = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    )

    const results: Record<string, unknown> = {}

    // Test 1: List files in job-audio bucket to see what's there
    const { data: files, error: listError } = await supabase.storage
      .from('job-audio')
      .list('ios', { limit: 5, sortBy: { column: 'created_at', order: 'desc' } })

    results.iosFiles = files?.map(f => ({ name: f.name, size: f.metadata?.size, created: f.created_at })) || []
    results.listError = listError?.message

    // Also check android folder
    const { data: androidFiles } = await supabase.storage
      .from('job-audio')
      .list('android', { limit: 5, sortBy: { column: 'created_at', order: 'desc' } })
    results.androidFiles = androidFiles?.map(f => ({ name: f.name, size: f.metadata?.size, created: f.created_at })) || []

    // Test 2: Download a known audio from the web and send to Deepgram via raw binary
    const audioUrl = 'https://dpgr.am/spacewalk.wav'
    const audioResp = await fetch(audioUrl)
    const audioBlob = await audioResp.arrayBuffer()
    results.downloadedSize = audioBlob.byteLength

    // Upload this file to storage
    const testPath = 'test/deepgram_test.wav'
    const { error: uploadError } = await supabase.storage
      .from('job-audio')
      .upload(testPath, audioBlob, { contentType: 'audio/wav', upsert: true })
    results.uploadError = uploadError?.message

    // Download it back
    const { data: dlData, error: dlError } = await supabase.storage
      .from('job-audio')
      .download(testPath)
    results.downloadError = dlError?.message

    if (dlData) {
      const dlBuf = await dlData.arrayBuffer()
      results.redownloadedSize = dlBuf.byteLength
      results.sizesMatch = dlBuf.byteLength === audioBlob.byteLength

      // Send redownloaded data to Deepgram (raw binary)
      const dgResp = await fetch(
        'https://api.deepgram.com/v1/listen?model=nova-3&smart_format=true',
        {
          method: 'POST',
          headers: {
            'Authorization': `Token ${DEEPGRAM_API_KEY}`,
            'Content-Type': 'audio/wav',
          },
          body: dlBuf,
        }
      )
      results.dgRawStatus = dgResp.status
      if (dgResp.ok) {
        const dgData = await dgResp.json()
        results.dgRawTranscript = (dgData?.results?.channels?.[0]?.alternatives?.[0]?.transcript || '').substring(0, 150)
      } else {
        results.dgRawError = await dgResp.text()
      }

      // Also test via signed URL
      const { data: signedData, error: signError } = await supabase.storage
        .from('job-audio')
        .createSignedUrl(testPath, 300)
      results.signError = signError?.message

      if (signedData?.signedUrl) {
        results.signedUrl = signedData.signedUrl.substring(0, 80) + '...'

        const dgUrlResp = await fetch(
          'https://api.deepgram.com/v1/listen?model=nova-3&smart_format=true',
          {
            method: 'POST',
            headers: {
              'Authorization': `Token ${DEEPGRAM_API_KEY}`,
              'Content-Type': 'application/json',
            },
            body: JSON.stringify({ url: signedData.signedUrl }),
          }
        )
        results.dgUrlStatus = dgUrlResp.status
        if (dgUrlResp.ok) {
          const dgUrlData = await dgUrlResp.json()
          results.dgUrlTranscript = (dgUrlData?.results?.channels?.[0]?.alternatives?.[0]?.transcript || '').substring(0, 150)
        } else {
          results.dgUrlError = await dgUrlResp.text()
        }
      }
    }

    // Cleanup
    await supabase.storage.from('job-audio').remove([testPath])

    return new Response(JSON.stringify(results, null, 2), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    })
  } catch (error) {
    return new Response(JSON.stringify({ error: error.message }), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    })
  }
})
