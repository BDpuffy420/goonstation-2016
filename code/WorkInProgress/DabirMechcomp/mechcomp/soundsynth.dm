/obj/item/mechcomp/soundsynth
{
	name = "sound synthesizer component"
	desc = "Takes a text string and speaks it. Requires 2 seconds to recharge between uses."
	icon_state = "comp_synth"
	var/ready = 1

	getReadout()
	{
		return "<span style=\"color:blue\">The synthesizer is [ready ? "ready to speak" : "recharging"]</span>"
	}

	proc/input1(var/datum/mech_message/input, getName=0)
	{
		if(getName) return "Speak"

		if(ready && input)
		{
			ready = 0
			componentSay(input.signal)
			spawn(20) ready = 1
		}
		return
	}

	updateIcon()
	{
		icon_state = "comp_synth"
		return
	}
}