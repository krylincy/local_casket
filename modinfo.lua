name = "Casket"
version = "1.2"
author = "krylincy"

description = "A small casket for your pocket. \n Version: "..version.."\n\nIf you play alone with no caves ( = as host) then you can change the 'Mod Style' configuration to 'Inventory'. In this case, the casket will extend your inventory, you can craft items from your casket and items you pickup will automatically stack in your casket - like a backback.\n\nIf you play with others or caves ( = as client) then you need to keep the 'Mod Style' configuration 'Portable Chest'. In this case, the casket works only like a portable chest. Items will not go into the casket if you pick them up and you can not craft from your casket."
forumthread = ""

api_version = 10

dst_compatible = true
client_only_mod = false
all_clients_require_mod = true

icon_atlas = "casket.xml"
icon = "casket.tex"

priority=-1

configuration_options = {
	{
		name = "modModeHost",
		label = "Mod Style",
        hover = "CAUTION: Use 'Inventory' only if you play alone as host without caves. For clients it has BUGS!",
		options = {
			{description = "Portable Chest", data = 0},
			{description = "Inventory", data = 1}
		},
		default = 0,
	},{
		name = "machine",
		label = "Crafting Tier",
        hover = "Recipe configuration",
		options = {
			{description = "-", data = 0},
			{description = "Prestihatitator", data = 2},
			{description = "Shadow Manipulator", data = 3}
		},
		default = 0,
	}, {
		name = "purplegem",
		label = "Recipe Purple Gem",
        hover = "Recipe configuration",
		options = {
			{description = "-", data = 0},
			{description = "1", data = 1},
			{description = "2", data = 2},
			{description = "3", data = 3},
			{description = "4", data = 4},
			{description = "5", data = 5},
			{description = "6", data = 6},
			{description = "7", data = 7},
			{description = "8", data = 8},
		},
		default = 0,
	}, {
		name = "nightmarefuel",
		label = "Recipe Nightmare Fuel",
        hover = "Recipe configuration",
		options = {
			{description = "-", data = 0},
			{description = "1", data = 1},
			{description = "2", data = 2},
			{description = "3", data = 3},
			{description = "4", data = 4},
			{description = "5", data = 5},
			{description = "6", data = 6},
			{description = "7", data = 7},
			{description = "8", data = 8},
		},
		default = 0,
	}, {
		name = "livinglog",
		label = "Recipe Living Log",
        hover = "Recipe configuration",
		options = {
			{description = "-", data = 0},
			{description = "1", data = 1},
			{description = "2", data = 2},
			{description = "3", data = 3},
			{description = "4", data = 4},
			{description = "5", data = 5},
			{description = "6", data = 6},
			{description = "7", data = 7},
			{description = "8", data = 8},
		},
		default = 0,
	}, {
		name = "goldnugget",
		label = "Recipe Gold Nugget",
        hover = "Recipe configuration",
		options = {
			{description = "-", data = 0},
			{description = "1", data = 1},
			{description = "2", data = 2},
			{description = "3", data = 3},
			{description = "4", data = 4},
			{description = "5", data = 5},
			{description = "6", data = 6},
			{description = "7", data = 7},
			{description = "8", data = 8},
		},
		default = 0,
	},
}
