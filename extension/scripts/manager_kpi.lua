--
-- 2E KPI - Kits, Parcels, and Items
--
-- Kits hold a simple list of links to Treasure Parcels. Applying a Kit to a
-- character unpacks each linked Parcel onto the character, using
-- ItemManager.handleParcel - the same generic parcel-expansion mechanism
-- CoreRPG itself uses for NPCs, the party sheet, and other parcels. Drag
-- the same Parcel onto the Kit twice for multiple copies.
--

local Original_CharManager_addBackgroundRef = nil;

function onInit()
	Original_CharManager_addBackgroundRef = CharManager.addBackgroundRef;
	CharManager.addBackgroundRef = addBackgroundRef_kpi;
end

-- add a link-only row to the Kit's Parcels list when a Treasure Parcel is
-- dropped onto the Kit record (does not unpack it - that happens when the
-- Kit itself is later applied to a character)
function addParcelLink(nodeKit, draginfo)
	local sClass, sRecord = draginfo.getShortcutData();
	if sClass ~= "treasureparcel" or (sRecord or "") == "" then
		return false;
	end

	local nodeSource = DB.findNode(sRecord);
	if not nodeSource then
		return false;
	end

	local nodeParcelList = DB.createChild(nodeKit, "parcellist");
	local nodeNew = DB.createChild(nodeParcelList);
	DB.setValue(nodeNew, "link", "windowreference", sClass, DB.getPath(nodeSource));
	DB.setValue(nodeNew, "name", "string", DB.getValue(nodeSource, "name", ""));
	DB.setValue(nodeNew, "coinsummary", "string", buildParcelCoinSummary(nodeSource));
	DB.setValue(nodeNew, "itemsummary", "string", buildParcelItemSummary(nodeSource));
	return true;
end

-- DB.getChildren/DB.getChild don't see a parcel's own coinlist/itemlist
-- children (confirmed - they find the list node correctly but report zero
-- children); DB.getChildList (what ItemManager.handleParcelTransfer itself
-- uses) reads the same data correctly, so these read the parcel with that
-- function instead - built once at drop time and cached on the Kit's own
-- row, since the real "treasureparcel" window doesn't render its contents
-- correctly when opened via a link from another record (see README).
function buildParcelCoinSummary(nodeParcel)
	local tChildren = DB.getChildList(nodeParcel, "coinlist");

	local tLines = {};
	for _, v in ipairs(tChildren) do
		local sDesc = DB.getValue(v, "description", "");
		if sDesc == "" then
			sDesc = DB.getValue(v, "name", "");
		end
		local nAmount = DB.getValue(v, "amount", 0);
		if nAmount ~= 0 then
			table.insert(tLines, nAmount .. " " .. sDesc);
		end
	end
	if #tLines == 0 then
		return "(none)";
	end
	return table.concat(tLines, "\n");
end

function buildParcelItemSummary(nodeParcel)
	local tChildren = DB.getChildList(nodeParcel, "itemlist");

	local tLines = {};
	for _, v in ipairs(tChildren) do
		local sName = DB.getValue(v, "name", "");
		local nCount = DB.getValue(v, "count", 1);
		if sName ~= "" then
			table.insert(tLines, nCount .. "x " .. sName);
		end
	end
	if #tLines == 0 then
		return "(none)";
	end
	return table.concat(tLines, "\n");
end

function addBackgroundRef_kpi(nodeChar, sClass, sRecord)
	Original_CharManager_addBackgroundRef(nodeChar, sClass, sRecord);

	local nodeSource = DB.findNode(sRecord);
	if not nodeSource then
		return;
	end

	addKitParcels(nodeSource, nodeChar);
end

-- unpack each Parcel linked on the Kit onto the character
function addKitParcels(nodeSource, nodeChar)
	for _, v in pairs(DB.getChildren(nodeSource, "parcellist")) do
		local _, sParcelRecord = DB.getValue(v, "link", "", "");
		if (sParcelRecord or "") ~= "" then
			ItemManager.handleParcel(nodeChar, sParcelRecord);
			CharManager.outputAdvancementLog(
				"Adding parcel: " .. DB.getValue(v, "name", "") .. ".", nodeChar, sParcelRecord);
		end
	end
end
