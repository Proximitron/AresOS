# Typical dev-version to work on plugins. You can change the file "dev.lua" to integrate the plugins you are currently working on
#lua wrap.lua start.lua artificiaOS_dev.json --slots core:type=core receiver:type=receiver

# This is a minimal core that allows normal flying with the construct. Without this, someone without the plugin files
# will not be able to even fly the construct this is installed on!
#lua wrap.lua start.lua artificiaOS_0_38_min.json --slots core:type=core --plugins register slots BaseFlight --minify

# Bare-bone function and interface
#lua wrap.lua start.lua artificiaOS_0_38_bareBone.json --slots core:type=core --plugins register slots config BaseFlight screener hud artificialhorizon --minify

# Release including all current modules
#lua wrap.lua start.lua artificiaOS_0_38_myOwnRelease.json --slots core:type=core --plugins register slots BaseFlight hud artificialhorizon screener config repairmonitor itemlist whispernet bankraid ec25519 keychain morus base64  --minify

# AUTOCONFIG may not support all featurs. Testing required.
#lua wrap.lua start.lua artificiaOS_0_38_min.conf --output yaml --name "AresOS 0.4 minimal core" --slots core:type=core --plugins register slots BaseFlight --minify
# Bare-bone function and interface
#lua wrap.lua start.lua artificiaOS_0_38_bareBone.conf --output yaml --name "AresOS 0.4 BareBone" --slots core:type=core --plugins register slots config CommandHandler BaseFlight hud artificialhorizon screener --minify
#lua wrap.lua start.lua artificiaOS_dev.conf --output yaml --name "AresOS 0.4 Entwicklungsmodus" --slots core:type=core receiver:type=receiver --dev

lua wrap.lua start.lua artificiaOS_dev.json --slots core:type=core --dev

lua wrap.lua start.lua Ares_GunnerV0.9.conf --output yaml --slots databank:type=databank transponder:type=transponder weapon:type=weapon,select=manual radar:type=radar,select=manual shieldGenerator:type=shieldGenerator core:type=core --plugins register slots screener CommandHandler Settings RadarWidget ShieldReconfigure WeaponWidget GunnerHUD shortName config WidgetCreator --name Ares_GunnerV0.9 --minify

lua wrap.lua start.lua Ares_RemoteV0.9.conf --output yaml --slots databank:type=databank warpdrive:type=warpdrive core:type=core engine:type=engine,select=manual --plugins register slots config Settings CommandHandler AR BaseFlight FlightHud Pipes screener --name Ares_RemoteV0.9 --minify


lua wrap.lua start.lua Ares_GunnerV0.9.conf --output yaml --slots databank:type=databank transponder:type=transponder weapon:type=weapon,select=manual radar:type=radar,select=manual shieldGenerator:type=shieldGenerator core:type=core --name Ares_GunnerV0.9 --dev

lua wrap.lua start.lua Ares_RemoteV0.9.conf --output yaml --slots databank:type=databank warpdrive:type=warpdrive core:type=core engine:type=engine,select=manual --name Ares_RemoteV0.9 --dev
