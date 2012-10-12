local Addon, private = ...

-- Builtins

-- Globals
local UICreateFrame = UI.CreateFrame

-- Locals

setfenv(1, private)
Ux.ItemWindowTemplate.FadingPopup = { }

-- Private methods
-- ============================================================================

local function fadeIn(self, height)
	local function tick(width) self:SetHeight(width) end

	self:SetVisible(true)
	Animate.stop(self.fadingAnimation)
	self.fadingAnimation = Animate.smoothstep(self:GetHeight(), height, 0.3, tick, function()
		self.fadingAnimation = 0
	end)
end

local function fadeOut(self)
	local function tick(width) self:SetHeight(width) end
	
	Animate.stop(self.fadingAnimation)
	self.fadingAnimation = Animate.smoothstep(self:GetHeight(), 0, 0.3, tick, function()
		self.fadingAnimation = 0
		self:SetVisible(false)
	end)
end

-- Public methods
-- ============================================================================

function Ux.ItemWindowTemplate.FadingPopup.MakeFadeable(frame, titleBar, fullHeight)
	local hotArea = UICreateFrame("Frame", "", frame)
	hotArea:SetLayer(100)
	hotArea:SetPoint("TOPLEFT", frame, "TOPLEFT")
	hotArea:SetPoint("TOPRIGHT", frame, "TOPRIGHT")
	hotArea:SetHeight(fullHeight)
	hotArea:SetMouseMasking("limited")
	
	if(titleBar) then
		function hotArea.Event.MouseOut()
			if(frame:GetHeight() > 1) then
				if(not titleBar:IsMouseHot()) then
					titleBar:FadeOut()
				end
				frame:FadeOut()
			end
		end
	else
		function hotArea.Event.MouseOut()
			if(frame:GetHeight() > 1) then
				frame:FadeOut()
			end
		end
	end
	
	frame.FadeIn = function(self) fadeIn(self, fullHeight) end
	frame.FadeOut = fadeOut
	
	return hotArea
end
