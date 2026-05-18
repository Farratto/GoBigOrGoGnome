-- Please see the license.txt file included with this distribution for
-- attribution and copyright information.

--luacheck: globals updateSizeHelper getTokenSpace onSpaceChanged onReachChanged onTokenRefUpdated
--luacheck: globals updateHealthHelperSM updateHealthBarScaleSM updateNameHelperSM
--luacheck: globals updateSizeHelperOriginal getTokenSpaceOriginal
--luacheck: globals fupdateHealthHelper fupdateHealthBarScale fupdateNameHelper

function onInit()
	updateSizeHelperOriginal = TokenManager.updateSizeHelper;
	TokenManager.updateSizeHelper = updateSizeHelper;
	getTokenSpaceOriginal = TokenManager.getTokenSpace;
	TokenManager.getTokenSpace = getTokenSpace;
	fupdateHealthHelper = TokenManager.updateHealthHelper;
	TokenManager.updateHealthHelper = updateHealthHelperSM;
	fupdateHealthBarScale = TokenManager.updateHealthBarScale;
	TokenManager.updateHealthBarScale = updateHealthBarScaleSM;
	fupdateNameHelper = TokenManager.updateNameHelper;
	TokenManager.updateNameHelper = updateNameHelperSM;

	if Session.IsHost then
		SizeManager.addSpaceChangedHandler(onSpaceChanged);
		SizeManager.addReachChangedHandler(onReachChanged);
		DB.addHandler('combattracker.list.*.tokenrefid', 'onUpdate', onTokenRefUpdated);
	end
end

function updateSizeHelper(tokenCT, nodeCT, ...)
	SizeManager.swapSpaceReach();
	local vReturn = updateSizeHelperOriginal(tokenCT, nodeCT, ...);
	SizeManager.resetSpaceReach();
	return vReturn;
end

function getTokenSpace(tokenMap, ...)
	SizeManager.swapSpaceReach();
	local nSpace = getTokenSpaceOriginal(tokenMap, ...);
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

function updateNameHelperSM(...)
	SizeManager.swapSpaceReach();
	local vReturn = fupdateNameHelper(...);
	SizeManager.resetSpaceReach();
	return vReturn;
end

function updateHealthHelperSM(tokenCT, nodeCT, ...)
	SizeManager.swapSpaceReach();

	local sOptTH;
	if Session.IsHost then
		sOptTH = OptionsManager.getOption("TGMH");
	elseif CombatManager.getFactionFromCT(nodeCT) == "friend" then
		sOptTH = OptionsManager.getOption("TPCH");
	else
		sOptTH = OptionsManager.getOption("TNPCH");
	end

	if sOptTH == "bar" or sOptTH == "barhover" then
		tokenCT.deleteWidget("healthdot");
		local nSpace = TokenManager.calcTokenSpace(DB.getValue(nodeCT, "space"));
		local tWidget = {
			name = "healthdot",
			icon = "healthdot",
			position = "bottomright",
			x = TokenManager.TOKEN_HEALTHDOT_HOFFSET,
			y = TokenManager.TOKEN_HEALTHDOT_VOFFSET,
			w = TokenManager.TOKEN_HEALTHDOT_SIZE * nSpace,
			h = TokenManager.TOKEN_HEALTHDOT_SIZE * nSpace,
		};
		tokenCT.addBitmapWidget(tWidget);
	end

	local vReturn = fupdateHealthHelper(tokenCT, nodeCT, ...);

	SizeManager.resetSpaceReach();

	return vReturn;
end
function updateHealthBarScaleSM(...)
	SizeManager.swapSpaceReach();
	local vReturn = fupdateHealthBarScale(...);
	SizeManager.resetSpaceReach();
	return vReturn;
end