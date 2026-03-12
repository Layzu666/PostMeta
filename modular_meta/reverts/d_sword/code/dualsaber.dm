/obj/item/dualsaber
    block_chance = 100
/datum/uplink_item/dangerous/doublesword
    cost = 16
/datum/uplink_item/dangerous/doublesword/get_discount_value(discount_type)
	switch(discount_type)
		if(TRAITOR_DISCOUNT_BIG)
			return 0.35
		if(TRAITOR_DISCOUNT_AVERAGE)
			return 0.2
		else
			return 0.1
