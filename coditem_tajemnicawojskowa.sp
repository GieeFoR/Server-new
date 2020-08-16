#include <sourcemod>
#include <sdkhooks>
#include <cod>

new const String:PLUGIN_NAME[32] = "coditem_tajemnicawojskowa";
new const String:PLUGIN_AUTHOR[32] = "GieeF";
new const String:PLUGIN_VERSION[32] = "1.0";
new const String:PLUGIN_DESCRIPTION[64] = "Item COD - Tajemnica Wojskowa";
new const String:PLUGIN_URL[32] = "-";

new const String:item_name[] = "Tajemnica Wojskowa";
new const String:item_description[] = "Posiadasz 1/RNG szans na oślepienie przeciwnika przy trafieniu";
new const String:item_weapons[] = "";
new const String:item_blackList[] = "";
new const item_intelligence = 0;
new const item_health = 0;
new const item_damage = 0;
new const item_resistance = 0;
new const item_trim = 0;
new const item_minVal = 3;
new const item_maxVal = 7;

new bool:player_hasItem[MAXPLAYERS];
new player_itemValue[MAXPLAYERS];

public Plugin:myinfo =  {
	name = PLUGIN_NAME, 
	author = PLUGIN_AUTHOR, 
	description = PLUGIN_DESCRIPTION, 
	version = PLUGIN_VERSION, 
	url = PLUGIN_URL
};

public OnAllPluginsLoaded() {
	CreateTimer(3.4, RegisterStart, 0);
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

public OnClientPutInServer(client) {
	SDKHook(client, SDKHook_OnTakeDamage, OnPlayerTakeDamage);
}

public OnClientDisconnect(client) {
	SDKUnhook(client, SDKHook_OnTakeDamage, OnPlayerTakeDamage);
}

public Action:OnPlayerTakeDamage(client, &attacker, &inflictor, &Float:damage, &damagetype) {
	if (!IsValidClient(attacker) || !player_hasItem[attacker]) {
		return Plugin_Continue;
	}
	
	if (!IsValidClient(client) || !IsPlayerAlive(client)) {
		return Plugin_Continue;
	}
	
	if (GetClientTeam(client) == GetClientTeam(attacker)) {
		return Plugin_Continue;
	}
	
	if (GetRandomInt(1, player_itemValue[attacker]) == 1) {
		PlayerBlind(client, 0, 255, 0, 128);
		CreateTimer(2.0, EndPlayerBlind, client);
	}
	
	return Plugin_Continue;
}

public Action:PlayerBlind(client, color1, color2, color3, alpha) {
	new clients[2];
	clients[0] = client;
	
	new color[4];
	color[0] = color1;
	color[1] = color2;
	color[2] = color3;
	color[3] = alpha;
	
	new flags;
	if (alpha) {
		flags = (0x0002 | 0x0008);
	}
	else {
		flags = (0x0001 | 0x0010);
	}
	
	new Handle:message = StartMessageEx(GetUserMessageId("Fade"), clients, 1);
	if (GetUserMessageType() == UM_Protobuf) {
		PbSetInt(message, "duration", 768);
		PbSetInt(message, "hold_time", 1536);
		PbSetInt(message, "flags", flags);
		PbSetColor(message, "clr", color);
	}
	else {
		BfWriteShort(message, 768);
		BfWriteShort(message, 1536);
		BfWriteShort(message, flags);
		BfWriteByte(message, color[0]);
		BfWriteByte(message, color[1]);
		BfWriteByte(message, color[2]);
		BfWriteByte(message, color[3]);
	}
	EndMessage();
}

public Action:EndPlayerBlind(Handle:timer, client) {
	if (!IsValidClient(client)) {
		return Plugin_Continue;
	}
	
	PlayerBlind(client, 0, 0, 0, 0);
	return Plugin_Continue;
} 