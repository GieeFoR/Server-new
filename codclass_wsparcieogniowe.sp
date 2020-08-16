#include <sourcemod>
#include <sdkhooks>
#include <sdktools>
#include <cod>

new const String:PLUGIN_NAME[32] = "codclass_wsparcieogniowe";
new const String:PLUGIN_AUTHOR[32] = "GieeF";
new const String:PLUGIN_VERSION[32] = "1.0";
new const String:PLUGIN_DESCRIPTION[64] = "Klasa COD - Wsparcie Ogniowe";
new const String:PLUGIN_URL[32] = "-";

new const String:class_name[] = "Wsparcie Ogniowe";
new const String:class_description[][] =  { "Posiada dwie rakiety o obrażeniach 30DMG", "Posiada dwie rakiety o obrażeniach 30DMG(+INT)", "Posiada dwie rakiety o obrażeniach 50DMG(+INT)", "Posiada trzy rakiety o obrażeniach 50DMG(+INT) +??", "Posiada trzy rakiety o obrażeniach 50DMG(+INT) +????"};
new const String:class_weapons[][] =  { "#weapon_mp5sd#weapon_glock", "#weapon_mp5sd#weapon_p250", "#weapon_mp5sd#weapon_p250", "#weapon_mp5sd#weapon_p250", "#weapon_mp5sd#weapon_p250" };
new const class_intelligence[] =  	{ 0, 	0, 		0, 		0, 		0 };
new const class_health[] =  		{ 0, 	0, 		0, 		0, 		0 };
new const class_damage[] =  		{ 0, 	0, 		0, 		0, 		0 };
new const class_resistance[] =  	{ 10, 	10, 	10, 	10, 	10 };
new const class_trim[] =  			{ 0, 	0, 		0, 		0, 		0 };

new bool:player_hasClass[MAXPLAYERS];
new player_advance[MAXPLAYERS];
new player_amountOfRockets[MAXPLAYERS];

new sprite_explosion;

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
	CreateTimer(1.0, RegisterStart, 0);
}

public OnMapStart() {
	PrecacheModel("models/props/de_vertigo/construction_safetyribbon_01.mdl");
	sprite_explosion = PrecacheModel("materials/sprites/blueflare1.vmt");
	PrecacheSound("weapons/hegrenade/explode5.wav");
}

public cod_classEnabled(client, advance) {
	player_hasClass[client] = true;
	player_advance[client] = advance;
	
	if(player_advance[client] <= 2) {
		player_amountOfRockets[client] = 2;
	}
	else {
		player_amountOfRockets[client] = 3;
	}
}

public cod_classDisabled(client) {
	player_hasClass[client] = false;
	player_advance[client] = 0;
}

public cod_classSkillUsed(client) {
	if(!player_amountOfRockets[client]) {
		PrintToChat(client, "Wykorzystałeś już moc swojej klasy!");
	}
	else {
		new ent = CreateEntityByName("hegrenade_projectile");
		if(ent != -1) {
			new Float:forigin[3];
			GetClientEyePosition(client, forigin);
			
			new Float:fangles[3];
			GetClientEyeAngles(client, fangles);
			
			new Float:iorigin[3], Float:iangles[3], Float:ivector[3];
			TR_TraceRayFilter(forigin, fangles, MASK_SOLID, RayType_Infinite, TraceRayFilter, ent);
			TR_GetEndPosition(iorigin);
			DispatchSpawn(ent);
			ActivateEntity(ent);
			SetEntityModel(ent, "models/props/de_vertigo/construction_safetyribbon_01.mdl");
			SetEntityMoveType(ent, MOVETYPE_STEP);
			SetEntityGravity(ent, 0.1);
			MakeVectorFromPoints(forigin, iorigin, ivector);
			NormalizeVector(ivector, ivector);
			ScaleVector(ivector, 1000.0);
			GetVectorAngles(ivector, iangles);
			TeleportEntity(ent, forigin, iangles, ivector);
			SetEntProp(ent, Prop_Send, "m_usSolidFlags", 12);
			SetEntProp(ent, Prop_Data, "m_nSolidType", 6);
			SetEntProp(ent, Prop_Send, "m_CollisionGroup", 1);
			SetEntPropEnt(ent, Prop_Send, "m_hOwnerEntity", client);
			SDKHook(ent, SDKHook_StartTouchPost, RocketTouch);

			player_amountOfRockets[client]--;
		}
	}
}

public Action:RegisterStart(Handle:timer) {
	cod_registerClass(class_name, class_description[0], class_description[1], class_description[2], class_description[3], class_description[4], class_weapons[0], class_weapons[1], class_weapons[2], class_weapons[3], class_weapons[4], class_intelligence, class_health, class_damage, class_resistance, class_trim);
}

public Action:RocketTouch(ent, client) {
	if(!IsValidEntity(ent)) {
		return Plugin_Continue;
	}
	
	new attacker = GetEntPropEnt(ent, Prop_Send, "m_hOwnerEntity");
	if(!IsValidClient(attacker) || !player_hasClass[attacker]) {
		AcceptEntityInput(ent, "Kill");
		return Plugin_Continue;
	}
	
	if(IsValidClient(client) && GetClientTeam(attacker) == GetClientTeam(client)) {
		return Plugin_Continue;
	}
	
	new Float:forigin[3], Float:iorigin[3];
	GetEntPropVector(ent, Prop_Send, "m_vecOrigin", forigin);
	
	new Float:damage;
	if(player_advance[client] <= 1) {
		damage = 30.0;
	}
	else {
		damage = 50.0;
	}
	
	for(new i = 1; i <= MaxClients; i++) {
		if(!IsClientInGame(i) || !IsPlayerAlive(i)) {
			continue;
		}
		
		if(GetClientTeam(attacker) == GetClientTeam(i)) {
			continue;
		}
		
		GetClientEyePosition(i, iorigin);
		if(GetVectorDistance(forigin, iorigin) <= 100.0) {
			new String:playerItem[32];
			cod_getPlayerItem(i, playerItem, sizeof(playerItem));
			if(StrEqual(playerItem, "Obronca")) {
				continue;
			}
			
			SDKHooks_TakeDamage(i, attacker, attacker, damage, DMG_BULLET);
			cod_inflictDamageWithIntelligence(i, attacker, 1.0);
		}
	}

	EmitSoundToAll("weapons/hegrenade/explode5.wav", ent, SNDCHAN_AUTO, SNDLEVEL_GUNFIRE);
	TE_SetupExplosion(forigin, sprite_explosion, 10.0, 1, 0, 100, 100);
	TE_SendToAll();

	AcceptEntityInput(ent, "Kill");
	return Plugin_Continue;
}

public bool:TraceRayFilter(ent, contents) {
	return false;
}

public Action:OnPlayerSpawn(Handle:event, String:name[], bool:dontBroadcast) {
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(!IsValidClient(client) || !player_hasClass[client]) {
		return Plugin_Continue;
	}
	
	if(player_advance[client] <= 2) {
		player_amountOfRockets[client] = 2;
	}
	else {
		player_amountOfRockets[client] = 3;
	}
	return Plugin_Continue;
}