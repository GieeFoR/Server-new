#include <sourcemod>
#include <sdkhooks>
#include <sdktools>
#include <cod>

new const String:PLUGIN_NAME[32] = "coditem_autodestrukcja";
new const String:PLUGIN_AUTHOR[32] = "GieeF";
new const String:PLUGIN_VERSION[32] = "1.0";
new const String:PLUGIN_DESCRIPTION[64] = "Item COD - Autodestrukcja";
new const String:PLUGIN_URL[32] = "-";

new const String:item_name[] = "Autodestrukcja";
new const String:item_description[] = "Wybuchasz po śmierci zabijając wszystkich przeciwników w pobliżu";
new const String:item_weapons[] = "";
new const String:item_blackList[] = "";
new const item_intelligence = 0;
new const item_health = 0;
new const item_damage = 0;
new const item_resistance = 0;
new const item_trim = 0;
new const item_minVal = 0;
new const item_maxVal = 0;

new bool:player_hasItem[MAXPLAYERS];

new sprite_explosion;

public Plugin:myinfo = {
	name = PLUGIN_NAME,
	author = PLUGIN_AUTHOR,
	description = PLUGIN_DESCRIPTION,
	version = PLUGIN_VERSION,
	url = PLUGIN_URL
};

public OnAllPluginsLoaded() {
	CreateTimer(0.3, RegisterStart, 0);
}

public Action:RegisterStart(Handle:timer) {
	cod_registerItem(item_name, item_description, item_weapons, item_blackList, item_minVal, item_maxVal, item_intelligence, item_health, item_damage, item_resistance, item_trim);
}

public OnPluginStart() {
	HookEvent("player_death", OnPlayerDeath);
}

public OnMapStart() {
	sprite_explosion = PrecacheModel("materials/sprites/blueflare1.vmt");
	PrecacheSound("weapons/hegrenade/explode5.wav");
}

public cod_itemEnabled(client) {
	player_hasItem[client] = true;
}

public cod_itemDisabled(client) {
	player_hasItem[client] = false;
}

public Action:OnPlayerDeath(Handle:event, String:name[], bool:dontbroadcast) {
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new killer = GetClientOfUserId(GetEventInt(event, "attacker"));
	if(!IsValidClient(client) || !player_hasItem[client]) {
		return Plugin_Continue;
	}
	
	if(!IsValidClient(killer) || GetClientTeam(client) == GetClientTeam(killer)) {
		return Plugin_Continue;
	}
	
	new Float:forigin[3], Float:iorigin[3];
	GetClientEyePosition(client, forigin);
	for(new i = 1; i <= MaxClients; i++) {
		if(!IsClientInGame(i) || !IsPlayerAlive(i)) {
			continue;
		}
		
		if(GetClientTeam(client) == GetClientTeam(i)) {
			continue;
		}
		
		GetClientEyePosition(i, iorigin);
		//if(GetVectorDistance(forigin, iorigin) <= 100.0) {
		//	SDKHooks_TakeDamage(i, client, client, float(1+GetClientHealth(i)), DMG_GENERIC);
		//}
		new Float:distance = GetVectorDistance(forigin, iorigin);
		if(distance <= 20.0) {
			SDKHooks_TakeDamage(i, client, client, float(1+GetClientHealth(i)), DMG_GENERIC);
		}
		else if(distance <= 250.0) {
			SDKHooks_TakeDamage(i, client, client, (10000 / distance), DMG_GENERIC);
		}
	}

	EmitSoundToAll("weapons/hegrenade/explode5.wav", client, SNDCHAN_AUTO, SNDLEVEL_GUNFIRE);
	TE_SetupExplosion(forigin, sprite_explosion, 10.0, 1, 0, 100, 100);
	TE_SendToAll();

	return Plugin_Continue;
}