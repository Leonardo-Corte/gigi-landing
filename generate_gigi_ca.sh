#!/usr/bin/env bash
#
# GIGI Root CA + profile signing certificate (OpenSSL).
# Usage: ./generate_gigi_ca.sh [output_directory]
# Default output: ./gigi_ca
#
set -euo pipefail

OUT="${1:-./gigi_ca}"
ROOT_DAYS=3650
PROFILE_DAYS=3650

mkdir -p "$OUT"
cd "$OUT"

echo "==> Output directory: $(pwd)"

# --- 1) GIGI Root CA: RSA 4096 private key ---
if [[ -f gigi_root.key ]]; then
  echo "WARNING: gigi_root.key already exists. Remove it first or use a different output directory." >&2
  exit 1
fi

openssl genrsa -out gigi_root.key 4096
chmod 600 gigi_root.key

# --- 2) Self-signed Root certificate (10 years), CN = GIGI System Authority ---
openssl req -new -x509 \
  -key gigi_root.key \
  -sha256 \
  -days "$ROOT_DAYS" \
  -subj "/CN=GIGI System Authority/O=GIGI/C=US" \
  -out gigi_root.pem

# --- 3) DER .cer (install on iPhone / trust store) ---
openssl x509 -in gigi_root.pem -outform DER -out gigi_root.cer

# --- 4) Profile signing key + cert issued by Root (for signing .mobileconfig) ---
openssl genrsa -out gigi_profile_signer.key 4096
chmod 600 gigi_profile_signer.key

openssl req -new \
  -key gigi_profile_signer.key \
  -subj "/CN=GIGI Profile Signing/O=GIGI/C=US" \
  -out gigi_profile_signer.csr

EXTFILE="$(mktemp)"
trap 'rm -f "$EXTFILE"' EXIT

cat > "$EXTFILE" <<'EOF'
[ profile_sign ]
basicConstraints = CA:FALSE
keyUsage = critical, digitalSignature, keyEncipherment
extendedKeyUsage = codeSigning
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid,issuer:always
EOF

openssl x509 -req \
  -in gigi_profile_signer.csr \
  -CA gigi_root.pem \
  -CAkey gigi_root.key \
  -CAcreateserial \
  -days "$PROFILE_DAYS" \
  -sha256 \
  -extfile "$EXTFILE" \
  -extensions profile_sign \
  -out gigi_profile_signer.pem

# Optional: PKCS#7 chain bundle (Root + signer) for tools that need a chain
cat gigi_profile_signer.pem gigi_root.pem > gigi_profile_chain.pem

echo ""
echo "Done."
echo "  Root private key:           $(pwd)/gigi_root.key"
echo "  Root certificate (PEM):     $(pwd)/gigi_root.pem   (server / tooling)"
echo "  Root certificate (DER):     $(pwd)/gigi_root.cer   (iPhone / install profile)"
echo "  Profile signer private key: $(pwd)/gigi_profile_signer.key"
echo "  Profile signer cert (PEM): $(pwd)/gigi_profile_signer.pem"
echo "  Chain (signer + root):      $(pwd)/gigi_profile_chain.pem"
echo "  CSR (optional archive):     $(pwd)/gigi_profile_signer.csr"
echo ""
echo "Keep *.key files secret. Do not commit them."
