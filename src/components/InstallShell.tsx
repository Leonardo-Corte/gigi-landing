import type { ReactNode } from "react";

/** Contenitore UI minimo per la pagina di installazione profilo (Layer Zero). */
export function InstallShell({ children }: { children: ReactNode }) {
  return (
    <main className="flex min-h-screen flex-col items-center justify-center bg-black px-4 text-white">
      <div className="w-full max-w-md space-y-8 text-center">{children}</div>
    </main>
  );
}
