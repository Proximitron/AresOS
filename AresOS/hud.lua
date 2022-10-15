-- Hud is generating a flight hud (general purpose)
local self = {}
local staticRenderList = {}
local mode = 0
local Flight = nil
local Horizon = nil
function renderHudGeneralCss()
    if modeColors[mode] == nil then
        modeColors[mode] = 290
    end
    local currHsl = math.max(0, math.min(modeColors[mode],360))

    local sqLeftHsl = currHsl + 270.0
    if sqLeftHsl > 360 then
        sqLeftHsl = sqLeftHsl - 360
    end
    local sqTwoRight = currHsl + 180.0
    if sqTwoRight > 360 then
        sqTwoRight = sqTwoRight - 360
    end

    return [[
                            .lfill { fill:hsl(]].. currHsl ..[[, 93.6%, 56.9%)}
                            .sfill { fill:hsl(]].. currHsl ..[[, 100%, 50%) }
                            polygon { fill:hsl(]].. currHsl ..[[, 93.6%, 56.9%);opacity:0.8 }
                            .majorLine, .minorLine {stroke:hsl(]].. currHsl ..[[, 100%, 50%);opacity:0.8;stroke-width:3;fill-opacity:0;}
                            .minorLine {opacity:0.4}
                            .text {fill:hsl(]].. currHsl ..[[, 100%, 50%);font-weight:bold}
                            
                            .sstroke { stroke:hsl(]].. currHsl ..[[, 100%, 50%) }
                            
                            .pitch, .alt { stroke:hsl(]].. currHsl ..[[, 98.9%, 34.9%) }
                            .spitch, .epitch, .salt { fill:hsl(]].. currHsl ..[[, 98.9%, 34.9%) }
                            .pitch {opacity:0.4;stroke-width:3}
                            .spitch {text-anchor:start;font-size:12;font-weight:bold}
                            .epitch {text-anchor:end;font-size:12;font-weight:bold}
                            
                            .alt {opacity:0.4;stroke-width:3}
                            .salt {text-anchor:start;font-size:12;font-weight:bold}
                            
                            .roll {stroke:hsl(]].. currHsl ..[[, 98.9%, 34.9%);opacity:0.4;stroke-width:2}
                            .sroll {fill:hsl(]].. currHsl ..[[, 98.9%, 34.9%);text-anchor:middle;font-weight:bold}
                            
                            .throttle {fill:hsl(]].. currHsl ..[[, 98.9%, 34.9%);opacity:0.7}
                            .textWeak text {fill-opacity:0.5}
                            
                            .atext {fill:hsl(]].. currHsl ..[[, 98.9%, 34.9%);font-weight:bold}
                            .txtPoly, .txtPolyN { opacity:0.5;stroke-width:2;stroke:hsl(]].. currHsl ..[[, 98.9%, 34.9%);fill:none;stroke-linejoin:miter }
                            .txtPolyN { stroke-dasharray:6, 2, 6, 2, 10 }
                        ]]
end
register:addAction("staticCssStyle","hudGeneral",renderHudGeneralCss)

function staticRender()
    local currReturn = ""
    if not staticRenderList[mode] then
        local content = [[
                            <svg id="hudMain" height="100%" width="100%" viewBox="0 0 1920 1080">
                                <g class="majorLine">
                            ]]
        if showCenterCross then
            content = content.. [[
                                    <line x1="932" y1="540" x2="945" y2="540"/>
                                    <line x1="988" y1="540" x2="975" y2="540"/>
                                    <line x1="960" y1="512" x2="960" y2="525"/>
                                    <line x1="960" y1="568" x2="960" y2="555"/>
                                ]]
        end

        if not useLightStyle then
            content = content.. [[
                                    <g style="opacity:0.2">
                                        <line x1="823" y1="540" x2="783" y2="540"/>
                                        <line x1="1097" y1="540" x2="1137" y2="540"/>
                                ]]
            if mode == 0 then
                content = content.. [[
                                        <line x1="940" y1="694" x2="980" y2="694"/>
                                    ]]
            else
                content = content.. [[
                                        <line x1="960" y1="694" x2="960" y2="712"/>
                                    ]]
            end
            content = content.. [[
                                    </g>
                                </g>
                                <g class="text">
                                    <g font-size=15>
                                ]]
            if (mode == 0) then
                content = content .. [[
                                        <text x="960" y="33" text-anchor="middle" id="atmosOrSpace">Surface Mode</text>
                                    ]]
            else
                content = content .. [[
                                        <text x="960" y="33" text-anchor="middle" id="atmosOrSpace">Space Mode</text>
                                    ]]
            end
            content = content.. [[
                                    </g>
                                    <g font-size="10" class="textWeak">
                                ]]
        else
            content = content.. [[
                                </g>
                                <g class="text">
                                    <g font-size="10" class="textWeak">
                                ]]
        end
        staticRenderList[mode] = content
    end
    return staticRenderList[mode]
