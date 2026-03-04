/datum/lazy_template/deathmatch/the_permabrig
	name = "The Permabrig"
	desc = "A recreation of ProtoBoxStation Permabrig."
	max_players = 8
	allowed_loadouts = list(/datum/outfit/deathmatch_loadout/prisoner)
	map_name = "protobox_permabrig"
	key = "protobox_permabrig"

/datum/lazy_template/deathmatch/byodm
	name = "Build Your Own Death Match"
	desc = "Modificated version of BYOS."
	max_players = 8
	allowed_loadouts = list(/datum/outfit/deathmatch_loadout/assistant)
	map_name = "BYODM"
	key = "BYODM"

/datum/lazy_template/deathmatch/middle_east
	name = "Middle East Showdown"
	desc = "Fight for N(a)T(o) or Arabic-Syndicate organization, whatever you choiced, fight everyone. \
	Redactors will go insane."
	max_players = 8
	allowed_loadouts = list(
		/datum/outfit/deathmatch_loadout/t_mid_east,
		/datum/outfit/deathmatch_loadout/ct_mid_east,
	)
	map_name = "middle_east_showdown"
	key = "middle_east_showdown"
