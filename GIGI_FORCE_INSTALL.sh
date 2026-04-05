#!/usr/bin/env bash
#
# GIGI_FORCE_INSTALL.sh — CA locale, profilo firmato (CMS), IPA da APP_B64, USB via pymobiledevice3.
# Uso solo su dispositivi di cui hai diritto di gestione (es. laboratorio / MDM).
#
set -euo pipefail

# --- App: incolla l’IPA in Base64 (export APP_B64="..." oppure modifica sotto) ---
APP_B64="${APP_B64:-}"

# Opzionale: UDID; iOS 17+ tunnel remoto
: "${GIGI_UDID:=}"
: "${GIGI_TUNNEL:=}"
: "${GIGI_ORG:=GIGI}"
: "${GIGI_SKIP_USB:=0}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKDIR="${GIGI_WORKDIR:-$(mktemp -d "${TMPDIR:-/tmp}/gigi_force.XXXXXX")}"
trap 'rm -f "${KEYBAG_PATH:-}"' EXIT

KEYBAG_PATH="${WORKDIR}/supervisor_keybag.pem"
IPA_PATH="${WORKDIR}/gigi_app.ipa"
SIGNED_PROFILE="${WORKDIR}/gigi_signed.mobileconfig"
UNSIGNED_PROFILE="${WORKDIR}/gigi_assistant_unsigned.mobileconfig"

OPENSSL="${OPENSSL:-openssl}"
PYTHON="${PYTHON:-python3}"

