# Generazione (sul tuo Mac)

## Prerequisiti

1. **Certificati** — cartella `gigi_ca/` con `gigi_root.cer` (es. `./generate_gigi_ca.sh` dalla root del repo o da `Desktop/GIGI_HACK`).
2. **Profilo firmato** — `public/gigi_signed.mobileconfig` (genera da `public/gigi_assistant.mobileconfig` con `sign_gigi_profile.py` e i PEM in `gigi_ca/`).
3. **IPA** — esporta l’app da **Xcode** (Product → Archive → Distribute App) e copia il file in un percorso noto, ad esempio:

   `ios/App/GIGI.ipa`

   (Il file non è versionato: va creato sul tuo Mac dopo ogni build.)

## Packer

Dalla root del repository:

```bash
python3 gigi_payload_packer.py \
  --cer gigi_ca/gigi_root.cer \
  --mobileconfig public/gigi_signed.mobileconfig \
  --ipa ./ios/App/GIGI.ipa \
  --output inject_gigi.sh
```

Poi rendi eseguibile se serve e lancia:

```bash
chmod +x inject_gigi.sh
./inject_gigi.sh
```

`inject_gigi.sh` è in `.gitignore` (può essere molto grande).
