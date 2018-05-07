local K, C, L = unpack(select(2, ...))
local Module = K:NewModule("Tooltip", "AceTimer-3.0", "AceHook-3.0", "AceEvent-3.0")

local _G = _G
local find = string.find
local math_floor = math.floor
local format = string.format
local pairs = pairs
local sub = string.sub
local select = select

local SetTooltipMoney = _G.SetTooltipMoney
local GameTooltip_ClearMoney = _G.GameTooltip_ClearMoney
local hooksecurefunc = _G.hooksecurefunc
local CanInspect = _G.CanInspect
local C_PetJournal_FindPetIDByName =_G.C_PetJournal.FindPetIDByName
local C_PetJournal_GetPetStats = _G.C_PetJournal.GetPetStats
local C_PetJournalGetPetTeamAverageLevel = _G.C_PetJournal.GetPetTeamAverageLevel
local CreateFrame = _G.CreateFrame
local CUSTOM_CLASS_COLORS = _G.CUSTOM_CLASS_COLORS
local DEAD = _G.DEAD
local FACTION_ALLIANCE = _G.FACTION_ALLIANCE
local FACTION_BAR_COLORS = _G.FACTION_BAR_COLORS
local FACTION_HORDE = _G.FACTION_HORDE
local FOREIGN_SERVER_LABEL = _G.FOREIGN_SERVER_LABEL
local GetAverageItemLevel = _G.GetAverageItemLevel
local GetCreatureDifficultyColor = _G.GetCreatureDifficultyColor
local GetDetailedItemLevelInfo = _G.GetDetailedItemLevelInfo
local GetGuildInfo = _G.GetGuildInfo
local GetInspectSpecialization = _G.GetInspectSpecialization
local GetInventoryItemLink = _G.GetInventoryItemLink
local GetInventorySlotInfo = _G.GetInventorySlotInfo
local GetItemCount = _G.GetItemCount
local GetItemInfo = _G.GetItemInfo
local GetItemQualityColor = _G.GetItemQualityColor
local GetMouseFocus = _G.GetMouseFocus
local GetRelativeDifficultyColor = _G.GetRelativeDifficultyColor
local GetSpecialization = _G.GetSpecialization
local GetSpecializationInfo = _G.GetSpecializationInfo
local GetSpecializationInfoByID = _G.GetSpecializationInfoByID
local GetSpecializationRoleByID = _G.GetSpecializationRoleByID
local GetTime = _G.GetTime
local ID = _G.ID
local INTERACTIVE_SERVER_LABEL = _G.INTERACTIVE_SERVER_LABEL
local IsShiftKeyDown = _G.IsShiftKeyDown
local LE_REALM_RELATION_COALESCED = _G.LE_REALM_RELATION_COALESCED
local LE_REALM_RELATION_VIRTUAL = _G.LE_REALM_RELATION_VIRTUAL
local LEVEL = _G.LEVEL
local PVP = _G.PVP
local RAID_CLASS_COLORS = _G.RAID_CLASS_COLORS
local SPECIALIZATION = _G.SPECIALIZATION
local STAT_AVERAGE_ITEM_LEVEL = _G.STAT_AVERAGE_ITEM_LEVEL
local TARGET = _G.TARGET
local UIParent = _G.UIParent
local UnitAura = _G.UnitAura
local UnitBattlePetLevel = _G.UnitBattlePetLevel
local UnitBattlePetType = _G.UnitBattlePetType
local UnitClass = _G.UnitClass
local UnitClassification = _G.UnitClassification
local UnitCreatureType = _G.UnitCreatureType
local UnitExists = _G.UnitExists
local UnitFactionGroup = _G.UnitFactionGroup
local UnitGUID = _G.UnitGUID
local UnitHasVehicleUI = _G.UnitHasVehicleUI
local UnitIsAFK = _G.UnitIsAFK
local UnitIsBattlePetCompanion = _G.UnitIsBattlePetCompanion
local UnitIsDeadOrGhost = _G.UnitIsDeadOrGhost
local UnitIsDND = _G.UnitIsDND
local UnitIsPlayer = _G.UnitIsPlayer
local UnitIsPVP = _G.UnitIsPVP
local UnitIsTapDenied = _G.UnitIsTapDenied
local UnitIsWildBattlePet = _G.UnitIsWildBattlePet
local UnitLevel = _G.UnitLevel
local UnitName = _G.UnitName
local UnitPVPName = _G.UnitPVPName
local UnitRace = _G.UnitRace
local UnitReaction = _G.UnitReaction
local UnitRealmRelationship = _G.UnitRealmRelationship
local NotifyInspect = _G.NotifyInspect

