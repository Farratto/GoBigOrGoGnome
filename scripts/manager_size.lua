-- Please see the license.txt file included with this distribution for
-- attribution and copyright information.

--luacheck: globals getDBValue addSizeChangedHandler removeSizeChangedHandler invokeSizeChangedHandlers spairs
--luacheck: globals addSpaceChangedHandler removeSpaceChangedHandler invokeSpaceChangedHandlers
--luacheck: globals addReachChangedHandler removeReachChangedHandler invokeReachChangedHandlers
--luacheck: globals getDefaultSize getSizeTable onCurrentSizeChanged onCurrentSpaceChanged
--luacheck: globals onCurrentReachChanged onCurrentDeleted onChildDeleted onCombatantEffectUpdated
--luacheck: globals calculateSize calculateSpace calculateReach getSizeName getSpaceFromSize
--luacheck: globals swapSpaceReach resetSpaceReach swapSize resetSize incrementSize forceRedraw
--luacheck: globals fgetSpaceReachFromActorSize5E getSpaceReachFromActorSize5ESDM
--luacheck: globals fgetSpaceReachFromActorSize4E getSpaceReachFromActorSize4ESDM
--luacheck: globals fgetSpaceReachFromActorSizeD20 getSpaceReachFromActorSizeD20SDM
--luacheck: globals getSpaceReachFromActorSizeCustom
--luacheck: globals fupdateHealthHelper updateHealthHelperSDM
--luacheck: globals handleSlashList handleSlashAdd handleSlashRemove printSlashSyntax isSize removeCustomSize
--luacheck: globals GBOGG_PATH CUSTOM_SIZE_KEY SIZE_PATH
--luacheck: globals storeNewSize storeRulesetSizes applyCustomSizes

GBOGG_PATH = 'GoBigOrGoGnome';
CUSTOM_SIZE_KEY = 'customsizes';
SIZE_PATH = GBOGG_PATH..'.'..CUSTOM_SIZE_KEY;
OOB_MSGTYPE_SIZETYPECHANGE = 'size_type_change'
local getValueOriginal, bShouldSwap, sDeleted;
local tSizeChangedHandlers = {};
local tSpaceChangedHandlers = {};
local tReachChangedHandlers = {};
local tRulesetSizes = {};

function onInit()
	getValueOriginal = DB.getValue;
	DB.getValue = getDBValue;
	fupdateHealthHelper = TokenManager.updateHealthHelper;
	TokenManager.updateHealthHelper = updateHealthHelperSDM;
	fgetSpaceReachFromActorSize5E = ActorCommonManager.getSpaceReachFromActorSize5E;
	ActorCommonManager.getSpaceReachFromActorSize5E = getSpaceReachFromActorSize5ESDM;
	fgetSpaceReachFromActorSize4E = ActorCommonManager.getSpaceReachFromActorSize4E;
	ActorCommonManager.getSpaceReachFromActorSize4E = getSpaceReachFromActorSize4ESDM;
	fgetSpaceReachFromActorSizeD20 = ActorCommonManager.getSpaceReachFromActorSizeD20;
	ActorCommonManager.getSpaceReachFromActorSizeD20 = getSpaceReachFromActorSizeD20SDM;
	ActorCommonManager.setSpaceReachFromActorSizeCallback("D20", SizeManager.getSpaceReachFromActorSizeD20SDM);
	ActorCommonManager.setSpaceReachFromActorSizeCallback("4E", SizeManager.getSpaceReachFromActorSize4ESDM);
	ActorCommonManager.setSpaceReachFromActorSizeCallback("5E", SizeManager.getSpaceReachFromActorSize5ESDM);

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
		-- From 3.5E: Colossal (c) (4) (nSpace*6) (nReach*4)
		if Session.RulesetName == '5E' or Session.RulesetName == '4E' then
			DataCommon.creaturesize['c'] = 4;
			DataCommon.creaturesize['colossal'] = 4;
		end
		storeRulesetSizes();
		Comm.registerSlashHandler("listsize", handleSlashList, "lists creature size table")
		Comm.registerSlashHandler("addsize", handleSlashAdd, "[name] ([n]) [size] and [reach]. e.g. colossal (c) 6 and 4")
		Comm.registerSlashHandler("removesize", handleSlashRemove, "[name]")
		local nodeGBoGG = DB.createNode(GBOGG_PATH);
		DB.setPublic(nodeGBoGG, true);
		DB.createChild(nodeGBoGG, CUSTOM_SIZE_KEY);
	end

	applyCustomSizes();
