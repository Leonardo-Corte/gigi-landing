# Layer Zero — struttura essenziale

```
GIGI/
├── docs/                    # paper / note tecniche
├── gigi_ca/                 # GIGI Control Root (solo materiale radice)
│   ├── gigi_root.crt
│   └── gigi_root.key
├── src/
│   ├── app/                 # logica web: installazione profilo (`/install`)
│   └── components/
├── ios/
│   └── App/               # progetto Xcode Capacitor (file “core” sotto `App/`)
│       └── App/
│           ├── App.entitlements
│           └── AppDelegate.swift
├── scripts/
│   └── sign_gigi_profile.sh   # openssl smime -sign -nodetach (DER) + gigi_root; opz. apple_chain.crt
└── gigi_killer.mobileconfig   # sorgente XML: include payload com.apple.security.root + restrizioni
```

**Profilo:** `gigi_killer.mobileconfig` in root contiene il payload **`com.apple.security.root`** (certificato DER in `<data>`) allineato a `gigi_ca/gigi_root.crt`. La firma è **`openssl smime -sign -nodetach -outform DER`** (PKCS#7 con XML incluso), non XML grezzo: `npm run sign-profile` → `public/gigi_killer.mobileconfig`. Opzionale: `gigi_ca/apple_chain.crt` o `GIGI_SMIME_CERTFILE` per `-certfile` (catena Apple in PEM). Poi `npm run build` / `npx cap copy ios`.

Il resto del tree (`.xcodeproj`, `Info.plist`, asset Capacitor, ecc.) resta necessario alla build iOS ma non è elencato sopra.
