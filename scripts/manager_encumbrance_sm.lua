-- Please see the license.txt file included with this distribution for
-- attribution and copyright information.

--luacheck: globals getEncumbranceMult onSizeChanged

local getEncumbranceMultOriginal;

function onInit()
	if CharEncumbranceManager5E then
		getEncumbranceMultOriginal = CharEncumbranceManager5E.getEncumbranceMult;
		CharEncumbranceManager5E.getEncumbranceMult = getEncumbranceMult;

		SizeManager.addSizeChangedHandler(onSizeChanged);
	end
end

function getEncumbranceMult(nodeChar)
	SizeManager.swapSize();
	local result = getEncumbranceMultOriginal(nodeChar);
	SizeManager.resetSize();
	return result;
end

--[[function onSizeChanged(nodeCombatant)
	local sType,nodeChar = ActorManager.getTypeAndNode(nodeCombatant);
	-- ItemPowerManager is provided by Kit'N'Kaboodle, if present NPCs have inventories as well.
	if (sType == "pc") or ItemPowerManager then
		CharEncumbranceManager5E.updateEncumbranceLimit(nodeChar)
	end
end]]
function onSizeChanged(nodeCombatant)
	local rActor = ActorManager.resolveActor(nodeCombatant);
	if rActor then
		if ActorManager.isPC(rActor) or ItemPowerManager then
			local nodeCreature = ActorManager.getCreatureNode(rActor);
			if nodeCreature and DB.isOwner(nodeCreature) then
				CharEncumbranceManager5E.updateEncumbranceLimit(nodeCreature);
			end
		end
	end
end