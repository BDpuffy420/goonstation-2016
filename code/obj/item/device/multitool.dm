/obj/item/device/multitool
	name = "multitool"
	icon_state = "multitool"
	flags = FPRINT | TABLEPASS| CONDUCT
	force = 5.0
	w_class = 2.0
	throwforce = 5.0
	throw_range = 15
	throw_speed = 3
	desc = "A universal electronic signal manipulator. A vital tool for electricians, hackers and general pranksters."
	m_amt = 50
	g_amt = 20
	mats = 6
	module_research = list("tools" = 5, "devices" = 2)

	var/signalstring = ""

	proc/setSignal()
		signalstring = input("Set a signal to use as an output", "Custom Signal", signalstring)
		return signalstring

	attack_self()
		setSignal()