end

function getDBValue(vFirst, vSecond, ...)
	--[[local sType = type(vFirst);
	if sType == 'undefined' then return ... end
	if sType ~= 'databasenode' then
		if sType ~= 'string' then return ... end
		if not DB.findNode(vFirst) and not string.match(vFirst, '^options%.') then
			return vSecond;
		end
	end]]

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
		local nSizeSpace = ActorCommonManager.getSpaceReachFromActorSize(nSize, Session.RulesetName)
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
	local sCurrentSans = string.lower(string.gsub(sCurrent, '%s+.*$', ''));
	local sCurrentRemainder = string.match(sCurrent, '%(.+%)$');
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
		if sCurrentRemainder then sSizeNew = sSizeNew.." "..sCurrentRemainder end
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

-- From d20 SRD: Fine (-4), Diminutive (-3), Tiny (-2), Small (-1), Medium (0), Large (1), Huge (2), Gargantuan (3), Colossal (4)
function getSpaceReachFromActorSizeD20SDM(nActorSize)
	local nDU = GameSystem.getDistanceUnitsPerGrid();
	local nSpace, nReach;

	if nActorSize < 5 then
		nSpace, nReach = fgetSpaceReachFromActorSizeD20(nActorSize);
	else
		nSpace, nReach = getSpaceReachFromActorSizeCustom(nActorSize);
		if not nSpace then
			nSpace, nReach = fgetSpaceReachFromActorSizeD20(nActorSize);
		end
	end
	if nActorSize == -1 and OptionsManager.isOption('sm_small_size', 'on') and nSpace == nDU then
		nSpace = 0.75 * nSpace;
	end

	if not nReach then nReach = nDU end

	return nSpace, nReach;
end
-- From 4E Rules: Tiny (-2), Small (-1), Medium (0), Large (1), Huge (2), Gargantuan (3)
-- From 3.5E: Colossal (c) (4) (nSpace*6) (nReach*4)
function getSpaceReachFromActorSize4ESDM(nActorSize)
	local nDU = GameSystem.getDistanceUnitsPerGrid();
	local nSpace = nDU;
	local nReach = nSpace;

	if nActorSize < 4 then
		nSpace, nReach = fgetSpaceReachFromActorSize4E(nActorSize);
	elseif nActorSize == 4 then
		nSpace = nSpace * 6;
		nReach = nReach * 4;
	else
		nSpace, nReach = getSpaceReachFromActorSizeCustom(nActorSize);
		if not nSpace then
			nSpace = nSpace * 6;
			nReach = nReach * 4;
		end
	end
	if nActorSize == -1 and OptionsManager.isOption('sm_small_size', 'on') and nSpace == nDU then
		nSpace = 0.75 * nSpace;
	end

	return nSpace, nReach;
end
-- From 5E SRD: Tiny (-2), Small (-1), Medium (0), Large (1), Huge (2), Gargantuan (3)
-- From 3.5E: Colossal (c) (4) (nSpace*6) (nReach*4)
function getSpaceReachFromActorSize5ESDM(nActorSize)
	local nDU = GameSystem.getDistanceUnitsPerGrid();
	local nSpace = nDU;
	local nReach = nSpace;

	if nActorSize < 4 then
		nSpace, nReach = fgetSpaceReachFromActorSize5E(nActorSize);
	elseif nActorSize == 4 then
		nSpace = nSpace * 6;
	else
		nSpace, nReach = getSpaceReachFromActorSizeCustom(nActorSize, nDU);
		if not nSpace then
			nSpace = nSpace * 6;
		end
	end
	if nActorSize == -1 and OptionsManager.isOption('sm_small_size', 'on') and nSpace == nDU then
		nSpace = 0.75 * nSpace;
	end

	if not nReach then nReach = nDU end

	return nSpace, nReach;
end
function getSpaceReachFromActorSizeCustom(nActorSize, nDU)
	if not nDU then nDU = GameSystem.getDistanceUnitsPerGrid() end
	local nSpace = 6;
	local nReach = 1;
	for _, nodeSize in pairs(DB.getChildren(SIZE_PATH)) do
		local nSpcLcl = DB.getValue(nodeSize, 'space');
		local nRchLcl = DB.getValue(nodeSize, 'reach', nReach);
		if DB.getValue(nodeSize, 'ID', 4) == nActorSize then
			nSpace = nSpcLcl;
			nReach = nRchLcl
			break;
		end
		if nSpcLcl > nSpace then
			nSpace = nSpcLcl;
			nReach = nRchLcl;
		end
	end

	nSpace = nSpace * nDU
	nReach = nReach * nDU
	return nSpace, nReach;
