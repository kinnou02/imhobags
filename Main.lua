local context = UI.CreateContext("ImhoBags")

ImhoBags = { }

local pairs = pairs
local print = print
local table = table
local tostring = tostring

local Command = Command
local Event = Event
local Inspect = Inspect
local UI = UI


setfenv(1, ImhoBags)

local function printTable(tbl)
	for k, v in pairs(tbl) do
		print("["..k.."] = "..tostring(v))
	end
end

local function slot(item)
	printTable(item)
end

table.insert(Event.Item.Slot, { slot, "ImhoBags", "slot" })
