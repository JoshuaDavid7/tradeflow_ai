import { serve } from "https://deno.land/std@0.168.0/http/server.ts"

const GEMINI_API_KEY = Deno.env.get('GOOGLE_GEMINI_KEY')
const GEMINI_MODEL = 'gemini-3.1-flash-lite-preview'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

function parseJsonObjectResponse(raw: string): Record<string, unknown> {
  let text = raw.trim()

  if (text.startsWith('```')) {
    text = text
      .replace(/^```(?:json)?\s*/i, '')
      .replace(/\s*```$/, '')
      .trim()
  }

  if (!text.startsWith('{')) {
    const start = text.indexOf('{')
    const end = text.lastIndexOf('}')
    if (start >= 0 && end > start) {
      text = text.slice(start, end + 1).trim()
    }
  }

  const parsed = JSON.parse(text)
  if (!parsed || typeof parsed !== 'object' || Array.isArray(parsed)) {
    throw new Error('AI did not return a JSON object')
  }

  return parsed as Record<string, unknown>
}

function toTitleCase(value: string): string {
  return value
    .split(/\s+/)
    .filter(Boolean)
    .map((part) => part.charAt(0).toUpperCase() + part.slice(1).toLowerCase())
    .join(' ')
}

function normalizeText(value: string): string {
  return value
    .trim()
    .toLowerCase()
    .replace(/&/g, ' and ')
    .replace(/[^a-z0-9\s]/g, ' ')
    .replace(/\s+/g, ' ')
    .trim()
}

function levenshteinDistance(a: string, b: string): number {
  if (a === b) return 0
  if (!a) return b.length
  if (!b) return a.length

  const costs = Array.from({ length: b.length + 1 }, (_, i) => i)
  for (let i = 1; i <= a.length; i += 1) {
    let previous = costs[0]
    costs[0] = i
    for (let j = 1; j <= b.length; j += 1) {
      const current = costs[j]
      const substitutionCost = a[i - 1] === b[j - 1] ? 0 : 1
      costs[j] = Math.min(costs[j] + 1, costs[j - 1] + 1, previous + substitutionCost)
      previous = current
    }
  }
  return costs[b.length]
}

function bestMatchingCustomerName(
  candidate: unknown,
  knownCustomers: string[]
): string | null {
  const raw = String(candidate ?? '').trim()
  const query = normalizeText(raw)
  if (!query || knownCustomers.length === 0) {
    return raw || null
  }

  let bestName: string | null = null
  let bestScore = Number.POSITIVE_INFINITY

  for (const customer of knownCustomers) {
    const normalizedCustomer = normalizeText(customer)
    if (!normalizedCustomer) continue

    let score = Number.POSITIVE_INFINITY
    if (normalizedCustomer === query) {
      score = 0
    } else if (
      normalizedCustomer.includes(query) ||
      query.includes(normalizedCustomer)
    ) {
      score = 1
    } else {
      const distance = levenshteinDistance(normalizedCustomer, query)
      const maxLength = Math.max(normalizedCustomer.length, query.length)
      if (distance <= 2 || distance <= Math.round(maxLength / 4)) {
        score = 2 + distance
      }
    }

    if (score < bestScore) {
      bestScore = score
      bestName = customer
    }
  }

  return bestScore <= 4 ? bestName : raw || null
}

function isUnknownClientName(value: unknown): boolean {
  const normalized = normalizeText(String(value ?? ''))
  return !normalized || normalized === 'unknown'
}

function repairTranscriptForAsr(transcript: string): string {
  return transcript
    .replace(/^\s*phil\b/gi, 'bill')
    .replace(/\bone peter\b/gi, 'one heater')
}

