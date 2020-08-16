#include <sourcemod>
#include <sdkhooks>
#include <cod>

new const String:PLUGIN_NAME[32] = "coditem_notatkikapitana";
new const String:PLUGIN_AUTHOR[32] = "GieeF";
new const String:PLUGIN_VERSION[32] = "1.0";
new const String:PLUGIN_DESCRIPTION[64] = "Item COD - Notatki Kapitana";
new const String:PLUGIN_URL[32] = "-";

new const String:item_name[] = "Notatki Kapitana";
new const String:item_description[] = "Odbijasz RNG pociski na rundę";
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
new player_itemValue[MAXPLAYERS];
new player_amountOfReflectedBullets[MAXPLAYERS];

public Plugin:myinfo = {
	name = PLUGIN_NAME,
	author = PLUGIN_AUTHOR,
	description = PLUGIN_DESCRIPTION,
	version = PLUGIN_VERSION,
	url = PLUGIN_URL
};

public OnPluginStart() {
	HookEvent("player_spawn", OnPlayerSpawn);
}

public OnAllPluginsLoaded() {
	CreateTimer(2.0, RegisterStart, 0);
}

public Action:RegisterStart(Handle:timer) {
	cod_registerItem(item_name, item_description, item_weapons, item_blackList, item_minVal, item_maxVal, item_intelligence, item_health, item_damage, item_resistance, item_trim);
}

public cod_itemEnabled(client) {
	player_hasItem[client] = true;
	player_itemValue[client] = GetRandomInt(item_minVal, item_maxVal);
	player_amountOfReflectedBullets[client] = player_itemValue[client];
}

public cod_itemDisabled(client) {
	player_hasItem[client] = false;
	player_itemValue[client] = 0;
	player_amountOfReflectedBullets[client] = player_itemValue[client];
}

public cod_returnItemValue(client) {
	return player_itemValue[client];
}

public OnClientPutInServer(client) {
	SDKHook(client, SDKHook_OnTakeDamage, OnPlayerTakeDamage);
}

public OnClientDisconnect(client) {
	SDKUnhook(client, SDKHook_OnTakeDamage, OnPlayerTakeDamage);
}

public Action:OnPlayerTakeDamage(client, &attacker, &inflictor, &Float:damage, &damagetype) {
	if(!IsValidClient(client) || !player_hasItem[client]) {
		return Plugin_Continue;
	}
	
	if(!IsValidClient(attacker) || GetClientTeam(client) == GetClientTeam(attacker)) {
		return Plugin_Continue;
	}
	
	if(player_amountOfReflectedBullets[client]) {
		player_amountOfReflectedBullets[client]--;
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

public Action:OnPlayerSpawn(Handle:event, String:name[], bool:dontBroadcast) {
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(!IsValidClient(client) || !player_hasItem[client]) {
		return Plugin_Continue;
	}
	
	player_amountOfReflectedBullets[client] = player_itemValue[client];
	return Plugin_Continue;
}