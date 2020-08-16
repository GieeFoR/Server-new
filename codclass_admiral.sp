#include <sourcemod>
#include <sdkhooks>
#include <sdktools>
#include <cod>

new const String:PLUGIN_NAME[32] = "codclass_admiral";
new const String:PLUGIN_AUTHOR[32] = "GieeF";
new const String:PLUGIN_VERSION[32] = "1.0";
new const String:PLUGIN_DESCRIPTION[64] = "Klasa COD - Admirał";
new const String:PLUGIN_URL[32] = "-";

new const String:class_name[] = "Admirał";
new const String:class_description[][] =  { "Dostaje 10HP za kazde zabojstwo", "Dostaje 20HP za każde zabójstwo. Ma podwójny skok", "Dostaje 20HP oraz pełen magazynek za każde zabójstwo. Ma podwójny skok", "Dostaje 20HP oraz pełen magazynek za każde zabójstwo. Ma podwójny skok +??", "Dostaje 20HP oraz pełen magazynek za każde zabójstwo. Ma podwójny skok +????"};
new const String:class_weapons[][] =  { "#weapon_famas#weapon_glock", "#weapon_famas#weapon_glock", "#weapon_famas#weapon_glock", "#weapon_famas#weapon_glock", "#weapon_famas#weapon_glock" };
new const class_intelligence[] =  	{ 0, 	0, 		0, 		0, 		0 };
new const class_health[] =  		{ 30, 	30, 	30, 	30, 	30 };
new const class_damage[] =  		{ 0, 	0, 		0, 		0, 		0 };
new const class_resistance[] =  	{ 0, 	20, 	20, 	20, 	0 };
new const class_trim[] =  			{ 0, 	38, 	38, 	38, 	0 };

new bool:player_hasClass[MAXPLAYERS];
new player_advance[MAXPLAYERS];

new String:weaponsName[][] = {
	"weapon_glock", "weapon_usp_silencer", "weapon_hkp2000", "weapon_p250", "weapon_tec9", "weapon_fiveseven", "weapon_cz75a", "weapon_deagle",
	"weapon_revolver", "weapon_elite", "weapon_m4a1_silencer", "weapon_ak47", "weapon_awp", "weapon_m4a1", "weapon_negev", "weapon_famas",
	"weapon_aug", "weapon_p90", "weapon_nova", "weapon_xm1014", "weapon_mag7", "weapon_mac10", "weapon_mp7", "weapon_mp9", "weapon_bizon",
	"weapon_ump45", "weapon_galilar", "weapon_ssg08", "weapon_sg556", "weapon_m249", "weapon_scar20", "weapon_g3sg1", "weapon_sawedoff"
};
new weaponsAmmo[][2] = {
	{20, 120}, {12, 24}, {13, 52}, {13, 26}, {32, 120}, {20, 100}, {12, 12}, {7, 35}, {8, 8}, {30, 120}, {20, 40}, {30, 90}, {10, 30}, {30, 90}, {150, 200}, {25, 90}, {30, 90},
	{50, 100}, {8, 32}, {7, 32}, {5, 32}, {30, 100}, {30, 120}, {30, 120}, {64, 120}, {25, 100}, {35, 90}, {10, 90}, {30, 90}, {100, 200}, {20, 90}, {20, 90}, {7, 32}
};

public Plugin:myinfo = {
	name = PLUGIN_NAME,
	author = PLUGIN_AUTHOR,
	description = PLUGIN_DESCRIPTION,
	version = PLUGIN_VERSION,
	url = PLUGIN_URL
};

public OnAllPluginsLoaded() {
	CreateTimer(0.1, RegisterStart, 0);
}

public OnPluginStart() {
	HookEvent("player_death", PlayerDeath);
}

public OnPluginEnd() {
	UnhookEvent("player_death", PlayerDeath);
}

public cod_classEnabled(client, advance) {
	player_hasClass[client] = true;
	player_advance[client] = advance;
}

public cod_classDisabled(client) {
	player_hasClass[client] = false;
	player_advance[client] = 0;
}

