--
-- 2E Skill Throw
-- Copy of the stock ruleset's campaign/scripts/number_charskill.lua with
-- one change: onSourceUpdate treats stat == "throw" the same as
-- stat == "percent" (base value comes from the manually-entered
-- base_check field, not a derived ability score). Everything else,
-- including action()/onDragStart()/onDoubleClick(), is unchanged - the
-- roll itself is redirected by scripts/manager_skillthrow.lua, which
-- reads the "total" this script computes as the roll's target.
--

function onInit()
	local nodeChar = DB.getChild(window.getDatabaseNode(), "...");
	DB.addHandler(DB.getPath(nodeChar, "abilities.*.score"), "onUpdate", onSourceUpdate);
	DB.addHandler(DB.getPath(nodeChar, "profbonus"), "onUpdate", onSourceUpdate);

	addSource("adj_class");
	addSource("adj_armor");
	addSource("adj_mod");
	addSource("adj_racial");
	addSource("adj_stat");
	addSource("base_check");

	addSource("stat", "string");
	addSource("prof");
	addSourceWithOp("misc", "+");

	super.onInit();
end
function onClose()
	local nodeChar = DB.getChild(window.getDatabaseNode(), "...");
	DB.removeHandler(DB.getPath(nodeChar, "abilities.*.score"), "onUpdate", onSourceUpdate);
	DB.removeHandler(DB.getPath(nodeChar, "profbonus"), "onUpdate", onSourceUpdate);
end

function onSourceUpdate(node)
	local nValue = 0;

	local nodeSkill = window.getDatabaseNode();
	local nodeChar = DB.getChild(nodeSkill, "...");

	local sAbility = DB.getValue(nodeSkill, "stat", "");

	local nBaseCheck = DB.getValue(nodeSkill, "base_check", 0);
	local nClassADJ = DB.getValue(nodeSkill, "adj_class", 0);
	local nArmorADJ = DB.getValue(nodeSkill, "adj_armor", 0);
	local nRacialADJ = DB.getValue(nodeSkill, "adj_racial", 0);
	local nStatADJ = DB.getValue(nodeSkill, "adj_stat", 0);
	local nModADJ = DB.getValue(nodeSkill, "adj_mod", 0);
	local nMisc = DB.getValue(nodeSkill, "misc", 0);
	if sAbility == "percent" or sAbility == "throw" then
		nValue = nValue + nBaseCheck;
	elseif sAbility ~= "" then
		local nAbilityScore = DB.getValue(nodeChar, "abilities." .. sAbility .. ".score", 0);
		nValue = nValue + nAbilityScore;
	end

	nValue = nValue + nClassADJ + nModADJ + nStatADJ + nArmorADJ + nRacialADJ + nMisc;
	setValue(nValue);
end

function action(draginfo)
	local nodeSkill = window.getDatabaseNode();
	local nodeChar = DB.getChild(nodeSkill, "...");
	local rActor = ActorManager.resolveActor(nodeChar);
	local sAbility = DB.getValue(nodeSkill, "stat", "");
	local nTargetDC = DB.getValue(nodeSkill, "total", 20);

	ActionSkill.performRoll(draginfo, rActor, nodeSkill, nTargetDC);
	return true;
end

function onDragStart(button, x, y, draginfo)
	return action(draginfo);
end

function onDoubleClick(x, y)
	return action();
end
