#include <sourcemod>
#include <sdkhooks>
#include <cod>

new const String:PLUGIN_NAME[32] = "coditem_nabojekapitana";
new const String:PLUGIN_AUTHOR[32] = "GieeF";
new const String:PLUGIN_VERSION[32] = "1.0";
new const String:PLUGIN_DESCRIPTION[64] = "Item COD - Naboje Kapitana";
new const String:PLUGIN_URL[32] = "-";

new const String:item_name[] = "Naboje Kapitana";
new const String:item_description[] = "Dostajesz 40 obrażeń ale tracisz 30 życia";
new const String:item_weapons[] = "";
new const String:item_blackList[] = "";
new const item_intelligence = 0;
new const item_health = -30;
new const item_damage = 40;
new const item_resistance = 0;
new const item_trim = 0;
new const item_minVal = 0;
new const item_maxVal = 0;

public Plugin:myinfo = {
	name = PLUGIN_NAME,
	author = PLUGIN_AUTHOR,
	description = PLUGIN_DESCRIPTION,
	version = PLUGIN_VERSION,
	url = PLUGIN_URL
};

public OnAllPluginsLoaded() {
	CreateTimer(1.7, RegisterStart, 0);
}

public Action:RegisterStart(Handle:timer) {
	cod_registerItem(item_name, item_description, item_weapons, item_blackList, item_minVal, item_maxVal, item_intelligence, item_health, item_damage, item_resistance, item_trim);
}