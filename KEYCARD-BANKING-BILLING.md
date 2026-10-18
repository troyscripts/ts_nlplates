# Voorbereiding keycard, banking en billing

Bridge **0.0.3** hoort bij ts_keycard **1.1.4** en ts_hostage **1.1.8**.
Keycard is nu aangesloten; Apex/okok-resources zelf zijn niet aangepast.

## Gekozen koppelingen

| Onderdeel | Provider |
| --- | --- |
| Spelergegevens, rechten en contant geld | ESX |
| Persoonlijk banksaldo en bankmutaties | Apex Banking: GetBalance, AddMoney, RemoveMoney |
| Society-saldi en mutaties | Alleen esx_addonaccount via getSharedAccount-event |
| Facturen aanmaken en opvragen | Apex Billing: Bill, GetInvoice |
| Items en inventoryhooks | ox_inventory |

De Apex-adapters zijn gebaseerd op je eerder aangeleverde apex_banking.zip en
apex_billing.zip van 13 september 2026. Deze bestanden zijn alleen gelezen.
Er worden geen Apex-bedrijfsrekeningexports aangeroepen vanuit de societyadapter.
Een gestopte Apex-bank blokkeert een bankmutatie: de bridge schrijft niet alsnog
via een tweede route af. Apex verzorgt zijn eigen transactielog en UI-refresh.

Een directe bankbetaling is geen factuur. Een factuur wordt later betaald;
CreateInvoice retourneert een factuurreferentie, geen betaalbewijs. GetInvoice(id)
geeft de Apex-factuur terug (waaronder status), of nil plus foutcode bij een
ongeldige aanvraag/providerfout. Alleen serverresources kunnen deze exports gebruiken.

### Beperking in de aangeleverde Apex Billing

Apex gebruikt in ESX-modus esx_addonaccount voor society-ontvangsten, maar vraagt daar
GetSharedAccount als export op. Onze eigen societyadapter gebruikt het callback-event.
De aangeleverde Apex-betaalroutine controleert bovendien de retourwaarde van de
society-bijschrijving niet voordat de factuur op betaald wordt gezet. Dat wordt niet
opgelost door alleen ts_bridge te wijzigen. Daarom bevat deze versie geen PayInvoice-export
en geen automatische kaartuitgifte na factuurbetaling. Betaling via de bestaande Apex-UI
blijft door Apex zelf afgehandeld; daar is nu niets aan veranderd.

Voordat we factuurbetaling aan kaartuitgifte koppelen, moet de Apex-betaalroutine apart
worden aangepast/gecontroleerd op addonaccount-compatibiliteit, verificatie van de
bijschrijving en afhandeling bij fouten. Er is geen tweede societybijschrijving toegevoegd:
dat zou bij een al geslaagde Apex-betaling dubbel geld opleveren.

## Server-API voor speler en rechten

- `GetPlayerData(id)` → `{source, identifier, name, group, job}` of `nil, foutcode`.
  job bevat name, grade, label en grade_label. Alleen ESX wordt ondersteund.
- `HasJob(id, jobs, minimumGrade)` → boolean. jobs is bijvoorbeeld `{police=true}`.
- `HasPermission(id, rules)` → boolean. Accepteert expliciete OR-regels voor
  `ace`, `groups`, `jobs` en `minimumGrade`. Console-ID 0 krijgt niet automatisch toegang.
  ACE werkt ook zonder ESX; ESX-groepen en jobs niet. Een owner-groep is geen algemene
  ACE-vrijstelling en krijgt uitsluitend toegang als hij in rules.groups staat.

```lua
local allowed = exports.ts_bridge:HasPermission(source, {
    ace = 'ts_keycard.admin',
    groups = { owner = true, admin = true },
    jobs = { police = true }, minimumGrade = 7
})
```

De aanroepende resource moet rechten, afstand, doelgroep en herhaalde aanvragen zelf
controleren. Deze bridge voegt geen openbare net-events voor geld, items of facturen toe.

## Server-API voor geld

