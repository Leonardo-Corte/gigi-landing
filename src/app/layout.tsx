import type { Metadata } from "next";
import { GhostMode } from "@/components/GhostMode";
import "./globals.css";

export const metadata: Metadata = {
  title: "GIGI",
  description: "Voice shell",
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en">
      <body className="min-h-screen bg-transparent text-white antialiased">
        {children}
        <GhostMode />
      </body>
    </html>
  );
}
