#include <sourcemod>
#include <sdkhooks>
#include <sdktools>
#include <cod>

new const String:PLUGIN_NAME[32] = "codclass_snajper";
new const String:PLUGIN_AUTHOR[32] = "GieeF";
new const String:PLUGIN_VERSION[32] = "1.0";
new const String:PLUGIN_DESCRIPTION[64] = "Klasa COD - Snajper";
new const String:PLUGIN_URL[32] = "-";

new const String:class_name[] = "Snajper";
new const String:class_description[][] =  { "Zadaje obrazenia z AWP(+INT)", "Zadaje 140 procent obrażen z AWP(+inteligencja). Ma 1/3 na zabicie z noża[PPM]", "Zadaje 170 procent obrazen z AWP(+inteligencja). Ma 1/2 na zabicie z noża[PPM]. Ma pewne zabicie z zeusa.", "Zadaje 200 procent obrazen z AWP(+inteligencja). Ma pewne zabicie z zeusa i noża[PPM], oraz podwójny skok", "Zadaje 200 procent obrazen z AWP(+inteligencja). Ma pewne zabicie z zeusa i noża[PPM], oraz podwójny skok+????"};
new const String:class_weapons[][] =  { "#weapon_awp#weapon_glock", "#weapon_awp#weapon_p250", "#weapon_awp#weapon_elite", "#weapon_awp#weapon_elite", "#weapon_awp#weapon_elite" };
new const class_intelligence[] =  	{ 0, 	0, 		0, 		0, 		0 };
new const class_health[] =  		{ 10, 	20, 	20, 	20, 	20 };
new const class_damage[] =  		{ 0, 	0, 		0, 		0, 		0 };
new const class_resistance[] =  	{ 10, 	10, 	10, 	10, 	10 };
new const class_trim[] =  			{ 10, 	20, 	20, 	20, 	20 };

new bool:player_hasClass[MAXPLAYERS];
new player_advance[MAXPLAYERS];

public Plugin:myinfo = {
	name = PLUGIN_NAME,
	author = PLUGIN_AUTHOR,
	description = PLUGIN_DESCRIPTION,
	version = PLUGIN_VERSION,
	url = PLUGIN_URL
};

public OnAllPluginsLoaded() {
	CreateTimer(0.6, RegisterStart, 0);
}

public OnClientPutInServer(client) {
	SDKHook(client, SDKHook_OnTakeDamage, OnPlayerTakeDamage);
}

public OnClientDisconnect(client) {
	SDKUnhook(client, SDKHook_OnTakeDamage, OnPlayerTakeDamage);
}

public cod_classEnabled(client, advance) {
	player_hasClass[client] = true;
	player_advance[client] = advance;
}

public cod_classDisabled(client) {
	player_hasClass[client] = false;
	player_advance[client] = 0;
}

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapons) {
	if(!IsValidClient(client)) {
		return Plugin_Continue;
	}
	
	if(!IsPlayerAlive(client)) {
		return Plugin_Continue;
	}
	
	if(!player_hasClass[client] || player_advance[client] < 4) {
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

public Action:RegisterStart(Handle:timer) {
	cod_registerClass(class_name, class_description[0], class_description[1], class_description[2], class_description[3], class_description[4], class_weapons[0], class_weapons[1], class_weapons[2], class_weapons[3], class_weapons[4], class_intelligence, class_health, class_damage, class_resistance, class_trim);
}

public Action:OnPlayerTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype) {
	if(!IsValidClient(attacker)) {
		return Plugin_Continue;
	}
	
	if(!IsValidClient(victim)) {
		return Plugin_Continue;
	}
	
	if(!player_hasClass[attacker]) {
		return Plugin_Continue;
	}
	
	if(GetClientTeam(victim) == GetClientTeam(attacker)) {
		return Plugin_Continue;
	}
	
	new String:weapon[32];
	GetClientWeapon(attacker, weapon, sizeof(weapon));
	if(StrEqual(weapon, "weapon_awp") && damagetype & DMG_BULLET) {
		cod_inflictDamageWithIntelligence(victim, attacker, 0.5);
	}
	
	new chanceToKillWithKnife;
	if(player_advance[attacker] == 0) {
		return Plugin_Continue;
	}
	else if(player_advance[attacker] == 1) {
		chanceToKillWithKnife = 3;
		damage *= 1.4;
	}
	else if(player_advance[attacker] == 2){
		chanceToKillWithKnife = 2;
		damage *= 1.7;
	}
	else if(player_advance[attacker] >= 3){
		chanceToKillWithKnife = 1;
		damage *= 2;
	}
	
	if((StrEqual(weapon, "weapon_bayonet") || StrContains(weapon, "weapon_knife", false) != -1) && damagetype & (DMG_SLASH|DMG_BULLET) && GetClientButtons(attacker) & IN_ATTACK2) {
		if(GetRandomInt(1, chanceToKillWithKnife) == 1) {
			SDKHooks_TakeDamage(victim, attacker, attacker, float(1+GetClientHealth(victim)), DMG_GENERIC);
		}
	}
	
	if(player_advance[attacker] > 1) {
		if(StrEqual(weapon, "weapon_zeus") && damagetype & DMG_BULLET) {
			SDKHooks_TakeDamage(victim, attacker, attacker, float(1+GetClientHealth(victim)), DMG_GENERIC); //dmg type?
		}
	}
	return Plugin_Changed;
}