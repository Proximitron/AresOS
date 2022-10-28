local self = {}
function self:valid(key)
    return unitType == "remote" or unitType == "command"
end
self.version = 0.9
self.loadPrio = 1000
local u = unit
local s = system
local FlightModes = {}
local FlightMode = ""
function self:register(env)
	_ENV = env
	
	if not self:valid() then return end
	
	if Nav == nil then
		Nav = Navigator.new(system, core, unit)
	end
    if Nav.control.isRemoteControlled() == 1 then
        player.freeze(1)
    end
	
    local pitchInput = 0
    local rollInput = 0
    local yawInput = 0
    local brakeInput = 0
	local gearExtended = unit.isAnyLandingGearDeployed()
	
	local axisCommandManager = Nav.axisCommandManager
	axisCommandManager:setTargetGroundAltitude(1)
    --if vec3(construct.getWorldVelocity()):len() < 10 then brakeInput = 1 end

    register:addAction("systemOnUpdate", "NavUpdate",  function() Nav:update() end)

    register:addAction("forwardStart", "forwardStartFlight",  function() pitchInput =  -1 end)
    register:addAction("backwardStart", "backwardStartFlight",  function() pitchInput =  1 end)
    register:addAction("yawleftStart", "yawleftStartFlight",  function() yawInput =  1 end)
    register:addAction("yawrightStart", "yawrightStartFlight",  function() yawInput =  -1 end)
    register:addAction("strafeleftStart", "strafeleftStartFlight",  function() axisCommandManager:updateCommandFromActionStart(axisCommandId.lateral, -1.0) end)
    register:addAction("straferightStart", "straferightStartFlight",  function() axisCommandManager:updateCommandFromActionStart(axisCommandId.lateral, 1.0) end)
    register:addAction("leftStart", "leftStartFlight",  function() rollInput =  -1 end)
    register:addAction("rightStart", "rightStartFlight",  function() rollInput =  1 end)
    register:addAction("upStart", "upStartFlight",  function() axisCommandManager:updateCommandFromActionStart(axisCommandId.vertical, 1.0) end)
    register:addAction("downStart", "downStartFlight",  function() axisCommandManager:updateCommandFromActionStart(axisCommandId.vertical, -1.0) end)
	
	register:addAction("groundaltitudedownLoop", "groundaltitudedownLoopFlight",  function() axisCommandManager:updateTargetGroundAltitudeFromActionLoop(-1.0) end)
	register:addAction("groundaltitudedownStart", "groundaltitudedownStartFlight",  function() axisCommandManager:updateTargetGroundAltitudeFromActionStart(-1.0) end)
	register:addAction("groundaltitudeupLoop", "groundaltitudeupLoopFlight",  function() axisCommandManager:updateTargetGroundAltitudeFromActionLoop(1.0) end)
	register:addAction("groundaltitudeupStart", "groundaltitudeupStartFlight",  function() axisCommandManager:updateTargetGroundAltitudeFromActionStart(1.0) end)

    --register:addAction("gearStart", "gearStartFlight",  function() if brakeInput == 1 then brakeInput = 0 else brakeInput = 1 end end)
	register:addAction("gearStart", "gearStartFlight",  function()
		gearExtended = not gearExtended
		if gearExtended then unit.deployLandingGears() else unit.retractLandingGears() end
	end)
	register:addAction("lightStart", "lightStartFlight",  function()
		if unit.isAnyHeadlightSwitchedOn() == 1 then unit.switchOffHeadlights() else unit.switchOnHeadlights() end
	end)

	register:addAction("antigravityStart", "antigravityStartFlight",  function() if antigrav ~= nil then antigrav.toggle() end end)
    register:addAction("brakeStart", "brakeStartFlight",  function() brakeInput = 1 end)
    register:addAction("stopenginesStart", "stopenginesStartFlight",  function() axisCommandManager:resetCommand(axisCommandId.longitudinal) end)
    register:addAction("speedupStart", "speedupStartFlight",  function() axisCommandManager:updateCommandFromActionStart(axisCommandId.longitudinal, 5.0) end)
    register:addAction("speeddownStart", "speeddownStartFlight",  function() axisCommandManager:updateCommandFromActionStart(axisCommandId.longitudinal, -5.0) end)

    register:addAction("speedupLoop", "speedupLoopFlight", function() axisCommandManager:updateCommandFromActionLoop(axisCommandId.longitudinal, 1.0) end)
    register:addAction("speeddownLoop", "speeddownLoopFlight", function() axisCommandManager:updateCommandFromActionLoop(axisCommandId.longitudinal, -1.0) end)
    
    register:addAction("forwardStop", "forwardStopFlight", function() pitchInput = 0 end)
    register:addAction("backwardStop", "backwardStopFlight", function() pitchInput = 0 end)
    register:addAction("yawleftStop", "yawleftStopFlight", function() yawInput = 0 end)
    register:addAction("yawrightStop", "yawrightStopFlight", function() yawInput = 0 end)
    register:addAction("strafeleftStop", "strafeleftStopFlight", function() axisCommandManager:updateCommandFromActionStop(axisCommandId.lateral, 1.0) end)
    register:addAction("straferightStop", "straferightStopFlight", function() axisCommandManager:updateCommandFromActionStop(axisCommandId.lateral, -1.0) end)
    register:addAction("leftStop", "leftStopFlight", function() rollInput = 0 end)
    register:addAction("rightStop", "rightStopFlight", function() rollInput = 0 end)
    register:addAction("upStop", "upStopFlight", function() axisCommandManager:updateCommandFromActionStop(axisCommandId.vertical, -1.0) end)
    register:addAction("downStop", "downStopFlight", function() axisCommandManager:updateCommandFromActionStop(axisCommandId.vertical, 1.0) end)
    register:addAction("brakeStop", "brakeStopFlight", function() brakeInput = 0 end)
    local function NormalFlight()
		local s = system
		local ct = construct
        local pitchSpeedFactor = 1.6
        local yawSpeedFactor =  2
        local rollSpeedFactor = 3
        local brakeSpeedFactor = 30
        local brakeFlatFactor = 5
        local torqueFactor = 3
        self.brake = brakeInput

        -- final inputs
        local finalPitchInput = pitchInput + s.getControlDeviceForwardInput()
        local finalRollInput = rollInput + s.getControlDeviceYawInput()
        local finalYawInput = yawInput - s.getControlDeviceLeftRightInput()
        local finalBrakeInput = brakeInput

        -- Axis
        local worldVertical = vec3(core.getWorldVertical()) -- along gravity
        local constructUp = vec3(ct.getWorldOrientationUp())
        local constructForward = vec3(ct.getWorldOrientationForward())
        local constructRight = vec3(ct.getWorldOrientationRight())
        local constructVelocity = vec3(ct.getWorldVelocity())
        local constructVelocityDir = vec3(ct.getWorldVelocity()):normalize()
        local currentRollDeg = getRoll(worldVertical, constructForward, constructRight)
        local currentRollDegAbs = math.abs(currentRollDeg)
        local currentRollDegSign = utils.sign(currentRollDeg)

        -- Rotation
        local constructAngularVelocity = vec3(ct.getWorldAngularVelocity())
        local targetAngularVelocity = finalPitchInput * pitchSpeedFactor * constructRight
                                        + finalRollInput * rollSpeedFactor * constructForward
                                        + finalYawInput * yawSpeedFactor * constructUp

        -- Engine commands
        local keepCollinearity = 1 -- for easier reading
        local dontKeepCollinearity = 0 -- for easier reading
        local tolerancePercentToSkipOtherPriorities = 1 -- if we are within this tolerance (in%), we don't go to the next priorities

        -- Rotation
        local angularAcceleration = torqueFactor * (targetAngularVelocity - constructAngularVelocity)
        local airAcceleration = vec3(ct.getWorldAirFrictionAngularAcceleration())
        angularAcceleration = angularAcceleration - airAcceleration -- Try to compensate air friction
        Nav:setEngineTorqueCommand('torque', angularAcceleration, keepCollinearity, 'airfoil', '', '', tolerancePercentToSkipOtherPriorities)

        -- Brakes
        local brakeAcceleration = -finalBrakeInput * (brakeSpeedFactor * constructVelocity + brakeFlatFactor * constructVelocityDir)
        Nav:setEngineForceCommand('brake', brakeAcceleration)

        -- AutoNavigation regroups all the axis command by 'TargetSpeed'
        local autoNavigationEngineTags = ''
        local autoNavigationAcceleration = vec3()
        local autoNavigationUseBrake = false

        -- Longitudinal Translation
        local longitudinalEngineTags = 'thrust analog longitudinal'
        local longitudinalCommandType = axisCommandManager:getAxisCommandType(axisCommandId.longitudinal)
        if (longitudinalCommandType == axisCommandType.byThrottle) then
            local longitudinalAcceleration = axisCommandManager:composeAxisAccelerationFromThrottle(longitudinalEngineTags,axisCommandId.longitudinal)
            Nav:setEngineForceCommand(longitudinalEngineTags, longitudinalAcceleration, keepCollinearity)
        elseif  (longitudinalCommandType == axisCommandType.byTargetSpeed) then
            local longitudinalAcceleration = axisCommandManager:composeAxisAccelerationFromTargetSpeed(axisCommandId.longitudinal)
            autoNavigationEngineTags = autoNavigationEngineTags .. ' , ' .. longitudinalEngineTags
            autoNavigationAcceleration = autoNavigationAcceleration + longitudinalAcceleration
            if (axisCommandManager:getTargetSpeed(axisCommandId.longitudinal) == 0 or -- we want to stop
                axisCommandManager:getCurrentToTargetDeltaSpeed(axisCommandId.longitudinal) < - axisCommandManager:getTargetSpeedCurrentStep(axisCommandId.longitudinal) * 0.5) -- if the longitudinal velocity would need some braking
            then
                autoNavigationUseBrake = true
            end

        end

        -- Lateral Translation
        local lateralStrafeEngineTags = 'thrust analog lateral'
        local lateralCommandType = axisCommandManager:getAxisCommandType(axisCommandId.lateral)
        if (lateralCommandType == axisCommandType.byThrottle) then
            local lateralStrafeAcceleration =  axisCommandManager:composeAxisAccelerationFromThrottle(lateralStrafeEngineTags,axisCommandId.lateral)
            Nav:setEngineForceCommand(lateralStrafeEngineTags, lateralStrafeAcceleration, keepCollinearity)
        elseif  (lateralCommandType == axisCommandType.byTargetSpeed) then
            local lateralAcceleration = axisCommandManager:composeAxisAccelerationFromTargetSpeed(axisCommandId.lateral)
            autoNavigationEngineTags = autoNavigationEngineTags .. ' , ' .. lateralStrafeEngineTags
            autoNavigationAcceleration = autoNavigationAcceleration + lateralAcceleration
        end

        -- Vertical Translation
        local verticalStrafeEngineTags = 'thrust analog vertical'
        local verticalCommandType = axisCommandManager:getAxisCommandType(axisCommandId.vertical)
        if (verticalCommandType == axisCommandType.byThrottle) then
            local verticalStrafeAcceleration = axisCommandManager:composeAxisAccelerationFromThrottle(verticalStrafeEngineTags,axisCommandId.vertical)
            Nav:setEngineForceCommand(verticalStrafeEngineTags, verticalStrafeAcceleration, keepCollinearity, 'airfoil', 'ground', '', tolerancePercentToSkipOtherPriorities)
        elseif  (verticalCommandType == axisCommandType.byTargetSpeed) then
            local verticalAcceleration = axisCommandManager:composeAxisAccelerationFromTargetSpeed(axisCommandId.vertical)
            autoNavigationEngineTags = autoNavigationEngineTags .. ' , ' .. verticalStrafeEngineTags
            autoNavigationAcceleration = autoNavigationAcceleration + verticalAcceleration
        end

        -- Auto Navigation (Cruise Control)
        if (autoNavigationAcceleration:len() > constants.epsilon) then
            if (brakeInput ~= 0 or autoNavigationUseBrake or math.abs(constructVelocityDir:dot(constructForward)) < 0.95)  -- if the velocity is not properly aligned with the forward
            then
                autoNavigationEngineTags = autoNavigationEngineTags .. ', brake'
            end
            Nav:setEngineForceCommand(autoNavigationEngineTags, autoNavigationAcceleration, dontKeepCollinearity, '', '', '', tolerancePercentToSkipOtherPriorities)
        end
    end
	self:addFlightMode("Base",NormalFlight)
	self:setFlightMode("Base")
    register:addAction("systemOnFlush","FlightScript",function()
		local mode = self:getCurrentFlightMode()
		mode()
	end)
