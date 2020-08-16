#include <sourcemod>
#include <sdkhooks>
#include <sdktools>
#include <cod>

new const String:PLUGIN_NAME[32] = "codclass_szturmowiec";
new const String:PLUGIN_AUTHOR[32] = "GieeF";
new const String:PLUGIN_VERSION[32] = "1.0";
new const String:PLUGIN_DESCRIPTION[64] = "Klasa COD - Szturmowiec";
new const String:PLUGIN_URL[32] = "-";

new const String:class_name[] = "Szturmowiec";
new const String:class_description[][] =  { "Brak", "Posiada obrażenia z granatu(+INT)", "Posiada obrażenia z granatu(+INT). Ma podwójny skok", "Posiada obrażenia z granatu(+INT). Ma podwójny skok. Ma 15% szans na odbicie pocisku", "Posiada obrażenia z granatu(+INT). Ma podwójny skok. Ma 15% szans na odbicie pocisku+??"};
new const String:class_weapons[][] =  { "#weapon_m4a4#weapon_glock#weapon_hegrenade#weapon_flashbang#weapon_flashbang#weapon_smokegrenade", "#weapon_m4a4#weapon_glock#weapon_hegrenade#weapon_flashbang#weapon_flashbang#weapon_smokegrenade", "#weapon_m4a4#weapon_glock#weapon_hegrenade#weapon_flashbang#weapon_flashbang#weapon_smokegrenade", "#weapon_m4a4#weapon_glock#weapon_hegrenade#weapon_flashbang#weapon_flashbang#weapon_smokegrenade", "#weapon_m4a4#weapon_glock#weapon_hegrenade#weapon_flashbang#weapon_flashbang#weapon_smokegrenade" };
new const class_intelligence[] =  	{ 0, 	0, 		0, 		0, 		0 };
new const class_health[] =  		{ 20, 	20, 	20, 	20, 	20 };
new const class_damage[] =  		{ 0, 	0, 		0, 		0, 		0 };
new const class_resistance[] =  	{ 15, 	15, 	15, 	15, 	15 };
new const class_trim[] =  			{ -10, 	-10, 	-10, 	-10, 	-10 };

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
	CreateTimer(0.9, RegisterStart, 0);
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
	
	if(!player_hasClass[client] || player_advance[client] < 2) {
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
	
	if(!IsValidClient(victim) || GetClientTeam(victim) == GetClientTeam(attacker)) {
		return Plugin_Continue;
	}
	
	if(!player_hasClass[attacker] || !player_hasClass[victim]) {
		return Plugin_Continue;
	}
	
	new bool:isReflected = false;
	if(player_advance[victim] > 3) {
		if(damagetype & DMG_BULLET) {
			if(GetRandomInt(1, 7) == 1) {
				SDKHooks_TakeDamage(victim, attacker, attacker, damage, damagetype);
				damage = 0.0;
				isReflected = true;
			}
		}
	}
	
	if(player_advance[attacker] < 1) {
		return Plugin_Continue;
	}
	
	new String:weapon[32];
	GetClientWeapon(attacker, weapon, sizeof(weapon));
	if(StrEqual(weapon, "weapon_hegrenade") && damagetype & DMG_BULLET) {
		if(isReflected) {
			cod_inflictDamageWithIntelligence(attacker, victim, 1.0);
		}
		else {
			cod_inflictDamageWithIntelligence(victim, attacker, 1.0);
		}
	}
	return Plugin_Changed;
}