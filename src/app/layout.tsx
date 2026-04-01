import type { Metadata } from "next";
import { Inter } from "next/font/google";
import { ServiceWorkerRegister } from "@/components/ServiceWorkerRegister";
import "./globals.css";

const inter = Inter({
  subsets: ["latin"],
  variable: "--font-sans",
  display: "swap",
});

export const metadata: Metadata = {
  title: "Kill Siri. Give birth to GIGI.",
  description:
    "GIGI is your voice assistant based on OpenClaw.ai. It replaces Siri and turns your phone into an autonomous AI agent.",
  keywords: ["gigi", "voice ai", "openclaw", "assistant", "siri alternative", "ai agent"],
  openGraph: {
    title: "Kill Siri. Give birth to GIGI.",
    description:
      "GIGI is your voice assistant based on OpenClaw.ai. It replaces Siri and turns your phone into an autonomous AI agent.",
    images: ["/gigi-logo.png"],
  },
  icons: {
    icon: "/gigi-logo.png",
    shortcut: "/gigi-logo.png",
    apple: "/gigi-logo.png",
  },
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en" className={inter.variable}>
      <body className="min-h-screen bg-black font-sans text-white antialiased">
        <ServiceWorkerRegister />
        {children}
      </body>
    </html>
  );
}