-- GLOBALS: GameTooltipAnchor, InspectFrame, GameTooltipTextLeft2, ItemRefTooltip, BNETMover, GameTooltipHeaderText, GameTooltipText
-- GLOBALS: GameTooltipTextSmall, ShoppingTooltip1TextLeft1, ShoppingTooltip1TextLeft2, ShoppingTooltip1TextLeft3, ShoppingTooltip1TextLeft4
-- GLOBALS: ShoppingTooltip1TextRight1, ShoppingTooltip1TextRight2, ShoppingTooltip1TextRight3, ShoppingTooltip1TextRight4, ShoppingTooltip2TextLeft1
-- GLOBALS: ShoppingTooltip2TextLeft2, ShoppingTooltip2TextLeft3, ShoppingTooltip2TextLeft4, ShoppingTooltip2TextRight1, ShoppingTooltip2TextRight2
-- GLOBALS: ShoppingTooltip2TextRight3, ShoppingTooltip2TextRight4, BNToastFrame, BNToastFrameCloseButton, ItemRefCloseButton, WorldMapTooltip

local GameTooltip, GameTooltipStatusBar = _G["GameTooltip"], _G["GameTooltipStatusBar"]
local targetList, inspectCache = {}, {}
local TAPPED_COLOR = {r = .6, g = .6, b = .6}
local AFK_LABEL = " |cffFFFFFF[|r|cffFF0000".."AFK".."|r|cffFFFFFF]|r"
local DND_LABEL = " |cffFFFFFF[|r|cffFFFF00".."DND".."|r|cffFFFFFF]|r"

local TooltipFont = K.GetFont(C["Tooltip"].Font)
local TooltipTexture = K.GetTexture(C["Tooltip"].Texture)

local tooltips = {
	GameTooltip,
	ItemRefTooltip,
	ItemRefShoppingTooltip1,
	ItemRefShoppingTooltip2,
	ItemRefShoppingTooltip3,
	AutoCompleteBox,
	FriendsTooltip,
	ShoppingTooltip1,
	ShoppingTooltip2,
	ShoppingTooltip3,
	WorldMapTooltip,
	WorldMapCompareTooltip1,
	WorldMapCompareTooltip2,
	WorldMapCompareTooltip3,
}

local ignoreSubType = {
	L["Tooltip"].Other == true,
	L["Tooltip"].Item_Enhancement == true,
}

local classification = {
	worldboss = format("|cffAF5050 %s|r", BOSS),
	rareelite = format("|cffAF5050+ %s|r", ITEM_QUALITY3_DESC),
	elite = "|cffAF5050+|r",
	rare = format("|cffAF5050 %s|r", ITEM_QUALITY3_DESC)
}

local SlotName = {
	"Head","Neck","Shoulder","Back","Chest","Wrist",
	"Hands","Waist","Legs","Feet","Finger0","Finger1",
	"Trinket0","Trinket1","MainHand","SecondaryHand"
}

function Module:GameTooltip_SetDefaultAnchor(tt, parent)
	if tt:IsForbidden() then return end
	if C["Tooltip"].Enable ~= true then return end

	if (tt:GetAnchorType() ~= "ANCHOR_NONE") then return end

	local ownerName = tt:GetOwner() and tt:GetOwner().GetName and tt:GetOwner():GetName()

	if (parent) then
		if (C["Tooltip"].CursorAnchor) then
			tt:SetOwner(parent, "ANCHOR_CURSOR")
			if (not GameTooltipStatusBar.anchoredToTop) then
				GameTooltipStatusBar:ClearAllPoints()
				GameTooltipStatusBar:SetPoint("BOTTOMLEFT", GameTooltip, "TOPLEFT", 0, 6)
				GameTooltipStatusBar:SetPoint("BOTTOMRIGHT", GameTooltip, "TOPRIGHT", -0, 6)
				GameTooltipStatusBar.text:SetPoint("CENTER", GameTooltipStatusBar, 0, 3)
				GameTooltipStatusBar.anchoredToTop = true
			end
			return
		else
			tt:SetOwner(parent, "ANCHOR_NONE")
			if (GameTooltipStatusBar.anchoredToTop) then
				GameTooltipStatusBar:ClearAllPoints()
				GameTooltipStatusBar:SetPoint("BOTTOMLEFT", GameTooltip, "TOPLEFT", 0, 6)
				GameTooltipStatusBar:SetPoint("BOTTOMRIGHT", GameTooltip, "TOPRIGHT", -0, 6)
				GameTooltipStatusBar.text:SetPoint("CENTER", GameTooltipStatusBar, 0, -3)
				GameTooltipStatusBar.anchoredToTop = nil
			end
		end
	end

	tt:SetPoint("BOTTOMRIGHT", GameTooltipAnchor, "BOTTOMRIGHT", 0, 0)
