local ESX = exports['es_extended']:getSharedObject()

local Tokens = {}

local function debugLog(msg)
    if Config and Config.Debug then
        print(('[APEX-BossAction] %s'):format(msg))
    end
end

local function isBossAllowed(xPlayer, job)
    if not xPlayer or not job then return false end
    if not xPlayer.job or xPlayer.job.name ~= job then return false end
    local cfg = Config.Position and Config.Position[job]
    if not cfg or not cfg.grade then return false end
    local g = tonumber(xPlayer.job.grade) or 0
    return cfg.grade[g] == true
end

local function getSocietyAccount(job, cb)
    local accountName = 'society_' .. job
    TriggerEvent('esx_addonaccount:getSharedAccount', accountName, function(account)
        cb(account)
    end)
end

local function getGradeInfo(job, cb)
    local rows = {}
    MySQL.query('SELECT grade, label FROM job_grades WHERE job_name = ? ORDER BY grade ASC', { job }, function(result)
        if result and #result > 0 then
            for _, r in ipairs(result) do
                table.insert(rows, { grade = r.grade, grade_label = r.label })
            end
        end
        cb(rows)
    end)
end

local function buildAgency(job)
    local list = {}
    for _, id in ipairs(ESX.GetPlayers()) do
        local xP = ESX.GetPlayerFromId(id)
        if xP and xP.job and xP.job.name == job then
            local name = xP.getName and xP.getName() or GetPlayerName(id)
            local gradeLabel = xP.job.grade_label or tostring(xP.job.grade)
            table.insert(list, {
                identifier = xP.identifier,
                fullname = name,
                grade_label = gradeLabel
            })
        end
    end
    return list
end

local function broadcastFundToJob(job, fund)
    local j = tostring(job or '')
    if j == '' then return end

    for _, playerId in ipairs(ESX.GetPlayers()) do
        local xP = ESX.GetPlayerFromId(playerId)
        if xP and xP.job and xP.job.name == j then
            TriggerClientEvent('lizz_jobutilities:update-fund-temp', playerId, fund)
            TriggerClientEvent('APEX-BossAction:update-fund-temp', playerId, fund)
        end
    end
end


local function handleGenerateToken(src)
    local token = tostring(math.random(100000, 999999)) .. '-' .. tostring(os.time())
    Tokens[src] = token
    TriggerClientEvent('lizz_boss-action:gen-token', src, token)
    TriggerClientEvent('APEX-BossAction:gen-token', src, token)
end

RegisterNetEvent('lizz_boss-action:gen-token')
AddEventHandler('lizz_boss-action:gen-token', function()
    handleGenerateToken(source)
end)

RegisterNetEvent('APEX-BossAction:gen-token')
AddEventHandler('APEX-BossAction:gen-token', function()
    handleGenerateToken(source)
end)

local function handleGetBossData(src, job)
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return end
    local j = tostring(job or '')
    getSocietyAccount(j, function(acc)
        local fund = acc and acc.money or 0
        TriggerClientEvent('lizz_boss-action:receive-table_fund', src, fund)
        TriggerClientEvent('APEX-BossAction:receive-table_fund', src, fund)
        local agency = buildAgency(j)
        local gradeInfoReady = function(gradeRows)
            local grades = gradeRows or {}
            local map = {}
            map[j] = grades
            TriggerClientEvent('lizz_boss-action:receive-grade_info', src, map)
            TriggerClientEvent('APEX-BossAction:receive-grade_info', src, map)
            local data = {}
            data[j] = agency
            TriggerClientEvent('lizz_boss-action:receive-table_jobs', src, data)
            TriggerClientEvent('APEX-BossAction:receive-table_jobs', src, data)
        end
        getGradeInfo(j, gradeInfoReady)
    end)
end

RegisterNetEvent('lizz_boss-action:get-data')
AddEventHandler('lizz_boss-action:get-data', function(job)
    handleGetBossData(source, job)
end)

RegisterNetEvent('APEX-BossAction:get-data')
AddEventHandler('APEX-BossAction:get-data', function(job)
    handleGetBossData(source, job)
end)

RegisterNetEvent('lizz_jobutilities:deposit')
AddEventHandler('lizz_jobutilities:deposit', function(job, amount, token)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer or Tokens[src] ~= token then return end
    local j = tostring(job or '')
    if not isBossAllowed(xPlayer, j) then return end
    local amt = tonumber(amount) or 0
    if amt <= 0 then return end
    if xPlayer.getMoney() < amt then return end
    getSocietyAccount(j, function(acc)
        if not acc then return end
        xPlayer.removeMoney(amt)
        acc.addMoney(amt)
        broadcastFundToJob(j, acc.money)
    end)
end)

