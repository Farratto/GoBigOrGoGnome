-- Please see the license.txt file included with this distribution for
-- attribution and copyright information.

--luacheck: globals fgetSpaceReachFromActorSize5E getSpaceReachFromActorSize5ESDM
--luacheck: globals fgetSpaceReachFromActorSize4E getSpaceReachFromActorSize4ESDM
--luacheck: globals fgetSpaceReachFromActorSizeD20 getSpaceReachFromActorSizeD20SDM
--luacheck: globals getSpaceReachFromActorSizeCustom getRSSizeType sRSSizeType
--luacheck: globals fgetNPCSpaceReach getNPCSpaceReachPFRPG2SM getNPCSpaceReachADNDSM
--luacheck: globals GBOGG_PATH CUSTOM_SIZE_KEY SIZE_PATH
--luacheck: globals handleSlashList handleSlashAdd handleSlashRemove printSlashSyntax isSize removeCustomSize
--luacheck: globals storeNewSize storeRulesetSizes applyCustomSizes spairs

GBOGG_PATH = 'GoBigOrGoGnome';
CUSTOM_SIZE_KEY = 'customsizes';
SIZE_PATH = GBOGG_PATH..'.'..CUSTOM_SIZE_KEY;
local tRulesetSizes = {};

function onInit()
	fgetSpaceReachFromActorSize5E = ActorCommonManager.getSpaceReachFromActorSize5E;
	ActorCommonManager.getSpaceReachFromActorSize5E = getSpaceReachFromActorSize5ESDM;
	fgetSpaceReachFromActorSize4E = ActorCommonManager.getSpaceReachFromActorSize4E;
	ActorCommonManager.getSpaceReachFromActorSize4E = getSpaceReachFromActorSize4ESDM;
	fgetSpaceReachFromActorSizeD20 = ActorCommonManager.getSpaceReachFromActorSizeD20;
	ActorCommonManager.getSpaceReachFromActorSizeD20 = getSpaceReachFromActorSizeD20SDM;
	ActorCommonManager.setSpaceReachFromActorSizeCallback("D20", getSpaceReachFromActorSizeD20SDM);
	ActorCommonManager.setSpaceReachFromActorSizeCallback("4E", getSpaceReachFromActorSize4ESDM);
	ActorCommonManager.setSpaceReachFromActorSizeCallback("5E", getSpaceReachFromActorSize5ESDM);

	if CombatRecordManagerADND and CombatRecordManagerADND.getNPCSpaceReach then
		fgetNPCSpaceReach = CombatRecordManagerADND.getNPCSpaceReach;
		CombatRecordManagerADND.getNPCSpaceReach = getNPCSpaceReachADNDSM;
		ActorCommonManager.setRecordTypeSpaceReachCallback("npc", getNPCSpaceReachADNDSM);
	end
	if Session.RulesetName == 'PFRPG2' then
		fgetNPCSpaceReach = CombatManager2.getNPCSpaceReach;
		CombatManager2.getNPCSpaceReach = getNPCSpaceReachPFRPG2SM;
		ActorCommonManager.setRecordTypeSpaceReachCallback("npc", getNPCSpaceReachPFRPG2SM);
	end

	if not ActorCommonManager.hasRecordTypeSpaceReachCallback("charsheet") then
		local npcSpaceReachCallback = ActorCommonManager.getRecordTypeSpaceReachCallback("npc");
		ActorCommonManager.getRecordTypeSpaceReachCallback("charsheet", npcSpaceReachCallback);
	end

	sRSSizeType = getRSSizeType();

	if Session.IsHost then
		local nodeGBoGG = DB.createNode(GBOGG_PATH);
		DB.setPublic(nodeGBoGG, true);
		DB.createChild(nodeGBoGG, CUSTOM_SIZE_KEY);
		storeRulesetSizes();
		Comm.registerSlashHandler("listsize", handleSlashList, "lists creature size table")
		Comm.registerSlashHandler("addsize", handleSlashAdd, "[name] ([n]) [size] and [reach]. e.g. colossal (c) 6 and 4")
		Comm.registerSlashHandler("removesize", handleSlashRemove, "[name]")
	end

	applyCustomSizes();
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
	local bFound = false;
	for _, nodeSize in pairs(DB.getChildren(SIZE_PATH)) do
		local nSpcLcl = DB.getValue(nodeSize, 'space');
		local nRchLcl = DB.getValue(nodeSize, 'reach', nReach);
		if DB.getValue(nodeSize, 'ID', 4) == nActorSize then
			nSpace = nSpcLcl;
			nReach = nRchLcl;
			bFound = true;
			break;
		end
		if nSpcLcl > nSpace then
			nSpace = nSpcLcl;
			nReach = nRchLcl;
		end
	end

	nSpace = nSpace * nDU
	nReach = nReach * nDU
	return nSpace, nReach, bFound;
end

