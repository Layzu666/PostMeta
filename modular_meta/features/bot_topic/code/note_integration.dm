// Integration of note system with Discord bot
// Override of various procs found in code\modules\admin\sql_message_system.dm
/create_message(type, target_key, admin_ckey, text, timestamp, server, secret, logged = 1, browse, expiry, note_severity)
	if(!SSdbcore.Connect())
		to_chat(usr, span_danger("Failed to establish database connection."), confidential = TRUE)
		return
	if(!type)
		return
	var/target_ckey = ckey(target_key)
	if(!target_key && (type == "note" || type == "message" || type == "watchlist entry"))
		var/new_key = input(usr,"Who would you like to create a [type] for?","Enter a key or ckey",null) as null|text
		if(!new_key)
			return
		var/new_ckey = ckey(new_key)
		var/datum/db_query/query_find_ckey = SSdbcore.NewQuery(
			"SELECT ckey FROM [format_table_name("player")] WHERE ckey = :ckey",
			list("ckey" = new_ckey)
		)
		if(!query_find_ckey.warn_execute())
			qdel(query_find_ckey)
			return
		if(!query_find_ckey.NextRow())
			if(tgui_alert(usr, "[new_key]/([new_ckey]) has not been seen before, are you sure you want to create a [type] for them?", "Unknown ckey", list("Yes", "No", "Cancel")) != "Yes")
				qdel(query_find_ckey)
				return
		qdel(query_find_ckey)
		target_ckey = new_ckey
		target_key = new_key
	if(QDELETED(usr))
		return
	if(!target_key)
		target_key = target_ckey
	if(!admin_ckey)
		admin_ckey = usr.ckey
		if(!admin_ckey)
			return
	if(!target_ckey)
		target_ckey = admin_ckey
	if(!text)
		text = input(usr,"Write your [type]","Create [type]") as null|message
		if(!text)
			return
	if(!server)
		var/ssqlname = CONFIG_GET(string/serversqlname)
		if (ssqlname)
			server = ssqlname
	if(isnull(secret))
		switch(tgui_alert(usr,"Hide note from being viewed by players?", "Secret note?",list("Yes","No","Cancel")))
			if("Yes")
				secret = 1
			if("No")
				secret = 0
			else
				return
	if(isnull(expiry))
		if(tgui_alert(usr, "Set an expiry time? Expired messages are hidden like deleted ones.", "Expiry time?", list("Yes", "No", "Cancel")) == "Yes")
			var/expire_time = input("Set expiry time for [type] as format YYYY-MM-DD HH:MM:SS. All times in server time. HH:MM:SS is optional and 24-hour. Must be later than current time for obvious reasons.", "Set expiry time", ISOtime()) as null|text
			if(!expire_time)
				return
			var/datum/db_query/query_validate_expire_time = SSdbcore.NewQuery(
				"SELECT IF(STR_TO_DATE(:expire_time,'%Y-%c-%d %T') > NOW(), STR_TO_DATE(:expire_time,'%Y-%c-%d %T'), 0)",
				list("expire_time" = expire_time)
			)
			if(!query_validate_expire_time.warn_execute())
				qdel(query_validate_expire_time)
				return
			if(query_validate_expire_time.NextRow())
				var/checktime = text2num(query_validate_expire_time.item[1])
				if(!checktime)
					to_chat(usr, "Datetime entered is improperly formatted or not later than current server time.", confidential = TRUE)
					qdel(query_validate_expire_time)
					return
				expiry = query_validate_expire_time.item[1]
			qdel(query_validate_expire_time)
	if(type == "note" && isnull(note_severity))
		note_severity = input("Set the severity of the note.", "Severity", null, null) as null|anything in list("High", "Medium", "Minor", "None")
		if(!note_severity)
			return
	var/list/parameters = list(
		"type" = type,
		"target_ckey" = target_ckey,
		"admin_ckey" = admin_ckey,
		"text" = text,
		"server" = server,
		"internet_address" = world.internet_address || "0",
		"port" = "[world.port]",
		"round_id" = GLOB.round_id,
		"secret" = secret,
		"expiry" = expiry || null,
		"note_severity" = note_severity,
	)
	if(timestamp)
		parameters["timestamp"] = timestamp
	var/datum/db_query/query_create_message = SSdbcore.NewQuery({"
		INSERT INTO [format_table_name("messages")] (type, targetckey, adminckey, text, timestamp, server, server_ip, server_port, round_id, secret, expire_timestamp, severity, playtime)
		VALUES (:type, :target_ckey, :admin_ckey, :text, [timestamp? ":timestamp" : "Now()"], :server, INET_ATON(:internet_address), :port, :round_id, :secret, :expiry, :note_severity, (SELECT `minutes` FROM [format_table_name("role_time")] WHERE `ckey` = :target_ckey AND `job` = 'Living'))
	"}, parameters)
	var/pm = "[key_name(usr)] has created a [secret ? "secret " : ""][type][(type == "note" || type == "message" || type == "watchlist entry") ? " for [target_key]" : ""]: [text]"
	var/header = "[key_name_admin(usr)] has created a [secret ? "secret " : ""][type][(type == "note" || type == "message" || type == "watchlist entry") ? " for [target_key]" : ""]"
	if(!query_create_message.warn_execute())
		qdel(query_create_message)
		return
	qdel(query_create_message)
// Secret, or not?
	if(type == "note" && secret != 1)
		if(!GLOB.bot_event_sending_que)
			GLOB.bot_event_sending_que = list()
		var/note_event_data = list(
			"type" = "note",
			"action" = "created",
			"ckey" = target_ckey,
			"name" = target_key,
			"admin_ckey" = admin_ckey,
			"text" = text,
			"severity" = note_severity,
			"timestamp" = ISOtime(),
			"round_id" = GLOB.round_id
		)
		GLOB.bot_event_sending_que += list(note_event_data)
		log_admin_private("BOT DEBUG: Added note created event to queue. Ckey: [target_ckey], Admin: [admin_ckey]")

	if(logged)
		log_admin_private(pm)
		message_admins("[header]:<br>[text]")
		admin_ticket_log(target_ckey, "<font color='blue'>[header]</font><br>[text]")
		if(browse)
			browse_messages("[type]")
		else
			browse_messages(target_ckey = target_ckey, agegate = TRUE)

/delete_message(message_id, logged = 1, browse)
	if(!SSdbcore.Connect())
		to_chat(usr, span_danger("Failed to establish database connection."), confidential = TRUE)
		return
	message_id = text2num(message_id)
	if(!message_id)
		return
	var/type
	var/target_key
	var/text
	var/is_secret
	var/user_key_name = key_name(usr)
	var/user_name_admin = key_name_admin(usr)
	var/deleted_by_ckey = usr.ckey
	var/datum/db_query/query_find_del_message = SSdbcore.NewQuery(
		"SELECT type, IFNULL((SELECT byond_key FROM [format_table_name("player")] WHERE ckey = targetckey), targetckey), text, secret FROM [format_table_name("messages")] WHERE id = :id AND deleted = 0",
		list("id" = message_id)
	)
	if(!query_find_del_message.warn_execute())
		qdel(query_find_del_message)
		return
	if(query_find_del_message.NextRow())
		type = query_find_del_message.item[1]
		target_key = query_find_del_message.item[2]
		text = query_find_del_message.item[3]
		is_secret = text2num(query_find_del_message.item[4]) == 1
	qdel(query_find_del_message)
	var/datum/db_query/query_del_message = SSdbcore.NewQuery(
		"UPDATE [format_table_name("messages")] SET deleted = 1, deleted_ckey = :deleted_ckey WHERE id = :id",
		list("deleted_ckey" = deleted_by_ckey, "id" = message_id)
	)
	if(!query_del_message.warn_execute())
		qdel(query_del_message)
		return
	qdel(query_del_message)

	if(type == "note" && !is_secret)
		if(!GLOB.bot_event_sending_que)
			GLOB.bot_event_sending_que = list()
		var/note_event_data = list(
			"type" = "note",
			"action" = "deleted",
			"ckey" = ckey(target_key),
			"name" = target_key,
			"admin_ckey" = deleted_by_ckey,
			"text" = text,
			"timestamp" = ISOtime(),
			"round_id" = GLOB.round_id
		)
		GLOB.bot_event_sending_que += list(note_event_data)
		log_admin_private("BOT DEBUG: Added note deleted event to queue. Ckey: [ckey(target_key)], Admin: [deleted_by_ckey]")

	if(logged)
		var/m1 = "[user_key_name] has deleted a [type][(type == "note" || type == "message" || type == "watchlist entry") ? " for" : " made by"] [target_key]: [text]"
		var/m2 = "[user_name_admin] has deleted a [type][(type == "note" || type == "message" || type == "watchlist entry") ? " for" : " made by"] [target_key]:<br>[text]"
		log_admin_private(m1)
		message_admins(m2)
		if(browse)
			browse_messages("[type]")
		else
			browse_messages(target_ckey = ckey(target_key), agegate = TRUE)

/edit_message(message_id, browse)
	if(!SSdbcore.Connect())
		to_chat(usr, span_danger("Failed to establish database connection."), confidential = TRUE)
		return
	message_id = text2num(message_id)
	if(!message_id)
		return
	var/editor_ckey = usr.ckey
	var/editor_key = usr.key
	var/kn = key_name(usr)
	var/kna = key_name_admin(usr)
	var/datum/db_query/query_find_edit_message = SSdbcore.NewQuery({"
		SELECT
			type,
			IFNULL((SELECT byond_key FROM [format_table_name("player")] WHERE ckey = targetckey), targetckey),
			IFNULL((SELECT byond_key FROM [format_table_name("player")] WHERE ckey = adminckey), adminckey),
			text,
			secret
		FROM [format_table_name("messages")]
		WHERE id = :id AND deleted = 0
	"}, list("id" = message_id))
	if(!query_find_edit_message.warn_execute())
		qdel(query_find_edit_message)
		return
	if(query_find_edit_message.NextRow())
		var/type = query_find_edit_message.item[1]
		var/target_key = query_find_edit_message.item[2]
		var/admin_key = query_find_edit_message.item[3]
		var/old_text = query_find_edit_message.item[4]
		var/is_secret = text2num(query_find_edit_message.item[5]) == 1
		var/new_text = input("Input new [type]", "New [type]", "[old_text]") as null|message
		if(!new_text)
			qdel(query_find_edit_message)
			return
		var/edit_text = "Edited by [editor_key] on [ISOtime()] from<br>[old_text]<br>to<br>[new_text]<hr>"
		var/datum/db_query/query_edit_message = SSdbcore.NewQuery({"
			UPDATE [format_table_name("messages")]
			SET text = :text, lasteditor = :lasteditor, edits = CONCAT(IFNULL(edits,''),:edit_text)
			WHERE id = :id AND deleted = 0
		"}, list("text" = new_text, "lasteditor" = editor_ckey, "edit_text" = edit_text, "id" = message_id))
		if(!query_edit_message.warn_execute())
			qdel(query_edit_message)
			return
		qdel(query_edit_message)

		if(type == "note" && !is_secret)
			if(!GLOB.bot_event_sending_que)
				GLOB.bot_event_sending_que = list()
			var/note_event_data = list(
				"type" = "note",
				"action" = "edited",
				"ckey" = ckey(target_key),
				"name" = target_key,
				"admin_ckey" = editor_ckey,
				"old_text" = old_text,
				"new_text" = new_text,
				"timestamp" = ISOtime(),
				"round_id" = GLOB.round_id
			)
			GLOB.bot_event_sending_que += list(note_event_data)
			log_admin_private("BOT DEBUG: Added note edited event to queue. Ckey: [ckey(target_key)], Admin: [editor_ckey]")

		log_admin_private("[kn] has edited a [type] [(type == "note" || type == "message" || type == "watchlist entry") ? " for [target_key]" : ""] made by [admin_key] from [old_text] to [new_text]")
		message_admins("[kna] has edited a [type] [(type == "note" || type == "message" || type == "watchlist entry") ? " for [target_key]" : ""] made by [admin_key] from<br>[old_text]<br>to<br>[new_text]")
		if(browse)
			browse_messages("[type]")
		else
			browse_messages(target_ckey = ckey(target_key), agegate = TRUE)
	qdel(query_find_edit_message)
