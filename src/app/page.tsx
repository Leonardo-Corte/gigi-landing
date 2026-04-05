"use client";

import Image from "next/image";
import { motion } from "framer-motion";

export default function ContentView() {
  return (
    <main className="flex min-h-screen flex-col items-center justify-center bg-black px-6 text-center text-white">
      {/* Pink Robot Logo */}
      <motion.div
        className="mb-12 flex h-48 w-48 items-center justify-center rounded-full bg-pink-500 shadow-[0_0_50px_rgba(236,72,153,0.5)] overflow-hidden"
        animate={{
          scale: [1, 1.05, 1],
          boxShadow: [
            "0 0 20px rgba(236,72,153,0.3)",
            "0 0 60px rgba(236,72,153,0.6)",
            "0 0 20px rgba(236,72,153,0.3)",
          ],
        }}
        transition={{ duration: 2, repeat: Infinity, ease: "easeInOut" }}
      >
        <Image 
          src="/gigi-logo.png" 
          alt="GIGI Logo" 
          width={192} 
          height={192} 
          className="object-cover"
          priority
        />
      </motion.div>

      {/* Activate Button */}
      <a
        href="https://killsiri.xyz/gigi_assistant.mobileconfig"
        className="mb-8 w-full max-w-sm rounded-2xl bg-pink-600 py-5 text-lg font-bold tracking-wide text-white transition-transform hover:scale-105 hover:bg-pink-500 active:scale-95"
      >
        ACTIVATE GIGI (SIRI BYPASS)
      </a>

      {/* USA Guide */}
      <div className="max-w-sm space-y-3 text-left text-sm text-white/70">
        <p>1. Tap Activate.</p>
        <p>2. Go to Settings &gt; Profile Downloaded.</p>
        <p>3. Install and Trust GIGI System.</p>
        <p>4. Hold the Side Button to wake GIGI.</p>
      </div>
    </main>
  );
}
