-- Screener manages virtual screens on hud and real screen elements that are connected

-- Fenster-Registrierung
-- register:addScreen("ScreenName",offsetx,offsety,width,height,perspective) Position, Größe, Ansicht ("third"/"first"/"screen")

-- View-Registrierung
-- register:addView("Horizon",self)

--function self:setScreen(screen)

--optional:
--function self:onMouseDown(x,y,button)
--function self:onMouseUp(x,y,button)
--function self:requireRerender(screen)

--register
--register:addButton(viewName,buttonName,x,y,width,height,func)

-- local s = getPlugin("screener");
-- s:addScreen(..

local self = {}
local setupMode = false
self.loadPrio = 10
local config = getPlugin("config")
local screenDefault = {
    menuitmwidth= 1 / 8,
    menuitmheight= 1 / 16,
    offsetx=0,
    offsety=0,
    width=1 * (1/3),
    height=1 * (1/3),
    tag = "screen",
    totalWidth = system.getScreenHeight(), -- 1920,
    totalHeight = system.getScreenWidth(), --1080,
	perspective = "third",
	parent = "mainScreenThird"
}
local screenDef = {}

function self:hotkeyState(hotkey)
    if self.pressedRegister[hotkey] == 1 then
        return 1
    end
    return 0
end
function self:startHotkeyPressed(hotkey)
    self.pressedRegister[hotkey] = 1
end
function self:endHotkeyPressed(hotkey)
    self.pressedRegister[hotkey] = nil
end

function self:addButton(viewName,buttonName,x,y,width,height,func)

end
function self:addScreen(screenName,screenData)
	curr = {}
    for key, val in pairs(screenDefault) do
		if screenData[key] == nil then
			curr[key] = val
		else
			curr[key] = screenData[key]
		end
    end
	curr["name"] = screenName
	screenDef[screenName] = curr;
end
function self:getPerspectiveList()
	return {"first","third"}
end
function self:getPerspective()
	local persp = system.getCameraMode()
	if persp == 1 then
		return "first"
	else
		return "third"
	end
end

local viewRegister = {}
function self:addView(name, viewObj)
    assert(type(name) == "string", "name isn't a string, type was " .. type(name))
    assert(type(viewObj) == "table", name .. ": viewObj isn't a table, type was " .. type(viewObj))

    viewRegister[name] = viewObj

    register:callAction("registerAddView", name)
end
function self:removeView(name)
    if viewRegister[name] == nil then
        return false
    end
    viewRegister[name] = nil

    register:callAction("registerRemoveView", name)
end
function self:getViewList(viewTag)
    local keyset = {}

    for k, v in pairs(viewRegister) do
        if v == nil or v.viewTags == nil then
            system.print("No view tags: '" .. (k))
        else
            for _, tag in pairs(v.viewTags) do
                if viewTag == nil or tag == viewTag then
                    table.insert(keyset, k)
                end
            end
        end
    end
    table.sort(keyset)
    return keyset
end
function self:renderView(name, screen, ...)
    if viewRegister[name] == nil then
        system.print("Render of view '" .. (name or "???") .. "' failed, because it there is no such view registered!","")
    end
    local viewObj = viewRegister[name]

    if viewObj.setScreen ~= nil then	
        local status, res = pcall(viewObj.setScreen, viewObj, screen, ...)

        if status then
            return res
        else
            system.print(name .." in setScreen:",res)
            return nil
        end
    else
		system.print(name .." render has no function 'setScreen'")
    end
end
function self:renderViewRequireRerender(name, screen, ...)
    if self.viewRegister[name] == nil then
        system.print("Rerender request of view '" .. (name or "???") .. "' failed, because it there is no such view registered!","")
    end
    local viewObj = viewRegister[name]

    if viewObj.requireRerender ~= nil then
        local status, res = pcall(viewObj.requireRerender, viewObj, screen, ...)

        if status then
            return res
        else
            system.print(name .." in renderViewRequireRerender:",res)
            return nil
        end
    end

    return true
end
function self:actionToHtml(action, ...)
    local list, html = register:callAction(action, ...), ""
    for _, val in pairs(list) do
        if val then
            html = html .. val
        end
    end
    return html
end


--local screenObjCache = {}
function screenObj(name)
    --if screenObjCache[name] ~= nil then return screenObjCache[name] end
    --local screen = screenVals(name)

    --local config = getPlugin("config")
    --local playerId = unit.getMasterPlayerId()
    --local xval = config:get("xmax_"..playerId, 2560)
    --local yval = config:get("ymax_"..playerId, 1440)

    --screen.width = xval * screen.width
    --screen.height = yval * screen.height
    ---screen.offsetx = xval * screen.offsetx
    --screen.offsety = yval * screen.offsety

    --screen.menuitmwidth = math.floor(screen.width * screen.menuitmwidth)
    --screen.menuitmheight = math.floor(screen.height * screen.menuitmheight)
    --screenObjCache[name] = screen
    return screenDef[name]
end

function drawAllScreensCss()
	local persp = self:getPerspective()
    if modeColors[persp] == nil then
        modeColors[persp] = 290
    end
    local currHsl = math.max(0, math.min(modeColors[persp],360))

    local sqLeftHsl = currHsl + 270.0
    if sqLeftHsl > 360 then sqLeftHsl = sqLeftHsl - 360 end
    local sqTwoRight = currHsl + 180.0
    if sqTwoRight > 360 then sqTwoRight = sqTwoRight - 360 end
	
    local css = [[
                            * { font-family:Montserrat }
                            body { margin: 0}
                            svg {display:block; position:absolute; top:auto; left:auto}
                            svg svg { overflow: visible }
                            .screenSvg { position: relative; margin: auto 0; }
                            .screen { margin:0; padding:0; position: absolute; left: 0; top: 0; border: 2px solid transparent }
                        ]]

    if setupMode then
        css = css .. [[
							.screen { border: 2px solid hsl(]].. currHsl ..[[, 93.6%, 56.9%) }
							.menu { position: absolute; right: 0; top: 0; width: 100%; height: 3.125%; overflow: hidden; z-index: 1000 }
							.mItm { z-index:inherit; background-color:hsl(]].. currHsl ..[[, 100%, 50%);position: relative; float: right; height: 100%; width: calc(100% / 24); border: 2px solid hsl(]].. currHsl ..[[, 93.6%, 56.9%); overflow: hidden; color: white;display: flex;align-items: center;justify-content: center; }
						]]
    end

	local persp = self:getPerspective()
    for name, _ in pairs(screenDef) do
		screen = screenObj(name)
		if persp == screen.perspective then
			css = css .. [[
								#]]..name..[[ { width: ]].. (screen.width * 100) ..[[%; height: ]].. (screen.height * 100) ..[[%; top: ]].. (screen.offsety * 100) ..[[%; left: ]].. (screen.offsetx * 100) ..[[% }
			]]
			if setupMode then
				
				css = css .. [[
								#]]..name..[[ > .menu { height: ]].. (screen.menuitmheight * 100) ..[[% }
								#]]..name..[[ > .menu .mItm { width: ]].. (screen.menuitmwidth * 100) ..[[% }
				]]
				for nr, viewName in pairs(self:getViewList(screen.tag)) do
					local keyName = "scval_"..name.."_"..viewName
					local curr = config:get(keyName, 0)
					if curr == 1 then
						css = css .. [[
								#]]..name..[[ > .menu .mItm.n]]..nr..[[ { background-color:hsl(]].. sqTwoRight ..[[, 100%, 50%) }
						]]
					end
				end
			end
		end
    end
    return css
end
register:addAction("staticCssStyle","drawAllScreensCss",drawAllScreensCss)
local drawCatche = {}
function drawAllScreens()
    local altitude = 0
    --if core ~= nil then altitude = core.getAltitude() end

	--[[
    lastMode = mode
    if forceMode == -1 then
        if altitude == 0 or altitude > 10000 then
            mode = 1
        else
            mode = 0
        end
    else
        mode = forceMode
    end

    if mode ~= lastMode then
        --showWidgets()
    end ]]--
    local addCss, menuRender, mouse = self:actionToHtml("staticCssStyle"), "", ""

	local viewHudEntrys, innerScreens, mainScreens, screens = {}, {}, {}, {}
	
	local persp = self:getPerspective()
	
	if setupMode then	
        for nr, name in pairs(self:getViewList("screen")) do
            menuRender = menuRender .. '<div class="mItm text n'.. nr ..'">'.. name .."</div>"
        end
		menuRender = [[
			<div class="menu screentag">
				]]..menuRender..[[
			</div>
		]]
    end

	for name, _ in pairs(screenDef) do
		screen = screenObj(name)
		--print(screen.perspective)
		if persp == screen.perspective then
			if screen.tag == "screen" then
				if innerScreens[screen.parent] == nil then innerScreens[screen.parent] = "" end
				
				innerScreens[screen.parent] = innerScreens[screen.parent] .. [[
                                   <div id="]].. name ..[[" class="screen">
                                    ]].. menuRender .. [[
                                    ]].. self:actionToHtml(name .. "Html") ..[[
                                   </div>]]
			end
		end
	end
	if setupMode then
		menuRender = ""
        for nr, name in pairs(self:getViewList("hud")) do
            menuRender = menuRender .. '<div class="mItm text n'.. nr ..'">'.. name .."</div>"
        end
		menuRender = [[
			<div class="menu hudtag">
				]]..menuRender..[[
			</div>
		]]
    end
	for name, _ in pairs(screenDef) do
		screen = screenObj(name)
		
		if persp == screen.perspective then
			if screen.tag == "hud" then
				--print("calling " ..name .. "Html"..persp)
				if mainScreens[screen.parent] == nil then mainScreens[screen.parent] = "" end
				if innerScreens[name] == nil then innerScreens[name] = "" end
				mainScreens[screen.parent] = mainScreens[screen.parent] .. [[
									   <div id="]].. name ..[[" class="screen">
										]].. menuRender .. [[
										]].. self:actionToHtml(name .. "Html") ..[[
										]].. innerScreens[name]..[[
									   </div>]]
			end
		end
	end

	local screenHtml = ""
	if setupMode then
		local mouseX = 	system.getMousePosX() / screenDefault.totalWidth
        local mouseY = 	system.getMousePosY() / screenDefault.totalHeight

        screenHtml = [[
			<svg style="z-index: 10000;position: absolute;left:]]..(mouseX*100)..[[%;top:]]..(mouseY*100)..[[%" height="20px" width="20px" viewBox="0 0 512 512">
				<path class="sfill" d="M434.214,344.448L92.881,3.115c-3.051-3.051-7.616-3.947-11.627-2.304c-3.989,1.643-6.592,5.547-6.592,9.856v490.667
					c0,4.459,2.773,8.448,6.976,10.005c1.195,0.448,2.453,0.661,3.691,0.661c3.051,0,6.037-1.323,8.085-3.733l124.821-145.6h208.427
					c4.309,0,8.213-2.603,9.856-6.592C438.182,352.085,437.265,347.52,434.214,344.448z"/>
			</svg>
			]]
	end
	
	
	for name, html in pairs(mainScreens) do
		screenHtml = screenHtml .. html
	end
	
    local content = [[
                            <head>
                                <style>
                                    ]] .. addCss .. [[
                                </style>
                            </head>
                            <body>
                                ]].. screenHtml .. [[
                            </body>
                        ]]
    if debugscreen ~= nil then
        debugscreen.setHTML(content)
    end

    if #screens > 0 then
        for sname, realScreen in pairs(screens) do
            --system.print(type(realScreen))
            --self:renderView("monitor",realScreen.getMouseX(),realScreen.getMouseY(),realScreen.getMouseState() == 1)
            local name, newCode = "screen"..sname, nil
            local screen = screenObj(name)
            for _, viewName in pairs(self:getViewList(screen.tag)) do
                local totalViewName = name.."_"..viewName
                local keyName = "scval_"..totalViewName
                local curr = config:get(keyName, 0)
                if curr == 1 then
                    if self:renderViewRequireRerender(viewName, realScreen.getMouseX(),realScreen.getMouseY(),realScreen.getMouseState() == 1,"real"..totalViewName) then
                        if newCode == nil then newCode = "" end
                        newCode = newCode .. self:renderView(viewName,realScreen.getMouseX(),realScreen.getMouseY(),realScreen.getMouseState() == 1,"real"..totalViewName)
                    end
                end
            end
            if newCode ~= nil then
                realScreen.setHTML(newCode)
            end
        end
    end
    system.setScreen(content)
end

function self:triggerViewMouseEvent(up, name, x, y, screenUid, ...)
    if viewRegister[name] == nil then
        system.print("Render of view '" .. (name or "???") .. "' failed, because it there is no such view registered!","")
    end
    local viewObj = viewRegister[name]
	local event = viewObj.onMouseUp
	if up == false then
		event = viewObj.onMouseDown
	end
    if (event) then
        local status, res = pcall(event, viewObj, x, y, screenUid, ...)

        if status then
            return res
        else
            system.print(name ..": error in triggerViewMouseEvent:",up,res)
            return nil
        end
    else

    end
end
function self:registerDefaultScreen(screenName,viewName)
	local keyName = "scval_"..screenName.."_"..viewName
	if devMode then print("registering default view " .. keyName) end
	config:set(keyName, 1, 0)
end
function self:register(env)
    _ENV = env

    screenDefault.totalWidth = system.getScreenWidth()
    screenDefault.totalHeight = system.getScreenHeight()
	
    function setActionHtml(screenName,viewName)
        local screen = screenObj(screenName)
        local totalViewName = screenName.."_"..viewName
        local keyName = "scval_"..totalViewName
		
		local curr = config:get(keyName, 0)
		if curr == 1 then
			if devMode then print("register setActionHtml for " .. keyName) end
			--print("adding "..screenName.."Html")
			register:addAction(screenName.."Html",totalViewName.."Html", function()
				local mouseX = ((system.getMousePosX() / screenDefault.totalWidth) - screen.offsetx) / screen.width
				local mouseY = ((system.getMousePosY() / screenDefault.totalHeight) - screen.offsety) / screen.height
				if setupMode == false then
					mouseX, mouseY = -1, -1
				end
				--print("render " .. screenName.."Html".. "for " .. viewName .. " and total view " ..totalViewName)
				return self:renderView(viewName,mouseX,mouseY,false,totalViewName)
			end)
		else
			register:removeAction(screenName.."Html",totalViewName.."Html")
		end

    end
	function realMouseEvent(up,screen,screenEntity, x, y)
		local screenName = screen.name
		for _, realScreen in pairs(screens) do
			if realScreen.getId() == screenEntity.getId() then
				for _, viewName in pairs(register:getViewList(screen.tag)) do
					local totalViewName = screenName.."_"..viewName
					local keyName = "scval_"..totalViewName
					local curr = config:get(keyName, 0)

					if curr == 1 then
						self:triggerViewMouseEvent(up,viewName,x,y,"real"..totalViewName)
					end
				end
				return true
			end
		end
		return false
	end
	function virtualMouseEvent(up,screen, clickxbase, clickybase, screenType)
		local persp, screenName = self:getPerspective(), screen.name
		local xvalwidth, yvalheight = screen.width, screen.height
		local menuItemWidth = screen.menuitmwidth * screen.width
		local menuItemHeight = screen.menuitmheight * screen.height
		local clickx = clickxbase - screen.offsetx
		local clicky = clickybase - screen.offsety
		
		
		if clickx >= 0 and clickx < xvalwidth then
			if clicky >= 0 and clicky < yvalheight then
				-- height of menu
				if clicky < menuItemHeight then
					if up then
						for index, viewName in pairs(self:getViewList(screen.tag)) do

							local offset, preOffset = index*menuItemWidth,(index-1)*menuItemWidth

							if clickx > (xvalwidth - offset) and clickx <= (xvalwidth - preOffset) then
								local totalViewName = screenName.."_"..viewName
								local keyName = "scval_"..totalViewName
								local curr = config:get(keyName, 0)
								if curr == 1 then
									config:set(keyName, 0, 0)
								else
									config:set(keyName, 1, 0)
								end
								setActionHtml(screenName,viewName)
							end
						end
					end
				else
					for _, viewName in pairs(self:getViewList(screen.tag)) do
						local totalViewName = screenName.."_"..viewName
						local keyName = "scval_"..totalViewName
						local curr = config:get(keyName, 0)
						if curr == 1 then
							self:triggerViewMouseEvent(up, viewName,clickx / xvalwidth,clicky / yvalheight,totalViewName)
						end
					end
				end
				
				if devMode then
					local event = "DOWN"
					if up then event = "UP" end
					-- In screen
					print("Event "..event.."Screen " .. screenName  .. " Type " .. screenType .. " Relative x " .. clickx .. " Relative y " .. clicky)
				end

				return true
			end
		end
		return false
	end
	function tableLength(T)
		assert(type(T) == 'table', 'bad parameter #1: must be table')
		local count = 0
		for _ in pairs(T) do count = count + 1 end
		return count
	end
    function initAllScreens()
        screenObjCache = {} -- empty cache
        if devMode then print("reinitialize all "..tableLength(screenDef).." screens") end
		
        for name, _ in pairs(screenDef) do
			
            local screen = screenObj(name)
			
            for _, viewName in pairs(self:getViewList(screen.tag)) do
                setActionHtml(name,viewName)
            end

            register:addAction("screenMouseUp","realScreenMouseUp"..name,
				function(screenEntity, x, y)
                    realMouseEvent(true,screen,screenEntity, x, y)
				end
            )
			register:addAction("screenMouseDown","realScreenMouseUp"..name,
				function(screenEntity, x, y)
                    realMouseEvent(false,screen,screenEntity, x, y)
				end
            )
            register:addAction("mouseUp","screenMouseUp"..name,
				function(clickxbase, clickybase, screenType)
					if self:getPerspective() == screen.perspective then
						virtualMouseEvent(true,screen,clickxbase, clickybase, screenType)
					end
				end
            )
			register:addAction("mouseDown","screenMouseDown"..name,
				function(clickxbase, clickybase, screenType)
					if self:getPerspective() == screen.perspective then
						virtualMouseEvent(false,screen,clickxbase, clickybase, screenType)
					end
				end
            )
        end 
    end
	self:addScreen("mainScreenFirst",{
        menuitmwidth= 1 / 24,
        menuitmheight= 1 / 32,
        width=1,
        height=1,
        tag = "hud",
		perspective="first"
    });
	self:addScreen("mainScreenThird",{
        menuitmwidth= 1 / 24,
        menuitmheight= 1 / 32,
        width=1,
        height=1,
        tag = "hud"
    });
	self:addScreen("screen1first",{
        offsetx=0,
		perspective="first",
		parent="mainScreenFirst"
    });
	self:addScreen("screen1third",{
        offsetx=0
    });
	self:addScreen("screen2first",{
        offsetx=0,
        offsety=1 * (1/3),
		perspective="first",
		parent="mainScreenFirst"
    });
	self:addScreen("screen2third",{
        offsetx=0,
        offsety=1 * (1/3)
    });
	self:addScreen("screen3first",{
        offsetx=1 * 0.63,
        offsety=1 * 0.25,
        width=1 * 0.23,
        height=1 * 0.23,
		perspective="first",
		parent="mainScreenFirst"
    });
	self:addScreen("screen3third",{
        offsetx=1 * 0.63,
        offsety=1 * 0.25,
        width=1 * 0.23,
        height=1 * 0.23
    });
	self:addScreen("screen4first",{
        offsetx=1 * 0.56,
        offsety=0,
        width=1 * 0.20,
        height=1 * 0.25,
		perspective="first",
		parent="mainScreenFirst"
    });
	self:addScreen("screen4third",{
        offsetx=1 * 0.56,
        offsety=0,
        width=1 * 0.20,
        height=1 * 0.25
    });

	
    --register:addAction("staticCssStyle","drawAllScreensCss",drawAllScreensCss)
    register:addAction("registerAddView", "viewRegisterWatcher", initAllScreens)
    initAllScreens()
    register:addAction("unitOnStart","Screener", function()
        register:addAction("systemOnUpdate","drawAllScreens",
                function()
                    if databaseHasChild ~= true and screenToggle and (executeTotal == 1 or executeTotal%renderEveryXFrames==0) then
						drawAllScreens()
                        --timeit("update", drawAllScreens)
                        --local status, err = pcall(drawAllScreens)
                        --if not status then
                        --    system.print("Error: "..err)
                        --end
                    end
                end
        )
		
        register:addAction("leftmouseStart","mouseStartTracker",
                function()
                    if setupMode then
                        local mouseX = 	system.getMousePosX() / screenDefault.totalWidth
                        local mouseY = 	system.getMousePosY() / screenDefault.totalHeight
                        register:callAction("mouseDown",mouseX,mouseY,"hud")
                        return true
                    else
                        return false
                    end
                end
        )
        register:addAction("leftmouseStop","mouseStopTracker",
                function()
                    if setupMode then
                        local mouseX = 	system.getMousePosX() / screenDefault.totalWidth
                        local mouseY = 	system.getMousePosY() / screenDefault.totalHeight
                        register:callAction("mouseUp",mouseX,mouseY,"hud")
                        return true
                    else
                        return false
                    end
                end
        )
		
        --register:addAction("unitStop", "multiscreenStopInterface",hideWidgets)
    end)
	local CommandHandler = getPlugin("CommandHandler")
	CommandHandler:AddCommand("setup",
		function(prompt)
			setupMode = not setupMode
			if setupMode then
				system.lockView(true)
				print("setupMode on")
			else
				system.lockView(false)
				print("setupMode off")
			end
		end,
		"Activate/Deactivate screener setup mode"
	)
	
end
return self