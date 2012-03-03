local Addon, private = ...

if(Addon.toc.debug) then
	_G[Addon.identifier] = private
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

setfenv(1, private)

if(Addon.toc.debug) then
	log = function(...)
		local result = { }
		for i = 1, select("#", ...) do
			table.insert(result, tostring(select(i, ...)))
		end
		print(unpack(result))
	end
else
	log = function() end
end
