dofile('locales/nl.lua'); dofile('locale.lua')
local api, events, handlers, notifications, removed, added = {}, {}, {}, {}, {}, {}
local owner, state = 'ts_hostage', 'started'
exports = setmetatable({ ox_target = {
 addGlobalPlayer = function(_, opts) added[#added + 1] = opts end,
 addGlobalVehicle = function(_, opts) added[#added + 1] = opts end,
 removeGlobalPlayer = function(_, name) removed[#removed + 1] = name end,
 removeGlobalVehicle = function(_, name) removed[#removed + 1] = name end
}}, { __call = function(_, n, fn) api[n] = fn end })
function GetInvokingResource() return owner end
function GetCurrentResourceName() return 'ts_bridge' end
function GetResourceState() return state end
function RegisterNetEvent(n, fn) events[n] = fn end
function AddEventHandler(n, fn) handlers[n] = fn end
function PlayerPedId() return 10 end
function IsEntityDead() return false end
function IsPedFatallyInjured() return false end
LocalPlayer = { state = {} }
lib = { notify = function(data) notifications[#notifications + 1] = data end }
dofile('config.lua'); dofile('client/main.lua')
api.Notify('test'); assert(notifications[1].description == 'test')
source = 1; events['ts_bridge:notify']('bad'); assert(#notifications == 1)
source = 65535; events['ts_bridge:notify']('server'); assert(#notifications == 2)
assert(not api.IsDead(10)); LocalPlayer.state.laststand = true
assert(api.IsDead(10)); assert(not api.IsDead(11))
assert(api.AddGlobalPlayer({ { name = 'ts_hostage_player' } }))
assert(api.AddGlobalVehicle({ { name = 'ts_hostage_vehicle' } }))
owner = 'other'; assert(not api.RemoveGlobalPlayer('ts_hostage_player'))
assert(not pcall(api.AddGlobalPlayer, { { name = 'ts_hostage_player' } }))
handlers.onClientResourceStop('ts_hostage'); assert(#removed == 2)
owner = 'ts_hostage'; state = 'stopped'; assert(not api.AddGlobalPlayer({ { name = 'ts_hostage_player' } }))
state = 'started'; assert(api.AddGlobalPlayer({ { name = 'ts_hostage_player' } }))
handlers.onClientResourceStop('ox_target'); assert(#removed == 2)
assert(api.AddGlobalPlayer({ { name = 'ts_hostage_player' } }))
handlers.onClientResourceStop('ts_bridge'); assert(#removed == 3)
print('PASS: notifications, server-only event, death states, target ownership and restart cleanup')
