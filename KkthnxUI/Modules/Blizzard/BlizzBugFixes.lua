local K, C = unpack(select(2, ...))
local Module = K:NewModule("BlizzardFixes", "AceEvent-3.0", "AceHook-3.0")

local _G = _G

local collectgarbage = _G.collectgarbage
local CreateFrame = _G.CreateFrame
local PVPReadyDialog = _G.PVPReadyDialog
local ShowUIPanel, HideUIPanel = _G.ShowUIPanel, _G.HideUIPanel
local StaticPopupDialogs = _G.StaticPopupDialogs
local UpdateAddOnMemoryUsage = _G.UpdateAddOnMemoryUsage

local blizzardCollectgarbage = collectgarbage

-- Garbage collection is being overused and misused,
-- and it"s causing lag and performance drops.
blizzardCollectgarbage("setpause", 110)
blizzardCollectgarbage("setstepmul", 200)
function Module:CollectGarbage(opt, arg)
	if (opt == "collect") or (opt == nil) then
	elseif (opt == "count") then
		return blizzardCollectgarbage(opt, arg)
	elseif (opt == "setpause") then
		return blizzardCollectgarbage("setpause", 110)
	elseif opt == "setstepmul" then
		return blizzardCollectgarbage("setstepmul", 200)
	elseif (opt == "stop") then
	elseif (opt == "restart") then
	elseif (opt == "step") then
		if (arg ~= nil) then
			if (arg <= 10000) then
				return blizzardCollectgarbage(opt, arg)
			end
		else
			return blizzardCollectgarbage(opt, arg)
		end
	else
		return blizzardCollectgarbage(opt, arg)
	end
end

-- Memory usage is unrelated to performance, and tracking memory usage does not track "bad" addons.
-- Developers can uncomment this line to enable the functionality when looking for memory leaks,
-- but for the average end-user this is a completely pointless thing to track.
UpdateAddOnMemoryUsage = function() end

-- Misclicks for some popups
function Module:MisclickPopups()
	StaticPopupDialogs.RESURRECT.hideOnEscape = false
	StaticPopupDialogs.AREA_SPIRIT_HEAL.hideOnEscape = false
	StaticPopupDialogs.PARTY_INVITE.hideOnEscape = false
	StaticPopupDialogs.CONFIRM_SUMMON.hideOnEscape = false
	StaticPopupDialogs.ADDON_ACTION_FORBIDDEN.button1 = false
	StaticPopupDialogs.TOO_MANY_LUA_ERRORS.button1 = false
	StaticPopupDialogs.DELETE_ITEM.enterClicksFirstButton = true
	StaticPopupDialogs.DELETE_GOOD_ITEM = StaticPopupDialogs.DELETE_ITEM
	StaticPopupDialogs.CONFIRM_PURCHASE_TOKEN_ITEM.enterClicksFirstButton = true
	PetBattleQueueReadyFrame.hideOnEscape = false
	if (PVPReadyDialog) then
		PVPReadyDialog.leaveButton:Hide()
		PVPReadyDialog.enterButton:ClearAllPoints()
		PVPReadyDialog.enterButton:SetPoint("BOTTOM", PVPReadyDialog, "BOTTOM", 0, 25)
		PVPReadyDialog.label:SetPoint("TOP", 0, -22)
	end
end

-- Fix blank tooltip
local bug = nil
function Module:FixTooltip()
	if GameTooltip:IsShown() then
		bug = true
	end
end

function Module:BAG_UPDATE_DELAYED()
	if StuffingFrameBags and StuffingFrameBags:IsShown() then
		if GameTooltip:IsShown() then
			bug = true
		end
	end
end

function Module:BugTooltipCleared(tt)
	if tt:IsForbidden() then
		return
	end

	if bug and tt:NumLines() == 0 then
		tt:Hide()
		bug = false
	end
end

function Module:OnEnable()
	self:CollectGarbage()
	self:MisclickPopups()

	self:RegisterEvent("UPDATE_BONUS_ACTIONBAR", "FixTooltip")
	self:RegisterEvent("ACTIONBAR_PAGE_CHANGED", "FixTooltip")
	self:RegisterEvent("BAG_UPDATE_DELAYED")

	self:SecureHookScript(GameTooltip, "OnTooltipCleared", "BugTooltipCleared")

	-- Fix spellbook taint
	ShowUIPanel(SpellBookFrame)
	HideUIPanel(SpellBookFrame)

	CreateFrame("Frame"):SetScript("OnUpdate", function(self)
		if LFRBrowseFrame.timeToClear then
			LFRBrowseFrame.timeToClear = nil
		end
	end)
end