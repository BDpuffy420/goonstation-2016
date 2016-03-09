/obj/item/mechcomp/wifi
{
	name = "wifi transceiver component"
	desc = "Sends and receives wifi signals on a specific frequency. Can be set to forward any messages or only ones addressed to the component. Needs 3 seconds to recharge between transmissions."
	icon_state = "comp_radiosig"
	var/ready = 1
	var/eavesdrop = 0
	var/processing = 1

	var/net_id = null //What is our ID on the network?
	var/last_ping = 0
	var/range = 0

	var/frequency = 1149
	var/datum/radio_frequency/radio_connection

	New()
	{
		..()

		if(radio_controller)
			set_frequency(frequency)

		src.net_id = format_net_id("\ref[src]")

		return
	}

	getReadout()
	{
		var/freq_string = num2text(frequency)
		freq_string = copytext(freq_string, 1, 4) + "." + copytext(freq_string, 4)

		return {"<span style=\"color:blue\">Forwarding [processing ? "processed PDA and sendmsg" : "full"] messages with [eavesdrop ? "any address" :"this component's address"]<br>
		Current frequency: [freq_string]<br>
		This component's address is [net_id]<br>
		It is [ready ? "" : "not "]ready to transmit.</span>"}

	}

	proc/input1(var/datum/mech_message/input, getName=0)
	{
		if(getName) return "Set frequency"

		var/newfreq = text2num(input.signal)
		if(!newfreq) return
		set_frequency(newfreq)

		if(announcements)
		{
			var/freq_string = num2text(frequency)
			freq_string = copytext(freq_string, 1, 4) + "." + copytext(freq_string, 4)
			componentSay("Frequency set to [freq_string]")
		}
		return
	}

	proc/input2(var/datum/mech_message/input, getName=0)
	{
		if(getName) return "Toggle eavesdropping"

		if(input)
		{
			eavesdrop = !eavesdrop
			if(announcements) componentSay("Now forwarding messages for [eavesdrop ? "any" : "only my own"] address.")
		}
	}

	proc/input3(var/datum/mech_message/input, getName=0)
	{
		if(getName) return "Toggle message processing"

		if(input)
		{
			processing = !processing
			if(announcements) componentSay("Now [processing ? "only forwarding processed" : "not processing"] PDA and sendmsg messages.")
		}
	}

	proc/input4(var/datum/mech_message/input, getName=0)
	{
		if(getName) return "Send wifi message"

		if(input.signal)
		{
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
		}
	}

	receive_signal(datum/signal/signal)
	{
		if(!signal || signal.encryption)
			return

		if(signal.data["address_1"] == src.net_id || eavesdrop)
		{
			var/datum/mech_message/msg = newMessage("")

			if(processing)
			{
				if(signal.data["command"] == "text_message" || signal.data["command"] == "sendmsg")
				{
					msg.signal = signal.data["message"]
				}
			}
			else
			{
				msg.signal = list2params_noencode(signal.data)
			}

			if(msg.signal)
			{
				fireAllOutgoing(msg)
				animate_flash_color_fill(src,"#00FF00",2, 2)
			}
		}
		else if(signal.data["address_1"] == "ping" && signal.data["sender"])
		{
			var/datum/signal/pingsignal = get_free_signal()
			pingsignal.source = src
			pingsignal.data["device"] = "COMP_WIFI"
			pingsignal.data["netid"] = src.net_id
			pingsignal.data["address_1"] = signal.data["sender"]
			pingsignal.data["command"] = "ping_reply"
			pingsignal.data["data"] = "Wifi Component"
			pingsignal.transmission_method = TRANSMISSION_RADIO

			spawn(5) //Send a reply for those curious jerks
			{
				src.radio_connection.post_signal(src, pingsignal, src.range)
			}
		}
	}

	proc/set_frequency(new_frequency)
	{
		if(radio_controller)
		{
			new_frequency = max(1000, min(new_frequency, 1500))
			radio_controller.remove_object(src, "[frequency]")
			frequency = new_frequency
			radio_connection = radio_controller.add_object(src, "[frequency]")
		}
	}

	updateIcon()
	{
		icon_state = "[under_floor ? "u":""]comp_radiosig"
		return
	}
}