--easier time with timers
local self = {}
local Timer = {}
function self:addTimer(ID, time, callback)
    unit.setTimer(ID, time)
    Timer[ID] = callback
end
function onTimer(timerId)
    if Timer[timerId] ~= nil then
        local a,b = pcall(Timer[timerId])
        if not a then print("Timer:" .. b .. "  " .. timerId) end
    end
end
function self:stopTimer(timerId)
	if Timer[timerId] ~= nil then
		unit.setTimer(timerId,0)
		Timer[timerId] = nil -- free for garbage collecting
	end
end
function self:stopAllTimer()
    for k,_ in pairs(Timer) do
        self:stopTimer(k)
    end
end
local DelayCounter = 0
function self:delay(func, time)
    local ID = "DelayCounter".. DelayCounter
    self:addTimer(ID, time, function() pcall(func) unit.stopTimer(ID) end)
    DelayCounter = DelayCounter + 1
end
function self:register(env)
    _ENV = env
	register:addAction("unitOnTimer", "Timer", onTimer) 
end
return self
