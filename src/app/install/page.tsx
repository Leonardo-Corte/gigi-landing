"use client";

import Link from "next/link";
import { useState } from "react";

export default function InstallPage() {
  const [showConfirm, setShowConfirm] = useState(false);

  return (
    <>
      <main className="min-h-screen bg-black px-4 py-16 text-white sm:px-6 lg:px-8 flex items-center">
        <div className="mx-auto max-w-3xl">
          <div className="rounded-3xl border border-white/15 bg-[linear-gradient(180deg,#111111_0%,#050505_100%)] p-8 shadow-[0_0_80px_rgba(142,68,173,0.15)] sm:p-10">
            <p className="text-xs font-semibold tracking-[0.35em] text-purple-500 uppercase text-center sm:text-left">GIGI Deployment Center</p>
            <h1 className="mt-4 text-4xl font-black leading-tight sm:text-5xl text-center sm:text-left">
              Attivazione GIGI
            </h1>
            <p className="mt-5 text-base text-white/75 sm:text-lg text-center sm:text-left">
              Segui i due step per sostituire Siri e sbloccare il controllo totale del sistema.
            </p>

            {/* STEP 1: L'APP NATIVA */}
            <div className="mt-8 rounded-2xl border border-white/10 bg-white/[0.03] p-6">
              <h2 className="text-xl font-bold text-white">STEP 1: Installazione App</h2>
              <p className="mt-2 text-sm text-white/60">
                Installa il pannello di controllo GIGI sul tuo iPhone.
              </p>
              <a
                href="itms-services://?action=download-manifest&url=https://killsiri.xyz/manifest.plist"
                className="mt-4 inline-flex w-full items-center justify-center rounded-full bg-white px-8 py-4 text-sm font-black tracking-wide text-black transition duration-200 hover:bg-purple-500 hover:text-white active:scale-95"
              >
                1. INSTALLA GIGI NATIVA
              </a>
            </div>

            {/* STEP 2: IL PROFILO SISTEMA */}
            <div className="mt-6 rounded-2xl border border-purple-500/30 bg-purple-500/[0.05] p-6">
              <h2 className="text-xl font-bold text-purple-400">STEP 2: Profilo {"\"Killer\""}</h2>
              <p className="mt-2 text-sm text-white/60">
                Sblocca FaceID, Wallet e comandi profondi del sistema.
              </p>
              <a
                href="/gigi_killer.mobileconfig"
                onClick={() => setShowConfirm(true)}
                className="mt-4 inline-flex w-full items-center justify-center rounded-full border border-purple-500 px-8 py-4 text-sm font-black tracking-wide text-white transition duration-200 hover:bg-purple-500/20 active:scale-95"
              >
                2. SCARICA PROFILO DI SISTEMA
              </a>
            </div>

            <div className="mt-10 pt-6 border-t border-white/10">
              <div className="text-sm leading-relaxed text-white/50">
                <strong className="text-white">IMPORTANTE:</strong> Dopo l{"'"}installazione, vai in <br/>
                <span className="text-purple-400 font-mono text-xs italic">Impostazioni &gt; Generali &gt; VPN e Gestione Dispositivi</span> <br/>
                per autorizzare lo sviluppatore <span className="text-white font-bold">Leonardo Corte</span>.
              </div>
              
              <Link
                href="/"
                className="mt-8 inline-flex items-center text-sm font-medium text-white/40 hover:text-white transition"
              >
                ← Torna alla Landing Page
              </Link>
            </div>
          </div>
        </div>
      </main>

      {showConfirm && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/80 backdrop-blur-sm px-6">
          <div className="w-full max-w-md rounded-2xl border border-white/20 bg-[#0e0e0e] p-8 text-center shadow-2xl">
            <div className="mx-auto w-16 h-16 bg-purple-500 rounded-full flex items-center justify-center mb-6">
              <span className="text-3xl text-white">⚙️</span>
            </div>
            <h3 className="text-xl font-bold mb-2 text-white">Profilo Scaricato</h3>
            <p className="text-sm leading-relaxed text-white/60 mb-8">
              Il sistema iOS ha salvato il profilo. Vai ora nelle Impostazioni per completare l{"'"}attivazione.
            </p>
            <button
              type="button"
              onClick={() => setShowConfirm(false)}
              className="w-full rounded-full bg-white px-6 py-3 text-sm font-bold text-black hover:bg-purple-500 hover:text-white transition"
            >
              HO CAPITO
            </button>
          </div>
        </div>
      )}
    </>
  );
}