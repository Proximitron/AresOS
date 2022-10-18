# AresOS
Läd/organisiert eine beliebige Menge an Funktionen/Plugins, welche dann auf allen Bauteilen
(Sitze/Programming boards/Notfalleinheit) lauffähig sind, welche Lua unterstützen.

## Benötigte Gegenstände
* Ein Bauteil welches Lua unterstützt

## Empfohlene Gegenstände
* Mindestens eine Datenbank


# Informationen für Entwickler

* Grundlegend ist ein Plugin eine Lua-Datei, dessen Namen auch der Name des Plugins ist, beispielsweise
```superplugin.lua```. Mischung aus Groß-/Kleinschreibung ist erlaubt, muss aber dann überall eingehalten werden.

## Vorteile
* Einfache Erweiterung/Erstellung von Plugins
* Modulare, stabile Basis zum gleichzeitigen Einsatz beliebig vieler Entwicklungen im selben Lua element
* Abfangen und Anzeigen von Fehlermeldungen, auch  eingebundenen Dateien ohne Abstürze hervorzurufen
* Schnelles hinzufügen von Events, Codes, selbst tiinefen Programmänderungen ohne das Ingame-Lua-Interface aufrufen zu müssen.
* Universelle Funktion für alle Komponenten welche Lua unterstützen
* Schnelle portierung bestehender Projekte und Komponenten durch geringe Mindestanforderungen an Plugins

## Mindestanforderung an ein Plugin

Es wird erwartet, dass ein Plugin beim Laden seiner Datei ein Objekt zurückgibt.
Dies ist zwar nicht technisch erforderlich, ist allerdings für die Funktion der meisten Plugins Voraussetzung.

### Empfohlene Grundstruktur aller Plugins
* Das Rückgabeobjekt enthält die öffentliche Eigenschaft "version", welche eine Zahl ist. In unserem Beispiel
deklariert als ```superplugin.version = 1.15```. Neue veröffentlichte Versionen des gleichen Plugins enthalten eine
Version mit einer höheren Zahl.
* Üblicherweise enthalten alle Plugins die Funktion ```register(env)``` im Rückabewert, beispielsweise deklariert als
```function superplugin:register(env)```. Sie wird einmalig beim Laden des Plugins aufgerufen und dient hauptsächlich
um Plugins die Möglichkeit zu geben sich für Events zu registrieren (SystemUpdate, UnitStop,...). Manche Plugins
(z.B. reine Daten/Listen) benötigten diese Funktion natürlich nicht.

### Funktionelle Plugins
* Rein funktionelle Plugins stellen keine besonderen Anforderungen. Sie verwenden hauptsächlich ```register(env)``` um
Funktionen/Events hinzuzufügen. Wenn das zurückgegebene Objekt diese Funktion enthält, wird sie beim ersten Laden
des Plugins ausgeführt."
* Jedes Plugin wird in einem eigenen, sicheren Container ausgeführt. Im Falle von Fehlermeldungen werden diese in der
Lua-Console angezeigt, alle anderen Plugins aber weiter ausgeführt.

### Visuelle Screen Elemente
Sollen Elemente im Hud, auf virtuellen Monitoren (im Hud) oder auf echten Monitoren (Spielelemente) angezeigt werden,
wird meistens das Plugin ```screener``` zur Darstellung genutzt. Das Plugin ruft jeden Frame alle view mit dem
Tag ```"screen"```, mit der Funktion ```screener:getViewList("screen")``` auf. Entsprechend werden
folgende Dinge erwartet:
* Visuelle Elemente (Views) registrieren sich mit dem Befehl ```screener:addView("SuperView", superplugin)```
* Das übergebene Objekt "superplugin" enthält mindestens die Eigenschaft ```superplugin.viewTags = {"screen"}``` und
die Funktion ```function superplugin:setScreen(screen)```
* Die Funktion "setScreen" gibt den kompletten HTML-Code zurück, welcher dargestellt werden soll
* Optional kann sich das Plugin außerdem noch auf einem oder mehreren Bildschirmen registrieren
``` local screener = getPlugin("screener") ``` and ```screener:registerDefaultScreen("mainScreenThird","SuperView")```

