ESX = nil

secured_token = nil
table_jobs = {}
table_fund = 0
grade_info = {}
local bossUIOpen = false -- สถานะ UI สำหรับ boss action (เปิด NUI หรือไม่)
local bossTextUIOpen = false -- สถานะ textui (แสดง errorism.textui หรือไม่)
local playerJobGrade = nil

Citizen.CreateThread(function()
    while ESX == nil do
        ESX = exports['es_extended']:getSharedObject()
        Citizen.Wait(0)
    end
    while ESX.PlayerData == nil do
        Citizen.Wait(10)
    end
end)

Citizen.CreateThread(function()
    Citizen.Wait(Config["PlayerLoaded"])
    while true do
        Citizen.Wait(0)
        if NetworkIsPlayerActive(PlayerId()) then
            if ESX.PlayerData and ESX.PlayerData.job then
                table_job = ESX.PlayerData.job.name
                playerJobGrade = ESX.PlayerData.job.grade
            end
            TriggerServerEvent('APEX-BossAction:gen-token')
            secured_loaded()
            break
        end
    end
end)

RegisterNetEvent('esx:setJob')
AddEventHandler('esx:setJob', function(job)
	table_job = job.name
	playerJobGrade = job.grade
end)

RegisterNetEvent('lizz_boss-action:gen-token')
AddEventHandler('lizz_boss-action:gen-token', function(token)
    secured_token = token
end)

RegisterNetEvent('APEX-BossAction:gen-token')
AddEventHandler('APEX-BossAction:gen-token', function(token)
    secured_token = token
end)


RegisterNetEvent('lizz_boss-action:receive-table_jobs')
AddEventHandler('lizz_boss-action:receive-table_jobs', function(data)
    table_jobs = data
end)

RegisterNetEvent('APEX-BossAction:receive-table_jobs')
AddEventHandler('APEX-BossAction:receive-table_jobs', function(data)
    table_jobs = data
end)

RegisterNetEvent('lizz_boss-action:receive-table_fund')
AddEventHandler('lizz_boss-action:receive-table_fund', function(data)
    table_fund = data
end)

RegisterNetEvent('APEX-BossAction:receive-table_fund')
AddEventHandler('APEX-BossAction:receive-table_fund', function(data)
    table_fund = data
end)

RegisterNetEvent('lizz_boss-action:receive-grade_info')
AddEventHandler('lizz_boss-action:receive-grade_info', function(data)
    grade_info = data
end)

RegisterNetEvent('APEX-BossAction:receive-grade_info')
AddEventHandler('APEX-BossAction:receive-grade_info', function(data)
    grade_info = data
end)

local function syncFundToUi(newFund)
    table_fund = tonumber(newFund) or 0
    SendNUIMessage({
        type = "update_fund",
        fund = table_fund
    })
end

RegisterNetEvent("lizz_jobutilities:update-fund-temp")
AddEventHandler("lizz_jobutilities:update-fund-temp", function(newFund)
    syncFundToUi(newFund)
end)

RegisterNetEvent("APEX-BossAction:update-fund-temp")
AddEventHandler("APEX-BossAction:update-fund-temp", function(newFund)
    syncFundToUi(newFund)
end)

-- Event สำหรับปิด UI เมื่อผู้เล่นตาย
AddEventHandler('esx:onPlayerDeath', function(data)
    if bossUIOpen then
        SetNuiFocus(false, false)
        SendNUIMessage({
            type = "close"
        })
        Wait(1000)
        bossUIOpen = false
        -- ปิด textui เมื่อปิด UI
        if bossTextUIOpen then
            exports["errorism.textui"]:close()
            bossTextUIOpen = false
        end
    end
end)

-- ========================================
-- NPC SYSTEM (แบบเดียวกับ lizz_shop)
-- ========================================

Citizen.CreateThread(function()
    Citizen.Wait(Config["PlayerLoaded"])
    for k, v in pairs(Config.Position) do
        if v.npc_id and v.npc_anim then
            local heading = v.heading or 0.0
            exports['lizz_pedsnpc']:CreatPedNpc(v.npc_id, v.npc_anim, v.coords, heading, GetCurrentResourceName())
        end
    end
end)

