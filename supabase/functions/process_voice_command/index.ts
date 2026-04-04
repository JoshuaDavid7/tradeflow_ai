import { serve } from "https://deno.land/std@0.168.0/http/server.ts"

const GEMINI_API_KEY = Deno.env.get('GOOGLE_GEMINI_KEY')
const GEMINI_MODEL = 'gemini-3.1-flash-lite-preview'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

const defaultTaxDeductibleByCategory: Record<string, boolean> = {
  materials: true,
  labor: true,
  fuel: true,
  tools: true,
  supplies: true,
  insurance: true,
  utilities: true,
  marketing: true,
  fees: true,
  meals: false,
  other: true,
}
const allowedExpenseCategories = new Set(Object.keys(defaultTaxDeductibleByCategory))

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

function bestMatchingName(
  candidate: unknown,
  knownNames: string[]
): string | null {
  const raw = String(candidate ?? '').trim()
  const query = normalizeText(raw)
  if (!query || knownNames.length === 0) {
    return raw || null
  }

  let bestName: string | null = null
  let bestScore = Number.POSITIVE_INFINITY

  for (const name of knownNames) {
    const normalizedName = normalizeText(name)
    if (!normalizedName) continue

    let score = Number.POSITIVE_INFINITY
    if (normalizedName === query) {
      score = 0
    } else if (
      normalizedName.includes(query) ||
      query.includes(normalizedName)
    ) {
      score = 1
    } else {
      const distance = levenshteinDistance(normalizedName, query)
      const maxLength = Math.max(normalizedName.length, query.length)
      if (distance <= 2 || distance <= Math.round(maxLength / 4)) {
        score = 2 + distance
      } else {
        const queryTokens = query.split(' ').filter(Boolean)
        const candidateTokens = normalizedName.split(' ').filter(Boolean)
        let matchedTokens = 0
        let tokenDistance = 0

        for (const queryToken of queryTokens) {
          let bestTokenDistance = Number.POSITIVE_INFINITY
          for (const candidateToken of candidateTokens) {
            const candidateDistance = levenshteinDistance(candidateToken, queryToken)
            if (candidateDistance < bestTokenDistance) {
              bestTokenDistance = candidateDistance
            }
          }

          if (
            Number.isFinite(bestTokenDistance) &&
            bestTokenDistance <= Math.max(2, Math.round(queryToken.length / 3))
          ) {
            matchedTokens += 1
            tokenDistance += bestTokenDistance
          }
        }

        if (matchedTokens > 0) {
          score = 3 + tokenDistance + Math.max(0, queryTokens.length - matchedTokens)
        }
      }
    }

    if (score < bestScore) {
      bestScore = score
      bestName = name
    }
  }

  return bestScore <= 4 ? bestName : raw || null
}

function toTitleCase(value: string): string {
  return value
    .split(/\s+/)
    .filter(Boolean)
    .map((part) => part.charAt(0).toUpperCase() + part.slice(1).toLowerCase())
    .join(' ')
}

function normalizeLikelyMaterialName(name: unknown): string {
  const raw = String(name ?? '').trim()
  if (!raw) return raw

  const normalized = normalizeText(raw)
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

  const heaterAliases = new Set(['keter', 'keater', 'heeter', 'heater', 'heaters'])
  if (heaterAliases.has(normalized)) {
    return normalized.endsWith('s') ? 'Heaters' : 'Heater'
  }

  return toTitleCase(raw)
}

function normalizeLikelyVendorName(vendor: unknown, transcript: string): string {
  const raw = String(vendor ?? '').trim()
  const combined = normalizeText(`${raw} ${transcript}`)

  if (
    combined.includes('bunnings') ||
    combined.includes('bunnin') ||
    combined.includes('pennies')
  ) {
    return 'Bunnings'
  }

  if (
    combined.includes('home depot') ||
    combined.includes('home de pot') ||
    combined.includes('home deepo') ||
    combined.includes('ohm level') ||
    combined.includes('ohm liver')
  ) {
    return 'Home Depot'
  }

  if (!raw || normalizeText(raw) === 'unknown') {
    return 'Unknown'
  }

  return toTitleCase(raw)
}

