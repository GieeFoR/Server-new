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
#define TRIM_MULTIPLIER 0.004
#define TRIM_BASE 0.9

#define MAXCLASSES 10+1
#define MAXITEMS 50+1
#define PROMOTIONSVALUE 5

#define NAMELEN 32
#define DESCLEN 128
#define DESCLENEXTENDED 1024
#define WEAPONSLEN 512

new const String:PLUGIN_NAME[32] = "cod_engine";
new const String:PLUGIN_AUTHOR[32] = "GieeF";
new const String:PLUGIN_VERSION[32] = "0.9";
new const String:PLUGIN_DESCRIPTION[64] = "Plugin wprowadzajacy do cs-go serwery COD Mod";
new const String:PLUGIN_URL[32] = "-";

new bool:player_hasClass[MAXPLAYERS];
new bool:player_hasItem[MAXPLAYERS];

new player_class[MAXPLAYERS];
new player_newClass[MAXPLAYERS];
new player_item[MAXPLAYERS];
new player_itemRandomValue[MAXPLAYERS];
new player_exp[MAXPLAYERS][MAXCLASSES];
new player_lvl[MAXPLAYERS][MAXCLASSES];
new player_promotion[MAXPLAYERS][MAXCLASSES];
new player_stats_points[MAXPLAYERS][MAXCLASSES];
new player_stats_intelligence[MAXPLAYERS][MAXCLASSES];
new player_stats_health[MAXPLAYERS][MAXCLASSES];
new player_stats_damage[MAXPLAYERS][MAXCLASSES];
new player_stats_resistance[MAXPLAYERS][MAXCLASSES];
new player_stats_trim[MAXPLAYERS][MAXCLASSES];

new class_numberOfClasses = 0;
new Handle:class_plugins[MAXCLASSES];
new String:class_name[MAXCLASSES][PROMOTIONSVALUE][NAMELEN];
new String:class_description[MAXCLASSES][PROMOTIONSVALUE][DESCLEN];
new String:class_weapons[MAXCLASSES][PROMOTIONSVALUE][WEAPONSLEN];
new class_intelligence[MAXCLASSES][PROMOTIONSVALUE];
new class_health[MAXCLASSES][PROMOTIONSVALUE];
new class_damage[MAXCLASSES][PROMOTIONSVALUE];
new class_resistance[MAXCLASSES][PROMOTIONSVALUE];
new class_trim[MAXCLASSES][PROMOTIONSVALUE];

new item_numberOfItems = 0;
new Handle:item_plugins[MAXITEMS];
new String:item_name[MAXITEMS][NAMELEN];
new String:item_weapons[MAXITEMS][WEAPONSLEN];
new String:item_description[MAXITEMS][DESCLEN];
new String:item_blackList[MAXITEMS][WEAPONSLEN];
new item_minVal[MAXITEMS];
new item_maxVal[MAXITEMS];
new item_intelligence[MAXITEMS];
new item_health[MAXITEMS];
new item_damage[MAXITEMS];
new item_resistance[MAXITEMS];
new item_trim[MAXITEMS];

new stats_assignAmount[] =  { 1, 10, 50, 0, -1, -10, -50 };
new stats_selectedAmount[MAXPLAYERS];
new stats_limit[] =  { 80, 80, 80, 80, 80 };

new String:weaponsAllowed[][] =  { "weapon_knife", "weapon_c4" };

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
	pos_trim
};

public Plugin:myinfo = {
	name = PLUGIN_NAME, 
	author = PLUGIN_AUTHOR, 
	description = PLUGIN_DESCRIPTION, 
	version = PLUGIN_VERSION, 
	url = PLUGIN_URL
};

public APLRes:AskPluginLoad2(Handle:plugin, bool:late, String:error[], err_max) {
	CreateNative("cod_registerClass", Native_RegisterClass);
	CreateNative("cod_getPlayerClass", Native_GetPlayerClass);
	CreateNative("cod_getPlayerPromotion", Native_GetPlayerPromotion);
	CreateNative("cod_getPlayerMaxHealth", Native_GetPlayerMaxHealth);
	
	CreateNative("cod_inflictDamageWithIntelligence", Native_InflictDamageWithIntelligence);
	
	CreateNative("cod_registerItem", Native_RegisterItem);
	
	CreateNative("cod_getPlayerItem", Native_GetPlayerItem);
	
	pluginLoad = late;
	return APLRes_Success;
}

public OnPluginStart() {
	item_name[0] = "Brak";
	item_description[0] = "Zabij kogoś, aby otrzymać item";

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
				CreateTimer(1.5, LoadPlayerData_Timer, client, TIMER_FLAG_NO_MAPCHANGE);
				CreateTimer(0.1, ChangeTeam_Timer, client, TIMER_FLAG_NO_MAPCHANGE);
			}
			
			
			if(IsValidClient(client)) {
			//if(IsClientAuthorized(client) && IsClientConnected(client)) {
				SDKHook(client, SDKHook_OnTakeDamage, OnPlayerTakeDamage);
				SDKHook(client, SDKHook_WeaponCanUse, WeaponCanUse);
			}
		}
	}
}

public Events() {
	HookEvent("player_spawn", OnPlayerSpawn, EventHookMode_Post);
	HookEvent("player_death", OnPlayerDeath, EventHookMode_Post);
	HookEvent("round_start", OnRoundStart, EventHookMode_Post);
	HookEvent("round_end", OnRoundEnd, EventHookMode_Pre);
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
	AddCommandListener(Listener_DropWeapon, "drop");
	
	RegConsoleCmd("sm_stats", AssignStatsPoints_Menu);
	RegConsoleCmd("sm_staty", AssignStatsPoints_Menu);
	RegConsoleCmd("sm_class", ChooseClass_Menu);
	RegConsoleCmd("sm_klasa", ChooseClass_Menu);
	RegConsoleCmd("sm_classes", ClassesDescription_Menu);
	RegConsoleCmd("sm_klasy", ClassesDescription_Menu);
	RegConsoleCmd("sm_items", ItemsDescription_Menu);
	RegConsoleCmd("sm_itemy", ItemsDescription_Menu);
	RegConsoleCmd("sm_perks", ItemsDescription_Menu);
	RegConsoleCmd("sm_perki", ItemsDescription_Menu);
	RegConsoleCmd("sm_item", ItemDescription);
	RegConsoleCmd("sm_perk", ItemDescription);
	RegConsoleCmd("sm_drop", DropItem);
	RegConsoleCmd("sm_wyrzuc", DropItem);
	RegConsoleCmd("sm_menu", MainMenu_Menu);
	RegConsoleCmd("sm_info", ReturnPlayerInfoCommand);
	RegConsoleCmd("sm_useclass", UseClassSkill);
	RegConsoleCmd("sm_useitem", UseItem);
	RegConsoleCmd("sm_useperk", UseItem);
	
	RegConsoleCmd("sm_addexp", AddExpCommand);
	RegConsoleCmd("sm_remexp", RemoveExpCommand);
	RegConsoleCmd("sm_giveitem", GiveItemCommand);
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
	UnhookEvent("round_start", OnRoundStart, EventHookMode_Post);
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
	GiveWeapons(client);
	return Plugin_Continue;
}

