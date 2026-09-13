function dynamic_npc_portraits_normalize_conditions(raw) {
    var cond = {};
    if (is_string(raw[$ "time_of_day"])) {
        var tod = string_lower(raw.time_of_day);
        if (tod == "day" || tod == "night") { cond.time_of_day = tod; }
    }
    if (is_string(raw[$ "day_of_week"])) {
        var dw = try_string_to_day(string_lower(raw.day_of_week));
        if (dw != undefined) { cond.day_of_week = dw; }
    }
    if (is_real(raw[$ "day_of_month"]) && raw.day_of_month >= 1 && raw.day_of_month <= 28) {
        cond.day_of_month = raw.day_of_month;
    }
    if (is_string(raw[$ "season"])) {
        var se = try_string_to_season(string_lower(raw.season));
        if (se != undefined) { cond.season = se; }
    }
    if (is_real(raw[$ "year"]) && raw.year >= 1) {
        cond.year = raw.year;
    }
    if (is_string(raw[$ "weather"]) && raw.weather != "") {
        cond.weather = string_lower(raw.weather);
    }
    if (is_string(raw[$ "location"]) && raw.location != "") {
        cond.location = string_lower(raw.location);
    }
	if (is_real(raw[$ "weight"])) {
		cond.weight = raw.weight;
	}
    return cond;
}


function dynamic_npc_portraits_is_night() {
    return CLOCK.time >= DYNAMIC_NPC_PORTRAITS_NIGHT_START;
}

function dynamic_npc_portraits_current_weather() {
    var wm = global[$ "__weather"];
    if (is_struct(wm) == false) { return undefined; }
    var w = wm[$ "weather"];
    if (w == undefined) { return undefined; }
    return string_lower(weather_to_string(w));
}

function dynamic_npc_portraits_current_location() {
    var idx = CURRENT_LOCATION_ID;
    var outdoors = false;
    var name = undefined;
    if (is_real(idx) && idx >= 0 && idx < array_length(LOCATIONS)) {
        var loc = LOCATIONS[idx];
        if (is_struct(loc)) {
            outdoors = (loc[$ "outdoor"] == true);
            if (is_string(loc[$ "name"])) { name = string_lower(loc.name); }
        }
    }
    return { outdoors: outdoors, name: name };
}

function dynamic_npc_portraits_current_weight(npc) {
	if global[$"__food_to_weight"] == undefined {
		mmapi_log_warn("dynamic_npc_portraits", "Food to Weight not installed");
		return;
	}
	var _ftw = global[$"__food_to_weight"];
	mmapi_log_info("dynamic_npc_portraits","base weight is " + string(_ftw.base_weights.get(npc)) + ", weight gain is " + string(_ftw.weight_gain[$ npc]));
	var weight = _ftw.base_weights.get(npc) + floor(_ftw.weight_gain[$ npc] / 100);
	return weight;
}

function dynamic_npc_portraits_current_state(npc) {
    return {
		weight: dynamic_npc_portraits_current_weight(npc),
        is_night:     dynamic_npc_portraits_is_night(),
        day_of_month: CALENDAR.day() + 1,
        day_of_week:  CALENDAR.day_type(),
        season:       CALENDAR.season(),
        year:         CALENDAR.year(),
        weather:      dynamic_npc_portraits_current_weather(),
        location:     dynamic_npc_portraits_current_location(),
    };
}


function dynamic_npc_portraits_conditions_match(conditions, state, npc) {
    if (conditions[$ "time_of_day"] != undefined) {
        var want_night = (conditions.time_of_day == "night");
        if (want_night != state.is_night) { return false; }
    }
    if (conditions[$ "day_of_week"] != undefined && conditions.day_of_week != state.day_of_week) { return false; }
    if (conditions[$ "day_of_month"] != undefined && conditions.day_of_month != state.day_of_month) { return false; }
    if (conditions[$ "season"] != undefined && conditions.season != state.season) { return false; }
    if (conditions[$ "year"] != undefined && conditions.year != state.year) { return false; }
    if (conditions[$ "weather"] != undefined) {
        if (state.weather == undefined) { return false; }
        if (conditions.weather != state.weather) { return false; }
    }
    if (conditions[$ "location"] != undefined) {
        var want = conditions.location;
        if (want == "outdoors") {
            if (state.location.outdoors == false) { return false; }
        } else if (want == "indoors") {
            if (state.location.outdoors == true) { return false; }
        } else {
            if (state.location.name != want) { return false; }
        }
    }
	if (conditions[$"weight"] != undefined) && state.weight < conditions[$"weight"] { return false; }
	
    return true;
}
