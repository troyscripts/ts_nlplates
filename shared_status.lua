-- Alleen lezen: scripts kunnen API en beschikbare functies controleren.
local server = IsDuplicityVersion()
local names = server and {
    'GetPlayerData', 'HasJob', 'HasPermission', 'GetMoney', 'AddMoney', 'RemoveMoney',
    'GetSocietyBalance', 'AddSocietyMoney', 'RemoveSocietyMoney', 'GetItemSlots',
    'GetInventorySlot', 'GetEmptySlot', 'CanCarryItem', 'AddItem', 'RemoveItem',
    'SetItemMetadata', 'GetInventories', 'RegisterInventoryHook', 'RemoveInventoryHook',
    'CheckForUpdates', 'GetDiagnostics', 'GetWebhookStatus', 'CheckConfigVersion', 'Notify', 'AlertJobs', 'SendWebhook', 'GetStatus', 'GetJob', 'GetItemCount', 'HasItem',
    'CreateInvoice', 'GetInvoice', 'GetBillingStatus', 'RegisterBillingProvider'
} or {
    'RequestFirstPerson', 'ReleaseFirstPerson', 'SetCombatContext', 'GetCombatContext',
    'CheckConfigVersion', 'RegisterRadialMenu', 'RemoveRadialMenu', 'Notify', 'IsDead', 'GetTargetResource', 'AddGlobalPlayer', 'AddGlobalVehicle',
    'RemoveGlobalPlayer', 'RemoveGlobalVehicle', 'AddLocalEntity', 'RemoveLocalEntity',
    'UseItem', 'ProgressCircle', 'InputDialog', 'AlertDialog', 'GetStatus'
}
exports('GetStatus', function()
    if TSBridgeValidation and not TSBridgeValidation.valid then
        return { api = 1, version = GetResourceMetadata(GetCurrentResourceName(), 'version', 0),
            side = server and 'server' or 'client', features = {}, ready = false, configErrors = TSBridgeValidation.errors }
    end
    local features = {}
    for _, name in ipairs(names) do features[name] = true end
    local result = { api = 1, version = GetResourceMetadata(GetCurrentResourceName(), 'version', 0),
        side = server and 'server' or 'client', features = features }
    if server then
        result.framework = TSBridgeServer.Framework
        result.resources = {
            framework = TSBridgeServer.ESXResource, inventory = TSBridgeServer.InventoryResource,
            society = TSBridgeServer.SocietyResource, banking = TSBridgeServer.Banking.Resource
        }
        result.banking = TSBridgeServer.Banking.Provider
    else result.target = TSBridgeConfig.TargetResource end
    return result
end)
