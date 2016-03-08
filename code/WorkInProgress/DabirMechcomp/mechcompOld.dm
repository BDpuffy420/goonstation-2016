//TODO:
// - Stun and ghost checks for the verbs
// - Buttons can be picked up with the hands full. Woops.
// - Message Datum pooling and recycling.

//Important Notes:
//
//Please try to always re-use incoming signals for your outgoing signals.
//Just modify the message of the incoming signal and send it along.
//This is important because each message keeps track of which nodes it traveled trough.
//It's through that list that we can prevent infinite loops. Or at least try to.
//(People can probably still create infinite loops somehow. They always manage)
//Always use the newSignal proc of the mechanics holder of the sending object when creating a new message.

#define MECHFAILSTRING "<span style=\"color:red\">You must be holding a Multitool to change Connections or Options.</span>"
#define MECHLOOPSTRING "<span style=\"color:red\">You cannot create a direct loop between 2 components.</span>"
#define MECHDUPESTRING "<span style=\"color:red\">You cannot create multiple connections between the same components.</span>"
#define MECHNOINPUTSTRING "<span style=\"color:red\">[O] has no input slots. Can not connect [master] as Trigger.</span>"
#define MECHTOOBIGSTRING "<span style=\"color:red\">[src] is a little too big for that tool.</span>"
#define MECHTOOSMALLSTRING "<span style=\"color:red\">[src] is a little too small for that tool.</span>"

//Global list of telepads so we don't have to loop through the entire world aaaahhh.
var/list/mechcomp_telepads = new/list()

/datum/mechcompMessage
{
	//Contents of the message.
	var/signal = "1"

	//List of nodes through which the signal has passed, for infinite loop prevention.
	var/list/nodes = list()

	proc/addNode(obj/item/mechcomp/H)
	{
		nodes.Add(H)
	}

	proc/removeNode(obj/item/mechcomp/H)
	{
		nodes.Remove(H)
	}

	proc/hasNode(obj/item/mechcomp/H)
	{
		return nodes.Find(H)
	}

	proc/isTrue() //Thanks for not having bools, byond.
	{
		if (isnum(signal) && signal == 1)
		{
			return 1
		}

		else if(istext(signal))
		{
			if(lowertext(signal) == "true" || lowertext(signal) == "1" || lowertext(signal) == "one")
			{
				return 1
			}
		}

		else
		{
			return 0
		}
	}
}

