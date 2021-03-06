local K, C, L = unpack(select(2, ...))
if C["ActionBar"].Enable ~= true then return end

-- Lua API
local _G = _G
local string_gsub = string.gsub

-- Wow API
local GetFlyoutID = _G.GetFlyoutID
local GetFlyoutInfo = _G.GetFlyoutInfo
local GetNumFlyouts = _G.GetNumFlyouts
local hooksecurefunc = _G.hooksecurefunc
local InCombatLockdown = _G.InCombatLockdown
local NUM_PET_ACTION_SLOTS = _G.NUM_PET_ACTION_SLOTS
local NUM_STANCE_SLOTS = _G.NUM_STANCE_SLOTS

-- Global variables that we don't cache, list them here for mikk's FindGlobals script
-- GLOBALS: SpellFlyout, RightBarMouseOver, ActionButton_UpdateState, KEY_MOUSEWHEELDOWN
-- GLOBALS: KEY_MOUSEWHEELUP, KEY_BUTTON3, KEY_BUTTON4, KEY_BUTTON5, KEY_NUMPAD0, KEY_NUMPAD1
-- GLOBALS: KEY_NUMPAD2, KEY_NUMPAD3, KEY_NUMPAD4, KEY_NUMPAD5, KEY_NUMPAD6, KEY_NUMPAD7
-- GLOBALS: KEY_NUMPAD8, KEY_NUMPAD9, KEY_NUMPADDECIMAL, KEY_NUMPADDIVIDE, KEY_NUMPADMINUS
-- GLOBALS: KEY_NUMPADMULTIPLY, KEY_NUMPADPLUS, KEY_PAGEUP, KEY_PAGEDOWN, KEY_SPACE, KEY_INSERT
-- GLOBALS: KEY_HOME, KEY_DELETE, KEY_INSERT_MAC, SpellFlyoutHorizontalBackground, SpellFlyoutVerticalBackground
-- GLOBALS: SpellFlyoutBackgroundEnd, ActionButton_HideOverlayGlow, ActionButton_UpdateHotkeys

local function StyleNormalButton(self)
	local name = self:GetName()
	local button = self
	local icon = _G[name.."Icon"]
	local count = _G[name.."Count"]
	local flash = _G[name.."Flash"]
	local hotkey = _G[name.."HotKey"]
	local border = _G[name.."Border"]
	local btname = _G[name.."Name"]
	local normal = _G[name.."NormalTexture"]
	local float = _G[name.."FloatingBG"]

	flash:SetTexture("")
	button:SetNormalTexture("")

	if float then
		float:Hide()
		float = K.Noop
	end

	count:ClearAllPoints()
	count:SetPoint("BOTTOMRIGHT", 0, 2)
	count:SetFont(C["Media"].Font, C["Media"].FontSize, C["Media"].FontStyle)
	count:SetShadowOffset(0, 0)

	if border and button.isSkinned then
		-- border:SetTexture("")
		if border:IsShown() then
			button:SetBackdropBorderColor(0.08, 0.70, 0)
		else
			button:SetBackdropBorderColor(C["Media"].BorderColor[1], C["Media"].BorderColor[2], C["Media"].BorderColor[3])
		end
	end


	if btname then
		if C["ActionBar"].Macro == true then
			btname:ClearAllPoints()
			btname:SetPoint("BOTTOM", 0, 2)
			btname:SetFont(C["Media"].Font, C["Media"].FontSize - 1, C["Media"].FontStyle)
			btname:SetShadowOffset(0, 0)
			btname:SetWidth(C["ActionBar"].ButtonSize)
		else
			btname:Kill()
		end
	end

	if C["ActionBar"].Hotkey == true then
		hotkey:ClearAllPoints()
		hotkey:SetPoint("TOPRIGHT", 0, -2)
		hotkey:SetFont(C["Media"].Font, C["Media"].FontSize, C["Media"].FontStyle)
		hotkey:SetShadowOffset(0, 0)
		hotkey:SetWidth(C["ActionBar"].ButtonSize - 1)
		hotkey.ClearAllPoints = K.Noop
		hotkey.SetPoint = K.Noop
	else
		hotkey:Kill()
	end

	if not button.isSkinned then
		if self:GetHeight() ~= C["ActionBar"].ButtonSize and not InCombatLockdown() and not name:match("ExtraAction") then
			self:SetSize(C["ActionBar"].ButtonSize, C["ActionBar"].ButtonSize)
		end
		button:SetTemplate("ActionButton", true)

		icon:SetTexCoord(0.1, 0.9, 0.1, 0.9)
		icon:SetAllPoints(button)

		button.isSkinned = true
	end

	if normal and button:GetChecked() then
		ActionButton_UpdateState(button)
	end

	if normal then
		normal:ClearAllPoints()
		normal:SetPoint("TOPLEFT")
		normal:SetPoint("BOTTOMRIGHT")
	end
