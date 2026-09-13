#macro DYNAMIC_NPC_PORTRAITS_NIGHT_START 72000
#macro DYNAMIC_NPC_PORTRAITS_SEASON_TIME_UNITS (28 * 86400)

function __dynamic_npc_portraits_runtime() {
    if (global[$ "__dynamic_npc_portraits"] == undefined) {
        global.__dynamic_npc_portraits = {
            rules_by_npc: {},
            defaults_by_npc: {},
            registered_hooks: undefined,
            debug_registered: false,
            last_swap_outcome: "unset",
            last_happy_outcome: "unset",
            last_untouched: "unset",
            last_revert_outcome: "unset",
            last_live_swap: "unset",
            last_live_swap_npc: "",
            last_live_swap_count: -1,
            clock_restore: undefined,
            clock_forced: false,
            weather_restore: undefined,
            weather_forced: false,
            calendar_restore: undefined,
            calendar_forced: false,
            rule_prior_bucket: undefined,
            rule_forced: false,
            portrait_inner_ref: undefined,
            portrait_snapshot: undefined,
            portrait_forced: false,
        };
    }
    return global.__dynamic_npc_portraits;
}

function dynamic_npc_portraits_normalize_spec(mod_name, spec) {
    if (is_struct(spec) == false) { return undefined; }

    var npc = spec[$ "npc"];
    if (is_string(npc) == false || npc == "") { return undefined; }
    var npc_lower = string_lower(npc);
    if (try_string_to_npc_id(npc_lower) == undefined) {
        mmapi_log_warn("dynamic_npc_portraits", "rule names an unknown npc: " + string(npc));
        return undefined;
    }

    var sprite_name = spec[$ "sprite_name"];
    if (is_string(sprite_name) == false || sprite_name == "") { return undefined; }
    if (typeof(try_string_to_asset(sprite_name + "_neutral")) == "undefined") {
        mmapi_log_warn("dynamic_npc_portraits", "base sprite missing its _neutral variant: " + sprite_name);
        return undefined;
    }

    var raw = spec[$ "conditions"];
    if (is_struct(raw) == false) { return undefined; }
    var cond = dynamic_npc_portraits_normalize_conditions(raw);
    if (array_length(struct_get_names(cond)) == 0) {
        mmapi_log_warn("dynamic_npc_portraits", "rule for " + npc_lower + " has no valid condition; skipped");
        return undefined;
    }

    return { npc: npc_lower, sprite_name: sprite_name, conditions: cond, mod_name: mod_name };
}

function dynamic_npc_portraits_register(mod_name, specs) {
    if (is_array(specs) == false) { return 0; }
    var runtime = __dynamic_npc_portraits_runtime();
    var added = 0;
	//runs the struct of rules given by external mod
    for (var i = 0; i < array_length(specs); i++) {
		//grabs every dependent mod by name and sets every possible condition set in that mod, specs is a list of rule arrays
        var rule = dynamic_npc_portraits_normalize_spec(mod_name, specs[i]);
        if (rule == undefined) { continue; }
		//bucket gets set to the npc's name
        var bucket = runtime.rules_by_npc[$ rule.npc];
		//just double checks that rules were actually written
        if (bucket == undefined) {
            bucket = [];
            runtime.rules_by_npc[$ rule.npc] = bucket;
        }
		//adds the rule to the bucket's list array, then counts up for every rule successfully added, just to print in the side mod's log
		//each rule is stored in a struct as rules_by_npc = {"npc_name": rule1_struct, "npc_name": rule2_struct, ...}
        array_push(bucket, rule);
        added += 1;
    }
    return added;
}

function dynamic_npc_portraits_match_rule(npc_name, state) {
    var bucket = __dynamic_npc_portraits_runtime().rules_by_npc[$ string_lower(string(npc_name))];
    if (is_array(bucket) == false) { return undefined; }
    for (var i = 0; i < array_length(bucket); i++) {
        if (dynamic_npc_portraits_conditions_match(bucket[i].conditions, state)) {
            return bucket[i];
        }
    }
    return undefined;
}


function dynamic_npc_portraits_ctx_npc_name(ctx) {
    var npc_id = ctx[$ "current_npc_id"];
    if (is_real(npc_id) == false) { return undefined; }
    if (npc_id < 0 || npc_id >= NpcId.LEN) { return undefined; }
    return npc_id_to_string(npc_id);
}

