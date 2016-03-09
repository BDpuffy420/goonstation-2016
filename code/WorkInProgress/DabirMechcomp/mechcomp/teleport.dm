/obj/item/mechcomp/teleport
{
	name = "teleport component"
	desc = "Teleports anything on it to another teleporter with the same ID. Can be set to prevent receiving. Requires 3 seconds of cooldown between uses."
	icon_state = "comp_tele"
	var/ready = 1
	var/teleID = "tele1"
	var/incoming = 1

	New()
	{
		..()
		mechcomp_telepads.Add(src)
		return
	}

	getReadout()
	{
		return {"<span style=\"color:blue\">Current ID: \"[html_encode(sanitize(teleID))]\"<br>
		Incoming teleports are [incoming ? "allowed":"prevented"]</span>"}
	}

	proc/input1(var/datum/mech_message/input, getName=0)
	{
		if(getName) return "Set teleporter ID"

		if(input.signal)
		{
			teleID = input.signal
			if(announcements) componentSay("Teleporter ID changed to \"[teleID]\"")
		}
		return
	}

	proc/input2(var/datum/mech_message/input, getName=0)
	{
		if(getName) return "Toggle incoming teleports"

		if(input)
		{
			incoming = !incoming

			if(incoming)
			{
				src.overlays += image('icons/misc/mechanicsExpansion.dmi', icon_state = "comp_teleoverlay")
			}
			else
			{
				src.overlays.Cut()
			}
			if(announcements) componentSay("Now [incoming ? "allowing" : "preventing"]")
		}

	}

	proc/input3(var/datum/mech_message/input, getName=0)
	{
		if(getName) return "Teleport"

		if(ready)
		{
			ready = 0
			spawn(30) ready = 1

			flick("[under_floor ? "u":""]comp_tele1", src)

			particleMaster.SpawnSystem(new /datum/particleSystem/tpbeam(get_turf(src.loc)))
			playsound(src.loc, "sound/mksounds/boost.ogg", 50, 1)

			var/list/destinations = new/list()

			for(var/obj/item/mechcomp/teleport/T in mechcomp_telepads)
			{
				if(T != src && T.anchored && isturf(T.loc) && T.z == src.z && !isrestrictedz(T.z) && T.incoming && T.teleID == src.teleID)
				{
					destinations.Add(T)
				}
			}

			if(destinations.len)
			{
				var/atom/picked = pick(destinations)
				particleMaster.SpawnSystem(new /datum/particleSystem/tpbeam(get_turf(picked.loc)))
				for(var/atom/movable/M in src.loc)
				{
					if(M == src || M.invisibility || M.anchored) continue
					M.set_loc(get_turf(picked.loc))
				}
			}
		}
	//	spawn(0)
	//		mechanics.fireOutgoing(input)
	}

	Del()
	{
		mechcomp_telepads.Remove(src)
		return ..()
	}

	updateIcon()
	{
		icon_state = "[under_floor ? "u":""]comp_tele"
		return
	}

	verb/togglesendonly()
		set src in view(1)
		set name = "\[Toggle Send-only Mode\]"
		set desc = "Toggles Send-only Mode."
		set category = "Local"

		if (!istype(usr, /mob/living))
			return
		if (usr.stat)
			return
		if (!mechanics.allowChange(usr))
			boutput(usr, "<span style=\"color:red\">[MECHFAILSTRING]</span>")
			return

		incoming = !incoming

		if(incoming)
			src.overlays += image('icons/misc/mechanicsExpansion.dmi', icon_state = "comp_teleoverlay")
		else
			src.overlays.Cut()

		boutput(usr, "Send-only Mode now [incoming ? "on":"off"]")
		return
}