dofile('locales/nl.lua'); dofile('locale.lua')
local api, events = {}, {}
local owner = 'ts_keycard'
local cash, bank, society = 100, 500, 200
local failMode, denied, missing, invalidSociety, reads, mutations = nil, false, false, false, 0, 0
local player = {
 getJob = function() return {name='police',grade=7,grade_label='Leiding'} end,
 getIdentifier = function() return 'test:1' end, getName = function() return 'Test Agent' end,
 getGroup = function() return 'user' end,
 getMoney = function() return cash end, getAccount = function() return {money=bank} end,
 addMoney = function(n) mutations=mutations+1; cash=cash+n end,
 removeMoney = function(n)
  mutations=mutations+1
  if failMode == 'noop' then return false end
  cash=cash-n
  if failMode == 'throw_after' then error('provider') end
 end,
 addAccountMoney = function(a,n) assert(a=='bank'); bank=bank+n end,
 removeAccountMoney = function(a,n) assert(a=='bank'); bank=bank-n end
}
exports = setmetatable({es_extended={getSharedObject=function()
 return {GetPlayerFromId=function(id) return id==1 and player or nil end}
end}}, {__call=function(_,name,fn) api[name]=fn end})
function GetInvokingResource() return owner end
function GetCurrentResourceName() return 'ts_bridge' end
function GetPlayerName(id) return id==1 and 'Test' or nil end
function GetResourceState(name) return missing and 'stopped' or 'started' end
function IsPlayerAceAllowed(_,ace) return ace=='test.ace' end
function AddEventHandler(name,fn) events[name]=fn end
function TriggerEvent(name, account, callback)
 if name~='esx_addonaccount:getSharedAccount' then return end
 reads=reads+1
 if account~='society_police' then callback(nil); return end
 callback({ money=invalidSociety and {} or society,
  addMoney=setmetatable({}, {__call=function(_,amount) mutations=mutations+1; if not denied then society=society+amount end end}),
  removeMoney=function(amount) society=society-amount end })
end
dofile('config.lua'); dofile('server_config.lua'); dofile('server/framework.lua'); dofile('server/money.lua'); TSBridgeServer.Banking.Provider='esx'
assert(api.GetPlayerData(1).identifier=='test:1')
assert(api.GetPlayerData(99)==nil)
assert(api.HasJob(1,{police=true},7)); assert(not api.HasJob(1,{police=true},8))
assert(not api.HasJob(1,{ambulance=true},0))
assert(api.HasPermission(1,{ace='test.ace'})); assert(not api.HasPermission(1,{}))
assert(api.HasPermission(1,{groups={user=true}}))
assert(api.HasPermission(1,{jobs={police=true},minimumGrade=7}))
assert(not api.HasPermission(1,{jobs={police=true},minimumGrade=8}))
assert(not api.HasPermission(99,{ace='test.ace'}))
assert(api.GetMoney(1,'cash')==100); assert(api.GetMoney(1,'bank')==500)
assert(api.GetMoney(1,'invalid')==nil)
assert(api.RemoveMoney(1,'cash',10).ok and cash==90)
assert(api.AddMoney(1,'cash',10).ok and cash==100)
assert(api.RemoveMoney(1,'bank',20).ok and bank==480)
assert(api.AddMoney(1,'bank',20).ok and bank==500)
local n=mutations
for _,amount in ipairs({-1,0,0.1,math.huge,0/0}) do assert(not api.RemoveMoney(1,'cash',amount).ok) end
assert(api.RemoveMoney(1,'cash',101).code=='insufficient_funds'); assert(mutations==n)
failMode='noop'; local result=api.RemoveMoney(1,'cash',10)
assert(not result.ok and result.uncertain and cash==100)
failMode='throw_after'; result=api.RemoveMoney(1,'cash',10)
assert(not result.ok and result.uncertain and cash==90, 'do not claim money was refunded')
failMode=nil; assert(api.AddMoney(1,'cash',10).ok, 'lock released after exception')
local balance, resolved=api.GetSocietyBalance('police')
assert(balance==200 and resolved=='society_police')
local beforeReads=reads
assert(api.AddSocietyMoney('police',10).ok and society==210)
assert(reads>=beforeReads+2, 'fallback plus fresh snapshot after mutation')
assert(api.RemoveSocietyMoney('police',10).ok and society==200)
assert(api.RemoveSocietyMoney('police',201).code=='insufficient_funds')
assert(api.GetSocietyBalance('missing')==nil)
n=mutations; invalidSociety=true
assert(not api.AddSocietyMoney('police',10).ok and mutations==n)
invalidSociety=false; denied=true; result=api.AddSocietyMoney('police',10)
assert(not result.ok and result.uncertain and society==200)
denied=false
missing=true; assert(api.GetMoney(1,'cash')==nil); assert(not api.AddSocietyMoney('police',10).ok)
missing=false; TSBridgeServer.Framework='standalone'
assert(api.GetPlayerData(1)==nil); assert(not api.HasPermission(1,{groups={user=true}}))
assert(api.HasPermission(1,{ace='test.ace'}), 'ACE remains independent of framework')
TSBridgeServer.Framework='esx'
print('PASS: identity, permissions, cash/bank, validation, fresh society snapshots, failed mutations and locks')

