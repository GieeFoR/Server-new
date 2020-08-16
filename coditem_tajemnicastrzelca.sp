#include <sourcemod>
#include <sdkhooks>
#include <cod>

new const String:PLUGIN_NAME[32] = "coditem_tajemnicastrzelca";
new const String:PLUGIN_AUTHOR[32] = "GieeF";
new const String:PLUGIN_VERSION[32] = "1.0";
new const String:PLUGIN_DESCRIPTION[64] = "Item COD - Tajemnica Strzelca";
new const String:PLUGIN_URL[32] = "-";

new const String:item_name[] = "Tajemnica Strzelca";
new const String:item_description[] = "Dostajesz AK47 oraz 5(+INT) obrażeń z niego";
new const String:item_weapons[] = "#weapon_ak47";
new const String:item_blackList[] = "#Strzelec Wyborowy";
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
	CreateTimer(3.3, RegisterStart, 0);
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
	
	new String:weapon[32];
	GetClientWeapon(attacker, weapon, sizeof(weapon));
	if(StrEqual(weapon, "weapon_ak47") && damagetype & DMG_BULLET) {
		SDKHooks_TakeDamage(client, attacker, attacker, 5.0, DMG_GENERIC);
		cod_inflictDamageWithIntelligence(client, attacker, 0.2);
	}
	return Plugin_Continue;
}