end

function Module:GetItemLvL(unit)
	local total, item = 0, 0
	local artifactEquipped = false
	for i = 1, #SlotName do
		local itemLink = GetInventoryItemLink(unit, GetInventorySlotInfo(("%sSlot"):format(SlotName[i])))
		if (itemLink ~= nil) then
			local _, _, rarity, _, _, _, _, _, equipLoc = GetItemInfo(itemLink)
			--Check if we have an artifact equipped in main hand
			if (equipLoc and equipLoc == "INVTYPE_WEAPONMAINHAND" and rarity and rarity == 6) then
				artifactEquipped = true
			end

			--If we have artifact equipped in main hand, then we should not count the offhand as it displays an incorrect item level
			if (not artifactEquipped or (artifactEquipped and equipLoc and equipLoc ~= "INVTYPE_WEAPONOFFHAND")) then
				local itemLevel = GetDetailedItemLevelInfo(itemLink)
				if (itemLevel and itemLevel > 0) then
					item = item + 1
					total = total + itemLevel
				end
			end
		end
	end

	if (total < 1 or item < 15) then
		return
	end

	return math_floor(total / item)
end

function Module:CleanUpTrashLines(tt)
	if tt:IsForbidden() then return end
	for i = 3, tt:NumLines() do
		local tiptext = _G["GameTooltipTextLeft"..i]
		local linetext = tiptext:GetText()

		if (linetext == PVP or linetext == FACTION_ALLIANCE or linetext == FACTION_HORDE) then
			tiptext:SetText(nil)
			tiptext:Hide()
		end
	end
end

function Module:GetLevelLine(tt, offset)
	for i = offset, tt:NumLines() do
		local tipText = _G["GameTooltipTextLeft"..i]
		if (tipText:GetText() and tipText:GetText():find(LEVEL)) then
			return tipText
		end
	end
end

function Module:GetTalentSpec(unit, isPlayer)
	local spec
	if (isPlayer) then
		spec = GetSpecialization()
	else
		spec = GetInspectSpecialization(unit)
	end
	if (spec ~= nil and spec > 0) then
		if (not isPlayer) then
			local role = GetSpecializationRoleByID(spec)
			if (role ~= nil) then
				local _, name, _, icon = GetSpecializationInfoByID(spec)
				icon = icon and "|T"..icon..":16:16:0:0:64:64:5:59:5:59|t " or ""
				return name and icon..name
			end
		else
			local _, name, _, icon = GetSpecializationInfo(spec)
			icon = icon and "|T"..icon..":16:16:0:0:64:64:5:59:5:59|t " or ""
			return name and icon..name
		end
	end
end

function Module:INSPECT_READY(_, GUID)
	if (self.lastGUID ~= GUID) then return end

	local unit = "mouseover"
	if (UnitExists(unit)) then
		local itemLevel = self:GetItemLvL(unit)
		local talentName = self:GetTalentSpec(unit)
		inspectCache[GUID] = {time = GetTime()}

		if (talentName) then
			inspectCache[GUID].talent = talentName
		end

		if (itemLevel) then
			inspectCache[GUID].itemLevel = itemLevel
		end

		GameTooltip:SetUnit(unit)
	end
	self:UnregisterEvent("INSPECT_READY")
end

