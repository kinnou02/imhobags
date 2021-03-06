local Addon, private = ...

local shortcuts = {
	i = "inventory",
	inv = "inventory",
	b = "bank",
	c = "currency",
	e = "equipment",
	q = "quest",
}

local allowedLocations = {
	inventory = true,
	bank = true,
	currency = true,
	equipment = true,
	quest = true,
}

setfenv(1, private)

local function slashMain(handle, args)
	local arg1, arg2 = unpack(string.split(args, "%s", true))
	
	if(arg1 == "") then arg1 = nil end
	if(arg2 == "") then arg2 = nil end
	if(not arg1) then
		print(L.SlashMessage.usage)
		return
	end
	
	-- /imhobags search
	if(arg1 == "search") then
		Ux.SearchWindow:Show()
		return
	end
	
	-- /imhobags SetSort
	if(arg1 == "SetCategorySortOrder") then
		Ux.SetCategorySortWindow:Toggle()
		return
	end
	
	-- /imhobags menu
	if(arg1 == "menu") then
		Ux.ToggleMenuWindow()
		return
	end
	
	-- /imhobags config
	-- /imhobags config list
	-- /imhobags config help
	-- /imhobags option [value]
	if(arg1 == "config") then
		if(arg2 == "help") then
			print(L.SlashMessage.configOptions)
		elseif(arg2 == nil) then
			Ux.ToggleConfigWindow()
		else
			Config.print()
		end
		return
	elseif(Config.isOption(arg1)) then
		if(not arg2) then
			local v = Config[arg1]
			if(type(v) == "boolean") then
				print(arg1 .. " = " .. ((v and "yes") or "no"))
			else
				print(arg1 .. " = " .. tostring(v))
			end
		else
			local s, err = pcall(function() Config[arg1] = arg2 end)
			if(not s) then
				print("\n/imhobags " .. args)
				print(err)
				print(L.SlashMessage.configOptions)
			end
		end
		return
	end
	
	-- /imhobags char [location]
	if(arg1 == "player") then
		arg1 = Player.name
	end
	if(not Item.Storage.GetCharacterAlliances()[arg1]) then
		print("\n/imhobags " .. args)
		print(string.format(L.SlashMessage.unknownChar, arg1))
		return
	end
	local loc = shortcuts[arg2 or "i"] or arg2
	if(not allowedLocations[loc]) then
		print("\n/imhobags " .. args)
		print(string.format(L.SlashMessage.unknownLocation, arg2))
		return
	end
	Ux.ToggleItemWindow(arg1, loc)
end

Command.Event.Attach(Command.Slash.Register("imhobags"), slashMain, "slashMain")
