/obj/item/mechanics/accelerator
	name = "Graviton accelerator"
	desc = ""
	icon_state = "comp_accel"
	var/active = 0

	New()
		..()
		mechanics.addInput("activate", "activateproc")
		return

	proc/drivecurrent()
		if(level == 2) return
		var/count = 0
		for(var/atom/movable/M in src.loc)
			if(M.anchored) continue
			count++
			if(M == src) continue
			throwstuff(M)
			if(count > 50) return

	proc/activateproc(var/datum/mechanicsMessage/input)
		if(level == 2) return
		if(input)
			if(active) return
			particleMaster.SpawnSystem(new /datum/particleSystem/gravaccel(src.loc, src.dir))
			spawn(0)
				if(src)
					icon_state = "[under_floor ? "u":""]comp_accel1"
					active = 1
					spawn(0) drivecurrent()
					spawn(5) drivecurrent()
				sleep(30)
				if(src)
					icon_state = "[under_floor ? "u":""]comp_accel"
					active = 0
		return

	proc/throwstuff(atom/movable/AM as mob|obj)
		if(level == 2 || AM.anchored || AM == src) return
		if(AM.throwing) return
		var/atom/target = get_edge_target_turf(AM, src.dir)
		spawn(0) AM.throw_at(target, 50, 1)
		return

	HasEntered(atom/movable/AM as mob|obj)
		if(level == 2) return
		if(active)
			throwstuff(AM)
		return

	verb/setdir()
		set src in view(1)
		set name = "\[Rotate\]"
		set desc = "Rotates the object"
		set category = "Local"
		if (usr.stat)
			return
		src.dir = turn(src.dir, 90)
		return

	updateIcon()
		icon_state = "[under_floor ? "u":""]comp_accel"
		return