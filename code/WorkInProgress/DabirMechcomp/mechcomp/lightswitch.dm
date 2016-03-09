// Conversion of lightswitch to a special mechcomp that starts out anchored and processing.
// Differences: can't affect another area, can be moved by wrenching them,
// don't flip when another switch in the same area is flipped,
// are inherently a mechcomp rather than having the datum stuck to them.

// Consequences of this: The switches will get messed up very fast, and people can turn off all the lights and steal the switches.

/obj/item/mechcomp/light_switch
{
	name = "light switch"
	desc = "Turns the lights on and off."
	icon = 'icons/obj/power.dmi'  // TODO: replace the graphics with a mechanical switch.
	icon_state = "light1"
	anchored = 1
	var/stat = 0
	var/on = 1
	var/area/area = null

	New()
	{
		..()
		spawn(5)
		{
			// Lightswitches start anchored, so they're processed from the get-go.
			if (!(src in processing_items)) processing_items.Add(src)

			area = loc.loc

			if(!name || name == "N light switch" || name == "E light switch" || name == "S light switch" || name == "W light switch")
			{
				name = "light switch"
			}

			on = area.lightswitch
			updateIcon()
		}
	}

	proc/input1(var/datum/mechcompMessage/input, getName=0)
	{
		if(getName) return "Toggle lights"

		area.lightswitch = !area.lightswitch			// Toggle the area lights.

		for(var/obj/machinery/light_switch/L in area)	// For each old electronic lightswitch,
		{
			L.on = area.lightswitch							// update the display
			L.updateicon()									// to reflect the light status.
		}

		area.power_change()								// Deal with power stuff.

		if(connections_out)								// Tell everything that's listening whether the lights are now on or off.
		{
			fireAllOutgoing(newMessage("[on ? "lightOn":"lightOff"]"))
		}

		return
	}

	attack_hand(mob/user)
	{
		input1(newMessage("1"))			// Manually trigger the light toggle input.
		on = !on						// Also, flip the component's own switch.
		updateIcon()					// Which wouldn't happen if input was triggered remotely or w/ a multitool.
	}

	attack_self()
	{
		on = !on						// Flips the switch. It's in your hand so it can't affect anything.
		updateIcon()
	}

	// Code that lets you stick it to arbitrary positions on walls shamelessly stolen from hand scanners and stickers.
	afterattack(atom/target as mob|obj|turf|area, mob/user as mob, reach, params)
	{
		if(!anchored && get_dist(src, target) == 1)
		{
			if(isturf(target) && target.density)
			{
				user.drop_item()
				loc = target
				if(params)
				{
					if (islist(params) && params["icon-y"] && params["icon-x"])
					{
						pixel_x = text2num(params["icon-x"]) - 16
						pixel_y = text2num(params["icon-y"]) - 16
					}
				}

			}
		}
		return
	}

	// Recenter graphic when picked up.
	pickup()
	{
		pixel_x = 0
		pixel_y = 0
		return ..()
	}

	// When reanchoring, set the area it's operating on to its current location.
	toggleAnchor()
	{
		if(..() && anchored == 1)
		{
			area = loc.loc
		}
	}

	updateIcon()
	{
		if(on)
		{
			icon_state = "light1"
		}
		else
		{
			icon_state = "light0"
		}
	}

	get_desc()
	{
		. += "It is [on? "on" : "off"]"
	}
}

/obj/item/mechcomp/light_switch/north
{
	name = "N light switch"
	pixel_y = 24
}

/obj/item/mechcomplight_switch/east
{
	name = "E light switch"
	pixel_x = 24
}

/obj/item/mechcomplight_switch/south
{
	name = "S light switch"
	pixel_y = -24
}

/obj/item/mechcomplight_switch/west
{
	name = "W light switch"
	pixel_x = -24
}