# GIGI — Cloud configuration, supervisione e schermata Hello (pymobiledevice3)

Questa guida descrive **cosa fanno realmente** le API pubbliche di [pymobiledevice3](https://github.com/doronz88/pymobiledevice3) rispetto a nomi tipo “CloudConfig” o “post setup activation”, e quali **prerequisiti** servono su iPhone.

---

## 1. Nomenclatura Apple vs libreria

| Richiesta informale | Cosa esiste in pymobiledevice3 / iOS |
|---------------------|--------------------------------------|
| `CloudConfig.post_setup_activation` | **Non** è un simbolo esposto dalla libreria. L’equivalente utile è: **`MobileConfigService.store_profile(..., Purpose.PostSetupInstallation)`**, che memorizza un profilo da applicare in scenario **post-installazione** (flusso MDM/Configurator). |
| Payload cloud con `IsSupervised = true` | **`MobileConfigService.supervise(organization, keybag_file)`** invia un dizionario “cloud configuration” che include `IsSupervised`, `OrganizationName`, `SkipSetup`, certificati supervisore, ecc. (vedi sorgente `mobile_config.py`). |
| `CloudConfigurationUIHierarchy = false` | **Non** è documentato pubblicamente da Apple come chiave garantita. Lo script prova a **unire** questa chiave al dizionario restituito da `get_cloud_configuration()` dopo `supervise`. Su alcune versioni iOS la chiave può essere **ignorata** o assente. |
| “Saltare i passaggi di configurazione Apple” | `supervise()` imposta un array lungo **`SkipSetup`** (molte voci Assistant, Apple ID, ecc.). È il modello usato dalla CLI `pymobiledevice3 profile supervise`. **Non** sostituisce policy legali o contratti Apple; va usato solo su **dispositivi di cui hai diritto di gestione**. |

---

## 2. Prerequisiti operativi

1. **macOS / Linux / Windows** con `usbmuxd` (o iTunes/Apple Mobile Device su Windows) funzionante.
2. **Cavo USB**; dispositivo in stato in cui **lockdownd** espone il servizio `com.apple.mobile.MCInstall` (spesso in **Hello / pre-configurazione** o dopo reset, a seconda della build).
3. **Pairing**: il Mac/PC deve essere **affidato** (“Trust”) se richiesto; la prima volta serve l’interazione sul telefono.
4. **Stato di attivazione**: se il dispositivo risulta **`Unactivated`**, pymobiledevice3 può chiamare **`MobileActivationService.activate()`** prima della supervisione (come fa `profile supervise`).
5. **Configurazione cloud già presente**: se iOS risponde con errore “cloud configuration already present”, Apple richiede in genere **cancellazione** del dispositivo prima di una nuova cloud config — vedi eccezione `CloudConfigurationAlreadyPresentError` nella libreria.
6. **iOS 17+**: molti servizi “developer” richiedono **tunnel** (`tunneld`); per `MCInstall` su USB spesso si usa ancora usbmux, ma in caso di errori consulta la [guida tunnel iOS 17+](https://github.com/doronz88/pymobiledevice3/blob/master/docs/guides/ios17-tunnels.md) del progetto.

---

## 3. Keybag di supervisione

`supervise()` richiede un file **keybag PEM** che contiene **certificato supervisore + chiave privata** (`create_keybag_file` in pymobiledevice3, oppure file generato con `pymobiledevice3 profile create-keybag`).

Senza un keybag valido, la catena di fiducia supervisione **non** è quella Apple Configurator ufficiale, ma quella generata **localmente** dalla libreria (come nella CLI `supervise` senza `--keybag`).

---

## 4. Organizzazione “GIGI”

Imposta il nome organizzazione con `--organization` (default `GIGI`). Compare nel dizionario cloud come `OrganizationName`.

---

## 5. Script di riferimento

Nel repository: **`gigi_cloudconfig_setup.py`**

Esecuzione tipica:

```bash
python3 -m pip install -r requirements-device.txt
python3 gigi_cloudconfig_setup.py --organization "GIGI"
```

Opzioni utili: `--udid`, `--keybag /path/to/keybag.pem`, `--store-profile /path/to/extra.mobileconfig`.

---

## 6. Limitazioni e conformità

- Usa questi strumenti **solo** su dispositivi **autorizzati** (tuo parco, laboratorio, ABM/ASM con diritto di supervisione).
- **Nessuno** script lato USB può “rendere legale” una supervisione senza i corretti rapporti con Apple (ABM, MDM, o dispositivi di test).
- Il comportamento **Hello Screen** varia tra versioni iOS; in alcuni stati il servizio `MCInstall` non è disponibile finché non si completa un passo rete — la documentazione Apple e le issue pymobiledevice3 (es. “Exit Setup Screen”) sono la fonte migliore per casi limite.
