ESX			    		= nil

local Keys = {
    ["ESC"] = 322, ["F1"] = 288, ["F2"] = 289, ["F3"] = 170, ["F5"] = 166, ["F6"] = 167, ["F7"] = 168, ["F8"] = 169, ["F9"] = 56, ["F10"] = 57,
    ["~"] = 243, ["1"] = 157, ["2"] = 158, ["3"] = 160, ["4"] = 164, ["5"] = 165, ["6"] = 159, ["7"] = 161, ["8"] = 162, ["9"] = 163, ["-"] = 84, ["="] = 83, ["BACKSPACE"] = 177,
    ["TAB"] = 37, ["Q"] = 44, ["W"] = 32, ["E"] = 38, ["R"] = 45, ["T"] = 245, ["Y"] = 246, ["U"] = 303, ["P"] = 199, ["["] = 39, ["]"] = 40, ["ENTER"] = 18,
    ["CAPS"] = 137, ["A"] = 34, ["S"] = 8, ["D"] = 9, ["F"] = 23, ["G"] = 47, ["H"] = 74, ["K"] = 311, ["L"] = 182,
    ["LEFTSHIFT"] = 21, ["Z"] = 20, ["X"] = 73, ["C"] = 26, ["V"] = 0, ["B"] = 29, ["N"] = 249, ["M"] = 244, [","] = 82, ["."] = 81,
    ["LEFTCTRL"] = 36, ["LEFTALT"] = 19, ["SPACE"] = 22, ["RIGHTCTRL"] = 70,
    ["HOME"] = 213, ["PAGEUP"] = 10, ["PAGEDOWN"] = 11, ["DELETE"] = 178,
    ["LEFT"] = 174, ["RIGHT"] = 175, ["TOP"] = 27, ["DOWN"] = 173,
    ["NENTER"] = 201, ["N4"] = 108, ["N5"] = 60, ["N6"] = 107, ["N+"] = 96, ["N-"] = 97, ["N7"] = 117, ["N8"] = 61, ["N9"] = 118
  }

local NotiID			= 1
local ShowNow			= {}
local BaseRight 		= 	{
								["Base"] = 1
							}

Citizen.CreateThread(function()
	while ESX == nil do
		TriggerEvent("esx:getSharedObject", function(obj) ESX = obj end)
		Citizen.Wait(200)
	end

	while not ESX.GetPlayerData() or not ESX.GetPlayerData().job do
		Citizen.Wait(200)
	end

	local playerJob = ESX.GetPlayerData().job
	if playerJob and playerJob.name then
		TriggerServerEvent('APEX-AllNotify:cacheJob', playerJob.name)
	end

	UpdatePosNotify()
end)

RegisterNetEvent('esx:setJob')
AddEventHandler('esx:setJob', function(job)
	if job and job.name then
		TriggerServerEvent('APEX-AllNotify:cacheJob', job.name)
	end
end)

-- //////////////////////////////////////////////////////////////////////////// Notify
-- //////////////////////////////////////////////////////////////////////////// Notify
-- //////////////////////////////////////////////////////////////////////////// Notify

function AddNotify(data)
	if data.time == nil then
		data.time = 5000
	end
	data.id = NotiID
	if data.text then
		SendNUIMessage({
			type = "togglenotify",
			notify = data,
		})
		NotiID = NotiID + 1
		ShowNow[data.id] = true
	end
end

RegisterNetEvent('APEX-AllNotify:AddNotify')
AddEventHandler('APEX-AllNotify:AddNotify', function(data)
    exports['APEX-AllNotify']:AddNotify({
		type = data.type,
		text = data.text,
		time = data.time,
	})
end)

RegisterNUICallback('AddNotify', function(data, cb)
	exports['APEX-AllNotify']:AddNotify({
		type = data.type,
		text = data.text,
		time = data.time,
	})
	cb({status = "success"})
end)


RegisterCommand('notify', function(source, args, rawCommand)
	if args[1] and args[2] and args[1] == "success" or args[1] == "error" or args[1] == "warning" then
		exports['APEX-AllNotify']:AddNotify({
			type = args[1],
			text = args[2],
			time = 120000,
		})
	end
end)

