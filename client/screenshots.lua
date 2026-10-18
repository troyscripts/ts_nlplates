if TSBridgeValidation and not TSBridgeValidation.valid then return end
local busy = false
RegisterNetEvent('ts_bridge:screenshot:capture', function(token, resource, maxBytes, timeoutMs)
    -- Alleen de server mag een opname aanvragen.
    if source ~= 65535 then return end
    if type(token) ~= 'string' or type(resource) ~= 'string' then return end
    if type(maxBytes) ~= 'number' or maxBytes <= 0 or type(timeoutMs) ~= 'number' then return end
    local function fail(reason)
        TriggerServerEvent('ts_bridge:screenshot:result', token, nil, reason)
    end
    if busy then fail('busy'); return end
    if GetResourceState(resource) ~= 'started' then fail('unavailable'); return end
    busy = true
    local finished = false
    local function complete(data, failure)
        if finished then return end
        finished = true
        busy = false
        if failure then fail(failure); return end
        if type(data) ~= 'string' or #data > math.ceil(maxBytes / 3) * 4 + 64
            or not data:match('^data:image/jpe?g;base64,') then
            fail('invalid'); return
        end
        -- Begrensde overdracht zonder het normale eventkanaal met een grote foto te blokkeren.
        TriggerLatentServerEvent('ts_bridge:screenshot:result', 1000000, token, data)
    end
    SetTimeout(math.max(100, math.min(6000, timeoutMs - 500)), function()
        complete(nil, 'timeout')
    end)
    local ok = pcall(function()
        exports[resource]:requestScreenshot({ encoding = 'jpg', quality = 0.65 }, function(data)
            complete(data)
        end)
    end)
    if not ok then complete(nil, 'capture') end
end)