//this is the one actually using the hook
function dynamic_npc_portraits_speaker_filter(speaker, ctx) {
    if (is_struct(ctx) == false) { return undefined; }
	//this function calls the npc index, then grabs the lowercase name from it
    var npc_name = dynamic_npc_portraits_ctx_npc_name(ctx);
    if (npc_name == undefined) { return undefined; }
	//I'm pretty sure this is unnecessary because npc_id_to_string already gives lowercase names
    var npc_key = string_lower(string(npc_name));
	//this double checks that the global struct is defined, then returns with the global struct
    var runtime = __dynamic_npc_portraits_runtime();
	//this grab the rules assigned to a given NPC, using their name as the key in the rules_by_npc struct
    var bucket = runtime.rules_by_npc[$ npc_key];
    if (is_array(bucket) == false || array_length(bucket) == 0) { return undefined; }
	//this function checks the state of all possible conditions that can affect portraits
    var state = dynamic_npc_portraits_current_state(npc_key);
	//takes speaker obj, lowercase name, and the struct of current conditions. Returns 0 if it fails a condition check.
    var swapped = dynamic_npc_portraits_inject_speaker_portraits(speaker, npc_key, state);
    var rule = dynamic_npc_portraits_match_rule(npc_key, state);
    runtime.last_live_swap_npc = npc_key;
    runtime.last_live_swap_count = swapped;
    runtime.last_live_swap = (swapped >= 1) ? "swapped" : "kept";
    dynamic_npc_portraits_probe("portrait", "live", { npc: npc_key, matched: (rule != undefined), swapped: swapped });
    return undefined;
}

function dynamic_npc_portraits_capture_defaults(npc_key, inner) {
    var runtime = __dynamic_npc_portraits_runtime();
    var have = runtime.defaults_by_npc[$ npc_key];
    if (is_struct(have)) { return have; }
    var snap = {};
    var keys = struct_get_names(inner);
    for (var i = 0; i < array_length(keys); i++) { snap[$ keys[i]] = inner[$ keys[i]]; }
    runtime.defaults_by_npc[$ npc_key] = snap;
    return snap;
}

function dynamic_npc_portraits_inject_speaker_portraits(speaker, npc_key, state) {
    if (is_struct(speaker) == false) { return 0; }
    var me = speaker[$ "me"];
    if (is_struct(me) == false) { return 0; }
    var wardrobe = me[$ "wardrobe"];
    if (is_struct(wardrobe) == false) { return 0; }
    var outfit = wardrobe[$ "outfit_current"];
    if (is_struct(outfit) == false) { return 0; }
    var portraits = outfit[$ "portraits"];
    if (is_struct(portraits) == false) { return 0; }
    var inner = portraits[$ "inner"];
    if (is_struct(inner) == false) { return 0; }
	//inner = speaker.me.wardrobe.outfit_current.portraits.inner
    var defaults = dynamic_npc_portraits_capture_defaults(npc_key, inner);
	//grabs ALL the rules structs associated with the speaking NPC
    var bucket = __dynamic_npc_portraits_runtime().rules_by_npc[$ npc_key];
	//grabs every portrait file under the NPC and lists them by emotion string
    var keys = struct_get_names(inner);
    var swapped = 0;
	//goes through every possible sprite
    for (var i = 0; i < array_length(keys); i++) {
        var expression = keys[i];
        var target = undefined;
        var is_variant = false;
		//starts the portrait swap check, taking the bucket of rules, the expression string, and the current state of conditions
        var asset = dynamic_npc_portraits_resolve_expression(bucket, expression, state, npc_key);
        if (typeof(asset) != "undefined") { target = asset; is_variant = true; }
        if (target == undefined) {
            var d = defaults[$ expression];
            if (d != undefined) { target = d; }
        }
        if (target != undefined) {
            inner[$ expression] = target;
            if (is_variant) { swapped += 1; }
        }
    }
    return swapped;
}


#macro DYNAMIC_NPC_PORTRAITS_PILOT_NPC      "balor"
#macro DYNAMIC_NPC_PORTRAITS_PILOT_BASE     "spr_portrait_balor_spring_indoor"
#macro DYNAMIC_NPC_PORTRAITS_PILOT_DAY_TIME 43200

