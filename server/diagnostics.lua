local function diagnostics()
    local result = { version = GetResourceMetadata(GetCurrentResourceName(), 'version', 0),
        configValid = not TSBridgeValidation or TSBridgeValidation.valid,
        configErrors = TSBridgeValidation and TSBridgeValidation.errors or {}, resources = {} }
    if not result.configValid then return result end
    result.framework = TSBridgeServer.Framework
    local names = { 'ox_lib', TSBridgeConfig.TargetResource, TSBridgeServer.InventoryResource, TSBridgeServer.SocietyResource }
    if TSBridgeServer.Framework == 'esx' then names[#names+1] = TSBridgeServer.ESXResource end
    if TSBridgeServer.Screenshots then names[#names+1] = TSBridgeServer.ScreenshotResource end
    for _, key in ipairs({ 'Banking', 'Billing' }) do
        local cfg = TSBridgeServer[key]
        if cfg.Provider ~= 'none' and cfg.Provider ~= 'esx' and cfg.Resource ~= '' then names[#names+1] = cfg.Resource end
    end
    for _, name in ipairs(names) do result.resources[name] = GetResourceState(name) end
    result.billing = TSBridge and TSBridge.BillingStatus and TSBridge.BillingStatus() or { ready=false, reason='billing_unavailable' }
    result.webhooks = TSBridgeWebhookStatus and TSBridgeWebhookStatus() or nil
    local update = TSBridgeServer.UpdateCheck or { Enabled=true, Repository='troyscripts/ts_brigde' }
    result.updateCheckConfigured = update.Enabled == true and update.Repository ~= ''
    return result
end
exports('GetDiagnostics', diagnostics)
RegisterCommand('ts_bridge_check', function(src)
    if src ~= 0 then return end
    local d = diagnostics()
    print(('[ts_bridge] %s | config: %s'):format(d.version or '?', d.configValid and 'OK' or 'FOUT'))
    for _, field in ipairs(d.configErrors) do print(TSL('validation_error'):format(field)) end
    if not d.configValid then return end
    for name, state in pairs(d.resources) do print(('[ts_bridge] %s: %s'):format(name, state)) end
    print(('[ts_bridge] billing %s: %s (%s)'):format(d.billing.provider or '?', tostring(d.billing.ready), d.billing.reason or 'geen adapterfout'))
    if d.webhooks then print(('[ts_bridge] logs: %d/%d | screenshots: %d | bestemmingen: %d'):format(
        d.webhooks.queued, d.webhooks.capacity, d.webhooks.pendingPhotos, d.webhooks.destinations)) end
    if d.webhooks then
        print('[ts_bridge] Laatste screenshot: ' .. (d.webhooks.lastPhoto or 'onbekend'))
        print('[ts_bridge] Laatste Discord-resultaat: ' .. (d.webhooks.lastDelivery or 'onbekend'))
        print('[ts_bridge] Laatste Discord-fout: ' .. (d.webhooks.lastFailure or 'geen'))
    end
    print(('[ts_bridge] GitHub geconfigureerd: %s'):format(tostring(d.updateCheckConfigured)))
end, false)
