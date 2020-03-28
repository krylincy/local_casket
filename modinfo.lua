name = "Casket"
version = "1.0"
author = "krylincy"

description = "A small casket for your pocket. \n Version: "..version
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
		name = "machine",
		label = "Crafting Tier",
		options = {
			{description = "-", data = 0},
			{description = "Prestihatitator", data = 2},
			{description = "Shadow Manipulator", data = 3}
		},
		default = 0,
	}, {
		name = "purplegem",
		label = "Recipe Purple Gem",
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
