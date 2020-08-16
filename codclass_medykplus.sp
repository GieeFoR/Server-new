#include <sourcemod>
#include <sdkhooks>
#include <sdktools>
#include <cstrike>
#include <cod>

new const String:PLUGIN_NAME[32] = "codclass_medykplus";
new const String:PLUGIN_AUTHOR[32] = "GieeF";
new const String:PLUGIN_VERSION[32] = "1.0";
new const String:PLUGIN_DESCRIPTION[64] = "Klasa COD - Medyk+";
new const String:PLUGIN_URL[32] = "-";

new const String:class_name[32] = "Medyk+";
new const String:class_description[][128] =  { "Posiada dwie apteczki leczące wszystkich w pobliżu 5HP na sekundę", "Posiada dwie apteczki leczące wszystkich w pobliżu 10HP na sekundę(+INT). Może wskrzeszać 3 razy na rundę[E]", "Posiada dwie apteczki leczące wszystkich w pobliżu 20HP na sekundę(+INT). Może wskrzeszać 4 razy na rundę[E]", "Posiada trzy apteczki leczące wszystkich w pobliżu 20HP na sekundę(+INT). Może wskrzeszać 5 razy na rundę[E]", "chuj wi"};
new const String:class_weapons[][512] =  { "#weapon_sg556#weapon_p250#weapon_smokegrenade#weapon_healthshot#weapon_healthshot", "#weapon_sg556#weapon_p250#weapon_smokegrenade#weapon_healthshot#weapon_healthshot", "#weapon_sg556#weapon_p250#weapon_smokegrenade#weapon_healthshot#weapon_healthshot", "#weapon_sg556#weapon_p250#weapon_smokegrenade#weapon_healthshot#weapon_healthshot", "#weapon_sg556#weapon_p250#weapon_smokegrenade#weapon_healthshot#weapon_healthshot" };
new const class_intelligence[] =  { 0, 0, 0, 0, 0 };
new const class_health[] =  { 20, 20, 20, 20, 20 };
new const class_damage[] =  { 0, 0, 0, 0, 0 };
new const class_resistance[] =  { 10, 10, 10, 10, 10 };
new const class_trim[] =  { 0, 0, 0, 0, 0 };

new bool:player_hasClass[MAXPLAYERS];
new player_advance[MAXPLAYERS];

new Float:time_of_death[65];
new Float:last_revive[65];
new Handle:reviving[65];
new reviving_target[65];
new revive_counter[65];
new amountOfHealthKit[MAXPLAYERS];
new amountOfRevives[MAXPLAYERS];
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
	HookEvent("player_spawn", PlayerSpawn);
	HookEvent("player_death", PlayerDeath);
	HookEvent("round_end", RoundEnd);
}

public OnAllPluginsLoaded() {
	CreateTimer(0.4, RegisterStart, 0);
}

public OnClientPostAdminCheck(client) {
	last_revive[client] = GetGameTime();
	if (reviving[client] != null) {
		CloseHandle(reviving[client]);
		reviving[client] = null;
	}
	reviving_target[client] = -1;
	time_of_death[client] = 0.0;
	revive_counter[client] = 0;
}

public OnClientDisconnect(client) {
	if (reviving[client] != null) {
		CloseHandle(reviving[client]);
		reviving[client] = null;
	}
	reviving_target[client] = -1;
	time_of_death[client] = 0.0;
	last_revive[client] = 0.0;
	revive_counter[client] = 0;
}

public OnMapStart() {
	PrecacheModel("models/props/cs_italy/chianti02.mdl");
	sprite_beam = PrecacheModel("sprites/laserbeam.vmt");
	sprite_halo = PrecacheModel("sprites/glow01.vmt");
}

