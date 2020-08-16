#include <sourcemod>
#include <sdkhooks>
#include <cod>

new const String:PLUGIN_NAME[32] = "coditem_szybkostrzelnosc";
new const String:PLUGIN_AUTHOR[32] = "GieeF";
new const String:PLUGIN_VERSION[32] = "1.0";
new const String:PLUGIN_DESCRIPTION[64] = "Item COD - Szybkostrzelność";
new const String:PLUGIN_URL[32] = "-";

new const String:item_name[] = "Szybkostrzelność";
new const String:item_description[] = "Posiadasz zwiekszoną szybkostrzelność broni o RNG procent";
new const String:item_weapons[] = "";
new const String:item_blackList[] = "";
new const item_intelligence = 0;
new const item_health = 0;
new const item_damage = 0;
new const item_resistance = 0;
new const item_trim = 0;
new const item_minVal = 20;
new const item_maxVal = 50;

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
	CreateTimer(3.0, RegisterStart, 0);
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

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapons) {
	if(!IsValidClient(client) || !player_hasItem[client]) {
		return Plugin_Continue;
	}
	
	if(!IsPlayerAlive(client)) {
		return Plugin_Continue;
	}
	
	if(buttons & IN_ATTACK) {
		new activeWeapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
		if(activeWeapon != -1) {
			new Float:gametime = GetGameTime();
			new Float:fattack = GetEntDataFloat(activeWeapon, FindSendPropInfo("CBaseCombatWeapon", "m_flNextPrimaryAttack"))-gametime;
			SetEntDataFloat(activeWeapon, FindSendPropInfo("CBaseCombatWeapon", "m_flNextPrimaryAttack"), (fattack/(player_itemValue[client]/100+1))+gametime);
		}
	}
	return Plugin_Continue;
}