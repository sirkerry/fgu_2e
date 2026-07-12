--
-- Extends every ability score (Str, Dex, Con, Int, Wis, Cha) with a HackMaster-style
-- fractional bracket: each whole score 1-25 gets two rows, XX/01-50 and XX/51-00,
-- based on the existing abilities.<name>.percenttotal roll. Stock 2E only does this
-- for Strength, and only at score 18 (classic 18/01-18/00 exceptional strength).
--
-- Str/Dex tables are stock 2E's own aStrength/aDexterity[1-25] with a halfway row
-- inserted between each whole score. Con/Int/Wis/Cha have no percentile precedent in
-- 2E, so their halfway rows are generated the same way: numeric columns are the floor
-- average of the two neighboring whole-score rows; string/threshold columns (e.g.
-- Constitution's hit point adj, Wisdom's bonus spell list, Intelligence's max spells
-- per level) hold at the lower score's value, since 2E's own tables already treat
-- those as step functions with no fractional meaning.
--
function onInit()
    AbilityScoreADND.getStrengthProperties = getStrengthProperties_fracstats;
    AbilityScoreADND.getDexterityProperties = getDexterityProperties_fracstats;
    AbilityScoreADND.getConstitutionProperties = getConstitutionProperties_fracstats;
    AbilityScoreADND.getIntelligenceProperties = getIntelligenceProperties_fracstats;
    AbilityScoreADND.getWisdomProperties = getWisdomProperties_fracstats;
    AbilityScoreADND.getCharismaProperties = getCharismaProperties_fracstats;
end

-- score (1-25) + percenttotal (0-100) -> row index (1-50) in the doubled tables.
-- percent 1-50 = that score's XX/01-50 row; percent 51-100 (or 0, unrolled) = XX/51-00.
local function getBracketIndex(nScore, nPercent)
    local nIndex = (nScore * 2) - 1;
    if (nPercent > 50) then
        nIndex = nIndex + 1;
    end
    return nIndex;
end

function getStrengthProperties_fracstats(nodeChar)
    local nScore = DB.getValue(nodeChar, "abilities.strength.total",
        DB.getValue(nodeChar, "abilities.strength.score", 0));
    local nPercent = DB.getValue(nodeChar, "abilities.strength.percenttotal", 0);

    local rActor = ActorManager.resolveActor(nodeChar);
    if rActor then
        nScore = EffectManager.getMaxMod(rActor, "BSTR") or nScore;
        nPercent = math.max(math.min(EffectManager.getMaxMod(rActor, "BPSTR") or nPercent, 100), 0);

        nScore = nScore + EffectManager.getBonusMod(rActor, "STR");
        nPercent = nPercent + EffectManager.getBonusMod(rActor, "PSTR");
    end

    nScore = AbilityScoreADND.abilityScoreSanity(nScore);
    local nIndex = getBracketIndex(nScore, nPercent);

    local dbAbility = {
        score = nScore,
        scorepercent = nPercent,
        hitadj = FracStatsData.aStrength[nIndex][1],
        dmgadj = FracStatsData.aStrength[nIndex][2],
        weightallow = FracStatsData.aStrength[nIndex][3],
        maxpress = FracStatsData.aStrength[nIndex][4],
        opendoors = FracStatsData.aStrength[nIndex][5],
        bendbars = FracStatsData.aStrength[nIndex][6]
    };
    return dbAbility;
end

function getDexterityProperties_fracstats(nodeChar)
    local nScore = DB.getValue(nodeChar, "abilities.dexterity.total",
        DB.getValue(nodeChar, "abilities.dexterity.score", 0));
    local nPercent = DB.getValue(nodeChar, "abilities.dexterity.percenttotal", 0);

    local rActor = ActorManager.resolveActor(nodeChar);
    if rActor then
        nScore = EffectManager.getMaxMod(rActor, "BDEX") or nScore;
        nScore = nScore + EffectManager.getBonusMod(rActor, "DEX");
    end

    nScore = AbilityScoreADND.abilityScoreSanity(nScore);
    local nIndex = getBracketIndex(nScore, nPercent);

    local dbAbility = {
        score = nScore,
        reactionadj = FracStatsData.aDexterity[nIndex][1],
        hitadj = FracStatsData.aDexterity[nIndex][2],
        defenseadj = FracStatsData.aDexterity[nIndex][3]
    };
    return dbAbility;
end

function getConstitutionProperties_fracstats(nodeChar)
    local nScore = DB.getValue(nodeChar, "abilities.constitution.total",
        DB.getValue(nodeChar, "abilities.constitution.score", 0));
    local nPercent = DB.getValue(nodeChar, "abilities.constitution.percenttotal", 0);

    local rActor = ActorManager.resolveActor(nodeChar);
    if rActor then
        nScore = EffectManager.getMaxMod(rActor, "BCON") or nScore;
        nScore = nScore + EffectManager.getBonusMod(rActor, "CON");
    end

    nScore = AbilityScoreADND.abilityScoreSanity(nScore);
    local nIndex = getBracketIndex(nScore, nPercent);

    local dbAbility = {
        score = nScore,
        hitpointadj = FracStatsData.aConstitution[nIndex][1],
        systemshock = FracStatsData.aConstitution[nIndex][2],
        resurrectionsurvival = FracStatsData.aConstitution[nIndex][3],
        poisonadj = FracStatsData.aConstitution[nIndex][4],
        regeneration = FracStatsData.aConstitution[nIndex][5]
    };
    if DataCommonADND.coreVersion == "2e" then
        dbAbility.psp_bonus = FracStatsData.aConstitution[nIndex][6];
    end
    return dbAbility;
