dofile('locales/nl.lua'); dofile('locale.lua')
local api, events, stopped = {}, {}, {}
local bank, society, mutations = 100, 200, 0
local owner = 'ts_keycard'
local player={
 getAccount=function(name) assert(name=='bank');return {money=bank} end,
 addAccountMoney=function(name,n) assert(name=='bank');mutations=mutations+1;bank=bank+n end,
 removeAccountMoney=function(name,n) assert(name=='bank');mutations=mutations+1;bank=bank-n end
}
exports=setmetatable({
 es_extended={getSharedObject=function() return {GetPlayerFromId=function(id) return id==1 and player or nil end} end},
 okokBanking=setmetatable({}, {__index=function() error('No okok society export may be called') end})
},{__call=function(_,name,fn) api[name]=fn end})
function GetResourceState(name) return stopped[name] and 'stopped' or 'started' end
function GetPlayerName(id) return (id==1 or id==2) and 'test' or nil end
function GetInvokingResource() return owner end
function AddEventHandler(n,fn) events[n]=fn end
function TriggerEvent(name,key,cb)
 assert(name=='esx_addonaccount:getSharedAccount')
 cb(key=='society_police' and {money=society,addMoney=function(n) society=society+n end} or nil)
end
dofile('config.lua');dofile('server_config.lua');dofile('server/framework.lua');dofile('server/money.lua');dofile('server/billing.lua')
TSBridgeServer.Banking={Provider='okok',Resource='okokBanking'}
assert(api.GetMoney(1,'bank')==100)
assert(api.RemoveMoney(1,'bank',10).ok and bank==90 and mutations==1)
assert(api.AddMoney(1,'bank',10).ok and bank==100 and mutations==2)
assert(not api.RemoveMoney(1,'bank',101).ok and mutations==2)
stopped.okokBanking=true
assert(api.GetMoney(1,'bank')==nil)
assert(not api.RemoveMoney(1,'bank',10).ok and mutations==2)
assert(api.AddSocietyMoney('police',10).ok and society==210)
TSBridgeServer.Billing={Provider='okok',Resource='okokBilling'}
local invoice={issuerId=1,targetId=2,amount=10,society='society_police',label='Kaart'}
assert(not api.GetBillingStatus().ready and api.GetBillingStatus().reason=='billing_adapter_required')
assert(api.CreateInvoice(invoice).code=='billing_adapter_required')
assert(not api.RegisterBillingProvider(function() return {ok=true,id=1} end))
-- Alleen een later geverifieerde adapter IN okokBilling mag de provider activeren.
owner='okokBilling';assert(api.RegisterBillingProvider(function() return {ok=true,id=1} end))
owner='ts_keycard';assert(api.CreateInvoice(invoice).id==1)
events.onResourceStop('okokBilling');assert(not api.GetBillingStatus().ready)
assert(api.CreateInvoice(invoice).code=='billing_adapter_required')
print('PASS: okok ESX personal balance, no society exports, stopped bank, addon society, billing pending adapter')
