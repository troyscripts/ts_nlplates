# 1.0.4
- JG-compatibele kentekens met spaties; streepjes worden niet meer gegenereerd.
- Offline migratiehulp voor reeds opgeslagen 1.0.3-kentekens.
- Kentekenloket plaatsen/verwijderen via ACE admin en persistent opgeslagen locatie.
- Vervangingsprijs en betaalrekening via config; opbrengst naar society_police.
- Uniek documentnummer bij vervanging; oude kaarten rood NIETIG VERKLAARD.
- Bedrijfslabel voor opgeslagen jobvoertuigen en gevalideerde JG-jobgarage-spawners.
- Configversie 1.0.2.

# 1.0.3
- Instelbare serverzijdige kentekengenerator (standaard A-111-AA).
- Centrale nummerreservering voor JG-aankopen en nieuw NPC-verkeer.
- Eenmalig kentekenbewijs in ox_inventory-dashboardkastjes.
- Kaartweergave, meenemen, bekijken en tonen aan nabije spelers.
- Servercontrole op toegang, bezit en afstand; actuele ESX-eigenaar.
- Nieuwe dependencies en installatiehandleiding; configversie 1.0.1.
- Bestaande spelerskentekens en sleutelitems worden niet gemigreerd.

# 1.0.2

- Herzien voor publicatie, naar aanleiding van de in-game screenshots.
- Moderne achtergronden met rustiger geel, duidelijkere donkere rand en beter zichtbare NL/EU-symbolen.
- Nieuwe donkerblauwe oldtimerachtergrond.
- Eigen gedeelde kentekenfonttexture: lagere en stevigere cijfers/letters.
- Bijpassende normal map; L8-font in een afzonderlijke gestreamde YTD.
- Begrensde laadtijd, standaardfont bij timeout en opruimen bij stoppen.
- Lokaal debugcommando /nlplaatfont aan|uit|status via bestaande debugoptie.
- Oldtimer op build 3095+: donkerblauwe achtergrond op index 6 met witte GTA-letters (#FEFEFE).
- Bestaande oldtimerindices 1/2 worden door de voertuigbeheerder naar 6 omgezet.
- Mechanic-keuze voor oldtimer moet nu index 6 zijn; README aangepast.
- Kentekennummers en voertuigmodellen blijven ongewijzigd; geen SQL-migratie.
- Exacte crème-tint niet instelbaar. Oudere builds houden geel met een melding.
- Configversie blijft 1.0.0; geen configwijzigingen.
- Textures lokaal bekeken, ook op klein formaat. In-game resultaat nog te testen.

# 1.0.1

- README uitgebreid met installatie-instructies voor JG Mechanic en andere tuningmenu's.
- Exacte JG-plaatkeuzes en GTA-plaatindices 0, 1 en 3 gedocumenteerd.
- Geen mechanic-config meegeleverd; gebruikers passen hun eigen configuratie aan.
- Scriptversie en version.json naar 1.0.1; configversie blijft 1.0.0.
- Geen wijziging in textures of runtimegedrag.

# 1.0.0

- Scriptversie en configversie op 1.0.0 gezet.
- Zelfstandige server-side GitHub-versiechecker toegevoegd.
- Automatische controle bij starten en consolecommando ts_nlplates_check.
- Numerieke versievergelijking, timeout, foutmeldingen en main/master-fallback.
- Configversiecontrole in serverconsole; ts_bridge niet nodig.
- Textures met gecorrigeerde NL/EU-symbolen uit 0.0.2 behouden.

# 0.0.2

- Verticale uitrekking uit het NL-logo en de EU-sterren verwijderd.
- Symbolen opnieuw geplaatst voor standaard GTA-plaatverhoudingen.
- De vorm van de voertuigplaat en GTA-kentekenletters zijn niet aangepast.
- Configversie blijft 0.0.1; geen config- of JG-wijzigingen.
- PNG-bestanden visueel gecontroleerd; nog in FiveM testen.

# 0.0.1

- Eerste testversie met gewone, oldtimer- en luxe plaatachtergrond.
- Behoud van bestaande kentekentekst en voertuigidentiteit.
- JG Mechanic 1.9.0-config met drie stijlen.
- Lokale textures en opruimen bij stoppen van de resource.
- Uitleescommando /nlplaatinfo voor de F8-console.
