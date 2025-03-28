-- Please see the license.txt file included with this distribution for
-- attribution and copyright information.

--luacheck: globals updateSizeHelper getTokenSpace onSpaceChanged onReachChanged onTokenRefUpdated

local updateSizeHelperOriginal;
local getTokenSpaceOriginal;

function onInit()
	updateSizeHelperOriginal = TokenManager.updateSizeHelper;
	TokenManager.updateSizeHelper = updateSizeHelper;

	getTokenSpaceOriginal = TokenManager.getTokenSpace;
	TokenManager.getTokenSpace = getTokenSpace;

	if Session.IsHost then
		SizeManager.addSpaceChangedHandler(onSpaceChanged);
		SizeManager.addReachChangedHandler(onReachChanged);
		DB.addHandler('combattracker.list.*.tokenrefid', 'onUpdate', onTokenRefUpdated);
	end
end

function updateSizeHelper(tokenCT, nodeCT)
	SizeManager.swapSpaceReach();
	updateSizeHelperOriginal(tokenCT, nodeCT);
	SizeManager.resetSpaceReach();
end

function getTokenSpace(tokenMap)
	SizeManager.swapSpaceReach();
	local nSpace = getTokenSpaceOriginal(tokenMap);
	SizeManager.resetSpaceReach();
	return nSpace;
end

function onSpaceChanged(nodeCombatant)
	local tokenCombatant = CombatManager.getTokenFromCT(nodeCombatant);
	if tokenCombatant then
		TokenManager.updateSizeHelper(tokenCombatant, nodeCombatant);
		if OptionsManager.getOption("TASG") ~= "" then
			TokenManager.autoTokenScale(tokenCombatant);
		end
	end
end

function onReachChanged(nodeCombatant)
	local tokenCombatant = CombatManager.getTokenFromCT(nodeCombatant);
	if tokenCombatant then
		TokenManager.updateSizeHelper(tokenCombatant, nodeCombatant);
	end
end

function onTokenRefUpdated(nodeUpdated)
	local nodeCT = DB.getParent(nodeUpdated);
	if not nodeCT then return end
	local tokenCT = CombatManager.getTokenFromCT(nodeCT);
	if not tokenCT then return end
	SizeManager.onCombatantEffectUpdated(DB.getChild(nodeCT, 'effects'), true);
end