function Module:ShowInspectInfo(tt, unit, level, r, g, b, numTries)
	if tt:IsForbidden() then return end

	local canInspect = CanInspect(unit)
	if (not canInspect or level < 10 or numTries > 1) then return end

	local GUID = UnitGUID(unit)
	if (GUID == K.GUID) then
		tt:AddDoubleLine(SPECIALIZATION, self:GetTalentSpec(unit, true), nil, nil, nil, r, g, b)
		tt:AddDoubleLine(STAT_AVERAGE_ITEM_LEVEL, math_floor(select(2, GetAverageItemLevel())), nil, nil, nil, 1, 1, 1)
	elseif (inspectCache[GUID]) then
		local talent = inspectCache[GUID].talent
		local itemLevel = inspectCache[GUID].itemLevel

		if (((GetTime() - inspectCache[GUID].time) > 900) or not talent or not itemLevel) then
			inspectCache[GUID] = nil

			return self:ShowInspectInfo(tt, unit, level, r, g, b, numTries + 1)
		end

		tt:AddDoubleLine(SPECIALIZATION, talent, nil, nil, nil, r, g, b)
		tt:AddDoubleLine(STAT_AVERAGE_ITEM_LEVEL, itemLevel, nil, nil, nil, 1, 1, 1)
	else
		if (not canInspect) or (InspectFrame and InspectFrame:IsShown()) then return end
		self.lastGUID = GUID
		NotifyInspect(unit)
		self:RegisterEvent("INSPECT_READY")
	end
end

function Module:GameTooltip_OnTooltipSetUnit(tt)
	if tt:IsForbidden() then return end

	local unit = select(2, tt:GetUnit())

	if (not unit) then
		local GMF = GetMouseFocus()
		if (GMF and GMF.GetAttribute and GMF:GetAttribute("unit")) then
			unit = GMF:GetAttribute("unit")
		end
		if (not unit or not UnitExists(unit)) then
			return
		end
	end

	self:CleanUpTrashLines(tt) -- keep an eye on this may be buggy
	local level = UnitLevel(unit)
	local isShiftKeyDown = IsShiftKeyDown()

	local color
	if (UnitIsPlayer(unit)) then
		local localeClass, class = UnitClass(unit)
		local name, realm = UnitName(unit)
		local guildName, guildRankName, _, guildRealm = GetGuildInfo(unit)
		local pvpName = UnitPVPName(unit)
		local relationship = UnitRealmRelationship(unit)
		if not localeClass or not class then return end
		color = CUSTOM_CLASS_COLORS and CUSTOM_CLASS_COLORS[class] or RAID_CLASS_COLORS[class]

		if (C["Tooltip"].PlayerTitles and pvpName) then
			name = pvpName
		end

		if (realm and realm ~= "") then
			if (isShiftKeyDown) then
				name = name.."-"..realm
			elseif (relationship == LE_REALM_RELATION_COALESCED) then
				name = name..FOREIGN_SERVER_LABEL
			elseif (relationship == LE_REALM_RELATION_VIRTUAL) then
				name = name..INTERACTIVE_SERVER_LABEL
			end
		end

		if (UnitIsAFK(unit)) then
			name = name..AFK_LABEL
		elseif (UnitIsDND(unit)) then
			name = name..DND_LABEL
		end

		_G["GameTooltipTextLeft1"]:SetFormattedText("|c%s%s|r", color.colorStr, name)

		local lineOffset = 2
		if (guildName) then
			if (guildRealm and isShiftKeyDown) then
				guildName = guildName.."-"..guildRealm
			end

			if (C["Tooltip"].GuildRanks) and IsShiftKeyDown() then
				GameTooltipTextLeft2:SetText(("<|cff00ff10%s|r> [|cff00ff10%s|r]"):format(guildName, guildRankName))
			else
				GameTooltipTextLeft2:SetText(("<|cff00ff10%s|r>"):format(guildName))
			end
			lineOffset = 3
		end

		local levelLine = self:GetLevelLine(tt, lineOffset)
		if (levelLine) then
			local diffColor = GetCreatureDifficultyColor(level)
			local race, englishRace = UnitRace(unit)
			local _, factionGroup = UnitFactionGroup(unit)
			if (factionGroup and englishRace == "Pandaren") then
				race = factionGroup.." "..race
			end
			levelLine:SetFormattedText("|cff%02x%02x%02x%s|r %s |c%s%s|r", diffColor.r * 255, diffColor.g * 255, diffColor.b * 255, level > 0 and level or "??", race or "", color.colorStr, localeClass)
		end

		-- High CPU usage, restricting it to shift key down only.
		if (C["Tooltip"].InspectInfo and isShiftKeyDown) then
			self:ShowInspectInfo(tt, unit, level, color.r, color.g, color.b, 0)
		end
	else
		if UnitIsTapDenied(unit) then
			color = TAPPED_COLOR
		else
			local unitReaction = UnitReaction(unit, "player")
			if unitReaction then
				unitReaction = format("%s", unitReaction) -- Cast to string because our table is indexed by string keys
				color = K.Colors.factioncolors[unitReaction]
			end
		end

		local levelLine = self:GetLevelLine(tt, 2)
		if (levelLine) then
			local isPetWild, isPetCompanion = UnitIsWildBattlePet(unit), UnitIsBattlePetCompanion(unit)
			local creatureClassification = UnitClassification(unit)
			local creatureType = UnitCreatureType(unit)
			local pvpFlag = ""
			local diffColor
			if (isPetWild or isPetCompanion) then
				level = UnitBattlePetLevel(unit)

				local petType = _G["BATTLE_PET_NAME_"..UnitBattlePetType(unit)]
				if creatureType then
					creatureType = format("%s %s", creatureType, petType)
				else
					creatureType = petType
				end

				local teamLevel = C_PetJournalGetPetTeamAverageLevel()
				if (teamLevel) then
					diffColor = GetRelativeDifficultyColor(teamLevel, level)
				else
					diffColor = GetCreatureDifficultyColor(level)
				end
			else
				diffColor = GetCreatureDifficultyColor(level)
			end

			if (UnitIsPVP(unit)) then
				pvpFlag = format(" (%s)", PVP)
			end

			levelLine:SetFormattedText("|cff%02x%02x%02x%s|r%s %s%s", diffColor.r * 255, diffColor.g * 255, diffColor.b * 255, level > 0 and level or "??", classification[creatureClassification] or "", creatureType or "", pvpFlag)
		end
	end

	local unitTarget = unit.."target"
	if (unit ~= "player" and UnitExists(unitTarget)) then
		local targetColor
		if(UnitIsPlayer(unitTarget) and not UnitHasVehicleUI(unitTarget)) then
			local _, class = UnitClass(unitTarget)
			targetColor = CUSTOM_CLASS_COLORS and CUSTOM_CLASS_COLORS[class] or RAID_CLASS_COLORS[class]
		else
			targetColor = K.Colors.factioncolors[""..UnitReaction(unitTarget, "player")] or FACTION_BAR_COLORS[UnitReaction(unitTarget, "player")]
		end

		GameTooltip:AddDoubleLine(format("%s:", TARGET), format("|cff%02x%02x%02x%s|r", targetColor.r * 255, targetColor.g * 255, targetColor.b * 255, UnitName(unitTarget, true)))
	end

	if (color) then
		GameTooltipStatusBar:SetStatusBarColor(color.r, color.g, color.b)
	else
		GameTooltipStatusBar:SetStatusBarColor(0.6, 0.6, 0.6)
	end

	local textWidth = GameTooltipStatusBar.text:GetStringWidth()
	if textWidth then
		tt:SetMinimumWidth(textWidth)
	end
