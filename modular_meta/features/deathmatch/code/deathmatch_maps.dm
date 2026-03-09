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
	max_players = 18
	allowed_loadouts = list(
		/datum/outfit/deathmatch_loadout/t_mid_east,
		/datum/outfit/deathmatch_loadout/ct_mid_east,
	)
	map_name = "middle_east_showdown"
	key = "middle_east_showdown"

/* /datum/lazy_template/deathmatch/kamurocho //recycle unit
	name = "Kamurochō"
	desc = "I Receive You."
	max_players = 8
	allowed_loadouts = list(
		/datum/outfit/deathmatch_loadout/dragon_of_dojima,
		/datum/outfit/deathmatch_loadout/mad_dog_of_shimano,
	)
	map_name = "kamurocho"
	key = "kamurocho" */

/datum/lazy_template/deathmatch/island_operation
	name = "Island Operation"
	desc = "Infiltrate to 'Einstein' Island and defuse bomb."
	max_players = 10
	allowed_loadouts = list(
		/datum/outfit/deathmatch_loadout/ct_mid_east,
	)
	map_name = "island_operation"
	key = "island_operation"

/datum/lazy_template/deathmatch/library
	name = "Library of Sanity"
	desc = "Silence. I'VE SAID SILENCE."
	max_players = 15
	allowed_loadouts = list(
		/datum/outfit/deathmatch_loadout/curator,
	)
	map_name = "library"
	key = "library"

/datum/lazy_template/deathmatch/nuthouse
	name = "Nuthouse"
	desc = "DurkaRP."
	max_players = 6
	allowed_loadouts = list(
		/datum/outfit/deathmatch_loadout/patient,
	)
	map_name = "nuthouse"
	key = "nuthouse"
