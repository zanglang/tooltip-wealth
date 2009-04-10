--[[
	TinyTip Wealth v0.1 - by Jerry Chong. <zanglang@gmail.com>
	
	0.1 - Initial version
]]--

--------------------------------------------
-- Initializing and variables
--------------------------------------------

if not TinyTip then return end
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

local MOST_GOLD_OWNED = "334"
local TOTAL_GOLD_ACQUIRED = "328"

--------------------------------------------
-- DB Settings
--------------------------------------------

local defaults = {
	WealthType = MOST_GOLD_OWNED,
	DisableEnemyFaction = true,
	DisableInCombat = true,
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
		ShowCoins = {
			name = "Show wealth as coins",
			desc = "Displays wealth with coin graphic if enabled. Formatted as plain text if disabled.",
			type = "toggle",
			arg = "ShowCoins",
			order = 4, width = "full",
		}
	}
}

--------------------------------------------
-- Tooltip Formatting and Display
--------------------------------------------

local FormatMoneyPattern = {
	["|TInterface\\MoneyFrame\\UI-GoldIcon:0:0:2:0|t"] = "g",
	["|TInterface\\MoneyFrame\\UI-SilverIcon:0:0:2:0|t"] = "s",
	["|TInterface\\MoneyFrame\\UI-CopperIcon:0:0:2:0|t"] = "c"
}

function TinyTipWealth:FormatMoney(money)
	if not db.ShowCoins then
		return string.gsub(money, "|TInterface\\MoneyFrame\\UI%-%a+Icon:0:0:2:0|t", FormatMoneyPattern)
	-- else
	end
	return money
end

function TinyTipWealth:INSPECT_ACHIEVEMENT_READY()
	-- print("INSPECT_ACHIEVEMENT_READY")
	if GameTooltip:GetUnit() == currentUnit then
		GameTooltip:AddLine("Wealth: ".. self:FormatMoney(GetComparisonStatistic(db.WealthType)))
		GameTooltip:Show()
	-- else
		-- print("different unit")
	end
	currentUnit = nil
	readyFlag = true
end

--------------------------------------------
-- Events
--------------------------------------------

local function TinyTipWealth_InspectUnit(unit)
	if not UnitExists(unit) or not UnitIsPlayer(unit) or
			(db.DisableInCombat and InCombatLockdown()) or
			(db.DisableEnemyFaction and not UnitIsFriend("player", unit)) then return end
	-- print("mouseovered ".. UnitName(unit))
	
	if readyFlag then
		ClearAchievementComparisonUnit()
		SetAchievementComparisonUnit(unit)
		currentUnit = UnitName(unit)
		readyFlag = false
	end
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
	
	self:RegisterEvent("INSPECT_ACHIEVEMENT_READY")
	TinyTip.HookOnTooltipSetUnit(GameTooltip, TinyTipWealth_InspectUnit)
	readyFlag = true
end
