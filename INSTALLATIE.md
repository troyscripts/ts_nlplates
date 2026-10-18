# Actuele installatie: ts_bridge 0.0.6

Lees UPDATE-LOCATIES.md voor de update vanaf 0.0.5, de nieuwe configvelden en de
gezamenlijke stop/startvolgorde. Dit pakket bevat alleen gewijzigde bestanden.
Configschema is 0.0.6; server_config.lua blijft staan.

De onderstaande eerdere instructies gelden uitsluitend voor de migratie naar 0.0.5.

# Update ts_bridge 0.0.4 → 0.0.5

Dit pakket bevat alleen gewijzigde/nieuwe bestanden voor een bestaande 0.0.4-installatie.
De resourcemap heet ts_bridge. De bestaande GitHub-repository heet ts_brigde.

1. Maak een backup en beëindig actieve gijzelingen.
2. Stop ts_hostage, ts_antipunch en overige afhankelijke scripts (zoals ts_keycard).
   Stop daarna ts_bridge.
3. Kopieer de map ts_bridge uit dit pakket over de bestaande map. Laat overige
   bestanden staan; verwijder niets. Behoud config.lua en server_config.lua.
4. Installeer antipunch 1.8.2 en hostage 1.1.9, inclusief hun nieuwe configvelden.
5. Start ox_lib/providers indien nodig, daarna ts_bridge en de gestopte scripts.

```cfg
ensure ox_lib
# Bestaande framework-, inventory-, target- en bankingproviders vooraf starten.
ensure ts_bridge
ensure ts_antipunch
ensure ts_hostage
ensure ts_keycard
```

Start alleen geïnstalleerde scripts. Keycard 1.1.5 blijft compatibel.
Bridgeconfigschema blijft 0.0.3; de scriptversie wordt 0.0.5. Geen databasewijziging.
Na een bridgeherstart moeten afhankelijke scripts opnieuw starten.

Controleer de consoleversies en test richten/gijzelen/loslaten in beide volgordes.
Test ook herladen, melee, voertuigcamera en resource-stop met twee spelers.
De oude camera mag pas terugkomen als geen script meer first person aanvraagt.
De update is lokaal gesimuleerd getest, niet op een live FiveM-server.

## GitHub-updatecontrole

Upload alle gewijzigde resourcebestanden, inclusief fxmanifest.lua en version.json
met 0.0.5, naar troyscripts/ts_brigde. Zo kan een oudere installatie bij een volgende
start de hogere versie melden. Alleen het versienummer uploaden is onvoldoende:
de bijbehorende code moet mee. De ZIP publiceert niets automatisch op GitHub.

## Terugzetten

Stop afhankelijke scripts en zet bridge én bijpassende antipunch/hostage terug uit
backup. Antipunch 1.8.2 en hostage 1.1.9 vereisen minimaal bridge 0.0.5.