end

self.viewTags = {"hud"}
function self:setScreen(screen)
    local altitude = core.getAltitude()
    local velocity = construct.getVelocity()
    local speed = vec3(velocity):len()
    local worldV = vec3(core.getWorldVertical())
    local constrF = vec3(construct.getWorldOrientationForward())
    local constrR = vec3(construct.getWorldOrientationRight())
	
    local roll = 0
    local pitch = 0

    local rollOrYaw = "ROLL"
    local speedAsKmh = utils.round(speed * 3.6)
    local altOrSpeedVal = altitude
    local altOrSpeedTxt = "ALT"
    local speedOrBreak = "KM/H"

    local relativePitch = 0
    local relativeYaw = 0
    if speed > 5 then
        relativePitch = getRelativePitch(velocity)
        relativeYaw = getRelativeYaw(velocity)
        invertPitchYaw = false --export: Inverts pitch and yaw values for ships that had its core turned 180°
        if invertPitchYaw then
            relativePitch = relativePitch + 180
            relativeYaw = relativeYaw + 180
        end
    end
    --if true then return "" end
    if (mode == 1) then
        pitch = relativePitch
        roll = relativeYaw

        rollOrYaw = "YAW"
        altOrSpeedTxt = "KM/H"
        altOrSpeedVal = speedAsKmh

        speedOrBreak = "BREAK"

        --speedAsKmh = "-"
		if Flight ~= nil then
			speedAsKmh = getDistanceDisplayString(Flight:getBrakeTime(),2)
		end
        --speedAsKmh = register:callActionHtml("breakDistRender")

        --speedAsKmh = "0m - 00:00:00"

    else
        -- Pitch based on World coordinates
        pitch = 180 - getRoll(worldV, constrR, constrF)
        if pitch > 180 then
            pitch = -(360-pitch)
        end
        pitch = pitch * -1;

        -- Roll based on World coordinates
        roll = getRoll(worldV, constrF, constrR) * -1		
    end

    local content = staticRender(mode)
    content = content.. [[
                                    <text x="1135" y="395" text-anchor="end">]]..speedOrBreak..[[</text>
                        ]]

    local trottle = 0
    if unit.getThrottle then trottle = unit.getThrottle() end
    content = content.. [[
                            <text x="785" y="520" text-anchor="start">PITCH</text>
                            <text x="1135" y="520" text-anchor="end">]]..altOrSpeedTxt..[[</text>
                            <text x="960" y="678" text-anchor="middle">]]..rollOrYaw..[[</text>
                            <text x="790" y="660" text-anchor="start"></text>
							<text x="1135" y="660" text-anchor="end">THRL</text>
                        </g>
                        <g font-size="12">
                            <text x="785" y="534" text-anchor="start">]].. utils.round(pitch)..[[</text>
                            <text x="1135" y="534" text-anchor="end">]].. utils.round(altOrSpeedVal)..[[</text>
                            <text x="960" y="690" text-anchor="middle">]]..utils.round(roll)..[[</text>
                            <text x="790" y="672" text-anchor="start">]]..""..[[</text>
							<text x="1135" y="672" text-anchor="end">]]..utils.round(trottle)..[[%</text>
                        ]]

    content = content.. [[
                                    <text x="1135" y="409" text-anchor="end">]]..speedAsKmh..[[</text>
                        ]]

    content = content.. [[
                                    </g>                            
                                </g>
                        ]]

    if not useLightStyle then
        if mode == 1 then
            pitchC = utils.round(pitch)

            for i = pitchC-25,pitchC+25 do
                if (i%10==0) then
                    num = i

                    if num < -179 then
                        num = num + 360
                    end
                    if num > 180 then
                        num = num - 360
                    end

                    content = content..[[<g transform="translate(0 ]]..(-i*5 + pitch*5)..[[)">
                                            <text x="745" y="540" class="epitch" style="font-size:12">]]..num..[[</text></g>]]
                end

                len = 5
                if (i%10==0) then
                    len = 30
                elseif (i%5==0) then
                    len = 15
                end

                content = content..[[
                                    <g transform="translate(0 ]]..(-i*5 + pitch*5)..[[)">
                                        <line x1="]]..(780-len)..[[" y1="540" x2="780" y2="540" class="pitch"/></g>]]

            end
        end

        local altOrSpeed = altitude
        if mode == 1 then
            altOrSpeed = speed * 3.6
        end
        altOrSpeedMulti = 25
        if altOrSpeed < 100 then
            altOrSpeedMulti = 5
        end
        if altOrSpeed > 4000 then
            altOrSpeedMulti = 100
        end
        alt = utils.round(altOrSpeed / altOrSpeedMulti)
        if lastAlt ~= alt then
            lastAlt = alt
            lastAltDraw = ""
            for i = alt-25,alt+25 do
                if (i%10==0) then
                    num = i

                    lastAltDraw = lastAltDraw..[[<g transform="translate(0 ]]..(-i*5 + alt*5)..[[)">
                                            <text x="1175" y="543" class="salt" style="font-size:12">]]..(num * altOrSpeedMulti)..[[</text></g>]]
                end

                len = 5
                if (i%10==0) then
                    len = 30
                elseif (i%5==0) then
                    len = 15
                end

                lastAltDraw = lastAltDraw..[[
                                    <g transform="translate(0 ]]..(-i*5 + alt*5)..[[)">
                                        <line x1="]]..(1140+len)..[[" y1="540" x2="1140" y2="540" class="alt"/></g>]]
            end
        end
        content = content .. lastAltDraw

        if mode == 1 then
            rollC = utils.round(relativeYaw)
            for i = rollC-35,rollC+35 do
                if (i%10==0) then
                    num = math.abs(i)
                    if (num > 180) then
                        num = 180 + (180-num)
                    end
                    content = content..[[<g transform="rotate(]]..(i - relativeYaw)..[[,960,450)">
                                        <text x="960" y="760" class="sroll" style="font-size:12">]]..num..[[</text></g>]]
                end

                len = 5
                if (i%10==0) then
                    len = 15
                elseif (i%5==0) then
                    len = 10
                end
                if len > 5 then
                    content = content..[[<g transform="rotate(]]..(i - relativeYaw)..[[,960,450)">
                                        <line x1="960" y1="715" x2="960" y2="]]..(715+len)..[[" class="roll"/></g>]]
                end
            end
        end
    end

    content = content..[[
                            </svg>
                        ]]

    if mode == 0 then
        --content = content .. register:callActionHtml("svgSurface")
    end
	
	if mode == 0 then
		content = content .. Horizon:setScreen(screen)
	end
    --content = content .. [[<div style="position: absolute;left:20px;top:100px">]]..TODO.."</div>"

    if system.getArkTime() - bootTime < 2 then
        content = content .. [[<style>body { opacity: ]].. ((system.getArkTime() - bootTime) / 1.5)  ..[[ }</style>]]
    end

    return content
end
function getDistanceDisplayString(distance, places) -- Turn a distance into a string to a number of places
    local su = distance > 100000
    if places == nil then places = 1 end
    if su then
          -- Convert to SU
        return round(distance / 1000 / 200, places).." SU"
    elseif distance < 1000 then
        return round(distance, places).." M"
    else
        -- Convert to KM
        return round(distance / 1000, places).." KM"
    end
end
function self:register(env)
    _ENV = env

	Flight = getPlugin("BaseFlight",true)
	Horizon = getPlugin("artificialhorizon",true)
	local screener = getPlugin("screener")
	screener:registerDefaultScreen("mainScreenThird","Hud")
	screener:addView("Hud",self)
	
	
end
return self