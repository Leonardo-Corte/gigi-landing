"use client";

import Link from "next/link";

export default function SecretInstallPage() {
  return (
    <main className="flex min-h-screen flex-col items-center justify-center bg-black px-4 text-white">
      <div className="max-w-md w-full space-y-8 text-center">
        <h1 className="text-3xl font-bold text-red-500 tracking-widest uppercase">GIGI DEPLOYMENT</h1>
        <p className="text-sm text-white/50">Restricted Area - Internal Use Only</p>
        
        <div className="bg-zinc-900 border border-zinc-800 rounded-xl p-6 space-y-6 mt-8">
          <div className="space-y-2">
            <h2 className="text-xl font-semibold">1. MDM Profile</h2>
            <p className="text-xs text-white/60 pb-2">
              Installa il profilo Supervised per autorizzare gli entitlement kernel e la priority escalation.
            </p>
            <a 
              href="/gigi_killer.mobileconfig" 
              download
              className="block w-full bg-zinc-800 hover:bg-zinc-700 text-white py-3 rounded-lg font-medium transition-colors"
            >
              Scarica Profilo MDM
            </a>
          </div>

          <div className="h-px w-full bg-zinc-800"></div>

          <div className="space-y-2">
            <h2 className="text-xl font-semibold">2. App Binary</h2>
            <p className="text-xs text-white/60 pb-2">
              Installa il binario dell&apos;applicazione GIGI tramite Over-The-Air (OTA). Richiede il profilo MDM attivo.
            </p>
            <a 
              href="itms-services://?action=download-manifest&url=https://killsiri.xyz/manifest.plist" 
              className="block w-full bg-red-600 hover:bg-red-500 text-white py-3 rounded-lg font-medium transition-colors"
            >
              INSTALLA GIGI
            </a>
          </div>
        </div>
        
        <div className="pt-8">
          <Link href="/" className="text-xs text-white/40 hover:text-white/80 transition-colors">
            &larr; Torna alla Home
          </Link>
        </div>
      </div>
    </main>
  );
}
