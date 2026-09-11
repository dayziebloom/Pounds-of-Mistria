// My Mod

#macro FOOD_TO_WEIGHT_MOD_NAME "food_to_weight"
#macro FOOD_TO_WEIGHT_CONFIG_VERSION 1

function __food_to_weight_runtime() {
    if (global[$ "__food_to_weight"] == undefined) {
        global.__food_to_weight = { 
		registered_hooks: undefined, 
		cfg: undefined,
		food_weights: undefined,
		base_weights: undefined,
		weight_gain: undefined
		};
    }
	mmapi_log_info("food_to_weight", "runtime loaded");

    return global.__food_to_weight;
}
//^The global variable and its key are what other mods can access through setting their own variable equal to global[$"__food_to_weight"]


function food_to_weight_config() {
    var _rt = __food_to_weight_runtime();
    if (_rt.cfg != undefined) return _rt.cfg;
    var _source = mmapi_config_read_valid("food_to_weight", FOOD_TO_WEIGHT_CONFIG_VERSION);
    _rt.cfg = {
        enabled: mmapi_config_bool(_source, "enabled", true),
    };


    mmapi_config_write("food_to_weight", food_to_weight_CONFIG_VERSION, _rt.cfg);
	mmapi_log_info("food_to_weight", "config loaded");
    return _rt.cfg;
}


function food_to_weight_register_callbacks() {
    var _rt = __food_to_weight_runtime();
    if (_rt.registered_hooks != undefined) return;
    _rt.registered_hooks = true;
	
	mmapi_on("npc.gift_received", food_to_weight_gift_received);
	mmapi_on("ui.relationship_row_built", food_to_weight_relationship_row);
	mmapi_on("save.game_loaded", food_to_weight_map_loader);
	
	mmapi_log_info("food_to_weight", "callbacks registered");
}



// Named handler functions.


