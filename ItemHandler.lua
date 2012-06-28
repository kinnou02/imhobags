local Addon, private = ...

-- Builtins
local pcall = pcall

-- Globals
local Command = Command

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
	Trigger.Item.Standard.Right(params)
	if(not params.cancel) then
		pcall(Command.Item.Standard.Right, id)
	end
	return params.cancel
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
