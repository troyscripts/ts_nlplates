dofile('locales/nl.lua'); dofile('locale.lua'); dofile('server_config.lua')
local api, timers, requests, jsonObjects = {}, {}, {}, {}
local counter, owner, photo, screenshotState = 0, 'one', nil, 'stopped'
local function copy(x) if type(x)~='table' then return x end;local t={};for k,v in pairs(x)do t[k]=copy(v)end;return t end
json={encode=function(t) counter=counter+1;local key='json'..counter;jsonObjects[key]=copy(t);return key end,
 decode=function(k) if k=='rate' then return {retry_after=2} end;return copy(jsonObjects[k]) end}
exports=setmetatable({['screenshot-basic']={requestClientScreenshot=function(_,id,opts,cb) photo=cb end}}, {__call=function(_,n,f)api[n]=f end})
local events, handlers, capture = {}, {}, nil
function RegisterNetEvent(name, cb) events[name] = cb end
function AddEventHandler(name, cb) handlers[name] = cb end
function TriggerClientEvent(name, id, token)
    capture = { player = id, token = token }
    photo = function(err, data)
        source = id
        events['ts_bridge:screenshot:result'](token, data, err or nil)
    end
end
function GetInvokingResource() return owner end
function GetGameTimer() return 10000 end
function GetPlayerName() return 'Test' end
function GetResourceState() return screenshotState end
function SetTimeout(ms,f) timers[#timers+1]={ms=ms,f=f} end
function PerformHttpRequest(url,cb,method,body,headers)requests[#requests+1]={url=url,cb=cb,body=body,payload=copy(jsonObjects[body])}end
function GetCurrentResourceName() return 'ts_bridge' end
exports.ts_bridge = { UploadDiscordPhoto = function(_,url,payloadJson,dataUri,cb)
    requests[#requests+1]={url=url .. '?wait=true',cb=cb,imageData=dataUri,payload=copy(jsonObjects[payloadJson])}
end }
local a,b='https://discord.com/api/webhooks/1/a','https://discord.com/api/webhooks/2/b'
local payload={embeds={{title='Event',description='Original RP text',fields={{name='Player',value='Test'}}}}}
dofile('server/webhooks.lua')
assert(api.SendWebhook('start',a,payload));assert(api.SendWebhook('start',b,payload))
assert(#requests==2, 'a hung destination must not block another')
requests[1].cb(429,'rate');local retry=timers[#timers]
assert(api.SendWebhook('start',a,payload)); assert(#requests==2, 'same endpoint stays ordered')
requests[2].cb(204,'');timers[#timers].f()
assert(api.SendWebhook('start',b,payload));assert(#requests==3, 'other destination continues during backoff')
retry.f();assert(#requests==4 and requests[4].url==a .. '?wait=true')
assert(api.GetWebhookStatus().queued==3)
requests[4].cb(204,'');timers[#timers].f();assert(#requests==5 and requests[5].url==a .. '?wait=true')
-- Fresh isolated state: screenshot failure retains original content and caller input.
requests={};timers={};dofile('server/webhooks.lua')
assert(api.SendWebhook('start',a,payload,{screenshot=true,playerId=1}))
assert(requests[1].payload.embeds[1].description=='Original RP text')
assert(#requests[1].payload.embeds[1].fields==2 and #payload.embeds[1].fields==1)
requests[1].cb(204,'');timers[#timers].f()
screenshotState='started';TSBridgeServer.MaxQueue=1
assert(api.SendWebhook('start',a,payload,{screenshot=true,playerId=1}))
assert(api.GetWebhookStatus().pendingPhotos==1)
assert(not api.SendWebhook('start',b,payload), 'pending photo reserves total capacity')
local timeout=timers[#timers];assert(timeout.ms==8000);timeout.f()
assert(#requests==2 and requests[2].payload.embeds[1].description=='Original RP text')
assert(api.GetWebhookStatus().queued==1 and api.GetWebhookStatus().pendingPhotos==0)
photo(false,'data:image/jpeg;base64,/9j/');assert(#requests==2, 'late callback ignored')
requests[2].cb(204,'');timers[#timers].f();assert(api.GetWebhookStatus().queued==0)
local full=copy(payload);full.embeds[1].fields={};for i=1,25 do full.embeds[1].fields[i]={name='n',value='v'}end
screenshotState='stopped';assert(api.SendWebhook('start',a,full,{screenshot=true,playerId=1}))
assert(#requests[3].payload.embeds[1].fields==25 and requests[3].payload.content:find('Screenshot'))
print('PASS: independent webhook lanes, same-destination order/backoff, capacity reservations, description preservation, full embed fallback, late callback')

-- Transport: source binding, invalid image, duplicate/late replies, disconnect cleanup.
TSBridgeServer.MaxQueue=32;screenshotState='started';requests={};timers={}
dofile('server/webhooks.lua')
assert(api.SendWebhook('start',a,payload,{screenshot=true,playerId=1}))
local token=capture.token
source=2;events['ts_bridge:screenshot:result'](token,'data:image/jpeg;base64,/9j/')
assert(#requests==0 and api.GetWebhookStatus().pendingPhotos==1)
source=1;events['ts_bridge:screenshot:result']('unknown','data:image/jpeg;base64,/9j/')
assert(#requests==0)
events['ts_bridge:screenshot:result'](token,'data:image/jpeg;base64,/9j/')
assert(#requests==1 and requests[1].imageData=='data:image/jpeg;base64,/9j/')
assert(requests[1].payload.embeds[1].image.url=='attachment://screenshot.jpg')
events['ts_bridge:screenshot:result'](token,'data:image/jpeg;base64,/9j/')
assert(#requests==1 and api.GetWebhookStatus().pendingPhotos==0)
requests[1].cb(204,'');timers[#timers].f()
assert(api.SendWebhook('start',a,payload,{screenshot=true,playerId=1}))
events['ts_bridge:screenshot:result'](capture.token,'invalid')
assert(#requests==2 and requests[2].payload.embeds[1].fields[2].name=='Screenshot')
requests[2].cb(204,'');timers[#timers].f()
assert(api.SendWebhook('start',a,payload,{screenshot=true,playerId=1}))
handlers.playerDropped()
assert(#requests==3 and api.GetWebhookStatus().pendingPhotos==0)
requests[3].cb(204,'');timers[#timers].f()
TSBridgeServer.MaxImageBytes=1
assert(api.SendWebhook('start',a,payload,{screenshot=true,playerId=1}))
events['ts_bridge:screenshot:result'](capture.token,'data:image/jpeg;base64,/9j/')
assert(#requests==4 and requests[4].payload.embeds[1].fields[2].name=='Screenshot')
print('PASS: bound one-shot responses, JPEG multipart, invalid/oversized data, disconnect cleanup')

TSBridgeServer.MaxImageBytes=4*1024*1024
requests={};timers={};dofile('server/webhooks.lua')
assert(api.SendWebhook('start',a,payload,{screenshot=true,playerId=1}))
photo(false,'data:image/jpeg;base64,/9j/')
assert(requests[1].url==a .. '?wait=true')
requests[1].cb(400,json.encode({code=50035,errors={attachments={['0']={id={_errors={{code='INVALID'}}}}}}}))
assert(api.GetWebhookStatus().queued==1)
assert(api.GetWebhookStatus().lastDelivery:find('50035'))
timers[#timers].f()
assert(#requests==2 and requests[2].payload.embeds[1].description=='Original RP text')
assert(requests[2].payload.attachments==nil and requests[2].payload.embeds[1].image==nil)
assert(requests[2].payload.embeds[1].fields[2].name=='Screenshot')
assert(payload.embeds[1].image==nil and #payload.embeds[1].fields==1)
requests[2].cb(200,json.encode({id='123456789'}));timers[#timers].f()
assert(api.GetWebhookStatus().queued==0)
assert(api.GetWebhookStatus().lastDelivery:find('bevestigd'))
assert(api.GetWebhookStatus().lastPhoto:find('ontvangen'))
requests={};timers={};dofile('server/webhooks.lua')
assert(api.SendWebhook('start',a,payload,{screenshot=true,playerId=1}))
photo(false,'data:image/jpeg;base64,/9j/')
local expire=timers[#timers];assert(expire.ms==30000);expire.f()
timers[#timers].f()
assert(#requests==1 and api.GetWebhookStatus().queued==0)
requests[1].cb(200,json.encode({id='123456789'}))
assert(api.GetWebhookStatus().lastDelivery:find('HTTP 0'))
requests={};timers={};dofile('server/webhooks.lua')
assert(api.SendWebhook('start',a,payload,{screenshot=true,playerId=1}))
photo(false,'data:image/jpeg;base64,/9j/')
requests[1].cb(413,'');timers[#timers].f()
requests[2].cb(400,'');timers[#timers].f()
assert(#requests==2 and api.GetWebhookStatus().queued==0)
print('PASS: confirmed delivery, multipart rejection fallback, input preservation, no retry on uncertain outcome, bounded fallback')

requests={};timers={};dofile('server/webhooks.lua')
assert(api.SendWebhook('start',a,payload))
local failure=json.encode({code=50035,errors={content={_errors={{code='INVALID'}}}}})
requests[1].cb(400,nil,{},'HTTP 400: ' .. failure)
assert(api.GetWebhookStatus().lastFailure:find('50035'))
assert(api.GetWebhookStatus().lastFailure:find('payload.content'))
requests={};timers={};dofile('server/webhooks.lua')
assert(api.SendWebhook('start',a,payload,{screenshot=true,playerId=1}))
photo(false,'data:image/jpeg;base64,/9j/')
requests[1].cb(200,json.encode({id='123'}));timers[#timers].f()
assert(api.GetWebhookStatus().lastDelivery:find('foto: bevestigd'))
print('PASS: server-side uploader routing, errorData decoding, confirmed photo')
