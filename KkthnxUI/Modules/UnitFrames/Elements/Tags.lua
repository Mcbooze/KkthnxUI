local K, C, L = unpack(select(2, ...))
if C["Unitframe"].Enable ~= true and C["Raidframe"].Enable ~= true and C["Nameplates"].Enable ~= true then
	return
end

local oUF = oUF or K.oUF

if not oUF then
	K.Print("Could not find a vaild instance of oUF. Tags.lua code!")
	return
end

-- Lua API
local _G = _G
local math_floor = math.floor
local string_format = string.format
local string_gsub = string.gsub
local string_len = string.len

-- Wow API
local C_PetJournal_GetPetTeamAverageLevel = C_PetJournal.GetPetTeamAverageLevel
local DEAD = _G.DEAD
local DEFAULT_AFK_MESSAGE = _G.DEFAULT_AFK_MESSAGE
local GetLocale = _G.GetLocale
local GetPVPTimer = _G.GetPVPTimer
local GetQuestGreenRange = _G.GetQuestGreenRange
local GetRelativeDifficultyColor = _G.GetRelativeDifficultyColor
local GetSpellInfo = _G.GetSpellInfo
local GetThreatStatusColor = _G.GetThreatStatusColor
local GHOST = GetLocale() == "deDE" and "Geist" or GetSpellInfo(8326)
local IsInGroup = _G.IsInGroup
local ORANGE_FONT_COLOR_CODE = _G.ORANGE_FONT_COLOR_CODE
local PLAYER_OFFLINE = _G.PLAYER_OFFLINE
local QuestDifficultyColors = _G.QuestDifficultyColors
local RED_FONT_COLOR_CODE = _G.RED_FONT_COLOR_CODE
local UnitBattlePetLevel = _G.UnitBattlePetLevel
local UnitClass = _G.UnitClass
local UnitClassification = _G.UnitClassification
local UnitDetailedThreatSituation = _G.UnitDetailedThreatSituation
local UnitEffectiveLevel = _G.UnitEffectiveLevel
local UnitExists = _G.UnitExists
local UnitGroupRolesAssigned = _G.UnitGroupRolesAssigned
local UnitHealth = _G.UnitHealth
local UnitHealthMax = _G.UnitHealthMax
local UnitIsAFK = _G.UnitIsAFK
local UnitIsBattlePetCompanion = _G.UnitIsBattlePetCompanion
local UnitIsConnected = _G.UnitIsConnected
local UnitIsDead = _G.UnitIsDead
local UnitIsFriend = _G.UnitIsFriend
local UnitIsGhost = _G.UnitIsGhost
local UnitIsPlayer = _G.UnitIsPlayer
local UnitIsPVP = _G.UnitIsPVP
local UnitIsPVPFreeForAll = _G.UnitIsPVPFreeForAll
local UnitIsUnit = _G.UnitIsUnit
local UnitIsWildBattlePet = _G.UnitIsWildBattlePet
local UnitLevel = _G.UnitLevel
local UnitName = _G.UnitName
local UNITNAME_SUMMON_TITLE17 = _G.UNITNAME_SUMMON_TITLE17
local UnitPower = _G.UnitPower
local UnitPowerMax = _G.UnitPowerMax
local UnitPowerType = _G.UnitPowerType
local UnitPrestige = _G.UnitPrestige
local UnitReaction = _G.UnitReaction
local UNKNOWN = _G.UNKNOWN

-- GLOBALS: Hex, _TAGS

local function UnitName(unit)
	local name, realm = _G.UnitName(unit)
	if name == UNKNOWN and K.Class == "MONK" and UnitIsUnit(unit, "pet") then
		name = UNITNAME_SUMMON_TITLE17:format(UnitName("player"))
	else
		return name, realm
	end
end

local function GetPvPStatus(unit)
	local prestige = UnitPrestige(unit)
	local status
	local color

	if (UnitIsPVPFreeForAll(unit)) then
		status = "FFA"
		color = ORANGE_FONT_COLOR_CODE
	elseif (UnitIsPVP(unit)) then
		status = "PvP"
		color = RED_FONT_COLOR_CODE
	end

	if (status) then
		if (prestige and prestige > 0) then
			status = string_format("%s %d", status, prestige)
		end

		return string_format("%s%s|r", color, status)
	end
end

