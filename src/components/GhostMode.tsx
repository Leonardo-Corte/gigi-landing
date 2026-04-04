"use client";

import React, { useEffect, useState } from 'react';
import { motion, AnimatePresence } from 'framer-motion';

export const GhostMode = () => {
    const [isVisible, setIsVisible] = useState(false);

    useEffect(() => {
        // Ascoltiamo il segnale che arriva da Swift
        const handleGigiWake = () => {
            console.log("React: Ricevuto segnale di risveglio GIGI!");
            setIsVisible(true);
        };

        window.addEventListener('OpenGigiGhostMode', handleGigiWake);
        return () => window.removeEventListener('OpenGigiGhostMode', handleGigiWake);
    }, []);

    if (!isVisible) return null;

    return (
        <AnimatePresence>
            <motion.div
                className="fixed inset-0 z-[9999] bg-black/60 backdrop-blur-md flex flex-col items-center justify-center"
                initial={{ opacity: 0 }}
                animate={{ opacity: 1 }}
                exit={{ opacity: 0 }}
                onClick={() => setIsVisible(false)} // Chiudi al tocco per ora
            >
                {/* LA FACCIA DEL ROBOT GIGI */}
                <motion.div
                    className="w-48 h-48 bg-pink-500 rounded-full flex items-center justify-center shadow-[0_0_50px_rgba(236,72,153,0.5)]"
                    animate={{
                        scale: [1, 1.05, 1],
                        boxShadow: [
                            "0_0_20px_rgba(236,72,153,0.3)",
                            "0_0_60px_rgba(236,72,153,0.6)",
                            "0_0_20px_rgba(236,72,153,0.3)"
                        ]
                    }}
                    transition={{ duration: 2, repeat: Infinity, ease: "easeInOut" }}
                >
                    {/* Qui metteremo l'SVG della faccia del robot. Per ora mettiamo un'icona placeholder */}
                    <span className="text-6xl">🤖</span>
                </motion.div>

                <motion.p
                    className="mt-8 text-pink-400 font-mono tracking-widest text-lg"
                    animate={{ opacity: [0.4, 1, 0.4] }}
                    transition={{ duration: 1.5, repeat: Infinity }}
                >
                    GIGI IS LISTENING...
                </motion.p>
            </motion.div>
        </AnimatePresence>
    );
};
