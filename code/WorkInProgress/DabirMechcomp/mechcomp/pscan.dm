/obj/item/mechanics/pscan
	name = "Paper scanner"
	desc = ""
	icon_state = "comp_pscan"
	var/del_paper = 1
	var/thermal_only = 1
	var/ready = 1

	New()
		..()
		return

	afterattack(atom/target as mob|obj|turf|area, mob/user as mob)
		if(level == 2 && get_dist(src, target) == 1)
			if(isturf(target) && target.density)
				user.drop_item()
				src.loc = target
		return

	attackby(obj/item/W as obj, mob/user as mob)
		if(..(W, user)) return
		else if (istype(W, /obj/item/paper) && ready)
			if(thermal_only && !istype(W, /obj/item/paper/thermal))
				boutput(user, "<span style=\"color:red\">This scanner only accepts thermal paper.</span>")
				return
			ready = 0
			spawn(30) ready = 1
			flick("comp_pscan1",src)
			playsound(src.loc, "sound/machines/twobeep2.ogg", 90, 0)
			var/obj/item/paper/P = W
			var/saniStr = strip_html(sanitize(html_encode(P.info)))
			var/datum/mechanicsMessage/msg = mechanics.newSignal(saniStr)
			mechanics.fireOutgoing(msg)
			if(del_paper)
				del(W)
		return

	verb/togglepsdel()
		set src in view(1)
		set name = "\[Toggle Paper consumption\]"
		set desc = "Sets whether the scanner consumes the paper used on it or not."
		set category = "Local"

		if (!istype(usr, /mob/living))
			return
		if (usr.stat)
			return
		if (!mechanics.allowChange(usr))
			boutput(usr, "<span style=\"color:red\">[MECHFAILSTRING]</span>")
			return

		del_paper = !del_paper
		boutput(usr, "[del_paper ? "Now consuming paper":"Now NOT consuming paper"]")
		return

	verb/togglepstherm()
		set src in view(1)
		set name = "\[Toggle thermal paper mode\]"
		set desc = "Sets whether the scanner only accepts thermal paper or not."
		set category = "Local"

		if (!istype(usr, /mob/living))
			return
		if (usr.stat)
			return
		if (!mechanics.allowChange(usr))
			boutput(usr, "<span style=\"color:red\">[MECHFAILSTRING]</span>")
			return

		thermal_only = !thermal_only
		boutput(usr, "[thermal_only ? "Now accepting only thermal paper":"Now accepting any paper"]")
		return