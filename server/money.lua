if TSBridgeValidation and not TSBridgeValidation.valid then return end
local B = TSBridge
local locks = {}
local function failed(code, uncertain, before, after)
    return { ok = false, code = code, uncertain = uncertain == true, before = before, after = after }
end
local function playerBalance(player, account, id)
    local amount
    if account == 'cash' then amount = player.getMoney()
    elseif account == 'bank' and TSBridgeServer.Banking.Provider == 'apex' then
        if GetResourceState(TSBridgeServer.Banking.Resource) ~= 'started' then return nil, 'banking_unavailable' end
        amount = exports[TSBridgeServer.Banking.Resource]:GetBalance(id)
    elseif account == 'bank' and (TSBridgeServer.Banking.Provider == 'esx' or TSBridgeServer.Banking.Provider == 'okok') then
        if TSBridgeServer.Banking.Provider == 'okok' and GetResourceState(TSBridgeServer.Banking.Resource) ~= 'started' then
            return nil, 'banking_unavailable'
        end
        -- okokBanking: persoonlijk ESX-bankaccount. De okok AddMoney/RemoveMoney-exports
        -- zijn voor societyrekeningen en mogen hier niet worden gebruikt.
        local bank = player.getAccount('bank')
        amount = type(bank) == 'table' and bank.money
    else return nil, 'invalid_money_account' end
    if not B.Finite(amount) or amount < 0 then return nil, 'invalid_balance' end
    return amount
end
exports('GetMoney', function(id, account)
    local player, reason = B.Player(id)
    if not player then return nil, reason end
    local ok, balance, err = pcall(playerBalance, player, account, id)
    if not ok then return nil, 'balance_read_failed' end
    return balance, err
end)
local function changePlayer(id, account, amount, reason, subtract)
    if not B.PositiveInteger(amount) then return failed('invalid_amount') end
    if account ~= 'cash' and account ~= 'bank' then return failed('invalid_money_account') end
    local player, err = B.Player(id)
    if not player then return failed(err) end
    local key = 'player:' .. id .. ':' .. account
    if locks[key] then return failed('busy') end
    locks[key] = true
    local attempted, before, after = false
    local ok, result = pcall(function()
        local errorCode
        before, errorCode = playerBalance(player, account, id)
        if before == nil then return failed(errorCode) end
        if subtract and before < amount then return failed('insufficient_funds', false, before) end
        local expected = before + (subtract and -amount or amount)
        if not B.Finite(expected) or expected > 9007199254740991 then return failed('invalid_balance') end
        local method = account == 'cash' and (subtract and 'removeMoney' or 'addMoney')
            or (subtract and 'removeAccountMoney' or 'addAccountMoney')
        local useApex = account == 'bank' and TSBridgeServer.Banking.Provider == 'apex'
        if not useApex and not B.Callable(player[method]) then return failed('method_unavailable') end
        reason = type(reason) == 'string' and reason:sub(1, 120) or TSL('config_troy_scripts')
        attempted = true
        local providerResult
        if useApex then
            if subtract then providerResult = exports[TSBridgeServer.Banking.Resource]:RemoveMoney(id, amount, reason)
            else providerResult = exports[TSBridgeServer.Banking.Resource]:AddMoney(id, amount, reason) end
        elseif account == 'cash' then player[method](amount, reason)
        else player[method](account, amount, reason) end
        after = playerBalance(player, account, id)
        if useApex and providerResult ~= true then return failed('banking_rejected', after ~= before, before, after) end
        if after ~= expected then return failed('verification_failed', true, before, after) end
        return { ok = true, uncertain = false, before = before, after = after }
    end)
    locks[key] = nil
    return ok and result or failed('provider_error', attempted, before, after)
end
exports('AddMoney', function(id, account, amount, reason) return changePlayer(id, account, amount, reason, false) end)
exports('RemoveMoney', function(id, account, amount, reason) return changePlayer(id, account, amount, reason, true) end)

local function fetch(name)
    local account
    TriggerEvent('esx_addonaccount:getSharedAccount', name, function(value) account = value end)
    return account
end
local function resolve(key)
    if type(key) ~= 'string' or key == '' then return nil, 'invalid_society' end
    if GetResourceState(TSBridgeServer.SocietyResource) ~= 'started' then return nil, 'society_unavailable' end
    local names = TSBridgeServer.SocietyAccounts[key] or { key }
    if type(names) ~= 'table' then return nil, 'invalid_society_config' end
    for _, name in ipairs(names) do
        if type(name) ~= 'string' or name == '' then return nil, 'invalid_society_config' end
        local account = fetch(name)
        if account then
            local balance = type(account) == 'table' and tonumber(account.money)
            if not B.Finite(balance) or balance < 0 then return nil, 'invalid_society_balance' end
            return { name = name, account = account, balance = balance }
        end
    end
    return nil, 'society_not_found'
end
exports('GetSocietyBalance', function(key)
    local ok, value, reason = pcall(resolve, key)
    if not ok then return nil, 'society_read_failed' end
    if not value then return nil, reason end
    return value.balance, value.name
end)
local function changeSociety(key, amount, subtract)
    if not B.PositiveInteger(amount) then return failed('invalid_amount') end
    local lookupOk, value, reason = pcall(resolve, key)
    if not lookupOk then return failed('society_read_failed') end
    if not value then return failed(reason) end
    local lock = 'society:' .. value.name
    if locks[lock] then return failed('busy') end
    locks[lock] = true
    local before, after, attempted = value.balance, nil, false
    local ok, result = pcall(function()
        if subtract and before < amount then return failed('insufficient_funds', false, before) end
        local expected = before + (subtract and -amount or amount)
        if not B.Finite(expected) or expected > 9007199254740991 then return failed('invalid_balance') end
        local method = subtract and 'removeMoney' or 'addMoney'
        if not B.Callable(value.account[method]) then return failed('method_unavailable') end
        attempted = true
        value.account[method](amount)
        -- De rekening is een cross-resource snapshot: lees opnieuw, gebruik geen oud saldo.
        local fresh = fetch(value.name)
        after = type(fresh) == 'table' and tonumber(fresh.money) or nil
        if not B.Finite(after) or after ~= expected then return failed('verification_failed', true, before, after) end
        return { ok = true, uncertain = false, before = before, after = after, account = value.name }
    end)
    locks[lock] = nil
    return ok and result or failed('provider_error', attempted, before, after)
end
exports('AddSocietyMoney', function(key, amount) return changeSociety(key, amount, false) end)
exports('RemoveSocietyMoney', function(key, amount) return changeSociety(key, amount, true) end)
