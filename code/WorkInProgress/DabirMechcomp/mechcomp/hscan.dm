/obj/item/mechanics/hscan
	name = "Hand scanner"
	desc = ""
	icon_state = "comp_hscan"
	var/send_name = 0
	var/ready = 1

	New()
		..()
		return

	attack_hand(mob/user as mob)
		if(level != 2 && ready)
			if(istype(user, /mob/living/carbon/human) && user.bioHolder)
				ready = 0
				spawn(30) ready = 1
				flick("comp_hscan1",src)
				playsound(src.loc, "sound/machines/twobeep2.ogg", 90, 0)
				var/sendstr = (send_name ? user.real_name : md5(user.bioHolder.Uid))
				var/datum/mechanicsMessage/msg = mechanics.newSignal(sendstr)
				mechanics.fireOutgoing(msg)
			else
				boutput(user, "<span style=\"color:red\">The hand scanner can only be used by humanoids.</span>")
				return
		else return ..(user)

	afterattack(atom/target as mob|obj|turf|area, mob/user as mob)
		if(level == 2 && get_dist(src, target) == 1)
			if(isturf(target) && target.density)
				user.drop_item()
				src.loc = target
		return

	verb/togglehssig()
		set src in view(1)
		set name = "\[Toggle Signal type\]"
		set desc = "Toggles between the different signal modes."
		set category = "Local"

		if (!istype(usr, /mob/living))
			return
		if (usr.stat)
			return
		if (!mechanics.allowChange(usr))
			boutput(usr, "<span style=\"color:red\">[MECHFAILSTRING]</span>")
			return

		send_name = !send_name
		boutput(usr, "[send_name ? "Now sending user NAME":"Now sending user FINGERPRINT"]")
		return