# Webhooks voor kentekenbewijzen

Stel je eigen Discord-webhook in bij `url` in `config/webhooks.lua`. Dit bestand wordt uitsluitend server-side geladen; zet de URL nooit in `config/config.lua` of de NUI. Een lege URL kan via de centrale ts_bridge-route `ts_nlplates` / `registration` worden afgehandeld als die in jouw bridge is ingesteld.

- `enabled`: uitgiftelogging aan of uit.
- `firstIssue`: eerste uitgifte loggen.
- `replacement`: vervangende uitgifte loggen.
- `vehiclePhoto`: optionele foto van het passende voertuig in de buurt.

De verwerking gebruikt `ts_bridge:SendWebhook` met documentgegevens en een optionele screenshotaanvraag. Voor voertuigfoto's moet screenshot-basic werken. Zie [Electron AntiCheat](electron-anticheat.md) voor resource-whitelisting. Een mislukte webhook maakt een uitgegeven kentekenbewijs niet ongedaan.

Na bijwerken: neem de eigen instellingen uit de oude `webhook_config.lua` over in `config/webhooks.lua`, herstart de resource en test zowel eerste uitgifte als vervanging. Controleer het Discord-kanaal en de serverconsole.