end

function updateHealthHelperSDM(tokenCT, nodeCT, ...)
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

	return fupdateHealthHelper(tokenCT, nodeCT, ...);
end

function handleSlashList()
	local tMsg = {};
	tMsg['secret'] = true
	tMsg['text'] = "Size and Reach units are grid spaces.";
	Comm.addChatMessage(tMsg);
	tMsg['text'] = "Example: Size of 5 and Reach of 2 means creature size is 5x5 grid squares with a reach of 2 more grid squares";
	Comm.addChatMessage(tMsg);
	tMsg['text'] = "Name (Brev).........Size and Reach";
	tMsg['font'] = 'narratorfont'
	Comm.addChatMessage(tMsg);
	tMsg['font'] = nil;

	tMsg['text'] = "Default sizes for your ruleset (cannot be changed with slash commands)";
	Comm.addChatMessage(tMsg);
	for _, v in spairs(tRulesetSizes) do
		local sB = v['sBrev'];
		if not sB then sB = " " end
		local sReach = tostring(v['nReach']);
		if not sReach or sReach == "" or sReach == "nil" then sReach = "1" end
		tMsg['text'] = v['sName'].." ("..sB..")............"..tostring(v['nSpace']).." and "..sReach;
		Comm.addChatMessage(tMsg);
	end

	tMsg['font'] = 'narratorfont'
	tMsg['text'] = "Custom Sizes";
	Comm.addChatMessage(tMsg);
	tMsg['font'] = nil;
	local tCustomSizes = {};
	local bFound;
	for _, nodeSize in pairs(DB.getChildren(SIZE_PATH)) do
		local nID = DB.getValue(nodeSize, 'ID');
		local sName = DB.getValue(nodeSize, 'name', "Nameless");
		local sBrev = DB.getValue(nodeSize, 'abbreviation', " ");
		local nSpace = DB.getValue(nodeSize, 'space');
		local nReach = DB.getValue(nodeSize, 'reach', 1);
		local tSizeRecord = {};
		tSizeRecord['sName'] = sName;
		tSizeRecord['sBrev'] = sBrev;
		tSizeRecord['nSpace'] = nSpace;
		tSizeRecord['nReach'] = nReach;
		tCustomSizes[nID] = tSizeRecord;
		bFound = true;
	end
	for _, tSizeRecord in spairs(tCustomSizes) do
		local sSpace = tostring(tSizeRecord['nSpace'] or "");
		local sReach = tostring(tSizeRecord['nReach']);
		tMsg['text'] = tSizeRecord['sName'].." ("..tSizeRecord['sBrev']..")............"..sSpace.." and "..sReach;
		Comm.addChatMessage(tMsg);
	end
	if not bFound then
		tMsg['text'] = "You do not currently have any custom sizes.";
		Comm.addChatMessage(tMsg);
	end
