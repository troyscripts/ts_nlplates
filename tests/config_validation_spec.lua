dofile('locales/nl.lua'); dofile('locale.lua'); dofile('config.lua'); dofile('server_config.lua'); dofile('config_validation.lua')
assert(TSBridgeValidation.Validate(TSBridgeConfig, TSBridgeServer))
local c, s = TSBridgeConfig, TSBridgeServer
c.NotificationDuration = 0; s.Banking.Provider = 'typo'; s.MaxQueue = math.huge
assert(not TSBridgeValidation.Validate(c,s) and #TSBridgeValidation.errors == 3)
dofile('config.lua'); dofile('server_config.lua')
TSBridgeServer.Billing = nil; TSBridgeServer.Webhooks = { x = { secret = 'invalid-secret-token' } }
assert(not TSBridgeValidation.Validate(TSBridgeConfig,TSBridgeServer))
for _, e in ipairs(TSBridgeValidation.errors) do assert(not e:find('invalid-secret-token',1,true)) end
assert(not TSBridgeValidation.Validate(false, false))
TSBridgeConfig = nil; TSBridgeServer = nil
local api = {}; exports = function(n,f) api[n]=f end
function IsDuplicityVersion() return true end
function GetCurrentResourceName() return 'ts_bridge' end
function GetResourceMetadata() return '0.0.3' end
function RegisterCommand() end
dofile('server/framework.lua'); assert(TSBridge == nil, 'invalid config blocks operations')
dofile('shared_status.lua'); assert(not api.GetStatus().ready and next(api.GetStatus().features)==nil)
dofile('server/diagnostics.lua'); assert(not api.GetDiagnostics().configValid)
dofile('config.lua'); dofile('server_config.lua')
TSBridgeServer.UpdateCheck = nil; assert(TSBridgeValidation.Validate(TSBridgeConfig,TSBridgeServer), 'old configs supported')
print('PASS: config validation, finite ranges, provider typo, redaction, missing tables, fail closed, legacy optional update config')
