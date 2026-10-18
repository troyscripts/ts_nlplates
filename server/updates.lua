if TSBridgeValidation and not TSBridgeValidation.valid then return end
-- Alleen metadata ophalen; nooit externe code uitvoeren of installeren.
local active = {}
local function parse(value)
    if type(value) ~= 'string' or #value > 64 then return end
    local a,b,c = value:match('^%s*v?(%d+)%.(%d+)%.(%d+)%s*$')
    if not a then return end
    local result = {tonumber(a),tonumber(b),tonumber(c)}
    for _, n in ipairs(result) do if n > 9007199254740991 then return end end
    return result
end
local function check(resource, settings)
    if type(settings) ~= 'table' or settings.Enabled == false then return false end
    local repo = settings.Repository
    local owner, name
    if type(repo) == 'string' then owner, name = repo:match('^([%w][%w-]*)/([%w_.-]+)$') end
    local file = settings.File or 'version.json'
    local branch = settings.Branch
    local function log(message) print('[' .. resource .. '] ' .. message) end
    if not owner or name == '.' or name == '..' or (file ~= 'version.json' and file ~= 'version.txt')
        or (branch ~= nil and (type(branch) ~= 'string' or branch == '' or not branch:match('^[%w_./-]+$'))) then
        log(TSL('updates_invalid_settings')); return false
    end
    if active[resource] then return false end
    local installed = GetResourceMetadata(resource, 'version', 0)
    local current = parse(installed)
    if not current then log(TSL('updates_invalid_local')); return false end
    local token = {}; active[resource] = token
    local repository = 'https://github.com/' .. repo
    local endpoint = 'https://api.github.com/repos/' .. repo .. '/contents/' .. file
    if branch then endpoint = endpoint .. '?ref=' .. branch:gsub('([^%w_.~-])', function(c) return ('%%%02X'):format(c:byte()) end) end
    CreateThread(function()
        Wait(3000)
        if active[resource] ~= token then return end
        local completed = false
        SetTimeout(15000, function()
            if completed or active[resource] ~= token then return end
            completed = true; log(TSL('updates_timeout'))
        end)
        local requested = pcall(PerformHttpRequest, endpoint, function(status, body)
            if completed or active[resource] ~= token then return end
            completed = true
            if status ~= 200 then log(TSL('updates_http'):format(tostring(status))); return end
            if type(body) ~= 'string' or #body > 16384 then log(TSL('updates_invalid_remote')); return end
            local latest, raw, download
            if file == 'version.json' then
                local ok, data = pcall(json.decode, body)
                if ok and type(data) == 'table' then raw, download = data.version, data.download end
            else raw = body end
            latest = parse(raw)
            if not latest then log(TSL('updates_invalid_remote')); return end
            local comparison = 0
            for i=1,3 do if latest[i] ~= current[i] then comparison = latest[i] > current[i] and 1 or -1; break end end
            local remote = table.concat(latest, '.')
            if comparison > 0 then
                log(TSL('updates_available'):format(installed, remote))
                if type(download) ~= 'string' or #download > 500 or download:find('[%c%s%^]')
                    or (download ~= repository and download:sub(1,#repository+1) ~= repository .. '/') then download = repository end
                log('Download: ' .. download)
            elseif comparison == 0 then log(TSL('updates_current'):format(installed))
            else log(TSL('updates_local_newer'):format(installed, remote)) end
        end, 'GET', '', { ['Accept']='application/vnd.github.raw+json', ['User-Agent']='TroyScripts-ts_bridge',
            ['X-GitHub-Api-Version']='2022-11-28' }, {followLocation=false})
        if not requested and not completed then completed=true; log(TSL('updates_request_failed')) end
    end)
    return true
end
TSBridgeCheckForUpdates = check
exports('CheckForUpdates', function(settings)
    local owner = GetInvokingResource()
    if not owner then return false end
    return check(owner, settings)
end)
AddEventHandler('onResourceStop', function(name) active[name] = nil end)