//Map that determines how much weight each food item gives
//Each food item is stored by its variable name as a string. So "Sliced Turnip" is accessed via > your_global_variable.food_weights.get("sliced_turnip")
//and the result would be 20
function food_to_weight_food_map() {

	var _rt = global[$"__food_to_weight"];
	
	/*
	Unused list just to keep track of what consumables are not given weight values
	These are mostly either cutscene-only items or overworld interactables, such as stamina restoring fountains. The Harvest Day pie is excluded specifically for the
	case that a farmer WG mod would be abused by the player spam eating the feast over and over since there's no limit in vanilla. Other exceptions include items that
	would not reasonably be eaten by someone but still had the 'edible' tag, such as herbs or poisonous-when-raw mushrooms.
	*/
	
	/*banned_items = [
		"acorn",
		"basil",
		"burdock_root",
		"cave_kelp",
		"dill",
		"dragon_horn_mushroom",
		"dungeon_fountain_health",
		"dungeon_fountain_stamina",
		"essence_blossom",
		"ethereal_grass",
		"fairy_syrup",
		"harvest_day_pie",
		"heal_syrup",
		"heart_crystal",
		"horse_potion",
		"ice_block",
		"lurid_colored_drink",
		"mana_potion",
		"monster_hoop",
		"morel_mushroom",
		"oregano",
		"purple_mushroom",
		"restorative_syrup",
		"rosemary",
		"sage",
		"sesame",
		"shale_grass",
		"soup_of_the_day",
		"soup_of_the_day_gold",
		"speedy_syrup",
		"stamina_syrup",	
		"stamina_up",
		"stinky_stamina_potion",
		"sugar_cane",
		"thyme",
		"underseaweed",
		"void_herb",
		"world_fountain",
		"written_root"]*/
	
	
	//alright wise guy let's see YOU take a crack at it /j
	_rt.food_weights = new Map();
	
	_rt.food_weights.set("apple", 10);
	_rt.food_weights.set("apple_honey_curry", 700);
	_rt.food_weights.set("apple_juice", 20);
	_rt.food_weights.set("apple_pie", 350);
	_rt.food_weights.set("ash_mushroom", 10);
	_rt.food_weights.set("baked_potato", 30);
	_rt.food_weights.set("baked_sweetroot", 30);
	_rt.food_weights.set("beer", 100);
	_rt.food_weights.set("beet", 10);
	_rt.food_weights.set("beet_salad", -200);
	_rt.food_weights.set("beet_soup", 600);
	_rt.food_weights.set("bell_berry", 10);
	_rt.food_weights.set("bell_berry_bakewell_tart", 450);
	_rt.food_weights.set("berries_and_cream", 120);
	_rt.food_weights.set("berry_bowl", 400);
	_rt.food_weights.set("big_cookie", 1200);
	_rt.food_weights.set("blackberry", 10);
	_rt.food_weights.set("blackberry_jam", 100);
	_rt.food_weights.set("blueberry", 10);
	_rt.food_weights.set("blueberry_jam", 100);
	_rt.food_weights.set("braised_burdock", 200);
	_rt.food_weights.set("braised_carrots", 10);
	_rt.food_weights.set("bread", 150);
	_rt.food_weights.set("breaded_catfish", 300);
	_rt.food_weights.set("broccoli", -10);
	_rt.food_weights.set("broccoli_salad", -300);
	_rt.food_weights.set("bucket_brew", 250);
	_rt.food_weights.set("buttered_peas", 100);
	_rt.food_weights.set("cabbage", -20);
	_rt.food_weights.set("cabbage_slaw", -200);
	_rt.food_weights.set("caldosian_chocolate_cake", 500);
	_rt.food_weights.set("candied_lemon_peel", 100);
	_rt.food_weights.set("candied_queen_berries", 250);
	_rt.food_weights.set("candied_strawberries", 100);
	_rt.food_weights.set("candied_walnuts", 100);
	_rt.food_weights.set("canned_sardines", 150);
	_rt.food_weights.set("caramel_candy", 100);
	_rt.food_weights.set("caramelized_moon_fruit", 100);
	_rt.food_weights.set("carrot", -10);
	_rt.food_weights.set("cauliflower", -10);
	_rt.food_weights.set("cauliflower_curry", 400);
	_rt.food_weights.set("cheese", 60);
	_rt.food_weights.set("cherry", 10);
	_rt.food_weights.set("cherry_cobbler", 150);
	_rt.food_weights.set("cherry_smoothie", 200);
	_rt.food_weights.set("cherry_tart", 200);
	_rt.food_weights.set("chestnut", 10);
	_rt.food_weights.set("chickpea", 10);
	_rt.food_weights.set("chickpea_curry", 200);
	_rt.food_weights.set("chicky_hot_chocolate", 250);
	_rt.food_weights.set("chili_coconut_curry", 400);
	_rt.food_weights.set("chili_pepper", 20);
	_rt.food_weights.set("chocolate", 90);
	_rt.food_weights.set("clam_chowder", 250);
	_rt.food_weights.set("coconut", 10);
	_rt.food_weights.set("coconut_cream_pie", 550);
	_rt.food_weights.set("coconut_milk", 20);
	_rt.food_weights.set("cod_with_thyme", 300);
	_rt.food_weights.set("coffee", 20);
	_rt.food_weights.set("confiscated_coffee", 20);
	_rt.food_weights.set("corn", 10);
	_rt.food_weights.set("cow_donut", 400);
	_rt.food_weights.set("cow_milk", 20);
	_rt.food_weights.set("crab_cakes", 500);
	_rt.food_weights.set("cranberry", 10);
	_rt.food_weights.set("cranberry_juice", 20);
	_rt.food_weights.set("cranberry_orange_scone", 400);
	_rt.food_weights.set("crayfish_etouffee", 200);
	_rt.food_weights.set("crispy_fried_earthshroom", 200);
	_rt.food_weights.set("crunchy_chickpeas", 100);
	_rt.food_weights.set("crystal_berries", 20);
	_rt.food_weights.set("crystal_berry_pie", 450);
	_rt.food_weights.set("cucumber", -10);
	_rt.food_weights.set("cucumber_salad", -300);
	_rt.food_weights.set("cucumber_sandwich", 400);
	_rt.food_weights.set("cup_of_tea", 150);
	_rt.food_weights.set("daikon_radish", -10);
	_rt.food_weights.set("dark_chocolate", 150);
	_rt.food_weights.set("deep_sea_soup", 250);
	_rt.food_weights.set("deluxe_curry", 300);
	_rt.food_weights.set("deviled_eggs", 250);
	_rt.food_weights.set("dragon_horn_mushroom_with_thyme", 200);
	_rt.food_weights.set("dried_squid", 150);
	_rt.food_weights.set("duck_egg", 20);
	_rt.food_weights.set("earthshroom", 40);
	_rt.food_weights.set("egg", 20);
	_rt.food_weights.set("espresso", 100);
	_rt.food_weights.set("fast_food", 750);
	_rt.food_weights.set("fennel", -10);
	_rt.food_weights.set("fiddlehead", -10);
	_rt.food_weights.set("fish_skewer", 200);
	_rt.food_weights.set("fish_stew", 300);
	_rt.food_weights.set("fish_tacos", 600);
	_rt.food_weights.set("flame_pepper", 40);
	_rt.food_weights.set("floral_tea", 50);
	_rt.food_weights.set("fried_rice", 500);
	_rt.food_weights.set("garlic", 10);
	_rt.food_weights.set("garlic_bread", 200);
	_rt.food_weights.set("gazpacho", 300);
	_rt.food_weights.set("glowberry", 10);
	_rt.food_weights.set("glowberry_cookies", 550);
	_rt.food_weights.set("glowing_mushroom", 10);
	_rt.food_weights.set("golden_butter", 150);
	_rt.food_weights.set("golden_cheese", 150);
	_rt.food_weights.set("golden_cheesecake", 1000);
	_rt.food_weights.set("golden_cookies", 800);
	_rt.food_weights.set("golden_cow_milk", 50);
	_rt.food_weights.set("golden_duck_egg", 50);
	_rt.food_weights.set("golden_egg", 50);
	_rt.food_weights.set("grape_juice", 20);
	_rt.food_weights.set("green_tea", 50);
	_rt.food_weights.set("grilled_cheese", 400);
	_rt.food_weights.set("grilled_corn", 50);
	_rt.food_weights.set("grilled_eel_rice_bowl", 450);
	_rt.food_weights.set("hard_boiled_egg", 50);
	_rt.food_weights.set("harvest_plate", 700);
	_rt.food_weights.set("heavy_mist", 150);
	_rt.food_weights.set("herb_butter_pasta", 450);
	_rt.food_weights.set("herb_salad", -500);
	_rt.food_weights.set("honey_curry", 300);
	_rt.food_weights.set("honey_toast", 200);
	_rt.food_weights.set("honeycomb", 100);
	_rt.food_weights.set("horseradish", 10);
	_rt.food_weights.set("horseradish_salmon", 450);
	_rt.food_weights.set("hot_cocoa", 300);
	_rt.food_weights.set("hot_potato", 40);
	_rt.food_weights.set("hot_toddy", 200);
	_rt.food_weights.set("ice_cream_sundae", 500);
	_rt.food_weights.set("iced_coffee", 200);
	_rt.food_weights.set("incredibly_hot_pot", 500);
	_rt.food_weights.set("jam_sandwich", 300);
	_rt.food_weights.set("jasmine_tea", 100);
	_rt.food_weights.set("latte", 100);
	_rt.food_weights.set("lava_chestnuts", 50);
	_rt.food_weights.set("lavender_tea", 50);
	_rt.food_weights.set("lemon", 10);
	_rt.food_weights.set("lemon_pie", 400);
	_rt.food_weights.set("lemonade", 50);
	_rt.food_weights.set("loaded_baked_potato", 400);
	_rt.food_weights.set("lobster_roll", 600);
	_rt.food_weights.set("mackerel_sashimi", 150);
	_rt.food_weights.set("marmalade", 100);
	_rt.food_weights.set("milk_chocolate", 150);
	_rt.food_weights.set("miners_mushroom_stew", 100);
	_rt.food_weights.set("mines_mussels", 50);
	_rt.food_weights.set("mint_gimlet", 150);
	_rt.food_weights.set("mixed_fruit_juice", 100);
	_rt.food_weights.set("mocha", 200);
	_rt.food_weights.set("monster_cookie", 250);
	_rt.food_weights.set("monster_mash", 300);
	_rt.food_weights.set("mont_blanc", 900);
	_rt.food_weights.set("moon_fruit", 20);
	_rt.food_weights.set("moon_fruit_cake", 450);
	_rt.food_weights.set("mushroom_brew", 200);
	_rt.food_weights.set("mushroom_rice", 200);
	_rt.food_weights.set("mushroom_steak_dinner", 500);
	_rt.food_weights.set("nachos", 350);
	_rt.food_weights.set("nettle", -10);
	_rt.food_weights.set("noodles", 150);
	_rt.food_weights.set("omelet", 350);
	_rt.food_weights.set("onion", 10);
	_rt.food_weights.set("onion_soup", 200);
	_rt.food_weights.set("orange", 10);
	_rt.food_weights.set("orange_juice", 20);
	_rt.food_weights.set("oyster_mushroom", 30);
	_rt.food_weights.set("pan_fried_bream", 200);
	_rt.food_weights.set("pan_fried_salmon", 200);
	_rt.food_weights.set("pan_fried_snapper", 200);
	_rt.food_weights.set("pbjt_sandwich", 200);
	_rt.food_weights.set("pbm_sandwich", 300);
	_rt.food_weights.set("peach", 10);
	_rt.food_weights.set("peaches_and_cream", 200);
	_rt.food_weights.set("pear", 10);
	_rt.food_weights.set("peas", -10);
	_rt.food_weights.set("perch_risotto", 500);
	_rt.food_weights.set("pineshroom", 50);
	_rt.food_weights.set("pineshroom_toast", 250);
	_rt.food_weights.set("pizza", 350);
	_rt.food_weights.set("poached_pear", 300);
	_rt.food_weights.set("pomegranate", 10);
	_rt.food_weights.set("pomegranate_juice", 20);
	_rt.food_weights.set("pomegranate_sorbet", 200);
	_rt.food_weights.set("potato", 20);
	_rt.food_weights.set("potato_soup", 180);
	_rt.food_weights.set("pudding", 200);
	_rt.food_weights.set("pumpkin", 40);
	_rt.food_weights.set("pumpkin_pie", 450);
	_rt.food_weights.set("pumpkin_stew", 350);
	_rt.food_weights.set("queen_berry_pie", 350);
	_rt.food_weights.set("quiche", 250);
	_rt.food_weights.set("red_snapper_sushi", 180);
	_rt.food_weights.set("red_wine", 150);
	_rt.food_weights.set("riceball", 250);
	_rt.food_weights.set("roasted_cauliflower", 100);
	_rt.food_weights.set("roasted_chestnuts", 150);
	_rt.food_weights.set("roasted_rice_tea", 100);
	_rt.food_weights.set("roasted_sweet_potato", 100);
	_rt.food_weights.set("rockroot", 20);
	_rt.food_weights.set("rose_hip", 10);
	_rt.food_weights.set("rose_tea", 50);
	_rt.food_weights.set("rosehip_jam", 50);
	_rt.food_weights.set("rosemary_garlic_noodles", 400);
	_rt.food_weights.set("salmon_sashimi", 150);
	_rt.food_weights.set("salted_watermelon", 100);
	_rt.food_weights.set("sauteed_snow_peas", 60);
	_rt.food_weights.set("sea_bream_rice", 400);
	_rt.food_weights.set("sea_grapes", 50);
	_rt.food_weights.set("seafood_boil", 800);
	_rt.food_weights.set("seafood_snow_pea_noodles", 500);
	_rt.food_weights.set("seaweed_salad", -300);
	_rt.food_weights.set("sesame_broccoli", 30);
	_rt.food_weights.set("sesame_tuna_bowl", 400);
	_rt.food_weights.set("simmered_daikon", 150);
	_rt.food_weights.set("sliced_turnip", 20);
	_rt.food_weights.set("smoked_trout_soup", 150);
	_rt.food_weights.set("snow_peas", -10);
	_rt.food_weights.set("sour_lemon_cake", 300);
	_rt.food_weights.set("spell_fruit", 50);
	_rt.food_weights.set("spell_fruit_parfait", 750);
	_rt.food_weights.set("spicy_cheddar_biscuit", 350);
	_rt.food_weights.set("spicy_corn", 250);
	_rt.food_weights.set("spicy_crab_sushi", 450);
	_rt.food_weights.set("spicy_water_chestnuts", 100);
	_rt.food_weights.set("spirit_mushroom", 10);
	_rt.food_weights.set("spirit_mushroom_tea", 50);
	_rt.food_weights.set("spring_galette", 600);
	_rt.food_weights.set("spring_salad", -300);
	_rt.food_weights.set("star_shaped_cookie", 300);
	_rt.food_weights.set("steamed_broccoli", 20);
	_rt.food_weights.set("strawberries_and_cream", 100);
	_rt.food_weights.set("strawberry", 10);
	_rt.food_weights.set("strawberry_shortcake", 450);
	_rt.food_weights.set("summer_salad", -400);
	_rt.food_weights.set("sushi_platter", 600);
	_rt.food_weights.set("sweet_potato", 20);
	_rt.food_weights.set("sweet_potato_pie", 300);
	_rt.food_weights.set("sweet_sesame_balls", 300);
	_rt.food_weights.set("sweetroot", 20);
	_rt.food_weights.set("tesserae_cake", 450);
	_rt.food_weights.set("tide_lettuce", -50);
	_rt.food_weights.set("tide_salad", -400);
	_rt.food_weights.set("toasted_sunflower_seeds", 150);
	_rt.food_weights.set("tomato", 10);
	_rt.food_weights.set("tomato_soup", 150);
	_rt.food_weights.set("trail_mix", 100);
	_rt.food_weights.set("tulip_cake", 350);
	_rt.food_weights.set("tuna_sashimi", 150);
	_rt.food_weights.set("turnip", 10);
	_rt.food_weights.set("turnip_and_cabbage_salad", -300);
	_rt.food_weights.set("turnip_and_potato_gratin", 400);
	_rt.food_weights.set("twice_baked_rations", 100);
	_rt.food_weights.set("upper_mines_mushroom", 20);
	_rt.food_weights.set("vegetable_pot_pie", 400);
	_rt.food_weights.set("vegetable_quiche", 450);
	_rt.food_weights.set("vegetable_soup", 200);
	_rt.food_weights.set("veggie_sub_sandwich", 600);
	_rt.food_weights.set("walnut", 20);
	_rt.food_weights.set("water_chestnut", 10);
	_rt.food_weights.set("water_chestnut_fritters", 200);
	_rt.food_weights.set("watermelon", 10);
	_rt.food_weights.set("white_chocolate", 150);
	_rt.food_weights.set("white_wine", 150);
	_rt.food_weights.set("wild_berries", 10);
	_rt.food_weights.set("wild_berry_jam", 100);
	_rt.food_weights.set("wild_grapes", 30);
	_rt.food_weights.set("wild_leek", 10);
	_rt.food_weights.set("wild_mushroom", 10);
	_rt.food_weights.set("wildberry_pie", 300);
	_rt.food_weights.set("wildberry_scone", 300);
	_rt.food_weights.set("winter_stew", 350);
	_rt.food_weights.set("wintergreen_berry", 10);
	_rt.food_weights.set("wintergreen_ice_cream", 250);
	
	//Hook will go here to either edit weight values of food or add in a custom food item and weight
	
	mmapi_log_info("food_to_weight", "Food Weight map created");

}

