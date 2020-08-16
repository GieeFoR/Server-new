#include <sourcemod>
#include <sdkhooks>
#include <sdktools>
#include <cod>

new const String:PLUGIN_NAME[32] = "coditem_tajemnicagenerala";
new const String:PLUGIN_AUTHOR[32] = "GieeF";
new const String:PLUGIN_VERSION[32] = "1.0";
new const String:PLUGIN_DESCRIPTION[64] = "Item COD - Tajemnica Generała";
new const String:PLUGIN_URL[32] = "-";

new const String:item_name[] = "Tajemnica Generała";
new const String:item_description[] = "Zadajesz 100(+INT) obrażen więcej z granatu";
new const String:item_weapons[] = "#weapon_hegrenade";
new const String:item_blackList[] = "";
new const item_intelligence = 0;
new const item_health = 0;
new const item_damage = 0;
new const item_resistance = 0;
new const item_trim = 0;
new const item_minVal = 0;
new const item_maxVal = 0;

new bool:player_hasItem[MAXPLAYERS];

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
	HookEvent("hegrenade_detonate", OnGrenadeExplode);
}

public OnMapStart() {
	sprite_beam = PrecacheModel("sprites/laserbeam.vmt");
	sprite_halo = PrecacheModel("sprites/glow01.vmt");
}

public OnAllPluginsLoaded() {
	CreateTimer(3.2, RegisterStart, 0);
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

public Action:OnGrenadeExplode(Handle:event, const String:name[], bool:dontBroadcast) {
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(!IsValidClient(client) || !player_hasItem[client]) {
		return Plugin_Continue;
	}
	
	new Float:forigin[3], Float:iorigin[3];
	forigin[0] = GetEventFloat(event, "x");
	forigin[1] = GetEventFloat(event, "y");
	forigin[2] = GetEventFloat(event, "z");
	
	new Float:damage = 100.0;
	for(new i = 1; i <= MaxClients; i++) {
		if(!IsClientInGame(i) || !IsPlayerAlive(i)) {
			continue;
		}
		
		if(GetClientTeam(client) == GetClientTeam(i)) {
			continue;
		}
		
		GetClientEyePosition(i, iorigin);
		if(GetVectorDistance(forigin, iorigin) <= 200.0) {
			SDKHooks_TakeDamage(i, client, client, damage, DMG_GENERIC);
			
			new String:playerClass[32];
			cod_getPlayerClass(client, playerClass, sizeof(playerClass));
			if(!StrEqual(playerClass, "[Pro]Szturmowiec") && !StrEqual(playerClass, "[Elite]Szturmowiec") && !StrEqual(playerClass, "[Master]Szturmowiec") && !StrEqual(playerClass, "[God]Szturmowiec")) {
				cod_inflictDamageWithIntelligence(i, client, 0.5);
			}
		}
	}
	
	TE_SetupBeamRingPoint(forigin, 20.0, 200.0, sprite_beam, sprite_halo, 0, 10, 0.6, 6.0, 0.0, {0, 255, 0, 128}, 10, 0);
	TE_SendToAll();
	return Plugin_Continue;
}