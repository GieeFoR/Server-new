#include <sourcemod>
#include <sdkhooks>
#include <sdktools>
#include <cstrike>
#include <cod>

new const String:PLUGIN_NAME[32] = "coditem_podrecznikszpiega";
new const String:PLUGIN_AUTHOR[32] = "GieeF";
new const String:PLUGIN_VERSION[32] = "1.0";
new const String:PLUGIN_DESCRIPTION[64] = "Item COD - Podręcznik Szpiega";
new const String:PLUGIN_URL[32] = "-";

new const String:item_name[] = "Podręcznik Szpiega";
new const String:item_description[] = "Posiadasz 1/RNG szans na zadanie 50(+INT) obrażen więcej z granatu. Masz ubranie przeciwnika";
new const String:item_weapons[] = "#weapon_hegrenade";
new const String:item_blackList[] = "";
new const item_intelligence = 0;
new const item_health = 0;
new const item_damage = 0;
new const item_resistance = 0;
new const item_trim = 0;
new const item_minVal = 2;
new const item_maxVal = 3;

new bool:player_hasItem[MAXPLAYERS];
new player_itemValue[MAXPLAYERS];

new sprite_beam;
new sprite_halo;

new String:models[][] = {
	"models/player/ctm_fbi.mdl", "models/player/ctm_gign.mdl", "models/player/ctm_gsg9.mdl", "models/player/ctm_sas.mdl", "models/player/ctm_st6.mdl",
	"models/player/tm_anarchist.mdl", "models/player/tm_phoenix.mdl", "models/player/tm_pirate.mdl", "models/player/tm_balkan_variantA.mdl", "models/player/tm_leet_variantA.mdl"
};

public Plugin:myinfo = {
	name = PLUGIN_NAME,
	author = PLUGIN_AUTHOR,
	description = PLUGIN_DESCRIPTION,
	version = PLUGIN_VERSION,
	url = PLUGIN_URL
};

public OnPluginStart() {
	HookEvent("hegrenade_detonate", OnGrenadeExplosion);
	HookEvent("player_spawn", OnPlayerSpawn);
}

public OnMapStart() {
	for(new i = 0; i < sizeof(models); i ++) {
		PrecacheModel(models[i]);
	}
	sprite_beam = PrecacheModel("sprites/laserbeam.vmt");
	sprite_halo = PrecacheModel("sprites/glow01.vmt");
}

public OnAllPluginsLoaded() {
	CreateTimer(2.7, RegisterStart, 0);
}

public Action:RegisterStart(Handle:timer) {
	cod_registerItem(item_name, item_description, item_weapons, item_blackList, item_minVal, item_maxVal, item_intelligence, item_health, item_damage, item_resistance, item_trim);
}

public cod_itemEnabled(client) {
	player_hasItem[client] = true;
	player_itemValue[client] = GetRandomInt(item_minVal, item_maxVal);
	
	if(IsPlayerAlive(client)) {
		SetEntityModel(client, (GetClientTeam(client) == CS_TEAM_T)? models[GetRandomInt(0, 4)]: models[GetRandomInt(5, 9)]);
	}
}

public cod_itemDisabled(client) {
	player_hasItem[client] = false;
	player_itemValue[client] = 0;
	
	if(IsPlayerAlive(client)) {
		CS_UpdateClientModel(client);
	}
}

public Action:OnGrenadeExplosion(Handle:event, const String:name[], bool:dontBroadcast) {
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(!IsValidClient(client) || !player_hasItem[client]) {
		return Plugin_Continue;
	}
	
	if(GetRandomInt(1, player_itemValue[client]) == 1) {
		new Float:forigin[3], Float:iorigin[3];
		forigin[0] = GetEventFloat(event, "x");
		forigin[1] = GetEventFloat(event, "y");
		forigin[2] = GetEventFloat(event, "z");
		
		new Float:damage = 50.0;
		for(new i = 1; i <= MaxClients; i++) {
			if(!IsClientInGame(i) || !IsPlayerAlive(i)) {
				continue;
			}
			
			if(GetClientTeam(client) == GetClientTeam(i)) {
				continue;
			}
			
			GetClientEyePosition(i, iorigin);
			if(GetVectorDistance(forigin, iorigin) <= 200.0) {
				SDKHooks_TakeDamage(i, client, client, damage, DMG_GENERIC);
				cod_inflictDamageWithIntelligence(i, client, 0.5);	//czy to dziala
			}
		}
		
		TE_SetupBeamRingPoint(forigin, 20.0, 200.0, sprite_beam, sprite_halo, 0, 10, 0.6, 6.0, 0.0, {0, 255, 0, 128}, 10, 0);
		TE_SendToAll();
	}
	return Plugin_Continue;
}

public Action:OnPlayerSpawn(Handle:event, String:name[], bool:dontBroadcast) {
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(!IsValidClient(client) || !player_hasItem[client]) {
		return Plugin_Continue;
	}
	
	SetEntityModel(client, (GetClientTeam(client) == CS_TEAM_T)? models[GetRandomInt(0, 4)]: models[GetRandomInt(5, 9)]);
	return Plugin_Continue;
}