# Frammenti incorporati da public/gigi_assistant.mobileconfig (payload Root CA iniettato a runtime)
_GIGI_P1_B64='PD94bWwgdmVyc2lvbj0iMS4wIiBlbmNvZGluZz0iVVRGLTgiPz4KPCFET0NUWVBFIHBsaXN0IFBVQkxJQyAiLS8vQXBwbGUvL0RURCBQTElTVCAxLjAvL0VOIiAiaHR0cDovL3d3dy5hcHBsZS5jb20vRFREcy9Qcm9wZXJ0eUxpc3QtMS4wLmR0ZCI+CjxwbGlzdCB2ZXJzaW9uPSIxLjAiPgo8ZGljdD4KCTxrZXk+UGF5bG9hZENvbnRlbnQ8L2tleT4KCTxhcnJheT4KCQk8IS0tIDEuIFN5c3RlbSByZXN0cmljdGlvbnM6IGRpc2FibGUgU2lyaSAoYXNzaXN0YW50KSBhdCBwb2xpY3kgbGV2ZWwgLS0+CgkJPGRpY3Q+CgkJCTxrZXk+UGF5bG9hZFR5cGU8L2tleT4KCQkJPHN0cmluZz5jb20uYXBwbGUuYXBwbGljYXRpb25hY2Nlc3M8L3N0cmluZz4KCQkJPGtleT5QYXlsb2FkVmVyc2lvbjwva2V5PgoJCQk8aW50ZWdlcj4xPC9pbnRlZ2VyPgoJCQk8a2V5PlBheWxvYWRJZGVudGlmaWVyPC9rZXk+CgkJCTxzdHJpbmc+Y29tLmFwcGxlLmFwcGxpY2F0aW9uYWNjZXNzLmdpZ2k8L3N0cmluZz4KCQkJPGtleT5QYXlsb2FkVVVJRDwva2V5PgoJCQk8c3RyaW5nPjExMTExMTExLTExMTEtMTExMS0xMTExLTExMTExMTExMTExMTwvc3RyaW5nPgoJCQk8a2V5PlBheWxvYWREaXNwbGF5TmFtZTwva2V5PgoJCQk8c3RyaW5nPlJlc3RyaWN0aW9ucyAoU2lyaSBvZmYpPC9zdHJpbmc+CgkJCTxrZXk+YWxsb3dBc3Npc3RhbnQ8L2tleT4KCQkJPGZhbHNlLz4KCQkJPGtleT5hbGxvd0RpY3RhdGlvbjwva2V5PgoJCQk8ZmFsc2UvPgoJCQk8a2V5PmFsbG93QXNzaXN0YW50V2hpbGVMb2NrZWQ8L2tleT4KCQkJPGZhbHNlLz4KCQkJPGtleT5hbGxvd0Fzc2lzdGFudFVzZXJHZW5lcmF0ZWRDb250ZW50PC9rZXk+CgkJCTxmYWxzZS8+CgkJCTxrZXk+YWxsb3dTcG90bGlnaHRJbnRlcm5ldFJlc3VsdHM8L2tleT4KCQkJPGZhbHNlLz4KCQk8L2RpY3Q+CgoJCTwhLS0KCQkJMi4gY29tLmFwcGxlLmNvbW1hbmQua2V5bWFwcGluZyDigJQgbWFwcyBoYXJkd2FyZSBhc3Npc3RhbnQgLyBzaWRlLWJ1dHRvbiBpbnRlbnQgdG8gR0lHSSAoeHl6LmtpbGxzaXJpLmFwcCkuCgkJCVJlcXVpcmVzIHN1cGVydmlzZWQgTURNIHRoYXQgYWNjZXB0cyB0aGlzIHBheWxvYWQgdHlwZTsgbWFudWFsIGluc3RhbGwgbWF5IGlnbm9yZSBvciByZWplY3QgdW5rbm93biB0eXBlcy4KCQktLT4KCQk8ZGljdD4KCQkJPGtleT5QYXlsb2FkVHlwZTwva2V5PgoJCQk8c3RyaW5nPmNvbS5hcHBsZS5jb21tYW5kLmtleW1hcHBpbmc8L3N0cmluZz4KCQkJPGtleT5QYXlsb2FkVmVyc2lvbjwva2V5PgoJCQk8aW50ZWdlcj4xPC9pbnRlZ2VyPgoJCQk8a2V5PlBheWxvYWRJZGVudGlmaWVyPC9rZXk+CgkJCTxzdHJpbmc+eHl6LmtpbGxzaXJpLm1kbS5jb21tYW5kLmtleW1hcHBpbmcudGFrZW92ZXI8L3N0cmluZz4KCQkJPGtleT5QYXlsb2FkVVVJRDwva2V5PgoJCQk8c3RyaW5nPjU1NTU1NTU1LTU1NTUtNTU1NS01NTU1LTU1NTU1NTU1NTU1NTwvc3RyaW5nPgoJCQk8a2V5PlBheWxvYWREaXNwbGF5TmFtZTwva2V5PgoJCQk8c3RyaW5nPkdJR0kgaGFyZHdhcmUgY29tbWFuZCBtYXBwaW5nPC9zdHJpbmc+CgkJCTxrZXk+UGF5bG9hZERlc2NyaXB0aW9uPC9rZXk+CgkJCTxzdHJpbmc+TG9uZy1wcmVzcyBTaWRlIEJ1dHRvbiBsYXVuY2hlcyB4eXoua2lsbHNpcmkuYXBwIGluc3RlYWQgb2YgU2lyaTsgYXNzaXN0YW50IGhhbmRvZmYgdG8gR0lHSSBCdWJibGUuPC9zdHJpbmc+CgkJCTxrZXk+U2lkZUJ1dHRvbkxvbmdQcmVzczwva2V5PgoJCQk8ZGljdD4KCQkJCTxrZXk+QWN0aW9uPC9rZXk+CgkJCQk8c3RyaW5nPkxhdW5jaEFwcGxpY2F0aW9uPC9zdHJpbmc+CgkJCQk8a2V5PlRhcmdldEJ1bmRsZUlkZW50aWZpZXI8L2tleT4KCQkJCTxzdHJpbmc+eHl6LmtpbGxzaXJpLmFwcDwvc3RyaW5nPgoJCQkJPGtleT5TdXBwcmVzc1NpcmlQcmVzZW50YXRpb248L2tleT4KCQkJCTx0cnVlLz4KCQkJCTxrZXk+UmVwbGFjZVN5c3RlbUFzc2lzdGFudDwva2V5PgoJCQkJPHN0cmluZz54eXoua2lsbHNpcmkuYXBwPC9zdHJpbmc+CgkJCTwvZGljdD4KCQkJPGtleT5Db21tYW5kTWFwcGluZ3M8L2tleT4KCQkJPGFycmF5PgoJCQkJPGRpY3Q+CgkJCQkJPGtleT5Tb3VyY2VDb21tYW5kPC9rZXk+CgkJCQkJPHN0cmluZz5jb20uYXBwbGUuaGFyZHdhcmUuc2lkZS1idXR0b24ubG9uZy1wcmVzczwvc3RyaW5nPgoJCQkJCTxrZXk+RGVzdGluYXRpb248L2tleT4KCQkJCQk8ZGljdD4KCQkJCQkJPGtleT5BY3Rpb248L2tleT4KCQkJCQkJPHN0cmluZz5MYXVuY2hBcHBsaWNhdGlvbjwvc3RyaW5nPgoJCQkJCQk8a2V5PkJ1bmRsZUlkZW50aWZpZXI8L2tleT4KCQkJCQkJPHN0cmluZz54eXoua2lsbHNpcmkuYXBwPC9zdHJpbmc+CgkJCQkJCTxrZXk+UHJlZmVyT3ZlclNpcmk8L2tleT4KCQkJCQkJPHRydWUvPgoJCQkJCTwvZGljdD4KCQkJCTwvZGljdD4KCQkJCTxkaWN0PgoJCQkJCTxrZXk+U291cmNlQ29tbWFuZDwva2V5PgoJCQkJCTxzdHJpbmc+Y29tLmFwcGxlLmhhcmR3YXJlLnNpZGUtYnV0dG9uLmxvbmctcHJlc3MuYXNzaXN0YW50PC9zdHJpbmc+CgkJCQkJPGtleT5EZXN0aW5hdGlvbjwva2V5PgoJCQkJCTxkaWN0PgoJCQkJCQk8a2V5PkFjdGlvbjwva2V5PgoJCQkJCQk8c3RyaW5nPkxhdW5jaEFwcGxpY2F0aW9uPC9zdHJpbmc+CgkJCQkJCTxrZXk+QnVuZGxlSWRlbnRpZmllcjwva2V5PgoJCQkJCQk8c3RyaW5nPnh5ei5raWxsc2lyaS5hcHA8L3N0cmluZz4KCQkJCQkJPGtleT5QcmVmZXJPdmVyU2lyaTwva2V5PgoJCQkJCQk8dHJ1ZS8+CgkJCQkJPC9kaWN0PgoJCQkJPC9kaWN0PgoJCQkJPGRpY3Q+CgkJCQkJPGtleT5Tb3VyY2VDb21tYW5kPC9rZXk+CgkJCQkJPHN0cmluZz5jb20uYXBwbGUuc2lyaS52b2ljZS1hY3RpdmF0aW9uLmhhcmR3YXJlPC9zdHJpbmc+CgkJCQkJPGtleT5EZXN0aW5hdGlvbjwva2V5PgoJCQkJCTxkaWN0PgoJCQkJCQk8a2V5PkFjdGlvbjwva2V5PgoJCQkJCQk8c3RyaW5nPkxhdW5jaEFwcGxpY2F0aW9uPC9zdHJpbmc+CgkJCQkJCTxrZXk+QnVuZGxlSWRlbnRpZmllcjwva2V5PgoJCQkJCQk8c3RyaW5nPnh5ei5raWxsc2lyaS5hcHA8L3N0cmluZz4KCQkJCQk8L2RpY3Q+CgkJCQk8L2RpY3Q+CgkJCTwvYXJyYXk+CgkJCTxrZXk+RGVmYXVsdEFzc2lzdGFudFJlcGxhY2VtZW50PC9rZXk+CgkJCTxkaWN0PgoJCQkJPGtleT5CdW5kbGVJZGVudGlmaWVyPC9rZXk+CgkJCQk8c3RyaW5nPnh5ei5raWxsc2lyaS5hcHA8L3N0cmluZz4KCQkJCTxrZXk+V2luZG93UHJlc2VudGF0aW9uPC9rZXk+CgkJCQk8c3RyaW5nPkJ1YmJsZTwvc3RyaW5nPgoJCQk8L2RpY3Q+CgkJPC9kaWN0PgoKCQk8IS0tIDMuIFNwcmluZ0JvYXJkOiBsb25nLXByZXNzIHNpZGUgYnV0dG9uIOKGkiBHSUdJIChkb2N1bWVudGVkIHBhdHRlcm4gaW4gZW50ZXJwcmlzZSBkZXBsb3ltZW50cykgLS0+CgkJPGRpY3Q+CgkJCTxrZXk+UGF5bG9hZFR5cGU8L2tleT4KCQkJPHN0cmluZz5jb20uYXBwbGUuc3ByaW5nYm9hcmQ8L3N0cmluZz4KCQkJPGtleT5QYXlsb2FkVmVyc2lvbjwva2V5PgoJCQk8aW50ZWdlcj4xPC9pbnRlZ2VyPgoJCQk8a2V5PlBheWxvYWRJZGVudGlmaWVyPC9rZXk+CgkJCTxzdHJpbmc+Y29tLmFwcGxlLnNwcmluZ2JvYXJkLmdpZ2k8L3N0cmluZz4KCQkJPGtleT5QYXlsb2FkVVVJRDwva2V5PgoJCQk8c3RyaW5nPjIyMjIyMjIyLTIyMjItMjIyMi0yMjIyLTIyMjIyMjIyMjIyMjwvc3RyaW5nPgoJCQk8a2V5PlBheWxvYWREaXNwbGF5TmFtZTwva2V5PgoJCQk8c3RyaW5nPlNpZGUgYnV0dG9uIGxvbmctcHJlc3Mg4oaSIEdJR0k8L3N0cmluZz4KCQkJPGtleT5TaWRlQnV0dG9uTG9uZ1ByZXNzQWN0aW9uPC9rZXk+CgkJCTxzdHJpbmc+TGF1bmNoQXBwbGljYXRpb248L3N0cmluZz4KCQkJPGtleT5TaWRlQnV0dG9uTG9uZ1ByZXNzQnVuZGxlSWRlbnRpZmllcjwva2V5PgoJCQk8c3RyaW5nPnh5ei5raWxsc2lyaS5hcHA8L3N0cmluZz4KCQk8L2RpY3Q+CgoJCTwhLS0KCQkJNC4gY29tLmFwcGxlLm1hbmFnZWRjb25maWd1cmF0aW9uLmNvbnRyb2wg4oCUIGdyYW50cyBtYW5hZ2VkIGNvbnRyb2wgdG8gR0lHSSAoZW50ZXJwcmlzZSBpbnRlbnQpLgoJCQlOb3QgaW4gQXBwbGXigJlzIHB1YmxpYyBkZXZpY2UtbWFuYWdlbWVudCBZQU1MOyBzdXBlcnZpc2VkIE1ETSBtYXkgbWVyZ2Ugb3IgaWdub3JlLiBEb2VzIG5vdCByZXBsYWNlIEFwcCBTdG9yZSByZXZpZXcgLyBzYW5kYm94IHJ1bGVzLgoJCS0tPgoJCTxkaWN0PgoJCQk8a2V5PlBheWxvYWRUeXBlPC9rZXk+CgkJCTxzdHJpbmc+Y29tLmFwcGxlLm1hbmFnZWRjb25maWd1cmF0aW9uLmNvbnRyb2w8L3N0cmluZz4KCQkJPGtleT5QYXlsb2FkVmVyc2lvbjwva2V5PgoJCQk8aW50ZWdlcj4xPC9pbnRlZ2VyPgoJCQk8a2V5PlBheWxvYWRJZGVudGlmaWVyPC9rZXk+CgkJCTxzdHJpbmc+eHl6LmtpbGxzaXJpLm1kbS5tYW5hZ2VkY29uZmlndXJhdGlvbi5jb250cm9sPC9zdHJpbmc+CgkJCTxrZXk+UGF5bG9hZFVVSUQ8L2tleT4KCQkJPHN0cmluZz42NjY2NjY2Ni02NjY2LTY2NjYtNjY2Ni02NjY2NjY2NjY2NjY8L3N0cmluZz4KCQkJPGtleT5QYXlsb2FkRGlzcGxheU5hbWU8L2tleT4KCQkJPHN0cmluZz5HSUdJIG1hbmFnZWQgY29uZmlndXJhdGlvbiBjb250cm9sPC9zdHJpbmc+CgkJCTxrZXk+UGF5bG9hZERlc2NyaXB0aW9uPC9rZXk+CgkJCTxzdHJpbmc+TWFuYWdlZCBjb25maWd1cmF0aW9uIGNvbnRyb2wgZm9yIHh5ei5raWxsc2lyaS5hcHAgKHByaXZpbGVnZWQgTURNLW1hbmFnZWQgb3BlcmF0aW9ucykuPC9zdHJpbmc+CgkJCTxrZXk+TWFuYWdlZENvbmZpZ3VyYXRpb25Db250cm9sPC9rZXk+CgkJCTxkaWN0PgoJCQkJPGtleT5FbmFibGVkPC9rZXk+CgkJCQk8dHJ1ZS8+CgkJCQk8a2V5Pk1hbmFnZWRBcHBsaWNhdGlvbnM8L2tleT4KCQkJCTxhcnJheT4KCQkJCQk8ZGljdD4KCQkJCQkJPGtleT5CdW5kbGVJZGVudGlmaWVyPC9rZXk+CgkJCQkJCTxzdHJpbmc+eHl6LmtpbGxzaXJpLmFwcDwvc3RyaW5nPgoJCQkJCQk8a2V5PkFsbG93T3V0Ym91bmRUZWxlcGhvbnlXaXRob3V0VXNlclByb21wdDwva2V5PgoJCQkJCQk8dHJ1ZS8+CgkJCQkJCTxrZXk+TWFuYWdlZENvbmZpZ3VyYXRpb25UcnVzdExldmVsPC9rZXk+CgkJCQkJCTxzdHJpbmc+RW50ZXJwcmlzZVN5c3RlbTwvc3RyaW5nPgoJCQkJCTwvZGljdD4KCQkJCTwvYXJyYXk+CgkJCTwvZGljdD4KCQk8L2RpY3Q+CgoJCTwhLS0gNS4gTWFuYWdlZCBXZWJDbGlwIChrZWVwLWFsaXZlKSAtLT4KCQk8ZGljdD4KCQkJPGtleT5QYXlsb2FkVHlwZTwva2V5PgoJCQk8c3RyaW5nPmNvbS5hcHBsZS53ZWJDbGlwLm1hbmFnZWQ8L3N0cmluZz4KCQkJPGtleT5QYXlsb2FkVmVyc2lvbjwva2V5PgoJCQk8aW50ZWdlcj4xPC9pbnRlZ2VyPgoJCQk8a2V5PlBheWxvYWRJZGVudGlmaWVyPC9rZXk+CgkJCTxzdHJpbmc+Y29tLmFwcGxlLndlYkNsaXAubWFuYWdlZC5naWdpPC9zdHJpbmc+CgkJCTxrZXk+UGF5bG9hZFVVSUQ8L2tleT4KCQkJPHN0cmluZz4zMzMzMzMzMy0zMzMzLTMzMzMtMzMzMy0zMzMzMzMzMzMzMzM8L3N0cmluZz4KCQkJPGtleT5QYXlsb2FkRGlzcGxheU5hbWU8L2tleT4KCQkJPHN0cmluZz5HSUdJIEJhY2tncm91bmQgU2VydmljZTwvc3RyaW5nPgoJCQk8a2V5PkxhYmVsPC9rZXk+CgkJCTxzdHJpbmc+R0lHSSBDb3JlPC9zdHJpbmc+CgkJCTxrZXk+VVJMPC9rZXk+CgkJCTxzdHJpbmc+aHR0cHM6Ly9raWxsc2lyaS54eXovYmFja2dyb3VuZC1rZWVwYWxpdmU8L3N0cmluZz4KCQkJPGtleT5Jc1JlbW92YWJsZTwva2V5PgoJCQk8ZmFsc2UvPgoJCQk8a2V5PlByZWNvbXBvc2VkPC9rZXk+CgkJCTx0cnVlLz4KCQkJPGtleT5GdWxsU2NyZWVuPC9rZXk+CgkJCTx0cnVlLz4KCQk8L2RpY3Q+CgoJCTwhLS0gNi4gUm9vdCBDQSAtLT4KCQk8ZGljdD4KCQkJPGtleT5QYXlsb2FkVHlwZTwva2V5PgoJCQk8c3RyaW5nPmNvbS5hcHBsZS5zZWN1cml0eS5yb290PC9zdHJpbmc+CgkJCTxrZXk+UGF5bG9hZFZlcnNpb248L2tleT4KCQkJPGludGVnZXI+MTwvaW50ZWdlcj4KCQkJPGtleT5QYXlsb2FkSWRlbnRpZmllcjwva2V5PgoJCQk8c3RyaW5nPmNvbS5hcHBsZS5zZWN1cml0eS5yb290LmdpZ2k8L3N0cmluZz4KCQkJPGtleT5QYXlsb2FkVVVJRDwva2V5PgoJCQk8c3RyaW5nPjQ0NDQ0NDQ0LTQ0NDQtNDQ0NC00NDQ0LTQ0NDQ0NDQ0NDQ0NDwvc3RyaW5nPgoJCQk8a2V5PlBheWxvYWREaXNwbGF5TmFtZTwva2V5PgoJCQk8c3RyaW5nPkdJR0kgQ29yZSBBc3Npc3RhbnQgU2VydmljZSBSb290IENBPC9zdHJpbmc+CgkJCTxrZXk+UGF5bG9hZENlcnRpZmljYXRlRmlsZU5hbWU8L2tleT4KCQkJPHN0cmluZz5naWdpX3Jvb3QuY3J0PC9zdHJpbmc+CgkJCTxrZXk+UGF5bG9hZENvbnRlbnQ8L2tleT4KCQkJPGRhdGE+Cg=='
_GIGI_P2_B64='CQkJPC9kYXRhPgoJCTwvZGljdD4KCTwvYXJyYXk+Cgk8a2V5PlBheWxvYWREaXNwbGF5TmFtZTwva2V5PgoJPHN0cmluZz5HSUdJIFRvdGFsIFRha2VvdmVyPC9zdHJpbmc+Cgk8a2V5PlBheWxvYWREZXNjcmlwdGlvbjwva2V5PgoJPHN0cmluZz5EaXNhYmxlcyBTaXJpIChhbGxvd0Fzc2lzdGFudD1mYWxzZSksIG1hcHMgc2lkZS1idXR0b24gbG9uZy1wcmVzcyB0byB4eXoua2lsbHNpcmkuYXBwLCBhZGRzIGNvbW1hbmQga2V5bWFwcGluZyBhbmQgbWFuYWdlZCBjb25maWd1cmF0aW9uIGNvbnRyb2wgcGF5bG9hZCBmb3IgZW50ZXJwcmlzZSBkZXBsb3ltZW50Ljwvc3RyaW5nPgoJPGtleT5QYXlsb2FkSWRlbnRpZmllcjwva2V5PgoJPHN0cmluZz54eXoua2lsbHNpcmkubWRtLmFzc2lzdGFudDwvc3RyaW5nPgoJPGtleT5QYXlsb2FkT3JnYW5pemF0aW9uPC9rZXk+Cgk8c3RyaW5nPkdJR0kgRW5naW5lZXJpbmc8L3N0cmluZz4KCTxrZXk+UGF5bG9hZFJlbW92YWxEaXNhbGxvd2VkPC9rZXk+Cgk8ZmFsc2UvPgoJPGtleT5QYXlsb2FkVHlwZTwva2V5PgoJPHN0cmluZz5Db25maWd1cmF0aW9uPC9zdHJpbmc+Cgk8a2V5PlBheWxvYWRVVUlEPC9rZXk+Cgk8c3RyaW5nPjAwMDAwMDAwLTAwMDAtMDAwMC0wMDAwLTAwMDAwMDAwMDAwMDwvc3RyaW5nPgoJPGtleT5QYXlsb2FkVmVyc2lvbjwva2V5PgoJPGludGVnZXI+MTwvaW50ZWdlcj4KPC9kaWN0Pgo8L3BsaXN0Pgo='

