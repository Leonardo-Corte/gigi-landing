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
│   └── sign_gigi_profile.sh   # CMS/PKCS#7 (DER) con gigi_root.crt + gigi_root.key
└── gigi_killer.mobileconfig   # sorgente XML: include payload com.apple.security.root + restrizioni
```

**Profilo:** `gigi_killer.mobileconfig` in root contiene il payload **`com.apple.security.root`** (certificato DER in `<data>`) allineato a `gigi_ca/gigi_root.crt`. Per il trust sul firmatario serve il file **firmato** (non l’XML grezzo): `npm run sign-profile` scrive `public/gigi_killer.mobileconfig` (DER CMS). Poi `npm run build` / `npx cap copy ios`.

Il resto del tree (`.xcodeproj`, `Info.plist`, asset Capacitor, ecc.) resta necessario alla build iOS ma non è elencato sopra.
