TSBridgeValidation = { errors = {}, valid = true }
local V = TSBridgeValidation
local function issue(path) V.errors[#V.errors+1] = path end
local function text(t, key, path, optional)
    local v = t[key]
    if optional and v == '' then return end
    if type(v) ~= 'string' or v == '' or #v > 200 or v:find('%c') then issue(path .. '.' .. key) end
end
local function integer(t, key, path, minimum, maximum)
    local v = t[key]
    if type(v) ~= 'number' or v ~= v or v % 1 ~= 0 or v < minimum or v > maximum then issue(path .. '.' .. key) end
end
local function enum(t, key, path, allowed)
    if type(t[key]) ~= 'string' or not allowed[t[key]] then issue(path .. '.' .. key) end
end
local function validate(shared, server)
    V.errors = {}
    if type(shared) ~= 'table' then issue('TSBridgeConfig') else
        for _, key in ipairs({ 'Locale', 'NotificationTitle', 'WaypointKey', 'InventoryResource', 'TargetResource' }) do text(shared, key, 'TSBridgeConfig') end
        -- Nieuwe velden zijn optioneel bij migratie; de configversie waarschuwt.
        if shared.AlertDismissKey ~= nil then text(shared, 'AlertDismissKey', 'TSBridgeConfig') end
        if shared.AlertBlip ~= nil and type(shared.AlertBlip) ~= 'boolean' then issue('TSBridgeConfig.AlertBlip') end
        if shared.AlertLocation ~= nil then
            local loc = shared.AlertLocation
            if type(loc) ~= 'table' then issue('TSBridgeConfig.AlertLocation') else
                text(loc, 'MapResource', 'TSBridgeConfig.AlertLocation')
                for _, key in ipairs({'ShowArea', 'ShowPostcode', 'ShowStreet'}) do
                    if type(loc[key]) ~= 'boolean' then issue('TSBridgeConfig.AlertLocation.' .. key) end
                end
                local distance = loc.MaxPostcodeDistance
                if type(distance) ~= 'number' or distance ~= distance or distance < 0 or distance == math.huge then
                    issue('TSBridgeConfig.AlertLocation.MaxPostcodeDistance')
                end
            end
        end
        integer(shared, 'NotificationDuration', 'TSBridgeConfig', 1, 300000)
        if type(shared.DeadStateKeys) ~= 'table' then issue('TSBridgeConfig.DeadStateKeys')
        else for k,v in pairs(shared.DeadStateKeys) do
            if type(k) ~= 'number' or k % 1 ~= 0 or k < 1 or type(v) ~= 'string' or v == '' then issue('TSBridgeConfig.DeadStateKeys'); break end
        end end
    end
    if server ~= nil then
        if type(server) ~= 'table' then issue('TSBridgeServer') else
            enum(server, 'Framework', 'TSBridgeServer', { esx=true, standalone=true })
            for _, key in ipairs({ 'ESXResource', 'InventoryResource', 'SocietyResource', 'ScreenshotResource' }) do text(server, key, 'TSBridgeServer') end
            if type(server.Screenshots) ~= 'boolean' then issue('TSBridgeServer.Screenshots') end
            integer(server, 'ScreenshotTimeoutMs', 'TSBridgeServer', 100, 300000)
            integer(server, 'MaxImageBytes', 'TSBridgeServer', 1, 25*1024*1024)
            integer(server, 'MaxQueue', 'TSBridgeServer', 1, 1000)
            for name, choices in pairs({ Banking={apex=true,esx=true,okok=true}, Billing={apex=true,custom=true,none=true,okok=true} }) do
                local t = server[name]
                if type(t) ~= 'table' then issue('TSBridgeServer.' .. name) else
                    enum(t, 'Provider', 'TSBridgeServer.' .. name, choices)
                    text(t, 'Resource', 'TSBridgeServer.' .. name, t.Provider == 'none' or t.Provider == 'esx')
                end
            end
            if type(server.SocietyAccounts) ~= 'table' then issue('TSBridgeServer.SocietyAccounts') else
                for alias, names in pairs(server.SocietyAccounts) do
                    if type(alias) ~= 'string' or alias == '' or type(names) ~= 'table' or #names == 0 then issue('TSBridgeServer.SocietyAccounts')
                    else for _, name in pairs(names) do if type(name) ~= 'string' or name == '' then issue('TSBridgeServer.SocietyAccounts') end end end
                end
            end
            if type(server.Webhooks) ~= 'table' then issue('TSBridgeServer.Webhooks') else
                for owner, routes in pairs(server.Webhooks) do
                    if type(owner) ~= 'string' or type(routes) ~= 'table' then issue('TSBridgeServer.Webhooks') else
                        for route, url in pairs(routes) do
                            if type(route) ~= 'string' or type(url) ~= 'string' or (url ~= '' and not (
                                url:match('^https://discord%.com/api/webhooks/%d+/[%w_-]+$') or
                                url:match('^https://discord%.com/api/v%d+/webhooks/%d+/[%w_-]+$'))) then issue('TSBridgeServer.Webhooks (route-URL)') end
                        end
                    end
                end
            end
            if server.UpdateCheck ~= nil then
                local u = server.UpdateCheck
                if type(u) ~= 'table' then issue('TSBridgeServer.UpdateCheck') else
                    if type(u.Enabled) ~= 'boolean' then issue('TSBridgeServer.UpdateCheck.Enabled') end
                    local owner, repo
                    if type(u.Repository) == 'string' then owner, repo = u.Repository:match('^([%w][%w-]*)/([%w_.-]+)$') end
                    if u.Repository ~= '' and (not owner or repo == '.' or repo == '..') then issue('TSBridgeServer.UpdateCheck.Repository') end
                end
            end
        end
    end
    V.valid = #V.errors == 0
    return V.valid, V.errors
end
V.Validate = validate
V.Report = function()
    if V.valid then return end
    for _, field in ipairs(V.errors) do print(TSL('validation_error'):format(field)) end
end
validate(TSBridgeConfig)
V.Report()