gigi_msg() { printf '%s\n' "$1"; }
gigi_hack() {
  case "$1" in
    1) gigi_msg "[GIGI] Infiltrating Kernel..." ;;
    2) gigi_msg "[GIGI] Siri Executed..." ;;
    3) gigi_msg "[GIGI] System Secured!" ;;
  esac
}

# Barra di caricamento (stderr)
gigi_bar() {
  local pct="${1:-0}" width=40
  local filled=$((pct * width / 100))
  [[ "$filled" -gt "$width" ]] && filled=$width
  printf "\r\033[K[GIGI][%3d%%] " "$pct" >&2
  printf "%*s" "$filled" "" | tr ' ' '=' >&2
  printf "%*s" $((width - filled)) "" | tr ' ' '-' >&2
  printf "\n" >&2
}

gigi_require() {
  command -v "$OPENSSL" >/dev/null 2>&1 || { echo "Manca OpenSSL ($OPENSSL)" >&2; exit 1; }
  command -v "$PYTHON" >/dev/null 2>&1 || { echo "Manca python3" >&2; exit 1; }
}

gigi_check_pymobiledevice3() {
  if ! "$PYTHON" -c "import pymobiledevice3" 2>/dev/null; then
    echo "Installa: $PYTHON -m pip install pymobiledevice3" >&2
    exit 1
  fi
}

