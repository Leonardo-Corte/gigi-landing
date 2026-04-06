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
          Il download è il profilo <strong className="text-white/80">firmato CMS</strong> (PKCS#7) con{" "}
          <code className="text-white/80">gigi_root.key</code> / <code className="text-white/80">gigi_root.crt</code> —
          così iOS mostra il trust sul firmatario. Installa da Impostazioni → Profilo scaricato.
        </p>
        <a
          href="/gigi_killer.mobileconfig"
          download
          className="block w-full rounded-lg bg-zinc-800 py-3 font-medium text-white transition-colors hover:bg-zinc-700"
        >
          Scarica profilo
        </a>
      </div>

      <div className="mt-6 space-y-4 rounded-xl border border-zinc-800 bg-zinc-900 p-6">
        <h2 className="text-xl font-semibold">App (OTA)</h2>
        <p className="text-xs text-white/60">
          iOS legge <code className="text-white/80">/manifest.plist</code> e scarica l&apos;IPA dall&apos;URL indicato (oggi{" "}
          <code className="text-white/80">gigi_app.ipa</code>). Aggiungi l&apos;IPA in <code className="text-white/80">public/</code> se serve l&apos;OTA.
        </p>
        <a
          href="itms-services://?action=download-manifest&url=https://killsiri.xyz/manifest.plist"
          className="block w-full rounded-lg bg-red-600 py-3 font-medium text-white transition-colors hover:bg-red-500"
        >
          INSTALLA GIGI
        </a>
      </div>

      <p className="pt-8 text-xs text-white/40">
        Sorgente XML (unsigned): <code className="text-white/60">gigi_killer.mobileconfig</code> in root. Firma:{" "}
        <code className="text-white/60">npm run sign-profile</code> → <code className="text-white/60">public/</code>.
      </p>

      <Link href="/" className="text-xs text-white/40 hover:text-white/80">
        ← Home
      </Link>
    </InstallShell>
  );
}
