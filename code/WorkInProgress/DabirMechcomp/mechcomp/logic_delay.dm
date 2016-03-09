/obj/item/mechcomp/logic_delay
{
	name = "Delay component"
	desc = "Takes a signal into the buffer. Sends it after the given delay. Delay time is in seconds."
	icon_state = "comp_wait"
	var/delay = 1				// Delay in seconds.
	var/buffer = ""				// The signal being delayed.

	getReadout()
	{
		return {"<span style=\"color:blue\">Current delay: [delay] seconds<br>
		Current buffer: [html_encode(sanitize(buffer))]</span>"}
	}

	proc/input1(var/datum/mech_message/input, getName=0)
	{
		if(getName) return "Delay signal"

		if(buffer) return
		if(input)
		{
			spawn(0)
			{
				if(src)
				{
					icon_state = "[under_floor ? "u":""]comp_wait1"
					buffer = input.signal
				}
				sleep(delay * 10)									// sleep() operates in 10ths of a second.
				if(src && anchored)									// Have to still exist and be secured to forward the signal.
				{
					fireAllOutgoing(input)
					icon_state = "[under_floor ? "u":""]comp_wait"
					buffer = ""
				}
			}
		}
		return
	}

	proc/input2(var/datum/mech_message/input, getName=0)
	{
		if(getName) return "Set delay"

		var/newdelay = text2num(input.signal)
		if(newdelay)
		{
			delay = max(1, round(newdelay, 0.1)) 	// Minimum delay of 1 second, rounded to the nearest 1/10 second.
			if(announcements) componentSay("Delay set to [delay] seconds.")
		}
	}

	updateIcon()
	{
		icon_state = "[under_floor ? "u":""]comp_wait"
		return
	}
}