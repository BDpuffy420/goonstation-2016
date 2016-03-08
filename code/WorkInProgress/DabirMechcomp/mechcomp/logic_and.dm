/obj/item/mechcomp/logic_and
{
	name = "logical AND component"
	desc = "When this component receives two signals within a given time of each other, it forwards the second one. Timeframe is measured in seconds."
	icon_state = "comp_and"
	var/timeframe = 3
	var/primed = 0				// Tracks whether a message has been received within the last timeframe.
	var/times_fired = 0			// Need to track this to prevent one firing from unpriming a later one.

	getReadout()
	{
		return {"<br><span style=\"color:blue\">Current Time Frame: [timeframe]
		<br></span>"}
	}

	proc/input1(var/datum/mech_message/input, getName=0)
	{
		if(getName) return "Input"

		if(input)
		{
			if(primed == 1)
			{
				primed = 0
				fireAllOutgoing(input)
				times_fired++
			}
			else
			{
				primed = 1
				var/i = times_fired					// Number of times fired at the time that spawn was called.
				spawn(timeframe * 10)
				{
					if(i == times_fired)				// Only reset if the component hasn't fired since spawn() was called.
					{
						primed = 0
					}
				}
			}
		}
	}

	proc/input2(var/datum/mech_message/input, getName=0)
	{
		if(getName) return "Set timeframe"

		if(isnum(input.signal))
		{
			timeframe = max(1, round(input.signal, 0.1)) 	// Minimum timeframe of 1 second, rounded to the nearest 1/10 second.
			if(announcements) componentSay("Timeframe set to [timeframe] seconds.")
		}
	}

	updateIcon()
		icon_state = "[under_floor ? "u":""]comp_and"
		return
}