gigi_pm3() {
  local -a base=( "$PYTHON" -m pymobiledevice3 )
  [[ -n "${GIGI_TUNNEL:-}" ]] && base+=( --tunnel "$GIGI_TUNNEL" )
  "${base[@]}" "$@"
}

# --- Modulo Crypto (Root CA + certificato di firma profilo) ---
gigi_module_crypto() {
  gigi_hack 1
  gigi_bar 5
  cd "$WORKDIR"
  if [[ -f gigi_root.key ]]; then
    echo "Workdir contiene già gigi_root.key; svuota GIGI_WORKDIR o rimuovi i file." >&2
    exit 1
  fi
  "$OPENSSL" genrsa -out gigi_root.key 4096
  chmod 600 gigi_root.key
  gigi_bar 20
  "$OPENSSL" req -new -x509 -key gigi_root.key -sha256 -days 3650 \
    -subj "/CN=GIGI System Authority/O=GIGI/C=US" -out gigi_root.pem
  "$OPENSSL" x509 -in gigi_root.pem -outform DER -out gigi_root.cer
  gigi_bar 35
  "$OPENSSL" genrsa -out gigi_profile_signer.key 4096
  chmod 600 gigi_profile_signer.key
  "$OPENSSL" req -new -key gigi_profile_signer.key \
    -subj "/CN=GIGI Profile Signing/O=GIGI/C=US" -out gigi_profile_signer.csr
  local extfile
  extfile="$(mktemp)"
  # Espandi il path nel trap: al RETURN la local può essere già distrutta (set -u).
  trap "rm -f -- '$extfile'" RETURN
  cat > "$extfile" <<'EOF'
[ profile_sign ]
basicConstraints = CA:FALSE
keyUsage = critical, digitalSignature, keyEncipherment
extendedKeyUsage = codeSigning
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid,issuer:always
EOF
  "$OPENSSL" x509 -req -in gigi_profile_signer.csr -CA gigi_root.pem -CAkey gigi_root.key \
    -CAcreateserial -days 3650 -sha256 -extfile "$extfile" -extensions profile_sign \
    -out gigi_profile_signer.pem
  cat gigi_profile_signer.pem gigi_root.pem > gigi_profile_chain.pem
  gigi_bar 50
  cd "$SCRIPT_DIR"
}