RegisterNetEvent('APEX-AllNotify:setright')
AddEventHandler('APEX-AllNotify:setright', function(name,right)
	if right then
		BaseRight[name] = right
	else
		BaseRight[name] = nil
	end
	UpdatePosNotify()
end)

function UpdatePosNotify()
	local mostright = 1
	for k,v in pairs(BaseRight) do
		if v > mostright then
			mostright = v
		end
	end
	SendNUIMessage({
		type = "changeposition",
		right = mostright,
	})
end

-- Citizen.CreateThread(function()

-- 	-- example -- example -- example -- example -- example -- example -- example -- example -- example -- example -- example
-- 	Citizen.Wait(1000)
-- 	exports['APEX-AllNotify']:AddNotify({
-- 		type = "success",
-- 		text = "test notify success type",
-- 		time = 5000,
-- 	})
-- 	exports['APEX-AllNotify']:AddNotify({
-- 		type = "error",
-- 		text = "Lorem ipsum dolor sit amet consectetur adipisicing elit. Consequatur nobis illo dolorem facilis reprehenderit distinctio in delectus natus qui amet. Tempora error perspiciatis repellendus, quia cupiditate quidem quas exercitationem? Aperiam?",
-- 		time = 5000,
-- 	})
-- 	-- example -- example -- example -- example -- example -- example -- example -- example -- example -- example -- example

-- 	Citizen.Wait(3000)

-- 	exports['APEX-AllNotify']:AddNotify({
-- 		type = "error",
-- 		text = "Lorem ipsum dolor sit amet consectetur adipisicing elit. Consequatur nobis illo dolorem facilis reprehenderit distinctio in delectus natus qui amet. Tempora error perspiciatis repellendus, quia cupiditate quidem quas exercitationem? Aperiam?",
-- 		time = 5000,
-- 		right = 700
-- 	})
	
-- end)

-- //////////////////////////////////////////////////////////////////////////// Notify
-- //////////////////////////////////////////////////////////////////////////// Notify
-- //////////////////////////////////////////////////////////////////////////// Notify
-- //////////////////////////////////////////////////////////////////////////// Notify


-- //////////////////////////////////////////////////////////////////////////// Alert
-- //////////////////////////////////////////////////////////////////////////// Alert
-- //////////////////////////////////////////////////////////////////////////// Alert

local Alert             = {}
local HaveAlert         = false
local AlertZone			= {}
local onlyBagCase  		= false
local AlertIDCounter    = 0
local AlertZoneToken    = {}

RegisterCommand('csbg', function ()
	if ESX.GetPlayerData().job.name ~= 'police' then
		return
	end
	onlyBagCase = not onlyBagCase
end, false)

RegisterNetEvent(scriptName..':AddAlert')
AddEventHandler(scriptName..':AddAlert', function(data)
    local AlertMe = false
	local icon = data.icon
    if data.job then
        if ESX.GetPlayerData().job.name == data.job then
            AlertMe = true
        end
    end
	if data.gang then
		local MyGang = exports['nakin_managegang']:GetMyGang()
		if MyGang then
			if MyGang.gangid == data.gang then
				AlertMe = true
			end
		end
	end
	if onlyBagCase and not data.bagcase then
		AlertMe = false
	end
    if AlertMe then
        local Index = GetLastIndex()
        local WP_Key = GetWayPointKey()
        if not data.waypoint then
            WP_Key = false
        end

        if not data.time then
            data.time = 20
        end

        if not data.coords then
            local ped = PlayerPedId()
            local pCoords = GetEntityCoords(ped)
            data.coords = { x = pCoords.x, y = pCoords.y, z = pCoords.z }
        end

        if data.coords then
            local zone = GetNameOfZone(data.coords.x, data.coords.y, data.coords.z)
            if Config["ZoneName"][zone] then
                data.zone = Config["ZoneName"][zone]
            else
                data.zone = "64BIT TOWN"
            end
        end

        if not icon then
            if data.job then
                icon = ""..data.job.."_alert"
            end
            if data.gang then
                icon = "gang_alert"
            end
        end

        Alert[Index] = {
            index = Index,
            text = data.text,
            wp_key = WP_Key,
            time = data.time,
            coords = data.coords,
            icon = icon,
            zone = data.zone,
            job = data.job,
            case = data.case
        }

        local blip = AddBlipForRadius(data.coords.x, data.coords.y, data.coords.z , 20.0) -- you can use a higher number for a bigger zone

        SetBlipHighDetail(blip, true)
        SetBlipColour(blip, 1)
        SetBlipAlpha (blip, 128)

        SendNUIMessage({type = "add", data = Alert[Index] })

        CreateThread(function()
            Citizen.Wait(20000)
            RemoveBlip(blip)
        end)
    end
end)

