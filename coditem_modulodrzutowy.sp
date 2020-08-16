#include <sourcemod>
#include <sdkhooks>
#include <sdktools>
#include <cod>

new const String:PLUGIN_NAME[32] = "coditem_modulodrzutowy";
new const String:PLUGIN_AUTHOR[32] = "GieeF";
new const String:PLUGIN_VERSION[32] = "1.0";
new const String:PLUGIN_DESCRIPTION[64] = "Item COD - Moduł Odrzutowy";
new const String:PLUGIN_URL[32] = "-";

new const String:item_name[] = "Moduł Odrzutowy";
new const String:item_description[] = "Posiadasz moduł odrzutowy który ładuje się co 4 sekundy";
new const String:item_weapons[] = "";
new const String:item_blackList[] = "#Komandos";
new const item_intelligence = 0;
new const item_health = 0;
new const item_damage = 0;
new const item_resistance = 0;
new const item_trim = 0;
new const item_minVal = 0;
new const item_maxVal = 0;

new bool:player_hasItem[MAXPLAYERS];
new Float:playerTime[MAXPLAYERS];

public Plugin:myinfo = {
	name = PLUGIN_NAME,
	author = PLUGIN_AUTHOR,
	description = PLUGIN_DESCRIPTION,
	version = PLUGIN_VERSION,
	url = PLUGIN_URL
};

public OnAllPluginsLoaded() {
	CreateTimer(1.4, RegisterStart, 0);
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

public cod_item_used(client) {
	if(!player_hasItem[client]) {
		return;
	}
	
	new Float:gametime = GetGameTime();
	if(gametime > playerTime[client]+4.0) {
		new Float:forigin[3];
		GetClientEyePosition(client, forigin);
		
		new Float:fangles[3];
		GetClientEyeAngles(client, fangles);
		
		new Float:iorigin[3], Float:iangles[3], Float:ivector[3];
		TR_TraceRayFilter(forigin, fangles, MASK_SOLID, RayType_Infinite, TraceRayFilter, client);
		TR_GetEndPosition(iorigin);
		MakeVectorFromPoints(forigin, iorigin, ivector);
		NormalizeVector(ivector, ivector);
		ScaleVector(ivector, 600.0);
		GetVectorAngles(ivector, iangles);
		
		TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, ivector);
		playerTime[client] = gametime;
	}
}

public bool:TraceRayFilter(ent, contents) {
	return false;
}