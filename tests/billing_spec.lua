dofile('locales/nl.lua'); dofile('locale.lua')
local api, events={},{}
local owner='test_billing'
exports=setmetatable({}, {__call=function(_,name,fn) api[name]=fn end})
function GetInvokingResource() return owner end
function GetCurrentResourceName() return 'ts_bridge' end
function GetResourceState() return 'started' end
function GetPlayerName(id) return (id==1 or id==2) and 'test' or nil end
function AddEventHandler(name,fn) events[name]=fn end
dofile('config.lua');dofile('server_config.lua');dofile('server/framework.lua');dofile('server/billing.lua')
TSBridgeServer.Billing.Provider='custom'; TSBridgeServer.Billing.Resource=''
local invoice={issuerId=1,targetId=2,amount=10,society='society_police',label='Politiekaart'}
assert(not api.GetBillingStatus().ready)
assert(api.CreateInvoice(invoice).code=='billing_unavailable')
local calls=0
local function handler(data)
 calls=calls+1;assert(data.requestingResource=='ts_keycard')
 assert(data.society=='society_police' and data.amount==10)
 return {ok=true,id='invoice:1'}
end
assert(not api.RegisterBillingProvider(handler))
TSBridgeServer.Billing.Resource='test_billing'
assert(api.RegisterBillingProvider(handler))
owner='ts_keycard';assert(not api.RegisterBillingProvider(handler))
assert(api.CreateInvoice(invoice).id=='invoice:1' and calls==1)
invoice.amount=-1;assert(not api.CreateInvoice(invoice).ok and calls==1);invoice.amount=10
invoice.targetId=99;assert(not api.CreateInvoice(invoice).ok and calls==1);invoice.targetId=2
owner='test_billing';api.RegisterBillingProvider(function() error('after write') end)
owner='ts_keycard';assert(api.CreateInvoice(invoice).uncertain)
owner='test_billing';api.RegisterBillingProvider(function() return {ok=true} end)
owner='ts_keycard';assert(api.CreateInvoice(invoice).code=='billing_missing_reference')
events.onResourceStop('test_billing');assert(not api.GetBillingStatus().ready)
assert(api.CreateInvoice(invoice).code=='billing_unavailable')
print('PASS: disabled billing, provider ownership, invoice validation, reference and uncertain errors, stop cleanup')