//Map that determines what everyone's starting weights are
//Stored with NPC's string name as the key (lowercase only) so your_global_variable.base_weights.get("darcy") returns 130
function food_to_weight_base_weight_map() {
	
	var _rt = global[$"__food_to_weight"];
	
	var npc_db = global[$"__npc_prototypes"];
	
	mmapi_log_info("food_to_weight", "established base weight npc proto");
	//only establish a blank Map if one doesn't exist already
	if _rt.base_weights == undefined {
		_rt.base_weights = new Map();
	}
	
	mmapi_log_info("food_to_weight", "made base weights a new map");
	
	//library of base weights, defaults to 125 pounds for custom NPCs
	function weight_switch (id) {
		switch (id) {
			case "adeline": return 120;
			case "balor": return 120;
			case "caldarus": return 215;
			case "celine": return 105;
			case "darcy": return 130;
			case "eiland": return 120;
			case "elsie": return 135;
			case "errol": return 235;
			case "hayden": return 225;
			case "hemlock": return 105;
			case "holt": return 210;
			case "josephine": return 185;
			case "juniper": return 115;
			case "landen": return 110;
			case "louis": return 110;
			case "march": return 125;
			case "merri": return 165;
			case "nora": return 120;
			case "olric": return 165;
			case "reina": return 135;
			case "ryis": return 120;
			case "seridia": return 235;
			case "stillwell": return 110;
			case "taliferro": return 125;
			case "terithia": return 185;
			case "valen": return 105;
			case "vera": return 130;
			case "zorel": return 120;
			case "wheedle": return 130;
			default: return 125;
		}
	}
		
		mmapi_log_info("food_to_weight", "created base weight library function");
	//loops through NPCs, rejecting child and animal NPCs	
	for (i = 0; i < NpcId.LEN; i++) {
		if (array_has(npc_db[i].tags, "child")) || (array_has(npc_db[i].tags, "animal")) {
		continue; 
		}
		_rt.base_weights.set(npc_id_to_string(i), weight_switch(npc_id_to_string(i)));
		//Hook will go here for custom NPC mods to manually set their NPC's base weight. If you want someone to start out Fat, this is the hook to edit.
	}
	
	mmapi_log_info("food_to_weight", "finished base weights map");
}

