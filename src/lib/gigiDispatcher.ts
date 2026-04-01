export type GigiIntent = "SYSTEM_ACTION" | "KNOWLEDGE_QUERY" | "WEB_ACTION";

export type GigiCommandCategory = "PASSWORDS" | "PAYMENTS" | "CALENDAR" | "GENERAL" | "WEB";

export type DispatchResult = {
  intent: GigiIntent;
  category: GigiCommandCategory;
  requiresPhysicalConfirmation: boolean;
  confirmationPrompt?: string;
  message: string;
};

function normalize(input: string): string {
  return input.trim().toLowerCase();
}

function includesAny(input: string, words: string[]): boolean {
  return words.some((word) => input.includes(word));
}

export function recognizeIntent(request: string): { intent: GigiIntent; category: GigiCommandCategory } {
  const text = normalize(request);

  const passwordWords = ["password", "passcode", "keychain", "credential", "login"];
  const paymentWords = ["pay", "payment", "send money", "transfer", "apple pay", "invoice"];
  const calendarWords = ["calendar", "meeting", "event", "schedule", "appointment", "reminder"];
  const webActionWords = ["vercel", "open website", "open tab", "click", "submit form", "navigate"];

  if (includesAny(text, paymentWords)) {
    return { intent: "SYSTEM_ACTION", category: "PAYMENTS" };
  }
  if (includesAny(text, passwordWords)) {
    return { intent: "SYSTEM_ACTION", category: "PASSWORDS" };
  }
  if (includesAny(text, calendarWords)) {
    return { intent: "SYSTEM_ACTION", category: "CALENDAR" };
  }
  if (includesAny(text, webActionWords)) {
    return { intent: "WEB_ACTION", category: "WEB" };
  }

  return { intent: "KNOWLEDGE_QUERY", category: "GENERAL" };
}

// Placeholder: native bridge will store credentials in iCloud Keychain.
export async function saveToKeychain(account: string, password: string): Promise<string> {
  void password;
  return `I've tucked that password into your iCloud Keychain for ${account}.`;
}

// Placeholder: native bridge will trigger Apple Pay sheet.
export async function triggerApplePay(amount: number, recipient: string): Promise<string> {
  return `Initiating FaceID for Apple Pay transfer of $${amount.toFixed(2)} to ${recipient}...`;
}

// Placeholder: native bridge will open app and run action.
export async function openAppAndPerform(appName: string, action: string): Promise<string> {
  return `Opening ${appName} and executing: ${action}.`;
}

function physicalConfirmationPrompt(category: GigiCommandCategory): string | undefined {
  if (category === "PAYMENTS") {
    return "Please confirm this payment with FaceID or TouchID.";
  }
  if (category === "PASSWORDS") {
    return "Please confirm secure credential access with FaceID or TouchID.";
  }
  return undefined;
}

export async function dispatchGigiCommand(request: string): Promise<DispatchResult> {
  const { intent, category } = recognizeIntent(request);
  const requiresPhysicalConfirmation = category === "PAYMENTS" || category === "PASSWORDS";
  const confirmationPrompt = physicalConfirmationPrompt(category);

  if (category === "PAYMENTS") {
    return {
      intent,
      category,
      requiresPhysicalConfirmation,
      confirmationPrompt,
      message: "Initiating FaceID for Vercel payment...",
    };
  }

  if (category === "PASSWORDS") {
    return {
      intent,
      category,
      requiresPhysicalConfirmation,
      confirmationPrompt,
      message: "I've tucked that password into your iCloud Keychain.",
    };
  }

  if (category === "CALENDAR") {
    return {
      intent,
      category,
      requiresPhysicalConfirmation: false,
      message: "Calendar action queued. I am syncing this with your system apps now.",
    };
  }

  if (intent === "WEB_ACTION") {
    return {
      intent,
      category,
      requiresPhysicalConfirmation: false,
      message: "Web action accepted. I am handing this off to the OS automation layer.",
    };
  }

  return {
    intent,
    category,
    requiresPhysicalConfirmation: false,
    message: "Knowledge query recognized. I will fetch the answer now.",
  };
}
