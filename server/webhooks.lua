if TSBridgeValidation and not TSBridgeValidation.valid then return end
-- Alleen serverresources starten logs; clients kunnen uitsluitend een aangevraagde foto beantwoorden.
local lanes, queued, pendingPhotos = {}, 0, 0
local lastPhoto, lastDelivery = 'geen aanvraag sinds start', 'geen verzending sinds start'
local lastFailure = 'geen fout sinds start'
local function photoStatus(message)
    lastPhoto = os.date('!%H:%M:%S') .. ' UTC | ' .. message
end
local function deliveryStatus(message)
    lastDelivery = os.date('!%H:%M:%S') .. ' UTC | ' .. message
end
-- Alleen foutcodes en veldnamen tonen; nooit URLs, payloads of transportfoutteksten.
local function discordResult(response)
    if type(response) == 'string' then response = response:gsub('^HTTP %d+:%s*', '') end
    local ok, data = pcall(json.decode, response or '')
    if not ok or type(data) ~= 'table' then return nil, 'geen leesbaar Discord-antwoord' end
    local parts = {}
    if type(data.code) == 'number' then parts[#parts + 1] = 'Discord-code ' .. tostring(data.code) end
    local function fields(node, path, depth)
        if type(node) ~= 'table' or depth > 6 or #parts >= 8 then return end
        for key, value in pairs(node) do
            if #parts >= 8 then break end
            if key == '_errors' then
                parts[#parts + 1] = 'veld ' .. path
            elseif type(key) == 'string' or type(key) == 'number' then
                local safe = tostring(key):gsub('[^%w_]', ''):sub(1, 40)
                fields(value, path .. '.' .. safe, depth + 1)
            end
        end
    end
    fields(data.errors, 'payload', 0)
    return data, #parts > 0 and table.concat(parts, '; ') or 'geen foutcode'
end
local function warning(message) print(TSL('webhooks_ts_bridge_webhook') .. message .. '^7') end
local function urlValid(url)
    return type(url) == 'string' and (
        url:match('^https://discord%.com/api/webhooks/%d+/[%w_-]+$') ~= nil
        or url:match('^https://discord%.com/api/v%d+/webhooks/%d+/[%w_-]+$') ~= nil)
end
local alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
local values = {}
for i = 1, #alphabet do values[alphabet:byte(i)] = i - 1 end
local function decodeJpeg(uri)
    if type(uri) ~= 'string' or #uri > math.ceil(TSBridgeServer.MaxImageBytes / 3) * 4 + 64 then return nil end
    local encoded = uri:match('^data:image/jpeg;base64,([A-Za-z0-9+/=]+)$')
        or uri:match('^data:image/jpg;base64,([A-Za-z0-9+/=]+)$')
    if not encoded or #encoded % 4 ~= 0 then return nil end
    local blocks = {}
    for i = 1, #encoded, 4 do
        local a, b, c, d = encoded:byte(i, i + 3)
        local x, y, z, w = values[a], values[b], values[c], values[d]
        if not x or not y or (not z and c ~= 61) or (not w and d ~= 61) then return nil end
        if (c == 61 or d == 61) and i ~= #encoded - 3 then return nil end
        if c == 61 and d ~= 61 then return nil end
        local n = (x << 18) | (y << 12) | ((z or 0) << 6) | (w or 0)
        local part = string.char((n >> 16) & 255)
        if c ~= 61 then part = part .. string.char((n >> 8) & 255) end
        if d ~= 61 then part = part .. string.char(n & 255) end
        blocks[#blocks + 1] = part
    end
    local bytes = table.concat(blocks)
    if #bytes > TSBridgeServer.MaxImageBytes or bytes:sub(1, 3) ~= '\255\216\255' then return nil end
    return bytes
end
-- Een antwoord is eenmalig en gebonden aan de speler van de serveraanvraag.
local photoRequests, photoSequence = {}, 0
local photoEpoch = tostring(os.time()) .. ':' .. tostring(GetGameTimer())
RegisterNetEvent('ts_bridge:screenshot:result', function(token, data, failure)
    if type(token) ~= 'string' then return end
    local request = photoRequests[token]
    if not request or request.player ~= source then return end
    photoRequests[token] = nil
    local reasons = {
        unavailable = 'screenshotresource niet gestart op de client',
        busy = 'screenshotopname op de client is nog bezig',
        timeout = 'lokale screenshotopname geeft geen antwoord; controleer screenshot-basic en de F8-console',
        capture = 'lokale screenshotexport mislukt',
        invalid = 'ongeldig of te groot JPEG-antwoord van de client'
    }
    if failure ~= nil then
        request.complete(nil, reasons[failure] or 'screenshotclient meldt een fout')
        return
    end
    local image = decodeJpeg(data)
    request.complete(image, image and nil or TSL('webhooks_ongeldig_of_te_groot_jpeg_antwoord'), image and data or nil)
end)
AddEventHandler('playerDropped', function()
    local player = source
    local dropped = {}
    for token, request in pairs(photoRequests) do
        if request.player == player then dropped[#dropped + 1] = token end
    end
    for _, token in ipairs(dropped) do
        local request = photoRequests[token]
        photoRequests[token] = nil
        request.complete(nil, TSL('webhooks_speler_niet_online'))
    end
end)

local pump
pump = function(lane)
    local queue = lane.queue
    if lane.processing or #queue == 0 then return end
    lane.processing = true
    local item = queue[1]
    local responded = false
    local function done(status, response)
        if responded then return end
        responded = true
        local result, detail = discordResult(response)
        if status == -1 then detail = 'lokale foto-uploader niet beschikbaar of invoer afgewezen' end
        local kind = item.image and 'foto' or 'tekst'
        deliveryStatus(kind .. ': HTTP ' .. tostring(status) .. ' | ' .. detail)
        if status < 200 or status >= 300 then lastFailure = lastDelivery end
        if status == 429 and item.retries < 3 then
            item.retries = item.retries + 1
            local seconds = type(result) == 'table' and tonumber(result.retry_after) or 2
            if not seconds or seconds ~= seconds then seconds = 2 end
            SetTimeout(math.floor(math.max(1, math.min(seconds, 60)) * 1000), function()
                lane.processing = false; pump(lane)
            end)
            return
        end
        if item.image and (status == -1 or status == 400 or status == 413 or status == 415 or status == 422) then
            warning('Discord weigert fotobericht: HTTP ' .. tostring(status) .. ' | ' .. detail .. '; tekstfallback volgt')
            item.image = nil
            item.imageData = nil
            item.payload.attachments = nil
            local embed = item.payload.embeds[1]
            embed.image = nil
            embed.fields = type(embed.fields) == 'table' and embed.fields or {}
            if #embed.fields < 25 then
                embed.fields[#embed.fields + 1] = { name = 'Screenshot',
                    value = 'Fotobericht afgewezen door Discord (HTTP ' .. tostring(status) .. '). Actie zonder foto geregistreerd.', inline = false }
            end
            item.retries = 0
            SetTimeout(1000, function() lane.processing = false; pump(lane) end)
            return
        end
        if status >= 200 and status < 300 and type(result) == 'table'
            and type(result.id) == 'string' and result.id:match('^%d+$') then
            deliveryStatus(kind .. ': bevestigd door Discord | bericht ' .. result.id)
            if item.image then print('[ts_bridge] Discord-foto bevestigd | bericht ' .. result.id) end
        elseif status >= 200 and status < 300 then
            deliveryStatus(kind .. ': HTTP ' .. tostring(status) .. ' zonder berichtbevestiging')
            warning('Discord gaf HTTP ' .. tostring(status) .. ' zonder berichtbevestiging; geen herhaling om dubbele logs te voorkomen')
        else
            warning('Versturen ' .. kind .. ' mislukt: HTTP ' .. tostring(status) .. ' | ' .. detail .. '; webhook-URL wordt niet getoond')
        end
        table.remove(queue, 1)
        queued = queued - 1
        SetTimeout(1000, function()
            lane.processing = false
            if #queue == 0 then lanes[item.url] = nil else pump(lane) end
        end)
    end
    deliveryStatus((item.image and 'foto' or 'tekst') .. ': HTTP-aanvraag gestart')
    local ok
    if item.image then
        ok = pcall(function()
            exports[GetCurrentResourceName()]:UploadDiscordPhoto(item.url, json.encode(item.payload), item.imageData,
                function(status, response) done(tonumber(status) or 0, response) end)
        end)
        if not ok then done(-1, '') end
    else
        ok = pcall(PerformHttpRequest, item.url .. '?wait=true', function(status, response, headers, errorData)
            done(tonumber(status) or 0, response or errorData)
        end, 'POST', json.encode(item.payload), { ['Content-Type'] = 'application/json' }, { followLocation = false })
        if not ok then done(0, '') end
    end
    -- Geen automatische POST-herhaling bij time-outs: voorkomt dubbele Discord-logs.
    SetTimeout(30000, function() done(0, '') end)
end
local function enqueue(url, payload, image, imageData)
    if queued + pendingPhotos >= TSBridgeServer.MaxQueue then warning(TSL('webhooks_wachtrij_vol_log_overgeslagen')); return false end
    local lane = lanes[url]
    if not lane then lane = { queue = {}, processing = false }; lanes[url] = lane end
    lane.queue[#lane.queue + 1] = { url = url, payload = payload, image = image, imageData = imageData, retries = 0 }
    queued = queued + 1
    pump(lane)
    return true
end

exports('SendWebhook', function(route, fallbackUrl, payload, options)
    local owner = GetInvokingResource()
    if not owner then return false, TSL('webhooks_geen_aanroepende_resource') end
    local routes = TSBridgeServer.Webhooks[owner] or {}
    local url = routes[route]
    if type(url) ~= 'string' or url == '' then url = fallbackUrl end
    if url == '' or url == nil then return false, TSL('webhooks_geen_webhook_ingesteld') end
    if not urlValid(url) then warning(TSL('webhooks_ongeldige_discord_webhook_voor') .. owner); return false, TSL('webhooks_ongeldige_url') end
    if type(payload) ~= 'table' or type(payload.embeds) ~= 'table' or type(payload.embeds[1]) ~= 'table' then
        return false, TSL('webhooks_embed_ontbreekt')
    end
    if queued + pendingPhotos >= TSBridgeServer.MaxQueue then warning(TSL('webhooks_wachtrij_vol_log_overgeslagen')); return false, TSL('webhooks_wachtrij_vol') end
    -- Eigen kopie: async screenshotcallbacks mogen de invoer van de aanroeper niet wijzigen.
    local ok, copied = pcall(function() return json.decode(json.encode(payload)) end)
    if not ok or type(copied) ~= 'table' then return false, TSL('webhooks_ongeldige_payload') end
    payload = copied
    payload.allowed_mentions = { parse = {} }
    options = type(options) == 'table' and options or {}
    local embed = payload.embeds[1]
    local id = tonumber(options.playerId)
    local function photoFailure(reason)
        local value = TSL('webhooks_screenshot_niet_beschikbaar') .. reason .. TSL('webhooks_actie_wel_geregistreerd')
        embed.fields = type(embed.fields) == 'table' and embed.fields or {}
        if #embed.fields < 25 then
            embed.fields[#embed.fields + 1] = { name = 'Screenshot', value = value:sub(1, 1024), inline = false }
        else
            -- Preserve a full embed; use message content only when there is room.
            local content = payload.content or ''
            if #content + #value + 1 <= 2000 then payload.content = content .. '\n' .. value end
        end
    end
    if not options.screenshot then return enqueue(url, payload) end
    local function unavailable(reason)
        photoFailure(reason)
        warning(owner .. ': ' .. reason)
        return enqueue(url, payload)
    end
    if not TSBridgeServer.Screenshots then return unavailable(TSL('webhooks_screenshots_uitgeschakeld_in_ts_bridge')) end
    if GetResourceState(TSBridgeServer.ScreenshotResource) ~= 'started' then return unavailable(TSL('webhooks_screenshotresource_niet_gestart')) end
    if not id or id <= 0 or not GetPlayerName(id) then return unavailable(TSL('webhooks_speler_niet_online')) end
    photoStatus('aangevraagd bij speler ' .. tostring(id))
    pendingPhotos = pendingPhotos + 1
    local completed = false
    photoSequence = photoSequence + 1
    local token = photoEpoch .. ":" .. tostring(photoSequence)
    local function complete(image, reason, imageData)
        if completed then return end
        completed = true
        photoRequests[token] = nil
        pendingPhotos = pendingPhotos - 1
        photoStatus(image and ('ontvangen: ' .. tostring(#image) .. ' bytes') or ('mislukt: ' .. tostring(reason)))
        if image then
            embed.image = { url = 'attachment://screenshot.jpg' }
            payload.attachments = { { id = 0, filename = 'screenshot.jpg' } }
        else
            photoFailure(reason or TSL('webhooks_screenshot_mislukt'))
            warning(owner .. ': ' .. (reason or TSL('webhooks_screenshot_mislukt')))
        end
        enqueue(url, payload, image, imageData)
    end
    photoRequests[token] = { player = id, complete = complete }
    SetTimeout(TSBridgeServer.ScreenshotTimeoutMs, function()
        complete(nil, 'screenshot time-out: geen volledig clientantwoord ontvangen via FiveM')
    end)
    -- Geen NUI HTTP-upload naar het serverendpoint en geen webhook-URL naar clients.
    local requested = pcall(TriggerClientEvent, 'ts_bridge:screenshot:capture', id,
        token, TSBridgeServer.ScreenshotResource, TSBridgeServer.MaxImageBytes,
        TSBridgeServer.ScreenshotTimeoutMs)
    if not requested then complete(nil, 'screenshotaanvraag kon niet naar de client worden gestuurd') end
    return true
end)

TSBridgeWebhookStatus = function()
    local destinations, active = 0, 0
    for _, lane in pairs(lanes) do
        destinations = destinations + 1
        if lane.processing then active = active + 1 end
    end
    return { queued = queued, pendingPhotos = pendingPhotos, destinations = destinations, active = active,
        capacity = TSBridgeServer.MaxQueue, lastPhoto = lastPhoto, lastDelivery = lastDelivery, lastFailure = lastFailure }
end
exports('GetWebhookStatus', TSBridgeWebhookStatus)
