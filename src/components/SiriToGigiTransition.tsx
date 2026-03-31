"use client";

import Image from "next/image";
import { motion } from "framer-motion";
import { useMemo, useState } from "react";

type Shard = {
  id: number;
  x: number;
  y: number;
  size: number;
  delay: number;
  rotate: number;
};

export function SiriToGigiTransition() {
  const [shattered, setShattered] = useState(false);
  const [showDead, setShowDead] = useState(false);
  const [showRobot, setShowRobot] = useState(false);

  const shards = useMemo<Shard[]>(
    () =>
      Array.from({ length: 1000 }, (_, i) => {
        const angle = (i / 1000) * Math.PI * 2;
        const radius = 90 + (i % 15) * 12;
        return {
          id: i,
          x: Math.cos(angle) * radius,
          y: Math.sin(angle) * radius,
          size: 1 + (i % 3),
          delay: (i % 40) * 0.004,
          rotate: 80 + (i % 10) * 36,
        };
      }),
    []
  );

  const triggerShatter = () => {
    if (!shattered) {
      setShattered(true);
      window.setTimeout(() => setShowDead(true), 600);
      window.setTimeout(() => setShowDead(false), 1250);
      window.setTimeout(() => setShowRobot(true), 1300);
    }
  };

  const shardPalette = ["#7df9ff", "#8f7bff", "#59b5ff", "#db8bff", "#ffffff"];

  return (
    <div className="relative mx-auto mt-10 flex h-64 w-64 items-center justify-center sm:h-72 sm:w-72">
      <motion.button
        type="button"
        aria-label="Transform Siri into GIGI"
        onHoverStart={() => triggerShatter()}
        onClick={() => triggerShatter()}
        onPointerDown={() => triggerShatter()}
        className="relative flex h-full w-full items-center justify-center touch-manipulation"
      >
        <motion.div
          className="relative z-10 flex items-center justify-center"
          initial={{ opacity: 0, scale: 0.72 }}
          animate={showRobot ? { opacity: 1, scale: [1, 1.025, 1] } : { opacity: 0, scale: 0.72 }}
          transition={{
            opacity: { duration: 0.4, delay: 0.04 },
            scale: {
              duration: 2.6,
              ease: "easeInOut",
              repeat: showRobot ? Number.POSITIVE_INFINITY : 0,
            },
          }}
        >
          <Image
            src="/gigi-logo.png"
            alt="GIGI revealed logo"
            width={240}
            height={240}
            className="h-44 w-44 rounded-2xl object-cover sm:h-52 sm:w-52"
            priority
          />
          <motion.span
            className="pointer-events-none absolute h-24 w-24 rounded-full bg-white/45 blur-2xl"
            animate={
              showRobot
                ? { opacity: [0.15, 0.52, 0.15], scale: [0.9, 1.15, 0.9] }
                : { opacity: 0, scale: 0.8 }
            }
            transition={{
              duration: 1.8,
              ease: "easeInOut",
              repeat: showRobot ? Number.POSITIVE_INFINITY : 0,
            }}
          />
        </motion.div>

        <motion.div
          className="pointer-events-none absolute z-50 select-none text-5xl font-black tracking-[0.18em] text-white sm:text-6xl"
          initial={{ opacity: 0, scale: 0.82 }}
          animate={showDead ? { opacity: [0, 1, 1, 0], scale: [0.82, 1.08, 1.02, 1] } : { opacity: 0 }}
          transition={{ duration: 0.85, ease: "easeOut" }}
        >
          DEAD
        </motion.div>

        <motion.div
          className="absolute z-30 h-44 w-44 rounded-full bg-[conic-gradient(from_90deg,#8e78ff,#58bbff,#72f6ff,#cf88ff,#8e78ff)] blur-[1px] sm:h-52 sm:w-52"
          animate={
            shattered
              ? { scale: [1, 0.84, 0.72], opacity: [0.95, 0.35, 0], rotate: [0, 16, 24] }
              : { scale: [1, 1.1, 1], opacity: [0.88, 1, 0.88], rotate: [0, 12, 0] }
          }
          transition={{
            duration: shattered ? 0.5 : 2.3,
            repeat: shattered ? 0 : Number.POSITIVE_INFINITY,
            ease: shattered ? "easeOut" : "easeInOut",
          }}
        />
        <motion.div
          className="absolute z-30 h-34 w-34 rounded-full bg-[radial-gradient(circle_at_30%_25%,#ffffff_0%,#bca0ff_25%,#6ec9ff_58%,#0e0f2c_100%)] sm:h-40 sm:w-40"
          animate={
            shattered
              ? { scale: [1, 0.8, 0.62], opacity: [1, 0.3, 0] }
              : { scale: [1, 1.08, 1], opacity: [0.9, 1, 0.9] }
          }
          transition={{
            duration: shattered ? 0.45 : 1.6,
            repeat: shattered ? 0 : Number.POSITIVE_INFINITY,
            ease: "easeInOut",
          }}
        />
        <motion.div
          className="absolute z-20 h-52 w-52 rounded-full border border-white/35 sm:h-60 sm:w-60"
          animate={
            shattered
              ? { scale: [1, 1.25, 1.45], opacity: [0.45, 0.2, 0] }
              : { scale: [1, 1.16, 1.3], opacity: [0.45, 0.2, 0] }
          }
          transition={{
            duration: shattered ? 0.7 : 1.95,
            repeat: shattered ? 0 : Number.POSITIVE_INFINITY,
            ease: "easeOut",
          }}
        />
        <motion.div
          className="absolute z-20 h-60 w-60 rounded-full bg-[#90e0ff]/20 blur-3xl sm:h-64 sm:w-64"
          animate={
            shattered
              ? { opacity: [0.45, 0.75, 0], scale: [1, 1.18, 1.3] }
              : { opacity: [0.35, 0.65, 0.35], scale: [0.95, 1.08, 0.95] }
          }
          transition={{
            duration: shattered ? 0.65 : 2.4,
            repeat: shattered ? 0 : Number.POSITIVE_INFINITY,
            ease: "easeInOut",
          }}
        />

        {shards.map((shard) => (
          <motion.span
            key={shard.id}
            className="absolute z-40 rounded-sm"
            style={{ width: shard.size, height: shard.size }}
            initial={{ x: 0, y: 0, opacity: 0, rotate: 0, scale: 0.4 }}
            animate={
              shattered
                ? {
                    x: shard.x,
                    y: shard.y,
                    opacity: 0,
                    rotate: shard.rotate,
                    scale: [1.1, 0.7, 0.15],
                    backgroundColor: shardPalette[shard.id % shardPalette.length],
                  }
                : {
                    x: 0,
                    y: 0,
                    opacity: 0,
                    rotate: 0,
                    scale: 0.4,
                    backgroundColor: shardPalette[shard.id % shardPalette.length],
                  }
            }
            transition={{
              duration: 1.1,
              delay: shard.delay,
              ease: [0.16, 0.9, 0.24, 1],
            }}
          />
        ))}

        <motion.div
          className="pointer-events-none absolute z-30 rounded-full bg-[#7ec8ff]/45 blur-2xl"
          animate={
            shattered
              ? { width: [110, 160, 120], height: [110, 160, 120], opacity: [0.55, 0.95, 0] }
              : { width: 0, height: 0, opacity: 0 }
          }
          transition={{
            duration: 0.75,
            ease: "easeOut",
          }}
        />
      </motion.button>
    </div>
  );
}
