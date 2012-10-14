local Addon, private = ...

-- Builtins

-- Globals
local UICreateFrame = UI.CreateFrame

-- Locals
local backgroundOffset = 3
local backgroundHeight = 64

local contentPaddingLeft = 7
local contentPaddingBottom = 9

local textColor = { 245 / 255, 240 / 255, 198 / 255 }

setfenv(1, private)
Ux.ItemWindowTemplate = Ux.ItemWindowTemplate or { }

-- Private methods
-- ============================================================================

-- Public methods
-- ============================================================================

function Ux.ItemWindowTemplate.SortSelector(parent, titleBar)
	local self = UICreateFrame("Mask", "", Ux.TooltipContext)
	self:SetHeight(0)
	
	local background = UICreateFrame("Texture", "", self)
	background:SetPoint("BOTTOMCENTER", self, "BOTTOMCENTER")
	background:SetTexture("Rift", "dropdown_list.png.dds")
	
	local sep = UICreateFrame("Texture", "", background)
	sep:SetTextureAsync("Rift", "rollover_divider_alpha.png.dds")
	
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
	
	sep:SetPoint("BOTTOMCENTER", bags, "TOPCENTER", 0, 5)
	
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
	
	-- Sorting options
	local icon = UICreateFrame("Texture", "", sep)
	icon:SetPoint("BOTTOMRIGHT", sep, "TOPCENTER", 0, 5)
	icon:SetTextureAsync("ImhoBags", "textures/icon_menu_sort_icon.png")
	
	local name = UICreateFrame("Text", "", sep)
	name:SetPoint("RIGHTCENTER", icon, "LEFTCENTER", -contentPaddingLeft, 0)
	name:SetFontColor(textColor[1], textColor[2], textColor[3])
	name:SetFontSize(14)
	name:SetText(L.Ux.SortOption.name)
	
	local rarity = UICreateFrame("Texture", "", sep)
	rarity:SetPoint("LEFTCENTER", icon, "RIGHTCENTER", contentPaddingLeft, 0)
	rarity:SetTextureAsync("ImhoBags", "textures/icon_menu_sort_rarity.png")
	
	local slot = UICreateFrame("Texture", "", sep)
	slot:SetPoint("LEFTCENTER", rarity, "RIGHTCENTER", contentPaddingLeft, 0)
	slot:SetTextureAsync("ImhoBags", "textures/icon_menu_bags.png")
	
	sep:SetWidth(icon:GetWidth() + name:GetWidth() + rarity:GetWidth() + slot:GetWidth() + 4 * contentPaddingLeft)
	self:SetWidth(sep:GetWidth())
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
	
	Ux.ItemWindowTemplate.FadingPopup.MakeFadeable(self, titleBar, backgroundHeight + backgroundOffset)

	return self
end
