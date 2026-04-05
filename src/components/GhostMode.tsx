"use client";

import React, { useEffect, useState, useRef } from 'react';
import { motion, AnimatePresence } from 'framer-motion';

export const GhostMode = () => {
    const [isVisible, setIsVisible] = useState(false);
    const [volume, setVolume] = useState(0);
    
    const audioContextRef = useRef<AudioContext | null>(null);
    const analyserRef = useRef<AnalyserNode | null>(null);
    const streamRef = useRef<MediaStream | null>(null);
    const animationFrameRef = useRef<number | null>(null);
    const silenceTimerRef = useRef<NodeJS.Timeout | null>(null);

    useEffect(() => {
        // Ascoltiamo il segnale che arriva da Swift
        const handleGigiWake = () => {
            console.log("React: Ricevuto segnale di risveglio GIGI!");
            setIsVisible(true);
            startListening();
        };

        window.addEventListener('OpenGigiGhostMode', handleGigiWake);
        return () => {
            window.removeEventListener('OpenGigiGhostMode', handleGigiWake);
        };
        // eslint-disable-next-line react-hooks/exhaustive-deps
    }, []);

    const hideBubble = () => {
        setIsVisible(false);
        stopListening();
        
        // Comunica a Swift di nascondere la finestra (animazione e isHidden = true)
        try {
            const win = window as any;
            if (win.webkit && win.webkit.messageHandlers && win.webkit.messageHandlers.LEE) {
                win.webkit.messageHandlers.LEE.postMessage(JSON.stringify({ action: 'hideBubble' }));
            }
        } catch (e) {
            console.error("Errore comunicazione con Swift:", e);
        }
    };

    const startListening = async () => {
        try {
            // Richiedi accesso al microfono
            const stream = await navigator.mediaDevices.getUserMedia({ audio: true });
            streamRef.current = stream;
            
            const AudioContextClass = window.AudioContext || (window as any).webkitAudioContext;
            const audioContext = new AudioContextClass();
            audioContextRef.current = audioContext;
            
            const analyser = audioContext.createAnalyser();
            analyser.fftSize = 256;
            analyserRef.current = analyser;
            
            const source = audioContext.createMediaStreamSource(stream);
            source.connect(analyser);
            
            const dataArray = new Uint8Array(analyser.frequencyBinCount);
            
            const updateVolume = () => {
                if (!analyserRef.current) return;
                
                analyserRef.current.getByteFrequencyData(dataArray);
                let sum = 0;
                for (let i = 0; i < dataArray.length; i++) {
                    sum += dataArray[i];
                }
                const average = sum / dataArray.length;
                
                // Normalizza il volume (0 - 1)
                const normalizedVolume = Math.min(average / 100, 1);
                setVolume(normalizedVolume);
                
                // Logica di rilevamento del silenzio
                if (normalizedVolume > 0.1) {
                    // C'è voce, resetta il timer di silenzio
                    if (silenceTimerRef.current) {
                        clearTimeout(silenceTimerRef.current);
                        silenceTimerRef.current = null;
                    }
                } else {
                    // Silenzio in corso, avvia il timer se non c'è già
                    if (!silenceTimerRef.current) {
                        silenceTimerRef.current = setTimeout(() => {
                            console.log("GIGI: Silenzio rilevato, nascondo la bolla.");
                            hideBubble();
                        }, 3000); // 3 secondi di silenzio per chiudere
                    }
                }
                
                animationFrameRef.current = requestAnimationFrame(updateVolume);
            };
            
            updateVolume();
            
        } catch (err) {
            console.error("Errore accesso microfono:", err);
            // Fallback: se non c'è microfono, chiudi la bolla dopo 5 secondi
            setTimeout(hideBubble, 5000);
        }
    };

    const stopListening = () => {
        if (animationFrameRef.current) {
            cancelAnimationFrame(animationFrameRef.current);
            animationFrameRef.current = null;
        }
        if (silenceTimerRef.current) {
            clearTimeout(silenceTimerRef.current);
            silenceTimerRef.current = null;
        }
        if (streamRef.current) {
            streamRef.current.getTracks().forEach(track => track.stop());
            streamRef.current = null;
        }
        if (audioContextRef.current) {
            audioContextRef.current.close();
            audioContextRef.current = null;
        }
    };

    // Pulisci tutto quando il componente viene smontato
    useEffect(() => {
        return () => {
            stopListening();
        };
    }, []);

    if (!isVisible) return null;

    // Calcola i valori dinamici basati sul volume (0-1)
    const scale = 1 + (volume * 0.15); // Scala da 1 a 1.15 per evitare di uscire troppo dai bordi
    const glowOpacity = 0.3 + (volume * 0.7); // Opacità da 0.3 a 1.0
    const glowSize = 10 + (volume * 40); // Dimensione da 10px a 50px

    return (
        <AnimatePresence>
            <motion.div
                className="w-full h-full flex items-center justify-center bg-transparent overflow-hidden rounded-full"
                initial={{ opacity: 0, scale: 0.5 }}
                animate={{ opacity: 1, scale: 1 }}
                exit={{ opacity: 0, scale: 0.5 }}
                transition={{ duration: 0.4, ease: "easeOut" }}
                onClick={hideBubble} // Chiudi al tocco manuale
            >
                {/* LA FACCIA DEL ROBOT GIGI - CERCHIO PERFETTO */}
                <motion.div
                    className="w-[90%] h-[90%] bg-pink-500 rounded-full flex items-center justify-center relative"
                    style={{
                        transform: `scale(${scale})`,
                        boxShadow: `0 0 ${glowSize}px rgba(236, 72, 153, ${glowOpacity})`,
                        transition: 'transform 0.1s ease-out, box-shadow 0.1s ease-out'
                    }}
                >
                    {/* Icona Placeholder GIGI */}
                    <span className="text-4xl relative z-10">🤖</span>
                    
                    {/* Inner Glow aggiuntivo per l'effetto pulsante */}
                    <div 
                        className="absolute inset-0 rounded-full mix-blend-overlay"
                        style={{
                            background: `radial-gradient(circle, rgba(255,255,255,${volume * 0.5}) 0%, transparent 70%)`,
                            transition: 'background 0.1s ease-out'
                        }}
                    />
                </motion.div>
            </motion.div>
        </AnimatePresence>
    );
};
