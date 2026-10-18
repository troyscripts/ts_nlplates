# ts_bridge 1.0.0 — foto-upload

Alleen gewijzigde/nieuwe bestanden ten opzichte van 0.0.9. Geen verwijderingen.

1. Kopieer de inhoud van ts_bridge/ over de bestaande resource. Neem ook het
   gewijzigde fxmanifest.lua en nieuwe server/screenshot_upload.js mee.
2. Laat Screenshots = true in ts_hostage/server_config.lua staan.
3. Voer in de SERVERCONSOLE uit, buiten actieve RP-situaties:

   restart ts_bridge
   ensure ts_hostage

   De bridgeherstart stopt ts_hostage automatisch. Start eventueel andere
   aangesloten Troy Scripts-resources opnieuw als die zichzelf ook stoppen.
4. Test een nieuwe gijzeling. Bij succes staat er:
   [ts_bridge] Discord-foto bevestigd | bericht ...
5. Ontbreekt de foto? Voer ts_bridge_check uit en stuur de drie Laatste-regels
   plus de webhookwaarschuwing. Webhook-URL's hoef je niet te delen.

Geen configuratiebestanden meegeleverd. Configversie blijft ongewijzigd.
Geen API-sleutel, extra resource of npm-installatie nodig; FiveM bevat de Node-runtime.

Techniek: screenshot-basic en client-serveroverdracht blijven hetzelfde. Alleen
het uploaden van foto's naar Discord loopt via Node https met Buffer en de
juiste Content-Length. Base64 houdt de overdracht tussen Lua/JS tekstveilig.
Foutdetails in het vierde argument errorData worden nu ook veilig verwerkt.

Validatie: Lua 5.4-tests voor wachtrij, bronbinding, time-outs, bevestigingen,
fallback en foutdetails. Node-test leest de opgebouwde multipart via een aparte
parser terug en vergelijkt nulbytes, alle bytewaarden en UTF-8-tekst. HTTP wordt
gesimuleerd; geen live Discord- of FiveM-test uitgevoerd.
