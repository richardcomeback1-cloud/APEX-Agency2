Config = Config or {}

Config["client_text-notify"] = function(type)
	if type == "job-not_math" then
		exports['mythic_notify']:SendAlert('error', 'คุณไม่ได้อยู่ในหน่วยงานนี้')
	elseif type == "job-grade_not_math" then
		exports['mythic_notify']:SendAlert('info', 'คุณไม่มีสิทธิ์เปิดเมนู')
	end
end