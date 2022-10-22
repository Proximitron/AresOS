local self = {}
function self:register(env)
    _ENV = env

	local CommandHandler = getPlugin("CommandHandler")
	CommandHandler:AddCommand("load",
		function(prompt)
			if prompt[2] == nil then
				print("Use of load: '/load pluginname'")
			else
				unloadPlugin(prompt[2])
				local loaded = getPlugin(prompt[2])
				if loaded ~= nil then
					if loaded.version ~= nil then
						print("Successfully loaded '"..prompt[2].."'("..loaded.version..")")
					else
						print("Successfully loaded '"..prompt[2].."'")
					end
				else
					print("Loaded '"..prompt[2].."', return nil received")
				end
			end
		end,
		"Load plugin by name (from file)"
	)
end
return self