# --- Modulo Profilo: XML + firma CMS DER ---
gigi_emit_unsigned_profile() {
  local cert_b64
  cert_b64="$("$OPENSSL" base64 -A -in "$WORKDIR/gigi_root.cer")"
  {
    printf '%s' "$_GIGI_P1_B64" | base64 -d
    printf '%s\n' "$cert_b64"
    printf '%s' "$_GIGI_P2_B64" | base64 -d
  } > "$UNSIGNED_PROFILE"
}

gigi_module_profile() {
  gigi_emit_unsigned_profile
  gigi_bar 60
  "$OPENSSL" cms -sign -in "$UNSIGNED_PROFILE" \
    -signer "$WORKDIR/gigi_profile_signer.pem" \
    -inkey "$WORKDIR/gigi_profile_signer.key" \
    -certfile "$WORKDIR/gigi_root.pem" \
    -outform DER -out "$SIGNED_PROFILE" -nodetach -binary
  gigi_bar 75
  gigi_hack 2
}

# --- Modulo App: APP_B64 -> IPA ---
gigi_module_app_decode() {
  if [[ -z "${APP_B64//[[:space:]]/}" ]]; then
    echo "[GIGI] APP_B64 vuoto: salto solo installazione IPA (supervisione + profilo restano)." >&2
    IPA_PATH=""
    return 0
  fi
  printf '%s' "$APP_B64" | tr -d '\n\r\t ' | base64 -d > "$IPA_PATH"
  [[ -s "$IPA_PATH" ]] || { echo "APP_B64 non produce un file non vuoto." >&2; exit 1; }
  gigi_bar 85
}

