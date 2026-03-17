shared_script "@bt_defender/module/shared.lua"

fx_version 'adamant'
game 'gta5'
lua54 'yes'

shared_scripts {
    '@es_extended/imports.lua',
    '@ox_lib/init.lua'
}

client_scripts {
	'config/config.lua',
	'config/config_func.lua',
   	'client/*.lua'
}

server_scripts {
	"@oxmysql/lib/MySQL.lua",
	'config/config.lua',
	'config/config_func.lua',
	'config/config_webhook.lua',
	'server/*.lua'
}

ui_page 'html/ui.html'

files {
    'html/**',
}