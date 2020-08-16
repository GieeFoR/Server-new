#include <sourcemod>
#include <sdkhooks>
#include <sdktools>
#include <cod>

new const String:PLUGIN_NAME[32] = "coditem_rozblysksloneczny";
new const String:PLUGIN_AUTHOR[32] = "GieeF";
new const String:PLUGIN_VERSION[32] = "1.0";
new const String:PLUGIN_DESCRIPTION[64] = "Item COD - Rozbłysk Słoneczny";
new const String:PLUGIN_URL[32] = "-";

new const String:item_name[] = "Rozbłysk Słoneczny";
new const String:item_description[] = "Po użyciu oślepiasz wszystkich przeciwników w pobliżu";
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
new bool:player_itemUsed[MAXPLAYERS];

new sprite_beam;
new sprite_halo;

public Plugin:myinfo = {
	name = PLUGIN_NAME,
	author = PLUGIN_AUTHOR,
	description = PLUGIN_DESCRIPTION,
	version = PLUGIN_VERSION,
	url = PLUGIN_URL
};

public OnPluginStart() {
	HookEvent("player_spawn", OnPlayerSpawn);
}

public OnAllPluginsLoaded() {
	CreateTimer(2.9, RegisterStart, 0);
}

public OnMapStart() {
	sprite_beam = PrecacheModel("sprites/laserbeam.vmt");
	sprite_halo = PrecacheModel("sprites/glow01.vmt");
}

public Action:RegisterStart(Handle:timer) {
	cod_registerItem(item_name, item_description, item_weapons, item_blackList, item_minVal, item_maxVal, item_intelligence, item_health, item_damage, item_resistance, item_trim);
}

public cod_itemEnabled(client) {
	player_hasItem[client] = true;
	player_itemUsed[client] = false;
}

public cod_itemDisabled(client) {
	player_hasItem[client] = false;
}

public cod_item_used(client) {
	if(player_itemUsed[client]) {
		PrintToChat(client, "Wykorzystałeś już moc swojego itemu!");
	}
	else {
		new Float:forigin[3], Float:iorigin[3];
		GetClientEyePosition(client, forigin);
		
		new Float:distance = 200.0;	//ew + intelligence
		for(new i = 1; i <= MaxClients; i++) {
			if(!IsClientInGame(i) || !IsPlayerAlive(i)) {
				continue;
			}
			
			if(GetClientTeam(client) == GetClientTeam(i)) {
				continue;
			}
			
			GetClientEyePosition(i, iorigin);
			if(GetVectorDistance(forigin, iorigin) <= distance) {
				PlayerBlind(i, 0, 255, 0, 128);
				CreateTimer(6.0, EndPlayerBlind, i);
			}
		}

		TE_SetupBeamRingPoint(forigin, 20.0, 200.0, sprite_beam, sprite_halo, 0, 10, 0.6, 6.0, 0.0, {0, 255, 0, 128}, 10, 0);
		TE_SendToAll();

		player_itemUsed[client] = true;
	}
}

public Action:OnPlayerSpawn(Handle:event, String:name[], bool:dontbroadcast) {
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(!IsValidClient(client) || !player_hasItem[client]) {
		return Plugin_Continue;
	}

	player_itemUsed[client] = false;
	return Plugin_Continue;
}

public Action:PlayerBlind(client, color1, color2, color3, alpha) {
	new String:playerClass[32];
	cod_getPlayerClass(client, playerClass, sizeof(playerClass));
	if(StrEqual(playerClass, "[Elite]Snajper+") || StrEqual(playerClass, "[Master]Snajper+") || StrEqual(playerClass, "[God]Snajper+")) {
		return Plugin_Continue;
	}
	
	new clients[2];
	clients[0] = client;
	
	new color[4];
	color[0] = color1;
	color[1] = color2;
	color[2] = color3;
	color[3] = alpha;

	new flags;
	if(alpha) {
		flags = (0x0002 | 0x0008);
	}
	else {
		flags = (0x0001 | 0x0010);
	}
	
	new Handle:message = StartMessageEx(GetUserMessageId("Fade"), clients, 1);
	if(GetUserMessageType() == UM_Protobuf) {
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
	return Plugin_Continue;
}

public Action:EndPlayerBlind(Handle:timer, client) {
	if(!IsValidClient(client)) {
		return Plugin_Continue;
	}
	
	PlayerBlind(client, 0, 0, 0, 0);
	return Plugin_Continue;
}