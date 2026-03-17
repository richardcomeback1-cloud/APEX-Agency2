ESX = exports['es_extended']:getSharedObject()

Config = {}

Config.TableName = 'apex_bills'


Config.Vat = {
	['council'] = 0,
	['ambulance'] = 80,
	['police'] = 0,
	['admin'] = 0,
}

Config.LimitCheck = true

Config.LimitCount = {
    ['police'] = 50000000,
    ['ambulance'] = 50000000,
    ['council'] = 50000000,
    ['admin'] = 10000000,
}

Config.AlertText = "คุณถูกตัดสินให้ล้มละลาย!!! เนื่องจากค้างชำระบิลเกินกำหนด กรุณาติดต่อแอดมิน"

