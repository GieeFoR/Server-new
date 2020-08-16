#include <sourcemod>
#include <sdkhooks>
#include <sdktools>
#include <cod>

new const String:PLUGIN_NAME[32] = "codclass_strzelecwyborowy";
new const String:PLUGIN_AUTHOR[32] = "GieeF";
new const String:PLUGIN_VERSION[32] = "1.0";
new const String:PLUGIN_DESCRIPTION[64] = "Klasa COD - Strzelec Wyborowy";
new const String:PLUGIN_URL[32] = "-";

new const String:class_name[] = "Strzelec Wyborowy";
new const String:class_description[][] =  { "Brak", "Zadaje obrazenia z AK47(+INT)", "Zadaje obrazenia z AK47(+INT). Regeneruje 5HP co 5 sekund", "Zadaje obrazenia z AK47(+INT). Regeneruje 5HP co 5 sekund. Ma 10% szans na oślepienie przeciwnika po trafieniu", "Zadaje obrazenia z AK47(+INT). Regeneruje 5HP co 5 sekund. Ma 10% szans na oślepienie przeciwnika po trafieniu+??"};
new const String:class_weapons[][] =  { "#weapon_ak47#weapon_fiveseven#weapon_flashbang#weapon_flashbang#weapon_hegranade#weapon_smokegrenade", "#weapon_ak47#weapon_fiveseven#weapon_flashbang#weapon_flashbang#weapon_hegranade#weapon_smokegrenade", "#weapon_ak47#weapon_fiveseven#weapon_flashbang#weapon_flashbang#weapon_hegranade#weapon_smokegrenade", "#weapon_ak47#weapon_fiveseven#weapon_flashbang#weapon_flashbang#weapon_hegranade#weapon_smokegrenade", "#weapon_ak47#weapon_fiveseven#weapon_flashbang#weapon_flashbang#weapon_hegranade#weapon_smokegrenade" };
new const class_intelligence[] =  	{ 0, 	0, 		0, 		0, 		0 };
new const class_health[] =  		{ 20, 	20, 	20, 	20, 	20 };
new const class_damage[] =  		{ 0, 	0, 		0, 		0, 		0 };
new const class_resistance[] =  	{ 20, 	20, 	20, 	20, 	20 };
new const class_trim[] =  			{ -20, 	-20, 	-20, 	-20, 	-20 };

new bool:player_hasClass[MAXPLAYERS];
new player_advance[MAXPLAYERS];

public Plugin:myinfo = {
	name = PLUGIN_NAME,
	author = PLUGIN_AUTHOR,
	description = PLUGIN_DESCRIPTION,
	version = PLUGIN_VERSION,
	url = PLUGIN_URL
};

public OnAllPluginsLoaded() {
	CreateTimer(0.8, RegisterStart, 0);
}

public OnClientPutInServer(client) {
	SDKHook(client, SDKHook_OnTakeDamage, OnPlayerTakeDamage);
}

public OnClientDisconnect(client) {
	SDKUnhook(client, SDKHook_OnTakeDamage, OnPlayerTakeDamage);
}

public cod_classEnabled(client, advance) {
	player_hasClass[client] = true;
	player_advance[client] = advance;
	
	if(player_advance[client] > 0) {
		CreateTimer(5.0, Regeneration, client, TIMER_REPEAT & TIMER_FLAG_NO_MAPCHANGE);
	}
}

public cod_classDisabled(client) {
	player_hasClass[client] = false;
	player_advance[client] = 0;
}

public Action:RegisterStart(Handle:timer) {
	cod_registerClass(class_name, class_description[0], class_description[1], class_description[2], class_description[3], class_description[4], class_weapons[0], class_weapons[1], class_weapons[2], class_weapons[3], class_weapons[4], class_intelligence, class_health, class_damage, class_resistance, class_trim);
}

public Action:OnPlayerTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype) {
	if(!IsValidClient(attacker)) {
		return Plugin_Continue;
	}
	
	if(!IsValidClient(victim) || GetClientTeam(victim) == GetClientTeam(attacker)) {
		return Plugin_Continue;
	}
	
	if(!player_hasClass[attacker] || player_advance[attacker] < 1) {
		return Plugin_Continue;
	}
	
	new String:weapon[32];
	GetClientWeapon(attacker, weapon, sizeof(weapon));
	if(StrEqual(weapon, "weapon_ak47") && damagetype & DMG_BULLET) {
		cod_inflictDamageWithIntelligence(victim, attacker, 0.5);
	}
	
	if(player_advance[attacker] > 3) {
		if(GetRandomInt(1, 10) == 1) {
			PlayerBlind(victim, 0, 255, 0, 128);
			CreateTimer(2.0, EndPlayerBlind_Timer, victim);
		}
	}
	
	return Plugin_Changed;
}

public Action:Regeneration(Handle:timer, client) {
	if(!IsValidClient(client) || !player_hasClass[client]) {
		return Plugin_Continue;
	}
	
	if(!IsPlayerAlive(client)) {
		return Plugin_Continue;
	}
	
	new playerHealth = GetClientHealth(client);
	new playerMaxHealth = cod_getPlayerMaxHealth(client);
	SetEntData(client, FindDataMapInfo(client, "m_iHealth"), (playerHealth+5 < playerMaxHealth)? playerHealth+5: playerMaxHealth);
	
	return Plugin_Continue;
}

public Action:PlayerBlind(client, color1, color2, color3, alpha) {
	new String:playerClass[32];
	cod_getPlayerClass(client, playerClass, sizeof(playerClass));
	if (StrEqual(playerClass, "[Master]Snajper+") || StrEqual(playerClass, "[God]Snajper+")) {
		return Plugin_Continue;
	}
	
	new String:playerItem[32];
	cod_getPlayerItem(client, playerItem, sizeof(playerItem));
	if (StrEqual(playerItem, "Ciemne Okulary")) {
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

public Action:EndPlayerBlind_Timer(Handle:timer, client) {
	if(!IsValidClient(client)) {
		return Plugin_Continue;
	}
	
	PlayerBlind(client, 0, 0, 0, 0);
	return Plugin_Continue;
}