end

function getCharismaProperties_fracstats(nodeChar)
    local nScore = DB.getValue(nodeChar, "abilities.charisma.total",
        DB.getValue(nodeChar, "abilities.charisma.score", 0));
    local nPercent = DB.getValue(nodeChar, "abilities.charisma.percenttotal", 0);

    local rActor = ActorManager.resolveActor(nodeChar);
    if rActor then
        nScore = EffectManager.getMaxMod(rActor, "BCHA") or nScore;
        nScore = nScore + EffectManager.getBonusMod(rActor, "CHA");
    end

    nScore = AbilityScoreADND.abilityScoreSanity(nScore);
    local nIndex = getBracketIndex(nScore, nPercent);

    local dbAbility = {
        score = nScore,
        maxhench = FracStatsData.aCharisma[nIndex][1],
        loyalty = FracStatsData.aCharisma[nIndex][2],
        reaction = FracStatsData.aCharisma[nIndex][3]
    };
    return dbAbility;
end

function getIntelligenceProperties_fracstats(nodeChar)
    local nScore = DB.getValue(nodeChar, "abilities.intelligence.total",
        DB.getValue(nodeChar, "abilities.intelligence.score", 0));
    local nPercent = DB.getValue(nodeChar, "abilities.intelligence.percenttotal", 0);

    local rActor = ActorManager.resolveActor(nodeChar);
    if rActor then
        nScore = EffectManager.getMaxMod(rActor, "BINT") or nScore;
        nScore = nScore + EffectManager.getBonusMod(rActor, "INT");
    end

    nScore = AbilityScoreADND.abilityScoreSanity(nScore);
    local nIndex = getBracketIndex(nScore, nPercent);

    -- illusion immunity tooltip text is keyed off the stock (whole-score) table, unrelated to our bracket data
    local sImmunity_TT = "Immune to these level of Illusion spells. ";
    if (nScore >= 19) then
        sImmunity_TT = sImmunity_TT .. DataCommonADND.aIntelligence[nScore + 100][5];
    end

    local dbAbility = {
        score = nScore,
        languages = FracStatsData.aIntelligence[nIndex][1],
        spelllevel = FracStatsData.aIntelligence[nIndex][2],
        learn = FracStatsData.aIntelligence[nIndex][3],
        maxlevel = FracStatsData.aIntelligence[nIndex][4],
        illusion = FracStatsData.aIntelligence[nIndex][5],
        sImmunity_TT = sImmunity_TT
    };
    if DataCommonADND.coreVersion == "2e" then
        dbAbility.mac_adjustment = FracStatsData.aIntelligence[nIndex][6];
        dbAbility.psp_bonus = FracStatsData.aIntelligence[nIndex][7];
        dbAbility.mthaco_bonus = FracStatsData.aIntelligence[nIndex][8];
    end
    return dbAbility;
end

function getWisdomProperties_fracstats(nodeChar)
    local nScore = DB.getValue(nodeChar, "abilities.wisdom.total", DB.getValue(nodeChar, "abilities.wisdom.score", 0));
    local nPercent = DB.getValue(nodeChar, "abilities.wisdom.percenttotal", 0);

    local rActor = ActorManager.resolveActor(nodeChar);
    if rActor then
        nScore = EffectManager.getMaxMod(rActor, "BWIS") or nScore;
        nScore = nScore + EffectManager.getBonusMod(rActor, "WIS");
    end

    nScore = AbilityScoreADND.abilityScoreSanity(nScore);
    local nIndex = getBracketIndex(nScore, nPercent);

    -- bonus-spell/immunity tooltip text is keyed off the stock (whole-score) table, unrelated to our bracket data
    local sBonus_TT = Interface.getString("char_abilityscore_wisdombonus_tooltip");
    local sImmunity_TT = Interface.getString("char_abilityscore_intelligencebonus_tooltip");
    if (nScore >= 17) then
        sBonus_TT = sBonus_TT .. DataCommonADND.aWisdom[nScore + 100][2];
        sImmunity_TT = sImmunity_TT .. DataCommonADND.aWisdom[nScore + 100][4];
    end

    local dbAbility = {
        score = nScore,
        magicdefenseadj = FracStatsData.aWisdom[nIndex][1],
        spellbonus = FracStatsData.aWisdom[nIndex][2],
        failure = FracStatsData.aWisdom[nIndex][3],
        immunity = FracStatsData.aWisdom[nIndex][4],
        sBonus_TT = sBonus_TT,
        sImmunity_TT = sImmunity_TT
    };
    if DataCommonADND.coreVersion == "2e" then
        dbAbility.mac_base = FracStatsData.aWisdom[nIndex][5];
        dbAbility.psp_bonus = FracStatsData.aWisdom[nIndex][6];
    end
    return dbAbility;
end
