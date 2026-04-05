"use client";

import React, { useEffect, useState, useRef } from "react";

export function GhostMode() {
  const [isVisible, setIsVisible] = useState(false);
  const [volume, setVolume] = useState(0);

  const audioContextRef = useRef<AudioContext | null>(null);
  const analyserRef = useRef<AnalyserNode | null>(null);
  const streamRef = useRef<MediaStream | null>(null);
  const animationFrameRef = useRef<number | null>(null);
  const silenceTimerRef = useRef<ReturnType<typeof setTimeout> | null>(null);

  useEffect(() => {
    const handleGigiWake = () => {
      setIsVisible(true);
      void startListening();
    };
    window.addEventListener("OpenGigiGhostMode", handleGigiWake);
    return () => window.removeEventListener("OpenGigiGhostMode", handleGigiWake);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  const hideBubble = () => {
    setIsVisible(false);
    stopListening();
    try {
      const win = window as Window & {
        webkit?: { messageHandlers?: { GigiBridge?: { postMessage: (s: string) => void } } };
      };
      win.webkit?.messageHandlers?.GigiBridge?.postMessage(
        JSON.stringify({ action: "hideBubble" })
      );
    } catch {
      /* native bridge unavailable */
    }
  };

  const startListening = async () => {
    try {
      const stream = await navigator.mediaDevices.getUserMedia({ audio: true });
      streamRef.current = stream;
      const Ctx = window.AudioContext || (window as Window & { webkitAudioContext?: typeof AudioContext }).webkitAudioContext;
      if (!Ctx) return;
      const audioContext = new Ctx();
      audioContextRef.current = audioContext;
      const analyser = audioContext.createAnalyser();
      analyser.fftSize = 256;
      analyserRef.current = analyser;
      audioContext.createMediaStreamSource(stream).connect(analyser);
      const dataArray = new Uint8Array(analyser.frequencyBinCount);

      const tick = () => {
        if (!analyserRef.current) return;
        analyserRef.current.getByteFrequencyData(dataArray);
        let sum = 0;
        for (let i = 0; i < dataArray.length; i++) sum += dataArray[i];
        const avg = sum / dataArray.length;
        const normalized = Math.min(avg / 100, 1);
        setVolume(normalized);

        if (normalized > 0.1) {
          if (silenceTimerRef.current) {
            clearTimeout(silenceTimerRef.current);
            silenceTimerRef.current = null;
          }
        } else if (!silenceTimerRef.current) {
          silenceTimerRef.current = setTimeout(() => hideBubble(), 3000);
        }
        animationFrameRef.current = requestAnimationFrame(tick);
      };
      tick();
    } catch {
      setTimeout(() => hideBubble(), 5000);
    }
  };

  const stopListening = () => {
    if (animationFrameRef.current != null) {
      cancelAnimationFrame(animationFrameRef.current);
      animationFrameRef.current = null;
    }
    if (silenceTimerRef.current) {
      clearTimeout(silenceTimerRef.current);
      silenceTimerRef.current = null;
    }
    streamRef.current?.getTracks().forEach((t) => t.stop());
    streamRef.current = null;
    void audioContextRef.current?.close();
    audioContextRef.current = null;
  };

  useEffect(() => () => stopListening(), []);

  if (!isVisible) return null;

  const scale = 1 + volume * 0.15;
  const glowOpacity = 0.3 + volume * 0.7;
  const glowSize = 10 + volume * 40;

  return (
    <div
      className="gigi-ghost-root flex h-full w-full items-center justify-center overflow-hidden rounded-full bg-transparent"
      onClick={hideBubble}
      role="presentation"
    >
      <div
        className="gigi-ghost-core relative flex h-[90%] w-[90%] items-center justify-center rounded-full bg-pink-500"
        style={{
          transform: `scale(${scale})`,
          boxShadow: `0 0 ${glowSize}px rgba(236, 72, 153, ${glowOpacity})`,
          transition: "transform 0.1s ease-out, box-shadow 0.1s ease-out",
        }}
      >
        <span className="relative z-10 text-4xl" aria-hidden>
          🤖
        </span>
        <div
          className="pointer-events-none absolute inset-0 rounded-full mix-blend-overlay"
          style={{
            background: `radial-gradient(circle, rgba(255,255,255,${volume * 0.5}) 0%, transparent 70%)`,
            transition: "background 0.1s ease-out",
          }}
        />
      </div>
    </div>
  );
}