function dynamic_npc_portraits_probe(feature_id, action, details) {
    if (mmapi_log_get_level() > MmapiLogLevel.Trace) { return; }
    var line = "[PROBE] " + string(feature_id) + "|" + string(action);
    if (is_struct(details)) {
        var keys = struct_get_names(details);
        for (var i = 0; i < array_length(keys); i++) {
            line += "|" + string(keys[i]) + "=" + string(details[$ keys[i]]);
        }
    }
    mmapi_log_trace("dynamic_npc_portraits", line);
    mmapi_log_flush("dynamic_npc_portraits");
}

function dynamic_npc_portraits_debug_swap(scenario) {
    var state = __dynamic_npc_portraits_runtime();
    state.clock_forced = false;
    state.rule_forced = false;
    state.portrait_forced = false;

    state.defaults_by_npc[$ string_lower(DYNAMIC_NPC_PORTRAITS_PILOT_NPC)] = undefined;

    var npc_id = try_string_to_npc_id(DYNAMIC_NPC_PORTRAITS_PILOT_NPC);
    if (typeof(npc_id) == "undefined") {
        state.last_swap_outcome = "unavailable";
        state.last_happy_outcome = "unavailable";
        state.last_untouched = "unavailable";
        dynamic_npc_portraits_probe("swap", "unavailable", { scenario: scenario, reason: "npc_id" });
        return "unavailable";
    }

    var base = DYNAMIC_NPC_PORTRAITS_PILOT_BASE;
    if (typeof(try_string_to_asset(base + "_neutral")) == "undefined"
        || typeof(try_string_to_asset(base + "_happy")) == "undefined") {
        state.last_swap_outcome = "unavailable";
        state.last_happy_outcome = "unavailable";
        state.last_untouched = "unavailable";
        dynamic_npc_portraits_probe("swap", "unavailable",
            { scenario: scenario, base: base, reason: "asset" });
        return "unavailable";
    }

    var speaker = undefined;
    try {
        speaker = new NpcSpeaker(npc_id);
    } catch (error_value) {
        state.last_swap_outcome = "no_save";
        state.last_happy_outcome = "no_save";
        state.last_untouched = "no_save";
        dynamic_npc_portraits_probe("swap", "no_save", { scenario: scenario });
        return "no_save";
    }

    var inner = undefined;
    if (is_struct(speaker)) {
        var me = speaker[$ "me"];
        var wardrobe = is_struct(me) ? me[$ "wardrobe"] : undefined;
        var outfit = is_struct(wardrobe) ? wardrobe[$ "outfit_current"] : undefined;
        if (is_struct(outfit)) {
            var portraits = outfit[$ "portraits"];
            if (is_struct(portraits)) { inner = portraits[$ "inner"]; }
        }
    }
    if (is_struct(inner) == false) {
        state.last_swap_outcome = "no_portraits";
        state.last_happy_outcome = "no_portraits";
        state.last_untouched = "no_portraits";
        dynamic_npc_portraits_probe("swap", "no_portraits", { scenario: scenario });
        return "no_portraits";
    }

    var snapshot = {};
    var keys = struct_get_names(inner);
    for (var i = 0; i < array_length(keys); i++) { snapshot[$ keys[i]] = inner[$ keys[i]]; }
    state.portrait_inner_ref = inner;
    state.portrait_snapshot = snapshot;
    state.portrait_forced = true;
    var default_happy = inner[$ "happy"];

    var npc_key = string_lower(DYNAMIC_NPC_PORTRAITS_PILOT_NPC);
    state.rule_prior_bucket = state.rules_by_npc[$ npc_key];
    state.rules_by_npc[$ npc_key] = undefined;
    dynamic_npc_portraits_register("dynamic_npc_portraits_pilot",
        [{ npc: DYNAMIC_NPC_PORTRAITS_PILOT_NPC, sprite_name: base,
           conditions: { time_of_day: "night" } }]);
    state.rule_forced = true;

    var clock_ok = is_struct(CLOCK);
    if (clock_ok) {
        state.clock_restore = CLOCK.time;
        state.clock_forced = true;
        CLOCK.time = (scenario == "swap")
            ? DYNAMIC_NPC_PORTRAITS_NIGHT_START
            : DYNAMIC_NPC_PORTRAITS_PILOT_DAY_TIME;
    }

    var ctx = { action: undefined, current_npc_id: npc_id, driver: undefined,
                conversation_name: "dynamic_npc_portraits_pilot", textbox: undefined, is_cameo: false };

    mmapi_apply_filters("dialogue.speaker", speaker, ctx);

    var expected_happy = try_string_to_asset(base + "_happy");
    var happy_now = inner[$ "happy"];
    var happy_outcome;
    if (happy_now == expected_happy) { happy_outcome = "swapped"; }
    else if (happy_now == default_happy) { happy_outcome = "kept"; }
    else { happy_outcome = "other"; }

    var untouched = "clean";
    var no_variant_seen = 0;
    var swapped_count = 0;
    for (var j = 0; j < array_length(keys); j++) {
        var expr = keys[j];
        var has_variant = (typeof(try_string_to_asset(base + "_" + expr)) != "undefined");
        var changed = (inner[$ expr] != snapshot[$ expr]);
        if (has_variant && changed) { swapped_count += 1; }
        if (has_variant == false) {
            no_variant_seen += 1;
            if (changed) { untouched = "leaked"; }
        }
    }
    if (untouched != "leaked" && no_variant_seen == 0) { untouched = "vacuous"; }

    for (var k = 0; k < array_length(keys); k++) { inner[$ keys[k]] = snapshot[$ keys[k]]; }
    state.portrait_forced = false;
    if (clock_ok) { CLOCK.time = state.clock_restore; state.clock_forced = false; }
    state.rules_by_npc[$ npc_key] = state.rule_prior_bucket;
    state.rule_forced = false;

    var outcome = (swapped_count >= 1) ? "swapped" : "kept";
    state.last_happy_outcome = happy_outcome;
    state.last_untouched = untouched;
    state.last_swap_outcome = outcome;
    dynamic_npc_portraits_probe("swap", "resolved",
        { scenario: scenario, outcome: outcome, happy: happy_outcome, untouched: untouched,
          swapped_count: swapped_count, no_variant_seen: no_variant_seen });
    return outcome;
}

