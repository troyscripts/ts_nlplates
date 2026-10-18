# okok-ondersteuning — 0.0.3

Apex blijft standaard geselecteerd. De scriptintegraties gebruiken dezelfde bankproviderkeuze.
Apex- en okok-resourcebestanden zelf zijn niet gewijzigd.

## okokBanking met ESX

Kies in ts_bridge/server_config.lua:

```lua
Banking = { Provider = 'okok', Resource = 'okokBanking' },
```

GetMoney/AddMoney/RemoveMoney met account='bank' gebruiken het persoonlijke ESX-bankaccount.
De bankresource moet gestart zijn; bij ontbreken volgt banking_unavailable en geen afschrijving.
Saldoverificatie, bedragvalidatie en de bestaande onzekere-foutafhandeling blijven gelden.
Dit pad ondersteunt het persoonlijke ESX-account, geen aparte spaarrekening of gedeelde
okokBanking V2-account. Er worden niet automatisch okok-transactiehistorie-items geschreven
of aparte UI-refresh-events aangeroepen. Cash blijft via ESX gaan.

De officiële okokBanking AddMoney/RemoveMoney/GetAccount-exports zijn voor societyaccounts.
Die worden hier bewust niet gebruikt voor persoonlijke banksaldi of society-geld.
Alle societyoperaties van ts_bridge blijven bij esx_addonaccount. De bridge synchroniseert
geen aparte okok-bedrijfsrekeningdatabase met addonaccount.

## okokBilling — providerkeuze voorbereid, adapter ontbreekt nog

De officiële documentatie toont een client-to-server CreateCustomInvoice-event, zonder
retourcontract met aangemaakte factuur-ID. Er is op basis daarvan geen betrouwbare
serveradapter gemaakt die de bestaande ts_bridge CreateInvoice-resultaten kan garanderen.
Er wordt geen factuuraanvraag via een spelerclient doorgestuurd en geen succes gefingeerd.

De keuze is voorbereid:

```lua
Billing = { Provider = 'okok', Resource = 'okokBilling' },
```

Zonder aangesloten versiegebonden serveradapter geeft CreateInvoice
`{ok=false, code='billing_adapter_required', uncertain=false}`. GetBillingStatus.ready is
false, ook wanneer okokBilling zelf draait. Er wordt geen factuur aangemaakt.
De bestaande providerregistratie kan later vanuit de geverifieerde okok-resource worden
gebruikt; alleen de geconfigureerde resource mag die adapter registreren. GetInvoice en
factuurbetaling zijn voor okok nog niet aangesloten.

**Volgende benodigde invoer: jouw okokBilling.zip**, zodat de werkelijke serverhandler,
identiteit van de uitgever, callback/export en opslagbevestiging gecontroleerd kunnen worden.

Volgens de ESX-configuratiedocumentatie kiest `Config.AddonAccount = true` bij okokBilling
voor addon_account_data in plaats van de okokBanking-tabellen. De standaardrekeningprefix
wordt met `Config.SocietyHasSocietyPrefix = true` gebruikt. Dat zegt nog niet of jouw versie
via de esx_addonaccount-resource werkt of alleen SQL uitvoert; dat moet in het bestand worden
gecontroleerd voordat we claimen dat de volledige factuurbetaling goed is aangesloten.
Deze instellingen worden nu niet automatisch in andere scripts gewijzigd.

## Controle

Na configureren de aangesloten scripts stoppen, bridge herstarten en scripts weer starten.
Voer ts_bridge_check uit. De meegeleverde mocktest controleert persoonlijke afschrijving,
te weinig saldo, een gestopte bank, addonaccount-societymutaties en een niet-aangesloten
billingprovider. Er is geen live okok-test uitgevoerd; de resources zijn niet aangeleverd.

## Bronnen

- [okokBanking exports](https://docs.okokscripts.io/scripts/okokbankingv2/exports)
- [okokBilling factuuraanvraag](https://docs.okokscripts.io/scripts/okokbilling/snippets)
- [okokBilling ESX-configuratie](https://docs.okokscripts.io/scripts/okokbilling/config-file)
