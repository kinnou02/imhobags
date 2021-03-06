local Addon, private = ...

setfenv(1, private)
Ux.ItemWindowTemplate.FadingPopup = { }

-- Private methods
-- ============================================================================

local function fadeIn(self, height)
	self:SetVisible(true)
	self.fadingAnimation:Stop()
	self.fadingAnimation = self:AnimateHeight(Const.AnimationsDuration, "smoothstep", height)
end

local function fadeOut(self)
	self.fadingAnimation:Stop()
	self.fadingAnimation = self:AnimateHeight(Const.AnimationsDuration, "smoothstep", 0, function()
		self:SetVisible(false)
	end)
end

-- Public methods
-- ============================================================================

function Ux.ItemWindowTemplate.FadingPopup.MakeFadeable(frame, titleBar, fullHeight)
	local hotArea = UI.CreateFrame("Frame", "", frame)
	hotArea:SetLayer(100)
	hotArea:SetPoint("TOPLEFT", frame, "TOPLEFT")
	hotArea:SetPoint("TOPRIGHT", frame, "TOPRIGHT")
	hotArea:SetHeight(fullHeight)
	hotArea:SetMouseMasking("limited")
	
	if(titleBar) then
		hotArea:EventAttach(Event.UI.Input.Mouse.Cursor.Out, function()
			if(frame:GetHeight() > 1) then
				if(not titleBar:IsMouseHot()) then
					titleBar:FadeOut()
				end
				frame:FadeOut()
			end
		end, "")
	else
		hotArea:EventAttach(Event.UI.Input.Mouse.Cursor.Out, function()
			if(frame:GetHeight() > 1) then
				frame:FadeOut()
			end
		end, "")
	end
	
	frame.FadeIn = function(self) fadeIn(self, fullHeight) end
	frame.FadeOut = fadeOut
	frame.fadingAnimation = LibAnimate.CreateEmptyAnimation()
	
	return hotArea
end
