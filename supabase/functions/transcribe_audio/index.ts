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
    const body = await req.json().catch(() => null)
    const filePath = body?.filePath || body?.filepath || body?.file_path

    if (!filePath) {
      throw new Error('Missing filePath in request body')
    }

    const supabase = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    )

    // Download the audio file from storage
    const { data: fileData, error: downloadError } = await supabase.storage
      .from('job-audio')
      .download(filePath)

    if (downloadError) {
      throw new Error(`Storage download failed: ${downloadError.message}`)
    }

    const arrayBuf = await fileData.arrayBuffer()
    const bytes = new Uint8Array(arrayBuf)

    if (bytes.length < 100) {
      throw new Error(`Audio file too small (${bytes.length} bytes). Recording may have failed.`)
    }

    // Detect audio format from header
    const headerStr = new TextDecoder().decode(bytes.slice(0, 32))
    const isM4A = headerStr.includes('ftyp')
    const contentType = isM4A ? 'audio/mp4' : 'audio/wav'

    // Send to Deepgram Nova-3 via raw binary POST (with 25s timeout)
    const dgController = new AbortController()
    const dgTimeout = setTimeout(() => dgController.abort(), 25000)
    let dgResponse: Response
    try {
      dgResponse = await fetch(
        'https://api.deepgram.com/v1/listen?model=nova-3&smart_format=true&detect_language=true',
        {
          method: 'POST',
          headers: {
            'Authorization': `Token ${DEEPGRAM_API_KEY}`,
            'Content-Type': contentType,
          },
          body: arrayBuf,
          signal: dgController.signal,
        }
      )
    } catch (e) {
      if (e.name === 'AbortError') throw new Error('Deepgram API timed out after 25s')
      throw e
    } finally {
      clearTimeout(dgTimeout)
    }

    if (!dgResponse.ok) {
      const errorText = await dgResponse.text()
      throw new Error(`Deepgram API returned ${dgResponse.status}: ${errorText}`)
    }

    const dgResult = await dgResponse.json()
    const transcript = dgResult?.results?.channels?.[0]?.alternatives?.[0]?.transcript || ''

    if (!transcript || transcript.trim().length === 0) {
      throw new Error('No speech detected. Please speak closer to the mic.')
    }

    // Cleanup storage
    await supabase.storage.from('job-audio').remove([filePath])

    return new Response(JSON.stringify({ transcript }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })

  } catch (error) {
    return new Response(JSON.stringify({ error: error.message }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  }
})
