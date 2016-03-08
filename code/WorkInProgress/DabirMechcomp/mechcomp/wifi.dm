/obj/item/mechcomp/wifi
	name = "Wifi transceiver component"
	desc = ""
	icon_state = "comp_radiosig"
	var/ready = 1
	var/send_full = 0
	var/only_directed = 1

	var/net_id = null //What is our ID on the network?
	var/last_ping = 0
	var/range = 0

	var/frequency = 1419
	var/datum/radio_frequency/radio_connection

	get_desc()
		. += {"<br><span style=\"color:blue\">[send_full ? "Sending full unprocessed Signals.":"Sending only processed sendmsg and pda Message Signals."]<br>
		[only_directed ? "Only reacting to Messages directed at this Component.":"Reacting to ALL Messages received."]<br>
		Current Frequency: [frequency]<br>
		Current NetID: [net_id]</span>"}

	New()
		..()
		mechanics.addInput("send radio message", "send")
		mechanics.addInput("set frequency", "setfreq")

		if(radio_controller)
			set_frequency(frequency)

		src.net_id = format_net_id("\ref[src]")

		return

	proc/setfreq(var/datum/mechanicsMessage/input)
		var/newfreq = text2num(input.signal)
		if(!newfreq) return
		set_frequency(newfreq)
		return

	proc/send(var/datum/mechanicsMessage/input)
		if(level == 2) return
		var/list/converted = params2list(input.signal)
		if(!converted.len || !ready) return

		ready = 0
		spawn(30) ready = 1

		var/datum/signal/sendsig = get_free_signal()

		sendsig.source = src
		sendsig.data["sender"] = src.net_id
		sendsig.transmission_method = TRANSMISSION_RADIO

		for(var/X in converted)
			sendsig.data["[X]"] = "[converted[X]]"

		spawn(0) src.radio_connection.post_signal(src, sendsig, src.range)

		animate_flash_color_fill(src,"#FF0000",2, 2)
		return

	receive_signal(datum/signal/signal)
		if(!signal || signal.encryption || level == 2)
			return

		if((only_directed && signal.data["address_1"] == src.net_id) || !only_directed || (signal.data["address_1"] == "ping"))

			if(send_full)
				var/datum/mechanicsMessage/msg = mechanics.newSignal(html_decode(list2params_noencode(signal.data)))
				mechanics.fireOutgoing(msg)
				animate_flash_color_fill(src,"#00FF00",2, 2)
				return

			if((signal.data["address_1"] == "ping") && signal.data["sender"])
				var/datum/signal/pingsignal = get_free_signal()
				pingsignal.source = src
				pingsignal.data["device"] = "COMP_WIFI"
				pingsignal.data["netid"] = src.net_id
				pingsignal.data["address_1"] = signal.data["sender"]
				pingsignal.data["command"] = "ping_reply"
				pingsignal.data["data"] = "Wifi Component"
				pingsignal.transmission_method = TRANSMISSION_RADIO

				spawn(5) //Send a reply for those curious jerks
					src.radio_connection.post_signal(src, pingsignal, src.range)

			else if(signal.data["command"] == "sendmsg" && signal.data["data"])
				var/datum/mechanicsMessage/msg = mechanics.newSignal(html_decode(signal.data["data"]))
				mechanics.fireOutgoing(msg)
				animate_flash_color_fill(src,"#00FF00",2, 2)

			else if(signal.data["command"] == "text_message" && signal.data["message"])
				var/datum/mechanicsMessage/msg = mechanics.newSignal(html_decode(signal.data["message"]))
				mechanics.fireOutgoing(msg)
				animate_flash_color_fill(src,"#00FF00",2, 2)

			else if(signal.data["command"] == "setfreq" && signal.data["data"])
				var/newfreq = text2num(signal.data["data"])
				if(!newfreq) return
				set_frequency(newfreq)
				animate_flash_color_fill(src,"#00FF00",2, 2)

		return

	proc/set_frequency(new_frequency)
		if(!radio_controller) return
		new_frequency = max(1000, min(new_frequency, 1500))
		radio_controller.remove_object(src, "[frequency]")
		frequency = new_frequency
		radio_connection = radio_controller.add_object(src, "[frequency]")

	verb/setfreqv()
		set src in view(1)
		set name = "\[Set Frequency\]"
		set desc = "Sets the frequency."
		set category = "Local"

		if (!istype(usr, /mob/living))
			return
		if (usr.stat)
			return
		if (!mechanics.allowChange(usr))
			boutput(usr, "<span style=\"color:red\">[MECHFAILSTRING]</span>")
			return

		var/inp = input(usr,"Please enter Frequency:","Frequency setting", frequency) as num
		if(inp)
			set_frequency(inp)
			boutput(usr, "Frequency set to [inp]")
		return


	verb/toggleidf()
		set src in view(1)
		set name = "\[Toggle NetID filtering\]"
		set desc = "Toggles whether the Component will only react to Radio Messages directed at it or to *all* Messages on the Frequency."
		set category = "Local"

		if (!istype(usr, /mob/living))
			return
		if (usr.stat)
			return
		if (!mechanics.allowChange(usr))
			boutput(usr, "<span style=\"color:red\">[MECHFAILSTRING]</span>")
			return

		only_directed = !only_directed
		boutput(usr, "[only_directed ? "Now only reacting to Messages directed at this Component":"Now reacting to ALL Messages."]")
		return

	verb/togglefall()
		set src in view(1)
		set name = "\[Toggle Forward All\]"
		set desc = "Toggles whether the Component will forward ALL radio Messages without processing them or not."
		set category = "Local"

		if (!istype(usr, /mob/living))
			return
		if (usr.stat)
			return
		if (!mechanics.allowChange(usr))
			boutput(usr, "<span style=\"color:red\">[MECHFAILSTRING]</span>")
			return

		send_full = !send_full
		boutput(usr, "[send_full ? "Now forwarding all Radio Messages as they are.":"Now processing only sendmsg and normal PDA messages."]")
		return

	updateIcon()
		icon_state = "[under_floor ? "u":""]comp_radiosig"
		return