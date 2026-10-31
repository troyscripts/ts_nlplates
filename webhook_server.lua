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
            local ped = GetPlayerPed(src)
            local function usable(entity)
                return entity and entity ~= 0 and DoesEntityExist(entity) and GetEntityType(entity) == 2
                    and ped ~= 0 and GetPlayerRoutingBucket(src) == GetEntityRoutingBucket(entity)
                    and #(GetEntityCoords(ped) - GetEntityCoords(entity)) <= 12
                    and TSPlate.normalize(exports.ts_bridge:GetVehicleRealPlate(entity)) == data.plate
            end
            if cfg.vehiclePhoto and not usable(vehicle) then
                vehicle = nil
                for _, candidate in ipairs(GetAllVehicles()) do
                    if usable(candidate) then vehicle = candidate; break end
                end
            end
            local takePhoto = cfg.vehiclePhoto and usable(vehicle) or false
            local payload = {username = 'Troy Scripts', embeds = {{
                title = kind == 'replacement' and 'Vervangend kentekenbewijs uitgegeven' or 'Kentekenbewijs aangemaakt',
                color = 1654581,
                description = kind == 'replacement' and 'Vorige documentversie nietig verklaard. Voertuigkenteken blijft gelijk.' or 'Eerste uitgifte in het dashboardkastje.',
                fields = {
                    {name = 'Kenteken', value = tostring(data.plate), inline = true},
                    {name = 'Documentnummer', value = tostring(data.documentNumber), inline = true},
                    {name = 'Geregistreerde eigenaar', value = tostring(data.owner):sub(1, 1000), inline = false},
                    {name = 'Speler bij uitgifte', value = ('%s (ID %s)'):format(playerName, src):sub(1, 1000), inline = false},
                    {name = 'Voertuigfoto', value = takePhoto and 'Foto wordt aangevraagd; clientbeeld is illustratief.'
                        or 'Niet aangevraagd: uitgeschakeld of geen passend voertuig dichtbij.', inline = false}
                },
                footer = {text = 'Troy Scripts | Uitgiftemoment | Roleplaydocument'},
                timestamp = os.date('!%Y-%m-%dT%H:%M:%SZ')
            }}}
            local sent, reason = exports.ts_bridge:SendWebhook('registration', cfg.url, payload, {
                document = data, screenshot = takePhoto, playerId = src,
                vehicleNetId = takePhoto and NetworkGetNetworkIdFromEntity(vehicle) or nil,
                vehiclePlate = data.plate
            })
            if not sent then print('[ts_nlplates] Webhook niet ingepland: ' .. tostring(reason)) end
        end)
        if not ok then print('[ts_nlplates] Webhookverwerking mislukt; bewijs blijft uitgegeven. Controleer bridge/dependencies.') end
    end)
end