function GetLastIndex()
    AlertIDCounter = AlertIDCounter + 1
    if AlertIDCounter > 2147483000 then
        AlertIDCounter = 1
    end
    while Alert[AlertIDCounter] do
        AlertIDCounter = AlertIDCounter + 1
        if AlertIDCounter > 2147483000 then
            AlertIDCounter = 1
        end
    end
    return AlertIDCounter
end

function GetWayPointKey()
    local Key = 1
    for _, alertData in pairs(Alert) do
        if alertData and alertData.wp_key then
            Key = Key + 1
        end
    end
    return Key
end

Citizen.CreateThread(function()
	local nextTickAt = 0
	while true do
		local sleep = 1000
		local now = GetGameTimer()

		if now >= nextTickAt then
			HaveAlert = false
			for k, v in pairs(Alert) do
				if v.time > 0 then
					HaveAlert = true
					v.time = v.time - 1
				else
					SendNUIMessage({type = "remove", id = k })
					Alert[k] = nil
				end
			end
			nextTickAt = now + 1000
		end

		if HaveAlert then
			sleep = 25
			for k, v in pairs(Alert) do
				if v.time > 0 and v.wp_key then
					if IsControlPressed(0, Keys["LEFTSHIFT"]) and IsDisabledControlJustPressed(0, Keys[tostring(v.wp_key)]) then
						SetNewWaypoint(v.coords.x, v.coords.y)

						if v.case then
							TriggerServerEvent('APEX-MedicReport:UpdateCase', v.case, 'getcase')
							TriggerEvent('APEX-MedicReport:markGPS', v.case)
						end

						SendNUIMessage({type = "remove", id = k })
						Alert[k] = nil
						Citizen.Wait(1000)
						break
					end
				end
			end
		end

		Citizen.Wait(sleep)
	end
end)

RegisterNetEvent('APEX-AllNotify:CreateAlertZone')
AddEventHandler('APEX-AllNotify:CreateAlertZone', function(coords)
	local index = ("%d_%d"):format(math.floor(coords.x), math.floor(coords.y))
	local token = (GetGameTimer() .. '_' .. tostring(math.random(1000, 9999)))
	AlertZoneToken[index] = token

	if AlertZone[index] and AlertZone[index].blip then
		RemoveBlip(AlertZone[index].blip)
	end

	AlertZone[index] = {coords = coords, time = 20}
	AlertZone[index].blip = AddBlipForRadius(coords.x, coords.y, coords.z , 20.0) -- you can use a higher number for a bigger zone
	SetBlipHighDetail(AlertZone[index].blip, true)
	SetBlipColour(AlertZone[index].blip, 1)
	SetBlipAlpha (AlertZone[index].blip, 128)
	SetTimeout(AlertZone[index].time * 1000, function()
		if AlertZoneToken[index] ~= token then
			return
		end
		if AlertZone[index] and AlertZone[index].blip then
			RemoveBlip(AlertZone[index].blip)
		end
		AlertZone[index] = nil
		AlertZoneToken[index] = nil
	end)
end)