public Action:OnPlayerDeath(Handle:event, const String:name[], bool:dontBroadcast) {
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	new bool:headshot = GetEventBool(event, "headshot");
	
	if(!IsValidClient(attacker)) {
		return Plugin_Handled;
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
	GiveItem(attacker, 0);
	
	return Plugin_Continue;
}

public Action:OnRoundStart(Handle:event, const String:name[], bool:dontbroadcast) {
	ChangeClientsClasses();
	for (new client = 1; client < MaxClients; client++) {
		if(!IsValidClient(client)) {
			continue;
		}
		
		if(player_stats_points[client][player_class[client]] <= 0) {
			continue;
		}
		
		AssignStatsPoints_Menu(client, 0);
	}
}

public Action:OnRoundEnd(Handle:event, const String:name[], bool:dontbroadcast) {
	new winners = GetEventInt(event, "winner");
	
	if(expForRoundWon) {
		for (new client = 1; client < MaxClients; client++) {
			if(!IsValidClient(client)) {
				continue;
			}
			
			if(!player_hasClass[client] || GetClientTeam(client) == CS_TEAM_SPECTATOR) {
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

public Action:OnPlayerHurt(Handle:event, const String:name[], bool:dontbroadcast) {
	new victim = GetClientOfUserId(GetEventInt(event, "userid"));
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	new damage = GetEventInt(event, "dmg_health");
	
	if(!IsValidClient(victim) || !IsValidClient(attacker)) {
		return Plugin_Handled;
	}
	
	if(!player_hasClass[attacker] || GetClientTeam(attacker) == CS_TEAM_SPECTATOR) {
		return Plugin_Handled;
	}
	
	if(GetClientTeam(victim) == GetClientTeam(attacker)) {
		return Plugin_Handled;
	}
	
	AddExpByDMG(attacker, damage, player_lvl[victim][player_class[victim]] - player_lvl[attacker][player_class[attacker]]);
	return Plugin_Continue;
}

public Action:OnHostageRescued(Handle:event, const String:name[], bool:dontbroadcast) {
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (!IsValidClient(client)) {
		return Plugin_Handled;
	}
	
	if(!player_hasClass[client] || GetClientTeam(client) == CS_TEAM_SPECTATOR) {
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
	
	if(!player_hasClass[client] || GetClientTeam(client) == CS_TEAM_SPECTATOR) {
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
	
	if(!player_hasClass[client] || GetClientTeam(client) == CS_TEAM_SPECTATOR) {
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
	
	if(!player_hasClass[client] || GetClientTeam(client) == CS_TEAM_SPECTATOR) {
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
	
	if(!player_hasClass[client] || GetClientTeam(client) == CS_TEAM_SPECTATOR) {
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
	
	if(!player_hasClass[client]) {
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

public Action:Listener_DropWeapon(client, const String:command[], args) {
	if(!IsValidClient(client)) {
		return Plugin_Handled;
	}
	
	new clientWeapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
	new String:weaponName[32];
	GetEdictClassname(clientWeapon, weaponName, sizeof(weaponName));
	
	
	if(!strcmp(weaponName, "weapon_c4")) {
		return Plugin_Continue;
	}
	
	return Plugin_Stop;
}

public OnClientPutInServer(client) {
	LoadPlayerData(client);
	SDKHook(client, SDKHook_OnTakeDamage, OnPlayerTakeDamage);
	SDKHook(client, SDKHook_WeaponCanUse, WeaponCanUse);
	
	ClientCommand(client, "hud_scaling 0.75");	//ciekawe czy to zadziala
}

public OnClientDisconnect(client) {
	SavePlayerData(client);
	SDKUnhook(client, SDKHook_OnTakeDamage, OnPlayerTakeDamage);
	SDKUnhook(client, SDKHook_WeaponCanUse, WeaponCanUse);
	
	new Function:classForward;
	classForward = GetFunctionByName(class_plugins[player_class[client]], "cod_classDisabled");
	if (classForward != INVALID_FUNCTION) {
		Call_StartFunction(class_plugins[player_class[client]], classForward);
		Call_PushCell(client);
		Call_Finish();
	}
	
	new Function:itemForward;
	itemForward = GetFunctionByName(item_plugins[player_item[client]], "cod_itemDisabled");
	if (itemForward != INVALID_FUNCTION) {
		Call_StartFunction(item_plugins[player_item[client]], itemForward);
		Call_PushCell(client);
		Call_Finish();
	}
	
	player_hasClass[client] = false;
	player_hasItem[client] = false;
	
	player_class[client] = 0;
	player_newClass[client] = 0;
	player_item[client] = 0;
	player_itemRandomValue[client] = 0;
}

public OnMapEnd() {
	for (new client = 1; client < MaxClients; client++) {
		new Function:classForward;
		classForward = GetFunctionByName(class_plugins[player_class[client]], "cod_classDisabled");
		if (classForward != INVALID_FUNCTION) {
			Call_StartFunction(class_plugins[player_class[client]], classForward);
			Call_PushCell(client);
			Call_Finish();
		}
		
		new Function:itemForward;
		itemForward = GetFunctionByName(item_plugins[player_item[client]], "cod_itemDisabled");
		if (itemForward != INVALID_FUNCTION) {
			Call_StartFunction(item_plugins[player_item[client]], itemForward);
			Call_PushCell(client);
			Call_Finish();
		}
		
		player_hasClass[client] = false;
		player_hasItem[client] = false;
		
		player_class[client] = 0;
		player_newClass[client] = 0;
		player_item[client] = 0;
		player_itemRandomValue[client] = 0;
	}
}

public OnMapStart() {
	AddFileToDownloadsTable("sound/cod/levelup.mp3");
	AddFileToDownloadsTable("sound/cod/promotion.mp3");
	AutoExecConfig(true, "codmod");
}

public Action:OnPlayerTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype) {
	if(!IsValidClient(victim) || !IsValidClient(attacker)) {
		return Plugin_Continue;
	}
	
	if (GetClientTeam(victim) == GetClientTeam(attacker)) {
		return Plugin_Continue;
	}
	
	new Float:attacker_damage = float(player_stats_damage[attacker][player_class[attacker]] + class_damage[player_class[attacker]][player_promotion[attacker][player_class[attacker]]] + item_damage[player_item[attacker]]);
	new Float:victim_resistance = float(player_stats_resistance[victim][player_class[victim]] + class_resistance[player_class[victim]][player_promotion[victim][player_class[victim]]] + item_resistance[player_item[victim]]);
	
	damage = (damage * (1.0 + attacker_damage/50.0)) / (1.0 + victim_resistance/50.0);
	return Plugin_Changed;
}

public Action:WeaponCanUse(client, weapon) {
	if (!IsValidClient(client) || !IsPlayerAlive(client)) {
		return Plugin_Continue;
	}
	
	if(!player_hasClass[client]) {
		return Plugin_Continue;
	}
	
	new String:weapons[WEAPONSLEN];
	GetEdictClassname(weapon, weapons, sizeof(weapons));
	new weaponindex = GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex");
	switch (weaponindex) {
		case 60:strcopy(weapons, sizeof(weapons), "weapon_m4a1_silencer");
		case 61:strcopy(weapons, sizeof(weapons), "weapon_usp_silencer");
		case 63:strcopy(weapons, sizeof(weapons), "weapon_cz75a");
		case 64:strcopy(weapons, sizeof(weapons), "weapon_revolver");
		case 500:strcopy(weapons, sizeof(weapons), "weapon_bayonet");
		case 505:strcopy(weapons, sizeof(weapons), "weapon_knife_flip");
		case 506:strcopy(weapons, sizeof(weapons), "weapon_knife_gut");
		case 507:strcopy(weapons, sizeof(weapons), "weapon_knife_karambit");
		case 508:strcopy(weapons, sizeof(weapons), "weapon_knife_m9_bayonet");
		case 509:strcopy(weapons, sizeof(weapons), "weapon_knife_tactical");
		case 512:strcopy(weapons, sizeof(weapons), "weapon_knife_falchion");
		case 514:strcopy(weapons, sizeof(weapons), "weapon_knife_survival_bowie");
		case 515:strcopy(weapons, sizeof(weapons), "weapon_knife_butterfly");
		case 516:strcopy(weapons, sizeof(weapons), "weapon_knife_push");
	}
	
	new String:weaponsClass[10][32];
	ExplodeString(class_weapons[player_class[client]][player_promotion[client][player_class[client]]], "#", weaponsClass, sizeof(weaponsClass), sizeof(weaponsClass[]));
	for (new i = 0; i < sizeof(weaponsClass); i++) {
		if (StrEqual(weaponsClass[i], weapons)) {
			return Plugin_Continue;
		}
	}
	
	new String:weaponsItem[10][32];
	ExplodeString(item_weapons[player_item[client]], "#", weaponsItem, sizeof(weaponsItem), sizeof(weaponsItem[]));
	for (new i = 0; i < sizeof(weaponsItem); i++) {
		if (StrEqual(weaponsItem[i], weapons)) {
			return Plugin_Continue;
		}
	}
	
	for (new i = 0; i < sizeof(weaponsAllowed); i++) {
		if (StrEqual(weaponsAllowed[i], weapons)) {
			return Plugin_Continue;
		}
	}
	
	return Plugin_Handled;
}

public Action:GiveWeapons(client) {
	if (!IsPlayerAlive(client))
		return Plugin_Continue;
	
	new ent = -1;
	for (new slot = 0; slot < 4; slot++) {
		if (slot == 2) {
			continue;
		}
		
		ent = GetPlayerWeaponSlot(client, slot);
		if (ent != -1) {
			RemovePlayerItem(client, ent);
		}
	}
	
	new String:weaponsClass[10][32];
	ExplodeString(class_weapons[player_class[client]][player_promotion[client][player_class[client]]], "#", weaponsClass, sizeof(weaponsClass), sizeof(weaponsClass[]));
	for (new i = 0; i < sizeof(weaponsClass); i++) {
		if (!StrEqual(weaponsClass[i], "")) {
			GivePlayerItem(client, weaponsClass[i]);
		}
	}
	
	new String:weaponsItem[5][32];
	ExplodeString(item_weapons[player_item[client]], "#", weaponsItem, sizeof(weaponsItem), sizeof(weaponsItem[]));
	for (new i = 0; i < sizeof(weaponsItem); i++) {
		if (!StrEqual(weaponsItem[i], "")) {
			GivePlayerItem(client, weaponsItem[i]);
		}
	}
	
	return Plugin_Continue;
}

public Action:TeamMenuHook(UserMsg:msg_id, Protobuf:msg, players[], playersNum, bool:reliable, bool:init) {
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

public SavePlayerData(client) {
	if (!IsValidClient(client)) {
		return;
	}
	
	if(class_numberOfClasses <= 0) {
		PrintToServer("Cannot save data - classes not exists");
		return;
	}
	
	new Handle:DataBase = CreateKeyValues("Player Data");
	FileToKeyValues(DataBase, InfoPath);
	
	new String:SteamID[32];
	GetClientAuthId(client, AuthId_Steam2, SteamID, sizeof(SteamID));
	
	KvJumpToKey(DataBase, SteamID, true);
	
	for (new i = 1; i <= class_numberOfClasses; i++) {
		KvJumpToKey(DataBase, class_name[i][pos_basic], true);
		
		KvSetNum(DataBase, "exp", player_exp[client][i]);
		KvSetNum(DataBase, "lvl", player_lvl[client][i]);
		KvSetNum(DataBase, "promotion", player_promotion[client][i]);
		KvSetNum(DataBase, "points", player_stats_points[client][i]);
		KvSetNum(DataBase, "intelligence", player_stats_intelligence[client][i]);
		KvSetNum(DataBase, "health", player_stats_health[client][i]);
		KvSetNum(DataBase, "damage", player_stats_damage[client][i]);
		KvSetNum(DataBase, "resistance", player_stats_resistance[client][i]);
		KvSetNum(DataBase, "trim", player_stats_trim[client][i]);
		
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
	
	if(class_numberOfClasses <= 0) {
		PrintToServer("Cannot load data - classes not exists");
		return;
	}
	
	new Handle:DataBase = CreateKeyValues("Player Data");
	FileToKeyValues(DataBase, InfoPath);
	
	new String:SteamID[32];
	GetClientAuthId(client, AuthId_Steam2, SteamID, sizeof(SteamID));
	
	KvJumpToKey(DataBase, SteamID, true);
	
	for (new i = 1; i <= class_numberOfClasses; i++) {
		KvJumpToKey(DataBase, class_name[i][pos_basic], true);
		
		player_exp[client][i] = KvGetNum(DataBase, "exp");
		player_lvl[client][i] = KvGetNum(DataBase, "lvl", 1);
		player_promotion[client][i] = KvGetNum(DataBase, "promotion");
		player_stats_points[client][i] = KvGetNum(DataBase, "points");
		player_stats_intelligence[client][i] = KvGetNum(DataBase, "intelligence");
		player_stats_health[client][i] = KvGetNum(DataBase, "health");
		player_stats_damage[client][i] = KvGetNum(DataBase, "damage");
		player_stats_resistance[client][i] = KvGetNum(DataBase, "resistance");
		player_stats_trim[client][i] = KvGetNum(DataBase, "trim");
		
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
		PrintToChat(client, "Twoja klasa: %s", class_name[player_class[client]][player_promotion[client][player_class[client]]]);
		PrintToChat(client, "Twoj exp: %d", player_exp[client][player_class[client]]);
		PrintToChat(client, "Twoj lvl: %d", player_lvl[client][player_class[client]]);
		PrintToChat(client, "Twoj awans: %d", player_promotion[client]);
		PrintToChat(client, "Twoje punkty do rozdania: %d", player_stats_points[client][player_class[client]]);
		PrintToChat(client, "Twoja inteligencja: %d", player_stats_intelligence[client][player_class[client]]);
		PrintToChat(client, "Twoje zdrowie: %d", player_stats_health[client][player_class[client]]);
		PrintToChat(client, "Twoje obrazenia: %d", player_stats_damage[client][player_class[client]]);
		PrintToChat(client, "Twoja odpornosc: %d", player_stats_resistance[client][player_class[client]]);
		PrintToChat(client, "Twoja kondycja: %d", player_stats_trim[client][player_class[client]]);
	}
	return Plugin_Continue;
}

public Action:UseClassSkill(client, args) {
	if (!IsValidClient(client)) {
		return Plugin_Handled;
	}
	
	if(!IsPlayerAlive(client)) {
		return Plugin_Handled;
	}
	
	new Function:classForward = GetFunctionByName(class_plugins[player_class[client]], "cod_classSkillUsed");
	if (classForward != INVALID_FUNCTION) {
		Call_StartFunction(class_plugins[player_class[client]], classForward);
		Call_PushCell(client);
		Call_Finish();
	}
	
	return Plugin_Continue;
}

public Action:UseItem(client, args) {
	if (!IsValidClient(client)) {
		return Plugin_Handled;
	}
	
	if (!IsPlayerAlive(client)) {
		return Plugin_Handled;
	}
	
	new Function:itemForward = GetFunctionByName(item_plugins[player_item[client]], "cod_itemUsed");
	if (itemForward != INVALID_FUNCTION) {
		Call_StartFunction(item_plugins[player_item[client]], itemForward);
		Call_PushCell(client);
		Call_Finish();
	}
	
	return Plugin_Continue;
}

public Action:AddExpCommand(client, args) {
	if(!IsValidClient(client)) {
		return Plugin_Handled;
	}
	
	if(!player_hasClass[client]) {
		return Plugin_Handled;
	}
	
	if(args < 1) {
		AddAmountOfExp(client, 1000);
		return Plugin_Continue;
	}
	else if(args == 1) {
		new String:arg[10];
		GetCmdArg(1, arg, sizeof(arg));
		new amountOfExp = StringToInt(arg);
		
		AddAmountOfExp(client, amountOfExp);
		return Plugin_Continue;
	}
	
	return Plugin_Continue;
}

public Action:RemoveExpCommand(client, args) {
	if(!IsValidClient(client)) {
		return Plugin_Handled;
	}
	
	if(!player_hasClass[client]) {
		return Plugin_Handled;
	}
	
	if(args < 1) {
		AddAmountOfExp(client, -1000);
		return Plugin_Continue;
	}
	else if(args == 1) {
		new String:arg[10];
		GetCmdArg(1, arg, sizeof(arg));
		new amountOfExp = StringToInt(arg);
		
		AddAmountOfExp(client, -amountOfExp);
		return Plugin_Continue;
	}
	
	return Plugin_Continue;
}

public Action:AddAmountOfExp(client, amount) {
	if(!IsValidClient(client)) {
		return Plugin_Handled;
	}
	
	if(amount == 0) {
		return Plugin_Handled;
	}
	
	if(amount < 0) {
		if(player_exp[client][player_class[client]] <= FloatAbs(float(amount))) {
			return Plugin_Handled;
		}
	}
	
	if(StrEqual(item_name[player_item[client]], "Podręcznik Expienia")) {
		amount *= 1.5;
	}
	
	player_exp[client][player_class[client]] += amount;
	CheckExp(client);
	
	return Plugin_Continue;
}

public Action:AddExpByDMG(client, damage, lvlDifference) {
	if(!IsValidClient(client)) {
		return Plugin_Handled;
	}
	
	if(!damageMultiplier) {
		return Plugin_Continue;
	}
	
	new Float:lvlFactor;
	if(lvlDifference > 0) {
		lvlFactor = 1.0 + lvlDifference / 100.0;
	}
	else {
		lvlFactor = 1.0;
	}
	
	if(StrEqual(item_name[player_item[client]], "Podręcznik Expienia")) {
		player_exp[client][player_class[client]] += RoundToFloor(damage*damageMultiplier*1.5*lvlFactor);
	}
	else {
		player_exp[client][player_class[client]] += RoundToFloor(damage*damageMultiplier*lvlFactor);
	}
	CheckExp(client);
	return Plugin_Continue;
}

public Action:GiveItemCommand(client, args) {
	new String:arg[8];
	GetCmdArg(1, arg, sizeof(arg));
	GiveItem(client, StringToInt(arg));
	
	return Plugin_Continue;
}

public Action:GiveItem(client, itemNumber) {
	if(!IsValidClient(client)) {
		return Plugin_Handled;
	}
	
	if(player_hasItem[client]) {
		return Plugin_Continue;
	}
	
	new bool:correctItem;
	new random;
	new String:blacklist[5][32];
	
	do {
		correctItem = true;
		if(itemNumber == 0) {
			random = GetRandomInt(1, item_numberOfItems);
		}
		else {
			random = itemNumber;
		}
		
		ExplodeString(item_blackList[random], "#", blacklist, sizeof(blacklist), sizeof(blacklist[]));
		for (new i = 0; i < 5; i++) {
			if(StrEqual(blacklist[i], class_name[player_class[client]][0])) {
				correctItem = false;
				itemNumber = 0;
			}
		}
	} while (!correctItem);
	
	player_item[client] = random;
	player_hasItem[client] = true;
	
	new Function:itemForward;
	itemForward = GetFunctionByName(item_plugins[player_item[client]], "cod_itemEnabled");
	if (itemForward != INVALID_FUNCTION) {
		Call_StartFunction(item_plugins[player_item[client]], itemForward);
		Call_PushCell(client);
		Call_Finish();
	}
	
	new Function:itemValueForward;
	itemValueForward = GetFunctionByName(item_plugins[player_item[client]], "cod_returnItemValue");
	if (itemValueForward != INVALID_FUNCTION) {
		Call_StartFunction(item_plugins[player_item[client]], itemValueForward);
		Call_PushCell(client);
		Call_Finish(player_itemRandomValue[client]);
	}
	else {
		player_itemRandomValue[client] = 0;
	}
	return Plugin_Continue;
}

public Action:DropItem(client, args) {
	if(!IsValidClient(client)) {
		return Plugin_Handled;
	}
	
	if(!player_hasItem[client]) {
		PrintToChat(client, "Nie posiadasz itemu do wyrzucenia");
		return Plugin_Continue;
	}
	
	new Function:itemForward;
	itemForward = GetFunctionByName(item_plugins[player_item[client]], "cod_itemDisabled");
	if (itemForward != INVALID_FUNCTION) {
		Call_StartFunction(item_plugins[player_item[client]], itemForward);
		Call_PushCell(client);
		Call_Finish();
	}
	
	player_hasItem[client] = false;
	PrintToChat(client, "Wyrzuciles %s", item_name[player_item[client]]);
	player_item[client] = 0;
	player_itemRandomValue[client] = 0;
	return Plugin_Continue;
}

public Action:CheckExp(client) {
	if(!IsValidClient(client)) {
		return Plugin_Handled;
	}
	
	if(player_exp[client][player_class[client]] <= expTable[player_lvl[client][player_class[client]]]) {
		if(player_lvl[client][player_class[client]] <= 0) {
			return Plugin_Continue;
		}
		
		if(player_exp[client][player_class[client]] >= expTable[player_lvl[client][player_class[client]]-1]) {
			return Plugin_Continue;
		}
		
		new counter = 0;
		while(player_exp[client][player_class[client]] < expTable[player_lvl[client][player_class[client]]-counter-1]) {
			if(player_lvl[client][player_class[client]]-counter-1 <= 0) {
				break;
			}
			counter++;
		}
		
		if(counter != 0) {
			player_lvl[client][player_class[client]] -= counter;
			PrintToChat(client, "[COD] %t", "Lvl Lost Message", player_lvl[client][player_class[client]]);
		}
		
		CheckPromotion(client);
		CheckPoints(client);
		return Plugin_Continue;
	}
	
	new counter = 0;
	while(player_exp[client][player_class[client]] > expTable[player_lvl[client][player_class[client]]+counter]) {
		if(player_lvl[client][player_class[client]]+counter >= sizeof(expTable)-1) {
			break;
		}
		counter++;
	}
	
	if(counter != 0) {
		player_lvl[client][player_class[client]] += counter;
		PrintToChat(client, "[COD] %t", "Lvl Gained Message", player_lvl[client][player_class[client]]);
		ClientCommand(client, "play *cod/levelup.mp3");
		
		if(player_lvl[client][player_class[client]] == sizeof(expTable)-1) {
			PrintToChat(client, "[COD] %t", "Lvl GainedMaxLVL Message");
		}
	}
	
	CheckPromotion(client);
	CheckPoints(client);
	AssignStatsPoints_Menu(client, 0);
	return Plugin_Continue;
}

public Action:CheckPromotion(client) {
	if(!IsValidClient(client)) {
		return Plugin_Handled;
	}
	
	if(player_lvl[client][player_class[client]] >= god) {
		if(player_promotion[client][player_class[client]] < pos_god) {
			//awans
			ClientCommand(client, "play *cod/promotion.mp3");
		}
		player_promotion[client][player_class[client]] = pos_god;
	}
	else if(player_lvl[client][player_class[client]] >= master) {
		if(player_promotion[client][player_class[client]] < pos_master) {
			//awans
			ClientCommand(client, "play *cod/promotion.mp3");
		}
		else if (player_promotion[client][player_class[client]] > pos_master){
			//degrad
		}
		player_promotion[client][player_class[client]] = pos_master;
	}
	else if(player_lvl[client][player_class[client]] >= elite) {
		if(player_promotion[client][player_class[client]] < pos_elite) {
			//awans
			ClientCommand(client, "play *cod/promotion.mp3");
		}
		else if (player_promotion[client][player_class[client]] > pos_elite){
			//degrad
		}
		player_promotion[client][player_class[client]] = pos_elite;
	}
	else if(player_lvl[client][player_class[client]] >= pro) {
		if(player_promotion[client][player_class[client]] < pos_pro) {
			//awans
			ClientCommand(client, "play *cod/promotion.mp3");
		}
		else if (player_promotion[client][player_class[client]] > pos_pro){
			//degrad
		}
		player_promotion[client][player_class[client]] = pos_pro;
	}
	else {
		if (player_promotion[client][player_class[client]] > pos_basic){
			//degrad
		}
		player_promotion[client][player_class[client]] = pos_basic;
	}
	
	new Function:classForward;
	classForward = GetFunctionByName(class_plugins[player_class[client]], "cod_classEnabled");
	if (classForward != INVALID_FUNCTION) {
		Call_StartFunction(class_plugins[player_class[client]], classForward);
		Call_PushCell(client);
		Call_PushCell(player_promotion[client][player_class[client]]);
		Call_Finish();
	}
	
	return Plugin_Continue;
}

public Action:CheckPoints(client) {
	if(!IsValidClient(client)) {
		return Plugin_Handled;
	}
	
	new sumOfPoints = player_lvl[client][player_class[client]] * 2;
	new distributedPoints = player_stats_intelligence[client][player_class[client]] + player_stats_health[client][player_class[client]] + player_stats_damage[client][player_class[client]] + player_stats_resistance[client][player_class[client]] + player_stats_trim[client][player_class[client]];
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
					if(player_stats_intelligence[client][player_class[client]] > 0) {
						player_stats_intelligence[client][player_class[client]]--;
						tempPoints++;
					}
				}
				case 1: {
					if(player_stats_health[client][player_class[client]] > 0) {
						player_stats_health[client][player_class[client]]--;
						tempPoints++;
					}
				}
				case 2: {
					if(player_stats_damage[client][player_class[client]] > 0) {
						player_stats_damage[client][player_class[client]]--;
						tempPoints++;
					}
				}
				case 3: {
					if(player_stats_resistance[client][player_class[client]] > 0) {
						player_stats_resistance[client][player_class[client]]--;
						tempPoints++;
					}
				}
				case 4: {
					if(player_stats_trim[client][player_class[client]] > 0) {
						player_stats_trim[client][player_class[client]]--;
						tempPoints++;
					}
				}
			}
		} 
	}
	
	player_stats_points[client][player_class[client]] = tempPoints;
	return Plugin_Continue;
}

public Action:ApplyStats(client) {
	if(!IsValidClient(client)) {
		return Plugin_Handled;
	}
	
	SetEntProp(client, Prop_Send, "m_ArmorValue", 0);
	
	if(!player_hasClass[client]) {
		return Plugin_Handled;
	}
	
	SetEntData(client, FindDataMapInfo(client, "m_iHealth"), HEALTH_BASE + (player_stats_health[client][player_class[client]] * HEALTH_MULTIPLIER) + class_health[player_class[client]][player_promotion[client][player_class[client]]] + item_health[player_item[client]]);
	SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", TRIM_BASE + ((player_stats_trim[client][player_class[client]] + class_trim[player_class[client]][player_promotion[client][player_class[client]]] + item_trim[player_item[client]]) * TRIM_MULTIPLIER));
	
	return Plugin_Continue;
}

public Action:AssignStatsPoints_Menu(client, args) {
	if(!IsValidClient(client)) {
		return Plugin_Handled;
	}
	
	new String:desc[128];
	new Handle:menu = CreateMenu(AssignStatsPoints_Handler);
	
	Format(desc, sizeof(desc), "Przydziel punkty (%d):", player_stats_points[client][player_class[client]]);
	SetMenuTitle(menu, desc);
	
	if (stats_assignAmount[stats_selectedAmount[client]] == 0) {
		Format(desc, sizeof(desc), "Ile dodawac: ALL");
	}
	else {
		Format(desc, sizeof(desc), "Ile dodawac: %d", stats_assignAmount[stats_selectedAmount[client]]);
	}
	AddMenuItem(menu, "1", desc);
	
	Format(desc, sizeof(desc), "Inteligencja: %d/%d", player_stats_intelligence[client][player_class[client]], stats_limit[pos_intelligence]);
	AddMenuItem(menu, "2", desc);
	
	Format(desc, sizeof(desc), "Zdrowie: %d/%d ", player_stats_health[client][player_class[client]], stats_limit[pos_health]);
	AddMenuItem(menu, "3", desc);
	
	Format(desc, sizeof(desc), "Obrazenia: %d/%d", player_stats_damage[client][player_class[client]], stats_limit[pos_damage]);
	AddMenuItem(menu, "4", desc);
	
	Format(desc, sizeof(desc), "Wytrzymalosc: %d/%d", player_stats_resistance[client][player_class[client]], stats_limit[pos_resistance]);
	AddMenuItem(menu, "5", desc);
	
	Format(desc, sizeof(desc), "Kondycja: %d/%d", player_stats_trim[client][player_class[client]], stats_limit[pos_trim]);
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
		
		if(!player_stats_points[client] && !StrEqual(item, "7")) {
			return;
		}
		
		new value;
		if(stats_assignAmount[stats_selectedAmount[client]] == 0) {
			value = player_stats_points[client][player_class[client]];
		}
		else if(stats_assignAmount[stats_selectedAmount[client]] > 0){
			value = (player_stats_points[client][player_class[client]] > stats_assignAmount[stats_selectedAmount[client]]) ? stats_assignAmount[stats_selectedAmount[client]] : player_stats_points[client][player_class[client]];
		}
		
		if(StrEqual(item, "1")) {
			stats_selectedAmount[client]++;
			stats_selectedAmount[client] %= sizeof(stats_assignAmount);
		}
		else if(StrEqual(item, "2")) {
			if(stats_assignAmount[stats_selectedAmount[client]] < 0) {
				if(player_stats_intelligence[client][player_class[client]] >= -stats_assignAmount[stats_selectedAmount[client]]) {
					player_stats_points[client][player_class[client]] -= stats_assignAmount[stats_selectedAmount[client]];
					player_stats_intelligence[client][player_class[client]] += stats_assignAmount[stats_selectedAmount[client]];
				}
				else {
					player_stats_points[client][player_class[client]] += player_stats_intelligence[client][player_class[client]];
					player_stats_intelligence[client][player_class[client]] = 0;
				}
			}
			else {
				player_stats_intelligence[client][player_class[client]] += value;
				if(player_stats_intelligence[client][player_class[client]] > stats_limit[pos_intelligence]) {
					player_stats_points[client][player_class[client]] = player_stats_points[client][player_class[client]] - value + (player_stats_intelligence[client][player_class[client]] - stats_limit[pos_intelligence]);
					player_stats_intelligence[client][player_class[client]] = stats_limit[pos_intelligence];
				}
				else {
					player_stats_points[client][player_class[client]] -= value;
				}
			}
		}
		else if(StrEqual(item, "3")) {
			if(stats_assignAmount[stats_selectedAmount[client]] < 0) {
				if(player_stats_health[client][player_class[client]] >= -stats_assignAmount[stats_selectedAmount[client]]) {
					player_stats_points[client][player_class[client]] -= stats_assignAmount[stats_selectedAmount[client]];
					player_stats_health[client][player_class[client]] += stats_assignAmount[stats_selectedAmount[client]];
				}
				else {
					player_stats_points[client][player_class[client]] += player_stats_health[client][player_class[client]];
					player_stats_health[client][player_class[client]] = 0;
				}
			}
			else {
				player_stats_health[client][player_class[client]] += value;
				if(player_stats_health[client][player_class[client]] > stats_limit[pos_health]) {
					player_stats_points[client][player_class[client]] = player_stats_points[client][player_class[client]] - value + (player_stats_health[client][player_class[client]] - stats_limit[pos_health]);
					player_stats_health[client][player_class[client]] = stats_limit[pos_health];
				}
				else {
					player_stats_points[client][player_class[client]] -= value;
				}
			}
		}
		else if(StrEqual(item, "4")) {
			if(stats_assignAmount[stats_selectedAmount[client]] < 0) {
				if(player_stats_damage[client][player_class[client]] >= -stats_assignAmount[stats_selectedAmount[client]]) {
					player_stats_points[client][player_class[client]] -= stats_assignAmount[stats_selectedAmount[client]];
					player_stats_damage[client][player_class[client]] += stats_assignAmount[stats_selectedAmount[client]];
				}
				else {
					player_stats_points[client][player_class[client]] += player_stats_damage[client][player_class[client]];
					player_stats_damage[client][player_class[client]] = 0;
				}
			}
			else {
				player_stats_damage[client][player_class[client]] += value;
				if(player_stats_damage[client][player_class[client]] > stats_limit[pos_damage]) {
					player_stats_points[client][player_class[client]] = player_stats_points[client][player_class[client]] - value + (player_stats_damage[client][player_class[client]] - stats_limit[pos_damage]);
					player_stats_damage[client][player_class[client]] = stats_limit[pos_damage];
				}
				else {
					player_stats_points[client][player_class[client]] -= value;
				}
			}
		}
		else if(StrEqual(item, "5")) {
			if(stats_assignAmount[stats_selectedAmount[client]] < 0) {
				if(player_stats_resistance[client][player_class[client]] >= -stats_assignAmount[stats_selectedAmount[client]]) {
					player_stats_points[client][player_class[client]] -= stats_assignAmount[stats_selectedAmount[client]];
					player_stats_resistance[client][player_class[client]] += stats_assignAmount[stats_selectedAmount[client]];
				}
				else {
					player_stats_points[client][player_class[client]] += player_stats_resistance[client][player_class[client]];
					player_stats_resistance[client][player_class[client]] = 0;
				}
			}
			else {
				player_stats_resistance[client][player_class[client]] += value;
				if(player_stats_resistance[client][player_class[client]] > stats_limit[pos_resistance]) {
					player_stats_points[client][player_class[client]] = player_stats_points[client][player_class[client]] - value + (player_stats_resistance[client][player_class[client]] - stats_limit[pos_resistance]);
					player_stats_resistance[client][player_class[client]] = stats_limit[pos_resistance];
				}
				else {
					player_stats_points[client][player_class[client]] -= value;
				}
			}
		}
		else if(StrEqual(item, "6")) {
			if(stats_assignAmount[stats_selectedAmount[client]] < 0) {
				if(player_stats_trim[client][player_class[client]] >= -stats_assignAmount[stats_selectedAmount[client]]) {
					player_stats_points[client][player_class[client]] -= stats_assignAmount[stats_selectedAmount[client]];
					player_stats_trim[client][player_class[client]] += stats_assignAmount[stats_selectedAmount[client]];
				}
				else {
					player_stats_points[client][player_class[client]] += player_stats_trim[client][player_class[client]];
					player_stats_trim[client][player_class[client]] = 0;
				}
			}
			else {
				player_stats_trim[client][player_class[client]] += value;
				if(player_stats_trim[client][player_class[client]] > stats_limit[pos_trim]) {
					player_stats_points[client][player_class[client]] = player_stats_points[client][player_class[client]] - value + (player_stats_trim[client][player_class[client]] - stats_limit[pos_trim]);
					player_stats_trim[client][player_class[client]] = stats_limit[pos_trim];
				}
				else {
					player_stats_points[client][player_class[client]] -= value;
				}
			}
		}
		else if(StrEqual(item, "7")) {
			ResetPoints(client);
		}
		
		if(player_stats_points[client][player_class[client]]) {
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
	player_stats_points[client][player_class[client]] = player_stats_points[client][player_class[client]] + player_stats_intelligence[client][player_class[client]] + player_stats_health[client][player_class[client]] + player_stats_damage[client][player_class[client]] + player_stats_resistance[client][player_class[client]] + player_stats_trim[client][player_class[client]];
	player_stats_intelligence[client][player_class[client]] = 0;
	player_stats_health[client][player_class[client]] = 0;
	player_stats_damage[client][player_class[client]] = 0;
	player_stats_resistance[client][player_class[client]] = 0;
	player_stats_trim[client][player_class[client]] = 0;
	AssignStatsPoints_Menu(client, 0);
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
	for (new i = 1; i <= class_numberOfClasses; i++) {
		Format(desc, sizeof(desc), "%s [%dlvl]", class_name[i][player_promotion[client][i]], player_lvl[client][i]);
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
		
		if(player_class[client] == itemVal) {
			PrintToChat(client, "Aktualnie korzystasz z klasy: %s", class_name[player_class[client]][player_promotion[client][player_class[client]]]);
			return;
		}
		
		if(!player_hasClass[client]) {
			CreateTimer(0.5, PlayerInfo_HUD, client, TIMER_REPEAT);
		}
		
		if(GetClientTeam(client) == CS_TEAM_SPECTATOR) {
			new state;
			new Function:classForward;
			classForward = GetFunctionByName(class_plugins[itemVal], "cod_classEnabled");
			if (classForward != INVALID_FUNCTION) {
				Call_StartFunction(class_plugins[itemVal], classForward);
				Call_PushCell(client);
				Call_PushCell(0);
				Call_Finish(state);
			}
			if(state == 4) {
				classForward = GetFunctionByName(class_plugins[itemVal], "cod_classDisabled");
				if (classForward != INVALID_FUNCTION) {
					Call_StartFunction(class_plugins[itemVal], classForward);
					Call_PushCell(client);
					Call_Finish();
				}
				
				return;
			}
			
			player_newClass[client] = itemVal;
			player_hasClass[client] = true;
			
			classForward = GetFunctionByName(class_plugins[player_newClass[client]], "cod_classEnabled");
			if (classForward != INVALID_FUNCTION) {
				Call_StartFunction(class_plugins[player_newClass[client]], classForward);
				Call_PushCell(client);
				Call_PushCell(player_promotion[client][player_newClass[client]]);
				Call_Finish();
			}
			
			if(player_class[client] > 0) {
				classForward = GetFunctionByName(class_plugins[player_class[client]], "cod_classDisabled");
				if (classForward != INVALID_FUNCTION) {
					Call_StartFunction(class_plugins[player_class[client]], classForward);
					Call_PushCell(client);
					Call_Finish();
				}
			}
			
			player_class[client] = player_newClass[client];
			
			ApplyStats(client);
			return;
		}
		
		new Function:classForward;
		new state;
		classForward = GetFunctionByName(class_plugins[itemVal], "cod_classEnabled");
		if (classForward != INVALID_FUNCTION) {
			Call_StartFunction(class_plugins[itemVal], classForward);
			Call_PushCell(client);
			Call_PushCell(player_promotion[client][itemVal]);
			Call_Finish(state);
		}
		if(state == 4) {
			classForward = GetFunctionByName(class_plugins[itemVal], "cod_classDisabled");
			if (classForward != INVALID_FUNCTION) {
				Call_StartFunction(class_plugins[itemVal], classForward);
				Call_PushCell(client);
				Call_Finish();
			}
			return;
		}
		player_newClass[client] = itemVal;
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
		
		if(player_class[client] == player_newClass[client]) {
			return;
		}
		
		new Function:classForward;
		classForward = GetFunctionByName(class_plugins[player_newClass[client]], "cod_classEnabled");
		if (classForward != INVALID_FUNCTION) {
			Call_StartFunction(class_plugins[player_newClass[client]], classForward);
			Call_PushCell(client);
			Call_PushCell(player_promotion[client][player_newClass[client]]);
			Call_Finish();
		}
		
		classForward = GetFunctionByName(class_plugins[player_class[client]], "cod_classDisabled");
		if (classForward != INVALID_FUNCTION) {
			Call_StartFunction(class_plugins[player_class[client]], classForward);
			Call_PushCell(client);
			Call_Finish();
		}
		
		player_class[client] = player_newClass[client];
		player_hasClass[client] = true;
		ApplyStats(client);
		GiveWeapons(client);
	} 
}

public Action:PlayerInfo_HUD(Handle:timer, client) {
	if(!IsValidClient(client)) {
		return Plugin_Handled;
	}
	
	if (IsPlayerAlive(client)) {
		PrintHintText(client, "[Klasa: %s]\n[Xp: %i | Lv: %i]\n[Item: %s]", class_name[player_class[client]][player_promotion[client][player_class[client]]], player_exp[client][player_class[client]], player_lvl[client][player_class[client]], item_name[player_item[client]]);
		//PrintHintText(client, "<font color='#008000'>[Klasa: <b>%s</b>]\n[Xp: <b>%i</b> | Lv: <b>%i</b>]\n[Item: <b>%s</b>]</font>", class_name[player_class[client]][player_promotion[client][player_class[client]]], player_exp[client][player_class[client]], player_lvl[client][player_class[client]], item_name[player_item[client]]);
	}
	else {
		new spect = GetEntProp(client, Prop_Send, "m_iObserverMode");
		if (spect == 4 || spect == 5) {
			new target = GetEntPropEnt(client, Prop_Send, "m_hObserverTarget");
			if (target != -1 && IsValidClient(target)) {
				//PrintHintText(client, "<font color='#FFFFFF'>[Klasa: <b>%s</b>]\n[Xp: <b>%i</b> | Lv: <b>%i</b>]\n[Item: <b>%s</b>]</font>", class_name[player_class[target]][player_promotion[target][player_class[target]]], player_exp[target][player_class[target]], player_lvl[target][player_class[target]], item_name[player_item[target]]);
				PrintHintText(client, "[Klasa: %s]\n[Xp: %i | Lv: %i]\n[Item: %s]", class_name[player_class[target]][player_promotion[target][player_class[target]]], player_exp[target][player_class[target]], player_lvl[target][player_class[target]], item_name[player_item[target]]);
			}
		}
	}
	
	return Plugin_Continue;
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
			case 3: ItemsDescription_Menu(client, 0);
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
	for (new i = 1; i <= class_numberOfClasses; i++) {
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
		/*
		new Function:classForward = GetFunctionByName(class_plugins[itemVal], "cod_classSkillUsed");
		if (classForward != INVALID_FUNCTION) {
			Format(desc, DESCLENEXTENDED, "Klasa: %s\nInteligencja: %i\nZdrowie: %i\nObrazenia: %i\nWytrzymalosc: %i\nKondycja: %i\nBronie: %s\nOpis: %s\nUzycie umiejetnosci: useclass", class_name[itemVal][pos_basic], class_intelligence[itemVal][pos_basic], class_health[itemVal][pos_basic], class_damage[itemVal][pos_basic], class_resistance[itemVal][pos_basic], class_trim[itemVal][pos_basic], weapons, class_description[itemVal][pos_basic]);
		}
		else {*/
		Format(desc, DESCLENEXTENDED, "Klasa: %s\nInteligencja: %i\nZdrowie: %i\nObrazenia: %i\nWytrzymalosc: %i\nKondycja: %i\nBronie: %s\nOpis: %s", class_name[itemVal][pos_basic], class_intelligence[itemVal][pos_basic], class_health[itemVal][pos_basic], class_damage[itemVal][pos_basic], class_resistance[itemVal][pos_basic], class_trim[itemVal][pos_basic], weapons, class_description[itemVal][pos_basic]);
		//}
		
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
	for (new i = 1; i <= class_numberOfClasses; i++) {
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
		/*
		new Function:classForward = GetFunctionByName(class_plugins[itemVal], "cod_classSkillUsed");
		if (classForward != INVALID_FUNCTION) {
			Format(desc, DESCLENEXTENDED, "Klasa: %s\nInteligencja: %i\nZdrowie: %i\nObrazenia: %i\nWytrzymalosc: %i\nKondycja: %i\nBronie: %s\nOpis: %s\nUzycie umiejetnosci: useclass", class_name[itemVal][pos_pro], class_intelligence[itemVal][pos_pro], class_health[itemVal][pos_pro], class_damage[itemVal][pos_pro], class_resistance[itemVal][pos_pro], class_trim[itemVal][pos_pro], weapons, class_description[itemVal][pos_pro]);
		}
		else {*/
		Format(desc, DESCLENEXTENDED, "Klasa: %s\nInteligencja: %i\nZdrowie: %i\nObrazenia: %i\nWytrzymalosc: %i\nKondycja: %i\nBronie: %s\nOpis: %s", class_name[itemVal][pos_pro], class_intelligence[itemVal][pos_pro], class_health[itemVal][pos_pro], class_damage[itemVal][pos_pro], class_resistance[itemVal][pos_pro], class_trim[itemVal][pos_pro], weapons, class_description[itemVal][pos_pro]);
		//}
		
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
	for (new i = 1; i <= class_numberOfClasses; i++) {
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
		/*
		new Function:classForward = GetFunctionByName(class_plugins[itemVal], "cod_classSkillUsed");
		if (classForward != INVALID_FUNCTION) {
			Format(desc, DESCLENEXTENDED, "Klasa: %s\nInteligencja: %i\nZdrowie: %i\nObrazenia: %i\nWytrzymalosc: %i\nKondycja: %i\nBronie: %s\nOpis: %s\nUzycie umiejetnosci: useclass", class_name[itemVal][pos_elite], class_intelligence[itemVal][pos_elite], class_health[itemVal][pos_elite], class_damage[itemVal][pos_elite], class_resistance[itemVal][pos_elite], class_trim[itemVal][pos_elite], weapons, class_description[itemVal][pos_elite]);
		}
		else {*/
		Format(desc, DESCLENEXTENDED, "Klasa: %s\nInteligencja: %i\nZdrowie: %i\nObrazenia: %i\nWytrzymalosc: %i\nKondycja: %i\nBronie: %s\nOpis: %s", class_name[itemVal][pos_elite], class_intelligence[itemVal][pos_elite], class_health[itemVal][pos_elite], class_damage[itemVal][pos_elite], class_resistance[itemVal][pos_elite], class_trim[itemVal][pos_elite], weapons, class_description[itemVal][pos_elite]);
		//}
		
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
	for (new i = 1; i <= class_numberOfClasses; i++) {
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
		/*
		new Function:classForward = GetFunctionByName(class_plugins[itemVal], "cod_classSkillUsed");
		if (classForward != INVALID_FUNCTION) {
			Format(desc, DESCLENEXTENDED, "Klasa: %s\nInteligencja: %i\nZdrowie: %i\nObrazenia: %i\nWytrzymalosc: %i\nKondycja: %i\nBronie: %s\nOpis: %s\nUzycie umiejetnosci: useclass", class_name[itemVal][pos_master], class_intelligence[itemVal][pos_master], class_health[itemVal][pos_master], class_damage[itemVal][pos_master], class_resistance[itemVal][pos_master], class_trim[itemVal][pos_master], weapons, class_description[itemVal][pos_master]);
		}
		else {*/
		Format(desc, DESCLENEXTENDED, "Klasa: %s\nInteligencja: %i\nZdrowie: %i\nObrazenia: %i\nWytrzymalosc: %i\nKondycja: %i\nBronie: %s\nOpis: %s", class_name[itemVal][pos_master], class_intelligence[itemVal][pos_master], class_health[itemVal][pos_master], class_damage[itemVal][pos_master], class_resistance[itemVal][pos_master], class_trim[itemVal][pos_master], weapons, class_description[itemVal][pos_master]);
		//}
		
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
	for (new i = 1; i <= class_numberOfClasses; i++) {
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
		/*
		new Function:classForward = GetFunctionByName(class_plugins[itemVal], "cod_classSkillUsed");
		if (classForward != INVALID_FUNCTION) {
			Format(desc, DESCLENEXTENDED, "Klasa: %s\nInteligencja: %i\nZdrowie: %i\nObrazenia: %i\nWytrzymalosc: %i\nKondycja: %i\nBronie: %s\nOpis: %s\nUzycie umiejetnosci: useclass", class_name[itemVal][pos_god], class_intelligence[itemVal][pos_god], class_health[itemVal][pos_god], class_damage[itemVal][pos_god], class_resistance[itemVal][pos_god], class_trim[itemVal][pos_god], weapons, class_description[itemVal][pos_god]);
		}
		else {*/
		Format(desc, DESCLENEXTENDED, "Klasa: %s\nInteligencja: %i\nZdrowie: %i\nObrazenia: %i\nWytrzymalosc: %i\nKondycja: %i\nBronie: %s\nOpis: %s", class_name[itemVal][pos_god], class_intelligence[itemVal][pos_god], class_health[itemVal][pos_god], class_damage[itemVal][pos_god], class_resistance[itemVal][pos_god], class_trim[itemVal][pos_god], weapons, class_description[itemVal][pos_god]);
		//}
		
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
	/*
	new Function:classForward = GetFunctionByName(class_plugins[itemVal], "cod_classSkillUsed");
	if (classForward != INVALID_FUNCTION) {
		Format(desc, DESCLENEXTENDED, "Klasa: %s\nInteligencja: %i\nZdrowie: %i\nObrazenia: %i\nWytrzymalosc: %i\nKondycja: %i\nBronie: %s\nOpis: %s\nUzycie umiejetnosci: useclass", class_name[itemVal][pos], class_intelligence[itemVal][pos], class_health[itemVal][pos], class_damage[itemVal][pos], class_resistance[itemVal][pos], class_trim[itemVal][pos], weapons, class_description[itemVal][pos]);
	}
	else {*/
	Format(desc, DESCLENEXTENDED, "Klasa: %s\nInteligencja: %i\nZdrowie: %i\nObrazenia: %i\nWytrzymalosc: %i\nKondycja: %i\nBronie: %s\nOpis: %s", class_name[itemVal][pos], class_intelligence[itemVal][pos], class_health[itemVal][pos], class_damage[itemVal][pos], class_resistance[itemVal][pos], class_trim[itemVal][pos], weapons, class_description[itemVal][pos]);
	//}
	
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
	return Plugin_Handled;
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

public Action:ItemsDescription_Menu(client, args) {
	new Handle:menu = CreateMenu(ItemsDescription_Handler);
	new String:buffer[8];
	for (new i = 1; i <= item_numberOfItems; i++) {
		Format(buffer, sizeof(buffer), "%d", i);
		AddMenuItem(menu, buffer, item_name[i]);
	}
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
	return Plugin_Handled;
}

public ItemsDescription_Handler(Handle:classhandle, MenuAction:action, client, position) {
	if (action == MenuAction_Select) {
		new String:item[32];
		GetMenuItem(classhandle, position, item, sizeof(item));
		new itemVal = StringToInt(item);
		
		new String:item_desc[128];
		new String:random[16];
		Format(random, sizeof(random), "%i-%i", item_minVal[itemVal], item_maxVal[itemVal]);
		Format(item_desc, sizeof(item_desc), item_description[itemVal]);
		ReplaceString(item_desc, sizeof(item_desc), "RNG", random);
		
		new String:desc[512];
		new Function:itemForward = GetFunctionByName(item_plugins[itemVal], "cod_itemUsed");
		if (itemForward != INVALID_FUNCTION) {
			Format(desc, sizeof(desc), "Item: %s\nZablokowany dla: %s\nOpis: %s\nUżycie umiejętności: Useitem", item_name[itemVal], item_blackList[itemVal], item_desc);
		}
		else {
			Format(desc, sizeof(desc), "Item: %s\nZablokowany dla: %s\nOpis: %s", item_name[itemVal], item_blackList[itemVal], item_desc);
		}
		
		new Handle:menu = CreateMenu(ItemsDescription_Handler2);
		SetMenuTitle(menu, desc);
		AddMenuItem(menu, "1", "Lista itemów");
		DisplayMenu(menu, client, MENU_TIME_FOREVER);
	}
	else if (action == MenuAction_End) {
		CloseHandle(classhandle);
	}
}

public ItemsDescription_Handler2(Handle:classhandle, MenuAction:action, client, position) {
	if (action == MenuAction_Select) {
		ItemsDescription_Menu(client, 0);
	}
	else if (action == MenuAction_End) {
		CloseHandle(classhandle);
	}
}

public Action:ItemDescription(client, args) {
	if(!player_hasItem[client]) {
		PrintToChat(client, "Nie posiadasz itemu. Zabij przeciwnika aby go zdobyc.");
		return Plugin_Handled;
	}
	
	new String:desc[128];
	new String:random[16];
	IntToString(player_itemRandomValue[client], random, sizeof(random));
	Format(desc, sizeof(desc), item_description[player_item[client]]);
	ReplaceString(desc, sizeof(desc), "RNG", random);
	
	PrintToChat(client, "Item: %s.", item_name[player_item[client]]);
	PrintToChat(client, "Opis: %s.", desc);
	
	new Function:itemForward = GetFunctionByName(item_plugins[player_item[client]], "cod_itemUsed");
	if (itemForward != INVALID_FUNCTION) {
		PrintToChat(client, "Uzycie umiejetnosci: Useitem.");
	}
	
	return Plugin_Handled;
}

public Native_RegisterClass(Handle:plugin, args) {
	if(args < 16) {
		return;
	}
	class_numberOfClasses++;
	class_plugins[class_numberOfClasses] = plugin;
	
	new String:tempName[NAMELEN];
	GetNativeString(1, tempName, NAMELEN);
	Format(class_name[class_numberOfClasses][pos_basic], NAMELEN, "%s", tempName);
	Format(class_name[class_numberOfClasses][pos_pro], NAMELEN, "[Pro] %s", tempName);
	Format(class_name[class_numberOfClasses][pos_elite], NAMELEN, "[Elite] %s", tempName);
	Format(class_name[class_numberOfClasses][pos_master], NAMELEN, "[Master] %s", tempName);
	Format(class_name[class_numberOfClasses][pos_god], NAMELEN, "[God] %s", tempName);
	
	new counter = 0;
	for (new i = 2; i < 7; i++) {
		GetNativeString(i, class_description[class_numberOfClasses][counter], DESCLEN);
		GetNativeString(i+5, class_weapons[class_numberOfClasses][counter], DESCLEN);
		counter++;
	}
	
	GetNativeArray(12, class_intelligence[class_numberOfClasses], PROMOTIONSVALUE);
	GetNativeArray(13, class_health[class_numberOfClasses], PROMOTIONSVALUE);
	GetNativeArray(14, class_damage[class_numberOfClasses], PROMOTIONSVALUE);
	GetNativeArray(15, class_resistance[class_numberOfClasses], PROMOTIONSVALUE);
	GetNativeArray(16, class_trim[class_numberOfClasses], PROMOTIONSVALUE);
}

public Native_GetPlayerClass(Handle:plugin, args) {
	new client = GetNativeCell(1);
	
	SetNativeString(2, class_name[player_class[client]][0], GetNativeCell(3));
	return 1;
}

public Native_GetPlayerPromotion(Handle:plugin, args) {
	new client = GetNativeCell(1);
	
	return player_promotion[client][player_class[client]];
}

public Native_GetPlayerMaxHealth(Handle:plugin, args) {
	new client = GetNativeCell(1);
	
	new result = HEALTH_BASE + (player_stats_health[client][player_class[client]] * HEALTH_MULTIPLIER) + class_health[player_class[client]][player_promotion[client][player_class[client]]] + item_health[player_item[client]];
	
	return result;
}

public Native_InflictDamageWithIntelligence(Handle:plugin, numParams) {
	new victim = GetNativeCell(1);
	new attacker = GetNativeCell(2);
	new Float:factor = GetNativeCell(3);
	
	/*
	new Handle:data = CreateDataPack();
	WritePackCell(data, victim);
	WritePackCell(data, attacker);
	WritePackCell(data, factor);
	*/
	//CreateTimer(0.1, InflictDamageWithIntelligence_Timer, data, TIMER_FLAG_NO_MAPCHANGE);
	
	new Float:attacker_intelligence = float(player_stats_intelligence[attacker][player_class[attacker]] + class_intelligence[player_class[attacker]][player_promotion[attacker][player_class[attacker]]] + item_intelligence[player_item[attacker]]);
	new Float:victim_resistance = float(player_stats_resistance[victim][player_class[victim]] + class_resistance[player_class[victim]][player_promotion[victim][player_class[victim]]] + item_resistance[player_item[victim]]);
	
	new Float:damage = (attacker_intelligence * factor) / (1.0 + victim_resistance / 50.0);
	
	if (IsValidClient(victim) && IsPlayerAlive(victim) && IsValidClient(attacker)) {
		SDKHooks_TakeDamage(victim, attacker, attacker, damage, DMG_BULLET);
	}
	
	return -1;
}

/*
public Action:InflictDamageWithIntelligence_Timer(Handle:timer, Handle:data) {
	ResetPack(data);
	new victim = ReadPackCell(data);
	new attacker = ReadPackCell(data);
	new Float:factor = ReadPackCell(data);
	CloseHandle(data);
	
	new Float:attacker_intelligence = float(player_stats_intelligence[attacker][player_class[attacker]] + class_intelligence[player_class[attacker]][player_promotion[attacker][player_class[attacker]]] + item_intelligence[player_item[attacker]]);
	new Float:victim_resistance = float(player_stats_resistance[victim][player_class[victim]] + class_resistance[player_class[victim]][player_promotion[victim][player_class[victim]]] + item_resistance[player_item[victim]]);
	
	new Float:damage = (attacker_intelligence * factor) / (1.0 + victim_resistance / 50.0);
	
	PrintToChatAll("to dziala, zadales: %f damage", damage);
	
	if (IsValidClient(victim) && IsPlayerAlive(victim) && IsValidClient(attacker)) {
		SDKHooks_TakeDamage(victim, attacker, attacker, damage, DMG_BULLET);
		PrintToChatAll("to tez dziala");
	}
	
	return Plugin_Continue;
}*/

public Native_RegisterItem(Handle:plugin, args) {
	if(args < 11) {
		return;
	}
	
	item_numberOfItems++;
	
	item_plugins[item_numberOfItems] = plugin;
	GetNativeString(1, item_name[item_numberOfItems], sizeof(item_name[]));
	GetNativeString(2, item_description[item_numberOfItems], sizeof(item_description[]));
	GetNativeString(3, item_weapons[item_numberOfItems], sizeof(item_weapons[]));
	GetNativeString(4, item_blackList[item_numberOfItems], sizeof(item_blackList[]));
	item_minVal[item_numberOfItems] = GetNativeCell(5);
	item_maxVal[item_numberOfItems] = GetNativeCell(6);
	item_intelligence[item_numberOfItems] = GetNativeCell(7);
	item_health[item_numberOfItems] = GetNativeCell(8);
	item_damage[item_numberOfItems] = GetNativeCell(9);
	item_resistance[item_numberOfItems] = GetNativeCell(10);
	item_trim[item_numberOfItems] = GetNativeCell(11);
}

public Native_GetPlayerItem(Handle:plugin, args) {
	new client = GetNativeCell(1);
	
	SetNativeString(2, item_name[player_item[client]], GetNativeCell(3));
	return 1;
}

bool:IsValidClient(client) {
	return (1 <= client <= MaxClients && IsClientInGame(client) && IsClientAuthorized(client) && !IsFakeClient(client));
}