local self = {}
self.version = 0.9
function self:register(env)
    _ENV = env
    local groundAltitudeMax = 30 --export: The highest we will set the hovers for landing or general hover height
    local setGroundAlt = 0 -- Current set ground altitude
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
                local velocity = construct.getVelocity()
                local speed = vec3(velocity):len()
                local newAlt = setGroundAlt
                if speed > 14 then -- about 50 km/h
                    lastHighSet = system.getArkTime()
                    newAlt = groundAltitudeMax
                elseif unit.getThrottle and unit.getThrottle() < 1 and (system.getArkTime() - lastHighSet) > 4 then
                    newAlt = 2
                end

                if newAlt ~= setGroundAlt and Nav then
                    setGroundAlt = newAlt
                    Nav.axisCommandManager:setTargetGroundAltitude(setGroundAlt)
                end
            end
    )
end
function self:unregister()
	print("unregister hovermanager")
	register:removeAction("upLoop","hovermanagerUpLoop")
	register:removeAction("systemOnUpdate","hovermanagerSpeedAndTimer")
end
return self