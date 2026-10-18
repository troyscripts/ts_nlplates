if TSBridgeValidation and not TSBridgeValidation.valid then return end
-- Elke client bezit alleen zijn eigen actieve melding. Geen serverbericht bij negeren.
local pending, serial, uiReady = nil, 0, false
local settings = TSBridgeConfig.AlertLocation or {
    MapResource = 'ts_gemertmap', ShowArea = true, ShowPostcode = true,
    ShowStreet = false, MaxPostcodeDistance = 1500.0
}
local dismissKey = TSBridgeConfig.AlertDismissKey or 'BACK'
local function finite(n) return type(n) == 'number' and n == n and math.abs(n) ~= math.huge end
local function clean(value, max)
    if type(value) ~= 'string' then return '' end
    return value:gsub('%^%d', ''):gsub('~[%w_]+~', ''):sub(1, max or 500)
end
local function clear()
    local old = pending
    pending = nil
    if old and old.blip then RemoveBlip(old.blip) end
    SendNUIMessage({ action = 'hide' })
end
local function render()
    if not uiReady or not pending then return end
    local remaining = pending.expires - GetGameTimer()
    if remaining <= 0 then clear(); return end
    SendNUIMessage({ action = 'show', id = pending.id, title = pending.title,
        description = pending.description, location = pending.location, postal = pending.postal,
        duration = remaining, acceptKey = TSBridgeConfig.WaypointKey,
        dismissKey = dismissKey == 'BACK' and 'Backspace' or dismissKey,
        acceptLabel = TSL('alerts_accept'), dismissLabel = TSL('alerts_dismiss'),
        remainingLabel = TSL('alerts_remaining') })
end
RegisterNUICallback('ready', function(_, cb)
    uiReady = true
    render()
    cb({ ok = true })
end)
local function locationAt(coords)
    local mapped
    if GetResourceState(settings.MapResource) == 'started' then
        local ok, result = pcall(function() return exports[settings.MapResource]:GetLocation(coords) end)
        if ok and type(result) == 'table' then mapped = result end
    end
    local parts = {}
    if settings.ShowArea then
        local zone = GetNameOfZone(coords.x, coords.y, coords.z)
        local area = mapped and mapped.area or (zone and GetLabelText(zone))
        if area == 'NULL' or area == '' then area = zone end
        if type(area) == 'string' and area ~= '' then parts[#parts+1] = clean(area) end
    end
    if settings.ShowStreet then
        local a, b = GetStreetNameAtCoord(coords.x, coords.y, coords.z)
        local street = a and GetStreetNameFromHashKey(a) or ''
        local crossing = b and b ~= 0 and GetStreetNameFromHashKey(b) or ''
        if type(street) == 'string' and street ~= '' then parts[#parts+1] = clean(street) end
        if type(crossing) == 'string' and crossing ~= '' and crossing ~= street then parts[#parts+1] = clean(crossing) end
    end
    local postcode = ''
    local nearest = mapped and mapped.postcode
    if settings.ShowPostcode and type(nearest) == 'table' and type(nearest.code) == 'string'
        and finite(nearest.distance) and nearest.distance >= 0
        and (settings.MaxPostcodeDistance == 0 or nearest.distance <= settings.MaxPostcodeDistance) then
        postcode = TSL('alerts_postcode'):format(clean(nearest.code, 20))
    end
    local location = table.concat(parts, ' · ')
    if location == '' and postcode == '' then location = TSL('alerts_'):format(coords.x, coords.y) end
    return location, postcode
end
RegisterNetEvent('ts_bridge:jobAlert', function(data, coords, waypointSeconds)
    if source ~= 65535 then return end
    if type(data) ~= 'table' or type(coords) ~= 'table'
        or not finite(coords.x) or not finite(coords.y) or not finite(coords.z) then return end
    local seconds = tonumber(waypointSeconds)
    if not finite(seconds) then seconds = 60 end
    seconds = math.max(1, math.min(seconds, 600))
    local location, postal = locationAt(coords)
    clear() -- nieuwste melding vervangt de vorige; geen verborgen oude G-bestemming
    serial = serial + 1
    local entry = { id = serial, x = coords.x, y = coords.y,
        expires = GetGameTimer() + seconds * 1000, location = location, postal = postal,
        title = clean(data.title or TSL('alerts_politiemelding'), 120),
        description = clean(data.description or '', 1500) }
    pending = entry
    if TSBridgeConfig.AlertBlip ~= false then
        entry.blip = AddBlipForCoord(coords.x, coords.y, coords.z)
        SetBlipSprite(entry.blip, 161)
        SetBlipColour(entry.blip, 1)
        SetBlipScale(entry.blip, 0.8)
        SetBlipAsShortRange(entry.blip, false)
        BeginTextCommandSetBlipName('STRING')
        AddTextComponentSubstringPlayerName(TSL('alerts_blip'))
        EndTextCommandSetBlipName(entry.blip)
    end
    render()
    SetTimeout(math.ceil(seconds * 1000), function()
        if pending == entry then clear() end
    end)
end)
RegisterCommand('ts_bridge_waypoint', function()
    local entry = pending
    if not entry then return end
    if GetGameTimer() >= entry.expires then clear(); return end
    -- Geef negeren voorrang wanneer G en Backspace in dezelfde frame binnenkomen.
    SetTimeout(0, function()
        if pending ~= entry then return end
        if GetGameTimer() >= entry.expires then clear(); return end
        SetNewWaypoint(entry.x, entry.y)
        clear()
    end)
end, false)
RegisterCommand('ts_bridge_ignore_alert', function() clear() end, false)
RegisterKeyMapping('ts_bridge_waypoint', TSL('alerts_troy_scripts_waypoint_naar_laatste_melding'), 'keyboard', TSBridgeConfig.WaypointKey)
RegisterKeyMapping('ts_bridge_ignore_alert', TSL('alerts_dismiss_binding'), 'keyboard', dismissKey)
AddEventHandler('onClientResourceStop', function(name)
    if name == GetCurrentResourceName() then clear() end
end)