| Export | Resultaat |
| --- | --- |
| GetMoney(id, 'cash' of 'bank') | saldo of nil, foutcode |
| AddMoney(id, account, amount, reason) | resultaatobject |
| RemoveMoney(id, account, amount, reason) | resultaatobject |
| GetSocietyBalance(key) | saldo, opgeloste rekeningnaam; of nil, foutcode |
| AddSocietyMoney(key, amount) | resultaatobject |
| RemoveSocietyMoney(key, amount) | resultaatobject |

Mutaties geven `{ok, code?, uncertain, before?, after?, account?}`. Controleer altijd
`result.ok`; een Lua-table is ook bij ok=false truthy. Bedragen moeten positieve gehele
getallen zijn. Te weinig saldo, ongeldige bedragen en ontbrekende resources worden geweigerd.
Na de mutatie wordt het saldo gecontroleerd. Bij een providerfout na een mogelijke
mutatie is `uncertain=true`: niet automatisch opnieuw afschrijven of terugbetalen.
Controleer dan eerst de transactiestatus. De bridge herhaalt geldmutaties nooit automatisch.

```lua
-- Voorbeeld van een losse bankafschrijving; keycard gebruikt daarnaast een aankooptransactie.
local result = exports.ts_bridge:RemoveMoney(playerId, 'bank', 10, 'Politiekaart')
if not result.ok then
    -- Stop de uitgifte; bij uncertain kan het saldo al veranderd zijn.
    return
end
```

Dit zijn losse betaalhandelingen, geen atomaire aankooptransactie. Bankafschrijving,
societybijschrijving en kaartuitgifte worden in ts_keycard/server/payment.lua samen afgehandeld, inclusief foutafhandeling
en herstel van bekende fouten. Alleen alle drie los aanroepen is onvoldoende.
Een lock voorkomt gelijktijdige bridge-aanroepen op hetzelfde saldo; externe scripts
vallen niet onder die lock. Er is geen persistent transactiegrootboek toegevoegd.

De societyadapter gebruikt esx_addonaccount en haalt na elke mutatie een nieuwe snapshot
op. `SocietyAccounts.police = {'society_police', 'socity_police'}` gebruikt de standaardrekening
eerst en daarna de oude spelling uit jouw kaartconfiguratie. Als beide rekeningen bestaan, wordt alleen de eerste gebruikt.
Het zijn alternatieven, geen rekeningen die onderling worden gesynchroniseerd.
Je kunt ook een exacte rekeningnaam doorgeven. Er worden geen rekeningen aangemaakt.
Apex Billing gebruikt society_<job>. Gebruik dus society_police voor de toekomstige
politie-factuurstroom; een oude socity_police-rekening wordt niet automatisch gemigreerd.

## Server-API voor inventory

Gebruikt ox_inventory, configureerbaar via InventoryResource in server_config.lua.
Argumenten volgen de overeenkomstige ox_inventory-API, behalve waar hieronder vermeld.

| Export | Argumenten |
| --- | --- |
| GetItemSlots | inventory, item, metadata?; zoekt automatisch met mode 'slots' |
| GetInventorySlot | inventory, slot |
| GetEmptySlot | inventory |
| GetItemCount | inventory, item, metadata?, strict? |
| HasItem | inventory, item, amount=1, metadata?, strict? |
| CanCarryItem | inventory, item, amount, metadata? |
| AddItem | inventory, item, amount, metadata?, slot?; geen callback |
| RemoveItem | inventory, item, amount, metadata?, slot?, ignoreTotal?, strict? |
| SetItemMetadata | inventory, slot, metadata |
| GetInventories | type; alleen als de geïnstalleerde inventoryversie dit ondersteunt |

Read-exports geven de providerresultaten, of nil plus foutcode bij een mislukte aanroep.
Mutaties geven succes/reden zoals de provider, of false plus foutcode. Ook bij mislukte
itemmutaties kan een externe provider na een gedeeltelijke wijziging een fout geven;
herhaal niet blind. SetItemMetadata controleert het slot en geeft true als de setter
zonder fout terugkeert; de provider geeft zelf geen opslagbevestiging.