//Map that holds how much weight each NPC has gained so far
//Starts at 0, does NOT store the total weight of an NPC so as to allow editing base weights separately.
/*
The food weights are based around a system of 100 being equal to 1 pound gained.
So, giving someone a carrot which is worth 10 means they gain 0.1 pounds from it, plus or minus their gift preferences.
Weight gain stat never goes lower than 0, meaning the NPCs cannot go below their starting weight.
*/
function food_to_weight_weight_gain_map() {
	
	mmapi_log_info("food_to_weight", "attempting weight gain map");
	var _rt = global[$"__food_to_weight"];
	
	var npc_db = global[$"__npc_prototypes"];
	
	_rt.weight_gain = {};
	
	mmapi_log_info("food_to_weight", "made weight gain a new map");
	//loops through NPCs, rejecting child and animal NPCs
	for (i = 0; i < NpcId.LEN; i++) {
			if (array_has(npc_db[i].tags, "child")) || (array_has(npc_db[i].tags, "animal")) {
			continue; 
			}
			var name = npc_id_to_string(i);
			//only sets gained weight to 0 if the NPC doesn't already have any weight gained, compensating for custom NPCs added after the mod was already installed
			if _rt.weight_gain[$ name] == undefined {	
				_rt.weight_gain[$ name] =  0;
		}
	}
	mmapi_log_info("food_to_weight", "weight gain map established");
}


