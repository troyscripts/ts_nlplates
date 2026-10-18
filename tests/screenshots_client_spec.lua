local event, callback, timers, replies, state = nil, nil, {}, {}, 'started'
function RegisterNetEvent(_,cb) event=cb end
function GetResourceState() return state end
function SetTimeout(ms,cb) timers[#timers+1]=cb end
function TriggerServerEvent(_,token,data,reason) replies[#replies+1]={token=token,reason=reason} end
function TriggerLatentServerEvent(_,bps,token,data) replies[#replies+1]={token=token,data=data,bps=bps} end
exports={['screenshot-basic']={requestScreenshot=function(_,opts,cb)
    assert(opts.encoding=='jpg');callback=cb
end}}
dofile('client/screenshots.lua')
source=1;event('a','screenshot-basic',1024,8000);assert(not callback)
source=65535;event('a','screenshot-basic',1024,8000)
event('b','screenshot-basic',1024,8000);assert(replies[1].reason=='busy')
callback('data:image/jpeg;base64,/9j/');assert(replies[2].token=='a' and replies[2].bps==1000000)
callback('data:image/jpeg;base64,/9j/');timers[1]();assert(#replies==2)
event('c','screenshot-basic',1024,8000);local late=callback;timers[#timers]()
assert(replies[3].reason=='timeout');late('data:image/jpeg;base64,/9j/');assert(#replies==3)
event('d','screenshot-basic',1,8000);callback(string.rep('x',100));assert(replies[4].reason=='invalid')
state='stopped';event('e','screenshot-basic',1024,8000);assert(replies[5].reason=='unavailable')
state='started';exports['screenshot-basic'].requestScreenshot=function() error('test') end
event('f','screenshot-basic',1024,8000);assert(replies[6].reason=='capture')
print('PASS: server-only capture, busy handling, latent transport, timeout, late callback, size limit, missing resource/export')
