local Addon, private = ...

-- Only the keys in this table are valid config options
local defaults = {
	showEnemyFaction = "no",
}

-- Contains valid values for string/int
local allowedValues = {
	showEnemyFaction = { no = true, yes = true, account = true }
}

local function setBoolean(k, v)
	if(type(v) == "boolean") then
		ImhoBags_Config[k] = v
	elseif(type(v) == "string") then
		local l, n = string.lower(v), tonumber(v)
		if(l == "true" or l == "t" or (n and n == 1)) then
			ImhoBags_Config[k] = true
		elseif(l == "false" or l == "f" or (n and n == 0)) then
			ImhoBags_Config[k] = false
		else
			error(string.format("Invalid value for boolean %s: %s", k, v), 0)
		end
	elseif(type(v) == "number") then
		if(tonumber(v) == 0) then
			ImhoBags_Config[k] = false
		else
			ImhoBags_Config[k] = true
		end
	else
		error(string.format("Invalid value for boolean %s: %s", k, tostring(v)), 0)
	end
end

local function setString(k, v)
	v = tostring(v)
	if(allowedValues[k] ~= nil) then
		if(not allowedValues[k][v]) then
			error(string.format("Invalid value for string %s: %s", k, v), 0)
		end
	end
	ImhoBags_Config[k] = v
end

local function set(t, k, v)
	if(defaults[k] == nil) then
		error(string.format("Unknown option %s", k), 0)
	end
	if(v == nil) then
		ImhoBags_Config[k] = nil -- Reset to default
	elseif(type(defaults[k]) == "boolean") then
		setBoolean(k, v)
	elseif(type(defaults[k]) == "string") then
		setString(k, v)
	end
	private.Trigger.Config(k, ImhoBags_Config[k])
end

local function variablesLoaded(addonIdentifier)
	if(addonIdentifier ~= Addon.identifier) then
		return
	end
	
	ImhoBags_Config = ImhoBags_Config or { }
	-- Remove obsolete values
	for k in pairs(ImhoBags_Config) do
		if(defaults[k] == nil) then
			ImhoBags_Config[k] = nil
		end
	end
	-- Set metatamethods for value validation
	setmetatable(ImhoBags_Config, {
		__index = defaults,
		__metatable = "not your business",
	})
	
	local interface = {
		isOption = function(k) return defaults[k] ~= nil end,
		reset = function()
			for k in pairs(ImhoBags_Config) do
				ImhoBags_Config[k] = nil
				private.Trigger.Config(k, ImhoBags_Config[k])
			end
		end,
	}
	
	private.Config = setmetatable(interface, {
		__index = ImhoBags_Config,
		__newindex = set,
		__metatable = "not your business",
	})
end

table.insert(Event.Addon.SavedVariables.Load.End, { variablesLoaded, Addon.identifier, "Config_variablesLoaded"})