function normalizeExpenseCategory(
  category: unknown,
  vendor: string,
  description: unknown,
  transcript: string,
  linkToJob: boolean
): string {
  const rawCategory = normalizeText(String(category ?? ''))
  const normalizedDescription = normalizeText(String(description ?? ''))
  const combined = normalizeText(`${rawCategory} ${vendor} ${description ?? ''} ${transcript}`)

  const hasAny = (needles: string[]) => needles.some((needle) => combined.includes(needle))

  if (hasAny(['meal', 'lunch', 'breakfast', 'dinner', 'coffee'])) return 'meals'
  if (hasAny(['fuel', 'gas station', 'diesel', 'petrol', 'gas '])) return 'fuel'
  if (hasAny(['insurance', 'premium'])) return 'insurance'
  if (hasAny(['utility', 'utilities', 'power bill', 'electric bill', 'water bill'])) return 'utilities'
  if (hasAny(['marketing', 'advertising', 'facebook ad', 'google ad'])) return 'marketing'
  if (hasAny(['fee', 'fees', 'permit fee', 'bank fee'])) return 'fees'
  if (hasAny(['labor', 'wage', 'helper', 'subcontractor'])) return 'labor'
  if (hasAny(['supply', 'supplies', 'cleaner', 'consumable'])) return 'supplies'
  if (hasAny(['drill', 'saw', 'ladder', 'wrench', 'hammer', 'meter', 'tool', 'blade', 'driver'])) {
    return 'tools'
  }
  if (hasAny(['pipe', 'fitting', 'fittings', 'heater', 'valve', 'wire', 'romex', 'lumber', 'material'])) {
    return 'materials'
  }

  if (allowedExpenseCategories.has(rawCategory)) {
    if (
      ['tools', 'supplies', 'other'].includes(rawCategory) &&
      linkToJob &&
      (vendor === 'Home Depot' || vendor === 'Bunnings') &&
      !hasAny(['drill', 'saw', 'ladder', 'wrench', 'hammer', 'meter', 'tool', 'blade', 'driver'])
    ) {
      return 'materials'
    }
    return rawCategory
  }

  if (linkToJob && (vendor === 'Home Depot' || vendor === 'Bunnings')) {
    return 'materials'
  }

  return 'other'
}

function normalizePaymentMethod(method: unknown, transcript: string): string | null {
  const combined = normalizeText(`${String(method ?? '')} ${transcript}`)

  if (
    combined.includes('bank transfer') ||
    combined.includes('plan transfer') ||
    combined.includes('meter plan transfer')
  ) {
    return 'bank_transfer'
  }
  if (combined.includes('cash')) return 'cash'
  if (combined.includes('card')) return 'card'
  if (combined.includes('check') || combined.includes('cheque')) return 'check'

  const raw = normalizeText(String(method ?? ''))
  return raw || null
}

