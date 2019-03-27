#define LOW_PRESSURE_SHOT 3.5
#define MEDIUM_PRESSURE_SHOT 5.3846
#define HIGH_PRESSURE_SHOT 8.75

/obj/item/weapon/gun/projectile/pneumatic_gun
	name = "pneumatic gun"
	desc = "Uses compressed gas to propell ball bearings at lethal speeds"
	icon = 'icons/obj/gun.dmi'
	icon_state = "pneumatic_gun_empty"
	item_state = "pneumatic_gun_empty"
	inhand_states = list("left_hand" = 'icons/mob/in-hand/left/guninhands_left.dmi', "right_hand" = 'icons/mob/in-hand/right/guninhands_right.dmi')
	fire_sound = 'sound/weapons/pneumatic_blast.ogg'
	slot_flags = SLOT_BACK
	flags = FPRINT
	siemens_coefficient = 1
	conventional_firearm = 0
	ammo_type = "/obj/item/ammo_casing/ball_bearing"
	mag_type = "/obj/item/ammo_storage/magazine/ball_bearing"
	load_method = 2
	caliber = BALL
	ejectshell = 0
	w_class = W_CLASS_MEDIUM
	delay_user = 0.3
	throw_speed = 3
	throw_range = 10
	force = 7.0
	recoil = 0
	w_type = RECYK_METAL
	melt_temperature = MELTPOINT_STEEL
	var/liters_per_shot = LOW_PRESSURE_SHOT //3.5 liters is low force (20 shots), 5.3846 liters is medium force(13 shots), and 8.75 liters is maximum force (8 shots)
	var/obj/item/weapon/tank/connected_tank = null //this is to keep track of the last tank used to shoot, so we can remove some gas from it after each shot
	var/tank_orig_capacity = null


/obj/item/weapon/gun/projectile/pneumatic_gun/attack_self(mob/user)
	if(connected_tank)
		var/shots_left = round(connected_tank.air_contents.volume / liters_per_shot)
		to_chat(user, "<span class='notice'>The pneumatic gun can still shoot [shots_left] times using [liters_per_shot] liters per shot.</span>")
	else
		to_chat(user, "<span class='warning'>The pneumatic gun is not connected to any gas tank!</span>")
	..()

/obj/item/weapon/gun/projectile/pneumatic_gun/attackby(obj/item/A, mob/user)
	. = ..()
	if(iswrench(A))
		switch(liters_per_shot)
			if (LOW_PRESSURE_SHOT) liters_per_shot = MEDIUM_PRESSURE_SHOT
			if (MEDIUM_PRESSURE_SHOT) liters_per_shot = HIGH_PRESSURE_SHOT
			else liters_per_shot = LOW_PRESSURE_SHOT
		to_chat(user, "<span class='notice'>The pneumatic gun gas selector now points to [liters_per_shot] liters per shot.</span>")
	if(istype(A, /obj/item/weapon/tank))
		if (A == connected_tank)
			user.visible_message("[user.name] begins to disconnect the [A.name] from the pneumatic gun", "<span class='notice'>You begin to disconnect the [A.name] from the pneumatic gun.</span>")
			if (do_after(user, src, 25))
				connected_tank = null
				tank_orig_capacity = null
				user.visible_message("[user.name] disconnects the [A.name] from the pneumatic gun.", "<span class='notice'>You disconnect the [A.name] from the pneumatic gun.</span>")
		else
			user.visible_message("[user.name] begins to connect the [A.name] to the pneumatic gun", "<span class='notice'>You begin to connect the [A.name] to the pneumatic gun.</span>")
			if (do_after(user, src, 25))
				connected_tank = A
				tank_orig_capacity = connected_tank.air_contents.volume
				user.visible_message("[user.name] connects the [A.name] to the pneumatic gun.", "<span class='notice'>You connect the [A.name] to the pneumatic gun.</span>")
	src.update_icon()


