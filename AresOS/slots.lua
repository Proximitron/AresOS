-- Slots is controlling all connected elements
local self = {}
self.slots = nil
local buildIn = {control=true,library=true,system=true,unit=true,player=true,construct=true} -- Could be list, but quicker access times and easier to use indexed

function self:calcSlots()
    self.slots={}
    local target = unit or {}
    for key, value in pairs(target) do
        if buildIn[key] == nil then
            if type(key) == "string" and type(value) == "table" and type(value.export) == "table" then
                self.slots[key] = value
            end
        end
    end
    return self.slots
end
function self:getSlots()
    if self.slots == nil then
        self:calcSlots()
    end
    return self.slots
end

self.elementsIdList = nil
function self:calcElementList()
    if core == nil then return end
    self.elementsIdList = core.getElementIdList()
end
function self:getElementList()
    if self.elementsIdList == nil then
        self:calcElementList()
    end
    return self.elementsIdList
end


local unitTypeClass = {
	RemoteControlUnit = "remote", CockpitHovercraftUnit = "command", PVPSeatUnit = "gunner" , CockpitCommandmentUnit = "command", CockpitFighterUnit = "command"
}
-- First 5 letters of name
local slotSubClass = {
	Weapo = "weapon", Shiel = "shield", Radar = "radar" , CoreU = "core", Hover = "hover"
}
local slotClasses = {
    AntiGravityGeneratorUnit="antigrav",WarpDriveUnit="warpdrive",DataBankUnit="databases",
    ReceiverUnit = "receiver",EmitterUnit="emitter",ScreenUnit="screens",CombatDefense="transponder",
    AtmoFuelContainer = "atmofueltank",SpaceFuelContainer = "spacefueltank",RocketFuelContainer = "rocketfueltank",CounterUnit="counter",LaserDetector="laser",
    SpaceEngine = "engine", AtmosphericVerticalBoosterLargeGroup="booster",AtmosphericVerticalBoosterMediumGroup="booster",AtmosphericVerticalBoosterSmallGroup="booster"
}
local slotLists = {
    weapon=true,databases=true,screens=true,atmofueltank=true,spacefueltank=true,rocketfueltank=true,radar=true,engine=true,hover=true,booster=true
}
local eventRegister = {
  core = {"onStressChanged(stress)"},
  container = {"onContentUpdate()"},
  industry = {"onStarted(id,quantity)", "onCompleted(id,quantity)", "onStatusChanged(status)","onBankUpdate()"},
  radar = {"onEnter(id)","onLeave(id)","onIdentified(id)"},
  screens = {"mouseDown(x,y)", "mouseUp(x,y)", "onOutputChanged(output)"},
  laser = { "onHit()", "onLoss()" },
  receiver = {"onReceived(channel,message)"},
  shield = {"onToggled(active)","onAbsorbed(hitpoints,rawHitpoints)","onVentin(active,restoredHitpoints)","onDown()","onRestored()"},
  weapon = { "onReload(ammoId)", "onReloaded(ammoId)", "onMissed(targetId)", "onDestroyed(targetId)", "onElementDestroyed(targetId,itemId)", "onHit(targetId,damage)"},

  -- abstract
  --enterable =  { "enter(id)", "leave(id)"},
  --pressable =  { "pressed()", "released()"},

  -- built-in
  --control = { "onStop()", "onTimer(tag)"},
  --system = { "onActionStart(action)", "onActionStop(action)", "onActionLoop(action)", "onUpdate()", "onFlush()", "onInputText(text)"},
  --player = { "onParentChanged(oldId,newId)"},
  --construct = { "onDocked(id)", "onUndocked(id)", "onPlayerBoarded(id)", "onVRStationEntered(id)", "onConstructDocked(id)", "onPvPTimer(active)"}
}

local function getArgsForFilter (filterSignature)
    for k,v in ipairs(filterSignature) do
        local funName, funArgs = v:match("^([^(]+)%((.*)%)")
    
        local argNames = {}
        for argName in funArgs:gmatch("[^%s,]+") do table.insert(argNames, argName) end
        for _,g in ipairs(argNames) do
            print(string.format("* Slot name %q has options %q.", funName, g))
        end
        local mappedArgs = map(argNames, function () return "*" end)
        for _,g in ipairs(mappedArgs) do
            print(string.format("* Slot name %q has options %q.", funName, g))
        end
		
		
    end
end
function self:getClassType(class)
	local type
	if slotClasses[class] ~= nil then
		type = slotClasses[class]
	else
		local c = string.sub(class,0,5)
		if slotSubClass[c] ~= nil then
			type = slotSubClass[c]
		end
	end
	--if type == nil then
		--system.print("Unrecognized Type: "..class)
	--end
	return type
end
function self:register(env)
    _ENV = env

    for type, _ in pairs(slotLists) do
        _ENV[type] = {}
    end
    for _, slotElement in pairs(self:getSlots()) do
        local class = slotElement.getClass()
		
		local type = self:getClassType(class)
		--print("class is " .. class.. " type "..type)
		if type == nil then
			system.print("Unrecognized Type: "..class)
		else
			if slotLists[type] == nil then
                _ENV[type] = slotElement
            else
                table.insert(_ENV[type], slotElement)
            end
		end
    end

    function compare(a, b)
        if a ~= nil and a.getLocalId and b ~= nil and b.getLocalId then
            return a.getLocalId() < b.getLocalId()
        end
        return nil
    end
    for type, _ in pairs(slotLists) do
        if #_ENV[type] > 1 then table.sort(_ENV[type],compare) end
    end

    if #_ENV["databases"] > 0 then
        local bankraid = getPlugin("bankraid",true)
        if bankraid ~= nil then
            _ENV["database"] = bankraid:new(_ENV["databases"])
        else
            _ENV["database"] = _ENV["databases"][1]
        end
    end

	if _ENV["unitType"] == nil or _ENV["unitType"] == "" then
		if unitTypeClass[unit.getClass()] ~= nil then
			_ENV["unitType"] = unitTypeClass[unit.getClass()]
		else
			system.print("Unrecognized unitTypeClass: "..unit.getClass())
		end
	end
	
    register:addAction("antigravityStart", "antigravityStart", function()
        if antigrav ~= nil then
            antigrav.toggle()
        end
    end)

    register:addAction("systemOnUpdate", "frameCounter",
            function()
                if executeTotal == nil then executeTotal = 0 end
                if executeSet == nil then executeSet = 0 end

                executeTotal = executeTotal + 1
                executeSet = executeSet + 1
                local currTime = system.getArkTime()
                if (currTime - executeTime) > 1 then
                    executeLastFrames = executeSet
                    executeSet = 1
                    executeTime = currTime
                    local showFrames = false --export: Will show current frames in console only
                    if showFrames then
                        system.print("Frames: " .. executeLastFrames)
                    end
                end
            end
    )
    register:addAction("systemOnActionStart", "systemActionStartAlias",
            function(action, system)
                register:callAction(action .. "Start", system)
				register:startHotkeyPressed(action)
            end
    )
    register:addAction("systemOnActionStop", "systemActionStopAlias",
            function(action, system)
                register:callAction(action .. "Stop", system)
				register:endHotkeyPressed(action)
            end
    )
    register:addAction("systemOnActionLoop", "systemActionLoopAlias",
            function(action, system)
                register:callAction(action .. "Loop", system)
            end
    )
end
return self