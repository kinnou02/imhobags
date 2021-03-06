local Addon, private = ...

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
		return params.cancel
	else
		return params.cancel
	end
end

function ItemHandler.Standard.Left(id)
	if(not Inspect.System.Secure()) then
		Command.System.Watchdog.Quiet()
	end
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
