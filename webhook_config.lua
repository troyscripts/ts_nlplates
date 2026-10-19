-- Alleen server-side. Zet geheime URLs nooit in gedeelde config.lua.
TSPlateWebhook = {
    enabled = true,
    url = '', -- gezamenlijke fallback-URL (bestaande instelling blijft ondersteund)
    createdUrl = '', -- webhook voor NIEUW aangemaakte kentekenbewijzen
    replacementUrl = '', -- optioneel aparte webhook voor vervangende bewijzen
    firstIssue = true,
    replacement = true,
    vehicleImage = true, -- modelafbeelding uit de FiveM-documentatie; geen live camera
}