function dynamic_npc_portraits_debug_revert(scenario) {
    var state = __dynamic_npc_portraits_runtime();
    state.clock_forced = false;
    state.rule_forced = false;
    state.portrait_forced = false;

    var npc_key = string_lower(DYNAMIC_NPC_PORTRAITS_PILOT_NPC);
    state.defaults_by_npc[$ npc_key] = undefined;

    var npc_id = try_string_to_npc_id(DYNAMIC_NPC_PORTRAITS_PILOT_NPC);
    if (typeof(npc_id) == "undefined") {
        state.last_revert_outcome = "unavailable";
        dynamic_npc_portraits_probe("revert", "unavailable", { scenario: scenario, reason: "npc_id" });
        return "unavailable";
    }

    var base = DYNAMIC_NPC_PORTRAITS_PILOT_BASE;
    if (typeof(try_string_to_asset(base + "_neutral")) == "undefined"
        || typeof(try_string_to_asset(base + "_happy")) == "undefined") {
        state.last_revert_outcome = "unavailable";
        dynamic_npc_portraits_probe("revert", "unavailable", { scenario: scenario, base: base, reason: "asset" });
        return "unavailable";
    }

    var speaker = undefined;
    try {
        speaker = new NpcSpeaker(npc_id);
    } catch (error_value) {
        state.last_revert_outcome = "no_save";
        dynamic_npc_portraits_probe("revert", "no_save", { scenario: scenario });
        return "no_save";
    }

    var inner = undefined;
    if (is_struct(speaker)) {
        var me = speaker[$ "me"];
        var wardrobe = is_struct(me) ? me[$ "wardrobe"] : undefined;
        var outfit = is_struct(wardrobe) ? wardrobe[$ "outfit_current"] : undefined;
        if (is_struct(outfit)) {
            var portraits = outfit[$ "portraits"];
            if (is_struct(portraits)) { inner = portraits[$ "inner"]; }
        }
    }
    if (is_struct(inner) == false) {
        state.last_revert_outcome = "no_portraits";
        dynamic_npc_portraits_probe("revert", "no_portraits", { scenario: scenario });
        return "no_portraits";
    }

    var snapshot = {};
    var keys = struct_get_names(inner);
    for (var i = 0; i < array_length(keys); i++) { snapshot[$ keys[i]] = inner[$ keys[i]]; }
    state.portrait_inner_ref = inner;
    state.portrait_snapshot = snapshot;
    state.portrait_forced = true;

    state.rule_prior_bucket = state.rules_by_npc[$ npc_key];
    state.rules_by_npc[$ npc_key] = undefined;
    dynamic_npc_portraits_register("dynamic_npc_portraits_pilot",
        [{ npc: DYNAMIC_NPC_PORTRAITS_PILOT_NPC, sprite_name: base,
           conditions: { time_of_day: "night" } }]);
    state.rule_forced = true;

    var ctx = { action: undefined, current_npc_id: npc_id, driver: undefined,
                conversation_name: "dynamic_npc_portraits_pilot", textbox: undefined, is_cameo: false };

    var clock_ok = is_struct(CLOCK);
    if (clock_ok) { state.clock_restore = CLOCK.time; state.clock_forced = true; }

    if (clock_ok) { CLOCK.time = DYNAMIC_NPC_PORTRAITS_NIGHT_START; }
    mmapi_apply_filters("dialogue.speaker", speaker, ctx);
    var night_swapped = 0;
    for (var a = 0; a < array_length(keys); a++) {
        var ke = keys[a];
        if (typeof(try_string_to_asset(base + "_" + ke)) != "undefined" && inner[$ ke] != snapshot[$ ke]) {
            night_swapped += 1;
        }
    }

    if (clock_ok) { CLOCK.time = DYNAMIC_NPC_PORTRAITS_PILOT_DAY_TIME; }
    mmapi_apply_filters("dialogue.speaker", speaker, ctx);
    var leaked = 0;
    for (var b = 0; b < array_length(keys); b++) {
        if (inner[$ keys[b]] != snapshot[$ keys[b]]) { leaked += 1; }
    }

    for (var k = 0; k < array_length(keys); k++) { inner[$ keys[k]] = snapshot[$ keys[k]]; }
    state.portrait_forced = false;
    if (clock_ok) { CLOCK.time = state.clock_restore; state.clock_forced = false; }
    state.rules_by_npc[$ npc_key] = state.rule_prior_bucket;
    state.rule_forced = false;

    var revert_outcome = (night_swapped >= 1)
        ? ((leaked == 0) ? "reverted" : "leaked")
        : "no_swap";
    state.last_revert_outcome = revert_outcome;
    dynamic_npc_portraits_probe("revert", "resolved",
        { scenario: scenario, outcome: revert_outcome, night_swapped: night_swapped, leaked: leaked });
    return revert_outcome;
}

