#include <sourcemod>
#include <sdkhooks>
#include <sdktools>
#include <cstrike>
#include <cod>

new const String:PLUGIN_NAME[32] = "codclass_lekkizolnierz";
new const String:PLUGIN_AUTHOR[32] = "GieeF";
new const String:PLUGIN_VERSION[32] = "1.0";
new const String:PLUGIN_DESCRIPTION[64] = "Klasa COD - Lekki Żołnierz";
new const String:PLUGIN_URL[32] = "-";

new const String:class_name[32] = "Lekki Zolnierz";
new const String:class_description[][128] =  { "Brak", "Posiada strój przeciwnej drużyny", "Posiada strój przeciwnej drużyny. Nie słychać jego kroków", "Posiada strój przeciwnej drużyny. Nie słychać jego kroków. Ma 10% szans na odrodzenie się po śmierci", "chuj wi"};
new const String:class_weapons[][512] =  { "#weapon_galilar#weapon_fiveseven", "#weapon_galilar#weapon_fiveseven", "#weapon_galilar#weapon_fiveseven", "#weapon_galilar#weapon_fiveseven", "#weapon_galilar#weapon_fiveseven" };
new const class_intelligence[] =  { 0, 0, 0, 0, 0 };
new const class_health[] =  { 10, 10, 10, 10, 10 };
new const class_damage[] =  { 0, 0, 0, 0, 0 };
new const class_resistance[] =  { 10, 10, 10, 10, 10 };
new const class_trim[] =  { 0, 0, 0, 0, 0 };

new bool:player_hasClass[MAXPLAYERS];
new player_advance[MAXPLAYERS];

public Plugin:myinfo = {
	name = PLUGIN_NAME,
	author = PLUGIN_AUTHOR,
	description = PLUGIN_DESCRIPTION,
	version = PLUGIN_VERSION,
	url = PLUGIN_URL
};

new String:models[][] = {
	"models/player/ctm_fbi.mdl", "models/player/ctm_gign.mdl", "models/player/ctm_gsg9.mdl", "models/player/ctm_sas.mdl", "models/player/ctm_st6.mdl",
	"models/player/tm_anarchist.mdl", "models/player/tm_phoenix.mdl", "models/player/tm_pirate.mdl", "models/player/tm_balkan_variantA.mdl", "models/player/tm_leet_variantA.mdl"
};

public OnPluginStart() {
	HookEvent("player_death", PlayerDeath);
	HookEvent("player_spawn", PlayerSpawn);
	AddNormalSoundHook(PlayerSound);
}

public OnAllPluginsLoaded() {
	CreateTimer(0.3, RegisterStart, 0);
}

public OnMapStart() {
	for(new i = 0; i < sizeof(models); i++) {
		PrecacheModel(models[i]);
	}
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

public Action:PlayerDeath(Handle:event, String:name[], bool:dontBroadcast) {
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(!IsValidClient(client) || !IsPlayerAlive(client)) {
		return Plugin_Continue;
	}
	
	if(!player_hasClass[client] || player_advance[client] < 4) {
		return Plugin_Continue;
	}
	
	if(GetRandomInt(1, 10) == 1) {
		CreateTimer(0.1, Respawn, client, TIMER_FLAG_NO_MAPCHANGE);
	}
	return Plugin_Continue;
}

public Action:PlayerSpawn(Handle:event, String:name[], bool:dontBroadcast) {
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(!IsValidClient(client)) {
		return Plugin_Continue;
	}
	
	if(!player_hasClass[client] || player_advance[client] < 1) {
		return Plugin_Continue;
	}
	
	SetEntityModel(client, (GetClientTeam(client) == CS_TEAM_T)? models[GetRandomInt(0, 4)]: models[GetRandomInt(5, 9)]);
	return Plugin_Continue;
}

public Action:PlayerSound(clients[64], &numclients, String:sample[PLATFORM_MAX_PATH], &entity, &channel, &Float:volume, &level, &pitch, &flags) {
	if(!IsValidClient(entity)) {
		return Plugin_Continue;
	}
	
	if((StrContains(sample, "physics") != -1 || StrContains(sample, "footsteps") != -1) && StrContains(sample, "suit") == -1) {
		if(!(player_hasClass[entity] && player_advance[entity] < 2)) {
			EmitSoundToAll(sample, entity);
		}
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

public Action:Respawn(Handle:timer, client) {
	if(!IsValidClient(client)) {
		return Plugin_Continue;
	}

	CS_RespawnPlayer(client);
	return Plugin_Continue;
}