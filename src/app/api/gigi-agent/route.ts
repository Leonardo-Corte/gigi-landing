import { NextResponse } from 'next/server';

export async function POST(req: Request) {
  const GIGI_AGENT_URL = process.env.OPENCLAW_SERVER_URL || 'https://api.openclaw.ai/v1/execute';

  try {
    const { userInput, context } = await req.json();
    console.log("Comando GIGI per OpenClaw:", userInput);

    const agentResponse = await fetch(GIGI_AGENT_URL, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${process.env.OPENCLAW_API_KEY}`
      },
      body: JSON.stringify({
        task: userInput,
        user_context: context,
        capabilities: ["web_navigation", "form_filling", "click_buttons"]
      }),
      signal: AbortSignal.timeout(15000) // Timeout dopo 15 secondi
    });

    if (!agentResponse.ok) {
      throw new Error(`OpenClaw error: ${agentResponse.status}`);
    }

    const result = await agentResponse.json();

    return NextResponse.json({
      voiceResponse: `Certamente Leonardo, GIGI e OpenClaw si stanno occupando di: ${userInput}.`,
      agentData: result,
      status: "executing"
    });
  } catch (error) {
    console.error("Errore Agente:", error);
    return NextResponse.json({
      voiceResponse: "Leonardo, c'è un problema di connessione con il mio modulo operativo. Riprovo tra un istante.",
      error: "Connessione interrotta"
    }, { status: 500 });
  }
}