//Runs when relationship menu is opened, displays weight value under every valid NPC
//This is where the total weight is actually calculated to be displayed.
function food_to_weight_relationship_row(_ctx) {
	
	var _rt = global[$"__food_to_weight"];
	
	//displays the weight only if the NPC has a recorded weight and has been met
	if (_rt.base_weights.get(npc_id_to_string(_ctx.npc_id)) != undefined) && (_ctx.npc.has_met()) {
		
		var name = npc_id_to_string(_ctx.npc_id);
		//Calculation first divides the weight gain stat by 100 and rounds down to make the number of pounds an integer, then adds that to the base weight for the final result
		var current_weight = _rt.base_weights.get(name) + floor(_rt.weight_gain[$ name] / 100);
		
		//the rest of this is just placing the 'lb'text based on where the giftbox icon is, then aligning the number display to the left of the 'lb'
		var weight_display = ANCHOR.text(_ctx.gift_icon)
			.set_align(Align.RightOut, Align.Middle)
			.set_lut(COMMON_LUT)
			.set_text("lb")
			.set_xy(21, 8); 
		
		text = ANCHOR.text(weight_display)
			.set_align(Align.LeftOut,Align.Middle)
			.set_lut(COMMON_LUT)
			.set_text(string(current_weight));

	}

}



