if TSBridgeValidation and not TSBridgeValidation.valid then return end
local B = TSBridge
local function call(method, ...)
    if GetResourceState(TSBridgeServer.InventoryResource) ~= 'started' then return false, 'inventory_unavailable' end
    local provider = exports[TSBridgeServer.InventoryResource]
    return pcall(function(...) return provider[method](provider, ...) end, ...)
end
-- Read-exports behouden de providerresultaten; transportfouten worden nil + foutcode.
for name, method in pairs({
    GetItemSlots = 'Search', GetInventorySlot = 'GetSlot', GetEmptySlot = 'GetEmptySlot',
    GetInventory = 'GetInventory', GetInventoryItems = 'GetInventoryItems',
    GetItemCount = 'GetItemCount', GetInventories = 'GetInventories'
}) do
    exports(name, function(...)
        local ok, result, reason
        if method == 'Search' then
            local id, item, metadata = ...
            ok, result, reason = call(method, id, 'slots', item, metadata)
        else ok, result, reason = call(method, ...) end
        if not ok then return nil, 'inventory_call_failed' end
        return result, reason
    end)
end
exports('HasItem', function(id, item, amount, metadata, strict)
    amount = amount or 1
    if not B.PositiveInteger(amount) then return false, 'invalid_amount' end
    local ok, count = call('GetItemCount', id, item, metadata, strict)
    if not ok or type(count) ~= 'number' then return false, 'inventory_call_failed' end
    return count >= amount
end)
for name, method in pairs({ CanCarryItem = 'CanCarryItem', AddItem = 'AddItem', RemoveItem = 'RemoveItem' }) do
    exports(name, function(id, item, amount, ...)
        if not B.PositiveInteger(amount) or type(item) ~= 'string' or item == '' then return false, 'invalid_item_or_amount' end
        -- Geen AddItem-callback: deze bridge gebruikt altijd de synchrone retourwaarden.
        local args = table.pack(...)
        if name == 'AddItem' and args.n > 2 then return false, 'callback_not_supported' end
        local ok, result, reason = call(method, id, item, amount, table.unpack(args, 1, args.n))
        if not ok then return false, 'inventory_call_failed' end
        return result, reason
    end)
end
exports('SetItemMetadata', function(id, slot, metadata)
    if not B.PositiveInteger(slot) or type(metadata) ~= 'table' then return false, 'invalid_slot_or_metadata' end
    local ok, item = call('GetSlot', id, slot)
    if not ok or not item then return false, 'slot_not_found' end
    local success, result = call('SetMetadata', id, slot, metadata)
    if not success or result == false then return false, 'metadata_update_failed' end
    return true -- SetMetadata heeft geen eigen succesretour; aanroep zonder fout.
end)

local hooks, serial = {}, 0
local allowed = { swapItems = true, openInventory = true, createItem = true }
exports('RegisterInventoryHook', function(event, callback, options)
    local owner = GetInvokingResource()
    if not owner or not allowed[event] or not B.Callable(callback) then return nil, 'invalid_hook' end
    serial = serial + 1
    local token = serial
    local ok, providerId = call('registerHook', event, callback, options)
    if not ok or not providerId then return nil, 'hook_registration_failed' end
    hooks[token] = { owner = owner, providerId = providerId }
    return token
end)
exports('RemoveInventoryHook', function(token)
    local hook = hooks[token]
    if not hook or hook.owner ~= GetInvokingResource() then return false end
    local ok = call('removeHooks', hook.providerId)
    if ok then hooks[token] = nil end
    return ok
end)
AddEventHandler('onResourceStop', function(name)
    if name == TSBridgeServer.InventoryResource then hooks = {}; TriggerEvent('ts_bridge:inventoryStopped'); return end
    for token, hook in pairs(hooks) do
        if name == hook.owner or name == GetCurrentResourceName() then
            call('removeHooks', hook.providerId)
            hooks[token] = nil
        end
    end
end)
AddEventHandler('onResourceStart', function(name)
    if name == TSBridgeServer.InventoryResource then
        -- Lokale serverevent; aangesloten scripts registreren hun hooks opnieuw.
        TriggerEvent('ts_bridge:inventoryReady')
    end
end)
