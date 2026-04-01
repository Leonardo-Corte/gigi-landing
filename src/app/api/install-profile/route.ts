import { NextResponse } from "next/server";
import { generateMobileConfigProfile } from "@/lib/gigiSystemCommander";

export async function GET() {
  const payload = generateMobileConfigProfile({
    displayName: "GIGI System Profile",
    organization: "GIGI Labs",
    payloadIdentifier: "xyz.killsiri.gigi.profile",
    payloadUUID: "5F06D6EE-E2CB-4C6F-BF62-0F1E891EAE7B",
  });

  return new NextResponse(payload, {
    status: 200,
    headers: {
      "Content-Type": "application/x-apple-aspen-config; charset=utf-8",
      "Content-Disposition": 'attachment; filename="gigi-system-profile.mobileconfig"',
      "Cache-Control": "no-store",
    },
  });
}
