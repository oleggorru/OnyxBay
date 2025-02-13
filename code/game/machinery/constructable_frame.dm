//This file was auto-corrected by findeclaration.exe on 25.5.2012 20:42:31

//Circuit boards are in /code/game/objects/items/weapons/circuitboards/machinery/

/obj/machinery/constructable_frame //Made into a seperate type to make future revisions easier.
	name = "machine frame"
	icon = 'icons/obj/stock_parts.dmi'
	icon_state = "box_0"
	density = 1
	anchored = 1
	use_power = POWER_USE_OFF
	var/obj/item/circuitboard/circuit
	var/list/components = list()
	var/list/req_components = list()
	var/list/req_component_names = list()
	var/state = 1
	atom_flags = ATOM_FLAG_CLIMBABLE

	proc/update_desc()
		var/D
		if(req_components)
			var/list/component_list = new
			for(var/I in req_components)
				if(req_components[I] > 0)
					component_list += "[num2text(req_components[I])] [req_component_names[I]]"
			D = "Requires [english_list(component_list)]."
		desc = D

/obj/machinery/constructable_frame/machine_frame
	attackby(obj/item/P as obj, mob/user as mob)
		switch(state)
			if(1)
				if(isCoil(P))
					var/obj/item/stack/cable_coil/C = P
					if (C.get_amount() < 5)
						to_chat(user, "<span class='warning'>You need five lengths of cable to add them to the frame.</span>")
						return
					playsound(src.loc, 'sound/items/Deconstruct.ogg', 50, 1)
					to_chat(user, "<span class='notice'>You start to add cables to the frame.</span>")
					if(do_after(user, 20, src) && state == 1)
						if(C.use(5))
							to_chat(user, "<span class='notice'>You add cables to the frame.</span>")
							state = 2
							icon_state = "box_1"
				else
					if(isWrench(P))
						playsound(src.loc, 'sound/items/Ratchet.ogg', 75, 1)
						to_chat(user, "<span class='notice'>You dismantle the frame</span>")
						new /obj/item/stack/material/steel(src.loc, 5)
						qdel(src)
			if(2)
				if(istype(P, /obj/item/circuitboard))
					var/obj/item/circuitboard/B = P
					if(B.board_type == "machine")
						if(!user.drop(P, src))
							return
						playsound(loc, 'sound/items/Deconstruct.ogg', 50, 1)
						to_chat(user, "<span class='notice'>You add the circuit board to the frame.</span>")
						circuit = P
						icon_state = "box_2"
						state = 3
						components = list()
						req_components = circuit.req_components.Copy()
						for(var/A in circuit.req_components)
							req_components[A] = circuit.req_components[A]
						req_component_names = circuit.req_components.Copy()
						for(var/A in req_components)
							var/obj/ct = A
							req_component_names[A] = initial(ct.name)
						update_desc()
						to_chat(user, desc)
					else
						to_chat(user, "<span class='warning'>This frame does not accept circuit boards of this type!</span>")
				else
					if(isWirecutter(P))
						playsound(src.loc, 'sound/items/Wirecutter.ogg', 50, 1)
						to_chat(user, "<span class='notice'>You remove the cables.</span>")
						state = 1
						icon_state = "box_0"
						var/obj/item/stack/cable_coil/A = new /obj/item/stack/cable_coil( src.loc )
						A.amount = 5

			if(3)
				if(isCrowbar(P))
					playsound(src.loc, 'sound/items/Crowbar.ogg', 50, 1)
					state = 2
					circuit.loc = src.loc
					circuit = null
					if(components.len == 0)
						to_chat(user, "<span class='notice'>You remove the circuit board.</span>")
					else
						to_chat(user, "<span class='notice'>You remove the circuit board and other components.</span>")
						for(var/obj/item/I in components)
							I.loc = src.loc
					desc = initial(desc)
					req_components = null
					components = null
					icon_state = "box_1"
				else
					if(isScrewdriver(P))
						var/component_check = 1
						for(var/R in req_components)
							if(req_components[R] > 0)
								component_check = 0
								break
						if(component_check)
							playsound(src.loc, 'sound/items/Screwdriver.ogg', 50, 1)
							var/obj/machinery/new_machine = new src.circuit.build_path(src.loc, src.dir)

							if(new_machine.component_parts)
								QDEL_LIST(new_machine.component_parts)
							else
								new_machine.component_parts = list()

							src.circuit.construct(new_machine)

							if(circuit.contain_parts) // things like disposal don't want their parts in them
								for(var/obj/O in components)
									O.loc = new_machine
									new_machine.component_parts.Add(O)
								circuit.loc = new_machine
							else
								for(var/obj/O in components)
									O.loc = null
									new_machine.component_parts.Add(O)
								circuit.loc = null

							new_machine.component_parts.Add(circuit)

							new_machine.RefreshParts()
							qdel(src)
					else
						if(istype(P, /obj/item))
							for(var/I in req_components)
								if(istype(P, I) && (req_components[I] > 0))
									playsound(src.loc, 'sound/items/Deconstruct.ogg', 50, 1)
									if(isCoil(P))
										var/obj/item/stack/cable_coil/CP = P
										if(CP.get_amount() > 1)
											var/camt = min(CP.amount, req_components[I]) // amount of cable to take, idealy amount required, but limited by amount provided
											var/obj/item/stack/cable_coil/CC = new /obj/item/stack/cable_coil(src)
											CC.amount = camt
											CC.update_icon()
											CP.use(camt)
											components.Add(CC)
											req_components[I] -= camt
											update_desc()
											break
									if(user.drop(P, src))
										components.Add(P)
										req_components[I]--
										update_desc()
										break
							to_chat(user, desc)
							if(P && P.loc != src && !istype(P, /obj/item/stack/cable_coil))
								to_chat(user, "<span class='warning'>You cannot add that component to the machine!</span>")
