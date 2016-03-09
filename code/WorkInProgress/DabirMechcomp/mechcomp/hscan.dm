/obj/item/mechcomp/hscan
{
	name = "hand scanner"
	desc = "Sends the full name or fingerprint of anyone who touches it."
	icon_state = "comp_hscan"
	var/send_name = 0
	var/ready = 1

	getReadout()
	{
		return "<span style=\"color:blue\">The component is reporting [send_name ? "name" : "fingerprint"]s</span>"
	}

	proc/input1(var/datum/mech_message/input, getName=0)
	{
		if(getName) return "Toggle report"

		if(input)
		{
			send_name = !send_name
			if(announcements) componentSay("Now reporting [send_name ? "name" : "fingerprint"]s.")
		}
	}

	attack_hand(mob/user as mob)
	{
		if(anchored && ready)
		{
			if(istype(user, /mob/living/carbon/human) && user.bioHolder)
			{
				ready = 0
				spawn(30) ready = 1
				flick("comp_hscan1",src)
				playsound(src.loc, "sound/machines/twobeep2.ogg", 90, 0)
				var/sendstr = (send_name ? user.real_name : md5(user.bioHolder.Uid))
				var/datum/mech_message/msg = newMessage(sendstr)
				fireAllOutgoing(msg)
			}
			else
			{
				boutput(user, "<span style=\"color:red\">The hand scanner can only be used by humanoids.</span>")
				return
			}
		}
		else
		{
			return ..(user)
		}
	}

	// Added the sticker position-anywhere code to these. Will have to see how it goes.
	afterattack(atom/target as mob|obj|turf|area, mob/user as mob, reach, params)
	{
		if(!anchored && get_dist(src, target) == 1)
		{
			if(isturf(target) && target.density)
			{
				user.drop_item()
				src.loc = target
				if(params)
				{
					if (islist(params) && params["icon-y"] && params["icon-x"])
					{
						pixel_x = text2num(params["icon-x"]) - 16
						pixel_y = text2num(params["icon-y"]) - 16
					}
				}
			}
		}
		return
	}

	// Recenter graphic when picked up.
	pickup()
	{
		pixel_x = 0
		pixel_y = 0
		return ..()
	}
}