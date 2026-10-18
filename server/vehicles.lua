if TSBridgeValidation and not TSBridgeValidation.valid then return end
local C = TSBridgeVehicles
local function enabled()
    assert(C and C.Enabled, 'vehicle_integration_disabled')
end
local function query(sql, params)
    enabled()
    assert(C.Ownership == 'esx' and TSBridgeServer.Framework == 'esx', 'vehicle_ownership_unsupported')
    assert(GetResourceState(C.DatabaseResource) == 'started', 'vehicle_database_unavailable')
    local pending = promise.new()
    exports[C.DatabaseResource]:query(sql, params or {}, function(rows)
        if rows == nil then pending:reject('vehicle_query_failed') else pending:resolve(rows) end
    end)
    return Citizen.Await(pending)
end
exports('VehicleExists', function(plate)
    return query('SELECT plate FROM owned_vehicles WHERE plate = ? LIMIT 1', {plate})[1] ~= nil
end)
exports('GetVehicleOwner', function(plate)
    local row = query([[SELECT v.*, CONCAT_WS(' ', u.firstname, u.lastname) AS owner_name
        FROM owned_vehicles v LEFT JOIN users u ON u.identifier = v.owner
        WHERE v.plate = ? LIMIT 1]], {plate})[1]
    if not row then return nil end
    if row.job_vehicle == true or tonumber(row.job_vehicle) == 1 then
        return {job = tostring(row.owner):gsub('^society_', '')}
    end
    return {identifier = row.owner, name = row.owner_name}
end)
exports('GetCompanyLabel', function(job)
    local row = query('SELECT label FROM jobs WHERE name = ? LIMIT 1', {job})[1]
    return row and row.label or job
end)
exports('GetJobGarages', function()
    enabled()
    assert(C.Garage.Provider == 'jg', 'garage_provider_unsupported')
    assert(GetResourceState(C.Garage.Resource) == 'started', 'garage_unavailable')
    return exports[C.Garage.Resource]:TSGetJobGarages()
end)
exports('GenerateVehiclePlate', function()
    enabled()
    if C.Dealer.Provider ~= 'jg' or GetInvokingResource() ~= C.Dealer.Resource then return false end
    if GetResourceState(C.PlatesResource) ~= 'started' then return false end
    return exports[C.PlatesResource]:GeneratePlate()
end)
exports('VehicleIntegrationReady', function()
    enabled()
    assert(C.Inventory == 'ox', 'vehicle_inventory_unsupported')
    assert(TSBridgeConfig.InventoryResource == TSBridgeServer.InventoryResource, 'inventory_config_mismatch')
    assert(GetResourceState(TSBridgeServer.InventoryResource) == 'started', 'inventory_unavailable')
    query('SELECT plate FROM owned_vehicles LIMIT 0')
    return true
end)
exports('GetGloveboxId', function(raw)
    enabled()
    assert(C.Inventory == 'ox', 'vehicle_inventory_unsupported')
    return 'glove' .. (GetConvarBool('inventory:trimplate', true) and raw:upper():match('^%s*(.-)%s*$') or raw)
end)
