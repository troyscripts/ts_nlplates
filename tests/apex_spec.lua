dofile('locales/nl.lua'); dofile('locale.lua')
local api, stopped, events = {}, {}, {}
local bank, society, bankCalls, billingCalls = 100, 200, 0, 0
local reject, throwAfter = false, false
local p = { getJob=function() return {name='police',grade=7} end }
exports=setmetatable({
 es_extended={getSharedObject=function() return {GetPlayerFromId=function(id) return (id==1 or id==2) and p or nil end} end},
 apex_banking={
  GetBalance=function(_,id) assert(id==1);return bank end,
  RemoveMoney=function(_,id,n,reason)
   bankCalls=bankCalls+1;assert(id==1 and reason=='kaart')
   if reject then return false end
   bank=bank-n;if throwAfter then error('after debit') end;return true
  end,
  AddMoney=function(_,id,n) bankCalls=bankCalls+1;bank=bank+n;return true end,
  AddBusinessMoney=function() error('Society must never use Apex business money') end
 },
 apex_billing={
  Bill=function(_,o)
   billingCalls=billingCalls+1
   assert(o.issuer==1 and o.recipient==2 and o.issueAs=='society')
   assert(o.items[1].price==10 and o.items[1].qty==1 and o.vatRate==0)
   if reject then return false,'no_item' end
   return true,nil,{id=25,number='TEST-25'}
  end,
  GetInvoice=function(_,id) return id==25 and {id=25,status='sent'} or nil end
 }
},{__call=function(_,name,fn) api[name]=fn end})
function GetResourceState(name) return stopped[name] and 'stopped' or 'started' end
function GetPlayerName(id) return (id==1 or id==2) and 'test' or nil end
function GetInvokingResource() return 'ts_keycard' end
function AddEventHandler(n,fn) events[n]=fn end
function TriggerEvent(name,account,cb)
 assert(name=='esx_addonaccount:getSharedAccount')
 cb(account=='society_police' and {money=society,addMoney=function(n) society=society+n end} or nil)
end
dofile('config.lua');dofile('server_config.lua');dofile('server/framework.lua');dofile('server/money.lua');dofile('server/billing.lua')
assert(api.GetMoney(1,'bank')==100)
assert(api.RemoveMoney(1,'bank',10,'kaart').ok and bank==90 and bankCalls==1)
assert(api.AddMoney(1,'bank',10).ok and bank==100)
reject=true;local r=api.RemoveMoney(1,'bank',10,'kaart');assert(not r.ok and not r.uncertain and bank==100)
reject=false;throwAfter=true;r=api.RemoveMoney(1,'bank',10,'kaart');assert(not r.ok and r.uncertain and bank==90)
throwAfter=false;stopped.apex_banking=true;local n=bankCalls
assert(not api.RemoveMoney(1,'bank',10,'kaart').ok and bankCalls==n, 'no fallback debit')
assert(api.AddSocietyMoney('police',10).ok and society==210 and bankCalls==n)
stopped.apex_banking=nil
local invoice={issuerId=1,targetId=2,amount=10,society='society_police',label='Politiekaart'}
assert(api.GetBillingStatus().ready)
r=api.CreateInvoice(invoice);assert(r.ok and r.id==25 and billingCalls==1)
assert(api.GetInvoice(25).status=='sent')
invoice.society='ambulance';assert(api.CreateInvoice(invoice).code=='society_job_mismatch' and billingCalls==1)
invoice.society='police';reject=true;assert(api.CreateInvoice(invoice).code=='no_item');reject=false
stopped.apex_billing=true;assert(api.CreateInvoice(invoice).code=='billing_unavailable')
assert(not api.GetBillingStatus().ready and api.GetInvoice(25)==nil)
assert(api.PayInvoice==nil, 'no unsafe automatic payment wrapper')
print('PASS: Apex bank signatures, no fallback/double debit, addon-only society, Apex invoice mapping and readback')