function dynamic_npc_portraits_debug_force_weather(weather_name) {
    var name = string_lower(string(weather_name));
    if (name != "calm" && name != "inclement" && name != "heavy_inclement" && name != "special") {
        dynamic_npc_portraits_probe("force", "weather_bad", { name: name });
        return "bad_arg";
    }
    if (is_struct(WEATHER) == false) {
        dynamic_npc_portraits_probe("force", "weather_no_save", { name: name });
        return "no_save";
    }
    var state = __dynamic_npc_portraits_runtime();
    if (state.weather_forced == false) { state.weather_restore = WEATHER.weather; }
    state.weather_forced = true;
    WEATHER.weather = string_to_weather(name);
    dynamic_npc_portraits_probe("force", "weather", { name: name });
    return name;
}

function dynamic_npc_portraits_debug_force_season(season_name) {
    var target = try_string_to_season(string_lower(string(season_name)));
    if (target == undefined) {
        dynamic_npc_portraits_probe("force", "season_bad", { name: string(season_name) });
        return "bad_arg";
    }
    if (is_struct(CALENDAR) == false) {
        dynamic_npc_portraits_probe("force", "season_no_save", { name: string(season_name) });
        return "no_save";
    }
    var state = __dynamic_npc_portraits_runtime();
    if (state.calendar_forced == false) { state.calendar_restore = CALENDAR.time; }
    state.calendar_forced = true;
    var cur = CALENDAR.season();
    CALENDAR.time += int64((target - cur) * DYNAMIC_NPC_PORTRAITS_SEASON_TIME_UNITS);
    dynamic_npc_portraits_probe("force", "season", { name: string_lower(string(season_name)), from: cur, to: target });
    return string_lower(string(season_name));
}

