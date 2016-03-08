/obj/item/mechanics/selector
	name = "Selection Component"
	desc = ""
	icon_state = "comp_selector"
	var/list/signals = new/list()
	var/current_index = 1
	var/announce = 0
	var/random = 0

	get_desc()
		. += {"<br><span style=\"color:blue\">[random ? "Sending random Signals.":"Sending selected Signals."]<br>
		[announce ? "Announcing Changes.":"Not announcing Changes."]<br>
		Current Selection: [(!current_index || current_index > signals.len ||!signals.len) ? "Empty":"[current_index] -> [signals[current_index]]"]<br>
		Currently contains [signals.len] Items:<br></span>"}
		for (var/x in signals)
			. += "- [x]<br>[(signals[signals.len] == x) ? "</span>" : null]"

	New()
		..()
		mechanics.addInput("add item", "additem")
		mechanics.addInput("remove item", "remitem")
		mechanics.addInput("remove all items", "remallitem")
		mechanics.addInput("select item", "selitem")
		mechanics.addInput("next", "next")
		mechanics.addInput("previous", "previous")
		mechanics.addInput("next + send", "nextplus")
		mechanics.addInput("previous + send", "previousplus")
		mechanics.addInput("send selected", "sendCurrent")
		mechanics.addInput("send random", "sendRand")
		verbs -= /obj/item/mechanics/verb/setvalue
		return

	proc/selitem(var/datum/mechanicsMessage/input)
		if(!input) return

		if(signals.Find(input.signal))
			current_index = signals.Find(input.signal)

		if(announce)
			componentSay("Current Selection : [signals[current_index]]")
		return

	proc/remitem(var/datum/mechanicsMessage/input)
		if(!input) return

		if(signals.Find(input.signal))
			signals.Remove(input.signal)
			if(announce)
				componentSay("Removed : [input.signal]")

		return

	proc/remallitem(var/datum/mechanicsMessage/input)
		if(!input) return

		for(var/s in signals)
			signals.Remove(s)

		if(announce)
			componentSay("Removed all signals.")

		return

	proc/additem(var/datum/mechanicsMessage/input)
		if(!input) return

		signals.Add(input.signal)
		if(announce)
			componentSay("Added : [input.signal]")

		return

	proc/sendRand(var/datum/mechanicsMessage/input)
		if(!input) return
		//I feel bad for doing this.
		var/orig = random
		random = 1
		sendCurrent(input)
		random = orig
		return

	proc/sendCurrent(var/datum/mechanicsMessage/input)
		if(!input) return
		if(!current_index || current_index > signals.len ||!signals.len) return

		if(random) input.signal = pick(signals)
		else input.signal = signals[current_index]

		spawn(0)
			mechanics.fireOutgoing(input)
		return

	proc/next(var/datum/mechanicsMessage/input)
		if(level == 2) return
		if(!signals.len) return
		if((current_index + 1) > signals.len)
			current_index = 1
		else
			current_index++

		if(announce)
			componentSay("Current Selection : [signals[current_index]]")
		return

	proc/nextplus(var/datum/mechanicsMessage/input)
		if(level == 2) return
		if(!signals.len) return
		if((current_index + 1) > signals.len)
			current_index = 1
		else
			current_index++

		if(announce)
			componentSay("Current Selection : [signals[current_index]]")

		sendCurrent(input)
		return

	proc/previous(var/datum/mechanicsMessage/input)
		if(level == 2) return
		if(!signals.len) return
		if((current_index - 1) < 1)
			current_index = signals.len
		else
			current_index--

		if(announce)
			componentSay("Current Selection : [signals[current_index]]")
		return

	proc/previousplus(var/datum/mechanicsMessage/input)
		if(level == 2) return
		if(!signals.len) return
		if((current_index - 1) < 1)
			current_index = signals.len
		else
			current_index--

		if(announce)
			componentSay("Current Selection : [signals[current_index]]")

		sendCurrent(input)
		return

	verb/setsignals()
		set src in view(1)
		set name = "\[Set Signal List\]"
		set desc = "Defines the List of Signals to be used by this Component."
		set category = "Local"

		if (!istype(usr, /mob/living))
			return
		if (usr.stat)
			return
		if (!mechanics.allowChange(usr))
			boutput(usr, "<span style=\"color:red\">[MECHFAILSTRING]</span>")
			return

		var/numsig = input(usr,"How many Signals would you like to define?","# Signals:", 3) as num
		numsig = round(numsig)
		if(numsig > 10) //Needs a limit because nerds are nerds
			boutput(usr, "<span style=\"color:red\">This component can't handle more than 10 signals!</span>")
			return
		if(numsig)
			signals.Cut()
			boutput(usr, "Defining [numsig] Signals ...")
			for(var/i=0, i<numsig, i++)
				var/signew = input(usr,"Content of Signal #[i]","Content:", "signal[i]") as text
				signew = adminscrub(signew) //SANITIZE THAT SHIT! FUCK!!!!
				if(length(signew))
					signals.Add(signew)
				else
					signals.Cut()
					return
			boutput(usr, "Set [numsig] Signals!")
			for(var/a in signals)
				boutput(usr, a)
		return

	verb/toggleannouncement()
		set src in view(1)
		set name = "\[Toggle Announcements\]"
		set desc = "Toggles wether the Component will say its selected item out loud or not."
		set category = "Local"

		if (!istype(usr, /mob/living))
			return
		if (usr.stat)
			return
		if (!mechanics.allowChange(usr))
			boutput(usr, "<span style=\"color:red\">[MECHFAILSTRING]</span>")
			return

		announce = !announce
		boutput(usr, "Announcements now [announce ? "on":"off"]")
		return

	verb/togglerndsel()
		set src in view(1)
		set name = "\[Toggle random\]"
		set desc = "Toggles whether the Component will pick an Item at random or not."
		set category = "Local"

		if (!istype(usr, /mob/living))
			return
		if (usr.stat)
			return
		if (!mechanics.allowChange(usr))
			boutput(usr, "<span style=\"color:red\">[MECHFAILSTRING]</span>")
			return

		random = !random
		boutput(usr, "[random ? "Now picking Items at random.":"Now using selected Items."]")
		return

	updateIcon()
		icon_state = "[under_floor ? "u":""]comp_selector"
		return