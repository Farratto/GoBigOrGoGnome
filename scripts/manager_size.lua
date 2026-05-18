-- Please see the license.txt file included with this distribution for
-- attribution and copyright information.

--luacheck: globals getDBValue addSizeChangedHandler removeSizeChangedHandler invokeSizeChangedHandlers
--luacheck: globals addSpaceChangedHandler removeSpaceChangedHandler invokeSpaceChangedHandlers
--luacheck: globals addReachChangedHandler removeReachChangedHandler invokeReachChangedHandlers
--luacheck: globals getDefaultSize getSizeTable onCurrentSizeChanged onCurrentSpaceChanged
--luacheck: globals onCurrentReachChanged onCurrentDeleted onChildDeleted onCombatantEffectUpdated
--luacheck: globals calculateSize calculateSpace calculateReach getSizeName getSpaceFromSize getBaseSize
--luacheck: globals swapSpaceReach resetSpaceReach swapSize resetSize incrementSize forceRedraw
--luacheck: globals fupdateHealthHelper updateHealthHelperSDM

local getValueOriginal, bShouldSwap, sDeleted;
local tSizeChangedHandlers = {};
local tSpaceChangedHandlers = {};
local tReachChangedHandlers = {};
OOB_MSGTYPE_SIZETYPECHANGE = 'size_type_change'

function onInit()
	getValueOriginal = DB.getValue;
	DB.getValue = getDBValue;

	OOBManager.registerOOBMsgHandler(OOB_MSGTYPE_SIZETYPECHANGE, handleSizeTypeChange);

	if Session.IsHost then
		DB.addHandler(CombatManager.CT_COMBATANT_PATH .. '.currentsize', 'onUpdate', onCurrentSizeChanged);
		DB.addHandler(CombatManager.CT_COMBATANT_PATH .. '.currentspace', 'onUpdate', onCurrentSpaceChanged);
		DB.addHandler(CombatManager.CT_COMBATANT_PATH .. '.currentreach', 'onUpdate', onCurrentReachChanged);
		DB.addHandler(CombatManager.CT_COMBATANT_PATH .. '.currentsize', 'onDelete', onCurrentDeleted);
		DB.addHandler(CombatManager.CT_COMBATANT_PATH .. '.currentspace', 'onDelete', onCurrentDeleted);
		DB.addHandler(CombatManager.CT_COMBATANT_PATH .. '.currentreach', 'onDelete', onCurrentDeleted);
		DB.addHandler(CombatManager.CT_COMBATANT_PATH, 'onChildDeleted', onChildDeleted);
		DB.addHandler(CombatManager.CT_COMBATANT_PATH .. '.effects', 'onChildUpdate', onCombatantEffectUpdated);
		OptionsManager.registerOptionData({ sKey = 'sm_small_size', sGroupRes = 'option_header_size_matters'
			, tCustom = { default = 'on' }
		});
	end
end

function getDBValue(vFirst, vSecond, ...)
	local sType = type(vFirst);
	if sType == 'undefined' then return ... end
	if sType ~= 'databasenode' then
		if sType ~= 'string' then return ... end
		if not DB.findNode(vFirst) and not string.match(vFirst, '^options%.') then
			return vSecond, ...;
		end
	end

	if bShouldSwap then
		if vSecond == 'size' then
			local nodeCT = ActorManager.getCTNode(vFirst);
			local vCurrent = getValueOriginal(nodeCT, 'currentsize');
			if vCurrent then
				return vCurrent;
			end
		elseif vSecond == 'space' then
			local nodeCT = ActorManager.getCTNode(vFirst);
			local vCurrent = getValueOriginal(nodeCT, 'currentspace');
			if vCurrent then
				return vCurrent;
			end
		elseif vSecond == 'reach' then
			local nodeCT = ActorManager.getCTNode(vFirst);
			local vCurrent = getValueOriginal(nodeCT, 'currentreach');
			if vCurrent then
				return vCurrent;
			end
		end
	end

	if vSecond ~= nil then
		return getValueOriginal(vFirst, vSecond, ...);
	else
		return getValueOriginal(vFirst);
	end
end


function addSizeChangedHandler(fHandler)
	tSizeChangedHandlers[fHandler] = true;
end

function removeSizeChangedHandler(fHandler)
	tSizeChangedHandlers[fHandler] = nil;
end

function invokeSizeChangedHandlers(nodeCombatant)
	for fHandler in pairs(tSizeChangedHandlers) do
		fHandler(nodeCombatant);
	end
end

function addSpaceChangedHandler(fHandler)
	tSpaceChangedHandlers[fHandler] = true;
end

function removeSpaceChangedHandler(fHandler)
	tSpaceChangedHandlers[fHandler] = nil;