function getNPCSpaceReachPFRPG2SM(rActor)
	local nActorSize = 0;
	local nodeActor = ActorManager.getCreatureNode(rActor);
	if nodeActor then
		local sField = "traits";
		if ActorManager.isPC(rActor) then sField = "size" end

		local aActorSplit = StringManager.split(DB.getValue(nodeActor, sField, ""):lower(), ", \n", true);
		for _,v in ipairs(aActorSplit) do
			if not nActorSize and DataCommon.creaturesize[v] then
				nActorSize = DataCommon.creaturesize[v];
				break;
			end
		end
	end

	local nSpace = GameSystem.getDistanceUnitsPerGrid();
	local nReach = nSpace;
	if nActorSize < -1 then
		-- Tiny or smaller
		nSpace = 0.5;
		nReach = 0;
	elseif nActorSize > -1 then
		local bFound;
		nSpace, nReach, bFound = getSpaceReachFromActorSizeCustom(nActorSize, nSpace);
		if not bFound then
			nSpace = nSpace * (nActorSize + 1);
			nReach = nReach * (nActorSize + 1);
		end
	end

	-- Check melee weapon attack traits for reach.
	local sMeleeAttacks = DB.getValue(nodeActor, "meleeatk", "");
	if sMeleeAttacks ~= "" then
		for sReach in string.gmatch(sMeleeAttacks, "reach (%d+) feet") do
			GlobalDebug.consoleObjects("SizeManager.getNPCSpaceReachPFRPG2SM - sReach = ", sReach);
			if StringManager.isNumberString(sReach) then
				local nAttackReach = tonumber(sReach);
				if nAttackReach > nReach then
					nReach = nAttackReach;
				end
			end
		end
	end

	return nSpace, nReach;
end

function getNPCSpaceReachADNDSM(rActor)
    local nSpace = GameSystem.getDistanceUnitsPerGrid();
    local nReach = nSpace;

    local nodeActor = ActorManager.getCreatureNode(rActor);
    if not nodeActor then
        return nSpace, nReach;
    end

	local nActorSize, bFound;
	local sSizeLower = string.lower(DB.getValue(nodeActor, "size", ""));
	local aActorSplit = StringManager.split(sSizeLower, " \n,", true);
	for _,sSizeID in ipairs(aActorSplit) do
		if DataCommon.creaturesize[sSizeID] then
			nActorSize = DataCommon.creaturesize[sSizeID];
			break;
		end
	end
	if not nActorSize then nActorSize = 3 end

	if nActorSize == 4.5 then
        nSpace = nSpace * 2;
    elseif nActorSize == 5 then
        nSpace = nSpace * 3;
    elseif nActorSize == 6 then
        nSpace = nSpace * 4;
    elseif nActorSize == 7 then
        nSpace = nSpace * 6;
	else
		nSpace, nReach, bFound = getSpaceReachFromActorSizeCustom(nActorSize, nSpace);
		if not bFound then
			nSpace = GameSystem.getDistanceUnitsPerGrid();
			nReach = nSpace;
		end
	end

    -- allow custom TOKEN_SIZE: XX
    if sSizeLower:find("token_size:%s?%d+") then
        local sTokenSize = sSizeLower:match("token_size:%s?(%d+)");
        nSpace = tonumber(sTokenSize) or 5;
    end
    -- allow custom TOKEN_REACH: XX
    if sSizeLower:find("token_reach:%s?%d+") then
        local sTokenReach = sSizeLower:match("token_reach:%s?(%d+)");
        nReach = tonumber(sTokenReach) or 5;
    end

    return nSpace, nReach;
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
	if not sParams or sParams == "" then return printSlashSyntax('add') end

	local sName = string.match(string.lower(sParams), '^%a+');
	if not sName then return printSlashSyntax('add') end

	local tMsg = {};
	tMsg['secret'] = true
	if isSize(sName) then
		tMsg['text'] = "That size name already exists.	If you want to change a custom size, remove it and then re-add it.	You cannot change ruleset sizes with this extension."; --luacheck: ignore 631
		Comm.addChatMessage(tMsg);
		return false;
	end

	local sSpace = string.match(sParams, '%d+');
	if not sSpace then return printSlashSyntax('add') end
	local nSpace = tonumber(sSpace);
	if isSize(nil, nSpace) then
		tMsg['text'] = "That size number already exists.  If you want to change a custom size, remove it and then re-add it.  You cannot change ruleset sizes with this extension."; --luacheck: ignore 631
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
	if not sParams or sParams == "" then
		return printSlashSyntax('remove');
	end

	local sParams = StringManager.trim(string.lower(sParams));
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
			nSpace, nReach = ActorCommonManager.getSpaceReachFromActorSize(nIndex, sRSSizeType);
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

function getRSSizeType()
	local sRS = Session.RulesetName;
	if sRS == '5E' then return '5E' end
	if sRS == '4E' then return '4E' end
	return 'D20';
end