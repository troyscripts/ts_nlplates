if TSBridgeValidation and not TSBridgeValidation.valid then return end
-- Generiek factuurcontract. Geen verzonnen exports voor een specifiek billingproduct.
local provider
local function failure(code, uncertain)
    return { ok = false, code = code, uncertain = uncertain == true }
end
exports('RegisterBillingProvider', function(handler)
    local owner = GetInvokingResource()
    local configured = TSBridgeServer.Billing.Resource
    if (TSBridgeServer.Billing.Provider ~= 'custom' and TSBridgeServer.Billing.Provider ~= 'okok') or not owner or configured == '' or owner ~= configured or not TSBridge.Callable(handler) then
        return false, 'provider_not_allowed'
    end
    provider = { owner = owner, handler = handler }
    return true
end)
exports('CreateInvoice', function(invoice)
    if type(invoice) ~= 'table' then return failure('invalid_invoice') end
    if not TSBridge.PositiveInteger(invoice.issuerId) or not GetPlayerName(invoice.issuerId)
        or not TSBridge.PositiveInteger(invoice.targetId) or not GetPlayerName(invoice.targetId) then
        return failure('player_not_found')
    end
    if not TSBridge.PositiveInteger(invoice.amount) then return failure('invalid_amount') end
    if type(invoice.label) ~= 'string' or #invoice.label == 0 or #invoice.label > 200 or invoice.label:find('%c') then
        return failure('invalid_label')
    end
    if type(invoice.society) ~= 'string' or #invoice.society == 0 or #invoice.society > 100 then
        return failure('invalid_society')
    end
    if TSBridgeServer.Billing.Provider == 'apex' then
        if GetResourceState(TSBridgeServer.Billing.Resource) ~= 'started' then return failure('billing_unavailable') end
        local player, reason = TSBridge.Player(invoice.issuerId)
        if not player then return failure(reason) end
        local jobOk, job = pcall(player.getJob)
        if not jobOk or type(job) ~= 'table' or type(job.name) ~= 'string' then return failure('invalid_issuer_job') end
        if invoice.society ~= job.name and invoice.society ~= 'society_' .. job.name then
            return failure('society_job_mismatch')
        end
        -- Apex bepaalt zelf de issuer-society uit de job; nooit een willekeurige rekening.
        -- Dit maakt een factuur, en boekt geen ontvangst op de society.
        local called, accepted, reason, info = pcall(function()
            return exports[TSBridgeServer.Billing.Resource]:Bill({
                issuer = invoice.issuerId, recipient = invoice.targetId,
                issueAs = 'society', recipientType = 'player', title = invoice.label,
                items = { { label = invoice.label, qty = 1, price = invoice.amount } },
                vatRate = 0
            })
        end)
        if not called then return failure('billing_provider_error', true) end
        if accepted ~= true then return failure(reason or 'billing_rejected') end
        if type(info) ~= 'table' or not info.id then return failure('billing_missing_reference', true) end
        return { ok = true, id = info.id, number = info.number, uncertain = false }
    end
    if TSBridgeServer.Billing.Provider ~= 'custom' and TSBridgeServer.Billing.Provider ~= 'okok' then return failure('billing_unavailable') end
    if TSBridgeServer.Billing.Provider == 'okok' and not provider then return failure('billing_adapter_required') end
    if not provider or provider.owner ~= TSBridgeServer.Billing.Resource
        or GetResourceState(provider.owner) ~= 'started' then return failure('billing_unavailable') end
    local requester = GetInvokingResource()
    if not requester then return failure('missing_requester') end
    -- Alleen gedocumenteerde gegevens, geen blind doorgestuurde clientpayload.
    local ok, result = pcall(provider.handler, {
        issuerId = invoice.issuerId, targetId = invoice.targetId,
        amount = invoice.amount, society = invoice.society, label = invoice.label,
        requestingResource = requester
    })
    if not ok or type(result) ~= 'table' or type(result.ok) ~= 'boolean' then
        -- Provider kan al een factuur hebben geschreven: nooit automatisch herhalen.
        return failure('billing_provider_error', true)
    end
    if result.ok and (type(result.id) ~= 'string' and type(result.id) ~= 'number') then
        return failure('billing_missing_reference', true)
    end
    return result -- ok=true betekent aangemaakt, niet betaald.
end)
local function billingStatus()
    local name = TSBridgeServer.Billing.Resource
    local mode = TSBridgeServer.Billing.Provider
    local needsAdapter = (mode == 'okok' or mode == 'custom') and provider == nil
    local reason = mode == 'none' and 'billing_disabled'
        or (needsAdapter and 'billing_adapter_required')
        or (GetResourceState(name) ~= 'started' and 'billing_resource_not_started') or nil
    return { resource = name, provider = TSBridgeServer.Billing.Provider,
        reason = reason,
        ready = GetResourceState(name) == 'started' and (TSBridgeServer.Billing.Provider == 'apex'
            or ((TSBridgeServer.Billing.Provider == 'custom' or TSBridgeServer.Billing.Provider == 'okok')
                and provider ~= nil and provider.owner == name)) }

end
TSBridge.BillingStatus = billingStatus
exports('GetBillingStatus', billingStatus)
AddEventHandler('onResourceStop', function(name)
    if provider and provider.owner == name then provider = nil end
end)

exports('GetInvoice', function(id)
    if not TSBridge.PositiveInteger(id) then return nil, 'invalid_invoice_id' end
    if TSBridgeServer.Billing.Provider ~= 'apex' or GetResourceState(TSBridgeServer.Billing.Resource) ~= 'started' then
        return nil, 'billing_unavailable'
    end
    local ok, invoice = pcall(function() return exports[TSBridgeServer.Billing.Resource]:GetInvoice(id) end)
    if not ok then return nil, 'billing_provider_error' end
    return invoice
end)