public cod_classEnabled(client, advance) {
	if(GetUserFlagBits(client) & ADMFLAG_CUSTOM2) {
		player_hasClass[client] = true;
		player_advance[client] = advance;
		
		if(player_advance[client] == 1) {
			amountOfRevives[client] = 3;
		}
		else if(player_advance[client] == 2) {
			amountOfRevives[client] = 4;
		}
		else if(player_advance[client] == 3) {
			amountOfRevives[client] = 5;
		}
		else if(player_advance[client] == 4) {
			amountOfRevives[client] = 6;
		}
		
		if(player_advance[client] < 4) {
			amountOfHealthKit[client] = 2;
		}
		else {
			amountOfHealthKit[client] = 3;
		}
		return COD_CONTINUE;
	}
	PrintToChat(client, "Nie masz dostępu do tej klasy premium");
	return COD_STOP;
}

public cod_classDisabled(client) {
	player_hasClass[client] = false;
	player_advance[client] = 0;
}

public Action:RegisterStart(Handle:timer) {
	cod_registerClass(class_name, class_description[0], class_description[1], class_description[2], class_description[3], class_description[4], class_weapons[0], class_weapons[1], class_weapons[2], class_weapons[3], class_weapons[4], class_intelligence, class_health, class_damage, class_resistance, class_trim);
}

public cod_classSkillUsed(client) {
	if(!amountOfHealthKit[client]) {
		PrintToChat(client, "Wykorzystales juz moc swojej klasy!");
	}
	else {
		new ent = CreateEntityByName("hegrenade_projectile");
		if(ent != -1) {
			new Float:forigin[3];
			GetClientEyePosition(client, forigin);
			
			new Float:fangles[3];
			GetClientEyeAngles(client, fangles);
			
			new Float:iangles[3] = {0.0, 0.0, 0.0};
			iangles[1] = fangles[1];
			
			DispatchSpawn(ent);
			ActivateEntity(ent);
			SetEntityModel(ent, "models/props/cs_italy/chianti02.mdl");
			SetEntityMoveType(ent, MOVETYPE_STEP);
			TeleportEntity(ent, forigin, iangles, NULL_VECTOR);
			SetEntProp(ent, Prop_Send, "m_usSolidFlags", 12);
			SetEntProp(ent, Prop_Data, "m_nSolidType", 6);
			SetEntProp(ent, Prop_Send, "m_CollisionGroup", 1);
			SetEntPropEnt(ent, Prop_Send, "m_hOwnerEntity", client);
			
			new ref = EntIndexToEntRef(ent);
			CreateTimer(1.0, ThinkHealthKit, ref, TIMER_FLAG_NO_MAPCHANGE);
			CreateTimer(8.0, ThinkEndHealthKit, ref, TIMER_FLAG_NO_MAPCHANGE);
			
			amountOfHealthKit[client] --;
		}
	}
}

public Action:ThinkHealthKit(Handle:timer, ref) {
	new ent = EntRefToEntIndex(ref);
	if (ent == -1 || !IsValidEntity(ent)) {
		return Plugin_Continue;
	}
	
	new client = GetEntPropEnt(ent, Prop_Send, "m_hOwnerEntity");
	if(!IsValidClient(client) || !player_hasClass[client]) {
		AcceptEntityInput(ent, "Kill");
		return Plugin_Continue;
	}
	
	new Float:forigin[3], Float:iorigin[3];
	GetEntPropVector(ent, Prop_Send, "m_vecOrigin", forigin);
	
	new regeneration;
	if(player_advance[client] == 0) {
		regeneration = 5;
	}
	else if(player_advance[client] == 1) {
		regeneration = 10;
	}
	else if(player_advance[client] >= 2) {
		regeneration = 20;
	}
	new health, maks_health;
	for(new i = 1; i <= MaxClients; i++) {
		if(!IsClientInGame(i) || !IsPlayerAlive(i)) {
			continue;
		}
		
		if(GetClientTeam(client) != GetClientTeam(i)) {
			continue;
		}
		
		GetClientEyePosition(i, iorigin);
		if(GetVectorDistance(forigin, iorigin) <= 200.0) {
			health = GetClientHealth(i);
			maks_health = cod_getPlayerMaxHealth(i);
			SetEntData(i, FindDataMapInfo(i, "m_iHealth"), (health+regeneration > maks_health)? maks_health: health+regeneration);
		}
	}

	TE_SetupBeamRingPoint(forigin, 20.0, 200.0, sprite_beam, sprite_halo, 0, 10, 0.6, 6.0, 0.0, {0, 255, 0, 128}, 10, 0);
	TE_SendToAll();

	CreateTimer(1.0, ThinkHealthKit, ent, TIMER_FLAG_NO_MAPCHANGE);
	return Plugin_Continue;
}

