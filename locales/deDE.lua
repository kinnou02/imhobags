local Addon, private = ...

if(Inspect.System.Language() ~= "German" ) then
	return
end

setfenv(1, private)
L = --@localization(locale="deDE", format="lua_table", handle-unlocalized="english", handle-subnamespaces="subtable")
