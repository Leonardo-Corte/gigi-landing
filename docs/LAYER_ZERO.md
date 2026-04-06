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
└── gigi_killer.mobileconfig   # profilo XML (canonico in root; `public/` punta qui)
```

Il resto del tree (`.xcodeproj`, `Info.plist`, asset Capacitor, ecc.) resta necessario alla build iOS ma non è elencato sopra.