end
function handleSlashAdd(_, sParams)
	local sName = string.match(sParams, '^%a+');
	if not sName then return printSlashSyntax('add') end
	sName = string.lower(sName);

	local tMsg = {};
	tMsg['secret'] = true
	if isSize(sName) then
		tMsg['text'] = "That size name already exists.	If you want to change a custom size, remove it and then re-add it.	You cannot change ruleset sizes with this extension.";
		Comm.addChatMessage(tMsg);
		return false;
	end

	local sSpace = string.match(sParams, '%d+');
	if not sSpace then return printSlashSyntax('add') end
	local nSpace = tonumber(sSpace);
	if isSize(nil, nSpace) then
		tMsg['text'] = "That size number already exists.  If you want to change a custom size, remove it and then re-add it.  You cannot change ruleset sizes with this extension.";
		Comm.addChatMessage(tMsg);
		return false;
	end

	local sReach = string.match(sParams, 'and %d+$');
	if not sReach then sReach = '1' end
	sReach = string.match(sReach, '%d+$');
	local nReach = tonumber(sReach);

	local sBrev = string.match(sParams, '%(%a*%)');
	if #sBrev ~= 3 then return printSlashSyntax('add') end
	sBrev = string.match(sBrev, '%a');
	if isSize(nil, nil, sBrev) then
		tMsg['text'] = "That size abbreviation already exists.	If you want to change a custom size, remove it and then re-add it.	You cannot change ruleset sizes with this extension.  Adding a size does not require an abbreviation letter.  You can just leave out the (letter) in the slash command."; --luacheck: ignore 631
		Comm.addChatMessage(tMsg);
		return false;
	end

	local tCustomSizes = {};
	local nSpaceMax = 6;
	local nIDMax = 4;
	for _, nodeSize in pairs(DB.getChildren(SIZE_PATH)) do
		local nID = DB.getValue(nodeSize, 'ID');
		local tSizeData = {};
		tSizeData['sName'] = DB.getValue(nodeSize, 'name');
		tSizeData['sBrev'] = DB.getValue(nodeSize, 'abbreviation');
		tSizeData['nSpace'] = DB.getValue(nodeSize, 'space');
		tSizeData['nReach'] = DB.getValue(nodeSize, 'reach', 1);
		tSizeData['node'] = nodeSize;
		tCustomSizes[nID] = tSizeData;
		if tSizeData['nSpace'] > nSpaceMax then
			nSpaceMax = tSizeData['nSpace'];
			nIDMax = nID;
		end
	end

	local nIDNew;
	local msgOOB = {};
	msgOOB['type'] = OOB_MSGTYPE_SIZETYPECHANGE;
	if nSpace > nSpaceMax then
		nIDNew = nIDMax + 1;
	else
		local tBooped = {};
		for nID,tSizeData in spairs(tCustomSizes) do
			if nSpace < tSizeData['nSpace'] then
				if not nIDNew then nIDNew = nID end
				table.insert(tBooped, nID);
			end
		end
		for _,nID in pairs(tBooped) do
			local nIDNew = nID + 1;
			local nodeSize = tCustomSizes[nID]['node'];
			local sNmLcl = tCustomSizes[nID]['sName'];
			local sBrvLcl = tCustomSizes[nID]['sBrev'];
			DataCommon.creaturesize[sNmLcl] = nIDNew;
			DB.setValue(nodeSize, 'ID', 'number', nIDNew);
			msgOOB['sName'] = sNmLcl;
			msgOOB['sID'] = tostring(nIDNew);
			Comm.deliverOOBMessage(msgOOB);
			if sBrvLcl then
				DataCommon.creaturesize[sBrvLcl] = nIDNew;
				msgOOB['sName'] = sBrvLcl;
				msgOOB['sID'] = tostring(nIDNew);
				Comm.deliverOOBMessage(msgOOB);
			end
		end
	end

	if storeNewSize(nIDNew, sName, nSpace, nReach or 1, sBrev) then
		handleSlashList();
	end
end
function handleSlashRemove(_, sParams)
	local sParams = StringManager.trim(sParams);
	local nSpace = tonumber(sParams);
	local sName, sBrev;
	if not nSpace then
		if #sParams == 1 then
			sBrev = sParams;
		else
			sName = sParams;
		end
	end

	local bIsSize, bIsCustomSize = isSize(sName, nSpace, sBrev);

	local tMsg = {};
	tMsg['secret'] = true
	if not bIsSize then
		tMsg['text'] = "That size does not exist.";
		Comm.addChatMessage(tMsg);
		return printSlashSyntax('remove');
	end
	if not bIsCustomSize then
		tMsg['text'] = "You cannot remove a ruleset size with this extension.";
		Comm.addChatMessage(tMsg);
	end

	if removeCustomSize(nil, nil, sName, sBrev, nSpace) then
		handleSlashList();
		return true;
	else
		Debug.console("GoBigOrGoGnome.handleSlashRemove - removeCustomSize returned false");
		return false;
	end
end
function printSlashSyntax(sWhich)
	local tMsg = {};
	tMsg['secret'] = true
	if sWhich == 'add' then
		tMsg['text'] = "Syntax for adding a new custom size: (if you want to change a size, remove and re-add it)";
		Comm.addChatMessage(tMsg);
		tMsg['text'] = "/addsize [name] ([n]) [size] and [reach]";
		Comm.addChatMessage(tMsg);
		tMsg['text'] = "e.g. /addsize colossal (c) 6 and 4";
		Comm.addChatMessage(tMsg);
	elseif sWhich == 'remove' then
		tMsg['text'] = "Syntax for removing a custom size:	Will not work on ruleset sizes.";
		Comm.addChatMessage(tMsg);
		tMsg['text'] = "/removesize [size name] OR [size abbreviation] OR [size number]";
		Comm.addChatMessage(tMsg);
		tMsg['text'] = "e.g. /removesize colosal OR /removesize c OR /removesize 6";
		Comm.addChatMessage(tMsg);
	end