local GetPVPTimer = GetPVPTimer
local pvpElapsed = 0
local function UpdatePvPTimer(self, elapsed)
	pvpElapsed = pvpElapsed + elapsed
	if (pvpElapsed > 0.5) then
		pvpElapsed = 0
		local timer = GetPVPTimer() / 1000
		if (timer > 0 and timer < 300) then
			self.PvP:SetText(string_format("%d:%02d", math_floor(timer / 60), timer % 60))
		end
	end
end

-- KkthnxUI Unitframe Tags
oUF.Tags.Events["KkthnxUI:GetNameColor"] = "UNIT_NAME_UPDATE"
oUF.Tags.Methods["KkthnxUI:GetNameColor"] = function(unit)
	local unitReaction = UnitReaction(unit, "player")
	local _, unitClass = UnitClass(unit)
	if (UnitIsPlayer(unit)) then
		local class = K.Colors.class[unitClass]
		if not class then
			return nil
		end
		return Hex(class[1], class[2], class[3])
	elseif (unitReaction) then
		local reaction = K.Colors.reaction[unitReaction]
		return Hex(reaction[1], reaction[2], reaction[3])
	else
		return Hex(255/255, 255/255, 255/255)
	end
end

oUF.Tags.Events["KkthnxUI:AltPowerCurrent"] = "UNIT_POWER_UPDATE UNIT_MAXPOWER"
oUF.Tags.Methods["KkthnxUI:AltPowerCurrent"] = function(unit)
	local cur = UnitPower(unit, 0)
	local max = UnitPowerMax(unit, 0)

	if (UnitPowerType(unit) ~= 0 and cur ~= max) then
		return math_floor(cur / max * 100)
	end
end

oUF.Tags.Methods["KkthnxUI:PvPStatus"] = GetPvPStatus
oUF.Tags.Events["KkthnxUI:PvPStatus"] = "UNIT_FACTION HONOR_PRESTIGE_UPDATE"
function K.CreatePvPText(self, unit)
	self.PvP = self:CreateFontString(nil, "OVERLAY")
	self.PvP:SetFont(C["Media"].Font, 10, "")
	self.PvP:SetPoint("BOTTOM", self.Portrait, "BOTTOM", 0, 0)
	self.PvP:SetTextColor(0.69, 0.31, 0.31)
	self.PvP:SetShadowOffset(1.25, -1.25)
	self:Tag(self.PvP, "[KkthnxUI:PvPStatus]")
	if (unit == "player") then
		self:HookScript("OnEnter", function()
			if (UnitIsPVP("player")) then
				self:SetScript("OnUpdate", UpdatePvPTimer)
			end
		end)
		self:HookScript("OnLeave", function()
			self:SetScript("OnUpdate", nil)
			self.PvP:UpdateTag()
		end)
	end
end

oUF.Tags.Events["KkthnxUI:DifficultyColor"] = "UNIT_LEVEL PLAYER_LEVEL_UP"
oUF.Tags.Methods["KkthnxUI:DifficultyColor"] = function(unit)
	local r, g, b
	if (UnitIsWildBattlePet(unit) or UnitIsBattlePetCompanion(unit)) then
		local level = UnitBattlePetLevel(unit)

		local teamLevel = C_PetJournal_GetPetTeamAverageLevel()
		if teamLevel < level or teamLevel > level then
			local c = GetRelativeDifficultyColor(teamLevel, level)
			r, g, b = c.r, c.g, c.b
		else
			local c = QuestDifficultyColors["difficult"]
			r, g, b = c.r, c.g, c.b
		end
	else
		local DiffColor = UnitLevel(unit) - UnitLevel("player")
		if (DiffColor >= 5) then
			r, g, b = 0.69, 0.31, 0.31
		elseif (DiffColor >= 3) then
			r, g, b = 0.71, 0.43, 0.27
		elseif (DiffColor >= -2) then
			r, g, b = 0.84, 0.75, 0.65
		elseif (-DiffColor <= GetQuestGreenRange()) then
			r, g, b = 0.33, 0.59, 0.33
		else
			r, g, b = 0.55, 0.57, 0.61
		end
	end

	return Hex(r, g, b)
end

oUF.Tags.Events["KkthnxUI:ClassificationColor"] = "UNIT_CLASSIFICATION_CHANGED"
oUF.Tags.Methods["KkthnxUI:ClassificationColor"] = function(unit)
	local classification = UnitClassification(unit)
	if (classification == "rare" or classification == "elite") then
		return Hex(0.69, 0.31, 0.31) -- Red
	elseif (classification == "rareelite" or classification == "worldboss") then
		return Hex(0.69, 0.31, 0.31) -- Red
	end
end