function formatCurrency(value: unknown): string | null {
  const number = Number(value)
  if (!Number.isFinite(number)) {
    return null
  }

  return Number.isInteger(number) ? `$${number}` : `$${number.toFixed(2)}`
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

function sentenceCase(value: string): string {
  const text = value.trim()
  if (!text) return text
  return text.charAt(0).toUpperCase() + text.slice(1)
}

function repairTranscriptForAsr(transcript: string): string {
  return transcript
    .replace(/^\s*phil\b/gi, 'bill')
    .replace(/\bone peter\b/gi, 'one heater')
    .replace(/\bthrough one hundred\b/gi, 'two hundred')
    .replace(/\bthrough hundred\b/gi, 'two hundred')
    .replace(/\bmeter flank transfer\b/gi, 'bank transfer')
    .replace(/\bmeter plan transfer\b/gi, 'bank transfer')
    .replace(/\bplan transfer\b/gi, 'bank transfer')
    .replace(/\btop jaw\b/gi, 'draft jobs')
    .replace(/\blogin expense\b/gi, 'log an expense')
    .replace(/\band pennies\b/gi, 'at Bunnings')
    .replace(/\bwith pennies\b/gi, 'at Bunnings')
    .replace(/\bohm level\b/gi, 'Home Depot')
    .replace(/\bohm liver\b/gi, 'Home Depot')
}

function buildAssistantResponse(
  action: unknown,
  params: Record<string, unknown>,
  fallback: unknown
): string {
  const response = String(fallback ?? '').trim()
  const clientName = String(params.clientName ?? '').trim()
  const jobName = String(params.jobName ?? '').trim()
  const vendor = String(params.vendor ?? '').trim()
  const amountText = formatCurrency(params.amount)
  const laborHours = Number(params.laborHours)
  const materials = Array.isArray(params.materials)
    ? params.materials.filter((item): item is Record<string, unknown> => !!item && typeof item === 'object')
    : []

  if (action === 'create_expense' && amountText) {
    const description = sentenceCase(String(params.description ?? 'expense'))
    if (clientName && jobName) {
      return `Logging a ${amountText} expense for ${clientName} on ${jobName}.`
    }
    if (clientName) {
      return `Logging a ${amountText} expense for ${clientName}.`
    }
    if (vendor && vendor !== 'Unknown') {
      return `Logged a ${amountText} expense at ${vendor} for ${description.toLowerCase()}.`
    }
    return `Logged a ${amountText} expense for ${description.toLowerCase()}.`
  }

  if (action === 'record_payment' && amountText && clientName) {
    const method = String(params.method ?? '').trim().replaceAll('_', ' ')
    const methodSegment = method ? ` ${method}` : ''
    return `Recorded a ${amountText}${methodSegment} payment from ${clientName}.`
  }

  if (action === 'create_invoice' && clientName) {
    const parts: string[] = []
    if (Number.isFinite(laborHours) && laborHours > 0) {
      parts.push(`${laborHours.toFixed(laborHours % 1 === 0 ? 0 : 1)} hours of labor`)
    }
    if (materials.length > 0) {
      const firstMaterial = materials[0]
      const itemName = String(firstMaterial['item'] ?? '').trim()
      const unitPrice = formatCurrency(firstMaterial['unitPrice'])
      if (itemName && unitPrice) {
        parts.push(`${itemName} at ${unitPrice}`)
      } else if (itemName) {
        parts.push(itemName)
      }
    }
    if (parts.length > 0) {
      return `Creating ${String(params.type ?? 'invoice') == 'quote' ? 'a quote' : 'an invoice'} for ${clientName} with ${parts.join(' and ')}.`
    }
    return `Creating ${String(params.type ?? 'invoice') == 'quote' ? 'a quote' : 'an invoice'} for ${clientName}.`
  }

  if (action === 'create_note') {
    const title = String(params.title ?? '').trim()
    if (clientName && title) {
      return `Opening a note for ${clientName}: ${title}.`
    }
    if (clientName) {
      return `Opening a note for ${clientName}.`
    }
    if (title) {
      return `Opening a note: ${title}.`
    }
    return 'Opening your note.'
  }

  if (action === 'navigate') {
    const screen = String(params.screen ?? '').trim()
    if (screen == 'clients' && clientName) {
      return `Opening ${clientName}.`
    }
    if (screen) {
      return `Opening your ${screen}.`
    }
  }

  if (action === 'update_settings') {
    const updates: string[] = []
    const hourlyRate = formatCurrency(params.hourlyRate)
    const taxRate = Number(params.taxRate)
    const markupPercent = Number(params.markupPercent)

    if (hourlyRate) updates.push(`hourly rate to ${hourlyRate} per hour`)
    if (Number.isFinite(taxRate)) updates.push(`tax rate to ${taxRate}%`)
    if (Number.isFinite(markupPercent)) updates.push(`markup to ${markupPercent}%`)

    if (updates.length > 0) {
      return `Updated your ${updates.join(' and ')}.`
    }
  }

  return response || 'Done.'
}

function normalizeAssistantResult(
  parsed: Record<string, unknown>,
  context: Record<string, unknown>,
  transcript: string
): Record<string, unknown> {
  const normalized = { ...parsed }
  const params =
    parsed.params && typeof parsed.params === 'object' && !Array.isArray(parsed.params)
      ? { ...(parsed.params as Record<string, unknown>) }
      : {}
  const recentCustomers = Array.isArray(context.recentCustomers)
    ? context.recentCustomers.filter((item): item is string => typeof item === 'string')
    : []
  const knownJobs = Array.isArray(context.jobs)
    ? context.jobs
        .map((item) => {
          if (!item || typeof item !== 'object' || Array.isArray(item)) return ''
          const job = item as Record<string, unknown>
          return String(job.title ?? '').trim()
        })
        .filter((title): title is string => !!title)
    : []

  if (typeof params.clientName === 'string' && params.clientName.trim()) {
    params.clientName = bestMatchingName(params.clientName, recentCustomers)
  }
  if (normalized.action === 'create_invoice') {
    const hintedClientName = extractClientNameHintFromTranscript(transcript)
    if (hintedClientName) {
      params.clientName = bestMatchingName(hintedClientName, recentCustomers) ?? hintedClientName
    }
  }

  if (typeof params.jobName === 'string' && params.jobName.trim()) {
    params.jobName = bestMatchingName(params.jobName, knownJobs)
  }

  if (normalized.action === 'create_expense') {
    params.vendor = normalizeLikelyVendorName(params.vendor, transcript)
    if (typeof params.linkToJob !== 'boolean') {
      params.linkToJob = Boolean(
        String(params.clientName ?? '').trim() || String(params.jobName ?? '').trim()
      )
    }
    params.category = normalizeExpenseCategory(
      params.category,
      String(params.vendor ?? ''),
      params.description,
      transcript,
      params.linkToJob === true
    )
    const category = String(params.category ?? '').trim()
    if (typeof params.taxDeductible !== 'boolean' && category) {
      params.taxDeductible = defaultTaxDeductibleByCategory[category] ?? true
    }
  }

  if (normalized.action === 'record_payment') {
    params.method = normalizePaymentMethod(params.method, transcript)
  }

  if (normalized.action === 'update_settings' && params.taxRate != null) {
    const taxRate = Number(params.taxRate)
    if (Number.isFinite(taxRate) && taxRate > 0 && taxRate <= 1) {
      params.taxRate = Number((taxRate * 100).toFixed(2))
    }
  }

  if (Array.isArray(params.materials)) {
    params.materials = params.materials.map((item) => {
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
        item: normalizeLikelyMaterialName(material.item),
        quantity: safeQuantity,
        unitPrice: safeUnitPrice,
        cost: Number((safeQuantity * safeUnitPrice).toFixed(2)),
      }
    })
  }

  normalized.params = params
  normalized.response = buildAssistantResponse(normalized.action, params, parsed.response)
  return normalized
}

