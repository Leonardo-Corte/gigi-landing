#!/usr/bin/env bash
# Firma S/MIME (PKCS#7 DER, contenuto incluso) con: openssl smime -sign -nodetach -outform DER
# Firmatario: gigi_ca/gigi_root.crt + gigi_root.key
# Opzionale -certfile: PEM con catena aggiuntiva (es. Apple WWDR). Imposta GIGI_SMIME_CERTFILE
# oppure crea gigi_ca/apple_chain.crt (non committato se preferisci).
set -euo pipefail
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"
for f in gigi_killer.mobileconfig gigi_ca/gigi_root.crt gigi_ca/gigi_root.key; do
  [[ -f "$f" ]] || { echo "Manca: $f" >&2; exit 1; }
done
OUT="${REPO}/public/gigi_killer.mobileconfig"
rm -f "$OUT"

CHAIN=""
[[ -n "${GIGI_SMIME_CERTFILE:-}" ]] && CHAIN="${GIGI_SMIME_CERTFILE}"
if [[ -z "$CHAIN" && -f "$REPO/gigi_ca/apple_chain.crt" ]]; then
  CHAIN="$REPO/gigi_ca/apple_chain.crt"
fi
if [[ -n "$CHAIN" && ! -f "$CHAIN" ]]; then
  echo "Catena PEM non trovata: $CHAIN" >&2
  exit 1
fi

SMIME_ARGS=(
  smime -sign
  -in gigi_killer.mobileconfig
  -out "$OUT"
  -signer gigi_ca/gigi_root.crt
  -inkey gigi_ca/gigi_root.key
  -outform DER
  -nodetach
  -binary
)
[[ -n "$CHAIN" ]] && SMIME_ARGS+=( -certfile "$CHAIN" )

openssl "${SMIME_ARGS[@]}"

echo "OK: openssl smime -sign (-nodetach, DER) → $OUT ($(wc -c < "$OUT" | tr -d ' ') byte)"
[[ -z "$CHAIN" ]] && echo "Nota: per -certfile aggiungi gigi_ca/apple_chain.crt (PEM) o GIGI_SMIME_CERTFILE=/percorso/catena.pem"
