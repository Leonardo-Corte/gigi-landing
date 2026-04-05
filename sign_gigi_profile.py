#!/usr/bin/env python3
"""
Sign a GIGI .mobileconfig with CMS/PKCS#7 (DER) using the profile signer from generate_gigi_ca.sh.

Requires OpenSSL 1.1+ with `openssl cms` (OpenSSL 3 recommended).

iOS shows the profile as signed when the PKCS#7 signature verifies. For "Verificato" / trusted
publisher, the signing certificate (or its issuing Root CA) must be trusted on the device
— typically by installing the Root CA from the same CA bundle or an earlier profile step.
"""

from __future__ import annotations

import argparse
import subprocess
import sys
from pathlib import Path


def main() -> int:
    repo_root = Path(__file__).resolve().parent

    parser = argparse.ArgumentParser(
        description="Sign gigi_assistant.mobileconfig (CMS DER) → gigi_signed.mobileconfig"
    )
    parser.add_argument(
        "--input",
        type=Path,
        default=repo_root / "public" / "gigi_assistant.mobileconfig",
        help="Unsigned .mobileconfig (XML plist)",
    )
    parser.add_argument(
        "--key",
        type=Path,
        default=repo_root / "gigi_ca" / "gigi_profile_signer.key",
        help="Profile signer private key (from generate_gigi_ca.sh)",
    )
    parser.add_argument(
        "--cert",
        type=Path,
        default=repo_root / "gigi_ca" / "gigi_profile_signer.pem",
        help="Profile signer certificate (PEM)",
    )
    parser.add_argument(
        "--chain",
        type=Path,
        default=repo_root / "gigi_ca" / "gigi_root.pem",
        help="Root CA certificate (PEM) to embed in PKCS#7 for chain verification",
    )
    parser.add_argument(
        "--output",
        type=Path,
        default=repo_root / "public" / "gigi_signed.mobileconfig",
        help="Output signed profile (DER-encoded CMS)",
    )
    parser.add_argument(
        "--openssl",
        default="openssl",
        help="OpenSSL binary path",
    )
    args = parser.parse_args()

    for label, p in ("--input", args.input), ("--key", args.key), ("--cert", args.cert):
        if not p.is_file():
            print(f"error: {label} not found: {p}", file=sys.stderr)
            return 1

    if not args.chain.is_file():
        print(f"warning: --chain not found ({args.chain}); signing without -certfile", file=sys.stderr)
        chain_args: list[str] = []
    else:
        chain_args = ["-certfile", str(args.chain)]

    args.output.parent.mkdir(parents=True, exist_ok=True)

    cmd = [
        args.openssl,
        "cms",
        "-sign",
        "-in",
        str(args.input),
        "-signer",
        str(args.cert),
        "-inkey",
        str(args.key),
        *chain_args,
        "-outform",
        "DER",
        "-out",
        str(args.output),
        "-nodetach",
        "-binary",
    ]

    try:
        subprocess.run(cmd, check=True, capture_output=True, text=True)
    except subprocess.CalledProcessError as e:
        print("openssl cms failed:", file=sys.stderr)
        if e.stderr:
            print(e.stderr, file=sys.stderr)
        if e.stdout:
            print(e.stdout, file=sys.stderr)
        return e.returncode or 1

    print(f"Wrote signed profile (DER CMS): {args.output}")
    print("Serve with Content-Type: application/x-apple-aspen-config (or application/octet-stream).")
    return 0


if __name__ == "__main__":
    sys.exit(main())
