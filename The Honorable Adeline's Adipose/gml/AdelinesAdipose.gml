// Manage your mod's state
function __adelines_adipose_runtime() {
    if (global[$ "__adelines_adipose"] == undefined) {
        global.__adelines_adipose = {
            dynamic_portraits_registered: false
        };
    }

    return global.__adelines_adipose;
}

// Define your rules
function adelines_adipose_rules() {
    return [
        // This rule is more specific, so it comes first.
		{
            npc: "adeline",
            sprite_name: "spr_portrait_adeline_barely_mobile_spring",
            conditions: {
                weight: 800,
				season: "spring"
            },
        },
		{
            npc: "adeline",
            sprite_name: "spr_portrait_adeline_massive_spring",
            conditions: {
                weight: 675,
				season: "spring"
            },
        },
		{
            npc: "adeline",
            sprite_name: "spr_portrait_adeline_huge_spring",
            conditions: {
                weight: 575,
				season: "spring"
            },
        },
		{
            npc: "adeline",
            sprite_name: "spr_portrait_adeline_heavy_spring",
            conditions: {
                weight: 500,
				season: "spring"
            },
        },
		{
            npc: "adeline",
            sprite_name: "spr_portrait_adeline_fat_spring",
            conditions: {
                weight: 450,
				season: "spring"
            },
        },
		{
            npc: "adeline",
            sprite_name: "spr_portrait_adeline_thick_spring",
            conditions: {
                weight: 375,
				season: "spring"
            },
        },
		{
            npc: "adeline",
            sprite_name: "spr_portrait_adeline_overweight_spring",
            conditions: {
                weight: 300,
				season: "spring"
            },
        },
		{
            npc: "adeline",
            sprite_name: "spr_portrait_adeline_chubby_spring",
            conditions: {
                weight: 250,
				season: "spring"
            },
        },
        {
            npc: "adeline",
            sprite_name: "spr_portrait_adeline_pudgy_spring",
            conditions: {
                weight: 200,
				season: "spring"
            },
        },
        {
            npc: "adeline",
            sprite_name: "spr_portrait_adeline_slim_spring",
            conditions: {
                weight: 150,
				season: "spring"
            },
        },
    ];
}

// Register your mod with Dynamic NPC Portraits
function adelines_adipose_register_dynamic_portraits() {
    var state = __adelines_adipose_runtime();

    if (state.dynamic_portraits_registered) {
        return;
    }

    var rules_added = dynamic_npc_portraits_register(
        "The Honorable Adeline's Adipose",
        adelines_adipose_rules()
    );

    state.dynamic_portraits_registered = true;

    mmapi_log_info(
        "adelines_adipose",
        "Registered " + string(rules_added)
            + " Dynamic NPC Portraits rules."
    );
}

// MMAPI mod registration
mmapi_register(adelines_adipose_register_dynamic_portraits);