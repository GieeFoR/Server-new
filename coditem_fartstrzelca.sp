#include <sourcemod>
#include <sdkhooks>
#include <cod>

new const String:PLUGIN_NAME[32] = "coditem_fartstrzelca";
new const String:PLUGIN_AUTHOR[32] = "GieeF";
new const String:PLUGIN_VERSION[32] = "1.0";
new const String:PLUGIN_DESCRIPTION[64] = "Item COD - Fart Strzelca";
new const String:PLUGIN_URL[32] = "-";

new const String:item_name[] = "Fart Strzelca";
new const String:item_description[] = "Masz 1/RNG szans na natychmiastowe zabicie przeciwnika";
new const String:item_weapons[] = "";
new const String:item_blackList[] = "";
new const item_intelligence = 0;
new const item_health = 0;
new const item_damage = 0;
new const item_resistance = 0;
new const item_trim = 0;
new const item_minVal = 10;
new const item_maxVal = 15;

new bool:player_hasItem[MAXPLAYERS];
new player_itemValue[MAXPLAYERS];

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

public OnClientPutInServer(client) {
	SDKHook(client, SDKHook_OnTakeDamage, OnPlayerTakeDamage);
}

public OnClientDisconnect(client) {
	SDKUnhook(client, SDKHook_OnTakeDamage, OnPlayerTakeDamage);
}

public Action:OnPlayerTakeDamage(client, &attacker, &inflictor, &Float:damage, &damagetype) {
	if(!IsValidClient(attacker) || !player_hasItem[attacker]) {
		return Plugin_Continue;
	}
	
	if(!IsValidClient(client) || GetClientTeam(client) == GetClientTeam(attacker)) {
		return Plugin_Continue;
	}
	
	if(!(damagetype & DMG_BULLET)) { // czy ok?
		return Plugin_Continue;
	}
	
	if(GetRandomInt(1, player_itemValue[attacker]) == 1) {
		SDKHooks_TakeDamage(client, attacker, attacker, float(1+GetClientHealth(client)), DMG_BULLET);
	}
	
	return Plugin_Continue;
}