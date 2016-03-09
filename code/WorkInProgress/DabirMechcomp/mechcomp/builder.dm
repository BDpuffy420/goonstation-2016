//Big changes from old version.
//Removed add to buffer + send, easy enough to accomplish with one extra component. Can be readded later if necessary.
//Added inputs to set start and end strings.
//Sending no longer clears the buffer. Also easy enough to do with another component.

/obj/item/mechcomp/builder
{
	name = "signal builder component"
	desc = "Strings sent to this component accumulate in its buffer and may be sent as one string, along with an optional start and end string."
	icon_state = "comp_builder"
	var/startstr = ""
	var/buffer = ""
	var/endstr = ""

	getReadout()
	{
		return {"<span style=\"color:blue\">Starting string: \"[html_encode(sanitize(startstr))]\"<br>
		Current buffer contents: \"[html_encode(sanitize(buffer))]\"<br>
		Ending string: \"[html_encode(sanitize(endstr))]\"</span>"}
	}

	proc/input1(var/datum/mech_message/input, getName=0)
	{
		if(getName) return "Set start string"

		if(input)
		{
			startstr = input.signal
			if(announcements) componentSay("Start string set to [startstr].")
		}
	}

	proc/input2(var/datum/mech_message/input, getName=0)
	{
		if(getName) return "Set end string"

		if(input)
		{
			endstr = input.signal
			if(announcements) componentSay("End string set to [endstr].")
		}
	}

	proc/input3(var/datum/mech_message/input, getName=0)
	{
		if(getName) return "Add to buffer"

		if(input)
		{
			buffer += input.signal
		}
	}

	proc/input4(var/datum/mech_message/input, getName=0)
	{
		if(getName) return "Send assembled string"

		if(input)
		{
			fireAllOutgoing(newMessage(startstr + buffer + endstr))
		}
	}

	proc/input5(var/datum/mech_message/input, getName=0)
	{
		if(getName) return "Clear buffer"

		if(input)
		{
			buffer = ""
		}
	}

	updateIcon()
	{
		icon_state = "[under_floor ? "u":""]comp_builder"
		return
	}
}