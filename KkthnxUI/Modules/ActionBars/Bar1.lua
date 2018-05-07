local K, C, L = unpack(select(2, ...))
if C["ActionBar"].Enable ~= true then
	return
end

-- Sourced Old Tukui (Tukz)

-- Lua API
local _G = _G
local select = select

-- Wow API
local CreateFrame = _G.CreateFrame
local HasOverrideActionBar = _G.HasOverrideActionBar
local HasVehicleActionBar = _G.HasVehicleActionBar
local InCombatLockdown = _G.InCombatLockdown
local NUM_ACTIONBAR_BUTTONS = _G.NUM_ACTIONBAR_BUTTONS
local RegisterStateDriver = _G.RegisterStateDriver
local UnitClass = _G.UnitClass
local MainMenuBar_OnEvent = _G.MainMenuBar_OnEvent

-- Global variables that we don't cache, list them here for mikk's FindGlobals script
-- GLOBALS: ActionButton_Update

local PageDRUID, PageROGUE = "", ""

local ActionBar1 = CreateFrame("Frame", "Bar1Holder", ActionBarAnchor, "SecureHandlerStateTemplate")
ActionBar1:SetAllPoints(ActionBarAnchor)

for i = 1, 12 do
	local button = _G["ActionButton"..i]
	button:SetSize(C["ActionBar"].ButtonSize, C["ActionBar"].ButtonSize)

	button:ClearAllPoints()
	button:SetParent(Bar1Holder)
	if i == 1 then
		button:SetPoint("BOTTOMLEFT", Bar1Holder, 0, 0)
	else
		local previous = _G["ActionButton"..i - 1]
		button:SetPoint("LEFT", previous, "RIGHT", C["ActionBar"].ButtonSpace, 0)
	end
end

if (not C["ActionBar"].DisableStancePages) then
	PageROGUE = "[bonusbar:1] 7;"
	PageDRUID = "[bonusbar:1,nostealth] 7; [bonusbar:1,stealth] 8; [bonusbar:2] 8; [bonusbar:3] 9; [bonusbar:4] 10;"
end

local Page = {
	["DRUID"] = PageDRUID,
	["ROGUE"] = PageROGUE,
	["DEFAULT"] = "[vehicleui][possessbar] 12; [shapeshift] 13; [overridebar] 14; [bar:2] 2; [bar:3] 3; [bar:4] 4; [bar:5] 5; [bar:6] 6;",
}

local function GetBar(self, defaultPage)
	local condition = Page["DEFAULT"]
	local class = select(2, UnitClass("player"))
	local page = Page[class]

	if page then
		condition = condition.." "..page
	end

	condition = condition.." [form] 1; 1"

	return condition
end

ActionBar1:RegisterEvent("PLAYER_LOGIN")
ActionBar1:RegisterEvent("UPDATE_VEHICLE_ACTIONBAR")
ActionBar1:RegisterEvent("UPDATE_OVERRIDE_ACTIONBAR")
ActionBar1:RegisterEvent("CURRENCY_DISPLAY_UPDATE")
ActionBar1:SetScript("OnEvent", function(self, event, ...)
	if event == "PLAYER_LOGIN" then
		for i = 1, NUM_ACTIONBAR_BUTTONS do
			local button = _G["ActionButton"..i]
			self:SetFrameRef("ActionButton"..i, button)
		end

		self:Execute([[
		button = table.new()
		for i = 1, 12 do
			table.insert(button, self:GetFrameRef("ActionButton"..i))
		end
		]])

		self:SetAttribute("_onstate-page", [[
		if HasTempShapeshiftActionBar() then
			newstate = GetTempShapeshiftBarIndex() or newstate
		end

		for i, button in ipairs(button) do
			button:SetAttribute("actionpage", tonumber(newstate))
		end
		]])

		RegisterStateDriver(self, "page", GetBar())
	elseif event == "UPDATE_VEHICLE_ACTIONBAR" or event == "UPDATE_OVERRIDE_ACTIONBAR" then
		if not InCombatLockdown() and (HasVehicleActionBar() or HasOverrideActionBar()) then
			for i = 1, NUM_ACTIONBAR_BUTTONS do
				local button = _G["ActionButton"..i]
				ActionButton_Update(button)
			end
		end
	else
		-- MainMenuBar_OnEvent(self, event, ...)
	end
end)
