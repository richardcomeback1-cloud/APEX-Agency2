shared_script "@bt_defender/module/shared.lua"



-- NC PROTECT+


fx_version 'cerulean'
games { 'gta5' }
author 'crossover1990'



ui_page 'html/index.html'

shared_script 'config.lua'

client_scripts {
    'script/client.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'script/server.lua'
}


file {
    'html/***'
}

lua54 'yes'