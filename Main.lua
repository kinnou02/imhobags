local context = UI.CreateContext("ImhoBags")

ImhoBags = { }

local dump = dump
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
	print("Event.Item.Slot")
	printTable(item)
end

AddonName = "ImhoBags"
ShardName = Inspect.Shard().name
