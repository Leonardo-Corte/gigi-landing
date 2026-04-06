import type { Metadata } from "next";
import "./globals.css";

export const metadata: Metadata = {
  title: "GIGI",
  description: "Layer Zero — profile install",
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="it">
      <body className="min-h-screen bg-black text-white antialiased">{children}</body>
    </html>
  );
}
