TSTaxi = {}
function TSTaxi.isModel(model)
    if not Config.Taxi or not Config.Taxi.enabled then return false end
    model = tonumber(model)
    if not model then return false end
    for _, name in ipairs(Config.Taxi.models or {}) do
        local hash = type(name) == 'number' and name or joaat(name)
        if (model & 0xffffffff) == (hash & 0xffffffff) then return true end
    end
    return false
end
function TSTaxi.isBusiness(job, garage)
    return Config.Taxi and Config.Taxi.enabled and
        ((Config.Taxi.jobs or {})[job] == true or (Config.Taxi.garages or {})[garage] == true) or false
end
