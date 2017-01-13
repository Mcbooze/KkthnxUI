local K, C, L = unpack(select(2, ...))

-- -- Lua API
-- local math_random = math.random
-- local select = select
--
-- -- Wow API
-- local DoEmote = DoEmote
-- local UnitGUID = UnitGUID
-- local GetAchievementInfo = GetAchievementInfo
--
-- local PVPEmoteMessages = CreateFrame("Frame")
--
-- local PVPEmotes = {
-- 	"BYE", "BITE", "CACKLE", "SHOO", "SLAP", "TEASE", "TAUNT", "MOCK", "MOO",
-- 	"CHICKEN", "COMFORT", "CUDDLE", "CURTSEY", "GIGGLE", "GROWL", "NOSEPICK",
-- 	"CHUCKLE", "BONK", "FLEX", "GRIN", "LAUGH", "MOON", "NO", "ROAR", "ROFL",
-- 	"MOURN", "SNIFF", "LICK", "SNICKER", "GUFFAW", "GLOAT", "PITY", "VIOLIN",
-- 	"RASP", "RUDE", "SMIRK", "SNUB", "SOOTHE", "THANK", "TICKLE", "VETO", "YAWN",
-- 	"SCRATCH", "SIGH", "SNARL", "TAP", "INSULT", "BARK", "BECKON", "CALM",
-- }
--
-- local function GetRandomEmote()
-- 	return PVPEmotes[math_random(1, #(PVPEmotes))]
-- end
--
-- PVPEmoteMessages:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
-- PVPEmoteMessages:SetScript("OnEvent", function(self, event, ...)
--   local eventType, _, sourceGUID, _, _, _, destGUID = ...
-- 	if eventType == "PARTY_KILL" then
-- 		if sourceGUID == UnitGUID("player") then
--       local tarName = select(8, ...)
-- 			if select(3, GetAchievementInfo(247)) then
-- 				DoEmote(GetRandomEmote(), tarName)
-- 			else
-- 				DoEmote("HUG", tarName)
-- 			end
-- 		end
-- 	end
-- end)
--
-- -- Remove the editbox for deleting "good" items
-- StaticPopupDialogs.DELETE_ITEM.enterClicksFirstButton = true
-- StaticPopupDialogs.DELETE_GOOD_ITEM = StaticPopupDialogs.DELETE_ITEM
