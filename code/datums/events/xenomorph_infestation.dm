/datum/event/xenomorph_infestation
	id = "xenomorph_infestation"
	name = "Xenomorph Infestation"
	description = "Xenomorphs someway appears on the station."

	fire_only_once = TRUE
	mtth = 5 HOURS

/datum/event/xenomorph_infestation/get_mtth()
	. = ..()
	. -= (SSevents.triggers.living_players_count * (3 MINUTES))
	. -= (SSevents.triggers.roles_count["Security"] * (6 MINUTES))
	. = max(1 HOUR, .)

/datum/event/xenomorph_infestation/on_fire()
	var/location = pick(GLOB.xenospawn_areas)
	if(!location)
		log_debug("Xenomorph infestation failed to find a viable spawn location. Probably, there are no \"Xenomorph\" landmarks on the current map. Aborting.")
		return

	var/list/xenospawn_turfs = get_area_turfs(location, list(/proc/not_turf_contains_dense_objects))
	var/spawn_count = 3
	var/players_count = length(GLOB.player_list)
	if(players_count < 20)
		spawn_count = 1
	else if(players_count < 40)
		spawn_count = 2

	spawn()
		log_and_message_admins("Xenomorph infestation spawned ([spawn_count]) in \the [location].")
		while(length(xenospawn_turfs) && spawn_count > 0)
			var/turf/simulated/floor/T = pick(xenospawn_turfs)
			xenospawn_turfs.Remove(T)
			spawn_count--

			var/mob/living/carbon/alien/larva/L = new /mob/living/carbon/alien/larva(T)
			L.larva_announce_to_ghosts()
