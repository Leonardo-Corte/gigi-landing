import { dispatchGigiCommand } from "@/lib/gigiDispatcher";
import { executeSystemCommand } from "@/lib/gigiSystemCommander";

export type GigiActionPackage = {
  input: string;
  intent: "SYSTEM_ACTION" | "KNOWLEDGE_QUERY" | "WEB_ACTION";
  voiceResponse: string;
  deepLink?: string;
  shouldExecuteDeepLink: boolean;
  confirmationRequired: boolean;
  confirmationPrompt?: string;
  metadata: {
    category: string;
    uiMode?: "handoff" | "compose";
  };
};

/**
 * Main orchestration entry-point:
 * 1) Recognize and dispatch intent
 * 2) If system action, build executable OS handoff payload
 * 3) Return a final action package for UI/voice runtime
 */
export async function orchestrateGigiInput(input: string): Promise<GigiActionPackage> {
  const dispatch = await dispatchGigiCommand(input);

  if (dispatch.intent === "SYSTEM_ACTION") {
    const systemExecution = executeSystemCommand(input);

    return {
      input,
      intent: dispatch.intent,
      voiceResponse: `${dispatch.message} ${systemExecution.voiceLine}`.trim(),
      deepLink: systemExecution.deepLink,
      shouldExecuteDeepLink: true,
      confirmationRequired:
        dispatch.requiresPhysicalConfirmation || systemExecution.confirmationRequired,
      confirmationPrompt: dispatch.confirmationPrompt,
      metadata: {
        category: dispatch.category,
        uiMode: systemExecution.uiMode,
      },
    };
  }

  return {
    input,
    intent: dispatch.intent,
    voiceResponse: dispatch.message,
    shouldExecuteDeepLink: false,
    confirmationRequired: dispatch.requiresPhysicalConfirmation,
    confirmationPrompt: dispatch.confirmationPrompt,
    metadata: {
      category: dispatch.category,
    },
  };
}
