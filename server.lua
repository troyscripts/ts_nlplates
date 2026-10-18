local resource = GetCurrentResourceName()
local expectedConfig = '1.0.2'
local repository = 'https://github.com/troyscripts/ts_nlplates'
local raw = 'https://raw.githubusercontent.com/troyscripts/ts_nlplates/'
local busy = false
local lastCheck = nil

local function log(message)
    print(('[%s] %s'):format(resource, message))
end

local function parseVersion(value)
    if type(value) ~= 'string' then return nil end
    local major, minor, patch = value:match('^v?(%d+)%.(%d+)%.(%d+)$')
    if not major then return nil end
    return { tonumber(major), tonumber(minor), tonumber(patch) }
end

local function compare(left, right)
    for i = 1, 3 do
        if left[i] > right[i] then return 1 end
        if left[i] < right[i] then return -1 end
    end
    return 0
end

local function status()
    local current = GetResourceMetadata(resource, 'version', 0) or 'onbekend'
    log(('Script %s | config %s | verwacht %s | %s'):format(current,
        tostring(Config.Version), expectedConfig,
        Config.Version == expectedConfig and 'config OK' or 'CONFIG BIJWERKEN'))
    return current
end

local function checkVersion()
    local current = status()
    if not Config.VersionCheck then
        log('Versiechecker uitgeschakeld in config.lua.')
        return
    end
    if busy then log('Versiecontrole loopt al.'); return end
    if lastCheck and os.time() - lastCheck < 60 then
        log('Wacht 60 seconden tussen versiecontroles.')
        return
    end
    local localVersion = parseVersion(current)
    if not localVersion then log('Ongeldige scriptversie in fxmanifest.lua.'); return end
    busy, lastCheck = true, os.time()
    local finished = false
    local function finish(message)
        if finished then return end
        finished, busy = true, false
        log(message)
    end
    SetTimeout(15000, function()
        finish('Versiecontrole verlopen: GitHub reageerde niet binnen 15 seconden. Script blijft werken.')
    end)

    local function request(branch)
        PerformHttpRequest(raw .. branch .. '/version.json', function(code, body)
            if finished then return end
            if code == 404 and branch == 'main' then request('master'); return end
            if code ~= 200 then
                finish(('Versiecontrole mislukt (HTTP %s). Controleer of version.json openbaar op main/master staat.')
                    :format(tostring(code)))
                return
            end
            if type(body) ~= 'string' or #body > 16384 then
                finish('Versiecontrole mislukt: ongeldige antwoordgrootte.'); return
            end
            local ok, data = pcall(json.decode, body)
            local remote = ok and type(data) == 'table' and parseVersion(data.version)
            if not remote then
                finish('Versiecontrole mislukt: version.json moet een versie zoals 1.0.0 bevatten.'); return
            end
            local result = compare(remote, localVersion)
            if result > 0 then
                finish(('Update beschikbaar: %s -> %s | %s'):format(current, data.version, repository))
            elseif result == 0 then
                finish(('Up-to-date: %s.'):format(current))
            else
                finish(('Lokale versie %s is nieuwer dan GitHub (%s).'):format(current, data.version))
            end
        end, 'GET', '', { ['Accept'] = 'application/json' })
    end
    request('main')
end

CreateThread(function()
    Wait(1000)
    checkVersion()
end)

-- Alleen serverconsole; geen netwerk-event of commando voor spelers.
RegisterCommand('ts_nlplates_check', function(source)
    if source ~= 0 then return end
    checkVersion()
end, true)
