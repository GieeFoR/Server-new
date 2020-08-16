#include <sourcemod>
#include <sdkhooks>
#include <sdktools>
#include <cod>

new const String:PLUGIN_NAME[32] = "codclass_rusher";
new const String:PLUGIN_AUTHOR[32] = "GieeF";
new const String:PLUGIN_VERSION[32] = "1.0";
new const String:PLUGIN_DESCRIPTION[64] = "Klasa COD - Rusher";
new const String:PLUGIN_URL[32] = "-";

new const String:class_name[] = "Rusher";
new const String:class_description[][] =  { "Zadaje obrazenia z novy(+INT)", "Zadaje obrazenia z novy(+INT). Posiada 3 sekundy niewidzialności", "Zadaje obrazenia z novy(+INT). Posiada 4 sekundy niewidzialności", "Zadaje obrazenia z xm1014(+INT). Posiada dwa razy po 4 sekundy niewidzialności", "Zadaje obrazenia z xm1014(+INT). Posiada dwa razy po 4 sekundy niewidzialności+????"};
new const String:class_weapons[][] =  { "#weapon_nova#weapon_glock", "#weapon_nova#weapon_glock", "#weapon_nova#weapon_fiveseven", "#weapon_xm1014#weapon_fiveseven", "#weapon_xm1014#weapon_fiveseven" };
new const class_intelligence[] =  	{ 5, 	5, 		5, 		5, 		5 };
new const class_health[] =  		{ 0, 	0, 		0, 		0, 		0 };
new const class_damage[] =  		{ 0, 	0, 		0, 		0, 		0 };
new const class_resistance[] =  	{ 5, 	5, 		5, 		5, 		5 };
new const class_trim[] =  			{ 5, 	5, 		5, 		5, 		5 };

new bool:player_hasClass[MAXPLAYERS];
new player_advance[MAXPLAYERS];
new amountOfInvisibility[MAXPLAYERS];
new invisibilityTimer[MAXPLAYERS];

public Plugin:myinfo = {
	name = PLUGIN_NAME,
	author = PLUGIN_AUTHOR,
	description = PLUGIN_DESCRIPTION,
	version = PLUGIN_VERSION,
	url = PLUGIN_URL
};

public OnPluginStart() {
	ServerCommand("sv_disable_immunity_alpha 1");
	
	HookEvent("player_spawn", OnPlayerSpawn);
}

public OnAllPluginsLoaded() {
	CreateTimer(0.5, RegisterStart, 0);
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
	
	if(player_advance[client] < 1)
		amountOfInvisibility[client] = 0;
	else if(player_advance[client] < 4) {
		amountOfInvisibility[client] = 1;
	}
	else {
		amountOfInvisibility[client] = 2;
	}
}

public cod_classDisabled(client) {
	player_hasClass[client] = false;
	player_advance[client] = 0;
	amountOfInvisibility[client] = 0;
}

public cod_class_skill_used(client) {
	//czy dobry warunek??
	if(invisibilityTimer[client] < RoundFloat(GetGameTime())) {
		return;
	}
	
	new invisibilityDuration;
	
	if(player_advance[client] < 1)
		invisibilityDuration = 0;
	else if(player_advance[client] < 2) {
		invisibilityDuration = 3;
	}
	else {
		invisibilityDuration = 4;
	}
	
	if(!amountOfInvisibility[client])
		PrintToChat(client, "Wykorzystałeś już moc swojej klasy!");
	else {
		invisibilityTimer[client] = RoundFloat(GetGameTime()) + invisibilityDuration;
		SetEntityRenderMode(client, RENDER_TRANSCOLOR);
		SetEntityRenderColor(client, 255, 255, 255, 1);
		
		SDKHook(client, SDKHook_SetTransmit, Hook_SetTransmit);
		
		amountOfInvisibility[client]--;
	}
}

public Action:RegisterStart(Handle:timer) {
	cod_registerClass(class_name, class_description[0], class_description[1], class_description[2], class_description[3], class_description[4], class_weapons[0], class_weapons[1], class_weapons[2], class_weapons[3], class_weapons[4], class_intelligence, class_health, class_damage, class_resistance, class_trim);
}

public Action:OnPlayerTakeDamage(client, &attacker, &inflictor, &Float:damage, &damagetype) {
	if(!IsValidClient(attacker)) {
		return Plugin_Continue;
	}
	
	if(!IsValidClient(client)) {
		return Plugin_Continue;
	}
	
	if(!player_hasClass[client]) {
		return Plugin_Continue;
	}
	
	if(GetClientTeam(client) == GetClientTeam(attacker)) {
		return Plugin_Continue;
	}
	
	new String:weapon[32];
	GetClientWeapon(attacker, weapon, sizeof(weapon));
	if(StrEqual(weapon, "weapon_nova") && damagetype & DMG_BULLET) {
		cod_inflictDamageWithIntelligence(client, attacker, 0.5);
	}
	
	return Plugin_Continue;
}

public Action:OnPlayerSpawn(Handle:event, String:name[], bool:dontBroadcast) {
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(!IsValidClient(client) || !player_hasClass[client]) {
		return Plugin_Continue;
	}
	
	if(player_advance[client] < 1)
		amountOfInvisibility[client] = 0;
	else if(player_advance[client] < 4) {
		amountOfInvisibility[client] = 1;
	}
	else {
		amountOfInvisibility[client] = 2;
	}
	return Plugin_Continue;
}

public Action:Hook_SetTransmit(client, entity) {
    if(client == entity)
        return Plugin_Continue;
    return Plugin_Handled;
}

public Action:KoniecNiewidzialnosci(client) {
	if(!IsValidClient(client) || !player_hasClass[client]) {
		return Plugin_Continue;
	}
	
	if(GetGameTime() >= invisibilityTimer[client]) {
		SetEntityRenderMode(client, RENDER_TRANSCOLOR);
		SetEntityRenderColor(client, 255, 255, 255, 255);
		SDKUnhook(client, SDKHook_SetTransmit, Hook_SetTransmit);
	}
	return Plugin_Continue;
}