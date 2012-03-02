local identifier = (...).id
local toc = (...).toc
local addon = (...).data

if(toc.debug) then
	_G[identifier] = addon
end

local print = print
local select = select
local table = table
local tostring = tostring
local unpack = unpack

local Command = Command
local Event = Event
local Inspect = Inspect
local UI = UI

setfenv(1, addon)

if(toc.debug) then
	debug = function(...)
		local result = { }
		for i = 1, select("#", ...) do
			table.insert(result, tostring(select(i, ...)))
		end
		print(unpack(result))
	end
else
	debug = function() end
end
