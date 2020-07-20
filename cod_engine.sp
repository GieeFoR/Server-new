#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <cstrike>

#pragma semicolon 1

#define CVAR_FLAGS FCVAR_NOTIFY

#define HEALTH_BASE 90
#define HEALTH_MULTIPLIER 2
#define DAMAGE_MULTIPLIER 0.003
#define RESISTANCE_MULTIPLIER 0.002
#define STAMINA_MULTIPLIER 0.004
#define STAMINA_BASE 0.9

#define MAXCLASSES 10+1
#define MAXITEMS 50+1
#define ADVANCESVALUE 5

#define NAMELEN 32
#define DESCLEN 128
#define DESCLENEXTENDED 1024
#define WEAPONSLEN 512

new const String:PLUGIN_NAME[32] = "cod_engine";
new const String:PLUGIN_AUTHOR[32] = "GieeF";
new const String:PLUGIN_VERSION[32] = "0.9";
new const String:PLUGIN_DESCRIPTION[64] = "Plugin wprowadzajacy do cs-go serwery COD Mod";
new const String:PLUGIN_URL[32] = "-";

new bool:hasClass[MAXPLAYERS];

new class[MAXPLAYERS];
new newClass[MAXPLAYERS];
new exp[MAXPLAYERS][MAXCLASSES];
new lvl[MAXPLAYERS][MAXCLASSES];
new advance[MAXPLAYERS][MAXCLASSES];
new stats_points[MAXPLAYERS][MAXCLASSES];
new stats_intelligence[MAXPLAYERS][MAXCLASSES];
new stats_health[MAXPLAYERS][MAXCLASSES];
new stats_damage[MAXPLAYERS][MAXCLASSES];
new stats_resistance[MAXPLAYERS][MAXCLASSES];
new stats_stamina[MAXPLAYERS][MAXCLASSES];

new numberOfClasses = 0;
new Handle:class_plugins[MAXCLASSES];
new String:class_name[MAXCLASSES][ADVANCESVALUE][NAMELEN];
new String:class_description[MAXCLASSES][ADVANCESVALUE][DESCLEN];
new String:class_weapons[MAXCLASSES][ADVANCESVALUE][WEAPONSLEN];
new class_intelligence[MAXCLASSES][ADVANCESVALUE];
new class_health[MAXCLASSES][ADVANCESVALUE];
new class_damage[MAXCLASSES][ADVANCESVALUE];
new class_resistance[MAXCLASSES][ADVANCESVALUE];
new class_stamina[MAXCLASSES][ADVANCESVALUE];

new numberOfItems = 0;
new Handle:item_plugins[MAXITEMS];
new String:item_name[MAXITEMS][NAMELEN];
new String:item_description[MAXITEMS][DESCLEN];
new item_minVal[MAXITEMS];
new item_maxVal[MAXITEMS];

new stats_assignAmount[] =  { 1, 10, 50, 0, -1, -10, -50 };
new stats_selectedAmount[MAXPLAYERS];
new stats_limit[] =  { 80, 80, 80, 80, 80 };

new itemValGlobal[MAXPLAYERS];
new posGlobal[MAXPLAYERS];

new bool:pluginLoad;

static String:InfoPath[PLATFORM_MAX_PATH];

new Handle:cvar_DamageToPlayerMultiplier = INVALID_HANDLE;
new Handle:cvar_ExpForDamageToHostages = INVALID_HANDLE;
new Handle:cvar_ExpForWinRound = INVALID_HANDLE;
new Handle:cvar_ExpForKill = INVALID_HANDLE;
new Handle:cvar_ExpForHS = INVALID_HANDLE;
new Handle:cvar_ExpForHostageRescued = INVALID_HANDLE;
new Handle:cvar_ExpForMVP = INVALID_HANDLE;
new Handle:cvar_ExpForBombPlanted = INVALID_HANDLE;
new Handle:cvar_ExpForBombDefused = INVALID_HANDLE;

new ExpForKill;
new ExpForHeadshot;
new expForRoundWon;
new expForHostageRescue;
new expForHostageHurt;
new expForMVP;
new expForBombPlanted;
new expForBombDefused;
new Float:damageMultiplier;

new const expTable[] = {
	0,
	57, 200, 348, 641, 1035, 1506, 2049, 2638, 3231, 3966, 
	4722, 5496, 6350, 7339, 8509, 9725, 11029, 12352, 13795, 15374, 
	16957, 18553, 20389, 22234, 24091, 26003, 28049, 30182, 32457, 34734, 
	37168, 39646, 42213, 44883, 47677, 50501, 53447, 56416, 59502, 62627, 
	65781, 69130, 72498, 75968, 79505, 83042, 86716, 90439, 94316, 98211, 
	102217, 106303, 110400, 114707, 119079, 123555, 128101, 132702, 137336, 142076, 
	146932, 151793, 156802, 161813, 166939, 172158, 177377, 182796, 188249, 193815, 
	199463, 205211, 211013, 216861, 222714, 228657, 234666, 240775, 247017, 253414, 
	259828, 266344, 272947, 279652, 286378, 293146, 300000, 307007, 314087, 321178, 
	328277, 335610, 342960, 350330, 357802, 365446, 373155, 380924, 388707, 396701, 
	404759, 412875, 421098, 429384, 437683, 446081, 454521, 463036, 471630, 480401, 
	489258, 498149, 507068, 516182, 525315, 534514, 543749, 553072, 562507, 572004, 
	581578, 591154, 600989, 610891, 620797, 630746, 640894, 651121, 661436, 671828, 
	682231, 692675, 703227, 713924, 724716, 735532, 746468, 757501, 768535, 779707, 
	790972, 802260, 813587, 825062, 836636, 848243, 859857, 871530, 883351, 895305, 
	907354, 919466, 931619, 943885, 956208, 968562, 981063, 993659, 1006354, 1019098, 
	1031977, 1044889, 1057853, 1070864, 1083897, 1097123, 1110447, 1123855, 1137340, 1150862, 
	1164408, 1178161, 1191963, 1205870, 1219825, 1233820, 1247891, 1261963, 1276064, 1290242, 
	1304545, 1319081, 1333645, 1348344, 1363117, 1377935, 1392889, 1407912, 1423024, 1438157, 
	1453306, 1468534, 1483808, 1499163, 1514583, 1530040, 1545741, 1561565, 1577401, 1593380, 
	1609376
};

enum (+= 40) {
	pro = 40,
	elite,
	master,
	god
};

enum (+= 1) {
	pos_basic = 0,
	pos_pro,
	pos_elite,
	pos_master,
	pos_god
};

enum (+= 1) {
	pos_intelligence = 0,
	pos_health,
	pos_damage,
	pos_resistance,
	pos_stamina
};

public Plugin:myinfo =  {
	name = PLUGIN_NAME, 
	author = PLUGIN_AUTHOR, 
	description = PLUGIN_DESCRIPTION, 
	version = PLUGIN_VERSION, 
	url = PLUGIN_URL
};

public APLRes:AskPluginLoad2(Handle:plugin, bool:late, String:error[], err_max) {
	CreateNative("cod_registerClass", Native_RegisterClass);
	CreateNative("cod_registerItem", Native_RegisterItem);
	
	pluginLoad = late;
	return APLRes_Success;
}

