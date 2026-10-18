dofile('locales/nl.lua'); dofile('locale.lua'); dofile('config.lua'); dofile('server_config.lua')
local api, events, sent = {}, {}, {}
local owner, now = 'one', 10000
exports = function(n,f) api[n]=f end
function GetInvokingResource() return owner end
function GetCurrentResourceName() return 'ts_bridge' end
function GetResourceMetadata() return '0.0.3' end
function GetPlayerName(id) return (id==1 or id==2) and 'Test' or nil end
function GetGameTimer() return now end
function RegisterCommand() end
function AddEventHandler(n,f) events[n]=f end
function TriggerClientEvent(...) sent[#sent+1]={...} end
function GetResourceState(name) return name=='apex_billing' and 'stopped' or 'started' end
TSBridge = { BillingStatus = function() return { ready=false, provider='apex', reason='billing_unavailable' } end }
TSBridgeWebhookStatus = function() return {queued=0,pendingPhotos=0,destinations=0,capacity=32} end
dofile('server/main.lua')
local data = { id='notice', description='text' }
assert(api.Notify(1,data,5000)); assert(data.id=='notice')
assert(not api.Notify(1,data,5000)); assert(api.Notify(2,data,5000))
owner='two'; assert(api.Notify(1,data,5000)); owner='one'
assert(api.Notify(1,'old')); assert(api.Notify(1,'old'))
assert(not api.Notify(1,data,math.huge)); assert(not api.Notify(1.5,data,5000)); assert(not api.Notify(99,data,5000))
now=15000; assert(api.Notify(1,data,5000))
source=1; events.playerDropped(); assert(api.Notify(1,data,5000))
events.onResourceStop('one'); assert(api.Notify(2,data,5000))
dofile('server/diagnostics.lua'); local d=api.GetDiagnostics()
assert(d.configValid and not d.billing.ready and d.resources.apex_billing=='stopped' and d.webhooks.queued==0)
print('PASS: server throttle per owner/player/id, legacy API, finite input, disconnect/stop cleanup, diagnostics')