end

local function StyleSmallButton(normal, button, icon, name, pet)
	local flash = _G[name.."Flash"]
	local hotkey = _G[name.."HotKey"]

	button:SetNormalTexture("")

	hooksecurefunc(button, "SetNormalTexture", function(self, texture)
		if texture and texture ~= "" then
			self:SetNormalTexture("")
		end
	end)

	flash:SetColorTexture(0.8, 0.8, 0.8, 0.5)
	flash:SetAllPoints(button)

	if C["ActionBar"].Hotkey == true then
		hotkey:ClearAllPoints()
		hotkey:SetPoint("TOPRIGHT", 0, -2)
		hotkey:SetFont(C["Media"].Font, C["Media"].FontSize, C["Media"].FontStyle)
		hotkey:SetWidth(C["ActionBar"].ButtonSize - 1)
		hotkey.ClearAllPoints = K.Noop
		hotkey.SetPoint = K.Noop
	else
		hotkey:Kill()
	end

	if not button.isSkinned then
		button:SetSize(C["ActionBar"].ButtonSize, C["ActionBar"].ButtonSize)
		button:SetTemplate("ActionButton", true)

		icon:SetTexCoord(0.1, 0.9, 0.1, 0.9)
		icon:ClearAllPoints()
		icon:SetAllPoints(button)

		if (pet) then
			local autocast = _G[name.."AutoCastable"]
			autocast:SetSize((C["ActionBar"].ButtonSize * 2) - 10, (C["ActionBar"].ButtonSize * 2) - 10)
			autocast:ClearAllPoints()
			autocast:SetPoint("CENTER", button, 0, 0)

			local shine = _G[name.."Shine"]
			shine:SetSize(C["ActionBar"].ButtonSize, C["ActionBar"].ButtonSize)

			local cooldown = _G[name.."Cooldown"]
			cooldown:SetSize(C["ActionBar"].ButtonSize - 2, C["ActionBar"].ButtonSize - 2)
		end
		button.isSkinned = true
	end

	if normal then
		normal:ClearAllPoints()
		normal:SetPoint("TOPLEFT")
		normal:SetPoint("BOTTOMRIGHT")
	end
end

function K.StyleShift()
	for i = 1, NUM_STANCE_SLOTS do
		local name = "StanceButton"..i
		local button = _G[name]
		local icon = _G[name.."Icon"]
		local normal = _G[name.."NormalTexture"]
		StyleSmallButton(normal, button, icon, name)
	end
end

function K.StylePet()
	for i = 1, NUM_PET_ACTION_SLOTS do
		local name = "PetActionButton"..i
		local button = _G[name]
		local icon = _G[name.."Icon"]
		local normal = _G[name.."NormalTexture2"]
		StyleSmallButton(normal, button, icon, name, true)
	end
end

