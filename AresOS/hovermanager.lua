local self = {}
self.version = 0.9
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
	local axisCommandManager = Nav.axisCommandManager
	function setGround(val)
		setGroundAlt = val
		axisCommandManager:setTargetGroundAltitude(val)
		config:set(groundAltitudeConfigVal, val, groundAltitudeMaxDefault)
	end
	setGround(setGroundAltMax)
	
	register:addAction("groundaltitudedownLoop", "groundaltitudedownLoopHovMng",  function() setGround(setGroundAlt-1.0) end)
	register:addAction("groundaltitudedownStart", "groundaltitudedownStartHovMng",  function() setGround(setGroundAlt-1.0) end)
	register:addAction("groundaltitudeupLoop", "groundaltitudeupLoopHovMng",  function() setGround(setGroundAlt+1.0) end)
	register:addAction("groundaltitudeupStart", "groundaltitudeupStartHovMng",  function() setGround(setGroundAlt+1.0) end)
	
	local autoLandBehaviour = false --export: Activates automatic landing code
	local autolandConfigVal = "hovermanagerAutoland"
	autoLandBehaviour = config:get(autolandConfigVal, autoLandBehaviour)
	
	if not autoLandBehaviour then return end
	
	local lastHighSet = 0 -- Time we last set the target alt to high value
    register:addAction("upLoop","hovermanagerUpLoop",
            function()
				
                if setGroundAlt ~= groundAltitudeMax and Nav then
                    setGroundAlt = groundAltitudeMax
                    Nav.axisCommandManager:setTargetGroundAltitude(setGroundAlt)
                end
                lastHighSet = system.getArkTime()
            end
    )

    register:addAction("systemOnUpdate","hovermanagerSpeedAndTimer",
            function()
				
                --[[local velocity = construct.getVelocity()
                local speed = vec3(velocity):len()
                local newAlt = setGroundAlt
                if speed > 14 then -- about 50 km/h
                    lastHighSet = system.getArkTime()
                    newAlt = groundAltitudeMax
                elseif unit.getThrottle and unit.getThrottle() < 1 and (system.getArkTime() - lastHighSet) > 6 then
                    newAlt = 1
                end

                if newAlt ~= setGroundAlt and Nav then
                    setGroundAlt = newAlt
                    Nav.axisCommandManager:setTargetGroundAltitude(setGroundAlt)
                end--]]
            end
    )
end
function self:unregister()
	print("unregister hovermanager")
	register:removeAction("upLoop","hovermanagerUpLoop")
	register:removeAction("systemOnUpdate","hovermanagerSpeedAndTimer")
end
return self