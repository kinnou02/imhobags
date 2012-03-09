local Addon, private = ...

if(Inspect.System.Language() ~= "Russian" ) then
	return
end

setfenv(1, private)
L = --@localization(locale="ruRU", format="lua_table", handle-unlocalized="english", handle-subnamespaces="subtable")
