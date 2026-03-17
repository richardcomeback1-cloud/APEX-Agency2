
local _R = GetCurrentResourceName()
RegisterKeyMapping('Billing', 'Billing', 'keyboard', 'F7')


PlayerData = {}
MyBill = {}
Thread = {} 
 
 
 

AddEventHandler('onResourceStart', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        PlayerData = ESX.GetPlayerData()
        Wait(1500)
        print('^3 Loaded Bills')
        ESX.TriggerServerCallback(_R..':CallBill', function(result) 
            MyBill = result 
        end, PlayerData.identifier)

    end
end)


RegisterNetEvent('esx:playerLoaded', function(xPlayer)
    PlayerData = xPlayer
    ESX.TriggerServerCallback(_R..':CallBill', function(result) 
        MyBill = result
    end, PlayerData.identifier)
end)

RegisterNetEvent("esx:setJob", function(job)
	PlayerData.job = job
end)

-- RegisterCommand('Billing', function()
  
-- end)
exports('Billing', function() 
    if IsEntityDead(PlayerPedId()) then
        return
    end
    if PlayerData.job.name == 'police' then
        return
    end
    if PlayerData.job.name == 'ambulance' then
        return
    end
    if PlayerData.job.name == 'council' then
        return
    end
    SetNuiFocus(true, true)
    SendNUIMessage({
        action = 'mybill',
        bills = MyBill,
        identifier = PlayerData.identifier
    })
end)
GetAccount = function()
    local bank, money = 0, 0
    local account = ESX.GetPlayerData().accounts
    for k,v in pairs(account) do
        if v.name == 'money' then
            money = v.money
        end
        if v.name == 'bank' then
            bank = v.money
        end
    end
    return bank, money
end

RegisterNUICallback('paybill', function(data, cb)
    data.billid = tonumber(data.billid)
    local bills = MyBill
    local bank, money = GetAccount()
    for k,v in pairs(bills) do
        if v.id == data.billid then
            if money >= v.amount then
                TriggerServerEvent(_R..':PayBill', v)
                MyBill[k].pay = 1
                cb(true)
            elseif bank >= v.amount then
                TriggerServerEvent(_R..':PayBill', v)
                MyBill[k].pay = 1
                cb(true)
            else
               
                pcall(function()
                    exports["Ace.Notify"]:ClientNotify({ 
                        content = 'คุณมีเงินไม่พอจ่าย',
                        timeout = 5,
                        type = "warning"     -- | success / error / warning
                    })
                end)
                cb(false)
            end
            break
        end 
    end
end)
RegisterNetEvent(_R..':Updatepaybill', function(billId, amount,removeAll, pay_time)
 
    billId = tonumber(billId) 
    for k,v in pairs(MyBill) do
        if v.id == billId then
            if removeAll then
                MyBill[k].pay = 1
                MyBill[k].pay_time = pay_time
            else 
                MyBill[k].amount = amount
            end
            break
        end 
    end
end)

RegisterNetEvent(_R..':successBill', function()
    SendNUIMessage({
        action = 'play'
    })
end)

RegisterNUICallback('deletebill', function(data)
    TriggerServerEvent(_R..':DeleteBill', data.billid)
end)

RegisterNUICallback('closeDisplay', function()
    SetNuiFocus(false, false)
end)

exports('DepartmentMenu', function(job)
    TriggerEvent(_R..':DepartmentMenu', job)
end)

exports('SendBill', function(bill)
    TriggerServerEvent(_R..':CrateBill', bill)
end)
exports('SendBillGang', function(bill)
    TriggerServerEvent(_R..':CrateBillGang', bill)
end)

exports('CreateBill', function(playerId)
    inputNameBill(playerId)
end)

RegisterNetEvent(_R..':Update', function(data)
    table.insert(MyBill, data)
end)
-- RegisterCommand('test', function()
--     inputNameBill(10)
-- end)
inputNameBill = function(playerId)
    ESX.UI.Menu.CloseAll()
    ESX.UI.Menu.Open('dialog', 'TEST_Ambulance', 'input_reason', {
        title = 'กรอกชื่อบิล',
    }, function(data, menu)
        if data.value then
            menu.close()
            inputPriceBill(playerId, data.value)
        end
    end, function(data, menu)
        menu.close()
    end)
end


inputPriceBill = function(playerId, bilName)
    ESX.UI.Menu.CloseAll()
    ESX.UI.Menu.Open('dialog', 'TEST_Ambulance', 'input_price', {
        title = 'กรอกจำนวนค่าบิล',
    }, function(data, menu)
        if tonumber(data.value) and tonumber(data.value) > 0 and tonumber(data.value) <= 5000000 then
            menu.close()
            TriggerServerEvent(_R..':CrateBill', {
                fine = tonumber(data.value),
                reason = bilName,
                recive = playerId
            })
        end
    end, function(data, menu)
        menu.close()
    end)
end

Disable = function()
    if MyBill then
        local total = 0
        for _, bill in pairs(MyBill) do
            if bill.pay == 0 then 
                total = total + (bill.amount or 0)
            end
        end

        if total >= 5000000 then 
           
            pcall(function()
                exports["Ace.Notify"]:ClientNotify({ 
                    content = 'ค้างชำระ มากกว่า 1 ล้านขึ้นไป',
                    timeout = 5,
                    type = "warning"     -- | success / error / warning
                })
            end)

            return true
        else 
            return false
        end
    end
    return false
end

exports('Disable' , Disable)
exports('getBill', function()
    return MyBill
end)
exports('payBill', function(k ,id)
     
end)