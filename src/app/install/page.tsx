import Link from "next/link";
import { InstallShell } from "@/components/InstallShell";

export default function InstallPage() {
  return (
    <InstallShell>
      <h1 className="text-3xl font-bold uppercase tracking-widest text-red-500">GIGI — Layer Zero</h1>
      <p className="text-sm text-white/50">Installazione profilo di configurazione</p>

      <div className="mt-8 space-y-4 rounded-xl border border-zinc-800 bg-zinc-900 p-6">
        <h2 className="text-xl font-semibold">Profilo MDM</h2>
        <p className="text-xs text-white/60">
          Scarica e installa <code className="text-white/80">gigi_killer.mobileconfig</code> da Impostazioni →
          Profilo scaricato.
        </p>
        <a
          href="/gigi_killer.mobileconfig"
          download
          className="block w-full rounded-lg bg-zinc-800 py-3 font-medium text-white transition-colors hover:bg-zinc-700"
        >
          Scarica profilo
        </a>
      </div>

      <p className="pt-8 text-xs text-white/40">
        File sorgente in root repo: <code className="text-white/60">gigi_killer.mobileconfig</code>
      </p>

      <Link href="/" className="text-xs text-white/40 hover:text-white/80">
        ← Home
      </Link>
    </InstallShell>
  );
}