-- ========================================
-- DISTANCE CHECKING SYSTEM (แบบเดียวกับ lizz_shop)
-- ========================================

local bossInRange = false
local bossInInteractionRange = false
local nearestBossData = nil

-- Thread เช็ค distance (ทุก 500ms เพื่อประหยัด performance)
Citizen.CreateThread(function()
    while true do
        bossInRange = false
        bossInInteractionRange = false
        nearestBossData = nil
        
        local ped = cache.ped
        local coords = cache.coords
        
        if coords and not cache.vehicle then
            local nearestDistance = Config.DrawDistance + 1.0
            
            for k, v in pairs(Config.Position) do
                local distance = #(coords - v.coords)
                
                -- เช็คระยะ DrawDistance
                if distance <= Config.DrawDistance then
                    bossInRange = true
                    
                    -- เก็บจุดที่ใกล้ที่สุด
                    if distance < nearestDistance then
                        nearestDistance = distance
                        local h = 0
                        if v.npc_id then
                            h = 0.98 -- ถ้ามี NPC ให้แสดง text สูงขึ้น
                        end
                        nearestBossData = {
                            key = k,
                            v = v,
                            h = h,
                            distance = distance
                        }
                        
                        -- เช็คระยะ interaction
                        if distance <= Config.distance then
                            bossInInteractionRange = true
                        end
                    end
                end
            end
        end
        
        Wait(500)
    end
end)

-- Thread สำหรับแสดง DrawTextUI (ทุก 250ms เมื่ออยู่ในระยะ)
Citizen.CreateThread(function()
    while true do
        if bossInRange and nearestBossData and not bossUIOpen and not cache.vehicle then
            local text_show = nearestBossData.v.text_show
            local detail_show = nearestBossData.v.detail_show
            exports['lizz_drawtext']:DrawTextUI(text_show, detail_show, nearestBossData.v.coords + vector3(0, 0, nearestBossData.h))
            Wait(250)  -- เปลี่ยนจาก Wait(0) เป็น Wait(250) เพื่อลดภาระงาน
        else
            Wait(500)
        end
    end
end)


local function openBossActionMenuByJob(jobName)
    local id = tostring(jobName or '')
    if id == '' then
        return false
    end

    local cfg = Config.Position and Config.Position[id]
    if not cfg then
        return false
    end

    local isJobAllowed = (type(check_jobs) == 'function' and check_jobs(id)) or (id == table_job)
    if not isJobAllowed then
        Config["client_text-notify"]('job-not_math')
        return false
    end

    local isGradeAllowed = false
    if type(check_grade) == 'function' then
        isGradeAllowed = check_grade(cfg.grade or {})
    else
        local g = tonumber(playerJobGrade or (ESX.PlayerData and ESX.PlayerData.job and ESX.PlayerData.job.grade))
        isGradeAllowed = g ~= nil and (cfg.grade or {})[g] == true
    end

    if not isGradeAllowed then
        Config["client_text-notify"]('job-grade_not_math')
        return false
    end

    if ESX and ESX.UI and ESX.UI.Menu and ESX.UI.Menu.CloseAll then
        ESX.UI.Menu.CloseAll()
    end

    TriggerServerEvent('APEX-BossAction:get-data', id)
    Wait(500)
    SetNuiFocus(true, true)
    SendNUIMessage({
        type = "main",
        title = id,
        fund = table_fund,
        agency = table_jobs[id],
        grade = grade_info[id],
        player = #(table_jobs[id] or {})
    })
    bossUIOpen = true

    if bossTextUIOpen then
        exports["errorism.textui"]:close()
        bossTextUIOpen = false
    end

    return true
end

RegisterNetEvent('APEX-BossAction:openMenu')
AddEventHandler('APEX-BossAction:openMenu', function(jobName)
    openBossActionMenuByJob(jobName or table_job)
end)

