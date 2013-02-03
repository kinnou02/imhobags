local Addon, private = ...

-- Locals
local backgroundOffset = 3
local backgroundHeight = 32

local contentPaddingLeft = 7
local contentPaddingBottom = 9

local textColor = { 245 / 255, 240 / 255, 198 / 255 }

setfenv(1, private)
Ux.ItemWindowTemplate = Ux.ItemWindowTemplate or { }

-- Private methods
-- ============================================================================

-- Public methods
-- ============================================================================

function Ux.ItemWindowTemplate.SortSelector(parent, titleBar, hasLayout)
	local UICreateFrame = UI.CreateFrame
	local self = UICreateFrame("Mask", "", Ux.TooltipContext)
	self:SetHeight(0)
	
	local background = UICreateFrame("Texture", "", self)
	background:SetPoint("BOTTOMCENTER", self, "BOTTOMCENTER")
	background:SetTexture("Rift", "dropdown_list.png.dds")
	
	local anchor
	
	if(hasLayout) then
		local sep = UICreateFrame("Texture", "", background)
		sep:SetTextureAsync("Rift", "rollover_divider_alpha.png.dds")
		anchor = sep
		
		-- Layout options
		local bags = UICreateFrame("Texture", "", sep)
		bags:SetPoint("BOTTOMCENTER", background, "BOTTOMCENTER", 0, -5)
		bags:SetTextureAsync("ImhoBags", "textures/icon_menu_bags.png")
		
		local default = UICreateFrame("Texture", "", sep)
		default:SetPoint("RIGHTCENTER", bags, "LEFTCENTER", -contentPaddingLeft, 0)
		default:SetTextureAsync("Rift", "NPCDialogIcon_auctioneer.png.dds")
		
		local onebag = UICreateFrame("Texture", "", sep)
		onebag:SetPoint("LEFTCENTER", bags, "RIGHTCENTER", contentPaddingLeft, 0)
		onebag:SetTextureAsync("ImhoBags", "textures/icon_menu_layout_onebag.png")
		
		sep:SetPoint("LEFT", background, "LEFT")
		sep:SetPoint("RIGHT", background, "RIGHT")
		sep:SetPoint("BOTTOM", bags, "TOP", nil, 5)
		
		function default.Event.LeftClick() self.layoutCallback("default") end
		function bags.Event.LeftClick() self.layoutCallback("bags") end
		function onebag.Event.LeftClick() self.layoutCallback("onebag") end
		
		function self:SetLayoutCallback(callback)
			self.layoutCallback = callback
		end
		function self:SetLayoutValue(sort)
			default:SetAlpha(sort == "default" and 1.0 or 0.7)
			bags:SetAlpha(sort == "bags" and 1.0 or 0.7)
			onebag:SetAlpha(sort == "onebag" and 1.0 or 0.7)
		end
	else
		anchor = background
		function self:SetLayoutCallback() end
		function self:SetLayoutValue() end
	end
	
	-- Sorting options
	local icon = UICreateFrame("Texture", "", background)
	icon:SetPoint("BOTTOMRIGHT", anchor, "BOTTOMCENTER", 0, -4)
	icon:SetTextureAsync("ImhoBags", "textures/icon_menu_sort_icon.png")

	local name = UICreateFrame("Texture", "", background)
	name:SetPoint("RIGHTCENTER", icon, "LEFTCENTER", -contentPaddingLeft, 0)
	name:SetTextureAsync("ImhoBags", "textures/icon_menu_sort_name.png")
	
	local rarity = UICreateFrame("Texture", "", background)
	rarity:SetPoint("LEFTCENTER", icon, "RIGHTCENTER", contentPaddingLeft, 0)
	rarity:SetTextureAsync("ImhoBags", "textures/icon_menu_sort_rarity.png")
	
	local slot = UICreateFrame("Texture", "", background)
	slot:SetPoint("LEFTCENTER", rarity, "RIGHTCENTER", contentPaddingLeft, 0)
	slot:SetTextureAsync("ImhoBags", "textures/icon_menu_bags.png")
		
	self:SetWidth(icon:GetWidth() + name:GetWidth() + rarity:GetWidth() + slot:GetWidth() + 4 * contentPaddingLeft)
	background:SetWidth(self:GetWidth())
	
	function icon.Event.LeftClick() self.sortCallback("icon") end
	function name.Event.LeftClick() self.sortCallback("name") end
	function rarity.Event.LeftClick() self.sortCallback("rarity") end
	function slot.Event.LeftClick() self.sortCallback("slot") end
	
	function self:SetSortCallback(callback)
		self.sortCallback = callback
	end
	function self:SetSortValue(sort)
		icon:SetAlpha(sort == "icon" and 1.0 or 0.7)
		name:SetAlpha(sort == "name" and 1.0 or 0.7)
		rarity:SetAlpha(sort == "rarity" and 1.0 or 0.7)
		slot:SetAlpha(sort == "slot" and 1.0 or 0.7)
	end
	
	Ux.ItemWindowTemplate.FadingPopup.MakeFadeable(self, titleBar, (hasLayout and backgroundHeight or 0) + backgroundHeight + backgroundOffset)

	return self
end
