--
-- 2E Attack Throw
-- Centered Attack Throw matrix for the Actions-tab Combat section.
--
-- ACKS II ascending Armor Class:
--   unarmored = AC 0; higher AC is better.
--   Need to hit = Base Attack Throw + target AC.
--
-- Columns: AC 0 .. AC_MAX (left = unarmored). Cells show the target as N+.
--

local AC_MIN = 0;
local AC_MAX = 12;

local sHighlightColor = "a5a7aa";
local sRedColor = "ddaf90"; -- highlight unarmored (AC 0)

local function formatThrow(n)
	n = tonumber(n) or 10;
	return tostring(n) .. "+";
end

local function getThrowValue(node)
	if AttackThrowManager and AttackThrowManager.getAttackThrowFromNode then
		return AttackThrowManager.getAttackThrowFromNode(node);
	end
	if ActorManager.isPC(node) then
		return DB.getValue(node, "combat.attackthrow.score", 10);
	end
	local nTHACO = DB.getValue(node, "thaco", 20);
	return nTHACO - 10;
end

local function needVsAscendingAC(nThrow, nAC)
	return nThrow + nAC;
end

local function setBaseLine(nThrow)
	if self.base_throw_line then
		self.base_throw_line.setValue("Base " .. formatThrow(nThrow));
	end
end

function onInit()
	local node = getDatabaseNode();
	if ActorManager.isPC(node) then
		DB.addHandler(DB.getPath(node, "combat.attackthrow.score"), "onUpdate", update);
		DB.addHandler(DB.getPath(node, "combat.thaco.score"), "onUpdate", update);
		DB.addHandler(DB.getPath(node, "classes"), "onChildUpdate", update);
	else
		DB.addHandler(DB.getPath(node, "thaco"), "onUpdate", update);
		DB.addHandler(DB.getPath(node, "hitDice"), "onUpdate", update);
		DB.addHandler(DB.getPath(node, "attackthrow"), "onUpdate", update);
	end
	createAttackThrowMatrix();
end

function onClose()
	local node = getDatabaseNode();
	if ActorManager.isPC(node) then
		DB.removeHandler(DB.getPath(node, "combat.attackthrow.score"), "onUpdate", update);
		DB.removeHandler(DB.getPath(node, "combat.thaco.score"), "onUpdate", update);
		DB.removeHandler(DB.getPath(node, "classes"), "onChildUpdate", update);
	else
		DB.removeHandler(DB.getPath(node, "thaco"), "onUpdate", update);
		DB.removeHandler(DB.getPath(node, "hitDice"), "onUpdate", update);
		DB.removeHandler(DB.getPath(node, "attackthrow"), "onUpdate", update);
	end
end

function createAttackThrowMatrix()
	local node = getDatabaseNode();
	local nThrow = getThrowValue(node);
	setBaseLine(nThrow);

	local bHighlight = true;
	for nAC = AC_MIN, AC_MAX, 1 do
		local nNeed = needVsAscendingAC(nThrow, nAC);
		local sACName = "atk_matrix_ac_" .. nAC;
		local sNeedName = "atk_matrix_need_" .. nAC;

		local cntNeed = createControl("number_thaco_matrix", sNeedName);
		cntNeed.setFrame(nil);
		cntNeed.setValue(formatThrow(nNeed));

		local cntAC = createControl("label_fieldtop_thaco_matrix", sACName);
		cntAC.setReadOnly(true);
		cntAC.setValue(tostring(nAC));
		cntAC.setAnchor("left", sNeedName, "left", "absolute", 0);

		if nAC == 0 then
			cntNeed.setBackColor(sRedColor);
			cntAC.setBackColor(sRedColor);
		elseif bHighlight then
			cntNeed.setBackColor(sHighlightColor);
			cntAC.setBackColor(sHighlightColor);
		end

		bHighlight = not bHighlight;
	end
end

function update()
	local node = getDatabaseNode();
	local nThrow = getThrowValue(node);
	setBaseLine(nThrow);

	for nAC = AC_MIN, AC_MAX, 1 do
		local sNeedName = "atk_matrix_need_" .. nAC;
		local cnt = self[sNeedName];
		if cnt then
			cnt.setValue(formatThrow(needVsAscendingAC(nThrow, nAC)));
		end
	end
end
