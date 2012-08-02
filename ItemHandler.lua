local Addon, private = ...

-- Builtins
local _G = _G
local pcall = pcall

-- Globals
local Command = Command
local ImhoBags = ImhoBags

setfenv(1, private)
ItemHandler = {
	Standard = {
	}
}

function ItemHandler.Standard.Right(id)
	local params = {
		id = id,
		cancel = false,
	}
	-- temporary measure to find out which code path returns in the error reports
	local BananAH = false
	for k, v in _G.ipairs(_G.ImhoBags.Event.Item.Standard.Right) do
		if(v[2] == "BananAH") then
			BananAH = true
		end
	end
	if(BananAH) then
		Trigger.Item.Standard.Right(params)
		if(not params.cancel) then
			pcall(Command.Item.Standard.Right, id)
			return params.cancel
		else
			return params.cancel
		end
	else
		Trigger.Item.Standard.Right(params)
		if(not params.cancel) then
			pcall(Command.Item.Standard.Right, id)
			return params.cancel
		else
			return params.cancel
		end
	end
end

function ItemHandler.Standard.Left(id)
	local params = {
		id = id,
		cancel = false,
	}
	Trigger.Item.Standard.Left(params)
	if(not params.cancel) then
		pcall(Command.Item.Standard.Left, id)
	end
	return params.cancel
end

function ItemHandler.Standard.Drag(id)
	local params = {
		id = id,
		cancel = false,
	}
	Trigger.Item.Standard.Drag(params)
	if(not params.cancel) then
		pcall(Command.Item.Standard.Drag, id)
	end
	return params.cancel
end

function ItemHandler.Standard.Drop(id)
	local params = {
		id = id,
		cancel = false,
	}
	Trigger.Item.Standard.Drop(params)
	if(not params.cancel) then
		pcall(Command.Item.Standard.Drop, id)
	end
	return params.cancel
end