secured_loaded = function()
    Citizen.CreateThread(function()
        while true do
            local sleep_tread = 1000
            
            if bossInInteractionRange and nearestBossData and not cache.vehicle and not bossUIOpen then
                sleep_tread = 0
                
                local v = nearestBossData.v
                local k = nearestBossData.key
                
                -- เช็ค grade และ job ก่อนแสดง textui
                local isJobAllowed = check_jobs(k)
                local isGradeAllowed = false
                if isJobAllowed then
                    isGradeAllowed = check_grade(v.grade)
                end
                
                -- แสดง textui เฉพาะเมื่อมีสิทธิ์
                if isJobAllowed and isGradeAllowed then
                    if not bossTextUIOpen then
                        exports["errorism.textui"]:open({
                            key = "E",
                            text = "MENU BOSS ACTION"
                        })
                        bossTextUIOpen = true
                    end
                else
                    if bossTextUIOpen then
                        exports["errorism.textui"]:close()
                        bossTextUIOpen = false
                    end
                end
                
                -- เช็คการกด E
                if IsControlJustReleased(0, 38) then
                    if isJobAllowed and isGradeAllowed then
                        openBossActionMenuByJob(k)
                    elseif not isJobAllowed then
                        if Config["Debug"] then
                            print('[^3debug^0] : job ^3' .. table_job .. ' ^1not math ^0require (^5' .. k .. '^0)')
                        end
                        Config["client_text-notify"]('job-not_math')
                    elseif not isGradeAllowed then
                        Config["client_text-notify"]('job-grade_not_math')
                    end
                end
            else
                if bossTextUIOpen then
                    exports["errorism.textui"]:close()
                    bossTextUIOpen = false
                end
            end
            
            Citizen.Wait(sleep_tread)
        end
    end)

    check_jobs = function(key)
        if key == table_job then
            return true
        end
        return false
    end

    check_grade = function(grade)
        -- ใช้ ESX.PlayerData.job.grade (cache ไว้ใน memory แล้ว เร็วกว่า GetPlayerData())
        if not playerJobGrade and ESX.PlayerData and ESX.PlayerData.job then
            playerJobGrade = ESX.PlayerData.job.grade
        end
        if playerJobGrade and grade[playerJobGrade] then
            return true
        end
        return false
    end

    RegisterNUICallback("deposit", function(data)
        TriggerServerEvent("lizz_jobutilities:deposit", data["job"], data["amount"], secured_token)
    end)

    RegisterNUICallback("withdraw", function(data)
        TriggerServerEvent("lizz_jobutilities:withdraw", data["job"], data["amount"], secured_token)
    end)

    RegisterNUICallback("hire", function(data, cb)
        TriggerServerEvent("lizz_jobutilities:hire", data["id"], data["job"], secured_token)
        Wait(500)
        cb({
            agency = table_jobs[data["job"]],
            player = #table_jobs[data["job"]],
        })
    end)

    RegisterNUICallback("fire", function(data, cb)
        TriggerServerEvent("lizz_jobutilities:fire", data["identifier"], data["job"], secured_token)
        Wait(500)
        cb({
            agency = table_jobs[data["job"]],
            player = #table_jobs[data["job"]],
        })
    end)

    RegisterNUICallback("set_rank", function(data, cb)
        TriggerServerEvent("lizz_jobutilities:setrank", data["identifier"], data["job"], data["rank"], secured_token)
        Wait(500)
        cb({
            agency = table_jobs[data["job"]],
            player = #table_jobs[data["job"]],
        })
    end)

    RegisterNUICallback("givebonus", function(data)
        TriggerServerEvent("lizz_jobutilities:givebonus", data["identifier"], data["amount"], data["job"], secured_token)
    end)

    RegisterNUICallback("exit", function(data)
        SetNuiFocus(false, false)
        SendNUIMessage({
            type = "close"
        })
        -- ปิด textui เมื่อปิด UI
        if bossTextUIOpen then
            exports["errorism.textui"]:close()
            bossTextUIOpen = false
        end
        Wait(1000)
        bossUIOpen = false
    end)
end
