if TSBridgeValidation and not TSBridgeValidation.valid then return end
local C = TSBridgeVehicles
exports('CloseInventory', function()
    if GetResourceState(TSBridgeConfig.InventoryResource) ~= 'started' then return false end
    exports[TSBridgeConfig.InventoryResource]:closeInventory()
    return true
end)
local function keys(action, vehicle)
    if not C or not C.Enabled then return false, 'vehicle_integration_disabled' end
    if C.Keys.Provider == 'none' then return true end
    if C.Keys.Provider ~= 'mrnewb' then return false, 'keys_provider_unsupported' end
    if not DoesEntityExist(vehicle) then return false, 'vehicle_missing' end
    if GetResourceState(C.Keys.Resource) ~= 'started' then return false, 'keys_unavailable' end
    local ok, result = pcall(function()
        local provider = exports[C.Keys.Resource]
        return provider[action](provider, vehicle)
    end)
    return ok and result ~= false, ok and nil or 'keys_call_failed'
end
exports('GiveVehicleKeys', function(vehicle) return keys('GiveKeys', vehicle) end)
exports('RemoveVehicleKeys', function(vehicle) return keys('RemoveKeys', vehicle) end)
if C and C.Enabled and C.Garage.Provider == 'jg' then
    AddEventHandler(C.Garage.Resource .. ':client:TakeOutVehicle:config', function(vehicle, _, garageType)
        if garageType == 'job' and DoesEntityExist(vehicle) then
            TriggerEvent('ts_bridge:vehicle:jobSpawned', vehicle)
        end
    end)
end