RegisterNetEvent('lizz_jobutilities:withdraw')
AddEventHandler('lizz_jobutilities:withdraw', function(job, amount, token)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer or Tokens[src] ~= token then return end
    local j = tostring(job or '')
    if not isBossAllowed(xPlayer, j) then return end
    local amt = tonumber(amount) or 0
    if amt <= 0 then return end
    getSocietyAccount(j, function(acc)
        if not acc or acc.money < amt then return end
        acc.removeMoney(amt)
        xPlayer.addMoney(amt)
        broadcastFundToJob(j, acc.money)
    end)
end)

RegisterNetEvent('lizz_jobutilities:hire')
AddEventHandler('lizz_jobutilities:hire', function(targetId, job, token)
    local src = source
    local xBoss = ESX.GetPlayerFromId(src)
    if not xBoss or Tokens[src] ~= token then return end
    local j = tostring(job or '')
    if not isBossAllowed(xBoss, j) then return end
    local tId = tonumber(targetId)
    if not tId then return end
    local xTarget = ESX.GetPlayerFromId(tId)
    if not xTarget then return end
    xTarget.setJob(j, 0)
    local cfg = Config.Position and Config.Position[j]
    if cfg and cfg.welfare and cfg.welfare.hire and cfg.welfare.hire.item and cfg.welfare.hire.count then
        xTarget.addInventoryItem(cfg.welfare.hire.item, cfg.welfare.hire.count)
    end
end)

RegisterNetEvent('lizz_jobutilities:fire')
AddEventHandler('lizz_jobutilities:fire', function(identifier, job, token)
    local src = source
    local xBoss = ESX.GetPlayerFromId(src)
    if not xBoss or Tokens[src] ~= token then return end
    local j = tostring(job or '')
    if not isBossAllowed(xBoss, j) then return end
    local target = nil
    for _, id in ipairs(ESX.GetPlayers()) do
        local xP = ESX.GetPlayerFromId(id)
        if xP and xP.identifier == identifier then
            target = xP
            break
        end
    end
    if not target then return end
    local sackJob = (Config.Position and Config.Position[j] and Config.Position[j].sack) or 'unemployed'
    target.setJob(sackJob, 0)
    local cfg = Config.Position and Config.Position[j]
    if cfg and cfg.welfare and cfg.welfare.sack and cfg.welfare.sack.item and cfg.welfare.sack.count then
        target.addInventoryItem(cfg.welfare.sack.item, cfg.welfare.sack.count)
    end
end)

RegisterNetEvent('lizz_jobutilities:setrank')
AddEventHandler('lizz_jobutilities:setrank', function(identifier, job, rank, token)
    local src = source
    local xBoss = ESX.GetPlayerFromId(src)
    if not xBoss or Tokens[src] ~= token then return end
    local j = tostring(job or '')
    if not isBossAllowed(xBoss, j) then return end
    local r = tonumber(rank) or 0
    local target = nil
    for _, id in ipairs(ESX.GetPlayers()) do
        local xP = ESX.GetPlayerFromId(id)
        if xP and xP.identifier == identifier then
            target = xP
            break
        end
    end
    if not target then return end
    target.setJob(j, r)
end)

RegisterNetEvent('lizz_jobutilities:givebonus')
AddEventHandler('lizz_jobutilities:givebonus', function(identifier, amount, job, token)
    local src = source
    local xBoss = ESX.GetPlayerFromId(src)
    if not xBoss or Tokens[src] ~= token then return end
    local j = tostring(job or '')
    if not isBossAllowed(xBoss, j) then return end
    local amt = tonumber(amount) or 0
    if amt <= 0 then return end
    getSocietyAccount(j, function(acc)
        if not acc or acc.money < amt then return end
        local target = nil
        for _, id in ipairs(ESX.GetPlayers()) do
            local xP = ESX.GetPlayerFromId(id)
            if xP and xP.identifier == identifier then
                target = xP
                break
            end
        end
        if not target then return end
        acc.removeMoney(amt)
        target.addAccountMoney('bank', amt)
        broadcastFundToJob(j, acc.money)
    end)
end)
