-- This library has been created to keep out of the watchdog easily. 
-- Instead of having to write the whole coroutine mechanic each time you have performance issues, you can use this.
-- It permit to create a coroutine in a couple of lines.

-- To use it, just call corout(YourFunction) and it will start a coroutine running YourFunction automatically.
-- You have to call corout.check() sometimes in your function to verify that the watchdog isn't about to cut of you addon.

-- It is recommended to add a label to all your corouts in order to be safe with others addons and your own addon when you use multiples corouts together.
-- In addition, you're allowed to pass as much parameters as you wish after those ones. You may get something like corout(MyFunction, "Corout MyLabel", MyArg1, MyArg2, ...).
-- You can also define another time remaining limit before watchdog alarm if you want to (default is 0.03).

-- Here is an example :

-- function example(arg1, arg2)
--		for foo, foo2 in pairs(arg) do
--			arg2[foo] = foo2 	
--			-- do something here too
--
--			corout.check()							--check the watchdog state
--		end
-- end
--
-- corout(example, "Corout AddonIdentifier", arg1, arg2)

local unpack = table.unpack

--The Corout library
corout = setmetatable(
{	
	-- Creation of a new corout, executing immediately
	new = function(functionToCorout, label, ...)
		if not label then
			label = "Corout"
		end

		local alive, err
		local args = {...}

		local coroutProcess = coroutine.create(functionToCorout)

		local function coroutResume(handle)			
			if coroutine.status(coroutProcess) ~= "dead" then
				alive, err = coroutine.resume(coroutProcess, unpack(args))
			else
				if err then
					error("Error in "..label.." : "..err)
				end

				coroutProcess = nil
				Command.Event.Detach(Event.System.Update.Begin, coroutResume, label)
			end
		end

		Command.Event.Attach(Event.System.Update.Begin, coroutResume, label)
	end,

	--Check the remaining time before the watchdog alert
	check = function(timeRemaining)
		if Inspect.System.Watchdog() < (timeRemaining or 0.03) then
			print("coroutine yielding for Watchdog!")
			coroutine.yield()
		end
	end
}, 
{
	--Allow the calling of corout() instead of corout.new()
	__call = function(corout, functionToCorout, label, ...)		 	
		corout.new(functionToCorout, label, ...)
	end
}
)	