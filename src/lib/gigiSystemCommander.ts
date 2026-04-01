export type SystemCommandIntent =
  | "OPEN_SETTINGS_BLUETOOTH"
  | "OPEN_SETTINGS_WIFI"
  | "OPEN_SETTINGS_GENERAL"
  | "OPEN_SHORTCUT"
  | "PREPARE_MESSAGE"
  | "OPEN_FACETIME"
  | "OPEN_MESSAGES";

export type SystemExecutionResult = {
  intent: SystemCommandIntent;
  deepLink: string;
  confirmationRequired: boolean;
  voiceLine: string;
  uiMode: "handoff" | "compose";
};

function encode(value: string): string {
  return encodeURIComponent(value.trim());
}

/**
 * Apple URL schemes library (safe, explicit handoff).
 * These schemes can change by iOS version; keep this map centralized.
 */
export const SYSTEM_DEEP_LINKS = {
  bluetooth: "App-prefs:root=Bluetooth",
  wifi: "App-prefs:root=WIFI",
  generalSettings: "App-prefs:root=General",
  shortcuts: (shortcutName: string) => `shortcuts://run-shortcut?name=${encode(shortcutName)}`,
  facetime: (target: string) => `facetime://${encode(target)}`,
  messages: (target?: string, body?: string) =>
    `sms:${target ? encode(target) : ""}${body ? `&body=${encode(body)}` : ""}`,
} as const;

function parseMessageTarget(command: string): string {
  const match = command.match(/text\s+([a-z0-9@.+_\- ]+)/i);
  return match?.[1]?.trim() ?? "contact";
}

function parseShortcutName(command: string): string {
  const match = command.match(/shortcut\s+(.+)$/i);
  return match?.[1]?.trim() ?? "GIGI Command";
}

/**
 * Translates plain language into a direct OS handoff.
 * Note: this intentionally avoids hidden/bypass behavior.
 */
export function executeSystemCommand(command: string): SystemExecutionResult {
  const text = command.trim().toLowerCase();

  if (text.includes("turn off bluetooth") || text.includes("bluetooth off")) {
    return {
      intent: "OPEN_SETTINGS_BLUETOOTH",
      deepLink: SYSTEM_DEEP_LINKS.bluetooth,
      confirmationRequired: true,
      voiceLine: "Opening Bluetooth settings. Confirm the change with FaceID/TouchID if prompted.",
      uiMode: "handoff",
    };
  }

  if (text.includes("turn off wifi") || text.includes("wifi off")) {
    return {
      intent: "OPEN_SETTINGS_WIFI",
      deepLink: SYSTEM_DEEP_LINKS.wifi,
      confirmationRequired: true,
      voiceLine: "Opening Wi-Fi settings. Confirm the change with FaceID/TouchID if prompted.",
      uiMode: "handoff",
    };
  }

  if (text.startsWith("text ")) {
    const target = parseMessageTarget(command);
    return {
      intent: "PREPARE_MESSAGE",
      deepLink: SYSTEM_DEEP_LINKS.messages(target),
      confirmationRequired: false,
      voiceLine: `Message draft prepared for ${target} in Messages.`,
      uiMode: "compose",
    };
  }

  if (text.includes("facetime")) {
    const target = command.replace(/.*facetime\s*/i, "").trim() || "contact";
    return {
      intent: "OPEN_FACETIME",
      deepLink: SYSTEM_DEEP_LINKS.facetime(target),
      confirmationRequired: false,
      voiceLine: `Launching FaceTime for ${target}.`,
      uiMode: "handoff",
    };
  }

  if (text.includes("run shortcut")) {
    const shortcutName = parseShortcutName(command);
    return {
      intent: "OPEN_SHORTCUT",
      deepLink: SYSTEM_DEEP_LINKS.shortcuts(shortcutName),
      confirmationRequired: false,
      voiceLine: `Running shortcut ${shortcutName}.`,
      uiMode: "handoff",
    };
  }

  if (text.includes("open messages")) {
    return {
      intent: "OPEN_MESSAGES",
      deepLink: SYSTEM_DEEP_LINKS.messages(),
      confirmationRequired: false,
      voiceLine: "Opening Messages.",
      uiMode: "handoff",
    };
  }

  return {
    intent: "OPEN_SETTINGS_GENERAL",
    deepLink: SYSTEM_DEEP_LINKS.generalSettings,
    confirmationRequired: false,
    voiceLine: "Opening system settings.",
    uiMode: "handoff",
  };
}

export type MdmProfileOptions = {
  displayName: string;
  organization: string;
  payloadIdentifier: string;
  payloadUUID: string;
};

/**
 * Generates a consensual MDM profile template.
 * This is for managed-device enrollment flows only, not bypass behavior.
 */
export function generateMobileConfigProfile(options: MdmProfileOptions): string {
  const { displayName, organization, payloadIdentifier, payloadUUID } = options;
  return `<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>PayloadType</key>
  <string>Configuration</string>
  <key>PayloadVersion</key>
  <integer>1</integer>
  <key>PayloadIdentifier</key>
  <string>${payloadIdentifier}</string>
  <key>PayloadUUID</key>
  <string>${payloadUUID}</string>
  <key>PayloadDisplayName</key>
  <string>${displayName}</string>
  <key>PayloadOrganization</key>
  <string>${organization}</string>
  <key>PayloadDescription</key>
  <string>Managed profile for GIGI system automation with explicit user/admin consent.</string>
  <key>ConsentText</key>
  <dict>
    <key>default</key>
    <string>This managed profile grants approved automation capabilities to GIGI.</string>
  </dict>
  <key>PayloadContent</key>
  <array/>
</dict>
</plist>`;
}
