-- Please see the license.txt file included with this distribution for
-- attribution and copyright information.

--luacheck: globals getDBValue addSizeChangedHandler removeSizeChangedHandler invokeSizeChangedHandlers
--luacheck: globals addSpaceChangedHandler removeSpaceChangedHandler invokeSpaceChangedHandlers
--luacheck: globals addReachChangedHandler removeReachChangedHandler invokeReachChangedHandlers
--luacheck: globals getDefaultSize getSizeTable onCurrentSizeChanged onCurrentSpaceChanged
--luacheck: globals onCurrentReachChanged onCurrentDeleted onChildDeleted onCombatantEffectUpdated
--luacheck: globals calculateSize calculateSpace calculateReach getSizeName getSpaceFromSize
--luacheck: globals swapSpaceReach resetSpaceReach swapSize resetSize incrementSize forceRedraw

local getValueOriginal;

local tSizeChangedHandlers = {};
local tSpaceChangedHandlers = {};
local tReachChangedHandlers = {};

local bShouldSwap;
local sDeleted;

function onInit()
	getValueOriginal = DB.getValue;
	DB.getValue = getDBValue;

	if Session.IsHost then
		DB.addHandler(CombatManager.CT_COMBATANT_PATH .. ".currentsize", "onUpdate", onCurrentSizeChanged);
		DB.addHandler(CombatManager.CT_COMBATANT_PATH .. ".currentspace", "onUpdate", onCurrentSpaceChanged);
		DB.addHandler(CombatManager.CT_COMBATANT_PATH .. ".currentreach", "onUpdate", onCurrentReachChanged);
		DB.addHandler(CombatManager.CT_COMBATANT_PATH .. ".currentsize", "onDelete", onCurrentDeleted);
		DB.addHandler(CombatManager.CT_COMBATANT_PATH .. ".currentspace", "onDelete", onCurrentDeleted);
		DB.addHandler(CombatManager.CT_COMBATANT_PATH .. ".currentreach", "onDelete", onCurrentDeleted);
		DB.addHandler(CombatManager.CT_COMBATANT_PATH, "onChildDeleted", onChildDeleted);
		DB.addHandler(CombatManager.CT_COMBATANT_PATH .. ".effects", "onChildUpdate", onCombatantEffectUpdated);
		OptionsManager.registerOptionData({ sKey = 'sm_small_size', sGroupRes = 'option_header_size_matters'
			, tCustom = { default = "on" }
		});
	end
end

function getDBValue(vFirst, vSecond, ...)
	if bShouldSwap then
		if vSecond == "size" then
			local nodeCT = ActorManager.getCTNode(vFirst)
			local vCurrent = getValueOriginal(nodeCT, "currentsize");
			if vCurrent then
				return vCurrent;
			end
		elseif vSecond == "space" then
			local nodeCT = ActorManager.getCTNode(vFirst)
			local vCurrent = getValueOriginal(nodeCT, "currentspace");
			if vCurrent then
				return vCurrent;
			end
		elseif vSecond == "reach" then
			local nodeCT = ActorManager.getCTNode(vFirst)
			local vCurrent = getValueOriginal(nodeCT, "currentreach");
			if vCurrent then
				return vCurrent;
			end
		end
	end
	if vSecond then
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
	if tSize and tSize["medium"] then
		return tSize["medium"];
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
	if sDeleted == "currentsize" then
		invokeSizeChangedHandlers(nodeCombatant);
	elseif sDeleted == "currentspace" then
		invokeSpaceChangedHandlers(nodeCombatant);
	elseif sDeleted == "currentreach" then
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
	local sBaseSize = DB.getValue(nodeCombatant, "size", ""):lower();
	sBaseSize = string.gsub(sBaseSize, '%s+.*$', ''); --removes everything after the first space
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

	local nMin = 1000;
	local nMax = -1000;
	for _,nMappedSize in pairs(tSize) do
		if nMappedSize < nMin then
			nMin = nMappedSize;
		end
		if nMax < nMappedSize then
			nMax = nMappedSize;
		end
	end
	nSize = math.max(nMin, math.min(nSize, nMax));

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
		local nSizeSpace = getSpaceFromSize(nSize, nDU);
		--local nSizeSpace = ActorCommonManager.getSpaceReachFromActorSize(nSize, Session.RulesetName);
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

function getSpaceFromSize(nSize, nDU)
	-- Scale by increments over default.
--[[
	local nDefaultSize = getDefaultSize();
	if nDefaultSize then
		--return nDU * math.max(1, nSize + 1 - nDefaultSize);
		local nReturn = nSize + 1 - nDefaultSize;
		if nReturn < 0.5 then
			if Session.RulesetName == '5E' then
				if nReturn == 0 then
					nReturn = 1;
				elseif nReturn == -1 then
					nReturn = 0.5;
				else
					nReturn = 1;
				end
			else
				nReturn = 1;
			end
		end
		return nReturn * nDU;
	end
]]
	--not RAW but seems cool.  I'll make an option if anyone complains.
	--if Session.RulesetName == '5E' and OptionsManager.isOption('sm_small_size', 'on') and nSize == -1 then
	if Session.RulesetName == '5E' and OptionsManager.isOption('sm_small_size', 'on') and nSize == -1 then
		if not nDU then nDU = GameSystem.getDistanceUnitsPerGrid() end
		return nDU * 0.75;
	end

	return ActorCommonManager.getSpaceReachFromActorSize(nSize, Session.RulesetName);
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
	local sCurrentSans = string.lower(string.gsub(sCurrent, '%s+.*$', ''));
	local sCurrentRemainder = string.match(sCurrent, '%(.+%)$');
	local tSize = getSizeTable();
	local nSize = tSize[sCurrentSans];
	if not nSize then return false end
	local nSizeNew = nSize + nIncrement;

	local sSizeNew;
	for sSizePredef,nSizeCat in pairs(tSize) do
		if #sSizePredef > 1 and nSizeCat == nSizeNew then
			sSizeNew = StringManager.capitalize(sSizePredef);
			break;
		end
	end
	if sSizeNew then
		if sCurrentRemainder then sSizeNew = sSizeNew.." "..sCurrentRemainder end
		--setValue(sSizeNew);
		return sSizeNew;
	else
		return false;
	end
end

function forceRedraw(nodeW)
	local nodePath = DB.getPath(nodeW);
	local bOnCT = string.match(nodePath, 'combattracker');
	if bOnCT then
		SizeManager.onCombatantEffectUpdated(DB.getChild(nodeW, 'effects'), true);
	elseif ActorManager.isPC(nodeW) then
		local nodeCT = ActorManager.getCTNode(nodeW);
		if nodeCT then SizeManager.onCombatantEffectUpdated(DB.getChild(nodeCT, 'effects'), true) end
	end
end