`RegisterInventoryHook(event, callback, options?)` ondersteunt swapItems, openInventory
en createItem. Geeft een bridge-token of nil plus foutcode. `RemoveInventoryHook(token)`
verwijdert alleen een hook van de aanroeper. Bij resource-stop worden eigen hooks opgeruimd.
Bij inventory-stop vervallen tokens. Registreer opnieuw na het lokale serverevent
`ts_bridge:inventoryReady`. Retourwaarden van callbacks, waaronder false om te blokkeren,
blijven behouden. Voorwaarden voor verouderde kaarten blijven in ts_keycard.

## Client-API

- AddLocalEntity(entity, options) / RemoveLocalEntity(entity, optionName): targetopties
  voor één lokale NPC. Optienamen moeten met de aanroepende resource plus `_` beginnen.
  De bridge ruimt de opties op; het kaartscript blijft verantwoordelijk voor de NPC zelf.
  Na een targetrestart moet het aangesloten script opties opnieuw registreren.
- UseItem(data, callback): ox_inventory useItem, afhandeling via callback. Bij ontbrekende
  inventory volgt callback(nil) en false. true betekent aangevraagd, niet voltooid.
- ProgressCircle(options), InputDialog(title, rows, options?), AlertDialog(options):
  ox_lib-interfaces met behoud van de annuleringsresultaten.

Client- en server-InventoryResource moeten dezelfde naam bevatten. Resource hernoemen
maakt geen ander inventoryproduct compatibel. NPC-spawnlogica, contextmenu's, NUI,
callbacks voor kaartuitgifte, KVP-opslag, intrekkingsgeneraties en de deurregels blijven
in het kaartscript. Er is geen vlr_doorlock-adapter of deurtoegangwijziging toegevoegd.

## Apex-facturen

Standaard: `Billing = {Provider='apex', Resource='apex_billing'}`.
`CreateInvoice({issuerId, targetId, amount, society, label})` maakt één factuurregel
met het opgegeven bedrag en expliciet 0% btw; het bedrag wordt dus niet onbedoeld
met de standaard-btw verhoogd. Voor deze eenvoudige bridge-API zijn geen losse
btw-/regelopties toegevoegd. Apex blijft zijn eigen uitgiftekosten, limieten,
benodigde items en jobrechten controleren. Zelf een society opgeven om de issuerjob
te omzeilen kan niet: society moet de jobnaam of society_<job> van de uitgever zijn.

```lua
local result = exports.ts_bridge:CreateInvoice({
    issuerId = source, targetId = target,
    amount = 10, society = 'society_police', label = 'Politiekaart'
})
if result.ok then
    print('Factuur aangemaakt: ' .. tostring(result.id))
end
```

`GetBillingStatus()` geeft `{resource, provider, ready}`. ready betekent resource
beschikbaar; het is geen database- of betaaltest. `GetInvoice(id)` gebruikt Apex GetInvoice.
Bij een exception kan al een factuur zijn geschreven: uncertain=true betekent
niet automatisch opnieuw aanmaken. Bij gewone weigeringen blijft de Apex-foutcode behouden.

### Optioneel eigen billingproduct

Alleen bij `Billing.Provider='custom'` kan de ingestelde Billing.Resource zelf
`RegisterBillingProvider(handler)` aanroepen. Registreer opnieuw na resourceherstarts.
De handler krijgt de factuurvelden plus requestingResource en retourneert
`{ok=true,id=...}` of `{ok=false,code=...}`. Wacht in een passende adapter op de echte
uitkomst van een asynchrone provider. `Provider='none'` schakelt facturen uit.

## Technische referenties

- De eerder aangeleverde Apex server/exports.lua-bestanden zijn de basis voor de Apex-aanroepen.
- [ESX xPlayer](https://docs.esx-framework.org/en/esx_core/es_extended/server/xplayer)
- [ox_inventory server](https://overextended.dev/docs/ox_inventory/Functions/Server)
- [ox_inventory hooks](https://overextended.dev/docs/ox_inventory/Functions/Server/Hooks)
