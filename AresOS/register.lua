-- Register is handling all event registrations
local self = {}
self.functionRegister = {}
self.overwriteRegister = {}
self.overwriteOrder = {}
self.viewRegister = {} -- collection of all views
self.pressedRegister = {} -- collection of all currently pressed keys. For performance reasons, only use this for events, not ship movement!

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

-- Switches are functions that can be activated or deactivated
-- the property "buttonName" and functions like "activate", "deactivate" and "isActive" should be part of the entity passed
self.switches = {}
function self:addSwitch(name, entity)
    assert(type(name) == "string", "name isn't a string, type was " .. type(name))
    assert(type(entity) == "table", name .. ": entity isn't a table, type was " .. type(entity))

    self.switches[name] = entity

    self:callAction("registerAddSwitch", name)
end
function self:getSwitch(name)
    assert(type(name) == "string", "name isn't a string, type was " .. type(name))
    return self.switches[name]
end
function self:getSwitches()
    return self.switches
end

self.taskRegister = { }
self.taskOrder = {}
local function compareTasks(a, b)
    if a ~= nil and b ~= nil then
        return self.taskRegister[a].order < self.taskRegister[b].order
    end
    return nil
end
--[[Adds a task that will be done one step (yield) every frame,
    if there is not a task with lower or same priority number before that.
    Tasks with a lot of yield and unset "rating" that run for a very long time may block important tasks.
    "rating" is the amount of power, in relation the total cpu cycles, a task takes.
    At the time of adding this rating, you could execute about 3500 commands before cpu overload.]]--
local taskMaxRating = 2500
function self:addTask(name, func, priority, rating)
    assert(type(name) == "string", "addTask: name isn't a string, type was " .. type(name))
    assert(type(func) == "function", name .. ": func isn't a function, type was " .. type(func))
    if priority == nil then
        priority = 10
    else
        assert(type(priority) == "number" ,  name .. ": priority has to be number, type was " .. type(priority))
    end

    if rating == nil then
        rating = taskMaxRating
    else
        assert(type(rating) == "number" ,  name .. ": rating has to be number, type was " .. type(rating))
        assert(rating <= taskMaxRating ,  name .. ": rating has to be smaller then the allowed max rating of " .. taskMaxRating)
    end

    if not self:hasAction("systemUpdate","registerTasker") then
        self:addAction("systemUpdate","registerTasker",function() self:runTasks() end)
    end

    if self.taskRegister[name] ~= nil then self:removeTask(name) end

    table.insert(self.taskOrder, name)
    self.taskRegister[name] = {order=priority,task=coroutine.create(func),rating=rating}

    if #self.taskOrder > 1 then table.sort(self.taskOrder,compareTasks) end
end
function self:hasTask(name)
    return self.taskRegister[name] ~= nil
end
function self:removeTask(name)
    assert(type(name) == "string", "removeTask: Name isn't a string, type was " .. type(name))

    self.taskRegister[name] = nil
    for k,v in pairs(self.taskOrder) do
        if v == name then
            table.remove(self.taskOrder,k)
            return
        end
    end
end
function self:runTasks()
    local currTasksRating = 0
    for _, name in ipairs(self.taskOrder) do
        local regTask = self.taskRegister[name]

        if (currTasksRating + regTask.rating) <=  taskMaxRating then
            if regTask.task == nil or coroutine.status(regTask.task) == "dead" then
                self:removeTask(name)
            else
                currTasksRating = currTasksRating + regTask.rating
                local ok, errorMsg = coroutine.resume(regTask.task)
                if not ok then
                    system.print(name .." in runTasks:",errorMsg)
                    self:removeTask(name)
                end
            end
        end
    end
end

function self:hasAction(action,name)
    return self.functionRegister[action] ~= nil and self.functionRegister[action][name] ~= nil
end
function self:addAction(action, name, func)
    assert(type(action) == "string", "action isn't a string, type was " .. type(action))
    assert(type(name) == "string", action .. ": name isn't a string, type was " .. type(name))
    assert(type(func) == "function", action .. ":" .. name .. ": func isn't a function, type was " .. type(func))

    if self.functionRegister[action] == nil then
        self.functionRegister[action] = {}
    end
    self.functionRegister[action][name] = func
end
function self:removeAction(action, name)
    if self.functionRegister[action] == nil or self.functionRegister[action][name] == nil then
        return false
    end
    self.functionRegister[action][name] = nil
    return true
end
function self:callAction(action, ...)
    local results = {}
    if self.functionRegister[action] ~= nil then
        for name, func in pairs(self.functionRegister[action]) do
            if func ~= nil then
                local status, res = pcall(func, ...)
                if status then
                    results[name] = res
                else
                    system.print(name .." in callAction:",res)
                end
            end
        end
    end
    return results
end
function self:callActionSpecific(action, name, ...)
	assert(self.functionRegister[action] == "table", action .. ":" .. " not registered")
	assert(self.functionRegister[action][name] == "function", action .. ":" .. name .. ": called specified function isn't a function, type was " .. type(self.functionRegister[action][name]))
	
	local status, res = pcall(self.functionRegister[action][name], ...)
	if status then
		return res
	else
		system.print(name .." in callActionSpecific:",res)
	end
end
return self