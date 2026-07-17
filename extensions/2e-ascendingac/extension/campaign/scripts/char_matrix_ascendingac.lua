--
-- 2E Ascending AC
-- Matrix on the Actions combat strip: for each ascending AC, show the
-- d20 result needed (AC - BAB), written as N+.
--

local AC_MIN = 10;
local AC_MAX = 22;

local sHighlightColor = "a5a7aa";
local sRedColor = "ddaf90"; -- unarmored AC 10

local function formatNeed(n)
	n = tonumber(n) or 10;
	return tostring(n) .. "+";
end

local function getBAB(node)
	if AscendingACManager and AscendingACManager.getBABFromNode then
		return AscendingACManager.getBABFromNode(node);
	end
	if ActorManager.isPC(node) then
		return 20 - DB.getValue(node, "combat.thaco.score", 20);
	end
	return 20 - DB.getValue(node, "thaco", 20);
end

local function setBaseLine(nBAB)
	if self.base_bab_line then
		local s = "BAB +" .. tostring(nBAB);
		if nBAB < 0 then
			s = "BAB " .. tostring(nBAB);
		elseif nBAB == 0 then
			s = "BAB +0";
		end
		self.base_bab_line.setValue(s);
	end
end

-- d20 needed so that d20 + BAB >= AC  =>  d20 >= AC - BAB
local function needVsAC(nBAB, nAC)
	return nAC - nBAB;
end

function onInit()
	local node = getDatabaseNode();
	if ActorManager.isPC(node) then
		DB.addHandler(DB.getPath(node, "combat.thaco.score"), "onUpdate", update);
		DB.addHandler(DB.getPath(node, "combat.bab.score"), "onUpdate", update);
	else
		DB.addHandler(DB.getPath(node, "thaco"), "onUpdate", update);
		DB.addHandler(DB.getPath(node, "bab"), "onUpdate", update);
	end
	createMatrix();
end

function onClose()
	local node = getDatabaseNode();
	if ActorManager.isPC(node) then
		DB.removeHandler(DB.getPath(node, "combat.thaco.score"), "onUpdate", update);
		DB.removeHandler(DB.getPath(node, "combat.bab.score"), "onUpdate", update);
	else
		DB.removeHandler(DB.getPath(node, "thaco"), "onUpdate", update);
		DB.removeHandler(DB.getPath(node, "bab"), "onUpdate", update);
	end
end

function createMatrix()
	local node = getDatabaseNode();
	local nBAB = getBAB(node);
	setBaseLine(nBAB);

	local bHighlight = true;
	for nAC = AC_MIN, AC_MAX, 1 do
		local nNeed = needVsAC(nBAB, nAC);
		local sACName = "asc_matrix_ac_" .. nAC;
		local sNeedName = "asc_matrix_need_" .. nAC;

		local cntNeed = createControl("number_thaco_matrix", sNeedName);
		cntNeed.setFrame(nil);
		cntNeed.setValue(formatNeed(nNeed));

		local cntAC = createControl("label_fieldtop_thaco_matrix", sACName);
		cntAC.setReadOnly(true);
		cntAC.setValue(tostring(nAC));
		cntAC.setAnchor("left", sNeedName, "left", "absolute", 0);

		if nAC == 10 then
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
	local nBAB = getBAB(node);
	setBaseLine(nBAB);
	for nAC = AC_MIN, AC_MAX, 1 do
		local cnt = self["asc_matrix_need_" .. nAC];
		if cnt then
			cnt.setValue(formatNeed(needVsAC(nBAB, nAC)));
		end
	end
end
