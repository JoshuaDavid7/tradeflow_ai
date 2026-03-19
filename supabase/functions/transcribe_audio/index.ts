import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const DEEPGRAM_API_KEY = Deno.env.get('DEEPGRAM_API_KEY')

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

Deno.serve(async (req) => {
  // 1. Handle CORS Pre-flight
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  console.log("--- TRANSCRIBE_AUDIO REQUEST RECEIVED ---");

  try {
    // 2. Safely parse the body and log exactly what was received
    const body = await req.json().catch(() => null);
    console.log("Body contents:", JSON.stringify(body));

    // Support multiple casing options for the key to be extra safe
    const filePath = body?.filePath || body?.filepath || body?.file_path;

    if (!filePath) {
      console.error("Critical Error: No filePath found in the body provided by Flutter.");
      throw new Error("Missing filePath in request body");
    }

    console.log(`Target file: ${filePath}`);

    // 3. Initialize Supabase
    const supabase = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    )

    // 4. Download audio
    const { data: fileData, error: downloadError } = await supabase.storage
      .from('job-audio')
      .download(filePath)

    if (downloadError) {
      console.error("Supabase Storage Error:", JSON.stringify(downloadError));
      throw new Error(`Storage error: ${downloadError.message}`);
    }

    console.log("File downloaded. Calling Deepgram...");

    // 5. Transcription using Nova-3
    const dgResponse = await fetch('https://api.deepgram.com/v1/listen?model=nova-3&smart_format=true', {
      method: 'POST',
      headers: {
        'Authorization': `Token ${DEEPGRAM_API_KEY}`,
        'Content-Type': 'audio/m4a',
      },
      body: fileData,
    })

    if (!dgResponse.ok) {
      const errorText = await dgResponse.text();
      console.error("Deepgram reported an error:", errorText);
      throw new Error(`Deepgram API returned ${dgResponse.status}`);
    }

    const dgResult = await dgResponse.json()
    const transcript = dgResult?.results?.channels?.[0]?.alternatives?.[0]?.transcript || "";

    if (!transcript || transcript.trim().length === 0) {
      console.warn("Deepgram processed the audio but found no speech.");
      throw new Error("Could not hear any speech. Please try speaking closer to the mic.");
    }

    console.log("Success: Transcript generated.");

    // 6. Cleanup storage
    await supabase.storage.from('job-audio').remove([filePath])

    return new Response(JSON.stringify({ transcript }), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    })

  } catch (error) {
    console.error(`Transcribe Crash: ${error.message}`);
    return new Response(JSON.stringify({ error: error.message }), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    })
  }
})