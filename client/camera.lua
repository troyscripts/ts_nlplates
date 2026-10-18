if TSBridgeValidation and not TSBridgeValidation.valid then return end

-- Aanvragen blijven eigendom van de aanroepende resource; nooit net-events.
local requests = { ped = {}, vehicle = {} }
local views = { ped = {}, vehicle = {} }
local contexts = {}
local lastPed
local clearAll
local startWorker
local running = false
local function getView(scope)
    if scope == 'vehicle' then return GetFollowVehicleCamViewMode() end
    return GetFollowPedCamViewMode()
end
local function setView(scope, mode)
    if scope == 'vehicle' then SetFollowVehicleCamViewMode(mode)
    else SetFollowPedCamViewMode(mode) end
end
local function validKey(key)
    return type(key) == 'string' and #key > 0 and #key <= 100
end
local function aggregate()
    local result = { suspendCamera = false, suspendMeleeCancel = false }
    for _, entries in pairs(contexts) do
        for _, entry in pairs(entries) do
            result.suspendCamera = result.suspendCamera or entry.suspendCamera
            result.suspendMeleeCancel = result.suspendMeleeCancel or entry.suspendMeleeCancel
        end
    end
    return result
end
local function contextChanged()
    TriggerEvent('ts_bridge:combatContextChanged', aggregate())
end
local function restore(scope, force)
    local v = views[scope]
    if v.owned and (force or v.restore) and getView(scope) == 4 then
        setView(scope, v.previous or v.fallback or 1)
    end
    views[scope] = {}
end
local function enforce(scope)
    if not next(requests[scope]) then return end
    local ped = PlayerPedId()
    if not DoesEntityExist(ped) or IsEntityDead(ped) or IsPedFatallyInjured(ped) then return end
    local inVehicle = IsPedInAnyVehicle(ped, false)
    if (scope == 'vehicle') ~= inVehicle then return end
    local v, mode = views[scope], getView(scope)
    v.deadline = nil
    if mode ~= 4 then
        if not v.owned then v.previous, v.owned = mode, true end
        setView(scope, 4)
    end
end
local function release(owner, key, force)
    local removed = false
    for scope, entries in pairs(requests) do
        local owned = entries[owner]
        local entry = owned and owned[key]
        if entry then
            removed = true
            owned[key] = nil
            if not next(owned) then entries[owner] = nil end
            local v = views[scope]
            v.restore = v.restore or entry.restore or force
            if not next(entries) then
                v.deadline = GetGameTimer() + (force and 0 or entry.delay)
                if force or entry.delay == 0 then restore(scope, force) end
            end
        end
    end
    return removed
end

exports('RequestFirstPerson', function(key, options)
    local owner = GetInvokingResource()
    if not owner or not validKey(key) or type(options) ~= 'table' then return false end
    local scope = options.scope == nil and 'ped' or options.scope
    local delay = options.restoreDelayMs == nil and 0 or options.restoreDelayMs
    local fallback = options.defaultCamera == nil and 1 or options.defaultCamera
    if not requests[scope] or type(delay) ~= 'number' or delay ~= delay or delay % 1 ~= 0
        or delay < 0 or delay > 60000 or not ({[0]=true,[1]=true,[2]=true,[4]=true})[fallback]
        or (options.restore ~= nil and type(options.restore) ~= 'boolean') then return false end
    local ped = PlayerPedId()
    if not DoesEntityExist(ped) or IsEntityDead(ped) or IsPedFatallyInjured(ped) then return false end
    if lastPed and lastPed ~= ped then clearAll() end
    lastPed = ped
    -- Dezelfde key mag tegelijk een ped- en voertuigaanvraag hebben.
    requests[scope][owner] = requests[scope][owner] or {}
    requests[scope][owner][key] = { restore = options.restore ~= false, delay = delay }
    views[scope].fallback = views[scope].fallback or fallback
    views[scope].deadline = nil
    enforce(scope)
    startWorker()
    return true
end)
exports('ReleaseFirstPerson', function(key, forceRestore)
    local owner = GetInvokingResource()
    if not owner or not validKey(key) or (forceRestore ~= nil and type(forceRestore) ~= 'boolean') then return false end
    release(owner, key, forceRestore == true)
    return true
end)
exports('SetCombatContext', function(key, options)
    local owner = GetInvokingResource()
    if not owner or not validKey(key) then return false end
    if options == nil then
        if contexts[owner] then
            contexts[owner][key] = nil
            if not next(contexts[owner]) then contexts[owner] = nil end
        end
    else
        if type(options) ~= 'table' then return false end
        for _, name in ipairs({'suspendCamera', 'suspendMeleeCancel'}) do
            if options[name] ~= nil and type(options[name]) ~= 'boolean' then return false end
        end
        contexts[owner] = contexts[owner] or {}
        contexts[owner][key] = { suspendCamera = options.suspendCamera == true,
            suspendMeleeCancel = options.suspendMeleeCancel == true }
    end
    contextChanged()
    startWorker()
    return true
end)
exports('GetCombatContext', aggregate)

clearAll = function()
    requests = { ped = {}, vehicle = {} }
    restore('ped', true); restore('vehicle', true)
    contexts = {}; contextChanged()
end
startWorker = function()
    if running then return end
    running = true
    CreateThread(function()
      while true do
        local active = next(requests.ped) or next(requests.vehicle) or next(contexts)
            or views.ped.deadline or views.vehicle.deadline
        if not active then break end
        Wait(0)
        local ped = PlayerPedId()
        if (lastPed and lastPed ~= ped) or not DoesEntityExist(ped)
            or IsEntityDead(ped) or IsPedFatallyInjured(ped) then
            if active then clearAll() end
        else
            for scope, entries in pairs(requests) do
                if next(entries) then enforce(scope)
                elseif views[scope].deadline and GetGameTimer() >= views[scope].deadline then restore(scope, false) end
            end
        end
        lastPed = ped
      end
      running = false
    end)
end
AddEventHandler('onClientResourceStop', function(name)
    if name == GetCurrentResourceName() then clearAll(); return end
    for _, entries in pairs(requests) do
        local owned = entries[name]
        if owned then
            local keys = {}; for key in pairs(owned) do keys[#keys+1] = key end
            for _, key in ipairs(keys) do release(name, key, true) end
        end
    end
    if contexts[name] then contexts[name] = nil; contextChanged() end
end)
