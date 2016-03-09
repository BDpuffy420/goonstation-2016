/obj/item/mechcomp/splitter
{
	name = "signal splitter component"
	desc = "Takes a signal with many fields, such as a wifi signal, and splits off one of them by name."
	icon_state = "comp_split"
	var/triggerstr = ""

	getReadout()
	{
		return "<span style=\"color:blue\">Current trigger field: \"[html_encode(sanitize(triggerstr))]\"</span>"
	}

	proc/input1(var/datum/mech_message/input, getName=0)
	{
		if(getName) return "set trigger field"

		if(input)
		{
			if(input.signal)
			{
				triggerstr = input.signal
				if(announcements) componentSay("Trigger field set to \"[triggerstr]\".")
			}
		}
	}

	proc/input2(var/datum/mech_message/input, getName=0)
	{
		if(getName) return "split signal"

		if(input)
		{
			var/list/converted = params2list(input.signal)
			if(converted.len)
			{
				if(converted.Find(triggerstr))
				{
					input.signal = converted[triggerstr]
					fireAllOutgoing(input)
				}
			}
		}
		return
	}

	updateIcon()
	{
		icon_state = "[under_floor ? "u":""]comp_split"
		return
	}
}