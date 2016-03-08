/obj/item/mechcomp/teleport
{
	name = "teleport component"
	desc = "Teleports anything on it to another teleporter with the same ID. Can be set to prevent receiving."
	icon_state = "comp_tele"
	var/ready = 1
	var/teleID = "tele1"
	var/send_only = 0

	getReadout()
	{
		return {"<br><span style=\"color:blue\">Current ID: [teleID].
		<br>Send only Mode: [send_only ? "On":"Off"].</span>"}
	}

	New()
		..()
		mechcomp_telepads.Add(src)
		return

	proc/input(var/datum/mechanicsMessage/input, getName=0)
	{
		if(getName) return "Set teleporter ID"
		if(level == 2) return
		if(input.signal)
			teleID = input.signal
 		componentSay("ID Changed to : [input.signal]")
		return
	}

	proc/activate(var/datum/mechanicsMessage/input)
		if(level == 2 || !ready) return
		ready = 0
		spawn(30) ready = 1
		flick("[under_floor ? "u":""]comp_tele1", src)
		particleMaster.SpawnSystem(new /datum/particleSystem/tpbeam(get_turf(src.loc)))
		playsound(src.loc, "sound/mksounds/boost.ogg", 50, 1)
		var/list/destinations = new/list()

		for(var/obj/item/mechanics/telecomp/T in mechanics_telepads)
			if(T == src || T.level == 2 || !isturf(T.loc) || T.z != src.z  || isrestrictedz(T.z)|| T.send_only) continue
			if(T.teleID == src.teleID)
				destinations.Add(T)

		if(destinations.len)
			var/atom/picked = pick(destinations)
			particleMaster.SpawnSystem(new /datum/particleSystem/tpbeam(get_turf(picked.loc)))
			for(var/atom/movable/M in src.loc)
				if(M == src || M.invisibility || M.anchored) continue
				M.set_loc(get_turf(picked.loc))

		spawn(0)
			mechanics.fireOutgoing(input)
		return

	Del()
		mechanics_telepads.Remove(src)
		return ..()

	updateIcon()
		icon_state = "[under_floor ? "u":""]comp_tele"
		return

	verb/setid()
		set src in view(1)
		set name = "\[Set Teleporter ID\]"
		set desc = "Sets the ID of the Telepad."
		set category = "Local"

		if (!istype(usr, /mob/living))
			return
		if (usr.stat)
			return
		if (!mechanics.allowChange(usr))
			boutput(usr, "<span style=\"color:red\">[MECHFAILSTRING]</span>")
			return

		var/inp = input(usr,"Please enter ID:","ID setting",teleID) as text
		if(length(inp))
			inp = adminscrub(inp)
			teleID = inp
			boutput(usr, "ID set to [inp]")

		return

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

		send_only = !send_only

		if(send_only)
			src.overlays += image('icons/misc/mechanicsExpansion.dmi', icon_state = "comp_teleoverlay")
		else
			src.overlays.Cut()

		boutput(usr, "Send-only Mode now [send_only ? "on":"off"]")
		return
}