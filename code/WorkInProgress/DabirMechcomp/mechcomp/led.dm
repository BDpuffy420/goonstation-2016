/obj/item/mechcomp/led
	name = "light-emitting diode component"
	desc = ""
	icon_state = "comp_led"
	var/light_level = 2
	var/active = 0
	var/selcolor = "#FFFFFF"
	var/datum/light/light
	color = "#AAAAAA"

	get_desc()
		. += "<br><span style=\"color:blue\">Current Color: [selcolor].</span>"

	New()
		..()
		mechanics.addInput("toggle", "toggle")
		mechanics.addInput("activate", "turnon")
		mechanics.addInput("deactivate", "turnoff")
		mechanics.addInput("set rgb", "setrgb")
		verbs -= /obj/item/mechanics/verb/setvalue
		light = new /datum/light/point
		light.attach(src)
		return

	pickup()
		active = 0
		light.disable()
		src.color = "#AAAAAA"
		return ..()

	proc/setrgb(var/datum/mechanicsMessage/input)

		if(length(input.signal) == 7 && copytext(input.signal, 1, 2) == "#")
			if(active)
				color = input.signal
			selcolor = input.signal
			spawn(0) light.set_color(GetRedPart(selcolor) / 255, GetGreenPart(selcolor) / 255, GetBluePart(selcolor) / 255)

	proc/turnon(var/datum/mechanicsMessage/input)
		if(level == 2) return
		if (usr && usr.stat)
			return
		active = 1
		light.enable()
		src.color = selcolor
		return

	proc/turnoff(var/datum/mechanicsMessage/input)
		if(level == 2) return
		if (usr && usr.stat)
			return
		active = 0
		light.disable()
		src.color = "#AAAAAA"
		return

	proc/toggle(var/datum/mechanicsMessage/input)
		if(level == 2) return
		if (usr && usr.stat)
			return
		if(active)
			turnoff(input)
		else
			turnon(input)
		return

	verb/setcolor()
		set src in view(1)
		set name = "\[Set Color\]"
		set desc = "Sets the color of the light."
		set category = "Local"

		if (!istype(usr, /mob/living))
			return
		if (usr.stat)
			return
		if (!mechanics.allowChange(usr))
			boutput(usr, "<span style=\"color:red\">[MECHFAILSTRING]</span>")
			return

		var/red = input(usr,"Red Color (0.0 - 1.0):","Color setting", 1.0) as num
		red = max(red, 0.0)
		red = min(red, 1.0)

		var/green = input(usr,"Green Color (0.0 - 1.0):","Color setting", 1.0) as num
		green = max(green, 0.0)
		green = min(green, 1.0)

		var/blue = input(usr,"Blue Color (0.0 - 1.0):","Color setting", 1.0) as num
		blue = max(blue, 0.0)
		blue = min(blue, 1.0)

		selcolor = rgb(red * 255, green * 255, blue * 255)

		light.set_color(red, green, blue)

		return

	verb/setrange()
		set src in view(1)
		set name = "\[Set Range\]"
		set desc = "Sets the range of the light."
		set category = "Local"

		if (!istype(usr, /mob/living))
			return
		if (usr.stat)
			return
		if (!mechanics.allowChange(usr))
			boutput(usr, "<span style=\"color:red\">[MECHFAILSTRING]</span>")
			return

		var/inp = input(usr,"Please enter Range (1 - 7):","Range setting", light_level) as num
		if (get_dist(usr, src) > 1 || usr.stat)
			return

		inp = round(inp)
		inp = max(inp, 1)
		inp = min(inp, 7)

		boutput(usr, "Range set to [inp]")

		light.set_brightness(inp / 7)

		return

	updateIcon()
		icon_state = "[under_floor ? "u":""]comp_led"
		return