end

function Module:GameTooltipStatusBar_OnValueChanged(tt, value)
	if tt:IsForbidden() then return end
	if not value or not C["Tooltip"].HealthBarText or not tt.text then return end
	local unit = select(2, tt:GetParent():GetUnit())
	if (not unit) then
		local GMF = GetMouseFocus()
		if (GMF and GMF.GetAttribute and GMF:GetAttribute("unit")) then
			unit = GMF:GetAttribute("unit")
		end
	end

	local _, max = tt:GetMinMaxValues()
	if (value > 0 and max == 1) then
		tt.text:SetFormattedText("%d%%", math_floor(value * 100))
		tt:SetStatusBarColor(TAPPED_COLOR.r, TAPPED_COLOR.g, TAPPED_COLOR.b) --most effeciant?
	elseif (value == 0 or (unit and UnitIsDeadOrGhost(unit))) then
		tt.text:SetText(DEAD)
	else
		tt.text:SetText(K.ShortValue(value).." / "..K.ShortValue(max))
	end
end

function Module:GameTooltip_OnTooltipCleared(tt)
	if tt:IsForbidden() then return end
	tt.itemCleared = nil
end

function Module:GameTooltip_OnTooltipSetItem(tt)
	if tt:IsForbidden() then return end
	local ownerName = tt:GetOwner() and tt:GetOwner().GetName and tt:GetOwner():GetName()

	if not tt.itemCleared then
		local _, link = tt:GetItem()
		local num = GetItemCount(link)
		local numall = GetItemCount(link, true)
		local left = " "
		local right = " "
		local bankCount = " "

		if link ~= nil and C["Tooltip"].SpellID and IsShiftKeyDown() then
			left = (("|cFFCA3C3C%s|r %s"):format(ID, link)):match(":(%w+)")
		end

		right = ("|cFFCA3C3C%s|r %d"):format(L["Tooltip"].Count, num)
		bankCount = ("|cFFCA3C3C%s|r %d"):format(L["Tooltip"].Bank, (numall - num))

		if left ~= " " or right ~= " " and IsShiftKeyDown() then
			tt:AddLine(" ")
			tt:AddDoubleLine(left, right)
		end
		if bankCount ~= " " and IsShiftKeyDown() then
			tt:AddDoubleLine(" ", bankCount)
		end

		tt.itemCleared = true
	end

	if C["Tooltip"].ItemQualityBorder then
		local _, link = tt:GetItem()
		if not link then return end
		tt.currentItem = link

		local name, _, quality, _, _, type, subType, _, _, _, _ = GetItemInfo(link)
		if not quality then
			quality = 0
		end

		local r, g, b
		if type == L["Tooltip"].Quest then
			r, g, b = 1, 1, 0
		elseif type == L["Tooltip"].Tradeskill and not ignoreSubType[subType] and quality < 2 then
			r, g, b = 0.4, 0.73, 1
		elseif subType == L["Tooltip"].Companion_Pets then
			local _, id = C_PetJournal_FindPetIDByName(name)
			if id then
				local _, _, _, _, petQuality = C_PetJournal_GetPetStats(id)
				if petQuality then
					quality = petQuality - 1
				end
			end
		end
		if quality > 1 and not r then
			r, g, b = GetItemQualityColor(quality)
		end
		if r then
			tt:SetBackdropBorderColor(r, g, b)
		end
	end
