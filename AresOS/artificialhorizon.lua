-- Artificialhorizon is generating an artifical horizon into the hud
local self = {}
local artificialHorizonPreRender = ""
local artificialHorizonPreRenderN = ""
self.viewTags = {"hud"}

function self:requireRerender(screen)
	return true
end

function self:setScreen(screen)
    local invertedMod = false
    local currRender = artificialHorizonPreRender

    local velocity = construct.getVelocity()
    local speed = vec3(velocity):len()
    local worldV = vec3(core.getWorldVertical())
    local constrF = vec3(construct.getWorldOrientationForward())
    local constrR = vec3(construct.getWorldOrientationRight())
    --local constrV = vec3(core.getConstructWorldOrientationUp())

    local roll = 0
    local pitch = 0

    local relativePitch = 0
    local relativeYaw = 0

	if unit.getClosestPlanetInfluence() > 0 or (altitude > 0 and  altitude < 100000) then
		mode = 0
	else
		mode = 1
	end
	
    if speed > 5 then
        relativePitch = getRelativePitch(velocity)
        relativeYaw = getRelativeYaw(velocity)
        invertPitchYaw = false --export: Inverts pitch and yaw values for ships that had its core turned 180°
        if invertPitchYaw then
            relativePitch = relativePitch + 180
            relativeYaw = relativeYaw + 180
        end
    end
    if mode == 1 then
        pitch = relativePitch
        roll = relativeYaw
    else
        -- Pitch based on World coordinates
        pitch = 180 - getRoll(worldV, constrR, constrF)
        if pitch > 180 then
            pitch = -(360-pitch)
        end
        pitch = pitch * -1

        -- Roll based on World coordinates
        roll = getRoll(worldV, constrF, constrR) * -1
    end


    if pitch > 90 then
        pitch = pitch - 180
    elseif pitch < - 90 then
        pitch = pitch + 180
    end

    if roll > 90 or roll < -90 then
        invertedMod = true
        currRender = artificialHorizonPreRenderN
    end

    if roll > 90 then
        roll = roll - 180
    elseif roll < -90 then
        roll = roll + 180
    end
	--math.abs(roll)
    local content = [[
                        <svg id="artihorizon" height="70%" width="100%" viewBox="-640 -360 1280 720" style="display: block;margin: 0 auto;position: absolute;top: 22%; overflow: hidden">
                            <g transform="rotate(0 0,0) translate(0,0)">
                              <g transform="rotate(]] .. roll .. [[ 0,0) translate(0,]] .. math.floor(pitch * 8) .. [[)">
                                <rect width="200vw" height="100vh" x="-100vw" y="0" fill="transparent" />
                                <line x1="-45" y1="0" x2="-190" y2="0" class="sstroke" style="opacity:0.5;stroke-width:2;stroke-dasharray: 10, 10, 2, 10"/>
                                <line x1="45" y1="0" x2="190" y2="0" class="sstroke" style="opacity:0.5;stroke-width:2;stroke-dasharray: 10, 10, 2, 10" />
                                <g font-size=8>
                        ]]

    if currRender == ""  then
        for i = -72,72 do
            if i ~= 0 and (i%12==0) then
                local textY = i*10
                local textStr = utils.round(i*-1.250)

                local txtPolyName = "txtPoly"
                local textPosYMod = 5
                local textPosMod = 5
                if invertedMod then
                    textStr = textStr * -1

                    textPosYMod = -5
                    textPosMod = -5

                    if i <= 0 then
                        txtPolyName = "txtPolyN"
                        textPosYMod = 5
                        textPosMod = -1
                    end
                else
                    if i > 0 then
                        txtPolyName = "txtPolyN"
                        textPosYMod = -5
                        textPosMod = 1
                    end
                end

                currRender = currRender..[[
                                        <text x="59" y="]].. textY+textPosMod ..[[" class="atext chS">]].. textStr ..[[</text>
                                        <text x="-59" y="]].. textY+textPosMod ..[[" class="atext chE">]].. textStr ..[[</text>
                                        
                                        <polyline points="35 ]].. textY ..[[ 56 ]].. textY ..[[ 56 ]].. (textY+textPosYMod) ..[[" class="]].. txtPolyName ..[["/>		
                                        <polyline points="-35 ]].. textY ..[[ -56 ]].. textY ..[[ -56 ]].. (textY+textPosYMod) ..[[" class="]].. txtPolyName ..[["/>
                                    ]]
                --if textStr < pitch + 20 then
                --end
            end
        end
        if invertedMod then
            artificialHorizonPreRenderN = currRender
        else
            artificialHorizonPreRender = currRender
        end
    end
    content = content .. currRender

    content = content .. [[
                                </g>
                              </g>
                              <polyline points="-30,0 -7,0 0,7 7,0 30,0" fill="none" class="sstroke" stroke-width="2px" />
                          </g>
                        ]]
    if speed > 20 then
        content = content .. [[
                                <svg x="]]..utils.round((relativeYaw * -8)-14)..[[" y="]]..utils.round((relativePitch * 8)-13)..[[" viewBox="0 0 64 64" width="30px" height="30px">
                                  <line class="majorLine" x1="30" y1="30" x2="30" y2="5"/>
                                  <circle class="majorLine" cx="30" cy="30" r="25"/>
                                </svg>
                            ]]
    end

    content = content .. [[
                        </svg>
                        ]]
    return content
end
function self:register(env)
    _ENV = env
	
	-- This plugin is not made to load alone. It is part of hud. Let hud load it if required.
end
return self