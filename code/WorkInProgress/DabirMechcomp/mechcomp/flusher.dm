/obj/item/mechanics/flusher
	name = "Flusher component"
	desc = ""
	icon_state = "comp_flush"

	var/ready = 1
	var/obj/disposalpipe/trunk/trunk = null
	var/datum/gas_mixture/air_contents

	New()
		. = ..()
		verbs -= /obj/item/mechanics/verb/setvalue
		mechanics.addInput("flush", "flushp")

	disposing()
		if(air_contents)
			pool(air_contents)
			air_contents = null
		trunk = null
		..()

	attackby(obj/item/W as obj, mob/user as mob)
		if(..(W, user))
			if(src.level == 1) //wrenched down
				trunk = locate() in src.loc
				if(trunk)
					trunk.linked = src
					air_contents = unpool(/datum/gas_mixture)
			else if (src.level == 2) //loose
				trunk.linked = null
				if(air_contents)
					pool(air_contents)
				air_contents = null
				trunk = null
		return

	proc/flushp(var/datum/mechanicsMessage/input)
		if(level == 2) return
		if(input && input.signal && ready && trunk)
			ready = 0
			for(var/atom/movable/M in src.loc)
				if(M == src || M.anchored) continue
				M.set_loc(src)
			flushit()
			spawn(20) ready = 1
		return

	proc/flushit()
		if(!trunk) return
		var/obj/disposalholder/H = new()

		H.init(src)

		air_contents.zero()

		flick("comp_flush1", src)
		sleep(10)
		playsound(src, "sound/machines/disposalflush.ogg", 50, 0, 0)

		H.start(src) // start the holder processing movement
		return

	proc/expel(var/obj/disposalholder/H)

		var/turf/target
		playsound(src, "sound/machines/hiss.ogg", 50, 0, 0)
		for(var/atom/movable/AM in H)
			target = get_offset_target_turf(src.loc, rand(5)-rand(5), rand(5)-rand(5))

			AM.set_loc(src.loc)
			AM.pipe_eject(0)
			spawn(1)
				if(AM)
					AM.throw_at(target, 5, 1)

		H.vent_gas(loc)
		qdel(H)