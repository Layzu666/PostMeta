/datum/action/cooldown/spell/jaunt/ethereal_jaunt/sin
	name = "Demonic Jaunt"
	desc = "Briefly turn to cinder and ash, allowing you to freely pass through objects."
	background_icon_state = "bg_demon"
	overlay_icon_state = "bg_demon_border"
	sound = 'sound/effects/magic/fireball.ogg'
	check_flags = AB_CHECK_CONSCIOUS|AB_CHECK_HANDS_BLOCKED //blockin hands cuz deez shitty pants demon bouta run from bloody cuffs
	spell_requirements = SPELL_REQUIRES_NO_ANTIMAGIC

	cooldown_time = 50 SECONDS

	jaunt_duration = 3.5 SECONDS
	jaunt_in_type = /obj/effect/temp_visual/dir_setting/ash_shift
