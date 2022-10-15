local self = {}
function self:register(env)
    _ENV = env
    register:addAction("systemOnInputText", "CommandHandler", CommandHandler)
end
self.version = 0.9
self.loadPrio = 5
function CommandHandler(text)
    text = string.lower(text)
    local prefix = string.sub(text,1,1)
    if prefix ~= self.prefix then return end
    local command = mysplit(string.sub(text,2,#text))
    local a,error = pcall(CommandList[1][prefix][1][command[1]], command)
    if not a then print(error) end
end

if unitType == "gunner" then
    self.prefix = "/"
elseif unitType == "remote" then
    self.prefix = "!"
else
    self.prefix = "/"
end
CommandList = {
    {
        [self.prefix] = {
            {
                ["help"] = function (input)
                    local str = input[2]
                    if str == nil then 
                        for k,v in pairs(CommandList[1][self.prefix][2]) do
                            print(k .. ":  " .. v)
                        end
                    end
                end,
            },
            {
                ["help"] = "use this to list all commands",
            }
        },
    },
    {
        [self.prefix] = "basic commands from the" ..unitType or "",
    }
}
function self:AddCommand(name,func,desc)
    CommandList[1][self.prefix][1][name] = func
    CommandList[1][self.prefix][2][name] = desc or ""
end
return self