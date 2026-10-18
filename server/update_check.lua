if TSBridgeValidation and not TSBridgeValidation.valid then return end
TSBridgeCheckForUpdates(GetCurrentResourceName(), TSBridgeServer.UpdateCheck or {
    Enabled = true, Repository = 'troyscripts/ts_brigde'
})
