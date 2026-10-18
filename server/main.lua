if TSBridgeValidation and not TSBridgeValidation.valid then return end
local function getJob(id)
    if TSBridgeServer.Framework == 'standalone' then return nil end
    if TSBridgeServer.Framework ~= 'esx' then return nil, TSL('main_onbekend_framework') end
    if GetResourceState(TSBridgeServer.ESXResource) ~= 'started' then return nil, TSL('main_esx_niet_gestart') end
    local ok, job = pcall(function()
        local esx = exports[TSBridgeServer.ESXResource]:getSharedObject()
        local player = esx.GetPlayerFromId(tonumber(id))
        if not player then return nil end
        local value = type(player.getJob) == 'function' and player.getJob() or player.job
        if type(value) == 'string' then value = { name = value } end
        if type(value) ~= 'table' or type(value.name) ~= 'string' then return nil end
        return { name = value.name, grade = tonumber(value.grade) or 0, label = value.label, grade_label = value.grade_label }
    end)
    if not ok then return nil, TSL('main_esx_spelercontrole_mislukt') end
    return job
end
exports('GetJob', getJob)
local noticeTimes = {}
exports('Notify', function(id, data, cooldownMs)
    id = tonumber(id)
    if not id or id % 1 ~= 0 or id <= 0 or not GetPlayerName(id) then return false end
    if type(data) == 'string' then data = { description = data } end
    if type(data) ~= 'table' then return false end
    local copy = {}; for k, v in pairs(data) do copy[k] = v end
    local cooldown = tonumber(cooldownMs) or 0
    if cooldown ~= cooldown or math.abs(cooldown) == math.huge or cooldown < 0 then return false end
    if cooldown > 0 then
        local owner = GetInvokingResource() or GetCurrentResourceName()
        noticeTimes[owner] = noticeTimes[owner] or {}
        local players = noticeTimes[owner]
        players[id] = players[id] or {}
        local key, now = tostring(copy.id or 'default'), GetGameTimer()
        if players[id][key] and now - players[id][key] < cooldown then return false end
        players[id][key] = now
        copy.id = owner .. ':' .. key
    end
    TriggerClientEvent('ts_bridge:notify', id, copy)
    return true
end)
AddEventHandler('playerDropped', function()
    for _, players in pairs(noticeTimes) do players[source] = nil end
end)
AddEventHandler('onResourceStop', function(name) noticeTimes[name] = nil end)
exports('AlertJobs', function(jobs, data, coords, seconds)
    if type(jobs) ~= 'table' or type(data) ~= 'table' or type(coords) ~= 'table' then return 0 end
    for _, key in ipairs({ 'x', 'y', 'z' }) do
        local n = coords[key]
        if type(n) ~= 'number' or n ~= n or math.abs(n) == math.huge then return 0 end
    end
    local recipients = 0
    for _, playerId in ipairs(GetPlayers()) do
        local id = tonumber(playerId)
        local job = id and getJob(id)
        if job and jobs[job.name] == true then
            TriggerClientEvent('ts_bridge:jobAlert', id, data, coords, seconds)
            recipients = recipients + 1
        end
    end
    return recipients
end)
print(('[ts_bridge] %s gestart'):format(GetResourceMetadata(GetCurrentResourceName(), 'version', 0) or '?'))
