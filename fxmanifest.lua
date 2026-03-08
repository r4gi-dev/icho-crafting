fx_version 'cerulean'
game 'gta5'

name 'icho_crafting'
description 'Custom Crafting System'
author 'r4gi'
version '1.0.0'

lua54 'yes'

shared_scripts {
    '@ox_lib/init.lua',
    'config/*.lua'
}

client_scripts {
    'client/client.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/server.lua'
}

ui_page 'nui/index.html'

files {
    'nui/index.html',
    'nui/style.css',
    'nui/script.js'
}

dependencies {
    'ox_inventory',
    'ox_lib'
}