--[[
	TinyTip Wealth v0.1 - by Jerry Chong. <zanglang@gmail.com>
	
	0.1 - Initial version
]]--

--------------------------------------------
-- Initializing and variables
--------------------------------------------

TinyTipWealth = CreateFrame("Frame")
TinyTipWealth:SetScript("OnEvent", function(self, event, ...)
	if self[event] then
		return self[event](self, event, ...)
	end
end)
TinyTipWealth:RegisterEvent("ADDON_LOADED")

local GameTooltip = _G.GameTooltip
local currentUnit = nil
local readyFlag = false
local cityFlag = false

local MOST_GOLD_OWNED = "334"
local TOTAL_GOLD_ACQUIRED = "328"

--------------------------------------------
-- DB Settings
--------------------------------------------

local defaults = {
	WealthType = MOST_GOLD_OWNED,
	DisableEnemyFaction = true,
	DisableInCombat = true,
	OnlyInCity = false,
	ShowCoins = true,
}
local db = defaults

local options = {
	type = "group",
	name = "TinyTipWealth",
	get = function(k) return TinyTipWealthDB[k.arg] end,
	set = function(k, v) TinyTipWealthDB[k.arg] = v end,
	args = {
		desc = {
			type = "description", order = 0,
			name = "Sneakily inspect how much gold your mouseover target has made so far.",
		},
		WealthType = {
			name = "Wealth type",
			desc = "Use this statistic for querying wealth",
			type = "select",
			values = {
				[TOTAL_GOLD_ACQUIRED] = "Total gold acquired",
				[MOST_GOLD_OWNED] = "Most gold ever owned"
			},
			arg = "WealthType",
			order = 1,
		},
		DisableEnemyFaction = {
			name = "Disable opposite faction",
			desc = "Disables checking opposite faction wealth even if friendly.",
			type = "toggle",
			arg = "DisableEnemyFaction",
			order = 2, width = "full",
		},
		DisableInCombat = {
			name = "Disable in combat",
			desc = "Disables wealth querying in combat.",
			type = "toggle",
			arg = "DisableInCombat",
			order = 3, width = "full",
		},
		OnlyInCity = {
			name = "Enable only in cities",
			desc = "Enable checking only when inside a major city.",
			type = "toggle",
			arg = "OnlyInCity",
			order = 4, width = "full",
		},
		ShowCoins = {
			name = "Show wealth as coins",
			desc = "Displays wealth with coin graphic if enabled. Formatted as plain text if disabled.",
			type = "toggle",
			arg = "ShowCoins",
			order = 5, width = "full",
		}
	}
}

--------------------------------------------
-- Tooltip Formatting and player inspecting
--------------------------------------------

local doubleLine = false
if TipTop or CowTip then
	doubleLine = true
end

local FormatMoneyPattern = {
	["|TInterface\\MoneyFrame\\UI-GoldIcon:0:0:2:0|t"] = "g",
	["|TInterface\\MoneyFrame\\UI-SilverIcon:0:0:2:0|t"] = "s",
	["|TInterface\\MoneyFrame\\UI-CopperIcon:0:0:2:0|t"] = "c"
}

function TinyTipWealth:INSPECT_ACHIEVEMENT_READY()
	-- print("INSPECT_ACHIEVEMENT_READY")
	
	if GameTooltip:GetUnit() == currentUnit then
		local money = GetComparisonStatistic(db.WealthType)
		if not db.ShowCoins then
			money = string.gsub(money, "|TInterface\\MoneyFrame\\UI%-%a+Icon:0:0:2:0|t", FormatMoneyPattern)
		end
		
		if not doubleLine then
			GameTooltip:AddLine("Wealth: " .. money)
		else
			GameTooltip:AddDoubleLine("Wealth: ", money)
		end
		GameTooltip:Show()
	-- else
		-- print("different unit")
	end
	currentUnit = nil
	readyFlag = true
end

local function InspectUnit(unit)
	if not UnitExists(unit) or not UnitIsPlayer(unit) or
			(db.DisableInCombat and InCombatLockdown()) or
			(db.DisableEnemyFaction and not UnitIsFriend("player", unit)) or
			(db.OnlyInCity and not cityFlag) then return end
	-- print("mouseovered ".. UnitName(unit))
	
	if readyFlag then
		ClearAchievementComparisonUnit()
		SetAchievementComparisonUnit(unit)
		currentUnit = UnitName(unit)
		readyFlag = false
	end
end

function TinyTipWealth:UPDATE_MOUSEOVER_UNIT()
	-- print("update mouseover")
	InspectUnit("mouseover")
end

--------------------------------------------
-- Events
--------------------------------------------

function TinyTipWealth:ZONE_CHANGED_NEW_AREA(event)
	local channels = {EnumerateServerChannels()}
	for _, chan in pairs(channels) do
		if chan == "Trade" then
			cityFlag = true
			return
		end
	end
	cityFlag = false
end

function TinyTipWealth:ADDON_LOADED(event, name)
	if name ~= "TinyTipWealth" then return end
	self:UnregisterEvent("ADDON_LOADED")
	
	TinyTipWealthDB = TinyTipWealthDB or {}
	db = TinyTipWealthDB
	for name, value in pairs(defaults) do
		if db[name] == nil then
			 db[name] = value
		end
	end
	LibStub("AceConfigRegistry-3.0"):RegisterOptionsTable("TinyTipWealth", options)
	LibStub("AceConfigDialog-3.0"):AddToBlizOptions("TinyTipWealth", "TinyTip Wealth")
	
	self:RegisterEvent("ZONE_CHANGED_NEW_AREA")
	self:RegisterEvent("INSPECT_ACHIEVEMENT_READY")	
	TinyTipWealth:ZONE_CHANGED_NEW_AREA()
	
	-- check for alternate tooltip addons
	if TinyTip then
		TinyTip.HookOnTooltipSetUnit(GameTooltip, InspectUnit)
	else
		self:RegisterEvent("UPDATE_MOUSEOVER_UNIT")
	end
	
	readyFlag = true
end
