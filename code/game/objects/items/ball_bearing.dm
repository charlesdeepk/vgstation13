// /obj/item/ammo_storage/ball_ammo
// 	name = "ball bearing amo"
// 	desc = "Used to reduce friction in moving machines"
// 	icon = 'icons/obj/ammo.dmi'
// 	icon_state = "ball_bearing_mag"
// 	caliber = BALL
// 	max_ammo = 25
// 	exact = 0


/obj/item/ammo_casing/ball_bearing
	name = "ball bearing"
	caliber = BALL
	projectile_type = "/obj/item/projectile/bullet/ball_bearing"
	icon = 'icons/obj/projectiles.dmi'
	icon_state = "ball_bearing"
	item_state = "ball_bearing"
	

/obj/item/ammo_storage/magazine/ball_bearing
	name = "ball bearing magazine"
	caliber = BALL
	ammo_type = "/obj/item/ammo_casing/ball_bearing"
	icon = 'icons/obj/ammo.dmi'
	icon_state = "ball_bearing_mag"
	max_ammo = 25
	