local ESX = exports['es_extended']:getSharedObject()
local _R = GetCurrentResourceName()
local TABLE_NAME = (Config and Config.TableName) or 'apex_bills'

local function vatForJob(jobName)
    local v = Config.Vat and Config.Vat[jobName]
    if not v then return 0 end
    return tonumber(v) or 0
end

local function limitForJob(jobName)
    local v = Config.LimitCount and Config.LimitCount[jobName]
    if not v then return 0 end
    return tonumber(v) or 0
end

local function sanitizeFine(n)
    local x = tonumber(n)
    if not x or x <= 0 then return 0 end
    return math.floor(x)
end

local function now()
    return os.date('%Y-%m-%d %H:%M:%S')
end

MySQL.ready(function()
    MySQL.query(([[
        CREATE TABLE IF NOT EXISTS `%s` (
            id INT AUTO_INCREMENT PRIMARY KEY,
            identifier VARCHAR(64) NOT NULL,
            amount INT NOT NULL,
            reason VARCHAR(128) NOT NULL,
            pay TINYINT(1) DEFAULT 0,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            pay_time TIMESTAMP NULL DEFAULT NULL
        )
    ]]):format(TABLE_NAME))
end)

local function getUnpaidTotal(identifier, cb)
    MySQL.query(('SELECT COALESCE(SUM(amount),0) AS total FROM `%s` WHERE identifier = ? AND pay = 0'):format(TABLE_NAME), {identifier}, function(result)
        local total = 0
        if result and result[1] and result[1].total then
            total = tonumber(result[1].total) or 0
        end
        cb(total)
    end)
end

ESX.RegisterServerCallback(_R..':CallBill', function(src, cb, identifier)
    MySQL.query(('SELECT id, amount, reason, pay, pay_time FROM `%s` WHERE identifier = ? ORDER BY pay ASC, id DESC'):format(TABLE_NAME), {identifier}, function(rows)
        local list = {}
        for i=1, #(rows or {}) do
            local r = rows[i]
            list[#list+1] = {
                id = r.id,
                amount = r.amount,
                reason = r.reason,
                pay = r.pay,
                pay_time = r.pay_time
            }
        end
        cb(list)
    end)
end)

local function pushBillToTarget(targetSource, amount, reason)
    local xTarget = ESX.GetPlayerFromId(targetSource)
    if not xTarget then return false end

    local identifier = xTarget.identifier
    if not identifier then return false end

    local function insertBill()
        MySQL.query(('INSERT INTO `%s` (identifier, amount, reason, pay) VALUES (?, ?, ?, 0)'):format(TABLE_NAME), {identifier, amount, reason}, function()
            MySQL.query('SELECT LAST_INSERT_ID() AS id', {}, function(r2)
                local newId = r2 and r2[1] and r2[1].id or 0
                local data = { id = newId, amount = amount, reason = reason, pay = 0 }
                TriggerClientEvent(_R..':Update', targetSource, data)
            end)
        end)
    end

    if Config.LimitCheck then
        getUnpaidTotal(identifier, function(total)
            local limit = limitForJob((xTarget.job and xTarget.job.name) or 'unemployed')
            if limit > 0 and (total + amount) > limit then
                return
            end
            insertBill()
        end)
    else
        insertBill()
    end

    return true
end

local function createBill(src, bill)
    local xSender = ESX.GetPlayerFromId(src)
    if not xSender then return end

    local fine = sanitizeFine(bill and bill.fine)
    local reason = tostring((bill and bill.reason) or 'Fine')
    local recive = tonumber(bill and bill.recive)
    if fine <= 0 or not recive then return end

    local vat = vatForJob((xSender.job and xSender.job.name) or 'unemployed')
    local amount = fine + math.floor(fine * (vat/100))

    pushBillToTarget(recive, amount, reason)
end

RegisterNetEvent(_R..':CrateBill')
AddEventHandler(_R..':CrateBill', function(bill)
    createBill(source, bill)
end)

RegisterNetEvent(_R..':CrateBillGang')
AddEventHandler(_R..':CrateBillGang', function(bill)
    createBill(source, bill)
end)

-- รองรับบิลจากระบบมาตรฐาน (เช่น APEX-AmbulanceJob ที่ยิง esx_billing:sendBill)
RegisterNetEvent('esx_billing:sendBill')
AddEventHandler('esx_billing:sendBill', function(target, _sharedAccountName, amount, label)
    local src = source
    local xSender = ESX.GetPlayerFromId(src)
    if not xSender then return end

    local recive = tonumber(target)
    local fine = sanitizeFine(amount)
    if not recive or fine <= 0 then return end

    local vat = vatForJob((xSender.job and xSender.job.name) or 'unemployed')
    local totalAmount = fine + math.floor(fine * (vat/100))

    pushBillToTarget(recive, totalAmount, tostring(label or 'Fine'))
end)

RegisterNetEvent(_R..':PayBill')
AddEventHandler(_R..':PayBill', function(v)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return end
    local billId = tonumber(v and v.id)
    if not billId or billId <= 0 then return end
    MySQL.query(('SELECT id, amount, identifier FROM `%s` WHERE id = ? AND pay = 0 LIMIT 1'):format(TABLE_NAME), {billId}, function(rows)
        if not rows or not rows[1] then return end
        local row = rows[1]
        if row.identifier ~= xPlayer.identifier then return end
        local amt = tonumber(row.amount) or 0
        if amt <= 0 then return end
        local paid = false
        if xPlayer.getMoney and (xPlayer.getMoney() >= amt) then
            if xPlayer.removeMoney then xPlayer.removeMoney(amt) end
            paid = true
        else
            local acc = xPlayer.getAccount and xPlayer.getAccount('bank')
            local bankMoney = acc and acc.money or 0
            if bankMoney >= amt then
                if xPlayer.removeAccountMoney then xPlayer.removeAccountMoney('bank', amt) end
                paid = true
            end
        end
        if not paid then return end
        local tm = now()
        MySQL.query(('UPDATE `%s` SET pay = 1, pay_time = ? WHERE id = ?'):format(TABLE_NAME), {tm, billId})
        TriggerClientEvent(_R..':Updatepaybill', src, billId, amt, true, tm)
        TriggerClientEvent(_R..':successBill', src)
    end)
end)

RegisterNetEvent(_R..':DeleteBill')
AddEventHandler(_R..':DeleteBill', function(billId)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return end
    local id = tonumber(billId)
    if not id or id <= 0 then return end
    MySQL.query(('DELETE FROM `%s` WHERE id = ? AND identifier = ? AND pay = 0'):format(TABLE_NAME), {id, xPlayer.identifier})
end)