end
function isSize(sName, nSpace, sBrev)
	local bRulesetSize = false;
	for _, tSizeRecord in pairs(tRulesetSizes) do
		if (sName and sName == tSizeRecord['sName'])
			or (sBrev and sBrev == tSizeRecord['sBrev'])
			or (nSpace and nSpace == tSizeRecord['nSpace'])
		then
			bRulesetSize = true;
			break;
		end
	end

	local bCustomSize = false;
	for _, nodeSize in pairs(DB.getChildren(SIZE_PATH)) do
		if sName then
			local sNmLcl = DB.getValue(nodeSize, 'name');
			if sNmLcl and sName == sNmLcl then
				bCustomSize = true;
				break;
			end
		end
		if sBrev then
			local sBrvLcl = DB.getValue(nodeSize, 'abbreviation');
			if sBrvLcl and sBrev == sBrvLcl then
				bCustomSize = true;
				break;
			end
		end
		if nSpace then
			local nSpcLcl = DB.getValue(nodeSize, 'space');
			if nSpcLcl and nSpace == nSpcLcl then
				bCustomSize = true;
				break;
			end
		end
	end

	return bRulesetSize or bCustomSize, bCustomSize;
end
function storeNewSize(nID, sName, nSpace, nReach, sBrev)
	local nodeNewSize = DB.createChild(SIZE_PATH);
	if not nodeNewSize then
		Debug.console("GoBigOrGoGnome.storeNewSize - not nodeNewSize");
		return false;
	end

	DB.setValue(nodeNewSize, 'ID', 'number', nID);
	DB.setValue(nodeNewSize, 'name', 'string', sName);
	DB.setValue(nodeNewSize, 'space', 'number', nSpace);
	DB.setValue(nodeNewSize, 'reach', 'number', nReach or 1);
	if sBrev then
		DB.setValue(nodeNewSize, 'abbreviation', 'string', sBrev);
		DataCommon.creaturesize[sBrev] = nID;
	end
	DataCommon.creaturesize[sName] = nID;

	local msgOOB = {};
	msgOOB['type'] = OOB_MSGTYPE_SIZETYPECHANGE;
	msgOOB['sName'] = sName;
	msgOOB['sID'] = tostring(nID);
	Comm.deliverOOBMessage(msgOOB);

	return nodeNewSize;