function describeKnownJobs(context: Record<string, unknown>): string {
  const jobs = Array.isArray(context.jobs)
    ? context.jobs.filter((item): item is Record<string, unknown> => !!item && typeof item === 'object' && !Array.isArray(item))
    : []

  if (jobs.length === 0) {
    return '(none yet)'
  }

  return jobs
    .map((job) => {
      const clientName = String(job.clientName ?? '').trim()
      const title = String(job.title ?? '').trim()
      const status = String(job.status ?? '').trim()
      const type = String(job.type ?? '').trim()
      const amountDue = Number(job.amountDue ?? 0)
      const dueText = Number.isFinite(amountDue) ? `, due $${amountDue}` : ''
      return `- ${clientName || 'Unknown client'} — ${title || 'Untitled'} (${type || 'invoice'}, ${status || 'draft'}${dueText})`
    })
    .join('\n')
}

function buildGlobalAssistantPrompt(
  transcript: string,
  context: Record<string, unknown>
): string {
  const stats = (context.stats as Record<string, unknown>) || {}
  const profile = (context.profile as Record<string, unknown>) || {}
  const recentCustomers = (context.recentCustomers as string[]) || []
  const currentScreen = (context.currentScreen as string) || 'home'
  const knownJobs = describeKnownJobs(context)

  return `
You are an intelligent AI assistant for a tradesman's invoicing app called Tradesman Ledger. The user is a tradesperson (plumber, electrician, builder, etc.) who manages their business through this app. You have the ability to perform actions on their behalf.

═══ USER CONTEXT ═══
Current screen: ${currentScreen}
Business name: ${profile.businessName || '(not set)'}
Hourly rate: $${profile.hourlyRate || 85}/hr
Tax rate: ${profile.taxRate || 0}%
Currency: ${profile.currency || '$'}

Business summary:
- Total outstanding: $${stats.totalOutstanding || 0} across ${stats.outstandingCount || 0} invoices
- Invoices sent: ${stats.sentCount || 0}
- Drafts: ${stats.draftCount || 0}
- Paid this month: $${stats.monthlyCollected || 0}
- Revenue this month: $${stats.monthlyRevenue || 0}
- Expenses this month: $${stats.monthlyExpenses || 0}
- Profit this month: $${stats.monthlyProfit || 0}

Known customers: ${recentCustomers.length > 0 ? recentCustomers.join(', ') : '(none yet)'}
Known jobs:
${knownJobs}
═════════════════════

═══ VOICE COMMAND ═══
"${transcript}"
═════════════════════

YOUR TASK: Interpret the voice command and return a JSON response with the action to take.

AVAILABLE ACTIONS:

1. "create_invoice" — Create a new invoice or quote
   params: { clientName, type ("invoice"|"quote"), description, laborHours, laborType, laborRate, laborAmount, materials: [{item, quantity, unitPrice, cost}] }

2. "create_expense" — Log a new expense
   params: { amount, description, vendor, category ("materials"|"labor"|"fuel"|"tools"|"supplies"|"insurance"|"utilities"|"marketing"|"fees"|"meals"|"other"), taxDeductible, clientName (optional), jobName (optional), linkToJob (optional boolean) }

3. "record_payment" — Record a payment received
   params: { clientName, amount, method ("cash"|"card"|"bank_transfer"|"check") }

4. "navigate" — Go to a screen
   params: { screen ("home"|"jobs"|"expenses"|"clients"|"analytics"|"settings"|"notes"|"drafts"|"sent"|"paid"), clientName (optional, for customer detail) }

5. "answer" — Answer a question using the business data above
   params: {}

6. "update_settings" — Change a business setting
   params: { hourlyRate, taxRate, markupPercent }

7. "create_note" — Open a new note, optionally linked to a customer
   params: { clientName (optional), title (optional), content, pinned (optional) }

RULES:
1. Return exactly ONE action per command.
2. "response" is ALWAYS required — a short, natural spoken confirmation or answer.
3. For "create_invoice": extract as much as you can. Default laborHours to 1 and laborType to "profile" if missing.
4. Correct obvious speech-to-text mistakes when the context makes them clear. This applies to customer names, job names, trade items, and vendor names.
5. For "create_expense": if the user mentions a customer or a specific job ("for Godwin", "on the Steven attic job"), include clientName and/or jobName and set linkToJob to true.
6. For "record_payment": match clientName to the known customers list. If ambiguous, pick the closest match and mention it in the response.
7. If the user asks to open a specific customer, return action "navigate" with params { "screen": "clients", "clientName": "<matched customer>" }.
8. If the user wants to jot something down, remember something, or create a note, use "create_note" and put the actual note text into content.
9. For "answer": use ONLY the business data provided above. Do not make up numbers. If you don't have enough data, say so.
10. For "navigate": map natural language to screen names (e.g. "show me my clients" → "clients", "open my notes" → "notes").
11. If the command is unclear or doesn't fit any action, use "answer" and ask for clarification in "response".
12. Keep "response" under 2 sentences. These are spoken aloud.

RESPONSE FORMAT (JSON):
{
  "action": string,
  "params": { ... },
  "response": string
}

EXAMPLES:

Voice: "invoice David for 3 hours plumbing, copper pipes 120 dollars"
→ { "action": "create_invoice", "params": { "clientName": "David", "type": "invoice", "description": "Plumbing work", "laborHours": 3, "laborType": "profile", "materials": [{"item": "Copper Pipes", "quantity": 1, "unitPrice": 120, "cost": 120}] }, "response": "Creating an invoice for David — 3 hours plus $120 in materials." }

Voice: "I just spent 45 dollars at Bunnings on pipe fittings for Godwin"
→ { "action": "create_expense", "params": { "amount": 45, "description": "Pipe fittings", "vendor": "Bunnings", "category": "materials", "taxDeductible": true, "clientName": "Godwin", "linkToJob": true }, "response": "Logging a $45 expense for Godwin." }

Voice: "David just paid me 500 cash"
→ { "action": "record_payment", "params": { "clientName": "David", "amount": 500, "method": "cash" }, "response": "Recorded $500 cash payment from David." }

Voice: "how much am I owed?"
→ { "action": "answer", "params": {}, "response": "You have $${stats.totalOutstanding || 0} outstanding across ${stats.outstandingCount || 0} invoices." }

Voice: "show me my notes"
→ { "action": "navigate", "params": { "screen": "notes" }, "response": "Opening your notes." }

Voice: "open Sarah Henderson"
→ { "action": "navigate", "params": { "screen": "clients", "clientName": "Sarah Henderson" }, "response": "Opening Sarah Henderson." }

Voice: "make a note for Sarah that the tap is leaking in the back bathroom"
→ { "action": "create_note", "params": { "clientName": "Sarah", "title": "Leaking back bathroom tap", "content": "The tap is leaking in the back bathroom." }, "response": "Opening a note for Sarah." }

Voice: "change my hourly rate to 95"
→ { "action": "update_settings", "params": { "hourlyRate": 95 }, "response": "Updated your hourly rate to $95 per hour." }

Now process the voice command.
`;
}

serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders })

  try {
    const { transcript, context } = await req.json()

    if (!transcript || transcript.trim().length === 0) {
      throw new Error('Empty transcript received')
    }

    const repairedTranscript = repairTranscriptForAsr(transcript)
    const prompt = buildGlobalAssistantPrompt(repairedTranscript, context || {})

    console.log(`Global assistant processing: "${repairedTranscript.substring(0, 80)}..." (context: ${context ? 'yes' : 'no'})`)

    const controller = new AbortController()
    const timeout = setTimeout(() => controller.abort(), 25000)
    let response: Response
    try {
      response = await fetch(`https://generativelanguage.googleapis.com/v1beta/models/${GEMINI_MODEL}:generateContent?key=${GEMINI_API_KEY}`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          contents: [{ parts: [{ text: prompt }] }],
          generationConfig: { responseMimeType: "application/json" }
        }),
        signal: controller.signal,
      })
    } catch (e) {
      if (e.name === 'AbortError') throw new Error('AI timed out after 25s')
      throw e
    } finally {
      clearTimeout(timeout)
    }

    if (!response.ok) {
      const errorText = await response.text()
      console.error(`Gemini error (${response.status}):`, errorText)
      throw new Error(`Gemini returned ${response.status}`)
    }

    const result = await response.json()
    if (!result?.candidates?.[0]?.content?.parts?.[0]?.text) {
      console.error('Unexpected response:', JSON.stringify(result))
      throw new Error('Unexpected AI response format')
    }

    const extractedText = result.candidates[0].content.parts[0].text
    const parsed = normalizeAssistantResult(
      parseJsonObjectResponse(extractedText),
      context || {},
      repairedTranscript
    )
    console.log('Global assistant response ready')

    return new Response(JSON.stringify(parsed), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    })
  } catch (error) {
    console.error(`process_voice_command error: ${error.message}`)
    return new Response(JSON.stringify({
      action: 'answer',
      params: {},
      response: 'Sorry, I had trouble processing that. Please try again.',
      error: error.message,
    }), {
      status: 200,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    })
  }
})
