fx_version 'cerulean'
game 'gta5'
author 'Troy Scripts'
description 'Centrale ondersteuningsbridge voor Troy Scripts'
version '1.0.1'
shared_scripts { '@ox_lib/init.lua', 'locales/*.lua', 'locale.lua', 'config.lua', 'vehicle_config.lua', 'config_validation.lua', 'config_version.lua' }
client_scripts { 'client/screenshots.lua', 'client/main.lua', 'client/camera.lua', 'client/radial.lua', 'client/keycard_support.lua', 'client/vehicles.lua', 'client/alerts.lua', 'shared_status.lua' }
server_scripts { 'server_config.lua', 'server/validate.lua', 'server/framework.lua', 'server/money.lua', 'server/inventory.lua', 'server/vehicles.lua', 'server/billing.lua', 'server/main.lua', 'server/screenshot_upload.js', 'server/webhooks.lua', 'server/diagnostics.lua', 'server/updates.lua', 'server/update_check.lua', 'shared_status.lua' }
dependency 'ox_lib'

ui_page 'web/alerts.html'
files { 'web/alerts.html', 'web/alerts.css', 'web/alerts.js' }