public OnPluginStart() {
	CreateConVar( "sm_codmod_version", PLUGIN_VERSION, "Plugin version", CVAR_FLAGS | FCVAR_DONTRECORD );
	cvar_DamageToPlayerMultiplier = CreateConVar("cod_exp_damagemultiplier", "0.2", "Which part of taken damage receive in exp? (0 - to disable)", CVAR_FLAGS, true);
	cvar_ExpForDamageToHostages = CreateConVar("cod_exp_hostagedamage", "100", "How much exp does a player lose for hurting hostages? (0 - to disable)", CVAR_FLAGS, true);
	cvar_ExpForWinRound = CreateConVar("cod_exp_winround", "20", "How much exp does a player gain for being in a winning team? (0 - to disable)", CVAR_FLAGS, true);
	cvar_ExpForKill = CreateConVar("cod_exp_kill", "0", "How much exp does a player gain for getting frag? (0 - to disable)", CVAR_FLAGS, true);
	cvar_ExpForHS = CreateConVar("cod_exp_headshot", "0", "How much exp does a player gain for getting headshot? (0 - to disable)", CVAR_FLAGS, true);
	cvar_ExpForHostageRescued = CreateConVar("cod_exp_hostagerescued", "100", "How much exp does a player gain for rescuing hostage? (0 - to disable)", CVAR_FLAGS, true);
	cvar_ExpForMVP = CreateConVar("cod_exp_roundmvp", "100", "How much exp does a player gain for being a MVP? (0 - to disable)", CVAR_FLAGS, true);
	cvar_ExpForBombPlanted = CreateConVar("cod_exp_bombplanted", "100", "How much exp does a player gain for planting a bomb? (0 - to disable)", CVAR_FLAGS, true);
	cvar_ExpForBombDefused = CreateConVar("cod_exp_bombdefused", "100", "How much exp does a player gain for defusing a bomb? (0 - to disable)", CVAR_FLAGS, true);
	
	AutoExecConfig(true, "sm_codmod");
	
	HookConVarChange(cvar_DamageToPlayerMultiplier, OnConVarsChange);
	HookConVarChange(cvar_ExpForDamageToHostages, OnConVarsChange);
	HookConVarChange(cvar_ExpForWinRound, OnConVarsChange);
	HookConVarChange(cvar_ExpForKill, OnConVarsChange);
	HookConVarChange(cvar_ExpForHS, OnConVarsChange);
	HookConVarChange(cvar_ExpForHostageRescued, OnConVarsChange);
	HookConVarChange(cvar_ExpForMVP, OnConVarsChange);
	HookConVarChange(cvar_ExpForBombPlanted, OnConVarsChange);
	HookConVarChange(cvar_ExpForBombDefused, OnConVarsChange);
	
	GetConVars();
	
	LoadTranslations("COD.phrases");
	PrintToServer("[COD] %t", "Plugin Load Message", PLUGIN_NAME);
	
	CreateDirectory("addons/sourcemod/data/cod", 3);
	BuildPath(Path_SM, InfoPath, sizeof(InfoPath), "data/cod/data.txt");
	
	Events();
	ConsoleCommands();
	
	if (pluginLoad) {
		for (new client = 1; client <= MaxClients; client++) {
			if(IsValidClient(client)) {
				CreateTimer(5.0, LoadPlayerData_Timer, client, TIMER_FLAG_NO_MAPCHANGE);
			}
			
			//if(IsValidClient(client)) 
			//if(IsClientAuthorized(client) && IsClientConnected(client)) {
			//	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
			//}
		}
	}
}

public Events() {
	HookEvent("player_spawn", OnPlayerSpawn, EventHookMode_Post);
	HookEvent("player_death", OnPlayerDeath, EventHookMode_Post);
	HookEvent("round_end", OnRoundEnd, EventHookMode_Pre);
	HookEvent("round_end", OnRoundEndPost, EventHookMode_Post);
	HookEvent("player_hurt", OnPlayerHurt, EventHookMode_Post);
	HookEvent("hostage_rescued", OnHostageRescued, EventHookMode_Post);
	HookEvent("hostage_hurt", OnHostageHurt, EventHookMode_Post);
	HookEvent("round_mvp", OnRoundMVP, EventHookMode_Post);
	HookEvent("bomb_planted", OnBombPlanted, EventHookMode_Post);
	HookEvent("bomb_defused", OnBombDefused, EventHookMode_Post);
	HookUserMessage(GetUserMessageId("VGUIMenu"), TeamMenuHook, true);
}

public ConsoleCommands() {
	AddCommandListener(Listener_JoinTeam, "jointeam");
	AddCommandListener(Listener_BuyBlock, "buy");
	AddCommandListener(Listener_BuyBlock, "buymenu");
	AddCommandListener(Listener_BuyBlock, "buyrandom");
	AddCommandListener(Listener_BuyBlock, "autobuy");
	AddCommandListener(Listener_BuyBlock, "rebuy");
	
	RegConsoleCmd("sm_stats", AssignStatsPoints_Menu);
	RegConsoleCmd("sm_staty", AssignStatsPoints_Menu);
	RegConsoleCmd("sm_class", ChooseClass_Menu);
	RegConsoleCmd("sm_klasa", ChooseClass_Menu);
	RegConsoleCmd("sm_classes", ClassesDescription_Menu);
	RegConsoleCmd("sm_klasy", ClassesDescription_Menu);
	RegConsoleCmd("menu", MainMenu_Menu);
	RegConsoleCmd("sm_info", ReturnPlayerInfoCommand);
	
	RegConsoleCmd("sm_addexp", AddExpCommand);
	RegConsoleCmd("sm_remexp", RemoveExpCommand);
}

public OnPluginEnd() {
	CloseHandle(cvar_DamageToPlayerMultiplier);
	CloseHandle(cvar_ExpForDamageToHostages);
	CloseHandle(cvar_ExpForWinRound);
	CloseHandle(cvar_ExpForKill);
	CloseHandle(cvar_ExpForHS);
	CloseHandle(cvar_ExpForHostageRescued);
	CloseHandle(cvar_ExpForMVP);
	CloseHandle(cvar_ExpForBombPlanted);
	CloseHandle(cvar_ExpForBombDefused);
	
	UnhookEvent("player_spawn", OnPlayerSpawn, EventHookMode_Post);
	UnhookEvent("player_death", OnPlayerDeath, EventHookMode_Post);
	UnhookEvent("round_end", OnRoundEnd, EventHookMode_Pre);
	UnhookEvent("player_hurt", OnPlayerHurt, EventHookMode_Post);
	UnhookEvent("hostage_rescued", OnHostageRescued, EventHookMode_Post);
	UnhookEvent("hostage_hurt", OnHostageHurt, EventHookMode_Post);
	UnhookEvent("round_mvp", OnRoundMVP, EventHookMode_Post);
	UnhookEvent("bomb_planted", OnBombPlanted, EventHookMode_Post);
	UnhookEvent("bomb_defused", OnBombDefused, EventHookMode_Post);
	UnhookUserMessage(GetUserMessageId("VGUIMenu"), TeamMenuHook, true);
	
	for (new client = 1; client <= MaxClients; client++) {
		SavePlayerData(client);
	}
}

public OnConVarsChange(Handle:convar, const String:oldValue[], const String:newValue[]) {
	GetConVars();
}

public GetConVars() {
	ExpForKill = GetConVarInt(cvar_ExpForKill);
	ExpForHeadshot = GetConVarInt(cvar_ExpForHS);
	expForRoundWon = GetConVarInt(cvar_ExpForWinRound);
	expForHostageRescue = GetConVarInt(cvar_ExpForHostageRescued);
	expForHostageHurt = GetConVarInt(cvar_ExpForDamageToHostages);
	expForMVP = GetConVarInt(cvar_ExpForMVP);
	expForBombPlanted = GetConVarInt(cvar_ExpForBombPlanted);
	expForBombDefused = GetConVarInt(cvar_ExpForBombDefused);
	damageMultiplier = GetConVarFloat(cvar_DamageToPlayerMultiplier);
}

public Action:OnPlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast) {
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if(!IsValidClient(client)) {
		return Plugin_Handled;
	}
	
	ApplyStats(client);
	return Plugin_Continue;
}

public Action:OnPlayerDeath(Handle:event, const String:name[], bool:dontBroadcast) {
	new victim = GetClientOfUserId(GetEventInt(event, "userid"));
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	new bool:headshot = GetEventBool(event, "headshot");
	
	new String:victimName[64] = "";
	//if(IsValidClient(victim) && IsClientConnected(victim))		- na botach nie można expić
	if (IsClientConnected(victim)) {
		GetClientName(victim, victimName, sizeof(victimName));
	}
	
	if (!StrEqual(victimName, "")) {
		PrintToChatAll("Zginal gracz %s", victimName);
	}
	
	if(ExpForKill) {
		PrintToChat(attacker, "[COD] %t", "Exp Kill Message", ExpForKill);
		AddAmountOfExp(attacker, ExpForKill);
	}
	
	if(ExpForHeadshot && headshot) {
		PrintToChat(attacker, "[COD] %t", "Exp Headshot Message", ExpForHeadshot);
		AddAmountOfExp(attacker, ExpForHeadshot);
	}
	CheckExp(attacker);
	
	if (IsValidClient(attacker) && IsClientConnected(attacker)) {
		PrintToChat(attacker, "Posiadany exp: %d", exp[attacker]);
	}
	
	return Plugin_Continue;
}

public Action:OnRoundEnd(Handle:event, const String:name[], bool:dontbroadcast) {
	new winners = GetEventInt(event, "winner");
	
	if(expForRoundWon) {
		for (new client = 1; client < MaxClients; client++) {
			if(!IsValidClient(client)) {
				continue;
			}
			
			if(!hasClass[client] || GetClientTeam(client) == CS_TEAM_SPECTATOR) {
				continue;
			}
	
			if(GetClientTeam(client) == winners) {
				PrintToChat(client, "[COD] %t", "Exp RoundWon Message", expForRoundWon);
				AddAmountOfExp(client, expForRoundWon);
			}
		}
	}
	
	for (new client = 1; client < MaxClients; client++) {
		SavePlayerData(client);
	}
	return Plugin_Continue;
}

public Action:OnRoundEndPost(Handle:event, const String:name[], bool:dontbroadcast) {
	ChangeClientsClasses();
	return Plugin_Continue;
}

