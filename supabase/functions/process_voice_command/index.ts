import { serve } from "https://deno.land/std@0.168.0/http/server.ts"

const GEMINI_API_KEY = Deno.env.get('GOOGLE_GEMINI_KEY')
const GEMINI_MODEL = 'gemini-3.1-flash-lite-preview'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

function buildGlobalAssistantPrompt(
  transcript: string,
  context: Record<string, unknown>
): string {
  const stats = (context.stats as Record<string, unknown>) || {};
  const profile = (context.profile as Record<string, unknown>) || {};
  const recentCustomers = (context.recentCustomers as string[]) || [];
  const currentScreen = (context.currentScreen as string) || 'home';

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
═════════════════════

═══ VOICE COMMAND ═══
"${transcript}"
═════════════════════

YOUR TASK: Interpret the voice command and return a JSON response with the action to take.

AVAILABLE ACTIONS:

1. "create_invoice" — Create a new invoice or quote
   params: { clientName, type ("invoice"|"quote"), description, laborHours, laborType, laborRate, laborAmount, materials: [{item, quantity, unitPrice, cost}] }

2. "create_expense" — Log a new expense
   params: { amount, description, vendor, category ("materials"|"labor"|"tools"|"travel"|"equipment"|"other"), taxDeductible }

3. "record_payment" — Record a payment received
   params: { clientName, amount, method ("cash"|"card"|"bank_transfer"|"check") }

4. "navigate" — Go to a screen
   params: { screen ("home"|"jobs"|"expenses"|"clients"|"analytics"|"settings"|"drafts"|"sent"|"paid"), clientName (optional, for customer detail) }

5. "answer" — Answer a question using the business data above
   params: {} (no params needed — just use "response" to answer the question)

6. "update_settings" — Change a business setting
   params: { hourlyRate, taxRate, markupPercent } (include only fields being changed)

RULES:
1. Return exactly ONE action per command.
2. "response" is ALWAYS required — a short, natural spoken confirmation or answer.
3. For "create_invoice": extract as much as you can. Default laborHours to 1, laborType to "profile".
4. For "record_payment": match clientName to the known customers list. If ambiguous, pick the closest match and mention it in the response.
5. For "answer": use ONLY the business data provided above. Do not make up numbers. If you don't have enough data, say so.
6. For "navigate": map natural language to screen names (e.g. "show me my clients" → "clients", "open my invoices" → "jobs").
7. If the command is unclear or doesn't fit any action, use "answer" and ask for clarification in "response".
8. Keep "response" under 2 sentences. These are spoken aloud.

RESPONSE FORMAT (JSON):
{
  "action": string,
  "params": { ... },
  "response": string
}

EXAMPLES:

Voice: "invoice David for 3 hours plumbing, copper pipes 120 dollars"
→ { "action": "create_invoice", "params": { "clientName": "David", "type": "invoice", "description": "Plumbing work", "laborHours": 3, "laborType": "profile", "materials": [{"item": "Copper Pipes", "quantity": 1, "unitPrice": 120, "cost": 120}] }, "response": "Creating an invoice for David — 3 hours plus $120 in materials." }

Voice: "I just spent 45 dollars at Bunnings on pipe fittings"
→ { "action": "create_expense", "params": { "amount": 45, "description": "Pipe fittings", "vendor": "Bunnings", "category": "materials", "taxDeductible": false }, "response": "Logged $45 expense at Bunnings for pipe fittings." }

Voice: "David just paid me 500 cash"
→ { "action": "record_payment", "params": { "clientName": "David", "amount": 500, "method": "cash" }, "response": "Recorded $500 cash payment from David." }

Voice: "how much am I owed?"
→ { "action": "answer", "params": {}, "response": "You have $${stats.totalOutstanding || 0} outstanding across ${stats.outstandingCount || 0} invoices." }

Voice: "show me my expenses"
→ { "action": "navigate", "params": { "screen": "expenses" }, "response": "Opening your expenses." }

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

    const prompt = buildGlobalAssistantPrompt(transcript, context || {})

    console.log(`Global assistant processing: "${transcript.substring(0, 80)}..." (context: ${context ? 'yes' : 'no'})`)

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
    console.log('Global assistant response ready')

    return new Response(extractedText, {
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
      status: 200, // Return 200 with fallback so the app can show the message
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    })
  }
})