//Weight gain calculation, runs when a gift is handed to an NPC. Liked and loved gifts add multipliers to the weight value of the given food.
function food_to_weight_gift_received(_ctx) {
	
	//this is a lot of fiddling with variables because the npc.gift_received hook kind of sucks and gives you the live objects instead of the direct indexes of the NPC and item
	var _rt = global[$"__food_to_weight"];
	var npc_proto = global[$"__npc_prototypes"];
	var item_proto = global[$"__item_data"];
	//So this one grabs the string of the given food item i.e. "spell_fruit_parfait"
	var item_name = item_id_to_string(_ctx.item.item_id);
	//This one grabs the string of the NPC name i.e. "juniper"
	var npc_name = npc_id_to_string(_ctx.npc.npc_id);	
	//This one grabs the NPC's current weight gained from this mod's global variable
	var current_weight = _rt.weight_gain[$ npc_name];
	//These two use the index numbers of the item and NPC to find their prototype data within their respective globals
	var npc_proto_index = npc_proto[_ctx.npc.npc_id];
	var item_proto_index = item_proto[_ctx.item.item_id];
	
	mmapi_log_info("food_to_weight", "set current weight variable");
	
	//don't bother if NPC doesn't have a recorded weight
	if _rt.base_weights.get(npc_name) == undefined {
		return;
	}
	
	//only run if item has recorded weight stat
	if _rt.food_weights.get(item_name) != undefined {
		var food_weight = _rt.food_weights.get(item_name);
		
		//Multipliers for food weights. If the NPC loves it, its multiplied by 2. If they like it, the multiplier is 1.4.
		//If they dislike it, (i.e. Adeline dislikes mushrooms) then the food weight is set to 0, to simulate that the NPC would not eat it.
		 if _ctx.item.infusion == Infusion.Loveable || npc_proto_index.loved_gifts.contains(_ctx.item.item_id) {
                    food_weight *= 2;
                } else if _ctx.item.infusion == Infusion.Likeable || npc_proto_index.liked_gifts.contains(_ctx.item.item_id){
                    food_weight *= 1.4;
                } else if item_proto_index.tags.contains_any_value_from(npc_proto_index.disliked_gift_tags) {
                    food_weight = 0;
                }
		//defaults negative weight gain values to 0
		var new_weight = food_weight + current_weight;
		if new_weight < 0 {
			new_weight = 0;
		}
		_rt.weight_gain[$ npc_name] = new_weight;
	}

}

//This just builds all the maps on a save's load
function food_to_weight_map_loader() {
	food_to_weight_food_map();
	food_to_weight_base_weight_map();
	food_to_weight_weight_gain_map();
}

//runs when game saves, stores in mod sidecar
function food_to_weight_saving () {
	_rt = global[$"__food_to_weight"]
	var save_data = _rt.weight_gain;
	mmapi_log_info("food_to_weight", "Mod Data Saved");
	return save_data;
}

//runs as a save loads in, skips if the save hasn't been used with the mod yet
function food_to_weight_on_load (save_data){
	_rt = global[$"__food_to_weight"]
	if save_data == undefined {
		return;
	}
	_rt.weight_gain = save_data;
	mmapi_log_info("food_to_weight", "Save File Loaded");
	return;
}

mmapi_mod_declare("food_to_weight", "1.0.0");
food_to_weight_register_callbacks();

//calls the save & load handlers when needed
mmapi_modsave_register("food_to_weight", food_to_weight_saving, food_to_weight_on_load);