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
6. "materials": Extract EVERY material, part, or item mentioned with its cost. Look for patterns like "[item] [price]", "[item] costs [price]", "[price] for [item]". If a cost isn't mentioned for an item, set cost to 0.

EXAMPLES:
Transcript: "invoice david for 3 hours of work, materials pipe 50 dollars, valves 50 dollars"
→ { "clientName": "David", "type": "invoice", "laborHours": 3.0, "laborType": "profile", "description": "3 hours of work - pipe and valve installation", "materials": [{"item": "Pipe", "cost": 50}, {"item": "Valves", "cost": 50}] }

Transcript: "quote for smith building, replace hot water system, 4 hours at 90 an hour, new heater 800, fittings 45"
→ { "clientName": "Smith Building", "type": "quote", "laborHours": 4.0, "laborType": "hourly", "laborRate": 90, "description": "Replace hot water system", "materials": [{"item": "New Heater", "cost": 800}, {"item": "Fittings", "cost": 45}] }

Now extract from this transcript: "${transcript}"
`;

    const response = await fetch(`https://generativelanguage.googleapis.com/v1beta/models/${GEMINI_MODEL}:generateContent?key=${GEMINI_API_KEY}`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        contents: [{ parts: [{ text: systemPrompt }] }],
        generationConfig: { responseMimeType: "application/json" }
      })
    })

    const result = await response.json()
    return new Response(result.candidates[0].content.parts[0].text, {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    })
  } catch (error) {
    return new Response(JSON.stringify({ error: error.message }), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    })
  }
})
