// Integration of ban system with Discord bot
// Adds ban events to bot event queue for JS bot

/datum/admins/create_ban(player_key, ip_check, player_ip, cid_check, player_cid, use_last_connection, applies_to_admins, duration, interval, severity, reason, list/roles_to_ban)
	log_admin_private("BOT DEBUG: create_ban called for [player_key]")
	if(!check_rights(R_BAN))
		return
	if(!SSdbcore.Connect())
		to_chat(usr, span_danger("Failed to establish database connection."), confidential = TRUE)
		return
	var/player_ckey = ckey(player_key)
	if(player_ckey)
		var/datum/db_query/query_create_ban_get_player = SSdbcore.NewQuery({"
			SELECT byond_key, INET_NTOA(ip), computerid FROM [format_table_name("player")] WHERE ckey = :player_ckey
		"}, list("player_ckey" = player_ckey))
		if(!query_create_ban_get_player.warn_execute())
			qdel(query_create_ban_get_player)
			return
		if(query_create_ban_get_player.NextRow())
			player_key = query_create_ban_get_player.item[1]
			if(use_last_connection)
				if(ip_check)
					player_ip = query_create_ban_get_player.item[2]
				if(cid_check)
					player_cid = query_create_ban_get_player.item[3]
		else
			if(use_last_connection)
				if(tgui_alert(usr, "[player_key]/([player_ckey]) has not been seen before, unable to use IP and CID from last connection. Are you sure you want to create a ban for them?", "Unknown key", list("Yes", "No", "Cancel")) != "Yes")
					qdel(query_create_ban_get_player)
					return
			else
				if(tgui_alert(usr, "[player_key]/([player_ckey]) has not been seen before, are you sure you want to create a ban for them?", "Unknown key", list("Yes", "No", "Cancel")) != "Yes")
					qdel(query_create_ban_get_player)
					return
		qdel(query_create_ban_get_player)
	var/admin_ckey = usr.client.ckey
	if(applies_to_admins && !can_place_additional_admin_ban(admin_ckey))
		return
	var/admin_ip = usr.client.address
	var/admin_cid = usr.client.computer_id
	duration = text2num(duration)
	if (!(interval in list("SECOND", "MINUTE", "HOUR", "DAY", "WEEK", "MONTH", "YEAR")))
		interval = "MINUTE"
	var/time_message = "[duration] [LOWER_TEXT(interval)]" //no DisplayTimeText because our duration is of variable interval type
	if(duration > 1) //pluralize the interval if necessary
		time_message += "s"
	var/is_server_ban = (roles_to_ban[1] == "Server")
	var/note_reason = "Banned from [is_server_ban ? "the server" : " Roles: [roles_to_ban.Join(", ")]"] [isnull(duration) ? "permanently" : "for [time_message]"] - [reason]"
	var/list/clients_online = GLOB.clients.Copy()
	var/list/admins_online = list()
	for(var/client/C in clients_online)
		if(C.holder) //deadmins aren't included since they wouldn't show up on adminwho
			admins_online += C
	var/who = clients_online.Join(", ")
	var/adminwho = admins_online.Join(", ")
	var/kn = key_name(usr)
	var/kna = key_name_admin(usr)

	var/special_columns = list(
		"bantime" = "NOW()",
		"server_ip" = "INET_ATON(?)",
		"ip" = "INET_ATON(?)",
		"a_ip" = "INET_ATON(?)",
		"expiration_time" = "IF(? IS NULL, NULL, NOW() + INTERVAL ? [interval])"
	)
	var/sql_ban = list()
	for(var/role in roles_to_ban)
		sql_ban += list(list(
			"server_ip" = world.internet_address || 0,
			"server_port" = world.port,
			"round_id" = GLOB.round_id,
			"role" = role,
			"expiration_time" = duration,
			"applies_to_admins" = applies_to_admins,
			"reason" = reason,
			"ckey" = player_ckey || null,
			"ip" = player_ip || null,
			"computerid" = player_cid || null,
			"a_ckey" = admin_ckey,
			"a_ip" = admin_ip || null,
			"a_computerid" = admin_cid,
			"who" = who,
			"adminwho" = adminwho,
		))
	if(!SSdbcore.MassInsert(format_table_name("ban"), sql_ban, warn = TRUE, special_columns = special_columns))
		return
	var/target = ban_target_string(player_key, player_ip, player_cid)
	var/msg = "has created a [isnull(duration) ? "permanent" : "temporary [time_message]"] [applies_to_admins ? "admin " : ""][is_server_ban ? "server ban" : "role ban from [roles_to_ban.len] roles"] for [target]."
	log_admin_private("[kn] [msg][is_server_ban ? "" : " Roles: [roles_to_ban.Join(", ")]"] Reason: [reason]")
	message_admins("[kna] [msg][is_server_ban ? "" : " Roles: [roles_to_ban.Join("\n")]"]\nReason: [reason]")
	if(applies_to_admins)
		send2adminchat("BAN ALERT","[kn] [msg]")
	if(player_ckey)
		create_message("note", player_ckey, admin_ckey, note_reason, null, null, 0, 0, null, 0, severity)

	var/player_ban_notification = span_boldannounce("You have been [applies_to_admins ? "admin " : ""]banned by [usr.client.key] from [is_server_ban ? "the server" : " Roles: [roles_to_ban.Join(", ")]"].\nReason: [reason]</span><br>[span_danger("This ban is [isnull(duration) ? "permanent." : "temporary, it will be removed in [time_message]."] The round ID is [GLOB.round_id].")]")
	var/other_ban_notification = span_boldannounce("Another player sharing your IP or CID has been banned by [usr.client.key] from [is_server_ban ? "the server" : " Roles: [roles_to_ban.Join(", ")]"].\nReason: [reason]</span><br>[span_danger("This ban is [isnull(duration) ? "permanent." : "temporary, it will be removed in [time_message]."] The round ID is [GLOB.round_id].")]")

	notify_all_banned_players(player_ckey, player_ip, player_cid, player_ban_notification, other_ban_notification, is_server_ban, applies_to_admins)

	var/datum/admin_help/linked_ahelp_ticket = admin_ticket_log(player_ckey, "[kna] [msg]")

	if(is_server_ban && linked_ahelp_ticket)
		linked_ahelp_ticket.Resolve()

	// Add single ban event to bot event queue with all roles
	// This prevents duplicate messages when banning multiple roles at once
	var/ban_event_data = list(
		"type" = "ban",
		"action" = "created",
		"ckey" = player_ckey,
		"name" = player_key,
		"admin_ckey" = admin_ckey,
		"admin_name" = usr.client.key,
		"roles" = roles_to_ban, // Array of all banned roles
		"reason" = reason,
		"duration" = isnull(duration) ? "permanent" : time_message,
		"interval" = interval, // Interval type (SECOND, MINUTE, HOUR, DAY, WEEK, MONTH, YEAR)
		"applies_to_admins" = applies_to_admins,
		"server_ban" = is_server_ban,
		"round_id" = GLOB.round_id
	)
	add_ban_event_to_queue("created", ban_event_data)

/datum/admins/unban(ban_id, player_key, player_ip, player_cid, role, page, admin_key)
	if(!check_rights(R_BAN))
		return
	if(!SSdbcore.Connect())
		to_chat(usr, span_danger("Failed to establish database connection."), confidential = TRUE)
		return
	var/target = ban_target_string(player_key, player_ip, player_cid)
	// Make sure the only input that doesn't early return is "Yes" - This is the only situation in which we want the unban to proceed.
	if(tgui_alert(usr, "Please confirm unban of [target] from [role].", "Unban confirmation", list("Yes", "No")) != "Yes")
		return
	var/kn = key_name(usr)
	var/kna = key_name_admin(usr)
	var/change_message = "[usr.client.key] unbanned [target] from [role] on [ISOtime()] during round #[GLOB.round_id]<hr>"
	var/datum/db_query/query_unban = SSdbcore.NewQuery({"
		UPDATE [format_table_name("ban")] SET
			unbanned_datetime = NOW(),
			unbanned_ckey = :admin_ckey,
			unbanned_ip = INET_ATON(:admin_ip),
			unbanned_computerid = :admin_cid,
			unbanned_round_id = :round_id,
			edits = CONCAT(IFNULL(edits,''), :change_message)
		WHERE id = :ban_id
	"}, list("ban_id" = ban_id, "admin_ckey" = usr.client.ckey, "admin_ip" = usr.client.address, "admin_cid" = usr.client.computer_id, "round_id" = GLOB.round_id, "change_message" = change_message))
	if(!query_unban.warn_execute())
		qdel(query_unban)
		return
	qdel(query_unban)
	log_admin_private("[kn] has unbanned [target] from [role].")
	message_admins("[kna] has unbanned [target] from [role].")
	var/client/C = GLOB.directory[player_key]
	if(C)
		build_ban_cache(C)
		to_chat(C, span_boldannounce("[usr.client.key] has removed a ban from [role] for your key."), confidential = TRUE)
	for(var/client/i in GLOB.clients - C)
		if(i.address == player_ip || i.computer_id == player_cid)
			build_ban_cache(i)
			to_chat(i, span_boldannounce("[usr.client.key] has removed a ban from [role] for your IP or CID."), confidential = TRUE)
	unban_panel(player_key, admin_key, player_ip, player_cid, page)

	// Add unban event to bot event queue
	var/unban_event_data = list(
		"type" = "ban",
		"action" = "unbanned",
		"ckey" = ckey(player_key),
		"name" = player_key,
		"admin_ckey" = usr.client.ckey,
		"admin_name" = usr.client.key,
		"role" = role,
		"round_id" = GLOB.round_id
	)
	add_ban_event_to_queue("unbanned", unban_event_data)

/datum/admins/reban(ban_id, applies_to_admins, player_key, player_ip, player_cid, role, page, admin_key)
	if(!check_rights(R_BAN))
		return
	if(!SSdbcore.Connect())
		to_chat(usr, span_danger("Failed to establish database connection."), confidential = TRUE)
		return

	var/target = ban_target_string(player_key, player_ip, player_cid)
	// Make sure the only input that doesn't early return is "Yes" - This is the only situation in which we want the unban to proceed.
	if(tgui_alert(usr, "Please confirm undoing of unban of [target] from [role].", "Reban confirmation", list("Yes", "No")) != "Yes")
		return

	if(applies_to_admins && !can_place_additional_admin_ban(usr.client.ckey))
		return

	var/kn = key_name(usr)
	var/kna = key_name_admin(usr)
	var/change_message = "[usr.client.key] re-activated ban of [target] from [role] on [ISOtime()] during round #[GLOB.round_id]<hr>"
	var/datum/db_query/query_reban = SSdbcore.NewQuery({"
		UPDATE [format_table_name("ban")] SET
			unbanned_datetime = NULL,
			unbanned_ckey = NULL,
			unbanned_ip = NULL,
			unbanned_computerid = NULL,
			unbanned_round_id = NULL,
			edits = CONCAT(IFNULL(edits,''), :change_message)
		WHERE id = :ban_id
	"}, list("change_message" = change_message, "ban_id" = ban_id))
	if(!query_reban.warn_execute())
		qdel(query_reban)
		return
	qdel(query_reban)
	log_admin_private("[kn] has rebanned [target] from [role].")
	message_admins("[kna] has rebanned [target] from [role].")

	var/banned_player_message = span_boldannounce("[usr.client.key] has re-activated a removed ban from [role] for your key.")
	var/banned_other_message = span_boldannounce("[usr.client.key] has re-activated a removed ban from [role] for your IP or CID.")
	var/kick_banned_players = (role == "Server")

	notify_all_banned_players(ckey(player_key), player_ip, player_cid, banned_player_message, banned_other_message, kick_banned_players, applies_to_admins)
	unban_panel(player_key, admin_key, player_ip, player_cid, page)

	// Add reban event to bot event queue
	var/reban_event_data = list(
		"type" = "ban",
		"action" = "rebanned",
		"ckey" = ckey(player_key),
		"name" = player_key,
		"admin_ckey" = usr.client.ckey,
		"admin_name" = usr.client.key,
		"role" = role,
		"applies_to_admins" = applies_to_admins,
		"round_id" = GLOB.round_id
	)
	add_ban_event_to_queue("rebanned", reban_event_data)

/datum/admins/edit_ban(ban_id, player_key, ip_check, player_ip, cid_check, player_cid, use_last_connection, applies_to_admins, duration, interval, reason, mirror_edit, old_key, old_ip, old_cid, old_applies, admin_key, page, list/changes, is_server_ban)
	if(!check_rights(R_BAN))
		return
	if(!SSdbcore.Connect())
		to_chat(usr, span_danger("Failed to establish database connection."), confidential = TRUE)
		return
	var/player_ckey = ckey(player_key)
	var/bantime
	if(player_ckey)
		var/datum/db_query/query_edit_ban_get_player = SSdbcore.NewQuery({"
			SELECT
				byond_key,
				(SELECT bantime FROM [format_table_name("ban")] WHERE id = :ban_id),
				ip,
				computerid
			FROM [format_table_name("player")]
			WHERE ckey = :player_ckey
		"}, list("player_ckey" = player_ckey, "ban_id" = ban_id))
		if(!query_edit_ban_get_player.warn_execute())
			qdel(query_edit_ban_get_player)
			return
		if(query_edit_ban_get_player.NextRow())
			player_key = query_edit_ban_get_player.item[1]
			bantime = query_edit_ban_get_player.item[2]
			if(use_last_connection)
				if(ip_check)
					player_ip = query_edit_ban_get_player.item[3]
				if(cid_check)
					player_cid = query_edit_ban_get_player.item[4]
		else
			if(use_last_connection)
				if(tgui_alert(usr, "[player_key]/([player_ckey]) has not been seen before, unable to use IP and CID from last connection. Are you sure you want to edit a ban for them?", "Unknown key", list("Yes", "No", "Cancel")) != "Yes")
					qdel(query_edit_ban_get_player)
					return
			else
				if(tgui_alert(usr, "[player_key]/([player_ckey]) has not been seen before, are you sure you want to edit a ban for them?", "Unknown key", list("Yes", "No", "Cancel")) != "Yes")
					qdel(query_edit_ban_get_player)
					return
		qdel(query_edit_ban_get_player)

	if(applies_to_admins && (applies_to_admins != old_applies) && !can_place_additional_admin_ban(usr.client.ckey))
		return

	if (!(interval in list("SECOND", "MINUTE", "HOUR", "DAY", "WEEK", "MONTH", "YEAR")))
		interval = "MINUTE"

	var/list/changes_text = list()
	var/list/changes_keys = list()
	for(var/i in changes)
		changes_text += "[i]: [changes[i]]"
		changes_keys += i
	var/change_message = "[usr.client.key] edited the following [jointext(changes_text, ", ")]<hr>"

	var/list/arguments = list(
		"duration" = duration || null,
		"reason" = reason,
		"applies_to_admins" = applies_to_admins,
		"ckey" = player_ckey || null,
		"ip" = player_ip || null,
		"cid" = player_cid || null,
		"change_message" = change_message,
	)
	var/where
	if(text2num(mirror_edit))
		var/list/wherelist = list("bantime = '[bantime]'")
		if(old_key)
			wherelist += "ckey = :old_ckey"
			arguments["old_ckey"] = ckey(old_key)
		if(old_ip)
			wherelist += "ip = INET_ATON(:old_ip)"
			arguments["old_ip"] = old_ip || null
		if(old_cid)
			wherelist += "computerid = :old_cid"
			arguments["old_cid"] = old_cid
		where = wherelist.Join(" AND ")
	else
		where = "id = :ban_id"
		arguments["ban_id"] = ban_id

	var/datum/db_query/query_edit_ban = SSdbcore.NewQuery({"
		UPDATE [format_table_name("ban")]
		SET
			expiration_time = IF(:duration IS NULL, NULL, bantime + INTERVAL :duration [interval]),
			applies_to_admins = :applies_to_admins,
			reason = :reason,
			ckey = :ckey,
			ip = INET_ATON(:ip),
			computerid = :cid,
			edits = CONCAT(IFNULL(edits,''), :change_message)
		WHERE [where]
	"}, arguments)
	if(!query_edit_ban.warn_execute())
		qdel(query_edit_ban)
		return
	qdel(query_edit_ban)

	var/changes_keys_text = jointext(changes_keys, ", ")
	var/kn = key_name(usr)
	var/kna = key_name_admin(usr)
	log_admin_private("[kn] has edited the [changes_keys_text] of a ban for [old_key ? "[old_key]" : "[old_ip]-[old_cid]"].") //if a ban doesn't have a key it must have an ip and/or a cid to have reached this point normally
	message_admins("[kna] has edited the [changes_keys_text] of a ban for [old_key ? "[old_key]" : "[old_ip]-[old_cid]"].")
	if(changes["Applies to admins"])
		send2adminchat("BAN ALERT","[kn] has edited a ban for [old_key ? "[old_key]" : "[old_ip]-[old_cid]"] to [applies_to_admins ? "" : "not"]affect admins")

	var/player_edit_message = span_boldannounce("[usr.client.key] has edited the [changes_keys_text] of a ban for your key.")
	var/other_edit_message = span_boldannounce("[usr.client.key] has edited the [changes_keys_text] of a ban for your IP or CID.")

	var/kick_banned_players = (is_server_ban && (changes["Key"] || changes["IP"] || changes["CID"]))

	notify_all_banned_players(player_ckey, player_ip, player_cid, player_edit_message, other_edit_message, kick_banned_players, applies_to_admins)

	unban_panel(player_key, null, null, null, page)

	// Add edit ban event to bot event queue
	var/edit_ban_event_data = list(
		"type" = "ban",
		"action" = "edited",
		"ckey" = player_ckey || ckey(old_key),
		"name" = player_key || old_key,
		"admin_ckey" = usr.client.ckey,
		"admin_name" = usr.client.key,
		"role" = changes_keys[1] || "unknown", // First changed field, typically role
		"changes" = changes,
		"duration" = isnull(duration) ? "permanent" : "[duration] [LOWER_TEXT(interval)]",
		"interval" = interval, // Interval type (SECOND, MINUTE, HOUR, DAY, WEEK, MONTH, YEAR)
		"round_id" = GLOB.round_id
	)
	add_ban_event_to_queue("edited", edit_ban_event_data)
