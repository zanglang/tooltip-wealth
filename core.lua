
if not TinyTip then return end

local name = "TinyTipWealth"
local module = TinyTip:NewModule(name)
module.ready = false
module.unit = nil

function module:INSPECT_ACHIEVEMENT_READY(event)
	-- print("INSPECT_ACHIEVEMENT_READY")
	module:UnregisterEvent("INSPECT_ACHIEVEMENT_READY")
	
	-- "11115|TInterface\MoneyFrame\UI-GoldIcon:0:0:2:0|t 89|TInterface\\MoneyFrame\\UI-SilverIcon:0:0:2:0|t 17|TInterface\\MoneyFrame\\UI-CopperIcon:0:0:2:0|t"
	-- "44|TInterface\\MoneyFrame\\UI-SilverIcon:0:0:2:0|t 64|TInterface\\MoneyFrame\\UI-CopperIcon:0:0:2:0|t"
	-- "15|TInterface\MoneyFrame\UI-SilverIcon:0:0:2:0|t 0|TInterface\MoneyFrame\UI-CopperIcon:0:0:2:0|t"
	-- "0|TInterface\\MoneyFrame\\UI-CopperIcon:0:0:2:0|t"
	-- "--"
	-- local pattern = {["|TInterface\\MoneyFrame\\UI-GoldIcon:0:0:2:0|t"] = "g",["|TInterface\\MoneyFrame\\UI-SilverIcon:0:0:2:0|t"] = "s",["|TInterface\\MoneyFrame\\UI-CopperIcon:0:0:2:0|t"] = "c"}
	-- local str = string.gsub(GetComparisonStatistic(328), "|TInterface\\MoneyFrame\\UI%-%a+Icon:0:0:2:0|t", pattern)
	
	_G.GameTooltip:AddLine("Wealth: ".. GetComparisonStatistic(334))
	_G.GameTooltip:Show()
	module.ready = true
end

function module:InspectUnit(unit)
	if not UnitExists("mouseover") or not UnitIsPlayer("mouseover") then return end
	
	-- print("mouseovered ".. UnitName("mouseover"))
	if module.ready then
		ClearAchievementComparisonUnit()
		SetAchievementComparisonUnit("mouseover")
		module:RegisterEvent("INSPECT_ACHIEVEMENT_READY")
		module.unit = UnitName("mouseover")
		module.ready = false
	end
end

function module:ADDON_LOADED()
	TinyTip.HookOnTooltipSetUnit(_G.GameTooltip, module.InspectUnit)
	module.ready = true
end

module:RegisterEvent("ADDON_LOADED")
-- module:RegisterEvent("UPDATE_MOUSEOVER_UNIT")
module:RegisterEvent("INSPECT_ACHIEVEMENT_READY")
