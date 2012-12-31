local Addon, private = ...

-- Upvalue
local pairs = pairs
local UtilityItemSlotParse = Utility.Item.Slot.Parse

-- Locals
local list = {
--	all = function() Inspect.Item.List() end,
	bank = function() return Inspect.Item.List(Utility.Item.Slot.Bank()) end,
	equipment = function() return Inspect.Item.List(Utility.Item.Slot.Equipment()) end,
	guild = function() return Inspect.Item.List(Utility.Item.Slot.Guild()) end,
	inventory = function() return Inspect.Item.List(Utility.Item.Slot.Inventory()) end,
	quest = function() return Inspect.Item.List(Utility.Item.Slot.Quest()) end,
	wardrobe = function() return Inspect.Item.List(Utility.Item.Slot.Wardrobe()) end,
}

function ImhoBagsDispatch(container)
	private.Item.Dispatcher.RunSlot(container)
end

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
local function dispatch(items, callbacks)
	for slot, item in pairs(items) do
		local container, bag, index = UtilityItemSlotParse(slot)
		for k, v in pairs(callbacks[container] or empty) do
			v(slot, item, container, bag, index)
		end
	end
end

local function eventItemSlot(items)
	dispatch(items, slotCallbacks)
end

local function eventItemUpdate(items)
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
	Event.Item.Slot[#Event.Item.Slot + 1] = { eventItemSlot, Addon.identifier, "ItemProcessing.Dispatcher.eventItemSlot" }
	Event.Item.Update[#Event.Item.Update + 1] = { eventItemUpdate, Addon.identifier, "ItemProcessing.Dispatcher.eventItemUpdate" }
end

Item.Dispatcher.Enable()
