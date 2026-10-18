dofile('locales/nl.lua'); dofile('locale.lua')
local api, handlers, shown, roots, subs = {}, {}, {}, {}, {}
local owner, now = 'one', 10000
function GetInvokingResource() return owner end
function GetCurrentResourceName() return 'ts_bridge' end
function GetResourceState() return 'started' end
function GetGameTimer() return now end
function IsDuplicityVersion() return true end
function RegisterNetEvent() end
function AddEventHandler(n, f) handlers[n] = handlers[n] or {}; table.insert(handlers[n], f) end
local function stop(n) for _, f in ipairs(handlers.onClientResourceStop) do f(n) end end
exports = setmetatable({}, { __call = function(_, n, f) api[n] = f end })
lib = { notify = function(d) table.insert(shown, d) end,
 registerRadial = function(d) subs[d.id] = d end,
 addRadialItem = function(d) roots[d.id] = d end,
 removeRadialItem = function(id) roots[id] = nil end }
dofile('config.lua'); dofile('client/main.lua'); dofile('client/radial.lua'); dofile('config_version.lua')
local d = { id = 'same', description = 'test' }
assert(api.Notify(d, 5000)); assert(d.title == nil and d.id == 'same', 'input not mutated')
assert(not api.Notify(d, 5000)); owner = 'two'; assert(api.Notify(d, 5000), 'resource cooldown isolation')
assert(shown[1].id ~= shown[2].id)
owner = 'one'; now = now + 5000; assert(api.Notify(d, 5000))
assert(api.Notify('legacy')); assert(api.Notify('legacy'), 'old calls unthrottled')
local count = 0
local menu = { id = 'menu', label = 'Test', items = { { label = 'Act', onSelect = function() count = count + 1 end } } }
assert(api.RegisterRadialMenu(menu)); owner = 'two'; assert(api.RegisterRadialMenu(menu))
assert(roots['one:menu'] and roots['two:menu'])
subs['one:menu'].items[1].onSelect(); assert(count == 1)
assert(not api.RemoveRadialMenu('one:menu'), 'cannot remove other owner')
stop('one'); assert(not roots['one:menu'] and roots['two:menu']); assert(#subs['one:menu'].items == 0)
owner = 'one'; assert(api.Notify(d, 5000), 'cooldown reset on owner stop')
stop('ts_bridge'); assert(not next(roots))
assert(api.CheckConfigVersion('0.0.3', '0.0.3')); assert(not api.CheckConfigVersion(nil, '0.0.3'))
assert(not api.RegisterRadialMenu({})); assert(not api.CheckConfigVersion('a', nil))
print('PASS: UI ownership, cooldown isolation, legacy notify, immutable input, radial callbacks/cleanup, config checks')
