#include <sourcemod>
#include <sdkhooks>
#include <cod>

new const String:PLUGIN_NAME[32] = "coditem_taktycznenaboje";
new const String:PLUGIN_AUTHOR[32] = "GieeF";
new const String:PLUGIN_VERSION[32] = "1.0";
new const String:PLUGIN_DESCRIPTION[64] = "Item COD - Taktyczne Naboje";
new const String:PLUGIN_URL[32] = "-";

new const String:item_name[] = "Taktyczne Naboje";
new const String:item_description[] = "Posiadasz 1/RNG szans na opróżnienie magazynku przeciwnika";
new const String:item_weapons[] = "";
new const String:item_blackList[] = "";
new const item_intelligence = 0;
new const item_health = 0;
new const item_damage = 0;
new const item_resistance = 0;
new const item_trim = 0;
new const item_minVal = 4;
new const item_maxVal = 8;

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
	CreateTimer(3.5, RegisterStart, 0);
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
	
	if(!IsValidClient(client) || !IsPlayerAlive(client)) {
		return Plugin_Continue;
	}
	
	if(GetClientTeam(client) == GetClientTeam(attacker)) {
		return Plugin_Continue;
	}
	
	if(GetRandomInt(1, player_itemValue[attacker]) == 1) {
		new activeWeapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
		if(activeWeapon != -1) {
			SetEntData(activeWeapon, FindSendPropInfo("CWeaponCSBase", "m_iClip1"), 0);
		}
	}
	return Plugin_Continue;
}