end

function invokeSpaceChangedHandlers(nodeCombatant)
	for fHandler in pairs(tSpaceChangedHandlers) do
		fHandler(nodeCombatant);
	end
end

function addReachChangedHandler(fHandler)
	tReachChangedHandlers[fHandler] = true;
end

function removeReachChangedHandler(fHandler)
	tReachChangedHandlers[fHandler] = nil;
end

function invokeReachChangedHandlers(nodeCombatant)
	for fHandler in pairs(tReachChangedHandlers) do
		fHandler(nodeCombatant);
	end
end

function getDefaultSize()
	-- Assume that the ruleset has a defined medium size.
	local tSize = getSizeTable();
	if tSize and tSize['medium'] then
		return tSize['medium'];
	end
end

function getSizeTable()
	return DataCommon.creaturesize;
end

function onCurrentSizeChanged(nodeCurrent)
	invokeSizeChangedHandlers(nodeCurrent.getParent());
end

function onCurrentSpaceChanged(nodeCurrent)
	invokeSpaceChangedHandlers(nodeCurrent.getParent());
end

function onCurrentReachChanged(nodeCurrent)
	invokeReachChangedHandlers(nodeCurrent.getParent());
end

function onCurrentDeleted(nodeCurrent)
	sDeleted = nodeCurrent.getName();
end

function onChildDeleted(nodeCombatant)
	if sDeleted == 'currentsize' then
		invokeSizeChangedHandlers(nodeCombatant);
	elseif sDeleted == 'currentspace' then
		invokeSpaceChangedHandlers(nodeCombatant);
	elseif sDeleted == 'currentreach' then
		invokeReachChangedHandlers(nodeCombatant);
	end
	sDeleted =nil;
end

function onCombatantEffectUpdated(nodeEffectList, bForceRedraw)
	if not nodeEffectList then return end

	local nodeCombatant = nodeEffectList.getParent();
	calculateSpace(nodeCombatant, bForceRedraw);
	calculateReach(nodeCombatant);
end

function calculateSize(nodeCombatant)
	local tSize = getSizeTable();
	if not tSize then
		return;
	end

	local nDefaultSize = getDefaultSize();
	if not nDefaultSize then
		return;
	end

	local aSizeEffects = EffectManager.getEffectsByType(nodeCombatant, "SIZE");
	local nMod = 0;
	local sBaseSize = getBaseSize(nodeCombatant);
	local sCurrentSize = DB.getValue(nodeCombatant, "currentsize", sBaseSize):lower();
	local sSize = sBaseSize;
	for _,rEffect in ipairs(aSizeEffects) do
		for _,sRemainder in ipairs(rEffect.remainder) do
			sSize = sRemainder:lower(); -- last in wins
		end
		nMod = nMod + rEffect.mod;
	end
	local nSize = tSize[sSize] or tSize[sBaseSize] or nDefaultSize;
	nSize = nSize + nMod;

	--old way.  it increments/decrements by 1 grid square instead of by 1 size category
	--[[local nMin = 1000;
	local nMax = -1000;
	for _,nMappedSize in pairs(tSize) do
		if nMappedSize < nMin then
			nMin = nMappedSize;
		end
		if nMax < nMappedSize then
			nMax = nMappedSize;
		end
	end
	nSize = math.max(nMin, math.min(nSize, nMax));]]

	if nSize ~= tSize[sCurrentSize] then
		if nSize == tSize[sBaseSize] then
			DB.deleteChild(nodeCombatant, "currentsize");
		else
			DB.setValue(nodeCombatant, "currentsize", "string", getSizeName(nSize));
		end
	end
	return nSize;
end

function calculateSpace(nodeCombatant, bForceRedraw)
	local nDU = GameSystem.getDistanceUnitsPerGrid();
	local nBaseSpace = DB.getValue(nodeCombatant, "space", nDU);
	local nCurrentSpace = DB.getValue(nodeCombatant, "currentspace", nBaseSpace);
	local nSpace = nBaseSpace;

	local nSize = calculateSize(nodeCombatant);
	if nSize then
		local nSizeSpace = ActorCommonManager.getSpaceReachFromActorSize(nSize, ActorCommonManagerSM.sRSSizeType)
		if nSizeSpace then
			nSpace = nSizeSpace;
		end
	end

	local aSpaceEffects = EffectManager.getEffectsByType(nodeCombatant, "SPACE");
	for _,rEffect in ipairs(aSpaceEffects) do
		if rEffect.mod ~= 0 then
			nSpace = rEffect.mod;
		end
	end

	local aAddSpaceEffects = EffectManager.getEffectsByType(nodeCombatant, "ADDSPACE");
	for _,rEffect in ipairs(aAddSpaceEffects) do
		nSpace = nSpace + rEffect.mod;
	end

	if bForceRedraw or (nSpace ~= nCurrentSpace) then
		if nSpace == nBaseSpace then
			DB.deleteChild(nodeCombatant, "currentspace");
		else
			if bForceRedraw then DB.deleteChild(nodeCombatant, "currentspace") end
			DB.setValue(nodeCombatant, "currentspace", "number", nSpace);
		end
		if nSpace == 3.75 then
			local tokenCT = CombatManager.getTokenFromCT(nodeCombatant);
			if tokenCT then tokenCT.setScale(0.6) end
		end
		return true;
	end
