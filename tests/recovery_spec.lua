dofile('locales/nl.lua'); dofile('locale.lua'); dofile('config.lua')
local api, handlers = {}, {}
local owner, provider = 'ts_hostage', 'started'
local calls, roots, menus = {}, {}, {}
function GetInvokingResource() return owner end
function GetCurrentResourceName() return 'ts_bridge' end
function GetResourceState(name) if name=='ox_target' then return provider end; return 'started' end
function DoesEntityExist(id) return id==42 end
function RegisterNetEvent() end
function AddEventHandler(n,f) handlers[n]=handlers[n] or {}; table.insert(handlers[n],f) end
local function event(n,r) for _,f in ipairs(handlers[n] or {}) do f(r) end end
exports=setmetatable({ox_target={
 addGlobalPlayer=function(_,t) calls[#calls+1]={'player',t} end,
 addGlobalVehicle=function(_,t) calls[#calls+1]={'vehicle',t} end,
 addLocalEntity=function(_,id,t) calls[#calls+1]={'entity',t} end,
 removeGlobalPlayer=function() end, removeGlobalVehicle=function() end,removeLocalEntity=function() end
}}, {__call=function(_,n,f) api[n]=f end})
lib={registerRadial=function(t) menus[t.id]=t end,addRadialItem=function(t) roots[t.id]=t end,removeRadialItem=function(id) roots[id]=nil end}
dofile('client/main.lua');dofile('client/keycard_support.lua');dofile('client/radial.lua')
api.AddGlobalPlayer({{name='ts_hostage_player'}});api.AddGlobalVehicle({{name='ts_hostage_vehicle'}})
api.RegisterRadialMenu({id='menu',label='Hostage',items={{label='A',onSelect=function() end}}})
owner='ts_keycard';api.AddLocalEntity(42,{{name='ts_keycard_desk'}})
assert(#calls==3)
provider='stopped'; event('onClientResourceStop','ox_target');provider='started';event('onClientResourceStart','ox_target')
assert(#calls==6, 'all targets recovered')
roots={}; menus={};event('onClientResourceStart','ox_lib');assert(roots['ts_hostage:menu'] and #menus['ts_hostage:menu'].items==1)
event('onClientResourceStop','ts_hostage');provider='stopped';event('onClientResourceStop','ox_target');provider='started';event('onClientResourceStart','ox_target')
assert(#calls==7 and calls[7][1]=='entity', 'stopped owner not recovered')
event('onClientResourceStop','ts_keycard');event('onClientResourceStart','ox_target');assert(#calls==7)
print('PASS: player/vehicle/NPC target restoration, radial restoration, stopped-owner cleanup')
