# Verwijderd/vervangen voor modelafbeeldingen

- Live voertuigfoto-aanvraag uit ts_nlplates/webhook_server.lua verwijderd: geen voertuigscan, afstandseis, screenshot of camerawissel meer voor deze logging.
- webhook_config.lua: vehiclePhoto vervangen door vehicleImage; createdUrl/replacementUrl toegevoegd. Oude url en centrale registration-route blijven werken.
- De gedeelde screenshotfuncties in de bridge blijven beschikbaar voor andere scripts.
- Geen databasegegevens, bestaande kaarten, kentekens of adminrechten verwijderd.
- Nieuw: vehicle_models.lua, met modelhash, naam en exacte afbeelding-URL uit de opgegeven FiveM-documentatie.
- Versies blijven nlplates 1.0.6 en bridge 1.0.2.