oUF.Tags.Events["KkthnxUI:HealthCurrent"] = "UNIT_HEALTH_FREQUENT UNIT_MAXHEALTH UNIT_CONNECTION PLAYER_FLAGS_CHANGED"
oUF.Tags.Methods["KkthnxUI:HealthCurrent"] = function(unit)
	local status = UnitIsDead(unit) and "|cffFFFFFF"..DEAD.."|r" or UnitIsGhost(unit) and "|cffFFFFFF"..GHOST.."|r" or not UnitIsConnected(unit) and "|cffFFFFFF"..PLAYER_OFFLINE.."|r"
	if (status) then
		return status
	else
		return K.GetFormattedText("CURRENT", UnitHealth(unit), UnitHealthMax(unit))
	end
end

oUF.Tags.Events["KkthnxUI:HealthPercent"] = "UNIT_HEALTH_FREQUENT UNIT_MAXHEALTH UNIT_CONNECTION PLAYER_FLAGS_CHANGED"
oUF.Tags.Methods["KkthnxUI:HealthPercent"] = function(unit)
	local status = UnitIsDead(unit) and "|cffFFFFFF"..DEAD.."|r" or UnitIsGhost(unit) and "|cffFFFFFF"..GHOST.."|r" or not UnitIsConnected(unit) and "|cffFFFFFF"..PLAYER_OFFLINE.."|r"
	if (status) then
		return status
	else
		return K.GetFormattedText("PERCENT", UnitHealth(unit), UnitHealthMax(unit))
	end
end

oUF.Tags.Events["KkthnxUI:HealthCurrent-Percent"] = "UNIT_HEALTH_FREQUENT UNIT_MAXHEALTH UNIT_CONNECTION PLAYER_FLAGS_CHANGED"
oUF.Tags.Methods["KkthnxUI:HealthCurrent-Percent"] = function(unit)
	local status = UnitIsDead(unit) and "|cffFFFFFF"..DEAD.."|r" or UnitIsGhost(unit) and "|cffFFFFFF"..GHOST.."|r" or not UnitIsConnected(unit) and "|cffFFFFFF"..PLAYER_OFFLINE.."|r"
	if (status) then
		return status
	else
		return K.GetFormattedText("CURRENT_PERCENT", UnitHealth(unit), UnitHealthMax(unit))
	end
end

oUF.Tags.Events["KkthnxUI:HealthDeficit"] = "UNIT_HEALTH_FREQUENT UNIT_MAXHEALTH UNIT_CONNECTION PLAYER_FLAGS_CHANGED"
oUF.Tags.Methods["KkthnxUI:HealthDeficit"] = function(unit)
	local status = UnitIsDead(unit) and "|cffFFFFFF"..DEAD.."|r" or UnitIsGhost(unit) and "|cffFFFFFF"..GHOST.."|r" or not UnitIsConnected(unit) and "|cffFFFFFF"..PLAYER_OFFLINE.."|r"
	if (status) then
		return status
	else
		return K.GetFormattedText("DEFICIT", UnitHealth(unit), UnitHealthMax(unit))
	end
end

oUF.Tags.Events["KkthnxUI:PowerCurrent"] = "UNIT_DISPLAYPOWER UNIT_POWER_FREQUENT UNIT_MAXPOWER"
oUF.Tags.Methods["KkthnxUI:PowerCurrent"] = function(unit)
	local pType = UnitPowerType(unit)
	local min = UnitPower(unit, pType)

	return min == 0 and nil or K.GetFormattedText("CURRENT", min, UnitPowerMax(unit, pType))
end

oUF.Tags.Events["KkthnxUI:Level"] = "UNIT_LEVEL PLAYER_LEVEL_UP"
oUF.Tags.Methods["KkthnxUI:Level"] = function(unit)
	if (UnitClassification(unit) == "worldboss") then
		return
	end

	local level = UnitBattlePetLevel(unit)
	if (not level or level == 0) then
		level = UnitEffectiveLevel(unit)
	end

	if (level == UnitEffectiveLevel("player")) then
		return
	end

	if (level < 0) then
		return "??"
	end

	return level
end

oUF.Tags.Events["KkthnxUI:SmartLevel"] = "UNIT_LEVEL PLAYER_LEVEL_UP"
oUF.Tags.Methods["KkthnxUI:SmartLevel"] = function(unit)
	if not UnitExists(unit) then
		return
	end

	local level = UnitLevel(unit)
	if (UnitIsWildBattlePet(unit) or UnitIsBattlePetCompanion(unit)) then
		return UnitBattlePetLevel(unit)
	elseif level == UnitLevel("player") then
		return nil
	elseif(level > 0) then
		return level
	else
		return "??"
	end
