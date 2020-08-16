#include <sourcemod>
#include <sdkhooks>
#include <sdktools>
#include <cod>

new const String:PLUGIN_NAME[32] = "codclass_snajperplus";
new const String:PLUGIN_AUTHOR[32] = "GieeF";
new const String:PLUGIN_VERSION[32] = "1.0";
new const String:PLUGIN_DESCRIPTION[64] = "Klasa COD - Snajper+";
new const String:PLUGIN_URL[32] = "-";

new const String:class_name[] = "Snajper+";
new const String:class_description[][] =  { "Zadaje 130 procent obrazen z AWP(+INT)", "Zadaje 160 procent obrazen z AWP(+inteligencja). Posiada podwójny skok", "Zadaje 200 procent obrazen z AWP(+inteligencja). Posiada podwójny skok. Nie może zostać oślepiony", "Zadaje 200 procent obrazen z AWP(+inteligencja). Posiada podwójny skok. Nie może zostać oślepiony. +??", "Zadaje 200 procent obrazen z AWP(+inteligencja). Posiada podwójny skok. Nie może zostać oślepiony. +????"};
new const String:class_weapons[][] =  { "#weapon_awp#weapon_deagle", "#weapon_awp#weapon_elite", "#weapon_awp#weapon_elite", "#weapon_awp#weapon_elite", "#weapon_awp#weapon_elite" };
new const class_intelligence[] =  	{ 5, 	5, 		5, 		5, 		5 };
new const class_health[] =  		{ 20, 	20, 	20, 	20, 	20 };
new const class_damage[] =  		{ 0, 	0, 		0, 		0, 		0 };
new const class_resistance[] =  	{ 20, 	20, 	20, 	20, 	20 };
new const class_trim[] =  			{ 20, 	20, 	20, 	20, 	20 };

new bool:player_hasClass[MAXPLAYERS];
new player_advance[MAXPLAYERS];

new g_iFlashAlpha = -1;
new g_iFlashDuration = -1;

public Plugin:myinfo = {
	name = PLUGIN_NAME,
	author = PLUGIN_AUTHOR,
	description = PLUGIN_DESCRIPTION,
	version = PLUGIN_VERSION,
	url = PLUGIN_URL
};

public OnPluginStart() {
	HookEvent("player_blind", OnPlayerBlind);
	
	g_iFlashDuration = FindSendPropInfo("CCSPlayer", "m_flFlashDuration")
	g_iFlashAlpha = FindSendPropInfo("CCSPlayer", "m_flFlashMaxAlpha")
	if (g_iFlashDuration == -1){
		SetFailState("Failed to find CCSPlayer::m_flFlashDuration offset");
	}
	
	if (g_iFlashAlpha == -1) {
		SetFailState("Failed to find CCSPlayer::m_flFlashMaxAlpha offset");
	}
}

public OnAllPluginsLoaded() {
	CreateTimer(0.7, RegisterStart, 0);
}

public OnClientPutInServer(client) {
	SDKHook(client, SDKHook_OnTakeDamage, OnPlayerTakeDamage);
}

public OnClientDisconnect(client) {
	SDKUnhook(client, SDKHook_OnTakeDamage, OnPlayerTakeDamage);
}

public cod_classEnabled(client, advance) {
	if(GetUserFlagBits(client) & ADMFLAG_CUSTOM1) {
		player_hasClass[client] = true;
		player_advance[client] = advance;
	}
	PrintToChat(client, "Nie masz dostępu do tej klasy premium");
	return COD_STOP;
}

public cod_classDisabled(client) {
	player_hasClass[client] = false;
	player_advance[client] = 0;
}

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapons) {
	if(!IsValidClient(client)) {
		return Plugin_Continue;
	}
	
	if(!IsPlayerAlive(client)) {
		return Plugin_Continue;
	}
	
	if(!player_hasClass[client] || player_advance[client] < 1) {
		return Plugin_Continue;
	}
	
	static bool:oldbuttons[65];
	if(!oldbuttons[client] && buttons & IN_JUMP) {
		static bool:multijump[65];
		new flags = GetEntityFlags(client);
		if(!(flags & FL_ONGROUND) && !multijump[client]) {
			new Float:forigin[3];
			GetEntPropVector(client, Prop_Data, "m_vecVelocity", forigin);
			forigin[2] += 250.0;
			TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, forigin);
			multijump[client] = true;
		}
		else if(flags & FL_ONGROUND) {
			multijump[client] = false;
		}
		
		oldbuttons[client] = true;
	}
	else if(oldbuttons[client] && !(buttons & IN_JUMP)) {
		oldbuttons[client] = false;
	}
	return Plugin_Continue;
}

public Action:RegisterStart(Handle:timer) {
	cod_registerClass(class_name, class_description[0], class_description[1], class_description[2], class_description[3], class_description[4], class_weapons[0], class_weapons[1], class_weapons[2], class_weapons[3], class_weapons[4], class_intelligence, class_health, class_damage, class_resistance, class_trim);
}

public Action:OnPlayerTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype) {
	if(!IsValidClient(attacker)) {
		return Plugin_Continue;
	}
	
	if(!IsValidClient(victim)) {
		return Plugin_Continue;
	}
	
	if(!player_hasClass[attacker]) {
		return Plugin_Continue;
	}
	
	if(GetClientTeam(victim) == GetClientTeam(attacker)) {
		return Plugin_Continue;
	}
	
	new String:weapon[32];
	GetClientWeapon(attacker, weapon, sizeof(weapon));
	if(StrEqual(weapon, "weapon_awp") && damagetype & DMG_BULLET) {
		cod_inflictDamageWithIntelligence(victim, attacker, 0.5);
	}
	
	if(player_advance[attacker] == 0) {
		damage *= 1.3;
	}
	else if(player_advance[attacker] == 1) {
		damage *= 1.6;
	}
	else if(player_advance[attacker] >= 2){
		damage *= 2;
	}
	return Plugin_Changed;
}

public Action:OnPlayerBlind(Handle:event, String:name[], bool:dontBroadcast) {
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(!IsValidClient(client)) {
		return Plugin_Continue;
	}
	
	if(!player_hasClass[client]) {
		return Plugin_Continue;
	}
	
	SetEntDataFloat(client, g_iFlashAlpha, 0.5);
	SetEntDataFloat(client, g_iFlashDuration, 0.0);
	
	return Plugin_Changed; //było Plugin_Continue;
}