public Action:ThinkEndHealthKit(Handle:timer, ref) {
	new ent = EntRefToEntIndex(ref);
	if (ent == -1 || !IsValidEntity(ent)) {
		return Plugin_Continue;
	}
	AcceptEntityInput(ent, "Kill");
	return Plugin_Continue;
}

public Action:PlayerSpawn(Handle:event, String:name[], bool:dontBroadcast) {
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(!IsValidClient(client) || !player_hasClass[client]) {
		return Plugin_Continue;
	}
	
	if(player_advance[client] == 1) {
		amountOfRevives[client] = 3;
	}
	else if(player_advance[client] == 2) {
		amountOfRevives[client] = 4;
	}
	else if(player_advance[client] == 3) {
		amountOfRevives[client] = 5;
	}
	else if(player_advance[client] == 4) {
		amountOfRevives[client] = 6;
	}
	
	if(player_advance[client] < 4) {
		amountOfHealthKit[client] = 2;
	}
	else {
		amountOfHealthKit[client] = 3;
	}
		
	return Plugin_Continue;
}

public Action:PlayerDeath(Handle:event, String:name[], bool:dontBroadcast) {
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (!IsValidClient(client)) {
		return;
	}
	
	new deathBody = GetEntPropEnt(client, Prop_Send, "m_hRagdoll");
	if (deathBody > 0) {
		AcceptEntityInput(deathBody, "kill", 0, 0);
	}
	
	new ent = CreateEntityByName("prop_ragdoll");
	new String:sModel[PLATFORM_MAX_PATH];
	GetClientModel(client, sModel, sizeof(sModel));
	DispatchKeyValue(ent, "model", sModel);
	
	SetEntPropEnt(ent, Prop_Send, "m_hOwnerEntity", client);
	SetEntProp(ent, Prop_Data, "m_nSolidType", 6);
	SetEntProp(ent, Prop_Data, "m_CollisionGroup", 5);
	
	ActivateEntity(ent);
	
	if (DispatchSpawn(ent)) {
		new Float:origin[3], 
		Float:angles[3], 
		Float:velocity[3];
		
		GetClientAbsOrigin(client, origin);
		GetClientAbsAngles(client, angles);
		GetEntPropVector(client, Prop_Data, "m_vecAbsVelocity", velocity);
		new Float:speed = GetVectorLength(velocity);
		if (speed >= 500) {
			TeleportEntity(ent, origin, angles, NULL_VECTOR);
		}
		else {
			TeleportEntity(ent, origin, angles, velocity);
		}
		time_of_death[client] = GetGameTime();
	}
	SetEntProp(ent, Prop_Data, "m_CollisionGroup", 2);
}

public Action:RoundEnd(Handle:event, String:name[], bool:dontBroadcast) {
	for (new i = 1; i <= MaxClients; i++) {
		if (reviving[i] != null) {
			CloseHandle(reviving[i]);
			reviving[i] = null;
		}
		reviving_target[i] = -1;
		last_revive[i] = GetGameTime();
		time_of_death[i] = 0.0;
		revive_counter[i] = 0;
	}
}