local function UpdateHotkey(self, btype)
	local hotkey = _G[self:GetName().."HotKey"]
	local text = hotkey:GetText()
	local Indicator = _G["RANGE_INDICATOR"]

	if (not text) then
		return
	end

	text = string_gsub(text, "(s%-)", "S")
	text = string_gsub(text, "(a%-)", "A")
	text = string_gsub(text, "(c%-)", "C")
	text = string_gsub(text, KEY_MOUSEWHEELDOWN , "MDn")
	text = string_gsub(text, KEY_MOUSEWHEELUP , "MUp")
	text = string_gsub(text, KEY_BUTTON3, "M3")
	text = string_gsub(text, KEY_BUTTON4, "M4")
	text = string_gsub(text, KEY_BUTTON5, "M5")
	text = string_gsub(text, KEY_MOUSEWHEELUP, "MU")
	text = string_gsub(text, KEY_MOUSEWHEELDOWN, "MD")
	text = string_gsub(text, KEY_NUMPAD0, "N0")
	text = string_gsub(text, KEY_NUMPAD1, "N1")
	text = string_gsub(text, KEY_NUMPAD2, "N2")
	text = string_gsub(text, KEY_NUMPAD3, "N3")
	text = string_gsub(text, KEY_NUMPAD4, "N4")
	text = string_gsub(text, KEY_NUMPAD5, "N5")
	text = string_gsub(text, KEY_NUMPAD6, "N6")
	text = string_gsub(text, KEY_NUMPAD7, "N7")
	text = string_gsub(text, KEY_NUMPAD8, "N8")
	text = string_gsub(text, KEY_NUMPAD9, "N9")
	text = string_gsub(text, KEY_NUMPADDECIMAL, "N.")
	text = string_gsub(text, KEY_NUMPADDIVIDE, "N/")
	text = string_gsub(text, KEY_NUMPADMINUS, "N-")
	text = string_gsub(text, KEY_NUMPADMULTIPLY, "N*")
	text = string_gsub(text, KEY_NUMPADPLUS, "N+")
	text = string_gsub(text, KEY_PAGEUP, "PU")
	text = string_gsub(text, KEY_PAGEDOWN, "PD")
	text = string_gsub(text, KEY_SPACE, "SpB")
	text = string_gsub(text, KEY_INSERT, "Ins")
	text = string_gsub(text, KEY_HOME, "Hm")
	text = string_gsub(text, KEY_DELETE, "Del")
	text = string_gsub(text, KEY_INSERT_MAC, "Hlp") -- MAC

	if hotkey:GetText() == Indicator then
		hotkey:SetText("")
	else
		hotkey:SetText(text)
	end
end

local buttons = 0
local function SetupFlyoutButton()
	for i = 1, buttons do
		if _G["SpellFlyoutButton"..i] then
			StyleNormalButton(_G["SpellFlyoutButton"..i])
			_G["SpellFlyoutButton"..i]:StyleButton()

			if _G["SpellFlyoutButton"..i]:GetChecked() then
				_G["SpellFlyoutButton"..i]:SetChecked(false)
			end

			if C["ActionBar"].RightBarsMouseover == true then
				SpellFlyout:HookScript("OnEnter", function(self) RightBarMouseOver(1) end)
				SpellFlyout:HookScript("OnLeave", function(self) RightBarMouseOver(0) end)
				_G["SpellFlyoutButton"..i]:HookScript("OnEnter", function(self) RightBarMouseOver(1) end)
				_G["SpellFlyoutButton"..i]:HookScript("OnLeave", function(self) RightBarMouseOver(0) end)
			end
		end
	end
end
SpellFlyout:HookScript("OnShow", SetupFlyoutButton)

local function StyleFlyoutButton(self)
	if self.FlyoutBorder then
		self.FlyoutBorder:SetAlpha(0)
	end
	if self.FlyoutBorderShadow then
		self.FlyoutBorderShadow:SetAlpha(0)
	end

	SpellFlyoutHorizontalBackground:SetAlpha(0)
	SpellFlyoutVerticalBackground:SetAlpha(0)
	SpellFlyoutBackgroundEnd:SetAlpha(0)

	for i = 1, GetNumFlyouts() do
		local x = GetFlyoutID(i)
		local _, _, numSlots, isKnown = GetFlyoutInfo(x)
		if isKnown then
			if numSlots > buttons then
				buttons = numSlots
			end
		end
	end
end

local function HideHighlightButton(self)
	if self.overlay then
		self.overlay:Hide()
		ActionButton_HideOverlayGlow(self)
	end
end

do
	for i = 1, 12 do
		_G["ActionButton"..i]:StyleButton()
		_G["MultiBarBottomLeftButton"..i]:StyleButton()
		_G["MultiBarBottomRightButton"..i]:StyleButton()
		_G["MultiBarLeftButton"..i]:StyleButton()
		_G["MultiBarRightButton"..i]:StyleButton()
	end

	for i = 1, 10 do
		_G["StanceButton"..i]:StyleButton()
		_G["PetActionButton"..i]:StyleButton()
	end
end

hooksecurefunc("ActionButton_Update", StyleNormalButton)
hooksecurefunc("ActionButton_UpdateFlyout", StyleFlyoutButton)

if C["ActionBar"].Hotkey == true then
	hooksecurefunc("ActionButton_OnEvent", function(self, event, ...) if event == "PLAYER_ENTERING_WORLD" then ActionButton_UpdateHotkeys(self, self.buttonType) end end)
	hooksecurefunc("ActionButton_UpdateHotkeys", UpdateHotkey)
end

if C["ActionBar"].HideHightlight == true then
	hooksecurefunc("ActionButton_ShowOverlayGlow", HideHighlightButton)
end