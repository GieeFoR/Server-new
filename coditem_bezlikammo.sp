#include <sourcemod>
#include <sdkhooks>
#include <cod>

new const String:PLUGIN_NAME[32] = "coditem_bezlikammo";
new const String:PLUGIN_AUTHOR[32] = "GieeF";
new const String:PLUGIN_VERSION[32] = "1.0";
new const String:PLUGIN_DESCRIPTION[64] = "Item COD - Bezlik Ammo";
new const String:PLUGIN_URL[32] = "-";

new const String:item_name[] = "Bezlik Ammo";
new const String:item_description[] = "Posiadasz nieskonczoną ilość naboi w magazynku";
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
	CreateTimer(0.5, RegisterStart, 0);
}

public Action:RegisterStart(Handle:timer) {
	cod_registerItem(item_name, item_description, item_weapons, item_blackList, item_minVal, item_maxVal, item_intelligence, item_health, item_damage, item_resistance, item_trim);
}

public OnPluginStart() {
	HookEvent("bullet_impact", OnPlayerShoot);
}

public cod_itemEnabled(client) {
	player_hasItem[client] = true;
}

public cod_itemDisabled(client) {
	player_hasItem[client] = false;
}

public Action:OnPlayerShoot(Handle:event, String:name[], bool:dontbroadcast) {
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(!IsValidClient(client) || !player_hasItem[client]) {
		return Plugin_Continue;
	}
	
	new activeWeapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
	if(activeWeapon != -1) {
		SetEntData(activeWeapon, FindSendPropInfo("CWeaponCSBase", "m_iClip1"), 5);
	}
	return Plugin_Continue;
}