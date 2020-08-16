#include <sourcemod>
#include <sdkhooks>
#include <cod>

new const String:PLUGIN_NAME[32] = "coditem_tajemnicaadmirala";
new const String:PLUGIN_AUTHOR[32] = "GieeF";
new const String:PLUGIN_VERSION[32] = "1.0";
new const String:PLUGIN_DESCRIPTION[64] = "Item COD - Tajemnica Admirała";
new const String:PLUGIN_URL[32] = "-";

new const String:item_name[] = "Tajemnica Admirała";
new const String:item_description[] = "Dostajesz 20HP oraz pełen magazynek za każde zabójstwo";
new const String:item_weapons[] = "";
new const String:item_blackList[] = "#Admirał";
new const item_intelligence = 0;
new const item_health = 0;
new const item_damage = 0;
new const item_resistance = 0;
new const item_trim = 0;
new const item_minVal = 0;
new const item_maxVal = 0;

new bool:player_hasItem[MAXPLAYERS];

new String:weaponsName[][] = {
	"weapon_glock", "weapon_usp_silencer", "weapon_hkp2000", "weapon_p250", "weapon_tec9", "weapon_fiveseven", "weapon_cz75a", "weapon_deagle",
	"weapon_revolver", "weapon_elite", "weapon_m4a1_silencer", "weapon_ak47", "weapon_awp", "weapon_m4a1", "weapon_negev", "weapon_famas",
	"weapon_aug", "weapon_p90", "weapon_nova", "weapon_xm1014", "weapon_mag7", "weapon_mac10", "weapon_mp7", "weapon_mp9", "weapon_bizon",
	"weapon_ump45", "weapon_galilar", "weapon_ssg08", "weapon_sg556", "weapon_m249", "weapon_scar20", "weapon_g3sg1", "weapon_sawedoff"
};

new weaponsAmmo[][2] = {
	{20, 120}, {12, 24}, {13, 52}, {13, 26}, {32, 120}, {20, 100}, {12, 12}, {7, 35}, {8, 8}, {30, 120}, {20, 40}, {30, 90}, {10, 30}, {30, 90}, {150, 200}, {25, 90}, {30, 90},
	{50, 100}, {8, 32}, {7, 32}, {5, 32}, {30, 100}, {30, 120}, {30, 120}, {64, 120}, {25, 100}, {35, 90}, {10, 90}, {30, 90}, {100, 200}, {20, 90}, {20, 90}, {7, 32}
};

public Plugin:myinfo = {
	name = PLUGIN_NAME,
	author = PLUGIN_AUTHOR,
	description = PLUGIN_DESCRIPTION,
	version = PLUGIN_VERSION,
	url = PLUGIN_URL
};

public OnPluginStart() {
	HookEvent("player_death", SmiercGracza);
}

public OnAllPluginsLoaded() {
	CreateTimer(3.1, RegisterStart, 0);
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

public Action:SmiercGracza(Handle:event, String:name[], bool:dontBroadcast) {
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new killer = GetClientOfUserId(GetEventInt(event, "attacker"));
	if(!IsValidClient(killer) || !player_hasItem[killer]) {
		return Plugin_Continue;
	}
	
	if(!IsValidClient(client) || !IsPlayerAlive(killer)) {
		return Plugin_Continue;
	}
	
	if(GetClientTeam(client) == GetClientTeam(killer)) {
		return Plugin_Continue;
	}
	
	new activeWeapon = GetEntPropEnt(killer, Prop_Send, "m_hActiveWeapon");
	if(activeWeapon != -1) {
		new String:weapon[32];
		GetClientWeapon(killer, weapon, sizeof(weapon));
		for(new i = 0; i < sizeof(weaponsName); i++) {
			if(StrEqual(weapon, weaponsName[i])) {
				SetEntData(activeWeapon, FindSendPropInfo("CWeaponCSBase", "m_iClip1"), weaponsAmmo[i][0]);
				break;
			}
		}
	}
	
	new playerHealth = GetClientHealth(killer);
	new playerMaxHealth = cod_getPlayerMaxHealth(killer);
	SetEntData(killer, FindDataMapInfo(killer, "m_iHealth"), (playerHealth+20 < playerMaxHealth)? playerHealth+20: playerMaxHealth);
	return Plugin_Continue;
}