# ts_bridge 0.0.9 — Discord-screenshotdiagnose

Dit pakket bevat alleen gewijzigde en nieuwe bestanden voor ts_bridge 0.0.8.
De map op je server moet ts_bridge heten. Configuratiebestanden zijn niet
meegeleverd en worden niet gewijzigd. De configversie blijft gelijk.

1. Kopieer de inhoud van ts_bridge/ over je bestaande ts_bridge-resource.
2. Zet WebhookConfig.Screenshots = true in ts_hostage/server_config.lua voor de test.
3. Voer in de SERVERCONSOLE uit:

   restart ts_bridge
   ensure ts_hostage

Het stoppen/herstarten van de bridge stopt aangesloten ts_hostage automatisch.
Herstart zo nodig ook andere aangesloten Troy Scripts-resources die zichzelf
stoppen zodra de bridge verdwijnt. Voer dit buiten actieve RP-situaties uit.

4. Start een nieuwe gijzeling en wacht op het Discord-bericht.
5. Voer ts_bridge_check uit in de serverconsole (niet F8). Stuur bij ontbrekende
   foto de regels Laatste screenshot, Laatste Discord-resultaat en Laatste
   Discord-fout plus eventuele webhookwaarschuwingen.

Deze update vraagt Discord om bevestiging en toont veilige foutcodes/veldnamen.
Bij HTTP 400/413/415/422 op een fotobericht probeert hij dezelfde log eenmaal
zonder foto. De werkelijke oorzaak van de HTTP 400 is nog niet vastgesteld.
Bij een netwerk-time-out wordt niet automatisch opnieuw gepost, omdat het
bericht mogelijk al is aangekomen. Hiervoor is geen upload-API-sleutel nodig.

Validatie: Lua 5.4-tests met gesimuleerde FiveM/Discord-aanroepen voor wachtrijen,
broncontrole, screenshot-time-outs, afwijzing van foto's, tekstfallback,
berichtbevestiging en het voorkomen van dubbele verzendingen.
Er is geen live FiveM- of Discord-test uitgevoerd.
Verwijderde bestanden: geen.