function dynamic_npc_portraits_debug_force_time(seconds) {
    if (is_struct(CLOCK) == false) {
        dynamic_npc_portraits_probe("force", "time_no_save", {});
        return "no_save";
    }
    var state = __dynamic_npc_portraits_runtime();
    if (state.clock_forced == false) { state.clock_restore = CLOCK.time; }
    state.clock_forced = true;
    CLOCK.time = seconds;
    dynamic_npc_portraits_probe("force", "time", { seconds: seconds });
    return seconds;
}

function dynamic_npc_portraits_debug_restore() {
    var state = __dynamic_npc_portraits_runtime();
    var did = false;
    if (state.portrait_forced == true && is_struct(state.portrait_inner_ref) && is_struct(state.portrait_snapshot)) {
        var snap = state.portrait_snapshot;
        var inner = state.portrait_inner_ref;
        var keys = struct_get_names(snap);
        for (var i = 0; i < array_length(keys); i++) { inner[$ keys[i]] = snap[$ keys[i]]; }
        state.portrait_forced = false;
        did = true;
    }
    if (state.clock_forced == true && is_struct(CLOCK)) {
        CLOCK.time = state.clock_restore;
        state.clock_forced = false;
        did = true;
    }
    if (state.weather_forced == true && is_struct(WEATHER)) {
        WEATHER.weather = state.weather_restore;
        state.weather_forced = false;
        did = true;
    }
    if (state.calendar_forced == true && is_struct(CALENDAR)) {
        CALENDAR.time = state.calendar_restore;
        state.calendar_forced = false;
        did = true;
    }
    if (state.rule_forced == true) {
        state.rules_by_npc[$ string_lower(DYNAMIC_NPC_PORTRAITS_PILOT_NPC)] = state.rule_prior_bucket;
        state.rule_forced = false;
        did = true;
    }
    return did ? "restored" : "clean";
}

function dynamic_npc_portraits_debug_play_conversation(convo_path, scenario) {
    var state = __dynamic_npc_portraits_runtime();
    state.last_live_swap = "unset";
    state.last_live_swap_count = -1;

    var base = DYNAMIC_NPC_PORTRAITS_PILOT_BASE;
    if (typeof(try_string_to_asset(base + "_neutral")) == "undefined") {
        state.last_live_swap = "unavailable";
        dynamic_npc_portraits_probe("play", "unavailable", { base: base, reason: "asset" });
        return "unavailable";
    }
    var npc_id = try_string_to_npc_id(DYNAMIC_NPC_PORTRAITS_PILOT_NPC);
    if (typeof(npc_id) == "undefined") {
        state.last_live_swap = "unavailable";
        dynamic_npc_portraits_probe("play", "unavailable", { reason: "npc_id" });
        return "unavailable";
    }

    var is_weather = (scenario == "weather_swap" || scenario == "weather_hold");
    var rule_conditions = is_weather ? { weather: "inclement" } : { time_of_day: "night" };

    var npc_key = string_lower(DYNAMIC_NPC_PORTRAITS_PILOT_NPC);
    state.defaults_by_npc[$ npc_key] = undefined;
    state.rule_prior_bucket = state.rules_by_npc[$ npc_key];
    state.rules_by_npc[$ npc_key] = undefined;
    dynamic_npc_portraits_register("dynamic_npc_portraits_pilot",
        [{ npc: DYNAMIC_NPC_PORTRAITS_PILOT_NPC, sprite_name: base, conditions: rule_conditions }]);
    state.rule_forced = true;

    if (is_weather) {
        if (is_struct(WEATHER)) {
            state.weather_restore = WEATHER.weather;
            state.weather_forced = true;
            WEATHER.weather = (scenario == "weather_swap") ? Weather.Inclement : Weather.Calm;
        }
    } else {
        if (is_struct(CLOCK)) {
            state.clock_restore = CLOCK.time;
            state.clock_forced = true;
            CLOCK.time = (scenario == "swap") ? DYNAMIC_NPC_PORTRAITS_NIGHT_START : DYNAMIC_NPC_PORTRAITS_PILOT_DAY_TIME;
        }
    }

    var play_ok = true;
    try {
        play_conversation(npc_id, convo_path);
    } catch (play_err) {
        play_ok = false;
        mmapi_log_warn("dynamic_npc_portraits", "play_conversation failed for '" + string(convo_path) + "': " + string(play_err));
    }
    dynamic_npc_portraits_probe("play", "opened",
        { path: string(convo_path), scenario: scenario, play_ok: (play_ok ? "yes" : "no") });
    return (play_ok ? "opened" : "play_failed");
}

