"use client";

import Image from "next/image";
import Link from "next/link";
import { motion } from "framer-motion";
import { useEffect, useState } from "react";
import { CheckCircle2, Lock } from "lucide-react";
import { SiriToGigiTransition } from "@/components/SiriToGigiTransition";
import { WaitlistForm } from "@/components/WaitlistForm";

const reveal = {
  hidden: { opacity: 0, y: 28 },
  visible: { opacity: 1, y: 0 },
};

const leftColumn = [
  "I can't do that",
  "Here's what I found on the web",
  "Try opening the app manually",
];

const rightColumn = ["I booked the table", "Email sent", "File moved to your PC"];
const COUNTDOWN_TARGET_ISO = "2026-04-13T23:59:59Z";

function CountdownRetro() {
  const targetTime = new Date(COUNTDOWN_TARGET_ISO).getTime();
  const [remainingMs, setRemainingMs] = useState(Math.max(targetTime - Date.now(), 0));

  useEffect(() => {
    const tick = () => {
      setRemainingMs(Math.max(targetTime - Date.now(), 0));
    };

    tick();
    const timer = window.setInterval(tick, 1000);
    return () => window.clearInterval(timer);
  }, [targetTime]);

  const days = Math.floor(remainingMs / (1000 * 60 * 60 * 24));
  const hours = Math.floor((remainingMs / (1000 * 60 * 60)) % 24);
  const minutes = Math.floor((remainingMs / (1000 * 60)) % 60);

  const items = [
    { label: "DAYS", value: String(days).padStart(2, "0") },
    { label: "HOURS", value: String(hours).padStart(2, "0") },
    { label: "MINUTES", value: String(minutes).padStart(2, "0") },
  ];

  return (
    <motion.div
      initial={{ opacity: 0, y: 18 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ duration: 0.6, ease: "easeOut" }}
      className="mx-auto mb-8 mt-2 w-full max-w-xl rounded-2xl border border-white/35 bg-[linear-gradient(180deg,#0d0d0d_0%,#000000_100%)] p-4 shadow-[0_0_24px_rgba(255,255,255,0.12)]"
    >
      <p className="mb-3 text-center text-xs font-bold tracking-[0.22em] text-white/80">
        avaible in...
      </p>
      <div className="grid grid-cols-3 gap-3">
        {items.map((item) => (
          <div
            key={item.label}
            className="rounded-xl border border-white/25 bg-black px-2 py-3 text-center"
          >
            <p className="font-mono text-3xl font-extrabold tracking-wider text-white sm:text-4xl">
              {item.value}
            </p>
            <p className="mt-1 text-[10px] font-semibold tracking-[0.2em] text-white/65 sm:text-xs">
              {item.label}
            </p>
          </div>
        ))}
      </div>
    </motion.div>
  );
}

function Reveal({ children, delay = 0 }: { children: React.ReactNode; delay?: number }) {
  return (
    <motion.div
      variants={reveal}
      initial="hidden"
      whileInView="visible"
      viewport={{ once: true, amount: 0.2 }}
      transition={{ duration: 0.7, ease: "easeOut", delay }}
    >
      {children}
    </motion.div>
  );
}

function scrollToWaitlist() {
  document.getElementById("waitlist")?.scrollIntoView({ behavior: "smooth", block: "start" });
}

