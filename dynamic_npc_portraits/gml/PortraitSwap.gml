#macro DYNAMIC_NPC_PORTRAITS_PREFIX "spr_portrait_"

function dynamic_npc_portraits_parse_portrait(sprite_name) {
    if (is_string(sprite_name) == false) { return undefined; }
    var parts = string_split(string(sprite_name), "_");
    var n = array_length(parts);
    if (n < 5) { return undefined; }
    if (parts[0] != "spr" || parts[1] != "portrait") { return undefined; }
    var npc = string_lower(parts[2]);
    var expression = parts[4];
    for (var i = 5; i < n; i++) { expression += "_" + parts[i]; }
    return { npc: npc, expression: expression };
}

function dynamic_npc_portraits_resolve_expression(bucket, expression, state, npc) {
    if (is_array(bucket) == false) { return undefined; }
	//checks through every rule in order to see which one is true first
    for (var i = 0; i < array_length(bucket); i++) {
        var rule = bucket[i];
        if (dynamic_npc_portraits_conditions_match(rule.conditions, state, npc) == false) { continue; }
        var variant = rule.sprite_name + "_" + expression;
        var asset = try_string_to_asset(variant);
        if (typeof(asset) != "undefined") { return asset; }
    }
    return undefined;
}

function dynamic_npc_portraits_resolve(sprite_name, state) {
    var parsed = dynamic_npc_portraits_parse_portrait(sprite_name);
    if (parsed == undefined) { return undefined; }
    var bucket = __dynamic_npc_portraits_runtime().rules_by_npc[$ parsed.npc];
    return dynamic_npc_portraits_resolve_expression(bucket, parsed.expression, state);
}
