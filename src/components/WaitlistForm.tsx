"use client";

import { FormEvent, useState } from "react";

export function WaitlistForm() {
  const [email, setEmail] = useState("");
  const [isSending, setIsSending] = useState(false);
  const [message, setMessage] = useState("");
  const [status, setStatus] = useState<"idle" | "success" | "error">("idle");

  const onSubmit = async (e: FormEvent<HTMLFormElement>) => {
    e.preventDefault();
    if (!email.trim() || isSending) {
      return;
    }

    setIsSending(true);
    setMessage("");
    setStatus("idle");

    try {
      const response = await fetch("/api/waitlist", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ email: email.trim() }),
      });

      const payload = (await response.json()) as { error?: string; code?: string | null };

      if (response.ok) {
        setStatus("success");
        setMessage("Welcome to the revolution. GIGI will contact you soon.");
        setEmail("");
        setIsSending(false);
        return;
      }

      const errorCode = payload.code ?? "";
      const errorMessage = (payload.error ?? "").toLowerCase();
      const isDuplicate =
        errorCode === "23505" ||
        errorMessage.includes("duplicate") ||
        errorMessage.includes("already exists") ||
        errorMessage.includes("unique constraint");

      if (isDuplicate) {
        setStatus("error");
        setMessage("You're already part of the resistance!");
      } else if (errorCode === "PGRST205") {
        setStatus("error");
        setMessage("Waitlist table not found. Check the Supabase table name.");
      } else if (errorCode === "42501") {
        setStatus("error");
        setMessage("Insert blocked by Supabase RLS policy. Enable insert for anon.");
      } else {
        setStatus("error");
        setMessage(payload.error ? `Something went wrong. (${payload.error})` : "Something went wrong.");
      }
      setIsSending(false);
    } catch (err) {
      const fallbackMessage = err instanceof Error ? err.message : "Unexpected client error";
      setStatus("error");
      setMessage(`Something went wrong. (${fallbackMessage})`);
      setIsSending(false);
    }
  };

  return (
    <div className="mt-10">
      <form className="flex flex-col gap-3 sm:flex-row sm:justify-center" onSubmit={onSubmit}>
        <label htmlFor="email" className="sr-only">
          Email
        </label>
        <input
          id="email"
          name="email"
          type="email"
          required
          placeholder="you@company.com"
          autoComplete="email"
          value={email}
          onChange={(e) => setEmail(e.target.value)}
          disabled={isSending}
          className="min-h-12 w-full rounded-full border border-white/20 bg-white/[0.05] px-5 text-sm text-white placeholder:text-white/40 outline-none transition focus:border-white/70 focus:ring-2 focus:ring-white/30 disabled:cursor-not-allowed disabled:opacity-70 sm:max-w-sm"
        />
        <button
          type="submit"
          disabled={isSending}
          className="min-h-12 rounded-full bg-white px-7 text-sm font-semibold text-black transition duration-200 hover:scale-105 disabled:cursor-not-allowed disabled:opacity-70"
        >
          {isSending ? "Sending..." : "JOIN THE RESISTANCE"}
        </button>
      </form>
      {message && (
        <p className={`mt-4 text-sm ${status === "success" ? "text-[#9fd2ff]" : "text-white/80"}`}>
          {message}
        </p>
      )}
    </div>
  );
}
