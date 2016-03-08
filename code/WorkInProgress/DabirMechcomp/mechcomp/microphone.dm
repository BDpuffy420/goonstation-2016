/obj/item/mechcomp/microphone
{
	name = "microphone component"
	desc = ""
	icon_state = "comp_mic"
	var/names = 0

	getReadout()
	{
		return "<span style=\"color:blue\">[names ? "I" : "Not i"]ncluding names of speakers in signals.</span>"
	}

	proc/input1(var/datum/mech_message/input, getName=0)
	{
		if(getName) return "Toggle names"

		names = !names
		if(announcements)
		{
			componentSay("Now [names ? "" : "not "]including speaker names.")
		}
	}

	hear_talk(mob/M as mob, msg, real_name, lang_id)
	{
		var/message = msg[2]
		if(lang_id in list("english", ""))
		{
			message = msg[1]
		}
		message = strip_html( html_decode(message) )
		var/heardname = M.name
		if (real_name)
		{
			heardname = real_name
		}

		var/datum/mech_message/sigmsg = newMessage((names ? "[heardname] : " : "") + message)
		fireAllOutgoing(sigmsg)
		animate_flash_color_fill(src,"#00FF00",2, 2)
		return
	}

	updateIcon()
	{
		icon_state = "[under_floor ? "u":""]comp_mic"
		return
	}
}