end
function self:getMass()
    local c = construct
    local m = c.getMass()
    for k,v in pairs(c.getDockedConstructs()) do
        m = m + c.getDockedConstructMass(m)
    end
    for k,v in pairs(c.getPlayersOnBoard()) do
        m = m + c.getBoardedPlayerMass(m)
    end
    return m
end
function self:getBrakeTime()
    local c = 75000 / 3.6
	local ct = construct
    local spaceBrakeForce = ct.getMaxBrake()
    if spaceBrakeForce == nil then return 0,0 end
	local speed = vec3(ct.getWorldVelocity()):len()
	if speed < 1 then return 0,0 end
    local v = math.min(speed, ct.getMaxSpeed())
    local m = self:getMass()
    local brakeTime = m * c / spaceBrakeForce * math.asin(v / c)
    local brakeDistance = m * c ^ 2 / spaceBrakeForce * (1 - math.sqrt(1 - v ^ 2 / c ^ 2)) -- meter
    return brakeDistance, brakeTime
end
function self:addFlightMode(name,func)
    FlightModes[name] = func
end
function self:setFlightMode(name)
	FlightMode = name
end
function self:getFlightMode(name)
    return FlightModes[name]
end
function self:getCurrentFlightMode()
	return self:getFlightMode(FlightMode)
end
return self