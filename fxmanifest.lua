fx_version 'cerulean'
game 'gta5'

author 'Troy Scripts'
description 'Nederlandse kentekens en toonbaar kentekenbewijs voor ESX / ox_inventory'
version '1.0.6'

shared_scripts { '@ox_lib/init.lua', 'config.lua', 'plate_format.lua' }
client_scripts { 'client.lua', 'registration_client.lua' }
server_scripts { '@oxmysql/lib/MySQL.lua', 'server.lua', 'webhook_config.lua', 'vehicle_models.lua', 'webhook_server.lua', 'registration_server.lua' }
ui_page 'html/index.html'
files { 'textures/*.png', 'html/index.html', 'html/style.css', 'html/app.js' }
dependencies { '/onesync', 'ox_lib', 'oxmysql', 'ts_bridge' }
