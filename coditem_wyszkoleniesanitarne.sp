#include <sourcemod>
#include <sdkhooks>
#include <cod>

new const String:PLUGIN_NAME[32] = "coditem_wyszkoleniesanitarne";
new const String:PLUGIN_AUTHOR[32] = "GieeF";
new const String:PLUGIN_VERSION[32] = "1.0";
new const String:PLUGIN_DESCRIPTION[64] = "Item COD - Wyszkolenie Sanitarne";
new const String:PLUGIN_URL[32] = "-";

new const String:item_name[] = "Wyszkolenie Sanitarne";
new const String:item_description[] = "Regenerujesz RNG zdrowia, co 5 sekund";
new const String:item_weapons[] = "";
new const String:item_blackList[] = "";
new const item_intelligence = 0;
new const item_health = 0;
new const item_damage = 0;
new const item_resistance = 0;
new const item_trim = 0;
new const item_minVal = 5;
new const item_maxVal = 10;

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
	CreateTimer(3.8, RegisterStart, 0);
}

public Action:RegisterStart(Handle:timer) {
	cod_registerItem(item_name, item_description, item_weapons, item_blackList, item_minVal, item_maxVal, item_intelligence, item_health, item_damage, item_resistance, item_trim);
}

public cod_itemEnabled(client) {
	player_hasItem[client] = true;
	player_itemValue[client] = GetRandomInt(item_minVal, item_maxVal);
	CreateTimer(5.0, Regeneration, client, TIMER_REPEAT & TIMER_FLAG_NO_MAPCHANGE);
}

public cod_itemDisabled(client) {
	player_hasItem[client] = false;
	player_itemValue[client] = 0;
}

public Action:Regeneration(Handle:timer, client) {
	if(!IsValidClient(client) || !player_hasItem[client]) {
		return Plugin_Continue;
	}

	if(IsPlayerAlive(client)) {
		new playerHealth = GetClientHealth(client);
		new playerMaxHealth = cod_getPlayerMaxHealth(client);
		SetEntData(client, FindDataMapInfo(client, "m_iHealth"), (playerHealth+player_itemValue[client] < playerMaxHealth)? playerHealth+player_itemValue[client]: playerMaxHealth);
	}
	return Plugin_Continue;
}