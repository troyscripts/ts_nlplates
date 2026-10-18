dofile('locales/nl.lua');dofile('locale.lua')
local logs,timers,requests,api,events,threads={},{},{},{},{},{}
local owner,response='ts_keycard',nil
local realPrint=print
function print(s)logs[#logs+1]=s end
function GetInvokingResource()return owner end
function GetCurrentResourceName()return 'ts_bridge' end
function GetResourceMetadata(r) return r=='ts_bridge' and '0.0.4' or '1.1.5' end
function Wait()end
function CreateThread(f)threads[#threads+1]=f end
function SetTimeout(_,f)timers[#timers+1]=f end
function AddEventHandler(n,f)events[n]=f end
function PerformHttpRequest(url,cb,method,body,h) requests[#requests+1]={url=url,cb=cb,h=h} end
exports=function(n,f)api[n]=f end
json={decode=function(body) if body=='bad' then error('invalid') end;return response end}
local function has(text)for _,l in ipairs(logs)do if l:find(text,1,true)then return true end end end
local function reset()
 logs={};timers={};requests={};threads={};owner='ts_keycard';dofile('server/updates.lua')
end
local cfg={Enabled=true,Repository='troyscripts/ts_keycard',File='version.txt',Branch='main'}
reset();assert(api.CheckForUpdates(cfg));assert(not api.CheckForUpdates(cfg));threads[1]()
assert(requests[1].url=='https://api.github.com/repos/troyscripts/ts_keycard/contents/version.txt?ref=main')
requests[1].cb(200,'1.1.6\n');assert(has('[ts_keycard] Update beschikbaar') and has('Download: https://github.com/troyscripts/ts_keycard'))
local n=#logs;timers[1]();assert(#logs==n)
reset();owner='ts_bridge';TSBridgeServer={};dofile('server/update_check.lua');threads[1]()
assert(requests[1].url=='https://api.github.com/repos/troyscripts/ts_brigde/contents/version.json')
response={version='0.0.5',download='https://evil.invalid'};requests[1].cb(200,'ok');assert(has('Download: https://github.com/troyscripts/ts_brigde') and not has('evil'))
for _,case in ipairs({{'1.1.5','up-to-date'},{'1.1.4','nieuwer'},{'1.1.6-beta','ongeldig'}})do
 reset();api.CheckForUpdates(cfg);threads[1]();requests[1].cb(200,case[1]);assert(has(case[2]))
end
for _,status in ipairs({404,403,429,500})do reset();api.CheckForUpdates(cfg);threads[1]();requests[1].cb(status,'');assert(has('HTTP '..status))end
reset();api.CheckForUpdates(cfg);threads[1]();timers[1]();n=#logs;requests[1].cb(200,'1.1.6');assert(#logs==n and has('niet op tijd'))
reset();api.CheckForUpdates(cfg);threads[1]();requests[1].cb(200,string.rep('x',16385));assert(has('te groot'))
reset();assert(not api.CheckForUpdates({Enabled=false}));assert(not api.CheckForUpdates({Repository='../bad'}));assert(not api.CheckForUpdates({Repository='troyscripts/x',File='../bad'}));assert(#threads==0)
reset();api.CheckForUpdates(cfg);events.onResourceStop('ts_keycard');threads[1]();assert(#requests==0)
assert(api.CheckForUpdates(cfg));threads[2]();events.onResourceStop('ts_keycard');n=#logs;requests[1].cb(200,'1.1.6');assert(#logs==n)
reset();api.CheckForUpdates(cfg);owner='other';assert(api.CheckForUpdates(cfg));assert(#threads==2)
PerformHttpRequest=function()error('offline')end
reset();api.CheckForUpdates(cfg);threads[1]();assert(has('kon niet starten'))
realPrint('PASS: shared checker JSON/text, per-resource version/ownership, safe links, numeric versions, failures, timeout and stop/restart')
