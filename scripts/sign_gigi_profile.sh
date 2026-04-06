#!/usr/bin/env bash
# Firma PKCS#7 (CMS/DER) di gigi_killer.mobileconfig con la coppia gigi_root.crt + gigi_root.key.
# iOS mostra il profilo come firmato; per “Verificato” il certificato deve essere attendibile sul device.
set -euo pipefail
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"
for f in gigi_killer.mobileconfig gigi_ca/gigi_root.crt gigi_ca/gigi_root.key; do
  [[ -f "$f" ]] || { echo "Manca: $f" >&2; exit 1; }
done
OUT="${REPO}/public/gigi_killer.mobileconfig"
rm -f "$OUT"
# Niente -certfile se signer è la stessa root self-signed (OpenSSL 3: "certificate already present" su Vercel).
openssl cms -sign \
  -in gigi_killer.mobileconfig \
  -signer gigi_ca/gigi_root.crt \
  -inkey gigi_ca/gigi_root.key \
  -outform DER \
  -out "$OUT" \
  -nodetach -binary
echo "OK: firmato CMS → $OUT ($(wc -c < "$OUT" | tr -d ' ') byte DER)"
