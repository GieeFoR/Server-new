#include <sourcemod>
#include <sdkhooks>
#include <cstrike>
#include <cod>

new const String:PLUGIN_NAME[32] = "coditem_morfina";
new const String:PLUGIN_AUTHOR[32] = "GieeF";
new const String:PLUGIN_VERSION[32] = "1.0";
new const String:PLUGIN_DESCRIPTION[64] = "Item COD - Morfina";
new const String:PLUGIN_URL[32] = "-";

new const String:item_name[] = "Morfina";
new const String:item_description[] = "Posiadasz 1/RNG szans na ponowne odrodzenie się po śmierci";
new const String:item_weapons[] = "";
new const String:item_blackList[] = "";
new const item_intelligence = 0;
new const item_health = 0;
new const item_damage = 0;
new const item_resistance = 0;
new const item_trim = 0;
new const item_minVal = 3;
new const item_maxVal = 5;

new bool:player_hasItem[MAXPLAYERS];
new player_itemValue[MAXPLAYERS];

public Plugin:myinfo = {
	name = PLUGIN_NAME,
	author = PLUGIN_AUTHOR,
	description = PLUGIN_DESCRIPTION,
	version = PLUGIN_VERSION,
	url = PLUGIN_URL
};

public OnPluginStart() {
	HookEvent("player_death", OnPlayerDeath);
}

public OnAllPluginsLoaded() {
	CreateTimer(1.5, RegisterStart, 0);
}

public Action:RegisterStart(Handle:timer) {
	cod_registerItem(item_name, item_description, item_weapons, item_blackList, item_minVal, item_maxVal, item_intelligence, item_health, item_damage, item_resistance, item_trim);
}

public cod_itemEnabled(client) {
	player_hasItem[client] = true;
	player_itemValue[client] = GetRandomInt(item_minVal, item_maxVal);
}

public cod_itemDisabled(client) {
	player_hasItem[client] = false;
	player_itemValue[client] = 0;
}

public cod_returnItemValue(client) {
	return player_itemValue[client];
}

public Action:OnPlayerDeath(Handle:event, String:name[], bool:dontBroadcast) {
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new killer = GetClientOfUserId(GetEventInt(event, "attacker"));
	if(!IsValidClient(client) || !player_hasItem[client]) {
		return Plugin_Continue;
	}
	
	if(!IsValidClient(killer) || GetClientTeam(client) == GetClientTeam(killer)) {
		return Plugin_Continue;
	}
	
	if(GetRandomInt(1, player_itemValue[client]) == 1) {
		CreateTimer(0.1, Revive, client, TIMER_FLAG_NO_MAPCHANGE);
	}
	
	return Plugin_Continue;
}

public Action:Revive(Handle:timer, client) {
	if(!IsValidClient(client)) {
		return Plugin_Continue;
	}
	
	CS_RespawnPlayer(client);
	return Plugin_Continue;
}