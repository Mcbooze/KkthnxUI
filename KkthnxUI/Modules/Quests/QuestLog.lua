local K, C, L = unpack(select(2, ...))

-- WoW Lua
local pairs = pairs
local strmatch = string.match

-- Wow API
local GetAbandonQuestItems = GetAbandonQuestItems
local GetAbandonQuestName = GetAbandonQuestName
local GetQuestLink = GetQuestLink
local GetQuestLogIndexByID = GetQuestLogIndexByID
local GetQuestLogPushable = GetQuestLogPushable
local IsAltKeyDown = IsAltKeyDown
local IsControlKeyDown = IsControlKeyDown
local StaticPopup_Hide = StaticPopup_Hide
local StaticPopup_Show = StaticPopup_Show

-- Global variables that we don't cache, list them here for mikk's FindGlobals script
-- GLOBALS: QuestMapFrame, QuestMapQuestOptions_AbandonQuest, QuestMapQuestOptions_ShareQuest
-- GLOBALS: QuestLogPushQuest

-- Quest level
hooksecurefunc("QuestLogQuests_Update", function()
	for i, button in pairs(QuestMapFrame.QuestsFrame.Contents.Titles) do
		if button:IsShown() then
			local link = GetQuestLink(button.questID)
			if link then
				local level = strmatch(link, "quest:%d+:(%d+)")
				if level then
					local height = button.Text:GetHeight()
					button.Text:SetFormattedText("[%d] %s", level, button.Text:GetText())
					button.Check:SetPoint("LEFT", button.Text, button.Text:GetWrappedWidth() + 2, 0)
					button:SetHeight(button:GetHeight() - height + button.Text:GetHeight())
				end
			end
		end
	end
end)

-- Ctrl+Click to abandon a quest or Alt+Click to share a quest(by Suicidal Katt)
hooksecurefunc("QuestMapLogTitleButton_OnClick", function(self)
	local questLogIndex = GetQuestLogIndexByID(self.questID)
	if IsControlKeyDown() then
		QuestMapQuestOptions_AbandonQuest(self.questID)
	elseif IsAltKeyDown() and GetQuestLogPushable(questLogIndex) then
		QuestMapQuestOptions_ShareQuest(self.questID)
	end
end)

hooksecurefunc(QUEST_TRACKER_MODULE, "OnBlockHeaderClick", function(block)
	local questLogIndex = block.questLogIndex
	if IsControlKeyDown() then
		local items = GetAbandonQuestItems()
		if items then
			StaticPopup_Hide("ABANDON_QUEST")
			StaticPopup_Show("ABANDON_QUEST_WITH_ITEMS", GetAbandonQuestName(), items)
		else
			StaticPopup_Hide("ABANDON_QUEST_WITH_ITEMS")
			StaticPopup_Show("ABANDON_QUEST", GetAbandonQuestName())
		end
	elseif IsAltKeyDown() and GetQuestLogPushable(questLogIndex) then
		QuestLogPushQuest(questLogIndex)
	end
end)