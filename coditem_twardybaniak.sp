#include <sourcemod>
#include <sdkhooks>
#include <cod>

new const String:PLUGIN_NAME[32] = "coditem_twardybaniak";
new const String:PLUGIN_AUTHOR[32] = "GieeF";
new const String:PLUGIN_VERSION[32] = "1.0";
new const String:PLUGIN_DESCRIPTION[64] = "Item COD - Twardy Baniak";
new const String:PLUGIN_URL[32] = "-";

new const String:item_name[] = "Twardy Baniak";
new const String:item_description[] = "Jestes odporny na obrażenia otrzymywane w glowę";
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
new bool:headshot[MAXPLAYERS];

public Plugin:myinfo = {
	name = PLUGIN_NAME,
	author = PLUGIN_AUTHOR,
	description = PLUGIN_DESCRIPTION,
	version = PLUGIN_VERSION,
	url = PLUGIN_URL
};

public OnAllPluginsLoaded() {
	CreateTimer(3.6, RegisterStart, 0);
}

public Action:RegisterStart(Handle:timer) {
	cod_registerItem(item_name, item_description, item_weapons, item_blackList, item_minVal, item_maxVal, item_intelligence, item_health, item_damage, item_resistance, item_trim);
}

public cod_itemEnabled(client) {
	player_hasItem[client] = true;
}

public cod_itemDisabled(client) {
	player_hasItem[client] = false;
}

public OnClientPutInServer(client) {
	SDKHook(client, SDKHook_TraceAttack, TraceAttack);
	SDKHook(client, SDKHook_OnTakeDamage, OnPlayerTakeDamage);
}

public OnClientDisconnect(client) {
	SDKUnhook(client, SDKHook_TraceAttack, TraceAttack);
	SDKUnhook(client, SDKHook_OnTakeDamage, OnPlayerTakeDamage);
}

public Action:TraceAttack(client, &attacker, &inflictor, &Float:damage, &damagetype, &ammotype, hitbox, hitgroup) {
	if(!IsValidClient(client) || !player_hasItem[client]) {
		return Plugin_Continue;
	}
	
	if(!IsValidClient(attacker) || GetClientTeam(client) == GetClientTeam(attacker)) {
		return Plugin_Continue;
	}
	
	headshot[client] = (hitgroup == 1) ? true:false;
	return Plugin_Continue;
}

public Action:OnPlayerTakeDamage(client, &attacker, &inflictor, &Float:damage, &damagetype) {
	if(!IsValidClient(client) || !player_hasItem[client]) {
		return Plugin_Continue;
	}
	
	if(!IsValidClient(attacker) || GetClientTeam(client) == GetClientTeam(attacker)) {
		return Plugin_Continue;
	}
	
	if(headshot[client]) {
		return Plugin_Handled;
	}
	return Plugin_Continue;
}