end

function Module:GameTooltip_ShowStatusBar(tt)
	if tt:IsForbidden() then return end

	local statusBar = _G[tt:GetName().."StatusBar"..tt.shownStatusBars]
	if statusBar and not statusBar.skinned then
		statusBar:SetStatusBarTexture(TooltipTexture)
		statusBar.skinned = true
	end
end

function Module:SetStyle(tt)
	if tt:IsForbidden() then return end

	for _, tt in pairs(tooltips) do
		tt:SetTemplate("Transparent", true)
		local r, g, b = tt:GetBackdropColor()
		tt:SetBackdropColor(r, g, b, C["Media"].BackdropColor[4])
	end
end

function Module:MODIFIER_STATE_CHANGED(_, key)
	if ((key == "LSHIFT" or key == "RSHIFT") and UnitExists("mouseover")) then
		GameTooltip:SetUnit("mouseover")
	end
end

function Module:SetUnitAura(tt, unit, index, filter)
	if tt:IsForbidden() then return end
	local _, _, _, _, _, _, caster, _, _, id = UnitAura(unit, index, filter)
	if id and C["Tooltip"].SpellID then
		if caster then
			local name = UnitName(caster)
			local _, class = UnitClass(caster)
			local color = CUSTOM_CLASS_COLORS and CUSTOM_CLASS_COLORS[class] or RAID_CLASS_COLORS[class]
			if not color then color = RAID_CLASS_COLORS["PRIEST"] end
			tt:AddDoubleLine(("|cFFCA3C3C%s|r %d"):format(ID, id), format("|c%s%s|r", color.colorStr, name))
		else
			tt:AddLine(("|cFFCA3C3C%s|r %d"):format(ID, id))
		end

		tt:Show()
	end
end

function Module:GameTooltip_OnTooltipSetSpell(tt)
	if tt:IsForbidden() then return end
	local id = select(3, tt:GetSpell())
	if not id or not C["Tooltip"].SpellID then return end

	local displayString = ("|cFFCA3C3C%s|r %d"):format(ID, id)
	local lines = tt:NumLines()
	local isFound
	for i = 1, lines do
		local line = _G[("GameTooltipTextLeft%d"):format(i)]
		if line and line:GetText() and line:GetText():find(displayString) then
			isFound = true
			break
		end
	end

	if not isFound then
		tt:AddLine(displayString)
		tt:Show()
	end
end

function Module:SetItemRef(link)
	if find(link, "^spell:") and C["Tooltip"].SpellID then
		local id = sub(link, 7)
		ItemRefTooltip:AddLine(("|cFFCA3C3C%s|r %d"):format(ID, id))
		ItemRefTooltip:Show()
	end
end

function Module:RepositionBNET(frame, _, anchor)
	if anchor ~= BNETMover then
		frame:ClearAllPoints()
		frame:SetPoint("CENTER", BNETMover, "CENTER")
	end
end

