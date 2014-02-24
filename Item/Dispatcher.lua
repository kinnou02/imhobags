local Addon, private = ...

-- Upvalue
local pairs = pairs
local UtilityItemSlotParse = Utility.Item.Slot.Parse

local function mergetables(l, r)
	for k, v in pairs(r) do l[k] = v end
	return l
end

-- Locals
local list = {
--	all = function() Inspect.Item.List() end,
	bank = function() return mergetables(Inspect.Item.List(Utility.Item.Slot.Bank()), Inspect.Item.List(Utility.Item.Slot.Vault())) end,
	equipment = function() return Inspect.Item.List(Utility.Item.Slot.Equipment()) end,
	guild = function() return Inspect.Item.List(Utility.Item.Slot.Guild()) end,
	inventory = function() return Inspect.Item.List(Utility.Item.Slot.Inventory()) end,
	quest = function() return Inspect.Item.List(Utility.Item.Slot.Quest()) end,
	wardrobe = function() return Inspect.Item.List(Utility.Item.Slot.Wardrobe()) end,
}

setfenv(1, private)
Item = Item or { }
Item.Dispatcher = { }

-- Private methods
-- ============================================================================

local slotCallbacks = {
	bank = { },
	currency = { },
	equipment = { },
	guild = { },
	inventory = { },
	quest = { },
	wardrobe = { },
}

local updateCallbacks = {
	bank = { },
	currency = { },
	equipment = { },
	guild = { },
	inventory = { },
	quest = { },
	wardrobe = { },
}

local empty = { }

----------------------------------------------------------
-- NOTE:  See mouseMove() in ItemButton.lua for example using this technique with seperate function for the system update event
local dispatches = { }
local dispatchHookEnabled = false
local function dispatch(items, callbacks)
	-- create the thread (a function)
  local dispatchInstance = coroutine.create( 
  	function (items, callbacks)
			for slot, item in pairs(items) do
				if Inspect.System.Watchdog() < 0.02 then
					coroutine.yield()
				end
				local container, bag, index = UtilityItemSlotParse(slot)
				if container == "vault" then container = "bank" end
				for k, v in pairs(callbacks[container] or empty) do
					v(slot, item, container, bag, index)
				end
			end
		end
	)
  
  -- Run the thread.  If it is suspended immediately, then add it to 'dispatches' for handling at the System.Update.Begin event.
	coroutine.resume(dispatchInstance,items,callbacks)
	if coroutine.status(dispatchInstance) == 'suspended' then
  	dispatches[#dispatches + 1] = dispatchInstance
  end
  
  -- System.Update.Begin:   Go through all 'dispatches' and handle them appropriately
  if not dispatchHookEnabled then
    dispatchHookEnabled = true
    Command.Event.Attach(Event.System.Update.Begin, function (handle)
    	if (#dispatches > 0) then
				for i = 1, #dispatches do
					local thread = dispatches[i]
					if thread and type(thread) == 'thread' then
						local status = coroutine.status(thread)
						--print(string.format("DEBUG:  #dispatches: %d -- type(thread): %s -- status: %s -- i: %d",#dispatches,type(thread), tostring(status), i))
						if status == 'suspended' then
							coroutine.resume(thread)
						elseif status == 'dead' then
							table.remove(dispatches,i)
						end
					end
				end
	    end
    end, "Display")
  end
end
----------------------------------------------------------


local function eventItemSlot(handle, items)
	dispatch(items, slotCallbacks)
end

local function eventItemUpdate(handle, items)
	dispatch(items, updateCallbacks)
end

-- Public methods
-- ============================================================================

function Item.Dispatcher.AddSlotCallback(location, callback)
	local cb = slotCallbacks[location]
	if(cb) then
		cb[#cb + 1] = callback
	end
end

function Item.Dispatcher.RemoveSlotCallback(location, callback)
	local cb = slotCallbacks[location]
	if(cb) then
		for k, v in pairs(cb) do
			if(v == callback) then
				cb[k] = nil
			end
		end
	end
end

function Item.Dispatcher.AddUpdateCallback(location, callback)
	local cb = updateCallbacks[location]
	if(cb) then
		cb[#cb + 1] = callback
	end
end

function Item.Dispatcher.RemoveUpdateCallback(location, callback)
	local cb = updateCallbacks[location]
	if(cb) then
		for k, v in pairs(cb) do
			if(v == callback) then
				cb[k] = nil
			end
		end
	end
end

function Item.Dispatcher.RunSlot(location)
	local list = list[location]
	if(list) then
		dispatch(list(), slotCallbacks)
	end
end

function Item.Dispatcher.Enable()
	Command.Event.Attach(Event.Item.Slot, eventItemSlot, "Item.Dispatcher.eventItemSlot")
	Command.Event.Attach(Event.Item.Update, eventItemUpdate, "Item.Dispatcher.eventItemUpdate")
end

Item.Dispatcher.Enable()
