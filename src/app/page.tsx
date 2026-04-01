"use client";

import { useEffect, useState } from "react";

export default function Home() {
  const [micDenied, setMicDenied] = useState(false);
  const [isListening, setIsListening] = useState(false);

  const requestMicrophone = async () => {
    if (!navigator.mediaDevices?.getUserMedia) {
      setMicDenied(true);
      return;
    }

    try {
      const stream = await navigator.mediaDevices.getUserMedia({ audio: true });
      setMicDenied(false);
      setIsListening(true);

      const audioContext = new window.AudioContext();
      const analyser = audioContext.createAnalyser();
      analyser.fftSize = 512;
      const source = audioContext.createMediaStreamSource(stream);
      source.connect(analyser);

      const samples = new Uint8Array(analyser.frequencyBinCount);
      let rafId = 0;
      let lastActive = Date.now();

      const detectVoice = () => {
        analyser.getByteTimeDomainData(samples);
        let total = 0;
        for (let i = 0; i < samples.length; i += 1) {
          const centered = samples[i] - 128;
          total += Math.abs(centered);
        }

        const avg = total / samples.length;
        if (avg > 10) {
          lastActive = Date.now();
          setIsListening(true);
        } else if (Date.now() - lastActive > 350) {
          setIsListening(false);
        }

        rafId = window.requestAnimationFrame(detectVoice);
      };

      detectVoice();

      return () => {
        window.cancelAnimationFrame(rafId);
        stream.getTracks().forEach((track) => track.stop());
        source.disconnect();
        audioContext.close().catch(() => undefined);
      };
    } catch {
      setMicDenied(true);
    }
    return undefined;
  };

  useEffect(() => {
    const previousBodyBackground = document.body.style.background;
    document.body.style.background = "transparent";

    let cleanupAudio: (() => void) | undefined;
    void requestMicrophone().then((cleanup) => {
      cleanupAudio = cleanup;
    });

    return () => {
      document.body.style.background = previousBodyBackground;
      if (cleanupAudio) {
        cleanupAudio();
      }
    };
  }, []); // eslint-disable-line react-hooks/exhaustive-deps

  return (
    <>
      <main className="min-h-screen bg-transparent px-4 py-10 text-white">
        <div className="mx-auto flex min-h-[88vh] w-full max-w-3xl items-center justify-center rounded-[2rem] border border-white/25 bg-black/15 p-8 backdrop-blur-[20px]">
          <div className="text-center">
            <p className="mb-4 text-xs font-semibold tracking-[0.3em] text-white/65">GIGI GHOST MODE</p>
            <div className="relative mx-auto h-56 w-56 sm:h-64 sm:w-64">
              <div
                className={`absolute inset-0 rounded-full border border-white/40 transition ${
                  isListening ? "animate-ping opacity-90" : "opacity-25"
                }`}
              />
              <div
                className={`absolute inset-3 rounded-full border border-white/30 transition ${
                  isListening ? "animate-pulse opacity-80" : "opacity-20"
                }`}
              />
              <div className="absolute inset-7 rounded-full border border-white/20" />
              <svg
                viewBox="0 0 220 220"
                className="absolute inset-0 h-full w-full"
                role="img"
                aria-label="GIGI robot face"
              >
                <g fill="none" stroke="rgba(255,255,255,0.96)" strokeWidth="6" strokeLinecap="round">
                  <rect x="45" y="60" width="130" height="115" rx="22" />
                  <circle cx="85" cy="110" r="23" />
                  <circle cx="135" cy="110" r="23" />
                  <path d="M80 150 Q110 165 140 150" />
                  <path d="M85 58 V42" />
                  <circle cx="85" cy="38" r="6" fill="rgba(255,255,255,0.96)" stroke="none" />
                </g>
              </svg>
            </div>
            <p className="mt-7 text-sm text-white/75">
              {isListening
                ? "Voice detected. GIGI is processing live audio waves."
                : "Listening standby. Speak to awaken GIGI."}
            </p>
            <button
              type="button"
              onClick={() => void requestMicrophone()}
              className="mt-6 rounded-full border border-white/45 px-5 py-2 text-xs font-semibold tracking-[0.2em] text-white transition hover:bg-white/10"
            >
              RETRY MICROPHONE
            </button>
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
    </>
  );
}
