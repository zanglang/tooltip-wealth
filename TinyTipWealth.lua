--[[
	Tooltip Wealth v0.3 - by Jerry Chong. <zanglang@gmail.com>
	
	0.1 - Initial version
	0.2 - Caching
	0.3 - Various bugfixes
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
local playerName = nil

local MOST_GOLD_OWNED = "334"
local TOTAL_GOLD_ACQUIRED = "328"
local AVG_EARNED_DAILY = "753"
local EVERYTHING = "ALL_THE_THINGS"

--------------------------------------------
-- DB Settings
--------------------------------------------

local defaults = {
	WealthType = MOST_GOLD_OWNED,
	DisableEnemyFaction = true,
	DisableInCombat = true,
	OnlyInCity = false,
	ShowCoins = true,
	Cache = { player = nil, money = 0 }
}
local db = defaults

local options = {
	type = "group",
	name = "ToolTipWealth",
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
				[TOTAL_GOLD_ACQUIRED] = "Total gold ever acquired",
				[MOST_GOLD_OWNED] = "Most gold ever owned",
				[AVG_EARNED_DAILY] = "Average gold earned/day"
				[EVERYTHING] = "All of above",
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

local function ShowTooltip(money)
	-- formatting/presentation
	if money:sub(1, 1) == "-" and money:sub(2, 2) ~= "-" then
		-- print("Money before calculate: " .. money)
		money = money:gsub("|TInterface\\MoneyFrame\\UI%-%a+Icon:0:0:2:0|t", "")
		-- calculate spillover
		local max = 2147483648
		money = math.abs(math.abs(money) - max) + max
		money = math.floor(money/10000) .. "|TInterface\\MoneyFrame\\UI-GoldIcon:0:0:2:0|t " ..
				math.floor(money%10000/100) .. "|TInterface\\MoneyFrame\\UI-SilverIcon:0:0:2:0|t " ..
				(money%100) .. "|TInterface\\MoneyFrame\\UI-CopperIcon:0:0:2:0|t"
	end
	if not db.ShowCoins then
		money = string.gsub(money, "|TInterface\\MoneyFrame\\UI%-%a+Icon:0:0:2:0|t", FormatMoneyPattern)
	end
	
	if not doubleLine then
		GameTooltip:AddLine("Wealth: " .. money)
	else
		GameTooltip:AddDoubleLine("Wealth: ", money)
	end
	GameTooltip:Show()
end

function TinyTipWealth:INSPECT_ACHIEVEMENT_READY()
	-- print("INSPECT_ACHIEVEMENT_READY")
	if GameTooltip:GetUnit() == currentUnit then
		local function Query(id)
			local money = GetComparisonStatistic(id)
			db.Cache.player = currentUnit
			db.Cache.money = money
			ShowTooltip(money)
		end
		if db.WealthType ~= 9999 then
			Query(db.WealthType)
		else
			Query(TOTAL_GOLD_ACQUIRED)
			Query(MOST_GOLD_OWNED)
			Query(AVG_EARNED_DAILY)
		end
	-- else
		-- print("different unit")
	end
	self:UnregisterEvent("INSPECT_ACHIEVEMENT_READY");
	if (AchievementFrameComparison) then
		AchievementFrameComparison:RegisterEvent("INSPECT_ACHIEVEMENT_READY")
	end
	ClearAchievementComparisonUnit()
	ClearInspectPlayer()
	currentUnit = nil
	readyFlag = true
end

function TinyTipWealth:InspectUnit(unit)
	if not UnitExists(unit) or not UnitIsPlayer(unit) or
			(db.DisableInCombat and InCombatLockdown()) or
			(db.DisableEnemyFaction and not UnitIsFriend("player", unit)) or
			(db.OnlyInCity and not cityFlag) then return end
	-- print("mouseovered ".. UnitName(unit))
	
	local unitName = UnitName(unit)
	if unitName == playerName then
		ShowTooltip(GetStatistic(db.WealthType))
		return
	end
	
	if not CheckInteractDistance(unit, 1) then
		ShowTooltip("too far")
		return
	elseif not CanInspect(unit) then
		ShowTooltip("not allowed")
		return
	end
	
	if db.Cache.player == unitName then
		ShowTooltip(db.Cache.money) -- cache hit
		return
	end
	
	if readyFlag then
		if (AchievementFrameComparison) then
			AchievementFrameComparison:UnregisterEvent("INSPECT_ACHIEVEMENT_READY")
		end
		self:RegisterEvent("INSPECT_ACHIEVEMENT_READY")
		SetAchievementComparisonUnit(unit)
		currentUnit = unitName
		-- print("request achievement comparison")
		readyFlag = false
	-- else
		-- print("not ready yet")
	end
end

function TinyTipWealth:UPDATE_MOUSEOVER_UNIT()
	-- print("update mouseover")
	TinyTipWealth:InspectUnit("mouseover")
end

--------------------------------------------
-- Events
--------------------------------------------

function TinyTipWealth:ZONE_CHANGED_NEW_AREA(event)
	if not readyFlag then
		readyFlag = true
	end
	
	self:UnregisterEvent("INSPECT_ACHIEVEMENT_READY");
	if (AchievementFrameComparison) then
		AchievementFrameComparison:RegisterEvent("INSPECT_ACHIEVEMENT_READY")
	end
	
	local channels = {EnumerateServerChannels()}
	for _, chan in pairs(channels) do
		if chan == "Trade" then
			-- print("In city")
			cityFlag = true
			return
		end
	end
	
	-- print("outside city")
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
	LibStub("AceConfigRegistry-3.0"):RegisterOptionsTable("ToolTipWealth", options)
	LibStub("AceConfigDialog-3.0"):AddToBlizOptions("ToolTipWealth", "Tooltip Wealth")
	
	self:RegisterEvent("ZONE_CHANGED_NEW_AREA")
	TinyTipWealth:ZONE_CHANGED_NEW_AREA()
	
	-- check for alternate tooltip addons
	if TinyTip then
		TinyTip.HookOnTooltipSetUnit(GameTooltip, TinyTipWealth.InspectUnit)
	else
		self:RegisterEvent("UPDATE_MOUSEOVER_UNIT")
	end
	
	readyFlag = true
	playerName = UnitName("player")
end