end

oUF.Tags.Events["KkthnxUI:NameRaidShort"] = "UNIT_NAME_UPDATE"
oUF.Tags.Methods["KkthnxUI:NameRaidShort"] = function(unit)
	local NameRaidShort = UnitName(unit) or UNKNOWN
	return NameRaidShort ~= nil and K.ShortenString(NameRaidShort, 5, true) or ""
end

oUF.Tags.Events["KkthnxUI:NameVeryShort"] = "UNIT_NAME_UPDATE"
oUF.Tags.Methods["KkthnxUI:NameVeryShort"] = function(unit)
	local NameVeryShort = UnitName(unit) or UNKNOWN
	return NameVeryShort ~= nil and K.ShortenString(NameVeryShort, 6, true) or ""
end

oUF.Tags.Events["KkthnxUI:NameShort"] = "UNIT_NAME_UPDATE"
oUF.Tags.Methods["KkthnxUI:NameShort"] = function(unit)
	local NameShort = UnitName(unit) or UNKNOWN
	return NameShort ~= nil and K.ShortenString(NameShort, 11, true) or ""
end

oUF.Tags.Events["KkthnxUI:NameMedium"] = "UNIT_NAME_UPDATE"
oUF.Tags.Methods["KkthnxUI:NameMedium"] = function(unit)
	local NameMedium = UnitName(unit) or UNKNOWN
	return NameMedium ~= nil and K.ShortenString(NameMedium, 16, true) or ""
end

oUF.Tags.Events["KkthnxUI:NameMediumAbbrev"] = "UNIT_NAME_UPDATE"
oUF.Tags.Methods["KkthnxUI:NameMediumAbbrev"] = function(unit)
	local NameMediumAbbrev = UnitName(unit) or UNKNOWN
	local newname = (string_len(NameMediumAbbrev) > 16) and string_gsub(NameMediumAbbrev, "%s?(.[\128-\191]*)%S+%s", "%1. ") or NameMediumAbbrev
	return K.ShortenString(newname, 16, false)
end

oUF.Tags.Events["KkthnxUI:NameLong"] = "UNIT_NAME_UPDATE"
oUF.Tags.Methods["KkthnxUI:NameLong"] = function(unit)
	local NameLong = UnitName(unit) or UNKNOWN
	return NameLong ~= nil and K.ShortenString(NameLong, 20, true) or ""
end

oUF.Tags.Events["KkthnxUI:NameLongAbbrev"] = "UNIT_NAME_UPDATE"
oUF.Tags.Methods["KkthnxUI:NameLongAbbrev"] = function(unit)
	local NameLongAbbrev = UnitName(unit) or UNKNOWN
	local newname = (string_len(NameLongAbbrev) > 20) and string_gsub(NameLongAbbrev, "%s?(.[\128-\191]*)%S+%s", "%1. ") or NameLongAbbrev
	return K.ShortenString(newname, 20, false)
end

oUF.Tags.Events["KkthnxUI:AFK"] = "PLAYER_FLAGS_CHANGED"
oUF.Tags.Methods["KkthnxUI:AFK"] = function(unit)
	local isAFK = UnitIsAFK(unit)
	if isAFK then
		return ("|cffFFFFFF[|r|cffFF0000%s|r|cFFFFFFFF]|r"):format(DEFAULT_AFK_MESSAGE)
	else
		return nil
	end
end

oUF.Tags.Events["KkthnxUI:GroupRole"] = "GROUP_ROSTER_UPDATE PLAYER_ROLES_ASSIGNED ROLE_CHANGED_INFORM"
oUF.Tags.Methods["KkthnxUI:GroupRole"] = function(unit)
	local role = UnitGroupRolesAssigned(unit)
	local roleString = ""

	if role == "TANK" then
		roleString = "|cff0099CCTank|r"
	elseif role == "HEALER" then
		roleString = "|cff00FF00Heal|r"
	end

	return roleString
end

oUF.Tags.Events["KkthnxUI:RaidRole"] = "GROUP_ROSTER_UPDATE PLAYER_ROLES_ASSIGNED ROLE_CHANGED_INFORM"
oUF.Tags.Methods["KkthnxUI:RaidRole"] = function(unit)
	local role = UnitGroupRolesAssigned(unit)
	local roleString = ""

	if role then
		if role == "TANK" then
			roleString = "|cff0099CCT|r"
		elseif role == "HEALER" then
			roleString = "|cff00FF00H|r"
		end

		return roleString
	end
