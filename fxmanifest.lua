fx_version 'cerulean'
game 'gta5'

author 'Troy Scripts'
description 'Nederlandse kentekens en toonbaar kentekenbewijs voor ESX / ox_inventory'
version '1.1.0'

shared_scripts { '@ox_lib/init.lua', 'config/config.lua', 'shared/plate_format.lua', 'shared/taxi.lua' }
client_scripts { 'client/main.lua', 'client/registration.lua' }
server_scripts { '@oxmysql/lib/MySQL.lua', 'server/main.lua', 'config/webhooks.lua', 'server/webhook.lua', 'server/registration.lua' }
ui_page 'html/index.html'
files { 'textures/*.png', 'html/index.html', 'html/style.css', 'html/app.js' }
dependencies { '/onesync', 'ox_lib', 'oxmysql', 'ts_bridge' }
