local Addon, private = ...

-- Builtins
local pairs = pairs

-- Globals
local EventSystemUpdateBegin = Event.System.Update.Begin
local InspectTimeFrame = Inspect.Time.Frame

-- Locals
local animations = { }
local running = { }
local dummy = function() end

setfenv(1, private)
Animate = { }

-- Private methods
-- ============================================================================

local function lerp(t)
	return t
end

local function easeInOut(t)
	return 3 * t * t - 2 * t * t * t
end

EventSystemUpdateBegin[#EventSystemUpdateBegin + 1] = { function()
	local now = InspectTimeFrame()
	for k, v in pairs(running) do
		local dt = now - v[4]
		if(dt >= v[3]) then -- now - start >= duration
			v[6](v[2])	-- callback(to)
			v[7]()		-- finisher()
			running[k] = nil
		else
			local t = v[5](dt / v[3]) -- t = interpolant((now - start) / duration)
			v[6](v[1] + t * (v[2] - v[1])) -- callback(from + t * (to - from))
		end
	end
end, Addon.identifier, "animation runner" }

local function insert(from, to, duration, interpolant, callback, finisher, i)
	if(not i) then
		i = #running + 1
	end
	running[i] = { from, to, duration, InspectTimeFrame(), interpolant, callback or dummy, finisher or dummy }
	return i
end

-- Public methods
-- ============================================================================

Animate.predefined = {
	lerp = lerp,
	easeInOut = easeInOut,
}

function Animate.add(interpolant, callback, finisher)
	local i = #animations + 1
	animations[i] = { interpolant or lerp, callback, finisher }
	return i
end

function Animate.remove(i)
	animations[i] = nil
	running[i] = nil
end

function Animate.start(i, from, to, duration)
	if(animations[i] and not running[i]) then
		insert(from, to, duration, animations[i][1], animations[i][2], animations[i][3], i)
	end
end

function Animate.stop(i)
	running[i] = nil
end

function Animate.running(i)
	return i ~= nil and running[i] ~= nil
end

function Animate.lerp(from, to, duration, callback, finisher)
	return insert(from, to, duration, lerp, callback, finisher)
end

function Animate.easeInOut(from, to, duration, callback, finisher)
	return insert(from, to, duration, easeInOut, callback, finisher)
end