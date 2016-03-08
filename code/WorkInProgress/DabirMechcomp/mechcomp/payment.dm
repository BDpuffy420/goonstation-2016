/obj/item/mechcomp/payment
	name = "Payment component"
	desc = ""
	icon_state = "comp_money"
	density = 0
	var/price = 100
	var/code = null
	var/collected = 0
	var/current_buffer = 0
	var/ready = 1

	var/thank_string = ""

	get_desc()
		. += {"<br><span style=\"color:blue\">Collected money: [collected]<br>
		Current price: [price] credits</span>"}

	New()
		..()
		mechanics.addInput("eject money", "emoney")
		return


	proc/emoney(var/datum/mechanicsMessage/input)
		if(level == 2) return
		if(input)
			if(input.signal == code)
				ejectmoney()
		return

	attackby(obj/item/W as obj, mob/user as mob)
		if(..(W, user)) return
		else if (istype(W, /obj/item/spacecash) && ready)
			ready = 0
			spawn(30) ready = 1
			current_buffer += W.amount
			if (src.price <= 0)
				src.price = initial(src.price)
			if(current_buffer >= price)
				if(length(thank_string))
					componentSay("[thank_string]")

				if(current_buffer > price)
					componentSay("Here is your change!")
					var/obj/item/spacecash/C = new /obj/item/spacecash(user.loc, current_buffer - price)
					user.put_in_hand_or_drop(C)

				collected += price
				current_buffer = 0

				usr.drop_item()
				del(W)

				var/datum/mechanicsMessage/msg = mechanics.newSignal(mechanics.outputSignal)
				mechanics.fireOutgoing(msg)
				flick("comp_money1", src)
		return