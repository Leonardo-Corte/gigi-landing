import Link from "next/link";

export default function InstallPage() {
  return (
    <main className="min-h-screen bg-black px-4 py-16 text-white sm:px-6 lg:px-8">
      <div className="mx-auto max-w-3xl">
        <div className="rounded-3xl border border-white/15 bg-[linear-gradient(180deg,#111111_0%,#050505_100%)] p-8 shadow-[0_0_50px_rgba(255,255,255,0.08)] sm:p-10">
          <p className="text-xs font-semibold tracking-[0.35em] text-white/55">TOP SECRET DOSSIER</p>
          <h1 className="mt-4 text-4xl font-black leading-tight sm:text-5xl">
            Install the GIGI Profile
          </h1>
          <p className="mt-5 text-base text-white/75 sm:text-lg">
            Install the GIGI Profile to unlock full system control (FaceID, Wallet, Settings).
          </p>

          <div className="mt-8 rounded-2xl border border-white/10 bg-white/[0.03] p-5">
            <p className="text-sm text-white/70">
              This profile is delivered as an Apple configuration payload. iPhone will recognize it
              instantly and guide you through secure installation.
            </p>
            <ul className="mt-4 space-y-2 text-sm text-white/80">
              <li>Identity checks remain protected by FaceID / TouchID.</li>
              <li>You stay in control with explicit iOS confirmation screens.</li>
              <li>Remove anytime from Settings &gt; VPN &amp; Device Management.</li>
            </ul>
          </div>

          <div className="mt-10 flex flex-col gap-3 sm:flex-row sm:items-center">
            <a
              href="/api/install-profile"
              className="inline-flex items-center justify-center rounded-full bg-white px-8 py-4 text-sm font-extrabold tracking-wide text-black transition duration-200 hover:scale-105"
            >
              DOWNLOAD GIGI PROFILE
            </a>
            <Link
              href="/"
              className="inline-flex items-center justify-center rounded-full border border-white/30 px-6 py-4 text-sm font-semibold text-white/90 transition hover:bg-white/10"
            >
              Back to Command Center
            </Link>
          </div>
        </div>
      </div>
    </main>
  );
}
