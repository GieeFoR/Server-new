#include <sourcemod>
#include <cod>

new const String:PLUGIN_NAME[32] = "coditem_adrenalina";
new const String:PLUGIN_AUTHOR[32] = "GieeF";
new const String:PLUGIN_VERSION[32] = "1.0";
new const String:PLUGIN_DESCRIPTION[64] = "Item COD - Adrenalina";
new const String:PLUGIN_URL[32] = "-";

new const String:item_name[] = "Adrenalina";
new const String:item_description[] = "Za każde zabójstwo regenerujesz 30HP + 10HP za zabicie w głowę";
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

public Plugin:myinfo = {
	name = PLUGIN_NAME,
	author = PLUGIN_AUTHOR,
	description = PLUGIN_DESCRIPTION,
	version = PLUGIN_VERSION,
	url = PLUGIN_URL
};

public OnAllPluginsLoaded() {
	CreateTimer(0.1, RegisterStart, 0);
}

public Action:RegisterStart(Handle:timer) {
	cod_registerItem(item_name, item_description, item_weapons, item_blackList, item_minVal, item_maxVal, item_intelligence, item_health, item_damage, item_resistance, item_trim);
}

public OnPluginStart() {
	HookEvent("player_death", OnPlayerDeath);
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
	if(!IsValidClient(killer) || !IsPlayerAlive(killer) || !player_hasItem[killer]) {
		return Plugin_Continue;
	}
	
	if(!IsValidClient(client) || GetClientTeam(client) == GetClientTeam(killer)) {
		return Plugin_Continue;
	}
	
	new bool:headshot = GetEventBool(event, "headshot");
	
	new playerHealth = GetClientHealth(killer);
	new playerMaxHealth = cod_getPlayerMaxHealth(killer);
	
	if(headshot) {
		SetEntData(killer, FindDataMapInfo(killer, "m_iHealth"), (playerHealth+40 < playerMaxHealth)? playerHealth+40: playerMaxHealth);
	}
	else {
		SetEntData(killer, FindDataMapInfo(killer, "m_iHealth"), (playerHealth+30 < playerMaxHealth)? playerHealth+30: playerMaxHealth);
	}
	return Plugin_Continue;
}