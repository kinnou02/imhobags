local identifier = (...).id
local toc = (...).toc
local addon = (...).data

if(toc.debug) then
	_G[identifier] = addon
end

local pairs = pairs
local print = print
local table = table
local tostring = tostring

local Command = Command
local Event = Event
local Inspect = Inspect
local UI = UI

setfenv(1, addon)

debug = (toc.debug and print) or function() end
