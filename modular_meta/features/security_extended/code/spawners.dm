/obj/effect/spawner/random/armory/laser_gun
	name = "laser rifle spawner"
	icon_state = "laser_gun"
	loot = list(
		/obj/item/gun/ballistic/automatic/laser/security,
	)

/obj/effect/spawner/random/armory/laser_gun/spawn_loot(lootcount_override)
	. = ..()
	new /obj/item/ammo_box/magazine/recharge(get_turf(src))
	new /obj/item/ammo_box/magazine/recharge(get_turf(src))
	new /obj/item/ammo_box/magazine/recharge(get_turf(src))
