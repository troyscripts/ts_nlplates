# ts_bridge 0.0.8 — screenshot-update

Kopieer uitsluitend de gewijzigde bestanden van dit pakket over je bestaande `ts_bridge` resource. Deze update bouwt voort op 0.0.7. Je bestaande `config.lua` en `server_config.lua` blijven behouden, inclusief eigen banking-, billing-, webhook- en politie-instellingen.

Screenshots worden lokaal opgenomen via `screenshot-basic` en via een begrensd FiveM-event naar de server verstuurd. De eerdere HTTP-upload naar het gameserverendpoint vervalt. Discord-webhooks blijven uitsluitend server-side. Bij een mislukte screenshot blijft de tekstlogging beschikbaar. De lokale NUI-callback van `screenshot-basic` moet nog steeds correct werken.

De ambulanceondersteuning uit 0.0.7 blijft behouden. Controleer dat `ambulance = { 'society_ambulance' }` aanwezig is in de rekeningaliases van `server_config.lua` en dat de gedeelde ESX-rekening via `esx_addonaccount` bereikbaar is. Deze screenshot-update bevat geen serverconfig; ontbreekt de ambulance-alias nog, voeg die dan zelf toe.

Start `ts_bridge` vóór de afhankelijke Troy Scripts-resources. Herstart na installatie eerst de bridge en daarna de afhankelijke resources, waaronder `ts_hostage` en `ts_keycard`. Test of een screenshot bij de juiste Discord-log verschijnt. Controleer bij een betaalde ambulancekaart ook of €10 bij de ontvanger wordt afgeschreven en €10 op de ambulance-society wordt bijgeschreven.

De scriptversie en `version.json` zijn 0.0.8. De gedeelde `config.lua` en configschemaversie blijven 0.0.6, omdat de instellingen niet zijn gewijzigd. Geen nieuwe exports. Volgens de pakketdocumentatie zijn gesimuleerde tests uitgevoerd; een live FiveM-test blijft nodig.