#include <sourcemod>
#include <sdkhooks>
#include <sdktools>
#include <cod>

new const String:PLUGIN_NAME[32] = "codclass_komandos";
new const String:PLUGIN_AUTHOR[32] = "GieeF";
new const String:PLUGIN_VERSION[32] = "1.0";
new const String:PLUGIN_DESCRIPTION[64] = "Klasa COD - Komandos";
new const String:PLUGIN_URL[32] = "-";

new const String:class_name[32] = "Komandos";
new const String:class_description[][128] =  { "Posiada natychmiastowe zabicie z noza na [PPM]", "Posiada natychmiastowe zabicie z noża [PPM] oraz moduł odrzutowy (co 6 sekund)", "Posiada natychmiastowe zabicie z noża [PPM] oraz moduł odrzutowy (co 5 sekund) +??", "Posiada natychmiastowe zabicie z noża [PPM] oraz moduł odrzutowy (co 4 sekundy). Posiada AutoBH.", "chuj wi"};
new const String:class_weapons[][512] =  { "#weapon_deagle", "#weapon_deagle#weapon_flashbang#weapon_hegrenade", "#weapon_deagle#weapon_flashbang#weapon_hegrenade", "#weapon_deagle#weapon_flashbang#weapon_hegrenade", "#weapon_deagle#weapon_flashbang#weapon_hegrenade" };
new const class_intelligence[] =  { 0, 0, 0, 0, 0 };
new const class_health[] =  { 10, 10, 10, 10, 10 };
new const class_damage[] =  { 0, 0, 0, 0, 0 };
new const class_resistance[] =  { 20, 20, 20, 20, 20 };
new const class_trim[] =  { 30, 30, 30, 30, 30 };

new bool:player_hasClass[MAXPLAYERS];
new player_advance[MAXPLAYERS];

new WATER_LIMIT;
new bool:CSGO;
new Float:playerTime[MAXPLAYERS];

public Plugin:myinfo = {
	name = PLUGIN_NAME,
	author = PLUGIN_AUTHOR,
	description = PLUGIN_DESCRIPTION,
	version = PLUGIN_VERSION,
	url = PLUGIN_URL
};

public OnPluginStart() {
	new String:theFolder[40];
	GetGameFolderName(theFolder, sizeof(theFolder));
	CSGO = StrEqual(theFolder, "csgo");
	(CSGO) ? (WATER_LIMIT = 2) : (WATER_LIMIT = 1);
}

public OnAllPluginsLoaded() {
	CreateTimer(0.2, RegisterStart, 0);
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
	if((StrEqual(weapon, "weapon_bayonet") || StrContains(weapon, "weapon_knife", false) != -1) && damagetype & (DMG_SLASH|DMG_BULLET) && GetClientButtons(attacker) & IN_ATTACK2) {
		SDKHooks_TakeDamage(victim, attacker, attacker, float(1+GetClientHealth(victim)), DMG_GENERIC);
	}
	
	return Plugin_Continue;
}

public cod_classSkillUsed(client) {
	if(!player_hasClass[client] || player_advance[client] < 1) {
		return;
	}
	
	new Float:delay;
	switch(player_advance[client]) {
		case 1: { delay = 6.0; }
		case 2: { delay = 5.0; }
		case 3: { delay = 4.0; }
		case 4: { delay = 4.0; }
	}
	
	new Float:gametime = GetGameTime();
	if(gametime > playerTime[client]+delay) {
		new Float:forigin[3];
		GetClientEyePosition(client, forigin);

		new Float:fangles[3];
		GetClientEyeAngles(client, fangles);

		new Float:iorigin[3], Float:iangles[3], Float:ivector[3];
		TR_TraceRayFilter(forigin, fangles, MASK_SOLID, RayType_Infinite, TraceRayFilter, client);
		TR_GetEndPosition(iorigin);
		MakeVectorFromPoints(forigin, iorigin, ivector);
		NormalizeVector(ivector, ivector);
		ScaleVector(ivector, 600.0);
		GetVectorAngles(ivector, iangles);

		TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, ivector);
		playerTime[client] = gametime;
	}
}

public bool:TraceRayFilter(ent, contents) {
	return false;
}

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon) {
	if (!(IsPlayerAlive(client) && buttons & IN_JUMP)) {
		return Plugin_Continue;
	}
	
	if(!player_hasClass[client] || player_advance[client] < 4) {
		return Plugin_Continue;
	}
	
	if(!(GetEntityMoveType(client) & MOVETYPE_LADDER) && !(GetEntityFlags(client) & FL_ONGROUND)) {
		if(GetEntProp(client, Prop_Data, "m_nWaterLevel") < WATER_LIMIT) {
			buttons &= ~IN_JUMP; 
		}
	}
	
	return Plugin_Continue;
}