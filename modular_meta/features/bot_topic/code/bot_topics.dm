/datum/world_topic/bans
	keyword = "bans"
	require_comms_key = TRUE

/datum/world_topic/bans/Run(list/input)
	var/target_ckey = input["bans"]
	var/bans_list = list()

	if(!SSdbcore.Connect())
		return list("bans" = list())

	var/datum/db_query/query_bans
	if(target_ckey)
		query_bans = SSdbcore.NewQuery({"
			SELECT
				id,
				bantime,
				round_id,
				expiration_time,
				TIMESTAMPDIFF(MINUTE, bantime, expiration_time) as duration,
				applies_to_admins,
				reason,
				IFNULL((SELECT byond_key FROM [format_table_name("player")] WHERE [format_table_name("player")].ckey = [format_table_name("ban")].ckey), ckey) as player_name,
				IFNULL((SELECT byond_key FROM [format_table_name("player")] WHERE [format_table_name("player")].ckey = [format_table_name("ban")].a_ckey), a_ckey) as admin_name,
				a_ckey as admin_ckey
			FROM [format_table_name("ban")]
			WHERE ckey = :ckey
				AND unbanned_datetime IS NULL
				AND (expiration_time IS NULL OR expiration_time > NOW())
			ORDER BY bantime DESC
		"}, list("ckey" = ckey(target_ckey)))
	else
		query_bans = SSdbcore.NewQuery({"
			SELECT
				id,
				bantime,
				round_id,
				expiration_time,
				TIMESTAMPDIFF(MINUTE, bantime, expiration_time) as duration,
				applies_to_admins,
				reason,
				IFNULL((SELECT byond_key FROM [format_table_name("player")] WHERE [format_table_name("player")].ckey = [format_table_name("ban")].ckey), ckey) as player_name,
				IFNULL((SELECT byond_key FROM [format_table_name("player")] WHERE [format_table_name("player")].ckey = [format_table_name("ban")].a_ckey), a_ckey) as admin_name,
				a_ckey as admin_ckey
			FROM [format_table_name("ban")]
			WHERE unbanned_datetime IS NULL
				AND (expiration_time IS NULL OR expiration_time > NOW())
			ORDER BY bantime DESC
			LIMIT 100
		"}, list())

	if(!query_bans.warn_execute())
		qdel(query_bans)
		return list("bans" = list())

	while(query_bans.NextRow())
		var/ban_data = list(
			"type" = "ban",
			"name" = query_bans.item["player_name"] || query_bans.item["ckey"],
			"ckey" = query_bans.item["ckey"],
			"admin_name" = query_bans.item["admin_name"] || query_bans.item["admin_ckey"],
			"admin" = query_bans.item["admin_ckey"],
			"timestamp" = query_bans.item["bantime"],
			"duration" = text2num(query_bans.item["duration"]),
			"reason" = query_bans.item["reason"]
		)
		bans_list += list(ban_data)

	qdel(query_bans)
	return list("bans" = bans_list)

/datum/world_topic/bot_events
	keyword = "bot_events"
	require_comms_key = TRUE

/datum/world_topic/bot_events/Run(list/input)
	var/last_index = text2num(input["bot_events"]) || 0
	var/events_list = list()
	var/current_index = length(GLOB.bot_event_sending_que)

	if(last_index < current_index)
		for(var/i in (last_index + 1) to current_index)
			if(i <= length(GLOB.bot_event_sending_que))
				events_list += json_encode(GLOB.bot_event_sending_que[i])

	// Format response for JS - return list of JSON strings
	return list("events" = events_list, "last_index" = current_index)

/datum/world_topic/playerinfo
	keyword = "playerinfo"
	require_comms_key = TRUE

/datum/world_topic/playerinfo/Run(list/input)
	var/target_ckey = ckey(input["playerinfo"])

	if(!target_ckey)
		return list("error" = "No ckey provided")

	if(!SSdbcore.Connect())
		return list("error" = "Database connection failed")

	var/player_data = list("ckey" = target_ckey)

	var/datum/db_query/query_player = SSdbcore.NewQuery({"
		SELECT
			firstseen,
			lastseen
		FROM [format_table_name("player")]
		WHERE ckey = :ckey
		LIMIT 1
	"}, list("ckey" = target_ckey))

	if(!query_player.warn_execute())
		qdel(query_player)
		return list("error" = "Query failed")

	if(query_player.NextRow())
		// item is a list, not an associative list - use indexes
		player_data["first_seen"] = query_player.item[1]
		player_data["last_seen"] = query_player.item[2]
	else
		qdel(query_player)
		return list("error" = "Player not found")

	qdel(query_player)

	// Get total playtime from role_time - sum on BYOND side instead of SQL
	//Otherwise throws nulls for whatever reason, duh..
	var/datum/db_query/query_playtime = SSdbcore.NewQuery({"
		SELECT minutes
		FROM [format_table_name("role_time")]
		WHERE ckey = :ckey
	"}, list("ckey" = target_ckey))

	var/total_minutes = 0
	if(query_playtime.warn_execute())
		while(query_playtime.NextRow())
			var/minutes = text2num(query_playtime.item[1]) || 0
			total_minutes += minutes
		player_data["playtime"] = total_minutes
	else
		player_data["playtime"] = 0

	qdel(query_playtime)

	// Get achievements count
	var/datum/db_query/query_achievements = SSdbcore.NewQuery({"
		SELECT COUNT(*) as achievement_count
		FROM [format_table_name("achievements")]
		WHERE ckey = :ckey
	"}, list("ckey" = target_ckey))

	if(query_achievements.warn_execute() && query_achievements.NextRow())
		// item is a list, not an associative list - use indexes
		player_data["achievements"] = text2num(query_achievements.item[1]) || 0
	else
		player_data["achievements"] = 0

	qdel(query_achievements)

	// Get role time details
	var/datum/db_query/query_roles = SSdbcore.NewQuery({"
		SELECT job, minutes
		FROM [format_table_name("role_time")]
		WHERE ckey = :ckey
			AND job NOT IN ('Living', 'Admin')
		ORDER BY minutes DESC
	"}, list("ckey" = target_ckey))

	var/roles_list = list()
	if(query_roles.warn_execute())
		while(query_roles.NextRow())
			// item is a list, not an associative list - use indexes
			roles_list += list(list(
				"job" = query_roles.item[1],
				"minutes" = text2num(query_roles.item[2]) || 0
			))
	qdel(query_roles)
	player_data["roles"] = json_encode(roles_list)

	// Get achievements details
	//Excludes Achievements Score and boss killed statistics, as it's not, well. An achievement? Though it's still present in the same database under the achievement_key line.
	var/datum/db_query/query_achievements_detail = SSdbcore.NewQuery({"
		SELECT achievement_key, last_updated
		FROM [format_table_name("achievements")]
		WHERE ckey = :ckey
			AND achievement_key NOT IN ('Achievements Score')
			AND LOWER(achievement_key) NOT LIKE '%killed'
		ORDER BY last_updated DESC
	"}, list("ckey" = target_ckey)) // should work?

	var/achievements_list = list()
	if(query_achievements_detail.warn_execute())
		while(query_achievements_detail.NextRow())
			// item is a list, not an associative list - use indexes
			var/ach_key = query_achievements_detail.item[1]
			var/ach_date = query_achievements_detail.item[2]
			achievements_list += list(list(
				"achievement_key" = ach_key,
				"last_updated" = ach_date
			))
	qdel(query_achievements_detail)
	player_data["achievements_detail"] = json_encode(achievements_list)

	return player_data

/// Topic handler for getting OOC messages from queue
/datum/world_topic/ooc_messages
	keyword = "ooc_messages"
	require_comms_key = TRUE

/datum/world_topic/ooc_messages/Run(list/input)
	var/ooc_list = list()

	if(!GLOB.bot_ooc_sending_que)
		GLOB.bot_ooc_sending_que = list()
		return list("ooc" = "[]")

	// Copy and clear the queue
	ooc_list = GLOB.bot_ooc_sending_que.Copy()
	GLOB.bot_ooc_sending_que = list()

	var/json_ooc = json_encode(ooc_list)
	return list("ooc" = json_ooc)

/// Topic handler for sending OOC messages from Discord to game
/datum/world_topic/send_ooc
	keyword = "send_ooc"
	require_comms_key = TRUE
	required_params = list("author", "message")

/datum/world_topic/send_ooc/Run(list/input)
	var/author = input["author"]
	var/message = input["message"]

	if(!author || !message)
		return list("error" = "Missing author or message")

	message = sanitize(message)

	for(var/client/C in GLOB.clients)
		if(!C.prefs)
			continue
		if(!(C.prefs.chat_toggles & CHAT_OOC))
			continue
		to_chat(C, "<span class='ooc'><span class='prefix'>DISCORD OOC:</span> <EM>[author]:</EM> <span class='message linkify'>[message]</span></span>")

	return list("success" = TRUE)
