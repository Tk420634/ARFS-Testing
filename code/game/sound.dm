/proc/playsound(atom/source, soundin, vol as num, vary, extrarange as num, falloff, frequency = null, channel = 0, pressure_affected = TRUE)
	if(isarea(source))
		error("[source] is an area and is trying to make the sound: [soundin]")
		return

	var/turf/turf_source = get_turf(source)

	//allocate a channel if necessary now so its the same for everyone
	channel = channel || open_sound_channel()

 	// Looping through the player list has the added bonus of working for mobs inside containers
	var/sound/S = sound(get_sfx(soundin))
	var/maxdistance = (world.view + extrarange) * 3
	for(var/P in player_list)
		var/mob/M = P
		if(!M || !M.client)
			continue
		var/distance = get_dist(M, turf_source)

		if(distance <= maxdistance)
			var/turf/T = get_turf(M)

			if(T && T.z == turf_source.z)
				M.playsound_local(turf_source, soundin, vol, vary, frequency, falloff, channel, pressure_affected, S)

/mob/proc/playsound_local(turf/turf_source, soundin, vol as num, vary, frequency, falloff, channel = 0, pressure_affected = TRUE, sound/S)
	if(!client || !can_hear())
		return

	if(!S)
		S = sound(get_sfx(soundin))

	S.wait = 0 //No queue
	S.channel = channel || open_sound_channel()
	S.volume = vol

	if(vary)
		if(frequency)
			S.frequency = frequency
		else
			S.frequency = get_rand_frequency()

	if(isturf(turf_source))
		var/turf/T = get_turf(src)

		//sound volume falloff with distance
		var/distance = get_dist(T, turf_source)

		S.volume -= max(distance - world.view, 0) * 2 //multiplicative falloff to add on top of natural audio falloff.

		if(pressure_affected)
			//Atmosphere affects sound
			var/pressure_factor = 1
			var/datum/gas_mixture/hearer_env = T.return_air()
			var/datum/gas_mixture/source_env = turf_source.return_air()

			if(hearer_env && source_env)
				var/pressure = min(hearer_env.return_pressure(), source_env.return_pressure())
				if(pressure < ONE_ATMOSPHERE)
					pressure_factor = max((pressure - SOUND_MINIMUM_PRESSURE)/(ONE_ATMOSPHERE - SOUND_MINIMUM_PRESSURE), 0)
			else //space
				pressure_factor = 0

			if(distance <= 1)
				pressure_factor = max(pressure_factor, 0.15) //touching the source of the sound

			S.volume *= pressure_factor
			//End Atmosphere affecting sound

		if(S.volume <= 0)
			return //No sound

		var/dx = turf_source.x - T.x // Hearing from the right/left
		S.x = dx
		var/dz = turf_source.y - T.y // Hearing from infront/behind
		S.z = dz
		// The y value is for above your head, but there is no ceiling in 2d spessmens.
		S.y = 1
		S.falloff = (falloff ? falloff : FALLOFF_SOUNDS)

	src << S

/client/proc/playtitlemusic()
	if(!ticker || !ticker.login_music || config.disable_lobby_music)
		return
	if(prefs.sound & SOUND_LOBBY)
		src << sound(ticker.login_music, repeat = 0, wait = 0, volume = 85, channel = CHANNEL_LOBBYMUSIC) // MAD JAMS

/proc/open_sound_channel()
	var/static/next_channel = 1	//loop through the available 1024 - (the ones we reserve) channels and pray that its not still being used
	. = ++next_channel
	if(next_channel > CHANNEL_HIGHEST_AVAILABLE)
		next_channel = 1

/mob/proc/stop_sound_channel(chan)
	src << sound(null, repeat = 0, wait = 0, channel = chan)

/proc/get_rand_frequency()
	return rand(32000, 55000) //Frequency stuff only works with 45kbps oggs.