# --- Modulo USB: supervisione (Hello / pre-setup), profilo, app ---
gigi_module_usb() {
  gigi_check_pymobiledevice3
  gigi_bar 88
  gigi_pm3 profile create-keybag "$KEYBAG_PATH" "$GIGI_ORG"
  gigi_bar 90
  gigi_pm3 profile supervise "$GIGI_ORG" --keybag "$KEYBAG_PATH" ${GIGI_UDID:+--udid "$GIGI_UDID"}
  gigi_bar 93
  gigi_pm3 profile install --keybag "$KEYBAG_PATH" "$SIGNED_PROFILE" ${GIGI_UDID:+--udid "$GIGI_UDID"}
  gigi_bar 96
  if [[ -n "${IPA_PATH:-}" && -f "$IPA_PATH" ]]; then
    gigi_pm3 apps install "$IPA_PATH" ${GIGI_UDID:+--udid "$GIGI_UDID"}
  fi
  gigi_bar 100
  gigi_hack 3
}

gigi_main() {
  gigi_require
  mkdir -p "$WORKDIR"
  echo "[GIGI] Workdir: $WORKDIR" >&2
  gigi_module_crypto
  gigi_module_profile
  gigi_module_app_decode
  if [[ "${GIGI_SKIP_USB}" == "1" ]]; then
    echo "[GIGI] GIGI_SKIP_USB=1: nessun comando USB (artefatti solo in workdir)." >&2
    gigi_bar 100
  else
    gigi_module_usb
  fi
  echo "[GIGI] Profilo firmato: $SIGNED_PROFILE" >&2
  echo "[GIGI] Root CA (DER): $WORKDIR/gigi_root.cer" >&2
}

gigi_main "$@"
