# Aanpasbare teksten

Nederlands (`nl`) is de hoofdlocale en standaard. Bewerk `nl.lua` met UTF-8.
Laat sleutels en formattekens zoals `%s`, `%d`, `%.1f`, `~y~`, `~s~` en `\n` intact.
Gebruik geen echte nieuwe regel binnen een korte Lua-string; gebruik `\n`.

Voor een extra taal: kopieer nl.lua naar bijvoorbeeld en.lua, verander
`Locales['nl']` in `Locales['en']`, vertaal de waarden en kies Locale = 'en' in config.lua.
Ontbrekende talen en sleutels vallen terug op Nederlands. Commandonamen, exports,
resourcebenamingen, technische foutcodes en metadata-veldnamen worden niet vertaald.
Expliciete tekstinstellingen in je bestaande config blijven voorrang houden.
Herstart de resource na het wijzigen. Foutieve Lua-syntax in een localebestand moet
worden hersteld; de fallback kan geen ongeldige Lua-broncode repareren.
