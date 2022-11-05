local self = {}
self.version = 0.9

function self:AboveGroundLevel()
	local lastGround = 0
	
	local function compileDistance(gdist)
		if gdist == -1 then return -1
		if gdist > -1 and gdist < 0.01 then gdist = lastGround else lastGround = gdist end
		return gdist
	end
	local function detectGround()
		local groundDistances = {}
		
		if booster ~= nil then
			local distance = booster.getDistance()
			if distance ~= -1 then table.insert(groundDistances,  compileDistance(distance))
		end
		if hover ~= nil then
			local distance = hover.getDistance()
			if distance ~= -1 then table.insert(groundDistances,  compileDistance(distance))
		end
		if telemeter then 
			local distance = telemeter.raycast().distance
			if distance == 0 then distance = -1 end
			if distance ~= -1 then table.insert(groundDistances,  compileDistance(distance))
		end
		
		local minDist = -1
		for _,currCompare in pairs(groundDistances) do
			if currCompare < minDist then minDist = currCompare end
		end
		
		if minDist == -1 then return lastGround end
			
		return minDist
	end
	return detectGround()
end
function self:register(env)
    _ENV = env

	-- cleanup BaseFlight actions for groundaltitude
	local flight = getPlugin("BaseFlight",true)
	if flight ~= nil then
		register:removeAction("groundaltitudedownLoop", "groundaltitudedownLoopFlight")
		register:removeAction("groundaltitudedownStart", "groundaltitudedownStartFlight")
		register:removeAction("groundaltitudeupLoop", "groundaltitudeupLoopFlight")
		register:removeAction("groundaltitudeupStart", "groundaltitudeupStartFlight")
	end
	
	-- altitude from config
	local groundAltitudeMaxDefault = 1 --export: The highest we will set the hovers for landing or general hover height
	local config = getPlugin("config")
	local groundAltitudeConfigVal = "hovermanagerGroundAltitude"
    local setGroundAltMax = config:get(groundAltitudeConfigVal, groundAltitudeMaxDefault)
	local setGroundAlt = 0
	local flyModHoverHeight = 30
	local axisCommandManager = Nav.axisCommandManager

	function changeGround(val,configAdjust)
		if configAdjust ~= nil then
			local conf = config:get(groundAltitudeConfigVal, groundAltitudeMaxDefault)
			setGroundAltMax = conf + val
			setGroundAltMax = math.max(0,math.min(setGroundAltMax,30),setGroundAltMax)
			config:set(groundAltitudeConfigVal, setGroundAltMax, groundAltitudeMaxDefault)
			setGroundAlt = setGroundAltMax
		else
			setGroundAlt = math.max(0,math.min(setGroundAlt+val,30),setGroundAlt+val)
		end
		
		axisCommandManager:setTargetGroundAltitude(setGroundAlt)
	end
	changeGround(setGroundAltMax*-1)
	
	register:addAction("groundaltitudedownLoop", "groundaltitudedownLoopHovMng",  function() changeGround(-1.0,true) end)
	register:addAction("groundaltitudedownStart", "groundaltitudedownStartHovMng",  function() changeGround(-1.0,true) end)
	register:addAction("groundaltitudeupLoop", "groundaltitudeupLoopHovMng",  function() changeGround(1.0,true) end)
	register:addAction("groundaltitudeupStart", "groundaltitudeupStartHovMng",  function() changeGround(1.0,true) end)
	
	local autoLandBehaviour = true --export: Activates automatic landing code
	local autolandConfigVal = "hovermanagerAutoland"
	autoLandBehaviour = config:get(autolandConfigVal, autoLandBehaviour)
	
	if not autoLandBehaviour then return end
	
	local lastHighSet = 0 -- Time we last set the target alt to high value
    register:addAction("upLoop","hovermanagerUpLoop",
            function()
                if setGroundAlt < flyModHoverHeight and Nav then
					changeGround(flyModHoverHeight-setGroundAlt)
                end
                lastHighSet = system.getArkTime()
            end
    )

    register:addAction("systemOnUpdate","hovermanagerSpeedAndTimer",
            function()
				
                local velocity = construct.getVelocity()
                local speed = vec3(velocity):len()
                local newAlt = setGroundAlt
                if speed > 14 then -- about 50 km/h
                    lastHighSet = system.getArkTime()
                    newAlt = flyModHoverHeight
                end
				
				if unit.getThrottle() > 1 then
					lastHighSet = system.getArkTime()
				else
					if (system.getArkTime() - lastHighSet) > 6 then
						newAlt = config:get(groundAltitudeConfigVal, groundAltitudeMaxDefault)
					end
				end

                if newAlt ~= setGroundAlt and Nav then
					changeGround(newAlt-setGroundAlt)
                end
            end
    )
end
function self:deregister()
	print("unregister hovermanager")
	register:removeAction("upLoop","hovermanagerUpLoop")
	register:removeAction("systemOnUpdate","hovermanagerSpeedAndTimer")
	register:removeAction("groundaltitudedownLoop", "groundaltitudedownLoopHovMng")
	register:removeAction("groundaltitudedownStart", "groundaltitudedownStartHovMng")
	register:removeAction("groundaltitudeupLoop", "groundaltitudeupLoopHovMng")
	register:removeAction("groundaltitudeupStart", "groundaltitudeupStartHovMng")
	local axisCommandManager = Nav.axisCommandManager
	register:addAction("groundaltitudedownLoop", "groundaltitudedownLoopFlight",  function() axisCommandManager:updateTargetGroundAltitudeFromActionLoop(-1.0) end)
	register:addAction("groundaltitudedownStart", "groundaltitudedownStartFlight",  function() axisCommandManager:updateTargetGroundAltitudeFromActionStart(-1.0) end)
	register:addAction("groundaltitudeupLoop", "groundaltitudeupLoopFlight",  function() axisCommandManager:updateTargetGroundAltitudeFromActionLoop(1.0) end)
	register:addAction("groundaltitudeupStart", "groundaltitudeupStartFlight",  function() axisCommandManager:updateTargetGroundAltitudeFromActionStart(1.0) end)
end
return self