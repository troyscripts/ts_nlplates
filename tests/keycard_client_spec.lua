dofile('locales/nl.lua'); dofile('locale.lua')
local api, events, added, removed = {}, {}, 0, 0
local owner, state='ts_keycard','started'
exports=setmetatable({ ox_target={
 addLocalEntity=function(_,ped,options) assert(ped==42); added=added+1 end,
 removeLocalEntity=function(_,ped,name) assert(ped==42 and name=='ts_keycard_desk');removed=removed+1 end
}, ox_inventory={useItem=function(_,data,cb) cb({slot=2}) end}}, {__call=function(_,name,fn) api[name]=fn end})
function GetInvokingResource() return owner end
function GetCurrentResourceName() return 'ts_bridge' end
function DoesEntityExist(id) return id==42 end
function GetResourceState() return state end
function AddEventHandler(name,fn) events[name]=fn end
lib={progressCircle=function() return false end,inputDialog=function() return nil end,alertDialog=function() return 'cancel' end}
dofile('config.lua'); dofile('client/keycard_support.lua')
assert(api.AddLocalEntity(42,{{name='ts_keycard_desk'}}));assert(added==1)
owner='other';assert(not api.RemoveLocalEntity(42,'ts_keycard_desk'));owner='ts_keycard'
assert(api.RemoveLocalEntity(42,'ts_keycard_desk'));assert(removed==1)
assert(not api.AddLocalEntity(99,{{name='ts_keycard_desk'}}))
assert(not api.AddLocalEntity(42,{{name='other_desk'}}))
api.AddLocalEntity(42,{{name='ts_keycard_desk'}});events.onClientResourceStop('ts_keycard');assert(removed==2)
api.AddLocalEntity(42,{{name='ts_keycard_desk'}});events.onClientResourceStop('ox_target');assert(removed==2)
api.AddLocalEntity(42,{{name='ts_keycard_desk'}});events.onClientResourceStop('ts_bridge');assert(removed==3)
local used
assert(api.UseItem({},function(data) used=data end));assert(used.slot==2)
state='stopped';assert(not api.UseItem({},function(data) used=data end));assert(used==nil)
assert(api.ProgressCircle({})==false and api.InputDialog('x',{})==nil and api.AlertDialog({})=='cancel')
print('PASS: NPC targets, ownership, cleanup, item callback, cancelled progress and dialogs')
