#include <sourcemod>
#include <sdkhooks>
#include <sdktools>
#include <cod>

new const String:PLUGIN_NAME[32] = "coditem_cichobiegi";
new const String:PLUGIN_AUTHOR[32] = "GieeF";
new const String:PLUGIN_VERSION[32] = "1.0";
new const String:PLUGIN_DESCRIPTION[64] = "Item COD - Cichobiegi";
new const String:PLUGIN_URL[32] = "-";

new const String:item_name[] = "Cichobiegi";
new const String:item_description[] = "Nie slychać twoich kroków";
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

public OnPluginStart() {
	AddNormalSoundHook(PlayerSounds);
}

public OnAllPluginsLoaded() {
	CreateTimer(0.8, RegisterStart, 0);
}

public OnClientPutInServer(client) {
	if(!IsValidClient(client)) {
		SendConVarValue(client, FindConVar("sv_footsteps"), "0"); //czy ok?
	}
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

public Action:PlayerSounds(clients[64], &numclients, String:sample[PLATFORM_MAX_PATH], &entity, &channel, &Float:volume, &level, &pitch, &flags) {
	if(!IsValidClient(entity)) {
		return Plugin_Continue;
	}
	
	if((StrContains(sample, "physics") != -1 || StrContains(sample, "footsteps") != -1) && StrContains(sample, "suit") == -1) {
		if(!player_hasItem[entity]) {
			EmitSoundToAll(sample, entity);
		}
		return Plugin_Handled;
	}
	return Plugin_Continue;
}