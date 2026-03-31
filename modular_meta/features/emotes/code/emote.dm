/atom/movable/proc/display_image_in_bubble(image/displayed_image)
	var/mutable_appearance/display_bubble = mutable_appearance(
		'icons/effects/effects.dmi',
		"thought_bubble",
		offset_spokesman = src,
		plane = BALLOON_CHAT_PLANE,
		appearance_flags = KEEP_APART,
	)
	var/mutable_appearance/pointed_atom_appearance = new(displayed_image.appearance)
	pointed_atom_appearance.blend_mode = BLEND_INSET_OVERLAY
	pointed_atom_appearance.plane = FLOAT_PLANE
	pointed_atom_appearance.layer = FLOAT_LAYER
	pointed_atom_appearance.pixel_x = 0
	pointed_atom_appearance.pixel_y = 0
	display_bubble.overlays += pointed_atom_appearance
	display_bubble.pixel_w = 16
	display_bubble.pixel_z = 32
	display_bubble.alpha = 200
	add_overlay(display_bubble)
	LAZYADD(update_overlays_on_z, display_bubble)
	addtimer(CALLBACK(src, PROC_REF(clear_display_bubble), display_bubble), 3 SECONDS)

/atom/movable/proc/clear_display_bubble(mutable_appearance/display_bubble)
	LAZYREMOVE(update_overlays_on_z, display_bubble)
	cut_overlay(display_bubble)

/datum/emote/living/carbon/human/aprilfools
	var/emote_icon = 'modular_meta/features/emotes/icons/aprilfools_emotes.dmi'
	var/emote_icon_state = null
	cooldown = 20 SECONDS
	emote_type = EMOTE_VISIBLE

/datum/emote/living/carbon/human/aprilfools/run_emote(mob/user)
	. = ..()
	var/image/emote_image = image(emote_icon, user, emote_icon_state)
	user.display_image_in_bubble(emote_image)

/datum/emote/living/carbon/human/aprilfools/clueless
	key = "clueless"
	message = "looks clueless."
	emote_icon_state = "clueless"

/datum/emote/living/carbon/human/aprilfools/hmm
	key = "hmm"
	message = "squints their eyes."
	emote_icon_state = "hmm"

/datum/emote/living/carbon/human/aprilfools/troll
	key = "lmao"
	message = "is laughing their ass off!"
	emote_icon_state = "troll"

/datum/emote/living/carbon/human/aprilfools/reallymad
	key = "reallymad"
	message = "looks really mad about something!"
	emote_icon_state = "reallymad"
	sound = 'modular_meta/features/emotes/sounds/aprilfools/angry.ogg'

/datum/emote/living/carbon/human/aprilfools/zorp
	key = "zorp"
	message = "feels their impending doom approaching."
	emote_icon_state = "zorp"
	sound = 'modular_meta/features/emotes/sounds/aprilfools/bell.ogg'

/datum/emote/living/carbon/human/aprilfools/uncanny
	key = "uncanny"
	message = "looks really uncanny."
	emote_icon_state = "uncanny"
	sound = 'modular_meta/features/emotes/sounds/aprilfools/bell.ogg'

/datum/emote/living/carbon/human/aprilfools/xdd
	key = "xdd"
	message = "laughs."
	emote_icon_state = "xdd"

/datum/emote/living/carbon/human/aprilfools/xdd/run_emote(mob/user, params, type_override, intentional)
	. = ..()
	playsound(user, pick('modular_meta/features/emotes/sounds/aprilfools/goofylaugh.ogg', 'modular_meta/features/emotes/sounds/aprilfools/goofylaugh.ogg', 'modular_meta/features/emotes/sounds/aprilfools/goofylaugh.ogg', 'modular_meta/features/emotes/sounds/aprilfools/goofylaugh.ogg', 'modular_meta/features/emotes/sounds/aprilfools/goofylaugh2.ogg'), 50)

/datum/emote/living/carbon/human/aprilfools/taa
	key = "taa"
	message = "smokes an imaginary cigar."
	emote_icon_state = "taa"
	sound = 'modular_meta/features/emotes/sounds/aprilfools/rizz.ogg'

/datum/emote/living/carbon/human/aprilfools/noway
	key = "noway"
	message = "looks shocked!"
	emote_icon_state = "noway"
	sound = 'modular_meta/features/emotes/sounds/aprilfools/rizz.ogg'

/datum/emote/living/carbon/human/aprilfools/tuh
	key = "tuh"
	message = "gasps in shock!"
	emote_icon_state = "tuh"
	sound = 'modular_meta/features/emotes/sounds/aprilfools/vineboom.ogg'

/datum/emote/living/carbon/human/aprilfools/jokerge
	key = "jokerge"
	message = "grins."
	emote_icon_state = "jokerge"

/datum/emote/living/carbon/human/aprilfools/fuckingdies
	key = "fuckingdies"
	message = "fucking dies."
	emote_icon_state = "die"
	sound = 'modular_meta/features/emotes/sounds/aprilfools/rpdeath.ogg'

// Дальше идут мои эмоуты

/datum/emote/living/carbon/human/aprilfools/sex
    key = "sex"
    message = "includes a secret intent."
    emote_icon_state = "sex"
    sound = 'modular_meta/features/emotes/sounds/aprilfools/gey-echo.ogg'

/datum/emote/living/carbon/human/aprilfools/haram
    key = "haram"
    message = "это haram!"
    emote_icon_state = "haram"
    sound = 'modular_meta/features/emotes/sounds/aprilfools/musulmanin.ogg'

/datum/emote/living/carbon/human/aprilfools/robloxlaugh
    key = "robloxlaugh"
    message = "laughs like John Roblox."
    emote_icon_state = "robloxlaugh"
    sound = 'modular_meta/features/emotes/sounds/aprilfools/laughter-hahahahahaahahahah-funnyy.ogg'

/datum/emote/living/carbon/human/aprilfools/poebat
    key = "poebat"
    message = "he doesn't care."
    emote_icon_state = "poebat"
    sound = 'modular_meta/features/emotes/sounds/aprilfools/rizz-sound.ogg'

/datum/emote/living/carbon/human/aprilfools/money
    key = "money"
    message = "shows you the money!"
    emote_icon_state = "money"

/datum/emote/living/carbon/human/aprilfools/true
    key = "true"
    message = "speaks the truth."
    emote_icon_state = "true"

/datum/emote/living/carbon/human/aprilfools/jokerge1
    key = "jokerge1"
    message = "grins maniacally."
    emote_icon_state = "jokerge1"

/datum/emote/living/carbon/human/aprilfools/red
    key = "red"
    message = "it looks red."
    emote_icon_state = "red"
    sound = 'modular_meta/features/emotes/sounds/aprilfools/ia-uzhe-krasnyi.ogg'

/datum/emote/living/carbon/human/aprilfools/ohmygod
    key = "ohmygod"
    message = "pleasantly surprised."
    emote_icon_state = "ohmygod"
    sound = 'modular_meta/features/emotes/sounds/aprilfools/ohmygod.ogg'