public Action:OnPlayerRunCmd(client, &buttons) {
	if (!IsValidClient(client)) {
		return Plugin_Continue;
	}
	
	if (!IsPlayerAlive(client)) {
		return Plugin_Continue;
	}
	
	if (!(buttons & IN_USE)) {
		ClearReviveStuff(client);
	}
	else {
		new aim = GetClientAimTarget(client, false);
		if (aim > MaxClients)
		{
			if (aim != reviving_target[client]) {
				if (reviving[client] != null) {
					PrintToChat(client, "Wskrzeszanie przerwane");
					ClearReviveStuff(client);
				}
			}
			new String:class[128];
			GetEntityClassname(aim, class, sizeof(class));
			if (!StrEqual(class, "prop_ragdoll", false)) {
				if (reviving[client] != null) {
					PrintToChat(client, "Wskrzeszanie przerwane");
					ClearReviveStuff(client);
				}
				return Plugin_Continue;
			}
			
			new Float:eyePos[3];
			GetClientEyePosition(client, eyePos);
			new Float:bodyLoc[3];
			GetEntPropVector(aim, Prop_Data, "m_vecOrigin", bodyLoc);
			new Float:vec[3];
			MakeVectorFromPoints(eyePos, bodyLoc, vec);
			if (GetVectorLength(vec) > 150) {
				if (reviving[client] != null) {
					ClearReviveStuff(client);
				}
				return Plugin_Continue;
			}
			
			new owner = GetEntPropEnt(aim, Prop_Send, "m_hOwnerEntity");
			if (IsValidClient(owner)) {
				if(revive_counter[client] >= amountOfRevives[client]) {
					PrintToChat(client, "Wykorzystałeś limit wskrzeszeń na tę rundę");
					return Plugin_Continue;
				}
				if(revive_counter[owner] >= 1) {
					PrintToChat(client, "Nie możesz wskrzesić drugi raz tego samego gracza");
					return Plugin_Continue;
				}
					
				if ((GetClientTeam(owner) == GetClientTeam(client)) && (GetGameTime() - last_revive[client] >= 15) && reviving[client] == null) {
					reviving_target[client] = aim;
					reviving[client] = CreateTimer(5.0, TimerRevive, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
					SetEntPropFloat(client, Prop_Send, "m_flProgressBarStartTime", GetGameTime());
					SetEntProp(client, Prop_Send, "m_iProgressBarDuration", 5);
					PrintToChat(client, "Rozpocząłeś wskrzeszanie gracza %N", owner);
				}
			}
		}
	}
	return Plugin_Continue;
}

public ClearReviveStuff(client) {
	if(reviving[client] != null) {
		CloseHandle(reviving[client]);
		reviving[client] = null;
	}
	reviving_target[client] = -1;
	SetEntPropFloat(client, Prop_Send, "m_flProgressBarStartTime", 0.0);
	SetEntProp(client, Prop_Send, "m_iProgressBarDuration", 0);
}

public Action:TimerRevive(Handle:timer, userid) {
	new client = GetClientOfUserId(userid);
	if (!IsValidClient(client)) {
		return Plugin_Handled;
	}
	
	reviving[client] = null;
	SetEntPropFloat(client, Prop_Send, "m_flProgressBarStartTime", 0.0);
	SetEntProp(client, Prop_Send, "m_iProgressBarDuration", 0);
	
	new ent = reviving_target[client];
	reviving_target[client] = -1;
	if (!IsValidEntity(ent)) {
		return Plugin_Handled;
	}
	
	new aim = GetClientAimTarget(client, false);
	if (ent != aim) {
		return Plugin_Handled;
	}
	
	new Float:eyePos[3];
	GetClientEyePosition(client, eyePos);
	new Float:bodyLoc[3];
	GetEntPropVector(ent, Prop_Data, "m_vecOrigin", bodyLoc);
	new Float:vec[3];
	MakeVectorFromPoints(eyePos, bodyLoc, vec);
	if (GetVectorLength(vec) > 150) {
		PrintToChat(client, "Wskrzeszanie przerwane");
		return Plugin_Handled;
	}
	
	new target = GetEntPropEnt(ent, Prop_Send, "m_hOwnerEntity");
	if (!IsValidClient(target)) {
		return Plugin_Handled;
	}
	
	PrintToChat(client, "Wskrzesiłeś gracza %N.", target);
	
	CS_RespawnPlayer(target);
	TeleportEntity(target, bodyLoc, NULL_VECTOR, NULL_VECTOR);
	SetEntityHealth(target, 30);
	revive_counter[client]++;
	if (IsValidEntity(ent)) {
		AcceptEntityInput(ent, "kill", 0, 0);
	}
	
	last_revive[client] = GetGameTime();
	PrintToChat(target, "Gracz %N Cie wskrzesił.", client);
	return Plugin_Handled;
}