-- Citizen.CreateThread(function()
-- 	while true do
--         Sleep = 1000
--         if AlertZone then
--        		local Ped = PlayerPedId()
--             local PedCoords = GetEntityCoords(Ped)
--         	for k,v in pairs(AlertZone) do
--         		if AlertZone[k] then
--         			Sleep = 0
--         			DrawMarker(28, v.coords, 0.0, 0.0, 0.0, 0, 0.0, 0.0, 20.0,20.0,20.0, 255,102,102,20, false, false, 2, false, false, false, false)	
--         		end
--         	end
--         end
-- 		Citizen.Wait(Sleep)
-- 	end
-- end)

-- Citizen.CreateThread(function()
-- 	while true do
--         Sleep = 1000
--         if AlertZone then
--         	for k,v in pairs(AlertZone) do
--         		if AlertZone[k] then
--         			if AlertZone[k].time > 0 then
--         				AlertZone[k].time = AlertZone[k].time - 1
--         			else
--         				AlertZone[k] = nil
--         			end
--         		end
--         	end
--         end
-- 		Citizen.Wait(Sleep)
-- 	end
-- end)

-- RegisterCommand('alert_police', function(source, args, rawCommand)
--     TriggerServerEvent("APEX-AllNotify:SendAlert",{
--         job = "police",
--         text = "ขโมยปูน",
--         waypoint = true,
--         time = 5,
--         coords = vector3(-404.35275268555, 1172.6705322266, 325.64163208008),
-- 		-- icon = "hh2"
--     })
-- end)

-- RegisterCommand('alert_ambulance', function(source, args, rawCommand)
--     TriggerServerEvent("APEX-AllNotify:SendAlert",{
--         job = "ambulance",
--         text = "ผู้ป่วย",
--         waypoint = true,
--         time = 5,
--         coords = vector3(-2191.4128417969, 4405.8271484375, 57.520233154297),
--     })
-- end)

-- //////////////////////////////////////////////////////////////////////////// Alert
-- //////////////////////////////////////////////////////////////////////////// Alert
-- //////////////////////////////////////////////////////////////////////////// Alert


-- //////////////////////////////////////////////////////////////////////////// iTemsNotify
-- //////////////////////////////////////////////////////////////////////////// iTemsNotify

-- local iTEMsNotify = {}
-- local itemID = 1
-- local PlayID = 1
-- local Amount = 2

-- Citizen.CreateThread(function()
-- 	while true do
--         Sleep = 1000
-- 		for i = 1,Amount do
-- 			if iTEMsNotify[PlayID] then
-- 				Sleep = 5000
-- 				local options = iTEMsNotify[PlayID]
-- 				SendNUIMessage({
-- 					type = "itemsnotify",
-- 					id = itemID,
-- 					action = string.upper(options.text) or 'Error',
-- 					name = options.name or 'Unknown',
-- 					label = options.label or 'Unknown',
-- 					count = options.count or '',
-- 					inventoryLink = Config['inventory_link'],
-- 					time = Config['Time'],
-- 					color = Config['Color'][string.upper(options.text)],
-- 					text = Config['Text'],
-- 					ea = EA,
-- 				})
-- 				PlayID = PlayID + 1
-- 				print(PlayID)
-- 			end
-- 		end
-- 		Citizen.Wait(Sleep)
-- 	end
-- end)

-- function SendNotification(options)
-- 	local EA = Config['Text']["EA"]
-- 	if Config["Special_ITEMS"][options.name] then
-- 		options.label = Config["Special_ITEMS"][options.name]
-- 		EA = ""
-- 	end
-- 	iTEMsNotify[itemID] = options
-- 	itemID = itemID + 1
-- end
-- RegisterNetEvent(scriptName..":sendNotification")
-- AddEventHandler(scriptName..":sendNotification", function(options)
-- 	SendNotification(options)
-- end)

-- RegisterCommand('testitems', function(source, args, rawCommand)
-- 	if args[1] and args[2] and args[3] and args[4] then
-- 		TriggerEvent(scriptName..":sendNotification",{
-- 			text = args[1],
-- 			name = args[2],
-- 			label = args[3],
-- 			count = ESX.Math.GroupDigits(tonumber(args[4]))
-- 		})
-- 	end
-- end)

-- //////////////////////////////////////////////////////////////////////////// iTemsNotify
-- //////////////////////////////////////////////////////////////////////////// iTemsNotify
