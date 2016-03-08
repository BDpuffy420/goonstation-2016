/obj/item/mechanics/splitter
	name = "Signal splitter component"
	desc = ""
	icon_state = "comp_split"

	get_desc()
		. += "<br><span style=\"color:blue\">Current Trigger Field: [mechanics.triggerSignal]</span>"

	New()
		..()
		mechanics.addInput("split", "split")
		return

	proc/split(var/datum/mechanicsMessage/input)
		if(level == 2) return
		var/list/converted = params2list(input.signal)
		if(converted.len)
			if(converted.Find(mechanics.triggerSignal))
				input.signal = converted[mechanics.triggerSignal]
				mechanics.fireOutgoing(input)
		return

	verb/settvalue2()
		set src in view(1)
		set name = "\[Set Trigger Field\]"
		set desc = "Sets the Trigger Field that causes this component to forward the Value of that Field."
		set category = "Local"

		if (!istype(usr, /mob/living))
			return
		if (usr.stat)
			return
		if (!mechanics.allowChange(usr))
			boutput(usr, "<span style=\"color:red\">[MECHFAILSTRING]</span>")
			return

		var/inp = input(usr,"Please enter Trigger Field:","Trigger Field setting","1") as text
		if(length(inp))
			inp = strip_html(html_decode(inp))
			mechanics.triggerSignal = inp
			boutput(usr, "Trigger Field set to [inp]")
		return

	updateIcon()
		icon_state = "[under_floor ? "u":""]comp_split"
		return