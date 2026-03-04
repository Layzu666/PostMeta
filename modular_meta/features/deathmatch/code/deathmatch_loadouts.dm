/datum/outfit/deathmatch_loadout/prisoner
	name = "Deathmatch: Prisoner"
	display_name = "Prisoner"
	desc = "You must have committed war crimes"

	uniform = /obj/item/clothing/under/rank/prisoner
	back = /obj/item/storage/backpack
	box = /obj/item/storage/box/survival/prisoner
	shoes = /obj/item/clothing/shoes/sneakers/orange

/datum/outfit/deathmatch_loadout/t_mid_east
	name = "Deathmatch: Arabic Syndicate Terrorist"
	display_name = "Alduin"
	desc = "Pray Allah"

	uniform = /obj/item/clothing/under/pants/slacks
	suit = /obj/item/clothing/suit/armor/vest
	suit_store = /obj/item/gun/ballistic/automatic/wt550
	gloves = /obj/item/clothing/gloves/fingerless
	belt = /obj/item/grenade/c4
	back = /obj/item/storage/backpack/saddlepack
	head = /obj/item/clothing/head/helmet/rus_helmet
	mask = /obj/item/clothing/mask/balaclava
	shoes = /obj/item/clothing/shoes/workboots

	l_pocket = /obj/item/ammo_box/magazine/wt550m9
	r_pocket = /obj/item/ammo_box/magazine/wt550m9

	backpack_contents = list(
		/obj/item/ammo_box/magazine/wt550m9,
		/obj/item/grenade/c4,
		/obj/item/grenade/c4,
	)

/datum/outfit/deathmatch_loadout/ct_mid_east
	name = "Deathmatch: NaTo Marines"
	display_name = "Soldier 'Peacemaker'"
	desc = "I am a soldier and I'm marching on"

	uniform = /obj/item/clothing/under/syndicate/rus_army
	suit = /obj/item/clothing/suit/armor/vest/marine
	gloves = /obj/item/clothing/gloves/combat
	belt = /obj/item/ammo_box/magazine/m38
	back = /obj/item/gun/ballistic/automatic/battle_rifle
	head = /obj/item/clothing/head/beret/militia
	shoes = /obj/item/clothing/shoes/jackboots/dagger

	l_pocket = /obj/item/ammo_box/magazine/m38
	r_pocket = /obj/item/ammo_box/magazine/m38
