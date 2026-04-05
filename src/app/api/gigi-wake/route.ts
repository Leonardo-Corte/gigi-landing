import { NextResponse } from "next/server";

/**
 * Internal webhook for operators / MDM automation: returns the silent-push payload shape
 * for waking the GIGI iOS app. Actual APNs delivery is done with your Apple Push Key + device token
 * (from Xcode logs: `GIGI: APNs device token ...`).
 *
 * POST /api/gigi-wake
 * Header: x-gigi-secret: <same as GIGI_WAKE_SECRET on Vercel>
 */
export async function POST(request: Request) {
  const secret = request.headers.get("x-gigi-secret");
  const expected = process.env.GIGI_WAKE_SECRET;
  if (!expected || secret !== expected) {
    return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
  }

  const body = (await request.json().catch(() => ({}))) as {
    deviceTokenHex?: string;
  };

  const silentPayload = {
    aps: {
      "content-available": 1,
    },
    gigi: {
      wake: true,
    },
  };

  return NextResponse.json({
    ok: true,
    message:
      "Use this JSON as the APNs payload (HTTP/2 to api.push.apple.com or api.sandbox.push.apple.com). " +
      "Register Push Notifications capability and use the device token printed by the GIGI app.",
    apnsPayload: silentPayload,
    deviceTokenHex: body.deviceTokenHex ?? null,
    notes: [
      "Bundle id must match xyz.killsiri.app.",
      "Use .p8 APNs Auth Key, Key ID, Team ID from developer.apple.com.",
      "Silent push requires background modes: remote-notification (already in Info.plist).",
    ],
  });
}