/obj/item/mechcomp
{
	name = "MechComp base item"
	icon = 'icons/misc/mechanicsExpansion.dmi'
	icon_state = "comp_unk"
	item_state = "swat_suit"

	//Physical vars
	anchored = 0
	flags = FPRINT | EXTRADELAY | TABLEPASS | CONDUCT
	w_class = 1.0
	var/under_floor = 0
	var/list/particles = new/list()

	//Signal vars
	var/list/connections_in = list()
	var/list/connections_out = list()
	var/signal_output = "1"
	var/signal_trigger = "1"

	New()
	{
		if (!(src in processing_items))
		{
			processing_items.Add(src)
		}
		return ..()
	}

	process()
	{
		//Removes particles if is currently under the floor or not unsecured.
		if(!anchored || under_floor)
		{
			cutParticles()
			return
		}

		//Otherwise updates the particles.
		else if(particles.len != connections_out.len)
		{
			cutParticles()
			for(var/atom/X in connections_out)
				particles.Add(particleMaster.SpawnSystem(new /datum/particleSystem/mechanic(src.loc, X.loc)))
		}
		return
	}

	//Input procs
	proc/inputToggleAnnouncement(var/datum/mechanicsMessage/input)
	{
		var/announcements = !variables["Announcement"]
		variables["Announcement"] = !variables["Announcement"]
		componentSay("Announcements now turned [announcements ? on : off]")
	}

	//Signal procs

	//ALWAYS use this to create new messages!!!
	proc/newSignal(var/sig)
	{
		var/datum/mechcompMessage/message = new/datum/mechcompMessage
		message.signal = sig
		return message
	}

	//Used to copy a message because we don't want to pass a single message to multiple components which might end up modifying it both at the same time.
	proc/cloneMessage(var/datum/mechcompMessage/msg)
	{
		var/datum/mechcompMessage/msg2 = newSignal(msg.signal)
		msg2.nodes = msg.nodes.Copy()
		return msg2
	}

	//Brings up a prompt to choose an input from the object's list
	proc/chooseInput()
	{
		return input(usr, "Select \"[src]\" Input", "Input Selection") in inputs + "*CANCEL*"
	}

	//Fire given input by name with the message as an argument.
	//All input procs should be formatted as 'inputDoThis'
	proc/fireInput(var/input_name, var/datum/mechcompMessage/msg)
	{
		input_name = "input" + name
		if (hascall(src, input_name))
		{
			spawn(1) call(input_name)(msg)
			return 1
		}
		return 0
	}

	//Fire an outgoing connection with given value. Try to re-use incoming messages for outgoing signals whenever possible!
	//This reduces load AND preserves the node list which prevents infinite loops.
	proc/fireOutgoing(var/datum/mechcompMessage/msg)
	{
		//If we're already in the node list we will not send the signal on.
		if(!msg.hasNode(src))
		{
			msg.addNode(src)
		}
		else
		{
			return
		}

		for(var/atom/M in connections_out)
			if(istype(M, /obj/item/mechcomp))
				M.fireInput(connections_out[M], cloneMessage(msg))
		return
	}

	//Delete all incoming connections
	proc/wipeIncoming()
	{
		for(var/atom/M in connections_in)
		{
			if(istype(M, /obj/item/mechcomp))
			{
				M.connections_out.Remove(src)
			}

			connections_in.Remove(M)
		}
		return
	}

	//Delete all outgoing connections.
	proc/wipeOutgoing()
	{
		for(var/atom/M in connections_out)
		{
			if(istype(M, /obj/item/mechcomp))
			{
				M.connections_in.Remove(src)
			}

			connections_out.Remove(M)
		}
		return
	}

	//Helper proc to check if a mob has a multitool handy.
	proc/hasMultitool(var/mob/M)
	{
		if(hasvar(M, "l_hand") && istype(M:l_hand, /obj/item/device/multitool))
		{
			return 1
		}
		if(hasvar(M, "r_hand") && istype(M:r_hand, /obj/item/device/multitool))
		{
			return 1
		}
		if(hasvar(M, "module_states"))
		{
			for(var/atom/A in M:module_states)
			{
				if(istype(A, /obj/item/device/multitool))
				{
					return 1
				}
			}
		}

		return 0
	}

	//Helper proc to check if a mob is allowed to change connections. Right now you only need a multitool.
	proc/allowChange(var/mob/M)
	{
		if(hasMultitool(M))
		{
			return 1
		}

		return 0
	}

	//Called when a component is dragged onto another one.
	proc/dropConnect(obj/O, null, var/src_location, var/control_orig, var/control_new, var/params)
	{
		if(O == src || !istype(O, /obj/item/mechcomp))
		{
			return
		}

		var/typesel = input(usr, "Use [src] as:", "Connection Type") in list("Trigger", "Receiver", "*CANCEL*")

		if(typesel == "*CANCEL*")
		{
			return
		}

		switch(typesel)

			if("Trigger")
			{
				if(O.connections_out.Find(src))
				{
					boutput(usr, MECHLOOPSTRING)
					return
				}

				if (src.connections_out.Find(O))
				{
					boutput(usr, MECHDUPESTRING)
					return
				}

				if(O.inputs.len)
				{
					var/selected_input = O.chooseInput()

					if(selected_input == "*CANCEL*")
					{
						return
					}
					connections_out.Add(O)
					connections_out[O] = selected_input
					O.connections_in.Add(src)
					boutput(usr, "<span style=\"color:green\">You connect the [src.name] to the [O.name].</span>")
				}
				else
				{
					boutput(usr, MECHNOINPUTSTRING)
				}
			}

			if("Receiver")
			{
				if(O.connections_in.Find(src))
				{
					boutput(usr, MECHLOOPSTRING)
					return
				}

				if(inputs.len)
				{
					var/selected_input = chooseInput()

					if(selected_input == "*CANCEL*")
					{
						return
					}
					O.connections_out.Add(src)
					O.connections_out[src] = selected_input
					connections_in.Add(O)
					boutput(usr, "<span style=\"color:green\">You connect the [src.name] to the [O.name].</span>")
				}
				else
				{
					boutput(usr, MECHNOINPUTSTRING)
				}
			}

		return
	}

	//Physical procs

	get_desc()
	{
		if(hasMultitool(usr))
		{
			. += giveReadout()
		}
	}

	proc/giveReadout()
	{
		return
	}

	//Removes all particles attached to the component, for when it's unsecured, disconnected, under the floor etc.
	proc/cutParticles()
	{
		if(particles.len)
		{
			for(var/datum/particleSystem/mechanic/M in particles)
			{
				M.Die()
			}
			particles.Cut()
		}

		return
	}

	proc/toggleAnchor()
	{
		switch(anchored)
		{
			if(0)
			{
				if(!isturf(src.loc))
				{
					boutput(usr, "<span style=\"color:red\">[src] needs to be on the ground for that to work.</span>")
					return 0
				}

				boutput(user, "You attach the [src] to the underfloor and activate it.")
				logTheThing("station", user, src, "placed a %target% at [showCoords(src.x, src.y, src.z)]")
				anchored = 1
			}
			if(1)
			{
				boutput(user, "You detach the [src] from the underfloor and deactivate it.")
				anchored = 0
			}
		}

		var/turf/T = src.loc
		if(isturf(T))
		{
			hide(T.intact)
		}
		else
		{
			hide()
		}

		wipeIncoming()
		wipeOutgoing()
		return 1
	}

	attack_hand(mob/user as mob)
	{
		// Can only pick it up if it's loose and you're not a robot.
		if(anchored == 0 || !issilicon(user))
		{
			return ..(user)
		}
		else
		{
			return
		}
	}

	attack_ai(mob/user as mob)
	{
		return src.attack_hand(user)
	}

	attackby(obj/item/W as obj, mob/user as mob)
	{
		if(istype(W, /obj/item/screwdriver))
		{
			if(w_class >= 2)
			{
				boutput(usr, MECHTOOBIGSTRING)
			}
			else
			{
				return toggleAnchor()
			}
		}
		else if(istype(W, /obj/item/wrench))
		{
			if(w_class >= 4)
			{
				boutput(usr, MECHTOOBIGSTRING)
			}
			else if(w_class < 2)
			{
				boutput(usr, MECHTOOSMALLSTRING)
			}
			else
			{
				return toggleAnchor()
			}
		}
		else if(istype(W,/obj/item/device/multitool))
		{
			var/selected_input = chooseInput()

			if(selected_input == "*CANCEL*")
			{
				return 1
			}
			else
			{
				fireInput(selected_input, W.setSignal())
				return 1
			}
		}
		else
		{
			return 0
		}
	}

	pickup()
	{
		if(anchored == 1 || w_class >= 4)
		{
			return
		}

		mechanics.wipeIncoming()
		mechanics.wipeOutgoing()
		return ..()
	}

	dropped()
	{
		mechanics.wipeIncoming()
		mechanics.wipeOutgoing()
		return ..()
	}

	MouseDrop(obj/O, null, var/src_location, var/control_orig, var/control_new, var/params)
	{
		if(!istype(usr, /mob/living))
		{
			return
		}

		if(anchored == 0 || (istype(O, /obj/item/mechanics) && O.anchored == 0))
		{
			boutput(usr, "<span style=\"color:red\">Both components need to be secured into place before they can be connected.</span>")
			return
		}

		if(usr.stat)
		{
			return
		}

		if(!allowChange(usr))
		{
			boutput(usr, MECHFAILSTRING)
			return
		}

		dropConnect(O, null, src_location, control_orig, control_new, params)
		return ..()
	}

	proc/componentSay(var/string)
	{
		string = trim(sanitize(html_encode(string)), 1)
		for(var/mob/O in all_hearers(7, src.loc))
		{
			O.show_message("<span class='game radio'><span class='name'>[src]</span><b> [bicon(src)] [pick("squawks", "beeps", "boops", "says", "screeches")], </b> <span class='message'>\"[string]\"</span></span>",2)
		}
	}

	verb/wipe()
		set src in view(1)
		set name = "\[Disconnect all\]"
		set desc = "Disconnects all devices connected to this device."
		set category = "Local"

		if (!istype(usr, /mob/living) || usr.stat)
		{
			return
		}
		else if (!mechanics.allowChange(usr))
		{
			boutput(usr, MECHFAILSTRING)
			return
		}

		mechanics.wipeIncoming()
		mechanics.wipeOutgoing()

		boutput(usr, "<span style=\"color:blue\">You disconnect [src].</span>")
		return


	hide(var/intact)
	{
		under_floor = (intact && anchored == 1)
		updateIcon()
		return
	}

	proc/updateIcon()
	{
		return
	}
}

/*	verb/setvalue()
		set src in view(1)
		set name = "\[Set Send-Signal\]"
		set desc = "Sets the signal that is sent when this device is triggered."
		set category = "Local"

		if (!istype(usr, /mob/living))
			return
		if (usr.stat)
			return
		if (!mechanics.allowChange(usr))
			boutput(usr, "<span style=\"color:red\">[MECHFAILSTRING]</span>")
			return

		var/inp = input(usr,"Please enter Signal:","Signal setting","1") as text
		inp = trim(adminscrub(inp), 1)
		if(length(inp))
			mechanics.outputSignal = inp
			boutput(usr, "Signal set to [inp]")
		return
*/

