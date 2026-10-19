# Webhooks met FiveM-modelafbeelding

Dit hoort bij de volledige release ts_nlplates 1.0.6 / ts_bridge 1.0.2. Configschema's: 1.0.3 en 0.0.6. Geen extra SQL-update voor webhooks nodig.

## Instellen

Kopieer de bestanden naar de gelijknamige resourcemappen. Behoud jouw geheime URL als je webhook_config.lua al hebt ingevuld. Stel in ts_nlplates/webhook_config.lua in:

```lua
TSPlateWebhook = {
    enabled = true,
    url = '', -- optionele gezamenlijke fallback
    createdUrl = 'JOUW_WEBHOOK_VOOR_NIEUWE_BEWIJZEN',
    replacementUrl = '', -- optioneel andere webhook voor vervangingen
    firstIssue = true,
    replacement = true,
    vehicleImage = true,
}
```

Vul een echte https://discord.com/api/webhooks/... URL in. Met alleen url ingesteld gaan beide soorten naar hetzelfde kanaal. createdUrl is voor de eerste uitgifte; replacementUrl voor de vervangende kaart. Dit bestand is server-only; publiceer geen ingevulde URLs.

Je kunt de URLs ook centraal instellen binnen de bestaande TSBridgeServer.Webhooks-tabel van ts_bridge/server_config.lua:

```lua
['ts_nlplates'] = {
    created = 'JOUW_WEBHOOK_VOOR_NIEUWE_BEWIJZEN',
    replacement = 'JOUW_WEBHOOK_VOOR_VERVANGINGEN',
    -- registration = 'OPTIONELE_GEDEELDE_FALLBACK',
},
```

Voorrang per type: centrale created/replacement-route, daarna de typespecifieke URL uit nlplates. Als die lokale specifieke URL leeg is wordt eerst de bestaande centrale registration-route geprobeerd, daarna de lokale algemene url. Bestaande registration-configs blijven dus bruikbaar.

Herstart de server na installatie zodat bridge en afhankelijkheden volledig opnieuw laden.

## Wanneer verschijnt het bericht?

Een nieuw kentekenbewijs wordt gelogd zodra het item voor het eerst succesvol in het dashboardkastje is aangemaakt en de uitgifte is opgeslagen. Dat gebeurt bij de eerste opening van het kastje, niet automatisch bij aankoop. Een succesvolle vervanging via het loket heeft een afzonderlijke melding met het nieuwe documentnummer.

Opnieuw openen van een kastje met een al uitgegeven bewijs geeft geen nieuw bericht. Bestaande kaarten worden niet achteraf gelogd. Mislukte itemuitgifte geeft geen uitgiftelog. De melding bevestigt uitgifte; ze bevestigt niet dat een eventueel daarna uitgevoerde politiebetaling is geslaagd.

De eerdere versie had al eerste-uitgiftelogging maar gebruikte dezelfde registration-route als vervangingen. Er zijn nu expliciete created/replacement-routes en instellingen. Zonder serverlog of live test is niet vastgesteld waarom een eventueel eerder bericht bij jou ontbrak.

## Afbeeldingen

Het bericht bevat een PNG van de registratiekaart en daarnaast de bijbehorende standaardmodelafbeelding uit:
https://docs.fivem.net/docs/game-references/vehicle-references/vehicle-models/

De koppeling staat server-side in vehicle_models.lua: 859 modellen uit de opgegeven pagina, opgehaald op 19-10-2026. Zowel positieve als negatieve weergaven van dezelfde 32-bits hash worden herkend. Discord haalt de afbeelding op via de exacte docs-backend.fivem.net-URL uit die pagina. Er wordt geen URL gegokt voor onbekende modellen.

Het voertuig hoeft niet buiten te staan. Voor deze logging is screenshot-basic niet nodig; er wordt geen camera verplaatst en niet op sluiten van de inventory gewacht. vehiclePhoto uit de vorige webhookconfig vervalt; vehicleImage bepaalt of de modelafbeelding wordt getoond en is standaard aan, ook bij een oudere config zonder dat veld.

Het is de standaardafbeelding van het model, niet jouw kleur, tuning of livery. Addonvoertuigen die ontbreken op de FiveM-pagina krijgen de kaartafbeelding en een duidelijke melding dat er geen modelafbeelding beschikbaar is. Een externe bronstoring kan de modelafbeelding onzichtbaar maken; kaartgegevens en de PNG worden afzonderlijk meegestuurd.

De kaart-PNG gebruikt servergegevens. Een bekend model krijgt nu ook zijn leesbare modelnaam. De afbeelding is een momentopname van uitgifte; een later ingetrokken kaart wijzigt een ouder Discordbericht niet.

## Testen

- Gebruik een standaardvoertuig zonder eerder uitgegeven bewijs. Open het kastje: verwacht één bericht op created met kaart en modelafbeelding.
- Open opnieuw: verwacht geen tweede uitgiftelog.
- Vervang het bewijs bij het loket: verwacht één bericht op replacement.
- Test een addonmodel: kaart wordt gelogd, ontbrekende modelafbeelding wordt vermeld.

Lokaal getest: positieve/negatieve hashes, nieuwe/vervangende routes, gedeelde fallback, uitschakelopties, onbekende modellen, PNG-upload en bestaande bridgewebhookwachtrij. Geen live Discordbericht verstuurd. Webhookfouten draaien een uitgifte niet terug. De verzendwachtrij is niet permanent; uitstaande logs kunnen bij een serverstop verloren gaan. Bij onzekere HTTP-time-outs wordt niet automatisch opnieuw gepost.
