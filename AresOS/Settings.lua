self = {}
local config = getPlugin("config")

self.version = 0.9
self.loadPrio = 5
self.Default = {}
self.Range = {}
self.Description = {}

function self:add(name,Default,Range,Des,group)
    if name == nil or Default == nil then return "missing Infos" end
    Des = Des or ""
    group = group or "Standard" 
    if Range == nil or type(Range) ~= "table" then
        local t = type(Default)
        if t == "boolean" then
            Range = {"boolean"}
        elseif t == "number" then
            Range = {"number",1,10,1}
        else
            return "missing Range Infos"
        end
    end
    if self.Default[group] == nil then self.Default[group] = {} self.Range[group] = {} self.Description[group] = {} end
    self.Default[group][name] = Default
    self.Range[group][name] = Range
    self.Description[group][name] = Des
end

function self:rem(name,group)
    group = group or "Standard"
    self.Default[group][name] = nil
    self.Range[group][name] = nil
    self.Description[group][name] = nil
end

function self:set(name,val,group)
    group = group or "Standard"
    local r = self.Range[group][name]
    local t = type(val)
    if r[1] ~= t then return end
    if t == "number" then
        val = utils.clamp(val,r[2],r[3])
        val = (val - r[2]) / r[4]
        val = round(val)
        val = val * r[4] + r[2]
    elseif t == "string" then
        if not inTable(r[2],val) then return end
    end
	config:set(group..name,val,self.Default[group][name])
end

function self:get(name,group)
    group = group or "Standard"
	return config:get(group..name, self.Default[group][name])
end

function self:register(env)
    _ENV = env
end
return self