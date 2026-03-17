ESX = nil

local playerJobCache = {}
local playersByJob = {}

local function updatePlayerJobCache(playerId, jobName)
    local pid = tonumber(playerId)
    if not pid then return end

    local oldJob = playerJobCache[pid]
    if oldJob and playersByJob[oldJob] then
        playersByJob[oldJob][pid] = nil
    end

    playerJobCache[pid] = jobName

    if jobName then
        playersByJob[jobName] = playersByJob[jobName] or {}
        playersByJob[jobName][pid] = true
    end
end

local function removePlayerFromCache(playerId)
    local pid = tonumber(playerId)
    if not pid then return end

    local oldJob = playerJobCache[pid]
    if oldJob and playersByJob[oldJob] then
        playersByJob[oldJob][pid] = nil
    end

    playerJobCache[pid] = nil
end

local function getOnlinePlayerJob(playerId)
    if not ESX then
        return nil
    end

    local xPlayer = ESX.GetPlayerFromId(playerId)
    if not xPlayer or not xPlayer.job then
        return nil
    end

    return xPlayer.job.name
end

local function getTargetPlayers(data)
    if type(data) ~= 'table' then
        return nil, true
    end

    if data.job and playersByJob[data.job] then
        local targets = {}
        for playerId, _ in pairs(playersByJob[data.job]) do
            targets[#targets + 1] = playerId
        end
        return targets, false
    end

    return nil, true
end

Citizen.CreateThread(function()
    while ESX == nil do
        TriggerEvent(Config.BASE, function(obj)
            ESX = obj
        end)
        Citizen.Wait(200)
    end

    for _, playerId in ipairs(GetPlayers()) do
        updatePlayerJobCache(playerId, getOnlinePlayerJob(tonumber(playerId)))
    end
end)

local function sendNotify(target, data)
    if type(data) ~= 'table' then
        return
    end

    TriggerClientEvent('APEX-AllNotify:AddNotify', target or -1, {
        type = data.type,
        text = data.text,
        time = data.time,
    })
end

local function sendAlert(data)
    if type(data) ~= 'table' or not data.coords then
        return
    end

    local targets, broadcast = getTargetPlayers(data)
    if broadcast then
        TriggerClientEvent(scriptName .. ':AddAlert', -1, data)
        return
    end

    for _, playerId in ipairs(targets) do
        TriggerClientEvent(scriptName .. ':AddAlert', playerId, data)
    end
end

RegisterNetEvent('APEX-AllNotify:AddNotify')
AddEventHandler('APEX-AllNotify:AddNotify', function(data)
    sendNotify(source, data)
end)

RegisterNetEvent('APEX-AllNotify:SendAlert')
AddEventHandler('APEX-AllNotify:SendAlert', function(data)
    sendAlert(data)
end)

RegisterNetEvent('APEX-AllNotify:CreateAlertZone')
AddEventHandler('APEX-AllNotify:CreateAlertZone', function(payload)
    local zoneData = payload
    local coords = payload

    if type(payload) == 'table' and payload.coords then
        coords = payload.coords
    else
        zoneData = { coords = payload }
    end

    if not coords then
        return
    end

    local targets, broadcast = getTargetPlayers(zoneData)
    if broadcast then
        TriggerClientEvent('APEX-AllNotify:CreateAlertZone', -1, coords)
        return
    end

    for _, playerId in ipairs(targets) do
        TriggerClientEvent('APEX-AllNotify:CreateAlertZone', playerId, coords)
    end
end)

AddEventHandler('esx:playerLoaded', function(playerId, xPlayer)
    local jobName = xPlayer and xPlayer.job and xPlayer.job.name or getOnlinePlayerJob(playerId)
    updatePlayerJobCache(playerId, jobName)
end)

AddEventHandler('playerDropped', function()
    removePlayerFromCache(source)
end)

AddEventHandler('esx:setJob', function(sourceId, job, _lastJob)
    local playerId = tonumber(sourceId)
    local jobName = job and job.name or nil
    updatePlayerJobCache(playerId, jobName)
end)

RegisterNetEvent('APEX-AllNotify:cacheJob')
AddEventHandler('APEX-AllNotify:cacheJob', function(jobName)
    updatePlayerJobCache(source, jobName)
end)

exports('AddNotify', function(target, data)
    sendNotify(target, data)
end)

exports('SendAlert', function(data)
    sendAlert(data)
end)