//Removed because it's useless as most, if not all drop calls use the 'force' flag
//obj/item/weapon/gun/projectile/pneumatic_gun/allow_drop()
// 	if (connected_tank)
// 		to_chat("<span class='warning'>You cannot drop the pneumatic gun because it's still connected to the [connected_tank.name]!</span>")
// 		return 0
// 	else
// 		return 1


/obj/item/weapon/gun/projectile/pneumatic_gun/dropped(mob/user)
	..()
	if (connected_tank)
		user.drop_item(connected_tank)
	connected_tank = null
	src.update_icon()


/obj/item/weapon/gun/projectile/pneumatic_gun/afterattack(atom/A, mob/living/user, flag, params, struggle, var/use_shooter_turf = FALSE)
	if(flag)
		return //we're placing gun on a table or in backpack
	
	if (isturf(connected_tank.loc))
		connected_tank = null
		tank_orig_capacity = null
		to_chat("<span class='warning'>Cannot shoot because the gas tank was dropped!</span>")
		update_icon()
		return

	if(harm_labeled >= min_harm_label)
		to_chat(user, "<span class='warning'>A label sticks the trigger to the trigger guard!</span>")//Such a new feature, the player might not know what's wrong if it doesn't tell them.

		return
	if(istype(target, /obj/machinery/recharger))
		return //Shouldnt flag take care of this?

	if (user.is_pacified(VIOLENCE_GUN,A,src))
		return

	if(!chambered && stored_magazine && !stored_magazine.ammo_count() && gun_flags &AUTOMAGDROP) //auto_mag_drop decides whether or not the mag is dropped once it empties
		var/drop_me = stored_magazine // prevents dropping a fresh/different mag.
		spawn(automagdrop_delay_time)
			if((stored_magazine == drop_me) && (loc == user))	//prevent dropping the magazine if we're no longer holding the gun
				RemoveMag(user)
				if(mag_drop_sound)
					playsound(user, mag_drop_sound, 40, 1)
	

	if (connected_tank)
		if (connected_tank.volume >= liters_per_shot)
			Fire(A, user, params)
			var/turf/T = user.Facing()
			T.air.add(connected_tank.air_contents.remove_volume(liters_per_shot, TRUE, TRUE))
		else
			to_chat(user, "<span class='warning'>There is not enough gas in the tank!</span>")
	else
		to_chat(user, "<span class='warning'>There is not gas tank connected!</span>")

	src.update_icon()
	

/obj/item/weapon/gun/projectile/pneumatic_gun/update_icon()
	if (connected_tank)
		var/remaining_gas = connected_tank.air_contents.volume * 100 / connected_tank.volume
		if (remaining_gas >= 75)
			icon_state = "pneumatic_gun_green_connected"
			item_state = "pneumatic_gun_green_connected"
		else if (remaining_gas >= 25)
			icon_state = "pneumatic_gun_yellow_connected"
			item_state = "pneumatic_gun_yellow_connected"
		else if (remaining_gas < 25)
			icon_state = "pneumatic_gun_red_connected"
			item_state = "pneumatic_gun_red_connected"
	else
		icon_state = "pneumatic_gun_empty"
		item_state = "pneumatic_gun_empty"
	..()

/obj/item/weapon/gun/projectile/pneumatic_gun/examine(mob/user)
	to_chat(user, "<span class='notice'>The pneumatic gun is currently using [liters_per_shot] liters of gas per shot.</span>")