### Visuelle HUD Elemente
Der einzige Unterschied zwischen Screen und Hud Elementen ist, dass Screen Elemente in einem echten oder virtuellen
Bildschirm angezeigt werden. HUD-Elemente werden auf dem gesamten Spieler-Hud gerendert. Beispielsweise ein virtueller
Horizont. Der einzige Unterschied ist, dass die viewTags den Wert "hud" enthalten müssen. Beispielsweise mit der
Signatur ```superplugin.viewTags = {"hud"}```. ```superplugin.viewTags = {"screen","hud"}``` ist natürlich auch möglich.

### Verwendung anderer Plugins
* Standardmäßig kann die Instanz jedes Plugins mit der Funktion ```getPlugin("pluginname")``` von jedem anderen Plugin
abgefragt werden.
* Parameter 2 dieser Funktion kann die Fehlermeldung verhindern (übergabewert true), falls es damit
ein Problem gibt. z.B. ```getPlugin("pluginname",true)```. Im Falle eines Fehlers wird nil zurückgegeben.
* Parameter 3 dient der Sicherheit. Was auch immer als 3. Parameter übergeben wird, wird der optionalen Funktion
"valid" als erster Parameter übergeben. Beispielsweise ```getPlugin("pluginname",nil,{freigeben="ja!"})``` oder
```getPlugin("pluginname",nil,"meinGeheimerSchlüssel")```
Sollte diese Funktion existieren z.B. ```function superplugin:valid(key)``` und nicht true zurückgeben,
wird statt der Plugin-Instanz ```nil``` zurückgegeben.

### Zusätzliche Eigenschaften und Funktionen von Plugins
* Die optionale Funktion ```function superplugin:ready()``` kann zurückgeben, ob alle betriebsnotwendigen Plugins
bereits geladen wurden und es selbst bereit zum Einsatz ist.

### Externer Plugins
Im Order ```Dual Universe/Game/data/lua/autoconfig/custom/AresOS``` kann die Datei ```optionals.lua``` liegen, welche
zum Laden anderer Plugin-Dateien im gleichen Order verwendet werden kann. 

## Erstellung eines Releases (autoconfig oder copy/paste script)
In der Datei "convertToDU.sh" sind mehrere Beispiele zur Erstellung beliebiger Versionen. Sollte gewünscht
sein eigene Plugins direkt in die Autoconfig hinzuzufügen, kann der Name direkt beim Parameter ```--plugins```
angefügt werden.

### Voraussetzungen zur Erstellung
* Lua 5.3 installiert (http://www.lua.org/download.html)
(Der Windows PATH muss auf das Verzeichnis zeigen in welchem lua.exe zu finden ist. Die lua53.exe kann dazu umbenannt werden.)
* node installieren (https://nodejs.org/en/)
* "npm install -g luamin" (installiert luamin über npm)

### Erstellung einer Autoconfig
Erstellung von Autoconfigs wird in Zukunft wieder problemlos, in der aktuellen version allerdings nicht
empfehlenswert. Switch ist ```--output yaml```

### Schalter
Plugins die vom Benutzer ein- und/oder ausgeschalten werden können, können sich für diese Funktion (meist in
```register(env)```) registrieren.
```register:addSwitch("SuperSwitch", {activate=turnOnFunktion,deactivate=turnOffFunktion,isActive=isActiveFunktion})```
Im einfachsten Fall enthält die eigene Klasse die Funktionen ```activate```, ```deactivate``` und ```isActive```. Dann
reicht die Signatur ```register:addSwitch("SuperSwitch", superplugin)```

## Oft genutzte Standard Plugins
* register: Zentrale Aktionsregistrierung
* slots: Kategorisiert angeschlossene Geräte und weist sie Listen und standartisierten Namen zu. Beispiel: liste "atmosfueltank", slots globals "antigrav", "database" und "warpdrive"
* config: Performantes, simples schreiben von Konfigurations-Optionen. Für Konfigurationen dem direkten schreiben in die Datenbank vorzuziehen.
* Settings: Erweitert ```config``` für komplexe Konfigurationen. Erlaubt Gruppierung, Typisierung und Werte-Bereiche
* screener: Registrierung für visuelle Elemente (HUD und reale sowie virtuelle Bildschirme).
* CommandHandler: Registrieren und Ausführen von Befehlen im LUA-Fenster. Beliebige Funktion und Beschreibung wird hinterlegt und auch beim Aufruf von "/help" aufgelistet
* BaseFlight: Standard Flugprogramm (ähnliche NQs Basis-Flugscript)

