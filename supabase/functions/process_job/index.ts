import { serve } from "https://deno.land/std@0.168.0/http/server.ts"

const GEMINI_API_KEY = Deno.env.get('GOOGLE_GEMINI_KEY')
const GEMINI_MODEL = 'gemini-3.1-flash-lite-preview'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders })

  try {
    const { transcript } = await req.json()

    if (!transcript || transcript.trim().length === 0) {
      throw new Error('Empty transcript received')
    }

    const systemPrompt = `
You are an AI assistant for tradespeople (plumbers, electricians, builders, etc.) that extracts job details from spoken transcripts.

Extract ALL details from the transcript into a JSON object. Be thorough — do not miss anything mentioned.

RULES:
1. "clientName": The person or company being billed. Look for phrases like "invoice [name]", "for [name]", "client is [name]", "bill [name]". If unclear, use "Unknown".
2. "type": If they say "invoice" → "invoice". If they say "quote" or "estimate" → "quote". Default to "invoice".
3. "description": A clear summary of the work being done based on everything mentioned.
4. "laborHours": Total hours of work mentioned (e.g. "3 hours" → 3.0). Default to 1.0 if not mentioned.
5. "laborType" and rates:
   - If they mention an hourly rate (e.g. "at $80 an hour", "charge 50 per hour") → "laborType": "hourly", "laborRate": <number>
   - If they mention a flat labor amount (e.g. "labor is $400", "$200 for my time") → "laborType": "flat", "laborAmount": <number>
   - Otherwise → "laborType": "profile"
6. "materials": Extract EVERY material, part, or item mentioned with quantity and unit price.
   - Each item: { "item": string, "quantity": number, "unitPrice": number, "cost": number }
   - "quantity": How many (e.g. "3 pipes" → 3). Default to 1 if not mentioned.
   - "unitPrice": Price per single unit. If they say "3 pipes for 60" → unitPrice = 20, cost = 60.
   - "cost": Total = quantity × unitPrice. Always include this.
   - If a cost isn't mentioned for an item, set unitPrice and cost to 0.
7. "edits": If the transcript is clearly an EDIT command (e.g. "change pipes to 80", "remove the valves", "update quantity of pipes to 5", "make it 4 pipes instead"), extract edits instead of new items:
   - "edits": array of edit operations
   - Each edit: { "action": "update" | "remove", "item": string (name to match, case-insensitive), "quantity": number (optional), "unitPrice": number (optional), "cost": number (optional) }
   - For "remove": just { "action": "remove", "item": "Valves" }
   - For "update": include only the fields being changed, e.g. { "action": "update", "item": "Pipes", "unitPrice": 80 } or { "action": "update", "item": "Pipes", "quantity": 4 }
   - If BOTH new materials AND edits are mentioned, include both "materials" and "edits".

EXAMPLES:
Transcript: "invoice david for 3 hours of work, materials pipe 50 dollars, valves 50 dollars"
→ { "clientName": "David", "type": "invoice", "laborHours": 3.0, "laborType": "profile", "description": "3 hours of work - pipe and valve installation", "materials": [{"item": "Pipe", "quantity": 1, "unitPrice": 50, "cost": 50}, {"item": "Valves", "quantity": 1, "unitPrice": 50, "cost": 50}] }

Transcript: "invoice me for 3 pipes for 60 dollars"
→ { "clientName": "Unknown", "type": "invoice", "laborHours": 1.0, "laborType": "profile", "description": "Pipe supply", "materials": [{"item": "Pipes", "quantity": 3, "unitPrice": 20, "cost": 60}] }

Transcript: "quote for smith building, replace hot water system, 4 hours at 90 an hour, new heater 800, fittings 45"
→ { "clientName": "Smith Building", "type": "quote", "laborHours": 4.0, "laborType": "hourly", "laborRate": 90, "description": "Replace hot water system", "materials": [{"item": "New Heater", "quantity": 1, "unitPrice": 800, "cost": 800}, {"item": "Fittings", "quantity": 1, "unitPrice": 45, "cost": 45}] }

Transcript: "change the pipes to 80 dollars and remove the valves"
→ { "edits": [{"action": "update", "item": "Pipes", "unitPrice": 80}, {"action": "remove", "item": "Valves"}] }

Transcript: "make it 5 pipes instead"
→ { "edits": [{"action": "update", "item": "Pipes", "quantity": 5}] }

Transcript: "add 2 faucets for 120 and change labor to 4 hours"
→ { "laborHours": 4.0, "materials": [{"item": "Faucets", "quantity": 2, "unitPrice": 60, "cost": 120}] }

Now extract from this transcript: "${transcript}"
`;

    console.log(`Processing transcript (${transcript.length} chars)`);

    // Call Gemini with 20s timeout
    const controller = new AbortController()
    const timeout = setTimeout(() => controller.abort(), 20000)
    let response: Response
    try {
      response = await fetch(`https://generativelanguage.googleapis.com/v1beta/models/${GEMINI_MODEL}:generateContent?key=${GEMINI_API_KEY}`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          contents: [{ parts: [{ text: systemPrompt }] }],
          generationConfig: { responseMimeType: "application/json" }
        }),
        signal: controller.signal,
      })
    } catch (e) {
      if (e.name === 'AbortError') throw new Error('Gemini API timed out after 20s')
      throw e
    } finally {
      clearTimeout(timeout)
    }

    if (!response.ok) {
      const errorText = await response.text()
      console.error(`Gemini API error (${response.status}):`, errorText)
      throw new Error(`Gemini API returned ${response.status}: ${errorText}`)
    }

    const result = await response.json()

    // Validate response structure
    if (!result?.candidates?.[0]?.content?.parts?.[0]?.text) {
      console.error('Unexpected Gemini response:', JSON.stringify(result))
      throw new Error('Gemini returned an unexpected response format')
    }

    const extractedText = result.candidates[0].content.parts[0].text
    console.log('Extraction successful')

    return new Response(extractedText, {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    })
  } catch (error) {
    console.error(`process_job error: ${error.message}`)
    return new Response(JSON.stringify({ error: error.message }), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    })
  }
})