//I hate having to copy-paste this but it's the only way I can modify the parameters of each bullet
/obj/item/weapon/gun/projectile/pneumatic_gun/Fire(atom/target as mob|obj|turf|area, mob/living/user as mob|obj, params, reflex = 0, struggle = 0, var/use_shooter_turf = FALSE)//TODO: go over this
	//Exclude lasertag guns from the M_CLUMSY check.
		
	var/explode = FALSE
	var/dehand = FALSE
	if(istype(user, /mob/living))
		var/mob/living/M = user
		if(clumsy_check && clumsy_check(M) && prob(50))
			explode = TRUE
		if(honor_check && is_honorable(M, honorable))
			explode = TRUE
			dehand = TRUE
		if(explode)
			if(dehand)
				var/limb_index = user.is_holding_item(src)
				var/datum/organ/external/L = M.find_organ_by_grasp_index(limb_index)
				visible_message("<span class='sinister'>[src] blows up in [M]'s [L.display_name]!</span>")
				L.droplimb(1)
			else
				to_chat(M, "<span class='danger'>[src] blows up in your face.</span>")
				M.take_organ_damage(0,20)
			M.drop_item(src, force_drop = 1)
			qdel(src)
			return

	if(!can_Fire(user, 1))
		return

	add_fingerprint(user)
	var/atom/originaltarget = target

	var/turf/curloc = user.loc
	if(use_shooter_turf)
		curloc = get_turf(user)
	var/turf/targloc = get_turf(target)
	if (!istype(targloc) || !istype(curloc))
		return

	if(defective)
		target = get_inaccuracy(originaltarget, 1+recoil)
		targloc = get_turf(target)

	if(!special_check(user))
		return

	if (!ready_to_fire())
		if (world.time % 3) //to prevent spam
			to_chat(user, "<span class='warning'>[src] is not ready to fire again!</span>")
		return

	if(!process_chambered() || jammed) //CHECK
		return click_empty(user)

	if(!in_chamber)
		return
	if(defective)
		if(!failure_check(user))
			return
	if(!istype(src, /obj/item/weapon/gun/energy/tag))
		log_attack("[user.name] ([user.ckey]) fired \the [src] (proj:[in_chamber.name]) at [originaltarget] [ismob(target) ? "([originaltarget:ckey])" : ""] ([originaltarget.x],[originaltarget.y],[originaltarget.z])[struggle ? " due to being disarmed." :""]" )
	in_chamber.firer = user

	if(user.zone_sel)
		in_chamber.def_zone = user.zone_sel.selecting
	else
		in_chamber.def_zone = LIMB_CHEST

	if(targloc == curloc)
		target.bullet_act(in_chamber)
		qdel(in_chamber)
		in_chamber = null
		update_icon()
		play_firesound(user, reflex)
		return

	play_firesound(user, reflex)

	//damage setting
	if (liters_per_shot == LOW_PRESSURE_SHOT)
		in_chamber.damage *= (liters_per_shot / LOW_PRESSURE_DAMAGE)
	
	in_chamber.original = target
	in_chamber.forceMove(get_turf(user))
	in_chamber.starting = get_turf(user)
	in_chamber.shot_from = src
	user.delayNextAttack(delay_user) // TODO: Should be delayed per-gun.
	in_chamber.silenced = silenced
	in_chamber.current = curloc
	in_chamber.OnFired()
	in_chamber.yo = targloc.y - curloc.y
	in_chamber.xo = targloc.x - curloc.x
	in_chamber.inaccurate = (istype(user.locked_to, /obj/structure/bed/chair/vehicle))
	if(projectile_color)
		in_chamber.apply_projectile_color(projectile_color)
	if(params)
		var/list/mouse_control = params2list(params)
		if(mouse_control["icon-x"])
			in_chamber.p_x = text2num(mouse_control["icon-x"])
		if(mouse_control["icon-y"])
			in_chamber.p_y = text2num(mouse_control["icon-y"])

	spawn()
		if(in_chamber)
			in_chamber.process()
	sleep(1)
	in_chamber = null

	update_icon()

	user.update_inv_hand(user.active_hand)

	if(defective && recoil && prob(3))
		var/throwturf = get_ranged_target_turf(user, pick(alldirs), 7)
		user.drop_item()
		user.visible_message("\The [src] jumps out of [user]'s hands!","\The [src] jumps out of your hands!")
		throw_at(throwturf, rand(3, 6), 3)
		return 1

	return 1