public Action:OnPlayerHurt(Handle:event, const String:name[], bool:dontbroadcast) {
	new victim = GetClientOfUserId(GetEventInt(event, "userid"));
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	new damage = GetEventInt(event, "dmg_health");
	
	//	if(!IsValidClient(victim) || !IsValidClient(attacker)) {		- na botach nie można expić
	if (!IsValidClient(attacker)) {
		return Plugin_Handled;
	}
	
	if(!hasClass[victim] || GetClientTeam(victim) == CS_TEAM_SPECTATOR) {
		return Plugin_Handled;
	}
	
	if (GetClientTeam(victim) == GetClientTeam(attacker)) {
		return Plugin_Handled;
	}
	
	PrintToChat(attacker, "Zadales %i DMG", damage);
	AddExpByDMG(attacker, damage);
	
	return Plugin_Continue;
}

public Action:OnHostageRescued(Handle:event, const String:name[], bool:dontbroadcast) {
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (!IsValidClient(client)) {
		return Plugin_Handled;
	}
	
	if(!hasClass[client] || GetClientTeam(client) == CS_TEAM_SPECTATOR) {
		return Plugin_Handled;
	}
	
	PrintToChat(client, "[COD] %t", "Exp HostageRescued Message", expForHostageRescue);
	AddAmountOfExp(client, expForHostageRescue);
	
	return Plugin_Continue;
}

public Action:OnHostageHurt(Handle:event, const String:name[], bool:dontbroadcast) {
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (!IsValidClient(client)) {
		return Plugin_Handled;
	}
	
	if(!hasClass[client] || GetClientTeam(client) == CS_TEAM_SPECTATOR) {
		return Plugin_Handled;
	}
	
	PrintToChat(client, "[COD] %t", "Exp HostageHurt Message", expForHostageHurt);
	AddAmountOfExp(client, -expForHostageHurt);
	
	return Plugin_Continue;
}

public Action:OnRoundMVP(Handle:event, const String:name[], bool:dontbroadcast) {
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (!IsValidClient(client)) {
		return Plugin_Handled;
	}
	
	if(!hasClass[client] || GetClientTeam(client) == CS_TEAM_SPECTATOR) {
		return Plugin_Handled;
	}
	
	PrintToChat(client, "[COD] %t", "Exp RoundMVP Message", expForMVP);
	AddAmountOfExp(client, expForMVP);
	
	return Plugin_Continue;
}

public Action:OnBombPlanted(Handle:event, const String:name[], bool:dontbroadcast) {
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (!IsValidClient(client)) {
		return Plugin_Handled;
	}
	
	if(!hasClass[client] || GetClientTeam(client) == CS_TEAM_SPECTATOR) {
		return Plugin_Handled;
	}
	
	PrintToChat(client, "[COD] %t", "Exp BombPlanted Message", expForBombPlanted);
	AddAmountOfExp(client, expForBombPlanted);
	
	return Plugin_Continue;
}

public Action:OnBombDefused(Handle:event, const String:name[], bool:dontbroadcast) {
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (!IsValidClient(client)) {
		return Plugin_Handled;
	}
	
	if(!hasClass[client] || GetClientTeam(client) == CS_TEAM_SPECTATOR) {
		return Plugin_Handled;
	}
	
	PrintToChat(client, "[COD] %t", "Exp BombDefused Message", expForBombDefused);
	AddAmountOfExp(client, expForBombDefused);
	
	return Plugin_Continue;
}