function cleanClientNameCandidate(candidate: string): string | null {
  const stopTokens = new Set([
    'to',
    'for',
    'replace',
    'replacing',
    'flat',
    'just',
    'my',
    'one',
    'two',
    'three',
    'four',
    'five',
    'six',
    'seven',
    'eight',
    'nine',
    'ten',
    'hour',
    'hours',
    'labor',
    'plus',
    'and',
    'emergency',
    'call',
    'callout',
    'only',
    'no',
    'materials',
    'material',
    'faucet',
    'heater',
    'mixer',
    'tap',
    'tile',
    'tiles',
    'adhesive',
    'at',
    'of',
    'from',
  ])

  const parts = candidate
    .split(/\s+/)
    .map((part) => part.trim())
    .filter(Boolean)

  const kept: string[] = []
  for (const part of parts) {
    const normalizedPart = normalizeText(part)
    if (kept.length > 0 && stopTokens.has(normalizedPart)) {
      break
    }
    kept.push(part)
    if (kept.length >= 5) {
      break
    }
  }

  if (kept.length === 0) {
    return null
  }

  return toTitleCase(kept.join(' '))
}

function extractClientNameHintFromTranscript(transcript: string): string | null {
  const patterns = [
    /\b(?:invoice|quote|estimate|bill)\s+for\s+([a-z0-9][a-z0-9\s&'-]+?)(?=\s+(?:to|replace|replacing|flat|just|my|one|two|three|four|five|six|seven|eight|nine|ten|\d|hour|hours|labor|plus|and)\b|$)/i,
    /\b([a-z0-9][a-z0-9\s&'-]+?)\s+(?:invoice|quote|estimate|bill)\b(?=\s+(?:for|to|replace|replacing|flat|just|my|one|two|three|four|five|six|seven|eight|nine|ten|\d|hour|hours|labor|plus|and)\b|$)/i,
    /\b(?:invoice|quote|estimate|bill)\s+([a-z0-9][a-z0-9\s&'-]+?)(?=\s+(?:for|to|replace|replacing|flat|just|my|one|two|three|four|five|six|seven|eight|nine|ten|\d|hour|hours|labor|plus|and)\b|$)/i,
    /\bfor\s+([a-z0-9][a-z0-9\s&'-]+?)(?=\s+(?:to|replace|replacing|flat|just|my|one|two|three|four|five|six|seven|eight|nine|ten|\d|hour|hours|labor|plus|and)\b|$)/i,
  ]

  for (const pattern of patterns) {
    const match = transcript.match(pattern)
    const candidate = match?.[1]?.trim()
    if (candidate) {
      return cleanClientNameCandidate(candidate)
    }
  }

  return null
}

function normalizeLikelyMaterialName(name: unknown, transcript: string): string {
  const raw = String(name ?? '').trim()
  if (!raw) return raw

  const normalized = normalizeText(raw)
  const transcriptLower = normalizeText(transcript)

  const fittingsAliases = new Set([
    'filling',
    'fillings',
    'fizzing',
    'fizzings',
    'quidding',
    'quiddings',
  ])
  if (fittingsAliases.has(normalized)) {
    return 'Fittings'
  }

  const heaterAliases = new Set([
    'keter',
    'keater',
    'heeter',
    'heater',
    'heaters',
  ])
  if (heaterAliases.has(normalized)) {
    return normalized.endsWith('s') ? 'Heaters' : 'Heater'
  }

  if (
    normalized === 'people' &&
    (transcriptLower.includes('hot water system') ||
      transcriptLower.includes('water heater'))
  ) {
    return 'Heater'
  }

  const hoseAliases = new Set([
    'owe',
    'owes',
    'ows',
    'o s',
    'os',
    'owes fittings',
    'o rings',
    'orings',
  ])
  if (
    (hoseAliases.has(normalized) || normalized.startsWith('owe')) &&
    (transcriptLower.includes('mixer tap') ||
      transcriptLower.includes('tap'))
  ) {
    return 'Hose'
  }

  if (
    (normalized === 'piece' || normalized === 'pieces') &&
    transcriptLower.includes('tile')
  ) {
    return 'Adhesive'
  }

  return toTitleCase(raw)
}

function normalizeParsedJobResult(
  parsed: Record<string, unknown>,
  transcript: string,
  knownCustomers: string[]
): Record<string, unknown> {
  const normalized = { ...parsed }
  const materials = Array.isArray(parsed.materials) ? parsed.materials : []
  const transcriptClientHint = extractClientNameHintFromTranscript(transcript)

  normalized.materials = materials.map((item) => {
    if (!item || typeof item !== 'object' || Array.isArray(item)) {
      return item
    }

    const material = item as Record<string, unknown>
    const quantity = Number(material.quantity ?? 1)
    const unitPrice = Number(material.unitPrice ?? 0)
    const safeQuantity = Number.isFinite(quantity) && quantity > 0 ? quantity : 1
    const safeUnitPrice = Number.isFinite(unitPrice) ? unitPrice : 0

    return {
      ...material,
      item: normalizeLikelyMaterialName(material.item, transcript),
      quantity: safeQuantity,
      unitPrice: safeUnitPrice,
      cost: Number((safeQuantity * safeUnitPrice).toFixed(2)),
    }
  })

  if (transcriptClientHint) {
    normalized.clientName =
      bestMatchingCustomerName(transcriptClientHint, knownCustomers) ??
      transcriptClientHint
  } else if (typeof parsed.clientName === 'string' && !isUnknownClientName(parsed.clientName)) {
    normalized.clientName =
      bestMatchingCustomerName(parsed.clientName, knownCustomers) ??
      parsed.clientName.trim()
  }

  return normalized
}

/**
 * Build the original extraction prompt (no invoice context — initial creation).
 */
function buildExtractionPrompt(transcript: string, knownCustomers: string[]): string {
  const likelyClient = extractClientNameHintFromTranscript(transcript)

  return `
You are an AI assistant for tradespeople (plumbers, electricians, builders, etc.) that extracts job details from spoken transcripts.

Extract ALL details from the transcript into a JSON object. Be thorough — do not miss anything mentioned.

KNOWN CUSTOMERS:
${knownCustomers.length > 0 ? knownCustomers.join(', ') : '(none provided)'}

LIKELY CLIENT FROM TRANSCRIPT:
${likelyClient ?? '(none confidently inferred)'}

RULES:
0. The transcript came from speech recognition and may contain phonetic mistakes. Repair obvious ASR errors before extracting fields when the trade context makes the correction clear. Examples: "keter" can mean "heater", "fillings/fizzings/quiddings" can mean "fittings", and "owes/o's/o-rings" near a mixer tap can mean "hose". Spoken phrases like "2 hours and 85" can mean "2 hours at $85 an hour" if the rate wording was partially lost.
1. "clientName": The person or company being billed. Look for phrases like "invoice [name]", "for [name]", "client is [name]", "bill [name]". If unclear, use "Unknown".
   - If the spoken name is close to one of the known customers above, prefer the exact existing customer name.
   - If a likely client is shown above and it fits the transcript, use it instead of "Unknown".
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
function buildRefinePrompt(
  transcript: string,
  currentState: Record<string, unknown>,
  knownCustomers: string[]
): string {
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

KNOWN CUSTOMERS:
${knownCustomers.length > 0 ? knownCustomers.join(', ') : '(none provided)'}

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
10. The transcript may contain speech-to-text mistakes. Correct obvious phonetic errors for names, materials, and trade terms when the surrounding context makes the intended meaning clear.
11. If a client name sounds close to one of the known customers above, prefer the exact existing customer name.

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
    const { transcript, currentState, knownCustomers } = await req.json()

    if (!transcript || transcript.trim().length === 0) {
      throw new Error('Empty transcript received')
    }
    const repairedTranscript = repairTranscriptForAsr(transcript)

    const customerHints = Array.isArray(knownCustomers)
      ? knownCustomers.filter((item): item is string => typeof item === 'string')
      : []

    // Choose prompt based on whether we have current invoice context
    const isRefineMode = currentState != null && typeof currentState === 'object';
    const systemPrompt = isRefineMode
      ? buildRefinePrompt(repairedTranscript, currentState, customerHints)
      : buildExtractionPrompt(repairedTranscript, customerHints);

    console.log(`Processing transcript (${repairedTranscript.length} chars, mode: ${isRefineMode ? 'refine' : 'extract'})`);

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
    const parsed = normalizeParsedJobResult(
      parseJsonObjectResponse(extractedText),
      repairedTranscript,
      customerHints
    )
    console.log('Extraction successful')

    return new Response(JSON.stringify(parsed), {
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