function dynamic_npc_portraits_debug_close_conversation() {
    var closed = false;
    try {
        var m = ANCHOR.get_menu(Menu.Textbox);
        if (is_struct(m)) {
            var driver = is_struct(m[$ "driver"]) ? m[$ "driver"] : undefined;
            var finish = (driver != undefined) ? driver[$ "finish_conversation"] : undefined;
            if (finish != undefined && driver[$ "state"] != ConversationDriverState.Finished) {
                driver.finish_conversation();
                closed = true;
            } else if (m[$ "begin_close"] != undefined) {
                m.begin_close();
                closed = true;
            } else if (m[$ "close"] != undefined) {
                m.close();
                closed = true;
            }
        }
    } catch (error_value) {
        mmapi_log_warn("dynamic_npc_portraits", "close_conversation threw: " + string(error_value));
    }
    dynamic_npc_portraits_probe("play", "close", { closed: closed });
    return closed;
}

function dynamic_npc_portraits_install() {
    var state = __dynamic_npc_portraits_runtime();
    if (state.debug_registered == true) { return; }
    var cfg = mmapi_config_load("mmapi");
    if (mmapi_config_get(cfg, "debug_enabled", false) == true) {
        mmapi_debug_register_fn("dynamic_npc_portraits_debug_swap", dynamic_npc_portraits_debug_swap,
            { description: "Pilot: force the live clock to a named condition (swap=night / hold=day), drive dialogue.speaker for the pilot NPC, and record how the filter treated the real speaker's portrait map." });
        mmapi_debug_register_fn("dynamic_npc_portraits_debug_revert", dynamic_npc_portraits_debug_revert,
            { description: "Pilot: drive the SAME real speaker through dialogue.speaker twice (night then day) and record whether the day build restored every portrait to its default (no-leak / revert contract)." });
        mmapi_debug_register_fn("dynamic_npc_portraits_debug_play_conversation", dynamic_npc_portraits_debug_play_conversation,
            { description: "Pilot: play a REAL conversation (arg0 = section path, arg1 = swap/hold) so the engine builds the speaker and fires dialogue.speaker itself; the handler records last_live_swap. Needs the companion art deployed." });
        mmapi_debug_register_fn("dynamic_npc_portraits_debug_close_conversation", dynamic_npc_portraits_debug_close_conversation,
            { description: "Pilot: end the active dialogue textbox so the next scenario can play its own conversation." });
        mmapi_debug_register_fn("dynamic_npc_portraits_debug_force_weather", dynamic_npc_portraits_debug_force_weather,
            { description: "On-demand: force the live weather and HOLD it (arg0 = calm/inclement/heavy_inclement/special). Field-only (no atmosphere/crop side effect); revert with debug_restore." });
        mmapi_debug_register_fn("dynamic_npc_portraits_debug_force_season", dynamic_npc_portraits_debug_force_season,
            { description: "On-demand: force the live season and HOLD it (arg0 = spring/summer/fall/winter). Shifts the in-game DATE - restore before any save; revert with debug_restore." });
        mmapi_debug_register_fn("dynamic_npc_portraits_debug_force_time", dynamic_npc_portraits_debug_force_time,
            { description: "On-demand: force the live time-of-day and HOLD it (arg0 = seconds into day, night >= 72000). Revert with debug_restore." });
        mmapi_debug_register_fn("dynamic_npc_portraits_debug_restore", dynamic_npc_portraits_debug_restore,
            { description: "Pilot teardown / on-demand revert: restore the clock, weather, calendar date, rule bucket, and speaker portrait map if any drive or force left them forced (no-op on a clean state)." });
    }
    state.debug_registered = true;
}

function dynamic_npc_portraits_register_callbacks() {
    var runtime = __dynamic_npc_portraits_runtime();
    if (runtime.registered_hooks != undefined) {
        return runtime.registered_hooks;
    }
    mmapi_filter("dialogue.speaker", dynamic_npc_portraits_speaker_filter);
    mmapi_register(dynamic_npc_portraits_install);
    runtime.registered_hooks = ["dialogue.speaker"];
    return runtime.registered_hooks;
}


mmapi_mod_declare("dynamic_npc_portraits", "2.0.0");
mmapi_log_info("dynamic_npc_portraits", "Dynamic NPC Portraits 2.0.0 starting.");
dynamic_npc_portraits_register_callbacks();