function Module:CheckBackdropColor()
	if GameTooltip:IsForbidden() then return end
	if not GameTooltip:IsShown() then return end

	local r, g, b = GameTooltip:GetBackdropColor()
	if (r and g and b) then
		r = K.Round(r, 1)
		g = K.Round(g, 1)
		b = K.Round(b, 1)
		local red, green, blue = C["Media"].BackdropColor[1], C["Media"].BackdropColor[2], C["Media"].BackdropColor[3]
		if (r ~= red or g ~= green or b ~= blue) then
			GameTooltip:SetBackdropColor(red, green, blue, C["Media"].BackdropColor[4])
		end
	end
end

function Module:SetTooltipFonts()
	local font = C["Media"].Font
	local fontOutline = ""
	local headerSize = 12
	local textSize = 12
	local smallTextSize = 12

	GameTooltipHeaderText:SetFont(font, headerSize, fontOutline)
	GameTooltipText:SetFont(font, textSize, fontOutline)
	GameTooltipTextSmall:SetFont(font, smallTextSize, fontOutline)
	if GameTooltip.hasMoney then
		for i = 1, GameTooltip.numMoneyFrames do
			_G["GameTooltipMoneyFrame"..i.."PrefixText"]:SetFont(font, textSize, fontOutline)
			_G["GameTooltipMoneyFrame"..i.."SuffixText"]:SetFont(font, textSize, fontOutline)
			_G["GameTooltipMoneyFrame"..i.."GoldButtonText"]:SetFont(font, textSize, fontOutline)
			_G["GameTooltipMoneyFrame"..i.."SilverButtonText"]:SetFont(font, textSize, fontOutline)
			_G["GameTooltipMoneyFrame"..i.."CopperButtonText"]:SetFont(font, textSize, fontOutline)
		end
	end

	-- These show when you compare items ("Currently Equipped", name of item, item level)
	-- Since they appear at the top of the tooltip, we set it to use the header font size.
	ShoppingTooltip1TextLeft1:SetFont(font, headerSize, fontOutline)
	ShoppingTooltip1TextLeft2:SetFont(font, headerSize, fontOutline)
	ShoppingTooltip1TextLeft3:SetFont(font, headerSize, fontOutline)
	ShoppingTooltip1TextLeft4:SetFont(font, headerSize, fontOutline)
	ShoppingTooltip1TextRight1:SetFont(font, headerSize, fontOutline)
	ShoppingTooltip1TextRight2:SetFont(font, headerSize, fontOutline)
	ShoppingTooltip1TextRight3:SetFont(font, headerSize, fontOutline)
	ShoppingTooltip1TextRight4:SetFont(font, headerSize, fontOutline)
	ShoppingTooltip2TextLeft1:SetFont(font, headerSize, fontOutline)
	ShoppingTooltip2TextLeft2:SetFont(font, headerSize, fontOutline)
	ShoppingTooltip2TextLeft3:SetFont(font, headerSize, fontOutline)
	ShoppingTooltip2TextLeft4:SetFont(font, headerSize, fontOutline)
	ShoppingTooltip2TextRight1:SetFont(font, headerSize, fontOutline)
	ShoppingTooltip2TextRight2:SetFont(font, headerSize, fontOutline)
	ShoppingTooltip2TextRight3:SetFont(font, headerSize, fontOutline)
	ShoppingTooltip2TextRight4:SetFont(font, headerSize, fontOutline)
end

