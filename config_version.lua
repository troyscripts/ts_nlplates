local function check(current, required, owner)
    if type(required) ~= 'string' or required == '' then return false end
    local ok = current == required
    if IsDuplicityVersion() then
        if ok then print(TSL('config_version_ok'):format(owner, required))
        else print(TSL('config_version_old'):format(owner, tostring(current or 'zonder versie'), required)) end
    end
    return ok
end
exports('CheckConfigVersion', function(current, required)
    return check(current, required, GetInvokingResource() or GetCurrentResourceName())
end)
check(type(TSBridgeConfig) == 'table' and TSBridgeConfig.Version, '0.0.6', GetCurrentResourceName())
