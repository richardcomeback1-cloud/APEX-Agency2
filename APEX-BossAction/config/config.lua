Config = Config or {}

Config["Debug"] = false
Config["PlayerLoaded"] = 3000
Config["DrawDistance"] = 3.0 -- ระยะแสดง DrawTextUI
Config["distance"] = 1.5 -- ระยะการโต้ตอบ (กด E)
Config["Position"] = {
	['ambulance'] = {
		grade = {
			[4] = true,
			[5] = true
		},
		sack = "unemployed" -- @ เมื่อถูกไล่ออก จะ setJobs เป็นอาชีพนี้
	},
	['police'] = {
		grade = {
			[6] = true,
			[7] = true
		},
		sack = "unemployed" -- @ เมื่อถูกไล่ออก จะ setJobs เป็นอาชีพนี้
	},
	['council'] = {
		grade = {
			[3] = true,
			[4] = true
		},
		sack = "unemployed" -- @ เมื่อถูกไล่ออก จะ setJobs เป็นอาชีพนี้
	},
}