end

function calculateReach(nodeCombatant)
	local nDU = GameSystem.getDistanceUnitsPerGrid();
	local nBaseReach = DB.getValue(nodeCombatant, "reach", nDU);
	local nCurrentReach = DB.getValue(nodeCombatant, "currentreach", nBaseReach);
	local nReach = nBaseReach;

	local aReachEffects = EffectManager.getEffectsByType(nodeCombatant, "REACH");
	for _,rEffect in ipairs(aReachEffects) do
		if rEffect['mod'] ~= 0 then
			nReach = rEffect.mod;
		elseif not rEffect['dice'][1] then
			for _,sRemainder in ipairs(rEffect['remainder']) do
				if string.lower(sRemainder) == 'none' then
					nReach = 0;
					break;
				end
			end
			if nReach ~= 0 and string.match(string.lower(rEffect['original']), '^reach:%s*0$') then
				nReach = 0;
			end
		end
	end

	local aAddReachEffects = EffectManager.getEffectsByType(nodeCombatant, "ADDREACH");
	for _,rEffect in ipairs(aAddReachEffects) do
		nReach = nReach + rEffect.mod;
	end

	if nReach ~= nCurrentReach then
		if nReach == nBaseReach then
			DB.deleteChild(nodeCombatant, "currentreach");
		else
			DB.setValue(nodeCombatant, "currentreach", "number", nReach);
		end
		return true;
	end
end

function getSizeName(nSize)
	for sName,nMappedSize in pairs(getSizeTable()) do
		if (sName:len() > 1) and (nMappedSize == nSize) then
			return sName;
		end
	end
end

function swapSpaceReach()
	bShouldSwap = true;
end

function resetSpaceReach()
	bShouldSwap = false;
end

function swapSize()
	bShouldSwap = true;
end

function resetSize()
	bShouldSwap = false;
end

function incrementSize(sCurrent, nIncrement)
	local nStart, nEnd = string.find(sCurrent, '%a+');
	local sCurrentSans = string.sub(string.lower(sCurrent), nStart, nEnd);
	local sCurrentRemainder = string.sub(sCurrent, nEnd + 1) or "";
	local tSize = getSizeTable();
	local nSize = tSize[sCurrentSans];
	if not nSize then
		Debug.console("GoBigOrGoGnome.incrementSize - not nSize for "..tostring(sCurrent)..".");
		return false;
	end
	local nSizeNew = nSize + nIncrement;

	local sSizeNew;
	for sSizePredef,nSizeCat in pairs(tSize) do
		if #sSizePredef > 1 and nSizeCat == nSizeNew then
			sSizeNew = StringManager.capitalize(sSizePredef);
			break;
		end
	end
	if sSizeNew then
		if sCurrentRemainder then sSizeNew = sSizeNew..sCurrentRemainder end
		return sSizeNew;
	else
		return false;
	end
end

function forceRedraw(nodeW)
	local nodePath = DB.getPath(nodeW);
	local bOnCT = string.match(nodePath, 'combattracker');
	if bOnCT then
		onCombatantEffectUpdated(DB.getChild(nodeW, 'effects'), true);
	elseif ActorManager.isPC(nodeW) then
		local nodeCT = ActorManager.getCTNode(nodeW);
		if nodeCT then onCombatantEffectUpdated(DB.getChild(nodeCT, 'effects'), true) end
	end
end

function getBaseSize(nodeCT)
	local sBaseSize = DB.getValue(nodeCT, 'size', ""):lower();
	sBaseSize = string.gsub(sBaseSize, "%s+.*$", ""); --removes everything after the first space

	if sBaseSize == "" and Session.RulesetName == 'PFRPG2' then
		local sField;
		if ActorManager.isPC(nodeCT) then
			sField = 'type';
		else
			sField = 'traits';
		end
		local aActorSplit = StringManager.split(DB.getValue(nodeCT, sField, ""):lower(), ", \n", true);
		for _,v in ipairs(aActorSplit) do
			if DataCommon.creaturesize[v] then
				sBaseSize = v;
				break;
			end
		end
	end

	return sBaseSize;
end