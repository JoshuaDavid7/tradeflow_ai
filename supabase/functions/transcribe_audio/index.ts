import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const DEEPGRAM_API_KEY = Deno.env.get('DEEPGRAM_API_KEY')
const PRIMARY_TIMEOUT_MS = 20000
const FALLBACK_TIMEOUT_MS = 10000

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

async function callDeepgram(
  arrayBuf: ArrayBuffer,
  contentType: string,
  query: string,
  timeoutMs: number
): Promise<Response> {
  const controller = new AbortController()
  const timeout = setTimeout(() => controller.abort(), timeoutMs)

  try {
    return await fetch(`https://api.deepgram.com/v1/listen?${query}`, {
      method: 'POST',
      headers: {
        'Authorization': `Token ${DEEPGRAM_API_KEY}`,
        'Content-Type': contentType,
      },
      body: arrayBuf,
      signal: controller.signal,
    })
  } catch (error) {
    if (error.name === 'AbortError') {
      throw new Error(`Deepgram API timed out after ${Math.round(timeoutMs / 1000)}s`)
    }
    throw error
  } finally {
    clearTimeout(timeout)
  }
}

async function parseDeepgramResult(
  response: Response
): Promise<{ transcript: string; detectedLanguage: string | null }> {
  if (!response.ok) {
    const errorText = await response.text()
    throw new Error(`Deepgram API returned ${response.status}: ${errorText}`)
  }

  const result = await response.json()
  return {
    transcript: result?.results?.channels?.[0]?.alternatives?.[0]?.transcript || '',
    detectedLanguage: result?.results?.channels?.[0]?.detected_language ?? null,
  }
}

async function requestDeepgramTranscript(
  arrayBuf: ArrayBuffer,
  contentType: string,
  query: string,
  timeoutMs: number
): Promise<{ transcript: string; detectedLanguage: string | null }> {
  let lastError: Error | null = null

  for (let attempt = 1; attempt <= 2; attempt += 1) {
    try {
      return await parseDeepgramResult(
        await callDeepgram(arrayBuf, contentType, query, timeoutMs)
      )
    } catch (error) {
      lastError = error instanceof Error ? error : new Error(String(error))
      if (attempt >= 2) {
        throw lastError
      }
      console.warn(
        `Deepgram request failed (attempt ${attempt}/2, query="${query}"): ${lastError.message}`
      )
      await new Promise((resolve) => setTimeout(resolve, 250))
    }
  }

  throw lastError ?? new Error('Unknown Deepgram request failure')
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

    // This app is currently optimized for English-speaking users, and short
    // commands were being misdetected as other languages before we ever hit the
    // fallback path. Prefer explicit English first, then fall back to language
    // detection if English comes back empty.
    let primaryResult = await requestDeepgramTranscript(
      arrayBuf,
      contentType,
      'model=nova-3&smart_format=false&language=en',
      PRIMARY_TIMEOUT_MS
    )
    let transcript = primaryResult.transcript

    let usedEnglishFallback = false
    if (!transcript || transcript.trim().length === 0) {
      console.warn(
        `Deepgram returned empty English transcript for ${filePath}; retrying with detect_language`
      )
      const fallbackResult = await requestDeepgramTranscript(
        arrayBuf,
        contentType,
        'model=nova-3&smart_format=false&detect_language=true',
        FALLBACK_TIMEOUT_MS
      )
      transcript = fallbackResult.transcript
      usedEnglishFallback = !!fallbackResult.detectedLanguage
    }

    if (!transcript || transcript.trim().length === 0) {
      throw new Error('No speech detected. Please speak closer to the mic.')
    }

    // Cleanup storage
    await supabase.storage.from('job-audio').remove([filePath])

    return new Response(JSON.stringify({ transcript, usedEnglishFallback }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })

  } catch (error) {
    return new Response(JSON.stringify({ error: error.message }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  }
})