end
function removeCustomSize(nodeSize, nID, sName, sBrev, nSpace)
	if not nodeSize then
		for _, nodeSzLcl in pairs(DB.getChildren(SIZE_PATH)) do
			if nID then
				local nIDLcl = DB.getValue(nodeSzLcl, 'ID');
				if nIDLcl and nID == nIDLcl then
					nodeSize = nodeSzLcl;
					break;
				end
			end
			if sName then
				local sNmLcl = DB.getValue(nodeSzLcl, 'name');
				if sNmLcl and sName == sNmLcl then
					nodeSize = nodeSzLcl;
					break;
				end
			end
			if sBrev then
				local sBrvLcl = DB.getValue(nodeSzLcl, 'abbreviation');
				if sBrvLcl and sBrev == sBrvLcl then
					nodeSize = nodeSzLcl;
					break;
				end
			end
			if nSpace then
				local nSpcLcl = DB.getValue(nodeSzLcl, 'space');
				if nSpcLcl and nSpace == nSpcLcl then
					nodeSize = nodeSzLcl;
					break;
				end
			end
		end
	end
	if not nodeSize then
		Debug.console("GoBigOrGoGnome.removeCustomSize - not nodeSize");
		return false;
	end
	local nID = DB.getValue(nodeSize, 'ID');
	if not nID then
		Debug.console("GoBigOrGoGnome.removeCustomSize - not nID for "..DB.getPath(nodeSize));
		return false;
	end

	local msgOOB = {};
	msgOOB['type'] = OOB_MSGTYPE_SIZETYPECHANGE;
	for _, nodeSzLcl in pairs(DB.getChildren(SIZE_PATH)) do
		local nIDLcl = DB.getValue(nodeSzLcl, 'ID');
		if not nIDLcl then
			Debug.console("GoBigOrGoGnome.removeCustomSize - not nIDLcl for "..DB.getPath(nIDLcl));
			return false;
		end
		if nID < nIDLcl then
			local nIDNew = nIDLcl - 1;
			local sNmLcl = DB.getValue(nodeSzLcl, 'name');
			local sBrvLcl = DB.getValue(nodeSzLcl, 'abbreviation');
			DataCommon.creaturesize[sNmLcl] = nIDNew;
			DB.setValue(nodeSzLcl, 'ID', 'number', nIDNew);
			msgOOB['sName'] = sNmLcl;
			msgOOB['sID'] = tostring(nIDNew);
			Comm.deliverOOBMessage(msgOOB);
			if sBrvLcl then
				DataCommon.creaturesize[sBrvLcl] = nIDNew;
				msgOOB['sName'] = sBrvLcl;
				msgOOB['sID'] = tostring(nIDNew);
				Comm.deliverOOBMessage(msgOOB);
			end
		end
	end

	if not sName then sName = DB.getValue(nodeSize, 'name') end
	if not sBrev then sBrev = DB.getValue(nodeSize, 'abbreviation') end
	DataCommon.creaturesize[sName] = nil;
	msgOOB['sName'] = sName;
	msgOOB['sID'] = 'remove';
	Comm.deliverOOBMessage(msgOOB);
	if sBrev then
		DataCommon.creaturesize[sBrev] = nil;
		msgOOB['sName'] = sBrev;
		msgOOB['sID'] = 'remove';
		Comm.deliverOOBMessage(msgOOB);
	end
	DB.deleteNode(nodeSize);
	return true;
end
function handleSizeTypeChange(msgOOB)
	if Session.IsHost then return end

	local nID = tonumber(msgOOB['sID']);
	DataCommon.creaturesize[msgOOB['sName']] = nID;
end

function storeRulesetSizes()
	local nDU = GameSystem.getDistanceUnitsPerGrid();
	for sKey, nIndex in pairs(DataCommon.creaturesize) do
		local bBrev, nSpace, nReach, sBrev, sName;
		if #sKey == 1 then bBrev = true end
		if tRulesetSizes[nIndex] then
			nSpace = tRulesetSizes[nIndex]['nSpace'];
			nReach = tRulesetSizes[nIndex]['nReach'];
			if bBrev then
				sBrev = sKey;
				sName = tRulesetSizes[nIndex]['sName'];
			else
				sName = sKey;
				sBrev = tRulesetSizes[nIndex]['sBrev'];
			end
		else
			tRulesetSizes[nIndex] = {};
			nSpace, nReach = ActorCommonManager.getSpaceReachFromActorSize(nIndex, Session.RulesetName);
			nSpace = nSpace / nDU;
			nReach = nReach / nDU;
			if bBrev then
				sBrev = sKey;
			else
				sName = sKey;
			end
		end
		local tSizeRecord = {};
		tSizeRecord['nSpace'] = nSpace;
		tSizeRecord['nReach'] = nReach;
		tSizeRecord['sBrev'] = sBrev;
		tSizeRecord['sName'] = sName;
		tRulesetSizes[nIndex] = tSizeRecord;
	end
end
function applyCustomSizes()
	for _, nodeSize in pairs(DB.getChildren(SIZE_PATH)) do
		local sName = DB.getValue(nodeSize, 'name');
		local sBrev = DB.getValue(nodeSize, 'abbreviation');
		local nID = DB.getValue(nodeSize, 'ID');
		if sName then
			DataCommon.creaturesize[sName] = nID;
		end
		if sBrev then
			DataCommon.creaturesize[sBrev] = nID;
		end
	end
end

--from https://stackoverflow.com/questions/15706270/sort-a-table-in-lua
function spairs(t, order)
	-- collect the keys
	local keys = {};
	for k in pairs(t) do keys[#keys+1] = k end

	-- if order function given, sort by it by passing the table and keys a, b,
	-- otherwise just sort the keys
	if order then
		table.sort(keys, function(a,b) return order(t, a, b) end);
	else
		table.sort(keys);
	end

	-- return the iterator function
	local i = 0;
	return function()
		i = i + 1;
		if keys[i] then
			return keys[i], t[keys[i]];
		end
	end
end