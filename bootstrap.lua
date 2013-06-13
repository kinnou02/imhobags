local Addon, private = ...

-- Move globals into private table
local copy = {
	-- Standard functions
	"assert", "collectgarbage", "dofile", "error", "_G", "getfenv", "getmetatable", "ipairs", "load",
	"loadfile", "loadsting", "next", "pairs", "pcall", "print", "rawequal", "rawget", "rawset", "select",
	"setfenv", "setmetatable", "tonumber", "tostring", "type", "unpack", "_VERSION", "xpcall",
	
	-- Builtin libraries
	"bit", "coroutine", "debug", "math", "os", "string", "table",
	
	-- Rift specific
	"Command", "dump", "Event", "Inspect", "UI", "UIParent", "Utility",
	
	-- Used libraries
	"LibAnimate", "LibAsyncTextures", "zlib",
}
for i = 1, #copy do
	private[copy[i]] = _G[copy[i]]
end

-- Other setup stuff
if(Addon.toc.debug) then
	ImhoBagsDebug = private
end

if(Addon.toc.debug) then
	private.log = print
else
	private.log = function() end
end

if(string.find(Addon.toc.Version, "alpha")) then
	Command.Console.Display("general", false, "<font color='#FF8000'>This is an ALPHA development version of ImhoBags and not intended for release. It may be broken, have errors or not work at all. You have been warned.</font>", true)
end
local lang = Inspect.System.Language()
local translators = {
	German = true,
	English = true,
	Russian = true,
	French = true,
}
if(not translators[lang]) then
	Command.Console.Display("general", false, "<font color='#FFFF00'>ImhoBags is looking for " .. lang .. " translators and reviewers!\nContact Imhothar on Curse or RiftUI if you'd like to help!</font>", true)
end
