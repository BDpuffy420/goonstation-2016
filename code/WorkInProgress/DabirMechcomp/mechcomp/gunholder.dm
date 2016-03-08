// Updated these things for pixel bullets. Also improved user feedback and added log entries here and there (Convair880).
/obj/item/mechanics/gunholder
	name = "Gun Component"
	desc = ""
	icon_state = "comp_gun"
	density = 0
	var/obj/item/gun/Gun = null
	var/compatible_guns = /obj/item/gun/kinetic

	get_desc()
		. += "<br><span style=\"color:blue\">Current Gun: [Gun ? "[Gun] [Gun.canshoot() ? "(ready to fire)" : "(out of [istype(Gun, /obj/item/gun/energy) ? "charge)" : "ammo)"]"]" : "None"]</span>"

	New()
		..()
		mechanics.addInput("fire", "fire")
		return

	proc/getTarget()
		var/atom/trg = get_turf(src)
		for(var/mob/living/L in trg)
			return get_turf_loc(L)
		for(var/i=0, i<7, i++)
			trg = get_step(trg, src.dir)
			for(var/mob/living/L in trg)
				return get_turf_loc(L)
		return get_edge_target_turf(src, src.dir)

	proc/fire(var/datum/mechanicsMessage/input)
		if(level == 2) return
		if(input && Gun)
			if(Gun.canshoot())
				var/atom/target = getTarget()
				if(target)
					//DEBUG("Target: [log_loc(target)]. Src: [src]")
					Gun.shoot(target, get_turf(src), src)
			else
				src.visible_message("<span class='game say'><span class='name'>[src]</span> beeps, \"The [Gun.name] has no [istype(Gun, /obj/item/gun/energy) ? "charge" : "ammo"] remaining.\"</span>")
				playsound(src.loc, "sound/machines/buzz-two.ogg", 50, 0)
		else
			src.visible_message("<span class='game say'><span class='name'>[src]</span> beeps, \"No gun installed.\"</span>")
			playsound(src.loc, "sound/machines/buzz-two.ogg", 50, 0)
		return

	attackby(obj/item/W as obj, mob/user as mob)
		if(..(W, user)) return
		else if (istype(W, src.compatible_guns))
			if(!Gun)
				boutput(usr, "You put the [W] inside the [src].")
				logTheThing("station", usr, null, "adds [W] to [src] at [log_loc(src)].")
				usr.drop_item()
				Gun = W
				Gun.loc = src
			else
				boutput(usr, "There is already a [Gun] inside the [src]")
		else
			user.show_text("The [W.name] isn't compatible with this component.", "red")
		return

	updateIcon()
		icon_state = "comp_gun"
		return

	verb/removegun()
		set src in view(1)
		set name = "\[Remove Gun\]"
		set desc = "Removes the gun."
		set category = "Local"

		if (!istype(usr, /mob/living))
			return
		if (usr.stat)
			return
		if (!mechanics.allowChange(usr))
			boutput(usr, "<span style=\"color:red\">[MECHFAILSTRING]</span>")
			return

		if(Gun)
			logTheThing("station", usr, null, "removes [Gun] from [src] at [log_loc(src)].")
			Gun.loc = get_turf(src)
			Gun = null
		else
			boutput(usr, "<span style=\"color:red\">There is no gun inside this component.</span>")
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

/obj/item/mechanics/gunholder/recharging
	name = "E-Gun Component"
	desc = ""
	icon_state = "comp_gun2"
	density = 0
	compatible_guns = /obj/item/gun/energy
	var/charging = 0
	var/ready = 1

	get_desc()
		. = ..() // Please don't remove this again, thanks.
		. += charging ? "<br><span style=\"color:blue\">Component is charging.</span>" : null

	New()
		..()
		mechanics.addInput("recharge", "recharge")
		return

	process()
		..()
		if(level == 2)
			if(charging) charging = 0
			return

		if(!Gun && charging)
			charging = 0
			updateIcon()

		if(!istype(Gun, /obj/item/gun/energy) || !charging)
			return

		var/obj/item/gun/energy/E = Gun

		// Can't recharge the crossbow. Same as the other recharger.
		if (!E.rechargeable)
			src.visible_message("<span class='game say'><span class='name'>[src]</span> beeps, \"This gun cannot be recharged manually.\"</span>")
			playsound(src.loc, "sound/machines/buzz-two.ogg", 50, 0)
			charging = 0
			updateIcon()
			return

		if (E.cell)
			if (E.cell.charge(15) != 1) // Same as other recharger.
				src.charging = 0
				src.updateIcon()

		E.update_icon()
		return

	proc/recharge(var/datum/mechanicsMessage/input)
		if(charging || !Gun || level == 2) return
		if(!istype(Gun, /obj/item/gun/energy)) return
		charging = 1
		updateIcon()
		return ..()

	fire(var/datum/mechanicsMessage/input)
		if(charging || !ready) return
		ready = 0
		spawn(30) ready = 1
		return ..()

	updateIcon()
		icon_state = charging ? "comp_gun2x" : "comp_gun2"
		return