public Action:RegisterStart(Handle:timer) {
	cod_registerClass(class_name, class_description[0], class_description[1], class_description[2], class_description[3], class_description[4], class_weapons[0], class_weapons[1], class_weapons[2], class_weapons[3], class_weapons[4], class_intelligence, class_health, class_damage, class_resistance, class_trim);
}

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapons) {
	if(!IsValidClient(client)) {
		return Plugin_Continue;
	}
	
	if(!IsPlayerAlive(client)) {
		return Plugin_Continue;
	}
	
	if(!player_hasClass[client] || player_advance[client] < 1) {
		return Plugin_Continue;
	}
	
	static bool:oldbuttons[65];
	if(!oldbuttons[client] && buttons & IN_JUMP) {
		static bool:multijump[65];
		new flags = GetEntityFlags(client);
		if(!(flags & FL_ONGROUND) && !multijump[client]) {
			new Float:forigin[3];
			GetEntPropVector(client, Prop_Data, "m_vecVelocity", forigin);
			forigin[2] += 250.0;
			TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, forigin);
			multijump[client] = true;
		}
		else if(flags & FL_ONGROUND) {
			multijump[client] = false;
		}
		
		oldbuttons[client] = true;
	}
	else if(oldbuttons[client] && !(buttons & IN_JUMP)) {
		oldbuttons[client] = false;
	}
	return Plugin_Continue;
}

public Action:PlayerDeath(Handle:event, String:name[], bool:dontBroadcast) {
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new killer = GetClientOfUserId(GetEventInt(event, "attacker"));
	if(!IsValidClient(client) || !IsValidClient(killer)) {
		return Plugin_Continue;
	}

	if(!IsPlayerAlive(killer)) {
		return Plugin_Continue;
	}
	
	if(!player_hasClass[killer]) {
		return Plugin_Continue;
	}
	
	if(GetClientTeam(client) == GetClientTeam(killer)) {
		return Plugin_Continue;
	}
	
	new killerHealth = GetClientHealth(killer);
	new killerMaxHealth = cod_getPlayerMaxHealth(killer);
	new bonusHealth;
	
	if(player_advance[killer] == 0) {
		bonusHealth = 10;
		SetEntData(killer, FindDataMapInfo(killer, "m_iHealth"), (killerHealth+bonusHealth < killerMaxHealth)? killerHealth+bonusHealth: killerMaxHealth);
	}
	else if(player_advance[killer] == 1) {
		bonusHealth = 20;
		SetEntData(killer, FindDataMapInfo(killer, "m_iHealth"), (killerHealth+bonusHealth < killerMaxHealth)? killerHealth+bonusHealth: killerMaxHealth);
	}
	else if(player_advance[killer] == 2) {
		bonusHealth = 20;
		SetEntData(killer, FindDataMapInfo(killer, "m_iHealth"), (killerHealth+bonusHealth < killerMaxHealth)? killerHealth+bonusHealth: killerMaxHealth);
		
		new activeWeapon = GetEntPropEnt(killer, Prop_Send, "m_hActiveWeapon");
		if(activeWeapon != -1) {
			new String:weapon[32];
			GetClientWeapon(killer, weapon, sizeof(weapon));
			for(new i = 0; i < sizeof(weaponsName); i++) {
				if(StrEqual(weapon, weaponsName[i])) {
					SetEntData(activeWeapon, FindSendPropInfo("CWeaponCSBase", "m_iClip1"), weaponsAmmo[i][0]);
					break;
				}
			}
		}
	}
	else if(player_advance[killer] == 3) {
		bonusHealth = 20;
		SetEntData(killer, FindDataMapInfo(killer, "m_iHealth"), (killerHealth+bonusHealth < killerMaxHealth)? killerHealth+bonusHealth: killerMaxHealth);
		
		new activeWeapon = GetEntPropEnt(killer, Prop_Send, "m_hActiveWeapon");
		if(activeWeapon != -1) {
			new String:weapon[32];
			GetClientWeapon(killer, weapon, sizeof(weapon));
			for(new i = 0; i < sizeof(weaponsName); i++) {
				if(StrEqual(weapon, weaponsName[i])) {
					SetEntData(activeWeapon, FindSendPropInfo("CWeaponCSBase", "m_iClip1"), weaponsAmmo[i][0]);
					break;
				}
			}
		}
	}
	else if(player_advance[killer] == 4) {
		bonusHealth = 20;
		SetEntData(killer, FindDataMapInfo(killer, "m_iHealth"), (killerHealth+bonusHealth < killerMaxHealth)? killerHealth+bonusHealth: killerMaxHealth);
		
		new activeWeapon = GetEntPropEnt(killer, Prop_Send, "m_hActiveWeapon");
		if(activeWeapon != -1) {
			new String:weapon[32];
			GetClientWeapon(killer, weapon, sizeof(weapon));
			for(new i = 0; i < sizeof(weaponsName); i++) {
				if(StrEqual(weapon, weaponsName[i])) {
					SetEntData(activeWeapon, FindSendPropInfo("CWeaponCSBase", "m_iClip1"), weaponsAmmo[i][0]);
					break;
				}
			}
		}
	}
	
	return Plugin_Continue;
}