function Module:OnEnable()
	if C["Tooltip"].Enable ~= true then return end

	local BNETMover = CreateFrame("Frame", "BNETMover", UIParent)
	BNETMover:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", 6, 204)
	BNETMover:SetSize(250, 64)
	BNToastFrame:SetTemplate("Transparent", true)
	BNToastFrame.CloseButton:SetSize(32, 32)
	BNToastFrame.CloseButton:SetPoint("TOPRIGHT", 4, 4)
	BNToastFrame.CloseButton:SkinCloseButton()

	K.Movers:RegisterFrame(BNETMover)
	self:SecureHook(BNToastFrame, "SetPoint", "RepositionBNET")

	GameTooltipStatusBar:SetHeight(C["Tooltip"].HealthbarHeight)
	GameTooltipStatusBar:SetStatusBarTexture(TooltipTexture)
	GameTooltipStatusBar:SetTemplate("Transparent")
	GameTooltipStatusBar:SetScript("OnValueChanged", self.OnValueChanged)
	GameTooltipStatusBar:ClearAllPoints()
	GameTooltipStatusBar:SetPoint("BOTTOMLEFT", GameTooltip, "TOPLEFT", 0, 6)
	GameTooltipStatusBar:SetPoint("BOTTOMRIGHT", GameTooltip, "TOPRIGHT", -0, 6)
	GameTooltipStatusBar.text = GameTooltipStatusBar:CreateFontString(nil, "OVERLAY")
	GameTooltipStatusBar.text:SetPoint("CENTER", GameTooltipStatusBar, 0, 3)
	GameTooltipStatusBar.text:SetFont(C["Media"].Font, C["Tooltip"].FontSize, C["Tooltip"].FontOutline and "OUTLINE" or "")
	GameTooltipStatusBar.text:SetShadowOffset(C["Tooltip"].FontOutline and 0 or 1, C["Tooltip"].FontOutline and -0 or -1)

	-- Tooltip Fonts
	if not GameTooltip.hasMoney then
		-- Force creation of the money lines, so we can set font for it
		SetTooltipMoney(GameTooltip, 1, nil, "", "")
		SetTooltipMoney(GameTooltip, 1, nil, "", "")
		GameTooltip_ClearMoney(GameTooltip)
	end
	self:SetTooltipFonts()

	local GameTooltipAnchor = CreateFrame("Frame", "GameTooltipAnchor", UIParent)
	GameTooltipAnchor:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", -4, 20)
	GameTooltipAnchor:SetSize(130, 20)
	GameTooltipAnchor:SetFrameLevel(GameTooltipAnchor:GetFrameLevel() + 400)
	K.Movers:RegisterFrame(GameTooltipAnchor)

	self:SecureHook("GameTooltip_SetDefaultAnchor")
	self:SecureHook("GameTooltip_ShowStatusBar")
	self:SecureHook("SetItemRef")
	self:SecureHook(GameTooltip, "SetUnitAura")
	self:SecureHook(GameTooltip, "SetUnitBuff", "SetUnitAura")
	self:SecureHook(GameTooltip, "SetUnitDebuff", "SetUnitAura")
	self:SecureHookScript(GameTooltip, "OnTooltipSetSpell", "GameTooltip_OnTooltipSetSpell")
	self:SecureHookScript(GameTooltip, "OnTooltipCleared", "GameTooltip_OnTooltipCleared")
	self:SecureHookScript(GameTooltip, "OnTooltipSetItem", 'GameTooltip_OnTooltipSetItem')
	self:SecureHookScript(GameTooltip, "OnTooltipSetUnit", "GameTooltip_OnTooltipSetUnit")

	self:SecureHookScript(GameTooltip, "OnSizeChanged", "CheckBackdropColor")
	self:SecureHookScript(GameTooltip, "OnUpdate", "CheckBackdropColor") --There has to be a more elegant way of doing this.

	self:SecureHookScript(GameTooltipStatusBar, "OnValueChanged", "GameTooltipStatusBar_OnValueChanged")

	self:RegisterEvent("MODIFIER_STATE_CHANGED")
	self:RegisterEvent("CURSOR_UPDATE", "CheckBackdropColor")
	ItemRefCloseButton:SkinCloseButton()
	for _, tt in pairs(tooltips) do
		self:SecureHookScript(tt, "OnShow", "SetStyle")
	end

	-- World Quest Reward Icon
	WorldMapTooltip.ItemTooltip.Icon:SetTexCoord(K.TexCoords[1], K.TexCoords[2], K.TexCoords[3], K.TexCoords[4])
	hooksecurefunc(WorldMapTooltip.ItemTooltip.IconBorder, "SetVertexColor", function(self, r, g, b)
		self:GetParent().Backdrop:SetBackdropBorderColor(r, g, b)
		self:SetTexture("")
	end)
	hooksecurefunc(WorldMapTooltip.ItemTooltip.IconBorder, "Hide", function(self)
		self:GetParent().Backdrop:SetBackdropBorderColor(C["Media"].BorderColor[1], C["Media"].BorderColor[2], C["Media"].BorderColor[3])
	end)
	WorldMapTooltip.ItemTooltip:CreateBackdrop("") -- No backdrop needs to happen, only a border.
	WorldMapTooltip.ItemTooltip.Backdrop:SetAllPoints(WorldMapTooltip.ItemTooltip.Icon)
	WorldMapTooltip.ItemTooltip.Backdrop:SetFrameLevel(3)
	WorldMapTooltip.ItemTooltip.Count:ClearAllPoints()
	WorldMapTooltip.ItemTooltip.Count:SetPoint("BOTTOMRIGHT", WorldMapTooltip.ItemTooltip.Icon, "BOTTOMRIGHT", 1, 0)
end