local item={name='politie_sleutelkaart',slot=2,count=1,metadata={owner='test:1'}}
local hooks, removedHooks, serial = {}, {}, 0
exports.ox_inventory={
 Search=function(_,id,mode,name) assert(mode=='slots'); return {item} end,
 GetSlot=function(_,id,slot) return slot==2 and item or nil end,
 GetEmptySlot=function() return 3 end,
 GetItemCount=function() return 1 end,
 GetInventories=function() return {'stash:test'} end,
 CanCarryItem=function() return true end,
 AddItem=function() return false,'inventory_full' end,
 RemoveItem=function() return true end,
 SetMetadata=function(_,id,slot,metadata) item.metadata=metadata end,
 registerHook=function(_,name,cb,opts) serial=serial+1;hooks[serial]=cb;return serial end,
 removeHooks=function(_,id) removedHooks[#removedHooks+1]=id;hooks[id]=nil end
}
dofile('server/inventory.lua')
assert(api.GetItemSlots(1,'politie_sleutelkaart')[1]==item)
assert(api.GetEmptySlot(1)==3 and api.GetInventorySlot(1,2)==item)
assert(api.HasItem(1,'politie_sleutelkaart',1)); assert(not api.HasItem(1,'politie_sleutelkaart',2))
assert(not api.AddItem(1,'x',-1)); local ok,reason=api.AddItem(1,'x',1); assert(ok==false and reason=='inventory_full')
assert(api.CanCarryItem(1,'x',1)); assert(api.RemoveItem(1,'x',1))
assert(api.SetItemMetadata(1,2,{owner='new'}) and item.metadata.owner=='new')
assert(not api.SetItemMetadata(1,99,{}))
assert(api.GetInventories('stash')[1]=='stash:test')
local token=api.RegisterInventoryHook('swapItems',function() return false end)
assert(hooks[1]()==false, 'preserve deny return')
owner='other'; assert(not api.RemoveInventoryHook(token)); owner='ts_keycard'
assert(api.RemoveInventoryHook(token) and #removedHooks==1)
api.RegisterInventoryHook('openInventory',function() return false end)
events.onResourceStop('ts_keycard'); assert(#removedHooks==2)
local old=api.RegisterInventoryHook('createItem',function() end)
events.onResourceStop('ox_inventory')
local new=api.RegisterInventoryHook('createItem',function() end)
assert(old~=new and not api.RemoveInventoryHook(old))
events.onResourceStop('ts_bridge'); assert(#removedHooks==3)
missing=true; assert(api.GetInventorySlot(1,2)==nil); assert(not api.HasItem(1,'x',1))
assert(not api.AddItem(1,'x',1)); assert(api.RegisterInventoryHook('swapItems',function() end)==nil)
print('PASS: inventory results, metadata, capacity failure, hook ownership, cleanup and provider restart')
