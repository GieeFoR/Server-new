#include <sourcemod>
#include <cod>

new const String:PLUGIN_NAME[32] = "coditem_butykomandosa";
new const String:PLUGIN_AUTHOR[32] = "GieeF";
new const String:PLUGIN_VERSION[32] = "1.0";
new const String:PLUGIN_DESCRIPTION[64] = "Item COD - Buty Komandosa";
new const String:PLUGIN_URL[32] = "-";

new const String:name[] = "Buty Komandosa";
new const String:description[] = "Dostajesz 60 punktów kondycji";
new const String:weapons[] = "";
new const String:blackList[] = "#Komandos";
new const intelligence = 0;
new const health = 0;
new const damage = 0;
new const resistance = 0;
new const trim = 60;

public Plugin:myinfo = {
	name = PLUGIN_NAME,
	author = PLUGIN_AUTHOR,
	description = PLUGIN_DESCRIPTION,
	version = PLUGIN_VERSION,
	url = PLUGIN_URL
};

public OnAllPluginsLoaded() {
	CreateTimer(0.6, RegisterStart, 0);
}

public Action:RegisterStart(Handle:timer) {
	cod_registerItem(name, description, weapons, blackList, 0, 0, intelligence, health, damage, resistance, trim);
}