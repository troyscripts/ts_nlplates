if TSBridgeValidation and not TSBridgeValidation.valid then return end
-- Interne helpers; mutaties uitsluitend via serverexports, nooit via net-events.
TSBridge = TSBridge or {}
local B = TSBridge
function B.Callable(value)
    if type(value) == 'function' then return true end
    local mt = type(value) == 'table' and getmetatable(value)
    return type(mt) == 'table' and mt.__call ~= nil
end
function B.Finite(value)
    return type(value) == 'number' and value == value and math.abs(value) < math.huge
end
function B.PositiveInteger(value)
    return B.Finite(value) and value > 0 and value % 1 == 0 and value <= 9007199254740991
end
function B.Player(id)
    if not B.PositiveInteger(id) then return nil, 'invalid_player_id' end
    if TSBridgeServer.Framework ~= 'esx' then return nil, 'framework_unsupported' end
    if GetResourceState(TSBridgeServer.ESXResource) ~= 'started' then return nil, 'esx_unavailable' end
    local ok, player = pcall(function()
        return exports[TSBridgeServer.ESXResource]:getSharedObject().GetPlayerFromId(id)
    end)
    if not ok then return nil, 'player_lookup_failed' end
    if not player then return nil, 'player_not_found' end
    return player
end
local function data(id)
    local player, reason = B.Player(id)
    if not player then return nil, reason end
    local ok, value = pcall(function()
        local job = player.getJob()
        return {
            source = id, identifier = player.getIdentifier(), name = player.getName(),
            group = player.getGroup(),
            job = type(job) == 'table' and {
                name = job.name, grade = tonumber(job.grade), label = job.label, grade_label = job.grade_label
            } or nil
        }
    end)
    if not ok then return nil, 'player_data_failed' end
    return value
end
exports('GetPlayerData', data)
exports('HasJob', function(id, jobs, minimum)
    minimum = minimum or 0
    if type(jobs) ~= 'table' or not B.Finite(minimum) or minimum < 0 or minimum % 1 ~= 0 then return false end
    local player = data(id)
    local job = player and player.job
    return job ~= nil and jobs[job.name] == true and B.Finite(job.grade) and job.grade >= minimum
end)
exports('HasPermission', function(id, rules)
    if not B.PositiveInteger(id) or not GetPlayerName(id) or type(rules) ~= 'table' then return false end
    -- Expliciete OR: ACE, ESX-groep of toegestane job met minimumrang.
    if type(rules.ace) == 'string' and rules.ace ~= '' and IsPlayerAceAllowed(id, rules.ace) then return true end
    local player = data(id)
    if not player then return false end
    if type(rules.groups) == 'table' and rules.groups[player.group] == true then return true end
    local minimum = rules.minimumGrade or 0
    local job = player.job
    return type(rules.jobs) == 'table' and job ~= nil and rules.jobs[job.name] == true
        and B.Finite(minimum) and minimum >= 0 and minimum % 1 == 0
        and B.Finite(job.grade) and job.grade >= minimum
end)
