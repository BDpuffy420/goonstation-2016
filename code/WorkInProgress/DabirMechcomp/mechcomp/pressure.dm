/obj/item/mechcomp/pressure
	name = "pressure pad component"
	desc = "Sends a preset signal when stepped on. Requires 1 second to recharge between messages."
	icon_state = "comp_pressure"
	var/output = ""
	var/ready = 1

	getReadout()
	{
		return {"<br><span style=\"color:blue\">Output signal: \"[html_encode(sanitize(output))]\"<br>
		The pressure pad is [ready ? "ready" : "recharging"]</span>"}
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

	Crossed(atom/movable/AM as mob|obj)
	{
		if (anchored && ready && !istype(AM, /mob/dead))
		{
			spawn(10) ready = 1
			fireAllOutgoing(newMessage(output))
		}
		return
	}

	updateIcon()
	{
		icon_state = "[under_floor ? "u":""]comp_pressure"
		return
	}