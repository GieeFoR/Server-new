#include <sourcemod>
#include <cod>

new const String:PLUGIN_NAME[32] = "coditem_apteczka";
new const String:PLUGIN_AUTHOR[32] = "GieeF";
new const String:PLUGIN_VERSION[32] = "1.0";
new const String:PLUGIN_DESCRIPTION[64] = "Item COD - Apteczka";
new const String:PLUGIN_URL[32] = "-";

new const String:item_name[] = "Apteczka";
new const String:item_description[] = "Leczy zdrowie do pełna raz na rundę";
new const String:item_weapons[] = "";
new const String:item_blackList[] = "#Medyk+";
new const item_intelligence = 0;
new const item_health = 0;
new const item_damage = 0;
new const item_resistance = 0;
new const item_trim = 0;
new const item_minVal = 0;
new const item_maxVal = 0;

new bool:player_hasItem[MAXPLAYERS];
new bool:itemUsed[MAXPLAYERS];

public Plugin:myinfo = {
	name = PLUGIN_NAME,
	author = PLUGIN_AUTHOR,
	description = PLUGIN_DESCRIPTION,
	version = PLUGIN_VERSION,
	url = PLUGIN_URL
};

public OnAllPluginsLoaded() {
	CreateTimer(0.2, RegisterStart, 0);
}

public Action:RegisterStart(Handle:timer) {
	cod_registerItem(item_name, item_description, item_weapons, item_blackList, item_minVal, item_maxVal, item_intelligence, item_health, item_damage, item_resistance, item_trim);
}

public OnPluginStart() {
	HookEvent("player_spawn", OnPlayerSpawn);
}

public cod_itemEnabled(client) {
	player_hasItem[client] = true;
	itemUsed[client] = false;
}

public cod_itemDisabled(client) {
	player_hasItem[client] = false;
}
 
public cod_itemUsed(client) {
	if(itemUsed[client]) {
		PrintToChat(client, "Wykorzystałeś już moc swojego itemu!");
	}
	else {
		new playerMaxHealth = cod_getPlayerMaxHealth(client);
		SetEntData(client, FindDataMapInfo(client, "m_iHealth"), playerMaxHealth);
		itemUsed[client] = true;
	}
}

public Action:OnPlayerSpawn(Handle:event, String:name[], bool:dontbroadcast) {
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(!IsValidClient(client) || !player_hasItem[client]) {
		return Plugin_Continue;
	}
	
	itemUsed[client] = false;
	return Plugin_Continue;
}