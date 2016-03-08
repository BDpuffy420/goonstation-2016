/obj/item/mechanics/printer
	name = "Thermal printer"
	desc = ""
	icon_state = "comp_tprint"
	var/ready = 1
	var/paper_name = "thermal paper"

	New()
		..()
		mechanics.addInput("print", "print")
		return

	proc/print(var/datum/mechanicsMessage/input)
		if(level == 2 || !ready) return
		if(input)
			ready = 0
			spawn(50) ready = 1
			flick("comp_tprint1",src)
			playsound(src.loc, "sound/machines/printer_thermal.ogg", 60, 0)
			var/obj/item/paper/thermal/P = new/obj/item/paper/thermal(src.loc)
			P.info = strip_html(html_decode(input.signal))
			P.name = paper_name
		return

	afterattack(atom/target as mob|obj|turf|area, mob/user as mob)
		if(level == 2 && get_dist(src, target) == 1)
			if(isturf(target) && target.density)
				user.drop_item()
				src.loc = target
		return

	verb/setthprintstr()
		set src in view(1)
		set name = "\[Set paper name\]"
		set desc = "Sets the name of the printed paper."
		set category = "Local"

		if (!istype(usr, /mob/living))
			return
		if (usr.stat)
			return
		if (!mechanics.allowChange(usr))
			boutput(usr, "<span style=\"color:red\">[MECHFAILSTRING]</span>")
			return

		var/inp = input(usr,"Please enter name:","name setting", paper_name) as text
		paper_name = adminscrub(inp)
		boutput(usr, "String set to [paper_name]")
		return