end

-- Raid Tags
oUF.Tags.Events["KkthnxUI:RaidStatus"] = "UNIT_MAXHEALTH UNIT_HEALTH_FREQUENT UNIT_CONNECTION"
oUF.Tags.Methods["KkthnxUI:RaidStatus"] = function(unit)
	local Offline = not UnitIsConnected(unit) and "offline"
	if Offline then return Offline end

	local Dead = (UnitIsDead(unit) and "dead") or (UnitIsGhost(unit) and "ghost")
	if Dead then return Dead end

	local MaxHealth = UnitHealthMax(unit)
	local CurrentHealth = UnitHealth(unit)

	if CurrentHealth == MaxHealth or CurrentHealth == 0 or MaxHealth == 0 then
		return
	elseif UnitIsFriend("player", unit) then
		return "-"..K.ShortValue(MaxHealth - CurrentHealth)
	else
		return string_format("%.1f", CurrentHealth / MaxHealth * 100).."%"
	end
end

-- Nameplate Tags
oUF.Tags.Events["KkthnxUI:NameplateLevel"] = "UNIT_LEVEL PLAYER_LEVEL_UP"
oUF.Tags.Methods["KkthnxUI:NameplateLevel"] = function(unit)
	if not UnitExists(unit) then
		return
	end

	local level = UnitEffectiveLevel(unit)
	if (UnitIsWildBattlePet(unit) or UnitIsBattlePetCompanion(unit)) then
		return UnitBattlePetLevel(unit)
	elseif (level > 0) then
		return level
	else
		return "??"
	end
end

oUF.Tags.Events["KkthnxUI:NameplateSmartLevel"] = "UNIT_LEVEL PLAYER_LEVEL_UP"
oUF.Tags.Methods["KkthnxUI:NameplateSmartLevel"] = function(unit)
	if not UnitExists(unit) then
		return
	end

	local level = UnitLevel(unit)
	if (UnitIsWildBattlePet(unit) or UnitIsBattlePetCompanion(unit)) then
		return UnitBattlePetLevel(unit)
	elseif level == UnitLevel("player") then
		return nil
	elseif (level > 0) then
		return level
	else
		return "??"
	end
end

oUF.Tags.Events["KkthnxUI:NameplateNameColor"] = "UNIT_POWER_UPDATE UNIT_FLAGS"
oUF.Tags.Methods["KkthnxUI:NameplateNameColor"] = function(unit)
	local reaction = UnitReaction(unit, "player")
	local r, g, b = 0.33, 0.59, 0.33
	if not UnitIsUnit("player", unit) and UnitIsPlayer(unit) and (reaction and reaction >= 5) then
		local color = K.Colors.power["MANA"]
		return string_format("|cff%02x%02x%02x", color[1] * 255, color[2] * 255, color[3] * 255)
	elseif UnitIsPlayer(unit) then
		return _TAGS["raidcolor"](unit)
	elseif reaction then
		local color = K.Colors.reaction[reaction]
		return string_format("|cff%02x%02x%02x", color[1] * 255, color[2] * 255, color[3] * 255)
	else
		return string_format("|cff%02x%02x%02x", r * 255, g * 255, b * 255)
	end
end

oUF.Tags.Events["KkthnxUI:NameplateHealth"] = "UNIT_HEALTH_FREQUENT UNIT_MAXHEALTH NAME_PLATE_UNIT_ADDED"
oUF.Tags.Methods["KkthnxUI:NameplateHealth"] = function(unit)
	return K.GetFormattedText("CURRENT_PERCENT", UnitHealth(unit), UnitHealthMax(unit))
end

oUF.Tags.Events["KkthnxUI:NameplateThreatColor"] = "UNIT_THREAT_LIST_UPDATE"
oUF.Tags.Methods["KkthnxUI:NameplateThreatColor"] = function(unit)
	local _, status = UnitDetailedThreatSituation("player", unit)
	if (status) and (IsInGroup() or UnitExists("pet")) then
		return Hex(GetThreatStatusColor(status))
	else
		return nil
	end
end

oUF.Tags.Events["KkthnxUI:NameplateThreat"] = "UNIT_THREAT_LIST_UPDATE"
oUF.Tags.Methods["KkthnxUI:NameplateThreat"] = function(unit)
	local _, _, percent = UnitDetailedThreatSituation("player", unit)
	if (percent and percent > 0) and (IsInGroup() or UnitExists("pet")) then
		return string_format("%.0f%%", percent)
	else
		return nil
	end
end