public Action:Listener_JoinTeam(client, const String:command[], args) {
	if(!IsValidClient(client)) {
		return Plugin_Handled;
	}
	
	if(!hasClass[client]) {
		PrintToChat(client, "Aby dolaczyc do rozgrywki musisz miec wybrana klase");
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

public Action:Listener_BuyBlock(client, const String:command[], args) {
	if (IsValidClient(client)) {
		PrintToChat(client, "[COD] %t", "BuyMenu Block Message", client);
	}
	
	return Plugin_Handled;
}

public OnClientPutInServer(client) {
	LoadPlayerData(client);
}

public Action:TeamMenuHook(UserMsg:msg_id, Protobuf:msg, players[], playersNum, bool:reliable, bool:init)
{
	new String:buffermsg[64];
	PbReadString(msg, "name", buffermsg, sizeof(buffermsg));
	
	if (StrEqual(buffermsg, "team", true)) {
		new client = players[0];
		
		if(!IsValidClient(client)) {
			return Plugin_Handled;
		}
		
		CreateTimer(0.1, ChangeTeam_Timer, client, TIMER_FLAG_NO_MAPCHANGE);
		
		return Plugin_Handled;
	}
	
	return Plugin_Continue;
}

public Action:ChangeTeam_Timer(Handle:timer, client) {
	if(!IsValidClient(client)) {
		return Plugin_Handled;
	}
	
	ChangeClientTeam(client, CS_TEAM_SPECTATOR);
	return Plugin_Continue;
}

public OnClientDisconnect(client) {
	SavePlayerData(client);
}

public SavePlayerData(client) {
	if (!IsValidClient(client)) {
		return;
	}
	
	if(numberOfClasses <= 0) {
		PrintToServer("Cannot save data - classes not exists");
		return;
	}
	
	new Handle:DataBase = CreateKeyValues("Player Data");
	FileToKeyValues(DataBase, InfoPath);
	
	new String:SteamID[32];
	GetClientAuthId(client, AuthId_Steam2, SteamID, sizeof(SteamID));
	
	KvJumpToKey(DataBase, SteamID, true);
	
	for (new i = 1; i <= numberOfClasses; i++) {
		KvJumpToKey(DataBase, class_name[i][pos_basic], true);
		
		KvSetNum(DataBase, "exp", exp[client][i]);
		KvSetNum(DataBase, "lvl", lvl[client][i]);
		KvSetNum(DataBase, "advance", advance[client][i]);
		KvSetNum(DataBase, "points", stats_points[client][i]);
		KvSetNum(DataBase, "intelligence", stats_intelligence[client][i]);
		KvSetNum(DataBase, "health", stats_health[client][i]);
		KvSetNum(DataBase, "damage", stats_damage[client][i]);
		KvSetNum(DataBase, "resistance", stats_resistance[client][i]);
		KvSetNum(DataBase, "stamina", stats_stamina[client][i]);
		
		KvGoBack(DataBase);
	}
	KvRewind(DataBase);
	KeyValuesToFile(DataBase, InfoPath);
	CloseHandle(DataBase);
}

public Action:LoadPlayerData_Timer(Handle:timer, client) {
	if(!IsValidClient(client)) {
		return Plugin_Handled;
	}
	
	LoadPlayerData(client);
	return Plugin_Continue;
}

public LoadPlayerData(client) {
	if (!IsValidClient(client)) {
		return;
	}
	
	if(numberOfClasses <= 0) {
		PrintToServer("Cannot load data - classes not exists");
		return;
	}
	
	new Handle:DataBase = CreateKeyValues("Player Data");
	FileToKeyValues(DataBase, InfoPath);
	
	new String:SteamID[32];
	GetClientAuthId(client, AuthId_Steam2, SteamID, sizeof(SteamID));
	
	KvJumpToKey(DataBase, SteamID, true);
	
	for (new i = 1; i <= numberOfClasses; i++) {
		KvJumpToKey(DataBase, class_name[i][pos_basic], true);
		
		exp[client][i] = KvGetNum(DataBase, "exp");
		lvl[client][i] = KvGetNum(DataBase, "lvl", 1);
		advance[client][i] = KvGetNum(DataBase, "advance");
		stats_points[client][i] = KvGetNum(DataBase, "points");
		stats_intelligence[client][i] = KvGetNum(DataBase, "intelligence");
		stats_health[client][i] = KvGetNum(DataBase, "health");
		stats_damage[client][i] = KvGetNum(DataBase, "damage");
		stats_resistance[client][i] = KvGetNum(DataBase, "resistance");
		stats_stamina[client][i] = KvGetNum(DataBase, "stamina");
		
		KvGoBack(DataBase);
	}
	KvRewind(DataBase);
	CloseHandle(DataBase);
}

public Action:ReturnPlayerInfoCommand(client, args) {
	if (!IsValidClient(client)) {
		return Plugin_Handled;
	}
	
	if (args < 1) {
		PrintToChat(client, "Twoja klasa: %s", class_name[class[client]][advance[client][class[client]]]);
		PrintToChat(client, "Twoj exp: %d", exp[client][class[client]]);
		PrintToChat(client, "Twoj lvl: %d", lvl[client][class[client]]);
		PrintToChat(client, "Twoj awans: %d", advance[client]);
		PrintToChat(client, "Twoje punkty do rozdania: %d", stats_points[client][class[client]]);
		PrintToChat(client, "Twoja inteligencja: %d", stats_intelligence[client][class[client]]);
		PrintToChat(client, "Twoje zdrowie: %d", stats_health[client][class[client]]);
		PrintToChat(client, "Twoje obrazenia: %d", stats_damage[client][class[client]]);
		PrintToChat(client, "Twoja odpornosc: %d", stats_resistance[client][class[client]]);
		PrintToChat(client, "Twoja kondycja: %d", stats_stamina[client][class[client]]);
	}
	return Plugin_Continue;
}

public Action:AddExpCommand(client, args) {
	if(!IsValidClient(client)) {
		return Plugin_Handled;
	}
	
	if(!hasClass[client]) {
		return Plugin_Handled;
	}
	
	if(args < 1) {
		AddAmountOfExp(client, 1000);
		return Plugin_Continue;
	}
	else if(args == 1) {
		char arg[10];
		GetCmdArg(1, arg, sizeof(arg));
		int amountOfExp = StringToInt(arg);
		
		AddAmountOfExp(client, amountOfExp);
		return Plugin_Continue;
	}
	
	return Plugin_Continue;
}

public Action:RemoveExpCommand(client, args) {
	if(!IsValidClient(client)) {
		return Plugin_Handled;
	}
	
	if(!hasClass[client]) {
		return Plugin_Handled;
	}
	
	if(args < 1) {
		AddAmountOfExp(client, -1000);
		return Plugin_Continue;
	}
	else if(args == 1) {
		char arg[10];
		GetCmdArg(1, arg, sizeof(arg));
		int amountOfExp = StringToInt(arg);
		
		AddAmountOfExp(client, -amountOfExp);
		return Plugin_Continue;
	}
	
	return Plugin_Continue;
}

public Action:AddAmountOfExp(client, int amount) {
	if(!IsValidClient(client)) {
		return Plugin_Handled;
	}
	
	if(amount == 0) {
		return Plugin_Handled;
	}
	
	if(amount < 0) {
		if(exp[client][class[client]] <= FloatAbs(float(amount))) {
			return Plugin_Handled;
		}
	}
	
	exp[client][class[client]] += amount;
	CheckExp(client);
	
	return Plugin_Continue;
}

public Action:AddExpByDMG(client, int damage) {
	if(!IsValidClient(client)) {
		return Plugin_Handled;
	}
	
	if(damageMultiplier) {
		exp[client][class[client]] += RoundToFloor(damage*damageMultiplier);
		CheckExp(client);
	}
	
	return Plugin_Continue;
}

public Action:CheckExp(client) {
	if(!IsValidClient(client)) {
		return Plugin_Handled;
	}
	
	if(exp[client][class[client]] <= expTable[lvl[client][class[client]]]) {
		if(lvl[client][class[client]] <= 0) {
			return Plugin_Continue;
		}
		
		if(exp[client][class[client]] >= expTable[lvl[client][class[client]]-1]) {
			return Plugin_Continue;
		}
		
		new counter = 0;
		while(exp[client][class[client]] < expTable[lvl[client][class[client]]-counter-1]) {
			if(lvl[client][class[client]]-counter-1 <= 0) {
				break;
			}
			counter++;
		}
		
		if(counter != 0) {
			lvl[client][class[client]] -= counter;
			PrintToChat(client, "[COD] %t", "Lvl Lost Message", lvl[client][class[client]]);
		}
		
		CheckAdvance(client);
		CheckPoints(client);
		return Plugin_Continue;
	}
	
	new counter = 0;
	while(exp[client][class[client]] > expTable[lvl[client][class[client]]+counter]) {
		if(lvl[client][class[client]]+counter >= sizeof(expTable)-1) {
			break;
		}
		counter++;
	}
	
	if(counter != 0) {
		lvl[client][class[client]] += counter;
		PrintToChat(client, "[COD] %t", "Lvl Gained Message", lvl[client][class[client]]);
		
		if(lvl[client][class[client]] == sizeof(expTable)-1) {
			PrintToChat(client, "[COD] %t", "Lvl GainedMaxLVL Message");
		}
	}
	
	CheckAdvance(client);
	CheckPoints(client);
	return Plugin_Continue;
}

public Action:CheckAdvance(client) {
	if(!IsValidClient(client)) {
		return Plugin_Handled;
	}
	
	if(lvl[client][class[client]] >= god) {
		advance[client][class[client]] = pos_god;
		return Plugin_Continue;
	}
	else if(lvl[client][class[client]] >= master) {
		advance[client][class[client]] = pos_master;
		return Plugin_Continue;
	}
	else if(lvl[client][class[client]] >= elite) {
		advance[client][class[client]] = pos_elite;
		return Plugin_Continue;
	}
	else if(lvl[client][class[client]] >= pro) {
		advance[client][class[client]] = pos_pro;
		return Plugin_Continue;
	}
	else {
		advance[client][class[client]] = pos_basic;
	}
	
	return Plugin_Continue;
}

public Action:CheckPoints(client) {
	if(!IsValidClient(client)) {
		return Plugin_Handled;
	}
	
	new sumOfPoints = lvl[client][class[client]] * 2;
	new distributedPoints = stats_intelligence[client][class[client]] + stats_health[client][class[client]] + stats_damage[client][class[client]] + stats_resistance[client][class[client]] + stats_stamina[client][class[client]];
	new tempPoints = sumOfPoints - distributedPoints;
	
	if(tempPoints == 0) {
		return Plugin_Continue;
	}
	else if(tempPoints > 0) {
		PrintToChat(client, "You have points to distribute: %d", sumOfPoints - distributedPoints);
	}
	else if(tempPoints < 0) {
		PrintToChat(client, "[COD] %t", "Lvl LostStatPoints Message");
		
		while(tempPoints < 0) {
			//do zoptymalizowania
			new randNum = GetRandomInt(0, 4);
			
			switch(randNum) {
				case 0: {
					if(stats_intelligence[client][class[client]] > 0) {
						stats_intelligence[client][class[client]]--;
						tempPoints++;
					}
				}
				case 1: {
					if(stats_health[client][class[client]] > 0) {
						stats_health[client][class[client]]--;
						tempPoints++;
					}
				}
				case 2: {
					if(stats_damage[client][class[client]] > 0) {
						stats_damage[client][class[client]]--;
						tempPoints++;
					}
				}
				case 3: {
					if(stats_resistance[client][class[client]] > 0) {
						stats_resistance[client][class[client]]--;
						tempPoints++;
					}
				}
				case 4: {
					if(stats_stamina[client][class[client]] > 0) {
						stats_stamina[client][class[client]]--;
						tempPoints++;
					}
				}
			}
		} 
	}
	
	stats_points[client][class[client]] = tempPoints;
	return Plugin_Continue;
}

public Action:ApplyStats(client) {
	if(!IsValidClient(client)) {
		return Plugin_Handled;
	}
	
	SetEntProp(client, Prop_Send, "m_ArmorValue", 0);
	
	if(!hasClass[client]) {
		return Plugin_Handled;
	}
	
	SetEntData(client, FindDataMapInfo(client, "m_iHealth"), HEALTH_BASE + (stats_health[client][class[client]] * HEALTH_MULTIPLIER) + class_health[class[client]][advance[client][class[client]]]);
	SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", STAMINA_BASE + ((stats_stamina[client][class[client]] + class_stamina[class[client]][advance[client][class[client]]]) * STAMINA_MULTIPLIER));
	
	return Plugin_Continue;
}

public Action:AssignStatsPoints_Menu(client, args) {
	if(!IsValidClient(client)) {
		return Plugin_Handled;
	}
	
	new String:desc[128];
	new Handle:menu = CreateMenu(AssignStatsPoints_Handler);
	
	Format(desc, sizeof(desc), "Przydziel punkty (%d):", stats_points[client]);
	SetMenuTitle(menu, desc);
	
	if (stats_assignAmount[stats_selectedAmount[client]] == 0) {
		Format(desc, sizeof(desc), "Ile dodawac: ALL");
	}
	else {
		Format(desc, sizeof(desc), "Ile dodawac: %d", stats_assignAmount[stats_selectedAmount[client]]);
	}
	AddMenuItem(menu, "1", desc);
	
	Format(desc, sizeof(desc), "Inteligencja: %d/%d", stats_intelligence[client], stats_limit[pos_intelligence]);
	AddMenuItem(menu, "2", desc);
	
	Format(desc, sizeof(desc), "Zdrowie: %d/%d ", stats_health[client], stats_limit[pos_health]);
	AddMenuItem(menu, "3", desc);
	
	Format(desc, sizeof(desc), "Obrazenia: %d/%d", stats_damage[client], stats_limit[pos_damage]);
	AddMenuItem(menu, "4", desc);
	
	Format(desc, sizeof(desc), "Wytrzymalosc: %d/%d", stats_resistance[client], stats_limit[pos_resistance]);
	AddMenuItem(menu, "5", desc);
	
	Format(desc, sizeof(desc), "Kondycja: %d/%d", stats_stamina[client], stats_limit[pos_stamina]);
	AddMenuItem(menu, "6", desc);
	
	Format(desc, sizeof(desc), "Reset punktow");
	AddMenuItem(menu, "7", desc);
	
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
	
	return Plugin_Handled;
}

public AssignStatsPoints_Handler(Handle:classhandle, MenuAction:action, client, position) {
	if (action == MenuAction_Select) {
		new String:item[32];
		GetMenuItem(classhandle, position, item, sizeof(item));
		
		if(!stats_points[client] && !StrEqual(item, "7")) {
			return;
		}
		
		new value;
		if(stats_assignAmount[stats_selectedAmount[client]] == 0) {
			value = stats_points[client][class[client]];
		}
		else if(stats_assignAmount[stats_selectedAmount[client]] > 0){
			value = (stats_points[client][class[client]] > stats_assignAmount[stats_selectedAmount[client]]) ? stats_assignAmount[stats_selectedAmount[client]] : stats_points[client][class[client]];
		}
		
		if(StrEqual(item, "1")) {
			stats_selectedAmount[client]++;
			stats_selectedAmount[client] %= sizeof(stats_assignAmount);
		}
		else if(StrEqual(item, "2")) {
			if(stats_assignAmount[stats_selectedAmount[client]] < 0) {
				if(stats_intelligence[client][class[client]] >= -stats_assignAmount[stats_selectedAmount[client]]) {
					stats_points[client][class[client]] -= stats_assignAmount[stats_selectedAmount[client]];
					stats_intelligence[client][class[client]] += stats_assignAmount[stats_selectedAmount[client]];
				}
				else {
					stats_points[client][class[client]] += stats_intelligence[client][class[client]];
					stats_intelligence[client][class[client]] = 0;
				}
			}
			else {
				stats_intelligence[client][class[client]] += value;
				if(stats_intelligence[client][class[client]] > stats_limit[pos_intelligence]) {
					stats_points[client][class[client]] = stats_points[client][class[client]] - value + (stats_intelligence[client][class[client]] - stats_limit[pos_intelligence]);
					stats_intelligence[client][class[client]] = stats_limit[pos_intelligence];
				}
				else {
					stats_points[client][class[client]] -= value;
				}
			}
		}
		else if(StrEqual(item, "3")) {
			if(stats_assignAmount[stats_selectedAmount[client]] < 0) {
				if(stats_health[client][class[client]] >= -stats_assignAmount[stats_selectedAmount[client]]) {
					stats_points[client][class[client]] -= stats_assignAmount[stats_selectedAmount[client]];
					stats_health[client][class[client]] += stats_assignAmount[stats_selectedAmount[client]];
				}
				else {
					stats_points[client][class[client]] += stats_health[client][class[client]];
					stats_health[client][class[client]] = 0;
				}
			}
			else {
				stats_health[client][class[client]] += value;
				if(stats_health[client][class[client]] > stats_limit[pos_health]) {
					stats_points[client][class[client]] = stats_points[client][class[client]] - value + (stats_health[client][class[client]] - stats_limit[pos_health]);
					stats_health[client][class[client]] = stats_limit[pos_health];
				}
				else {
					stats_points[client][class[client]] -= value;
				}
			}
		}
		else if(StrEqual(item, "4")) {
			if(stats_assignAmount[stats_selectedAmount[client]] < 0) {
				if(stats_damage[client][class[client]] >= -stats_assignAmount[stats_selectedAmount[client]]) {
					stats_points[client][class[client]] -= stats_assignAmount[stats_selectedAmount[client]];
					stats_damage[client][class[client]] += stats_assignAmount[stats_selectedAmount[client]];
				}
				else {
					stats_points[client][class[client]] += stats_damage[client][class[client]];
					stats_damage[client][class[client]] = 0;
				}
			}
			else {
				stats_damage[client][class[client]] += value;
				if(stats_damage[client][class[client]] > stats_limit[pos_damage]) {
					stats_points[client][class[client]] = stats_points[client][class[client]] - value + (stats_damage[client][class[client]] - stats_limit[pos_damage]);
					stats_damage[client][class[client]] = stats_limit[pos_damage];
				}
				else {
					stats_points[client][class[client]] -= value;
				}
			}
		}
		else if(StrEqual(item, "5")) {
			if(stats_assignAmount[stats_selectedAmount[client]] < 0) {
				if(stats_resistance[client][class[client]] >= -stats_assignAmount[stats_selectedAmount[client]]) {
					stats_points[client][class[client]] -= stats_assignAmount[stats_selectedAmount[client]];
					stats_resistance[client][class[client]] += stats_assignAmount[stats_selectedAmount[client]];
				}
				else {
					stats_points[client][class[client]] += stats_resistance[client][class[client]];
					stats_resistance[client][class[client]] = 0;
				}
			}
			else {
				stats_resistance[client][class[client]] += value;
				if(stats_resistance[client][class[client]] > stats_limit[pos_resistance]) {
					stats_points[client][class[client]] = stats_points[client][class[client]] - value + (stats_resistance[client][class[client]] - stats_limit[pos_resistance]);
					stats_resistance[client][class[client]] = stats_limit[pos_resistance];
				}
				else {
					stats_points[client][class[client]] -= value;
				}
			}
		}
		else if(StrEqual(item, "6")) {
			if(stats_assignAmount[stats_selectedAmount[client]] < 0) {
				if(stats_stamina[client][class[client]] >= -stats_assignAmount[stats_selectedAmount[client]]) {
					stats_points[client][class[client]] -= stats_assignAmount[stats_selectedAmount[client]];
					stats_stamina[client][class[client]] += stats_assignAmount[stats_selectedAmount[client]];
				}
				else {
					stats_points[client][class[client]] += stats_stamina[client][class[client]];
					stats_stamina[client][class[client]] = 0;
				}
			}
			else {
				stats_stamina[client][class[client]] += value;
				if(stats_stamina[client][class[client]] > stats_limit[pos_stamina]) {
					stats_points[client][class[client]] = stats_points[client][class[client]] - value + (stats_stamina[client][class[client]] - stats_limit[pos_stamina]);
					stats_stamina[client][class[client]] = stats_limit[pos_stamina];
				}
				else {
					stats_points[client][class[client]] -= value;
				}
			}
		}
		else if(StrEqual(item, "7")) {
			ResetPoints(client);
		}
		
		if(stats_points[client][class[client]]) {
			AssignStatsPoints_Menu(client, 0);
		}
	}
	else if(action == MenuAction_End) {
		CloseHandle(classhandle);
	}
}

public Action:ResetPoints_Command(client, args) {
	if(!IsValidClient(client)) {
		return Plugin_Handled;
	}
	
	ResetPoints(client);
	return Plugin_Continue;
}

public ResetPoints(client) {
	PrintToChat(client, "Punkty zostaly zresetowane");
	stats_points[client][class[client]] = stats_points[client][class[client]] + stats_intelligence[client][class[client]] + stats_health[client][class[client]] + stats_damage[client][class[client]] + stats_resistance[client][class[client]] + stats_stamina[client][class[client]];
	stats_intelligence[client][class[client]] = 0;
	stats_health[client][class[client]] = 0;
	stats_damage[client][class[client]] = 0;
	stats_resistance[client][class[client]] = 0;
	stats_stamina[client][class[client]] = 0;
}

public Action:ChooseClass_Menu(client, args) {
	if(!IsValidClient(client)) {
		return Plugin_Handled;
	}
	
	new String:desc[128];
	new Handle:menu = CreateMenu(ChooseClass_Handler);
	
	Format(desc, sizeof(desc), "Wybierz klase:");
	SetMenuTitle(menu, desc);
	
	new String:temp[3];
	for (new i = 1; i <= numberOfClasses; i++) {
		Format(desc, sizeof(desc), "%s [%dlvl]", class_name[i][advance[client][i]], lvl[client][i]);
		IntToString(i, temp, sizeof(temp));
		AddMenuItem(menu, temp, desc);
	}
	
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
	
	return Plugin_Handled;
}

public ChooseClass_Handler(Handle:classhandle, MenuAction:action, client, position) {
	if (action == MenuAction_Select) {
		new String:item[32];
		GetMenuItem(classhandle, position, item, sizeof(item));
		new itemVal = StringToInt(item);
		
		if(class[client] == itemVal) {
			PrintToChat(client, "Aktualnie korzystasz z klasy: %s", class_name[class[client]][advance[client][class[client]]]);
			return;
		}
		
		if(GetClientTeam(client) == CS_TEAM_SPECTATOR) {
			class[client] = itemVal;
			newClass[client] = itemVal;
			hasClass[client] = true;
			ApplyStats(client);
			return;
		}
		
		newClass[client] = itemVal;
	}
	else if(action == MenuAction_End) {
		CloseHandle(classhandle);
	}
}

public ChangeClientsClasses() {
	for (new client = 1; client < MaxClients; client++) {
		if(!IsValidClient(client)) {
			return;
		}
		
		if(class[client] == newClass[client]) {
			return;
		}
		
		class[client] = newClass[client];
		hasClass[client] = true;
		ApplyStats(client);
	} 
}

public Action:MainMenu_Menu(client, args) {
	new Handle:menu = CreateMenu(MainMenu_Handler);
	SetMenuTitle(menu, "Menu główne:");
	AddMenuItem(menu, "1", "Wybierz klase");
	AddMenuItem(menu, "2", "Opisy klas");
	AddMenuItem(menu, "3", "Opisy itemów");
	AddMenuItem(menu, "4", "Opis serwera");
	AddMenuItem(menu, "5", "Kontakt");
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
	
	return Plugin_Handled;
}

public MainMenu_Handler(Handle:classhandle, MenuAction:action, client, position) {
	if (action == MenuAction_Select) {
		new String:item[32];
		GetMenuItem(classhandle, position, item, 32);
		new itemVal = StringToInt(item);
		
		switch (itemVal) {
			case 1: ChooseClass_Menu(client, 0);
			case 2: ClassesDescription_Menu(client, 0);
			//case 3: ItemsDescription_Menu(client, 0);
			case 4: ServerDescription_Menu(client);
			case 5: Contact_Menu(client);
		}
	}
	else if (action == MenuAction_End) {
		CloseHandle(classhandle);
	}
}

public Action:ServerDescription_Menu(client) {
	new String:desc[DESCLENEXTENDED];
	Format(desc, DESCLENEXTENDED, "Serwer COD MOD oparty o awanse klas [...]");
	
	new Handle:menu = CreateMenu(ServerDescription_Handler);
	SetMenuTitle(menu, desc);
	AddMenuItem(menu, "1", "Menu główne");
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

public ServerDescription_Handler(Handle:classhandle, MenuAction:action, client, position) {
	if (action == MenuAction_Select) {
		MainMenu_Menu(client, 0);
	}
	else if (action == MenuAction_End) {
		CloseHandle(classhandle);
	}
}

public Action:Contact_Menu(client) {
	new String:desc[DESCLENEXTENDED];
	Format(desc, DESCLENEXTENDED, "Forum: www.[...]");
	
	new Handle:menu = CreateMenu(Contact_Handler);
	SetMenuTitle(menu, desc);
	AddMenuItem(menu, "1", "Menu główne");
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

public Contact_Handler(Handle:classhandle, MenuAction:action, client, position) {
	if (action == MenuAction_Select) {
		MainMenu_Menu(client, 0);
	}
	else if (action == MenuAction_End) {
		CloseHandle(classhandle);
	}
}

public Action:ClassesDescription_Menu(client, args) {
	new Handle:menu = CreateMenu(ClassesDescription_Handler);
	SetMenuTitle(menu, "Wybierz grupę:");
	AddMenuItem(menu, "1", "Klasy podstawowe");
	AddMenuItem(menu, "2", "Klasy pro");
	AddMenuItem(menu, "3", "Klasy elite");
	AddMenuItem(menu, "4", "Klasy master");
	AddMenuItem(menu, "5", "Klasy god");
	AddMenuItem(menu, "6", "Powrot do menu głównego");
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
	return Plugin_Handled;
}

public ClassesDescription_Handler(Handle:classhandle, MenuAction:action, client, position) {
	if (action == MenuAction_Select) {
		new String:item[32];
		GetMenuItem(classhandle, position, item, 32);
		new itemVal = StringToInt(item);
		
		switch (itemVal) {
			case 1: DescriptionBasic_Menu(client, 0);
			case 2: DescriptionPro_Menu(client, 0);
			case 3: DescriptionElite_Menu(client, 0);
			case 4: DescriptionMaster_Menu(client, 0);
			case 5: DescriptionGod_Menu(client, 0);
			case 6: MainMenu_Menu(client, 0);
		}
	}
	else if (action == MenuAction_End) {
		CloseHandle(classhandle);
	}
}

public Action:DescriptionBasic_Menu(client, args) {
	new Handle:menu = CreateMenu(DesctiptionBasic_Handler);
	SetMenuTitle(menu, "Wybierz Klase:");
	new String:buffer[8];
	for (new i = 1; i <= numberOfClasses; i++) {
		Format(buffer, sizeof(buffer), "%d", i);
		AddMenuItem(menu, buffer, class_name[i][pos_basic]);
	}
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
	return Plugin_Handled;
}

public DesctiptionBasic_Handler(Handle:classhandle, MenuAction:action, client, position) {
	if (action == MenuAction_Select) {
		new String:item[32];
		GetMenuItem(classhandle, position, item, 32);
		new itemVal = StringToInt(item);
		itemValGlobal[client] = itemVal;
		
		new String:weapons[WEAPONSLEN];
		Format(weapons, WEAPONSLEN, "%s", class_weapons[itemVal][pos_basic]);
		ReplaceString(weapons, sizeof(weapons), "#weapon_", "|");
		
		new String:desc[DESCLENEXTENDED];
		new Function:classForward = GetFunctionByName(class_plugins[itemVal], "cod_class_skill_used");
		if (classForward != INVALID_FUNCTION) {
			Format(desc, DESCLENEXTENDED, "Klasa: %s\nInteligencja: %i\nZdrowie: %i\nObrazenia: %i\nWytrzymalosc: %i\nKondycja: %i\nBronie: %s\nOpis: %s\nUzycie umiejetnosci: Useclass", class_name[itemVal][pos_basic], class_intelligence[itemVal][pos_basic], class_health[itemVal][pos_basic], class_damage[itemVal][pos_basic], class_resistance[itemVal][pos_basic], class_stamina[itemVal][pos_basic], weapons, class_description[itemVal][pos_basic]);
		}
		else {
			Format(desc, DESCLENEXTENDED, "Klasa: %s\nInteligencja: %i\nZdrowie: %i\nObrazenia: %i\nWytrzymalosc: %i\nKondycja: %i\nBronie: %s\nOpis: %s", class_name[itemVal][pos_basic], class_intelligence[itemVal][pos_basic], class_health[itemVal][pos_basic], class_damage[itemVal][pos_basic], class_resistance[itemVal][pos_basic], class_stamina[itemVal][pos_basic], weapons, class_description[itemVal][pos_basic]);
		}
		
		new Handle:menu = CreateMenu(DescriptionBasicBack_Handler);
		SetMenuTitle(menu, desc);
		AddMenuItem(menu, "1", class_name[itemVal][pos_pro]);
		AddMenuItem(menu, "2", "Wroc do listy klas podstawowych");
		AddMenuItem(menu, "3", "Zmień grupę klas");
		DisplayMenu(menu, client, MENU_TIME_FOREVER);
	}
	else if (action == MenuAction_End) {
		CloseHandle(classhandle);
	}
}

public DescriptionBasicBack_Handler(Handle:classhandle, MenuAction:action, client, position) {
	if (action == MenuAction_Select) {
		new String:item[32];
		GetMenuItem(classhandle, position, item, 32);
		new itemVal = StringToInt(item);
		
		switch (itemVal) {
			case 1: DisplayDescription_Menu(client, itemValGlobal[client], pos_pro);
			case 2: DescriptionBasic_Menu(client, 0);
			case 3: ClassesDescription_Menu(client, 0);
		}
	}
	else if (action == MenuAction_End) {
		CloseHandle(classhandle);
	}
}

public Action:DescriptionPro_Menu(client, args) {
	new Handle:menu = CreateMenu(DescriptionPro_Handler);
	SetMenuTitle(menu, "Wybierz Klase:");
	new String:buffer[8];
	for (new i = 1; i <= numberOfClasses; i++) {
		Format(buffer, sizeof(buffer), "%d", i);
		AddMenuItem(menu, buffer, class_name[i][pos_pro]);
	}
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
	return Plugin_Handled;
}

public DescriptionPro_Handler(Handle:classhandle, MenuAction:action, client, position) {
	if (action == MenuAction_Select) {
		new String:item[32];
		GetMenuItem(classhandle, position, item, 32);
		new itemVal = StringToInt(item);
		itemValGlobal[client] = itemVal;
		
		new String:weapons[WEAPONSLEN];
		Format(weapons, WEAPONSLEN, "%s", class_weapons[itemVal][pos_pro]);
		ReplaceString(weapons, sizeof(weapons), "#weapon_", "|");
		
		new String:desc[DESCLENEXTENDED];
		new Function:classForward = GetFunctionByName(class_plugins[itemVal], "cod_class_skill_used");
		if (classForward != INVALID_FUNCTION) {
			Format(desc, DESCLENEXTENDED, "Klasa: %s\nInteligencja: %i\nZdrowie: %i\nObrazenia: %i\nWytrzymalosc: %i\nKondycja: %i\nBronie: %s\nOpis: %s\nUzycie umiejetnosci: Useclass", class_name[itemVal][pos_pro], class_intelligence[itemVal][pos_pro], class_health[itemVal][pos_pro], class_damage[itemVal][pos_pro], class_resistance[itemVal][pos_pro], class_stamina[itemVal][pos_pro], weapons, class_description[itemVal][pos_pro]);
		}
		else {
			Format(desc, DESCLENEXTENDED, "Klasa: %s\nInteligencja: %i\nZdrowie: %i\nObrazenia: %i\nWytrzymalosc: %i\nKondycja: %i\nBronie: %s\nOpis: %s", class_name[itemVal][pos_pro], class_intelligence[itemVal][pos_pro], class_health[itemVal][pos_pro], class_damage[itemVal][pos_pro], class_resistance[itemVal][pos_pro], class_stamina[itemVal][pos_pro], weapons, class_description[itemVal][pos_pro]);
		}
		
		new Handle:menu = CreateMenu(DescriptionProBack_Handler);
		SetMenuTitle(menu, desc);
		AddMenuItem(menu, "1", class_name[itemVal][pos_basic]);
		AddMenuItem(menu, "2", class_name[itemVal][pos_elite]);
		AddMenuItem(menu, "3", "Wroc do listy klas pro");
		AddMenuItem(menu, "4", "Zmień grupę klas");
		DisplayMenu(menu, client, MENU_TIME_FOREVER);
	}
	else if (action == MenuAction_End) {
		CloseHandle(classhandle);
	}
}

public DescriptionProBack_Handler(Handle:classhandle, MenuAction:action, client, position) {
	if (action == MenuAction_Select) {
		new String:item[32];
		GetMenuItem(classhandle, position, item, 32);
		new itemVal = StringToInt(item);
		
		switch (itemVal) {
			case 1: DisplayDescription_Menu(client, itemValGlobal[client], pos_basic);
			case 2: DisplayDescription_Menu(client, itemValGlobal[client], pos_elite);
			case 3: DescriptionPro_Menu(client, 0);
			case 4: ClassesDescription_Menu(client, 0);
		}
	}
	else if (action == MenuAction_End) {
		CloseHandle(classhandle);
	}
}

public Action:DescriptionElite_Menu(client, args) {
	new Handle:menu = CreateMenu(DescriptionElite_Handler);
	SetMenuTitle(menu, "Wybierz Klase:");
	new String:buffer[8];
	for (new i = 1; i <= numberOfClasses; i++) {
		Format(buffer, sizeof(buffer), "%d", i);
		AddMenuItem(menu, buffer, class_name[i][pos_elite]);
	}
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
	return Plugin_Handled;
}

public DescriptionElite_Handler(Handle:classhandle, MenuAction:action, client, position) {
	if (action == MenuAction_Select) {
		new String:item[32];
		GetMenuItem(classhandle, position, item, sizeof(item));
		new itemVal = StringToInt(item);
		
		itemValGlobal[client] = itemVal;
		
		new String:weapons[WEAPONSLEN];
		Format(weapons, WEAPONSLEN, "%s", class_weapons[itemVal][pos_elite]);
		ReplaceString(weapons, sizeof(weapons), "#weapon_", "|");
		
		new String:desc[DESCLENEXTENDED];
		new Function:classForward = GetFunctionByName(class_plugins[itemVal], "cod_class_skill_used");
		if (classForward != INVALID_FUNCTION) {
			Format(desc, DESCLENEXTENDED, "Klasa: %s\nInteligencja: %i\nZdrowie: %i\nObrazenia: %i\nWytrzymalosc: %i\nKondycja: %i\nBronie: %s\nOpis: %s\nUzycie umiejetnosci: Useclass", class_name[itemVal][pos_elite], class_intelligence[itemVal][pos_elite], class_health[itemVal][pos_elite], class_damage[itemVal][pos_elite], class_resistance[itemVal][pos_elite], class_stamina[itemVal][pos_elite], weapons, class_description[itemVal][pos_elite]);
		}
		else {
			Format(desc, DESCLENEXTENDED, "Klasa: %s\nInteligencja: %i\nZdrowie: %i\nObrazenia: %i\nWytrzymalosc: %i\nKondycja: %i\nBronie: %s\nOpis: %s", class_name[itemVal][pos_elite], class_intelligence[itemVal][pos_elite], class_health[itemVal][pos_elite], class_damage[itemVal][pos_elite], class_resistance[itemVal][pos_elite], class_stamina[itemVal][pos_elite], weapons, class_description[itemVal][pos_elite]);
		}
		
		new Handle:menu = CreateMenu(DescriptionEliteBack_Handler);
		SetMenuTitle(menu, desc);
		AddMenuItem(menu, "1", class_name[itemVal][pos_pro]);
		AddMenuItem(menu, "2", class_name[itemVal][pos_master]);
		AddMenuItem(menu, "3", "Wroc do listy klas elite");
		AddMenuItem(menu, "4", "Zmień grupę klas");
		DisplayMenu(menu, client, MENU_TIME_FOREVER);
	}
	else if (action == MenuAction_End) {
		CloseHandle(classhandle);
	}
}

public DescriptionEliteBack_Handler(Handle:classhandle, MenuAction:action, client, position) {
	if (action == MenuAction_Select) {
		new String:item[32];
		GetMenuItem(classhandle, position, item, sizeof(item));
		new itemVal = StringToInt(item);
		
		switch (itemVal) {
			case 1: DisplayDescription_Menu(client, itemValGlobal[client], pos_pro);
			case 2: DisplayDescription_Menu(client, itemValGlobal[client], pos_master);
			case 3: DescriptionElite_Menu(client, 0);
			case 4: ClassesDescription_Menu(client, 0);
		}
	}
	else if (action == MenuAction_End) {
		CloseHandle(classhandle);
	}
}

public Action:DescriptionMaster_Menu(client, args) {
	new Handle:menu = CreateMenu(DescriptionMaster_Handler);
	SetMenuTitle(menu, "Wybierz Klase:");
	new String:buffer[8];
	for (new i = 1; i <= numberOfClasses; i++) {
		Format(buffer, sizeof(buffer), "%d", i);
		AddMenuItem(menu, buffer, class_name[i][pos_master]);
	}
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
	return Plugin_Handled;
}

public DescriptionMaster_Handler(Handle:classhandle, MenuAction:action, client, position) {
	if (action == MenuAction_Select) {
		new String:item[32];
		GetMenuItem(classhandle, position, item, sizeof(item));
		new itemVal = StringToInt(item);
		itemValGlobal[client] = itemVal;
		
		new String:weapons[WEAPONSLEN];
		Format(weapons, WEAPONSLEN, "%s", class_weapons[itemVal][pos_master]);
		ReplaceString(weapons, sizeof(weapons), "#weapon_", "|");
		
		new String:desc[DESCLENEXTENDED];
		new Function:classForward = GetFunctionByName(class_plugins[itemVal], "cod_class_skill_used");
		if (classForward != INVALID_FUNCTION) {
			Format(desc, DESCLENEXTENDED, "Klasa: %s\nInteligencja: %i\nZdrowie: %i\nObrazenia: %i\nWytrzymalosc: %i\nKondycja: %i\nBronie: %s\nOpis: %s\nUzycie umiejetnosci: Useclass", class_name[itemVal][pos_master], class_intelligence[itemVal][pos_master], class_health[itemVal][pos_master], class_damage[itemVal][pos_master], class_resistance[itemVal][pos_master], class_stamina[itemVal][pos_master], weapons, class_description[itemVal][pos_master]);
		}
		else {
			Format(desc, DESCLENEXTENDED, "Klasa: %s\nInteligencja: %i\nZdrowie: %i\nObrazenia: %i\nWytrzymalosc: %i\nKondycja: %i\nBronie: %s\nOpis: %s", class_name[itemVal][pos_master], class_intelligence[itemVal][pos_master], class_health[itemVal][pos_master], class_damage[itemVal][pos_master], class_resistance[itemVal][pos_master], class_stamina[itemVal][pos_master], weapons, class_description[itemVal][pos_master]);
		}
		
		new Handle:menu = CreateMenu(DescriptionMasterBack_Handler);
		SetMenuTitle(menu, desc);
		AddMenuItem(menu, "1", class_name[itemVal][pos_elite]);
		AddMenuItem(menu, "2", class_name[itemVal][pos_god]);
		AddMenuItem(menu, "3", "Wroc do listy klas master");
		AddMenuItem(menu, "4", "Zmień grupę klas");
		DisplayMenu(menu, client, MENU_TIME_FOREVER);
	}
	else if (action == MenuAction_End) {
		CloseHandle(classhandle);
	}
}

public DescriptionMasterBack_Handler(Handle:classhandle, MenuAction:action, client, position) {
	if (action == MenuAction_Select) {
		new String:item[32];
		GetMenuItem(classhandle, position, item, sizeof(item));
		new itemVal = StringToInt(item);
		
		switch (itemVal) {
			case 1: DisplayDescription_Menu(client, itemValGlobal[client], pos_elite);
			case 2: DisplayDescription_Menu(client, itemValGlobal[client], pos_god);
			case 3: DescriptionMaster_Menu(client, 0);
			case 4: ClassesDescription_Menu(client, 0);
		}
	}
	else if (action == MenuAction_End) {
		CloseHandle(classhandle);
	}
}

public Action:DescriptionGod_Menu(client, args) {
	new Handle:menu = CreateMenu(DescriptionGod_Handler);
	SetMenuTitle(menu, "Wybierz Klase:");
	new String:buffer[8];
	for (new i = 1; i <= numberOfClasses; i++) {
		Format(buffer, sizeof(buffer), "%d", i);
		AddMenuItem(menu, buffer, class_name[i][pos_god]);
	}
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
	return Plugin_Handled;
}

public DescriptionGod_Handler(Handle:classhandle, MenuAction:action, client, position) {
	if (action == MenuAction_Select) {
		new String:item[32];
		GetMenuItem(classhandle, position, item, sizeof(item));
		new itemVal = StringToInt(item);
		itemValGlobal[client] = itemVal;
		
		new String:weapons[WEAPONSLEN];
		Format(weapons, WEAPONSLEN, "%s", class_weapons[itemVal][pos_god]);
		ReplaceString(weapons, sizeof(weapons), "#weapon_", "|");
		
		new String:desc[DESCLENEXTENDED];
		new Function:classForward = GetFunctionByName(class_plugins[itemVal], "cod_class_skill_used");
		if (classForward != INVALID_FUNCTION) {
			Format(desc, DESCLENEXTENDED, "Klasa: %s\nInteligencja: %i\nZdrowie: %i\nObrazenia: %i\nWytrzymalosc: %i\nKondycja: %i\nBronie: %s\nOpis: %s\nUzycie umiejetnosci: Useclass", class_name[itemVal][pos_god], class_intelligence[itemVal][pos_god], class_health[itemVal][pos_god], class_damage[itemVal][pos_god], class_resistance[itemVal][pos_god], class_stamina[itemVal][pos_god], weapons, class_description[itemVal][pos_god]);
		}
		else {
			Format(desc, DESCLENEXTENDED, "Klasa: %s\nInteligencja: %i\nZdrowie: %i\nObrazenia: %i\nWytrzymalosc: %i\nKondycja: %i\nBronie: %s\nOpis: %s", class_name[itemVal][pos_god], class_intelligence[itemVal][pos_god], class_health[itemVal][pos_god], class_damage[itemVal][pos_god], class_resistance[itemVal][pos_god], class_stamina[itemVal][pos_god], weapons, class_description[itemVal][pos_god]);
		}
		
		new Handle:menu = CreateMenu(DescriptionGodBack_Handler);
		SetMenuTitle(menu, desc);
		AddMenuItem(menu, "1", class_name[itemVal][pos_master]);
		AddMenuItem(menu, "2", "Wroc do listy klas god");
		AddMenuItem(menu, "3", "Zmień grupę klas");
		DisplayMenu(menu, client, MENU_TIME_FOREVER);
	}
	else if (action == MenuAction_End) {
		CloseHandle(classhandle);
	}
}

public DescriptionGodBack_Handler(Handle:classhandle, MenuAction:action, client, position) {
	if (action == MenuAction_Select) {
		new String:item[32];
		GetMenuItem(classhandle, position, item, sizeof(item));
		new itemVal = StringToInt(item);
		
		switch (itemVal) {
			case 1: DisplayDescription_Menu(client, itemValGlobal[client], pos_master);
			case 3: DescriptionGod_Menu(client, 0);
			case 4: ClassesDescription_Menu(client, 0);
		}
	}
	else if (action == MenuAction_End) {
		CloseHandle(classhandle);
	}
}

public Action:DisplayDescription_Menu(client, itemVal, pos) {
	itemValGlobal[client] = itemVal;
	
	new String:weapons[WEAPONSLEN];
	Format(weapons, WEAPONSLEN, "%s", class_weapons[itemVal][pos]);
	ReplaceString(weapons, sizeof(weapons), "#weapon_", "|");
	
	new String:desc[DESCLENEXTENDED];
	new Function:classForward = GetFunctionByName(class_plugins[itemVal], "cod_class_skill_used");
	if (classForward != INVALID_FUNCTION) {
		Format(desc, DESCLENEXTENDED, "Klasa: %s\nInteligencja: %i\nZdrowie: %i\nObrazenia: %i\nWytrzymalosc: %i\nKondycja: %i\nBronie: %s\nOpis: %s\nUzycie umiejetnosci: Useclass", class_name[itemVal][pos], class_intelligence[itemVal][pos], class_health[itemVal][pos], class_damage[itemVal][pos], class_resistance[itemVal][pos], class_stamina[itemVal][pos], weapons, class_description[itemVal][pos]);
	}
	else {
		Format(desc, DESCLENEXTENDED, "Klasa: %s\nInteligencja: %i\nZdrowie: %i\nObrazenia: %i\nWytrzymalosc: %i\nKondycja: %i\nBronie: %s\nOpis: %s", class_name[itemVal][pos], class_intelligence[itemVal][pos], class_health[itemVal][pos], class_damage[itemVal][pos], class_resistance[itemVal][pos], class_stamina[itemVal][pos], weapons, class_description[itemVal][pos]);
	}
	
	posGlobal[client] = pos;
	
	new Handle:menu = CreateMenu(DisplayDesctiprion_Menu);
	SetMenuTitle(menu, desc);
	if (pos > pos_basic) {
		AddMenuItem(menu, "1", class_name[itemVal][pos-1]);
	}
	if (pos < pos_god) {
		AddMenuItem(menu, "2", class_name[itemVal][pos+1]);
	}
	AddMenuItem(menu, "3", "Zmień grupę klas");
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
	return Plugin_Handled; //tego tu nie bylo
}

public DisplayDesctiprion_Menu(Handle:classhandle, MenuAction:action, client, position) {
	if (action == MenuAction_Select) {
		new String:item[32];
		GetMenuItem(classhandle, position, item, sizeof(item));
		new itemVal = StringToInt(item);

		switch (itemVal) {
			case 1: DisplayDescription_Menu(client, itemValGlobal[client], posGlobal[client]-1);
			case 2: DisplayDescription_Menu(client, itemValGlobal[client], posGlobal[client]+1);
			case 3: ClassesDescription_Menu(client, 0);
		}
	}
	else if (action == MenuAction_End) {
		CloseHandle(classhandle);
	}
}

public Native_RegisterClass(Handle:plugin, args) {
	if(args < 16) {
		return;
	}
	
	numberOfClasses++;
	
	class_plugins[numberOfClasses] = plugin;
	
	new String:tempName[NAMELEN];
	GetNativeString(1, tempName, NAMELEN);
	Format(class_name[numberOfClasses][pos_basic], NAMELEN, "%s", tempName);
	Format(class_name[numberOfClasses][pos_pro], NAMELEN, "[Pro] %s", tempName);
	Format(class_name[numberOfClasses][pos_elite], NAMELEN, "[Elite] %s", tempName);
	Format(class_name[numberOfClasses][pos_master], NAMELEN, "[Master] %s", tempName);
	Format(class_name[numberOfClasses][pos_god], NAMELEN, "[God] %s", tempName);
	
	new counter = 0;
	for (new i = 2; i < 7; i++) {
		GetNativeString(i, class_description[numberOfClasses][counter], DESCLEN);
		GetNativeString(i+5, class_weapons[numberOfClasses][counter], DESCLEN);
		counter++;
	}
	
	GetNativeArray(12, class_intelligence[numberOfClasses], ADVANCESVALUE);
	GetNativeArray(13, class_health[numberOfClasses], ADVANCESVALUE);
	GetNativeArray(14, class_damage[numberOfClasses], ADVANCESVALUE);
	GetNativeArray(15, class_resistance[numberOfClasses], ADVANCESVALUE);
	GetNativeArray(16, class_stamina[numberOfClasses], ADVANCESVALUE);
}

public Native_RegisterItem(Handle:plugin, args) {
	if(args < 4) {
		return;
	}
	
	numberOfItems++;
	
	item_plugins[numberOfItems] = plugin;
	GetNativeString(1, item_name[numberOfItems], sizeof(item_name[]));
	GetNativeString(2, item_description[numberOfItems], sizeof(item_description[]));
	item_minVal[numberOfItems] = GetNativeCell(3);
	item_maxVal[numberOfItems] = GetNativeCell(4);
}

bool:IsValidClient(client) {
	return (1 <= client <= MaxClients && IsClientInGame(client) && IsClientAuthorized(client) && !IsFakeClient(client));
}