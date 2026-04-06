#!/usr/bin/env bash
# Firma S/MIME (PKCS#7 DER, contenuto incluso):
#   openssl smime -sign -in gigi_killer.mobileconfig -out public/gigi_killer.mobileconfig \
#     -signer <cert.pem> -inkey <key.pem> [-certfile chain.pem] -outform DER -nodetach -binary
# Default: gigi_ca/gigi_root.crt + gigi_root.key
# Certificato Apple/Developer (es. team): GIGI_SIGNER_CERT=... GIGI_SIGNER_KEY=...
# Catena opzionale: GIGI_SMIME_CERTFILE o gigi_ca/apple_chain.crt
set -euo pipefail
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"
SIGNER="${GIGI_SIGNER_CERT:-gigi_ca/gigi_root.crt}"
KEY="${GIGI_SIGNER_KEY:-gigi_ca/gigi_root.key}"
for f in gigi_killer.mobileconfig "$SIGNER" "$KEY"; do
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
  -signer "$SIGNER"
  -inkey "$KEY"
  -outform DER
  -nodetach
  -binary
)
[[ -n "$CHAIN" ]] && SMIME_ARGS+=( -certfile "$CHAIN" )

openssl "${SMIME_ARGS[@]}"

echo "OK: openssl smime -sign (-nodetach, DER) → $OUT ($(wc -c < "$OUT" | tr -d ' ') byte)"
[[ -z "$CHAIN" ]] && echo "Nota: per -certfile aggiungi gigi_ca/apple_chain.crt (PEM) o GIGI_SMIME_CERTFILE=/percorso/catena.pem"