/proc/get_sfx(soundin)
	if(istext(soundin))
		switch(soundin)
			if("shatter")
				soundin = pick('sound/effects/Glassbr1.ogg','sound/effects/Glassbr2.ogg','sound/effects/Glassbr3.ogg')
			if("explosion")
				soundin = pick('sound/effects/Explosion1.ogg','sound/effects/Explosion2.ogg')
			if("sparks")
				soundin = pick('sound/effects/sparks1.ogg','sound/effects/sparks2.ogg','sound/effects/sparks3.ogg','sound/effects/sparks4.ogg')
			if("rustle")
				soundin = pick('sound/effects/rustle1.ogg','sound/effects/rustle2.ogg','sound/effects/rustle3.ogg','sound/effects/rustle4.ogg','sound/effects/rustle5.ogg')
			if("bodyfall")
				soundin = pick('sound/effects/bodyfall1.ogg','sound/effects/bodyfall2.ogg','sound/effects/bodyfall3.ogg','sound/effects/bodyfall4.ogg')
			if("punch")
				soundin = pick('sound/weapons/punch1.ogg','sound/weapons/punch2.ogg','sound/weapons/punch3.ogg','sound/weapons/punch4.ogg')
			if("clownstep")
				soundin = pick('sound/effects/clownstep1.ogg','sound/effects/clownstep2.ogg')
			if("jackboot")
				soundin = pick('sound/effects/jackboot1.ogg','sound/effects/jackboot2.ogg')
			if("swing_hit")
				soundin = pick('sound/weapons/genhit1.ogg', 'sound/weapons/genhit2.ogg', 'sound/weapons/genhit3.ogg')
			if("hiss")
				soundin = pick('sound/voice/hiss1.ogg','sound/voice/hiss2.ogg','sound/voice/hiss3.ogg','sound/voice/hiss4.ogg')
			if("pageturn")
				soundin = pick('sound/effects/pageturn1.ogg', 'sound/effects/pageturn2.ogg','sound/effects/pageturn3.ogg')
			if("gunshot")
				soundin = pick('sound/weapons/Gunshot.ogg', 'sound/weapons/Gunshot2.ogg','sound/weapons/Gunshot3.ogg','sound/weapons/Gunshot4.ogg')
			if("computer_ambience")
				soundin = pick('sound/goonstation/machines/ambicomp1.ogg', 'sound/goonstation/machines/ambicomp2.ogg', 'sound/goonstation/machines/ambicomp3.ogg')
			if("ricochet")
				soundin = pick('sound/weapons/effects/ric1.ogg', 'sound/weapons/effects/ric2.ogg','sound/weapons/effects/ric3.ogg','sound/weapons/effects/ric4.ogg','sound/weapons/effects/ric5.ogg')
			if("terminal_type")
				soundin = pick('sound/machines/terminal_button01.ogg', 'sound/machines/terminal_button02.ogg', 'sound/machines/terminal_button03.ogg',
							  'sound/machines/terminal_button04.ogg', 'sound/machines/terminal_button05.ogg', 'sound/machines/terminal_button06.ogg',
							  'sound/machines/terminal_button07.ogg', 'sound/machines/terminal_button08.ogg')
			if("growls")
				soundin = pick('sound/goonstation/voice/growl1.ogg', 'sound/goonstation/voice/growl2.ogg', 'sound/goonstation/voice/growl3.ogg')


			//arfcode start
			//This must go here unfortunately; unless we move the whole thing.
			if("step_boots")
				soundin = pick('sound/arf/footstep/boot-floor1.ogg', 'sound/arf/footstep/boot-floor2.ogg', 'sound/arf/footstep/boot-floor3.ogg', 'sound/arf/footstep/boot-floor4.ogg',\
							 'sound/arf/footstep/boot-floor5.ogg')
			if("step_generic_floor")
				soundin = pick('sound/arf/footstep/shoe-floor1.ogg', 'sound/arf/footstep/shoe-floor2.ogg', 'sound/arf/footstep/shoe-floor3.ogg', 'sound/arf/footstep/shoe-floor4.ogg',\
					 		'sound/arf/footstep/shoe-floor5.ogg', 'sound/arf/footstep/shoe-floor6.ogg', 'sound/arf/footstep/shoe-floor7.ogg')
			if("step_heels")
				soundin = pick('sound/arf/footstep/heel-floor1.ogg', 'sound/arf/footstep/heel-floor2.ogg')
			if("step_bare")
				soundin = pick('sound/arf/footstep/barefoot-floor1.ogg', 'sound/arf/footstep/barefoot-floor2.ogg', 'sound/arf/footstep/barefoot-floor3.ogg', 'sound/arf/footstep/barefoot-floor4.ogg')
			if("step_paw")
				soundin = pick('sound/arf/footstep/paw-floor1.ogg')
			if("step_snow")
				soundin = pick('sound/arf/footstep/all-snow1.ogg', 'sound/arf/footstep/all-snow2.ogg', 'sound/arf/footstep/all-snow3.ogg')
			if("step_resin")
				soundin = pick('sound/arf/footstep/all-resin1.ogg', 'sound/arf/footstep/all-resin2.ogg', 'sound/arf/footstep/all-resin3.ogg',\
							 'sound/arf/footstep/all-resin4.ogg', 'sound/arf/footstep/all-resin5.ogg')
			if("step_sand")
				soundin = pick('sound/arf/footstep/all-sand1.ogg', 'sound/arf/footstep/all-sand2.ogg', 'sound/arf/footstep/all-sand3.ogg')
			if("step_generic_rock")
				soundin = pick('sound/arf/footstep/shoe-rock1.ogg', 'sound/arf/footstep/shoe-rock2.ogg', 'sound/arf/footstep/shoe-rock3.ogg',\
							 'sound/arf/footstep/shoe-rock4.ogg', 'sound/arf/footstep/shoe-rock5.ogg', 'sound/arf/footstep/shoe-rock6.ogg')
			if("step_puddle")	//Small puddle of water, < 1 inch deep.
				soundin = pick('sound/arf/footstep/all-puddle1.ogg', 'sound/arf/footstep/all-puddle2.ogg', 'sound/arf/footstep/all-puddle3.ogg')
			if("step_water")	//Semi-deep water, no deeper than a foot.
				soundin = pick('sound/arf/footstep/all-water1.ogg', 'sound/arf/footstep/all-water2.ogg', 'sound/arf/footstep/all-water3.ogg', 'sound/arf/footstep/all-water4.ogg')
			if("step_metal")
				soundin = pick('sound/arf/footstep/all-plating1.ogg', 'sound/arf/footstep/all-plating2.ogg')
			if("step_sock")
				soundin = pick('sound/arf/footstep/sock-floor1.ogg', 'sound/arf/footstep/sock-floor2.ogg', 'sound/arf/footstep/sock-floor3.ogg')
			//Alien related sound effects
			if("alien_step")
				soundin = pick('sound/arf/alien/effects/step1.ogg', 'sound/arf/alien/effects/step2.ogg', 'sound/arf/alien/effects/step3.ogg', 'sound/arf/alien/effects/step4.ogg', 'sound/arf/alien/effects/step5.ogg')
			if("alien_step_run")
				soundin = pick('sound/arf/alien/effects/bang1.ogg', 'sound/arf/alien/effects/bang2.ogg', 'sound/arf/alien/effects/bang3.ogg', 'sound/arf/alien/effects/bang5.ogg')
			if("alien_screech")
				soundin = pick('sound/arf/alien/voice/screech1.ogg', 'sound/arf/alien/voice/screech2.ogg', 'sound/arf/alien/voice/screech3.ogg', 'sound/arf/alien/voice/screech4.ogg')
			if("alien_screech_far")
				soundin = pick('sound/arf/alien/voice/screechFar1.ogg', 'sound/arf/alien/voice/screechFar2.ogg', 'sound/arf/alien/voice/screechFar3.ogg', 'sound/arf/alien/voice/screechFar4.ogg',\
							   'sound/arf/alien/voice/screechFar5.ogg', 'sound/arf/alien/voice/screechFar6.ogg', 'sound/arf/alien/voice/screechFar7.ogg')
			if("alien_hiss")
				soundin = pick('sound/arf/alien/voice/hiss1.ogg', 'sound/arf/alien/voice/hiss2.ogg', 'sound/arf/alien/voice/hiss3.ogg')
			if("alien_hurt")
				soundin = pick('sound/arf/alien/voice/hurt1.ogg', 'sound/arf/alien/voice/hurt2.ogg')
			if("alien_gnarl")
				soundin = pick('sound/arf/alien/voice/gnarl1.ogg')
			if("alien_spit")
				soundin = pick('sound/arf/alien/effects/spit1.ogg')
			if("alien_growl")
				soundin = pick('sound/arf/alien/voice/growl1.ogg', 'sound/arf/alien/voice/growl3.ogg', 'sound/arf/alien/voice/growl8.ogg', 'sound/arf/alien/voice/growl9.ogg')
			if("alien_talk")
				soundin = pick('sound/arf/alien/voice/talk1.ogg', 'sound/arf/alien/voice/talk2.ogg', 'sound/arf/alien/voice/talk3.ogg', 'sound/arf/alien/voice/talk4.ogg')
			if("alien_resin_hit")
				soundin = pick('sound/arf/alien/effects/resinHit1.ogg', 'sound/arf/alien/effects/resinHit2.ogg', 'sound/arf/alien/effects/resinHit3.ogg')
			if("alien_weed")
				soundin = pick('sound/arf/alien/effects/weeds1.ogg', 'sound/arf/alien/effects/weeds2.ogg')
			if("alien_egg_hatch")
				soundin = pick('sound/arf/alien/effects/hatch1.ogg', 'sound/arf/alien/effects/hatch2.ogg', 'sound/arf/alien/effects/hatch3.ogg', 'sound/arf/alien/effects/hatch4.ogg')
			if("alien_secrete")
				soundin = pick('sound/arf/alien/effects/resin1.ogg', 'sound/arf/alien/effects/resin2.ogg', 'sound/arf/alien/effects/resin3.ogg', 'sound/arf/alien/effects/resin4.ogg')
			/* template
			if("")
				soundin = pick('sound/arf/')
			*/
			//arfcode end

	return soundin