export default function Home() {
  return (
    <div className="min-h-screen bg-[#000000] text-white">
      <header className="sticky top-0 z-50 border-b border-white/10 bg-black/80 backdrop-blur-xl">
        <div className="relative mx-auto flex h-16 max-w-6xl items-center justify-between px-4 sm:px-6 lg:px-8">
          <motion.div
            initial={{ opacity: 0, y: -10 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.6, ease: "easeOut" }}
          >
            <Link href="/" className="flex items-center gap-3">
              <Image src="/gigi-logo.png" alt="GIGI Logo" width={120} height={40} className="h-10 w-auto" />
            </Link>
          </motion.div>
          <p className="pointer-events-none absolute left-1/2 -translate-x-1/2 text-sm font-bold tracking-[0.32em] text-white/90">
            GIGI
          </p>
          <button
            type="button"
            onClick={scrollToWaitlist}
            className="rounded-full bg-white px-5 py-2 text-sm font-semibold text-black transition duration-200 hover:scale-105"
            aria-label="Kill Siri: scorri al form per lasciare la tua email"
          >
            Kill Siri
          </button>
        </div>
      </header>

      <main>
        <section className="px-4 pb-20 pt-14 sm:px-6 lg:px-8 lg:pt-24">
          <div className="mx-auto max-w-6xl text-center">
            <CountdownRetro />

            <motion.h1
              initial={{ opacity: 0, y: 22 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ duration: 0.8, ease: "easeOut" }}
              className="text-5xl font-extrabold leading-tight sm:text-6xl lg:text-7xl"
            >
              Kill Siri. Give birth to GIGI.
            </motion.h1>

            <motion.p
              initial={{ opacity: 0, y: 22 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ duration: 0.8, delay: 0.1, ease: "easeOut" }}
              className="mx-auto mt-6 max-w-3xl text-base text-white/70 sm:text-lg"
            >
              GIGI is your voice assistant based on OpenClaw.ai. It replaces Siri and turns your
              phone into an autonomous AI agent.
            </motion.p>

            <SiriToGigiTransition />

            <motion.div
              initial={{ opacity: 0, y: 22 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ duration: 0.8, delay: 0.25, ease: "easeOut" }}
              className="mt-10"
            >
              <button
                type="button"
                onClick={scrollToWaitlist}
                className="inline-flex rounded-full bg-white px-9 py-4 text-sm font-extrabold tracking-wide text-black transition duration-200 hover:scale-105"
                aria-label="Scorri al form per lasciare la tua email"
              >
                JOIN THE RESISTANCE
              </button>
            </motion.div>
          </div>
        </section>

        <section className="border-y border-white/10 px-4 py-20 sm:px-6 lg:px-8">
          <div className="mx-auto max-w-6xl">
            <Reveal>
              <h2 className="text-center text-3xl font-semibold text-white sm:text-4xl">
                Siri (The Past) vs GIGI (The Future)
              </h2>
            </Reveal>
            <div className="mt-10 grid gap-5 md:grid-cols-2">
              <Reveal>
                <article className="rounded-2xl border border-red-500/35 bg-red-500/10 p-6">
                  <p className="mb-5 text-sm uppercase tracking-[0.2em] text-red-300">Siri (The Past)</p>
                  <ul className="space-y-4">
                    {leftColumn.map((item) => (
                      <li key={item} className="flex items-start gap-3 text-red-200/90">
                        <Lock size={18} className="mt-0.5 shrink-0 text-red-300/80" />
                        <span>{item}</span>
                      </li>
                    ))}
                  </ul>
                </article>
              </Reveal>

              <Reveal delay={0.1}>
                <article className="rounded-2xl border border-white/15 bg-white/[0.03] p-6">
                  <p className="mb-5 text-sm uppercase tracking-[0.2em] text-white">GIGI (The Future)</p>
                  <ul className="space-y-4">
                    {rightColumn.map((item) => (
                      <li key={item} className="flex items-start gap-3 text-white">
                        <CheckCircle2 size={18} className="mt-0.5 shrink-0 text-white" />
                        <span>{item}</span>
                      </li>
                    ))}
                  </ul>
                </article>
              </Reveal>
            </div>
          </div>
        </section>

        <section id="waitlist" className="scroll-mt-24 px-4 py-20 sm:px-6 lg:px-8 lg:scroll-mt-28">
          <div className="mx-auto max-w-2xl text-center">
            <Reveal>
              <h2 className="text-3xl font-semibold text-white sm:text-4xl">Get Early Access</h2>
            </Reveal>
            <Reveal delay={0.1}>
              <p className="mt-4 text-white/70">The next interface does not answer. It acts.</p>
            </Reveal>
            <Reveal delay={0.16}>
              <WaitlistForm />
            </Reveal>
          </div>
        </section>
      </main>
    </div>
  );
}
