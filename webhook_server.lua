-- Alleen bevestigde serveruitgiftes roepen deze functie aan; geen net-event.
function TSPlateLogIssue(src, metadata, kind, vehicle)
    local cfg = TSPlateWebhook
    if not cfg or not cfg.enabled or (kind == 'replacement' and not cfg.replacement)
        or (kind == 'first' and not cfg.firstIssue) then return end
    local data = {plate = metadata.plate, owner = metadata.owner, model = metadata.model,
        documentNumber = metadata.documentNumber, issued = metadata.issued, status = metadata.status}
    local playerName = GetPlayerName(src) or 'Niet meer online'
    -- Screenshot/HTTP nooit laten wachten in de openInventory-hook of betaalafhandeling.
    CreateThread(function()
        local ok, err = pcall(function()
            local hash = tonumber(data.model)
            local info = hash and TSPlateVehicleModels[hash % 4294967296]
            local showImage = cfg.vehicleImage ~= false
            data.modelName = info and info.name or nil
            local payload = {username = 'Troy Scripts', embeds = {{
                title = kind == 'replacement' and 'Vervangend kentekenbewijs uitgegeven' or 'Kentekenbewijs aangemaakt',
                color = 1654581,
                description = kind == 'replacement' and 'Vorige documentversie nietig verklaard. Voertuigkenteken blijft gelijk.' or 'Eerste uitgifte in het dashboardkastje.',
                fields = {
                    {name = 'Kenteken', value = tostring(data.plate), inline = true},
                    {name = 'Documentnummer', value = tostring(data.documentNumber), inline = true},
                    {name = 'Geregistreerde eigenaar', value = tostring(data.owner):sub(1, 1000), inline = false},
                    {name = 'Speler bij uitgifte', value = ('%s (ID %s)'):format(playerName, src):sub(1, 1000), inline = false},
                    {name = 'Voertuigmodel', value = info and (info.name .. ' (' .. info.model .. ')')
                        or ('Onbekend/addon-model: ' .. tostring(data.model)), inline = false}
                },
                footer = {text = 'Troy Scripts | Uitgiftemoment | Roleplaydocument'},
                timestamp = os.date('!%Y-%m-%dT%H:%M:%SZ')
            }}}
            if showImage and info then
                payload.embeds[#payload.embeds + 1] = {
                    title = info.name .. ' — modelafbeelding',
                    url = 'https://docs.fivem.net/docs/game-references/vehicle-references/vehicle-models/',
                    description = 'Bron: FiveM-documentatie. Standaardmodel; kleur en tuning van de echte auto kunnen afwijken.',
                    image = {url = info.image}
                }
            elseif showImage then
                payload.embeds[1].fields[#payload.embeds[1].fields + 1] = {
                    name = 'Voertuigafbeelding', value = 'Geen modelafbeelding beschikbaar in de FiveM-documentatie.', inline = false}
            end
            local route = kind == 'replacement' and 'replacement' or 'created'
            local specificUrl = kind == 'replacement' and cfg.replacementUrl or cfg.createdUrl
            local fallbackUrl = type(specificUrl) == 'string' and specificUrl ~= '' and specificUrl or cfg.url
            local sent, reason = exports.ts_bridge:SendWebhook(route, fallbackUrl, payload, {
                document = data, screenshot = false,
                fallbackRoute = (not specificUrl or specificUrl == '') and 'registration' or nil
            })
            if not sent then print('[ts_nlplates] Webhook niet ingepland: ' .. tostring(reason)) end
        end)
        if not ok then print('[ts_nlplates] Webhookverwerking mislukt; bewijs blijft uitgegeven. Controleer bridge/dependencies.') end
    end)
end
