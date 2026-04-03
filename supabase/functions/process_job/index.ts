import { serve } from "https://deno.land/std@0.168.0/http/server.ts"

const GEMINI_API_KEY = Deno.env.get('GOOGLE_GEMINI_KEY')
const GEMINI_MODEL = 'gemini-3.1-flash-lite-preview'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

/**
 * Build the original extraction prompt (no invoice context — initial creation).
 */
function buildExtractionPrompt(transcript: string): string {
  return `
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

EXAMPLES:
Transcript: "invoice david for 3 hours of work, materials pipe 50 dollars, valves 50 dollars"
→ { "clientName": "David", "type": "invoice", "laborHours": 3.0, "laborType": "profile", "description": "3 hours of work - pipe and valve installation", "materials": [{"item": "Pipe", "quantity": 1, "unitPrice": 50, "cost": 50}, {"item": "Valves", "quantity": 1, "unitPrice": 50, "cost": 50}] }

Transcript: "quote for smith building, replace hot water system, 4 hours at 90 an hour, new heater 800, fittings 45"
→ { "clientName": "Smith Building", "type": "quote", "laborHours": 4.0, "laborType": "hourly", "laborRate": 90, "description": "Replace hot water system", "materials": [{"item": "New Heater", "quantity": 1, "unitPrice": 800, "cost": 800}, {"item": "Fittings", "quantity": 1, "unitPrice": 45, "cost": 45}] }

Now extract from this transcript: "${transcript}"
`;
}

/**
 * Build the context-aware refine prompt (invoice state provided — editing mode).
 * The AI sees the full current invoice and returns the complete desired state.
 */
function buildRefinePrompt(transcript: string, currentState: Record<string, unknown>): string {
  // Format current materials for readability
  const materials = (currentState.materials as Array<Record<string, unknown>>) || [];
  const materialLines = materials.length > 0
    ? materials.map((m, i) =>
        `  [${i}] ${m.item} — qty: ${m.quantity}, unit price: ${m.unitPrice}, total: ${m.cost}${m.fromReceipt ? ' (from receipt)' : ''}`
      ).join('\n')
    : '  (none)';

  // Format labor info
  let laborInfo = `${currentState.laborHours ?? 1.0} hours`;
  if (currentState.laborType === 'hourly') {
    laborInfo += ` at $${currentState.laborRate}/hr`;
  } else if (currentState.laborType === 'flat') {
    laborInfo += ` (flat rate: $${currentState.laborAmount})`;
  } else {
    laborInfo += ' (profile rate)';
  }

  return `
You are an intelligent AI assistant built into an invoicing app for tradespeople (plumbers, electricians, builders, etc.). You have FULL CONTROL over the current document.

The user is editing an existing ${currentState.type || 'invoice'} and is giving you a voice command. You must understand what they want and return the COMPLETE updated document state.

═══ CURRENT DOCUMENT STATE ═══
Client: ${currentState.clientName || '(empty)'}
Address: ${currentState.clientAddress || '(empty)'}
Phone: ${currentState.clientPhone || '(empty)'}
Email: ${currentState.clientEmail || '(empty)'}
Type: ${currentState.type || 'invoice'}
Description: ${currentState.description || '(empty)'}
Labor: ${laborInfo}
Markup: ${currentState.markupPercent ?? 0}%
Materials:
${materialLines}
═══════════════════════════════

═══ VOICE COMMAND ═══
"${transcript}"
═════════════════════

YOUR TASK: Interpret the voice command and return the COMPLETE updated document as JSON. Include ALL fields — even ones that didn't change. This is a REPLACEMENT, not a diff.

RULES:
1. Return EVERY field listed below. If the user didn't mention a field, keep its current value.
2. For materials: return the COMPLETE updated materials list. If the user said "remove the valves", return the list WITHOUT valves. If they said "add faucets", return the existing list PLUS the new item.
3. You can understand commands like:
   - "remove the valves" / "take off the second item" / "delete everything over $100"
   - "change pipes to 5" / "make the copper pipes $80 each" / "double all quantities"
   - "add a heater for $800" / "add 3 fittings at $15 each"
   - "clear all materials" / "start fresh with just labor"
   - "change the client to John" / "update the description" / "make it a quote"
   - "set labor to 4 hours at $90 an hour" / "make labor flat rate $500"
   - "add 15% markup" / "remove the markup" / "set markup to 10 percent"
   - "change the address to 123 Main St"
4. For material names: use sensible capitalization (e.g. "Copper Pipes" not "copper pipes").
5. "cost" must ALWAYS equal quantity × unitPrice. Calculate this yourself.
6. Include a "message" field — a short, natural confirmation of what you changed (shown to the user).
7. If the command is unclear, make your best interpretation and explain in "message".
8. NEVER invent data the user didn't mention and that isn't in the current state.
9. Keep materials that are marked "fromReceipt" unless the user explicitly asks to remove them.

RESPONSE FORMAT (JSON):
{
  "clientName": string,
  "clientAddress": string,
  "clientPhone": string,
  "clientEmail": string,
  "type": "invoice" | "quote",
  "description": string,
  "laborHours": number,
  "laborType": "profile" | "hourly" | "flat",
  "laborRate": number | null,
  "laborAmount": number | null,
  "markupPercent": number,
  "materials": [
    { "item": string, "quantity": number, "unitPrice": number, "cost": number }
  ],
  "message": string
}

EXAMPLES:

Voice: "remove the valves"
→ Return all current materials EXCEPT Valves. message: "Removed Valves from the materials list."

Voice: "change it to a quote and make labor 5 hours"
→ Return type: "quote", laborHours: 5.0, everything else unchanged. message: "Changed to a quote and updated labor to 5 hours."

Voice: "add a hot water system for $800 and 10% markup"
→ Return existing materials + new item, markupPercent: 10. message: "Added Hot Water System ($800) and set 10% markup."

Voice: "clear everything and start over, invoice for Sarah, 2 hours, one heater for $600"
→ Return fresh state with clientName: "Sarah", laborHours: 2.0, materials: [{item: "Heater", ...}]. message: "Started fresh. Invoice for Sarah — 2 hours labor, one heater at $600."

Now process the voice command above and return the updated document.
`;
}

serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders })

  try {
    const { transcript, currentState } = await req.json()

    if (!transcript || transcript.trim().length === 0) {
      throw new Error('Empty transcript received')
    }

    // Choose prompt based on whether we have current invoice context
    const isRefineMode = currentState != null && typeof currentState === 'object';
    const systemPrompt = isRefineMode
      ? buildRefinePrompt(transcript, currentState)
      : buildExtractionPrompt(transcript);

    console.log(`Processing transcript (${transcript.length} chars, mode: ${isRefineMode ? 'refine' : 'extract'})`);

    // Call Gemini with 25s timeout (refine may need more time)
    const controller = new AbortController()
    const timeout = setTimeout(() => controller.abort(), 25000)
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
      if (e.name === 'AbortError') throw new Error('Gemini API timed out after 25s')
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
