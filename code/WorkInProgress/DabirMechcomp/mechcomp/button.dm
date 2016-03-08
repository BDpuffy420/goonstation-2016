/obj/item/mechcomp/button
{
	name = "Button"
	desc = ""
	icon_state = "comp_button"
	density = 1
	var/output = "1"

	getReadout()
	{
		return "<br><span style=\"color:blue\">Output signal: \"[html_encode(sanitize(output))]\".</span>"
	}

	proc/input1(var/datum/mech_message/input, getName=0)
	{
		if(getName) return "Set output"

		if(input)
		{
			output = input.signal
			if(announcements) componentSay("Output signal set to \"[output]\".")
		}
	}

	attack_hand(mob/user as mob)
	{
		if(anchored)
		{
			flick("comp_button1", src)
			fireAllOutgoing(newMessage(output))
		}
		else
		{
			..(user)
		}
		return
	}

	attackby(obj/item/W as obj, mob/user as mob)
	{
		if(..(W, user)) return
		attack_hand(user)
		return
	}

	updateIcon()
	{
		icon_state = "comp_button"
		return
	}
}