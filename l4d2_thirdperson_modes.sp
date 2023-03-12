#include <sourcemod>
#include <sdktools>
#include <clientprefs>

Handle g_hCookie;
int	g_iClientModePref[MAXPLAYERS+1];

new bool:Third_Melee[MAXPLAYERS+1] = {false, ...};
new bool:Third_Melee_Always[MAXPLAYERS+1] = {false, ...};

public Plugin:myinfo =
{
	name = "[L4D2] Thirdperson with Melee-Only and Always on modes",
	author = "Yani & MasterMind420",
	description = "Enable third person on melee only, always or never. Preference is autosaved.",
	version = "1.2",
	url = ""
}

public OnPluginStart()
{
	RegConsoleCmd("sm_tp", sm_tp);
	RegConsoleCmd("sm_tps", sm_tp_select);
	g_hCookie = RegClientCookie("l4d_thirdperson_preference", "Third person - Mode", CookieAccess_Protected);

}

public Action:sm_tp_select(client,args)
{
	if (args < 1)
	{
	 	ReplyToCommand(client, "Usage: !tps (0: Disable third person, 1: Enable melee-only third person, 2: Enable third person");
	 	return Plugin_Handled;
	}

	decl String:arg[3];
	GetCmdArg(1, arg, sizeof(arg));

	if(StrEqual(arg, "0"))
	{
		disableTP(client);
 	}

	if(StrEqual(arg, "1"))
	{
		enableTPMeleeOnly(client);
 	}
 	if(StrEqual(arg,"2"))
	{
		enableTP(client);
 	}

	ReplyToCommand(client, "3rd person %s", Third_Melee[client] ? "enabled" : "disabled")
	return Plugin_Handled;
}

public Action:sm_tp(client,args)
{
	if(client > 0 && IsClientInGame(client))
	{
		ModeSelectMenu(client);
	}
	return Plugin_Handled;
}

void SetClientPrefs(int client)
{
	if( !IsFakeClient(client) )
	{	
		static char sCookie[2];
		Format(sCookie, sizeof(sCookie), "%i", g_iClientModePref[client]);
		SetClientCookie(client, g_hCookie, sCookie);
	}
}

public void OnClientCookiesCached(int client)
{
	if( client > 0 && IsClientInGame(client) && !IsFakeClient(client))
	{
		// Get client cookies, set type if available or default.
		static char sCookie[3];
		GetClientCookie(client, g_hCookie, sCookie, sizeof(sCookie));

		if(StringToInt(sCookie) == 1 || StringToInt(sCookie) == 2)
		{
			g_iClientModePref[client] = StringToInt(sCookie);

		} else {
			g_iClientModePref[client] = 0;
		}
	}
}

ModeSelectMenu(client)
{
	if(client<=0 || !IsClientInGame(client) || GetClientTeam(client) != 2)
	{
		return;
	}
	new Handle:menu = CreateMenu(MenuSelector1);
	SetMenuTitle(menu, "Please Select 3rd person Mode (!tp)"); 

	AddMenuItem(menu, "1", "3rd person disabled"); 
	AddMenuItem(menu, "2", "3rd person with melee weapon");
	AddMenuItem(menu, "3", "3rd person always enabled"); 

	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, 10); 
}

public MenuSelector1(Handle:menu, MenuAction:action, client, param2)
{
	if (action == MenuAction_Select)
	{ 
		decl String:item[256], String:display[256];		
		GetMenuItem(menu, param2, item, sizeof(item), _, display, sizeof(display));		
		if (StrEqual(item, "1")) {
			disableTP(client);
		}
		else if (StrEqual(item, "2"))
		{
			enableTPMeleeOnly(client);
		}
		else if(StrEqual(item, "3"))
		{
			enableTP(client);
		}
		SetClientPrefs(client);

	}
}

void disableTP(client)
{
	Third_Melee_Always[client]=false;
	Third_Melee[client] = false;
	g_iClientModePref[client] = 0;
	SetClientPrefs(client);
	SetEntPropFloat(client, Prop_Send, "m_TimeForceExternalView", 0.0);
}

void enableTPMeleeOnly(client)
{
	Third_Melee_Always[client]=false;
	Third_Melee[client] = true;
	g_iClientModePref[client] = 1;
	SetClientPrefs(client);
	SetEntPropFloat(client, Prop_Send, "m_TimeForceExternalView", 0.0);
}

void enableTP(client) {
	Third_Melee_Always[client]=true;	
	Third_Melee[client] = true;
	g_iClientModePref[client] = 2;
	SetClientPrefs(client);
	SetEntPropFloat(client, Prop_Send, "m_TimeForceExternalView", 99999.3);
}

public void OnMapStart() {

	for (int client = 1; client <= MaxClients; client++) {
		OnClientCookiesCached(client);
		if (GetClientTeam(client) == 2 && IsPlayerAlive(client)) {
			if (g_iClientModePref[client] == 1) enableTPMeleeOnly(client);
			if (g_iClientModePref[client] == 2) enableTP(client);
		}
	}
}

public OnGameFrame()
{
	for(new client=1; client<=MaxClients; client++)
	{

		if (IsClientInGame(client) && GetClientTeam(client) == 2 && IsPlayerAlive(client) && !IsFakeClient(client))
		{
			if(Third_Melee[client] == true)
			{
				new String:sClassName[64];
				new WeaponSlot = GetPlayerWeaponSlot(client, 1);
				if (WeaponSlot == -1) { return; }
				new ActiveWeapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
				GetEdictClassname(WeaponSlot, sClassName, sizeof(sClassName));
		
				if(Third_Melee_Always[client] == true || (StrEqual(sClassName, "weapon_melee") && WeaponSlot == ActiveWeapon))
				{
					SetEntPropFloat(client, Prop_Send, "m_TimeForceExternalView", 99999.3);
				}
				else
				{
					SetEntPropFloat(client, Prop_Send, "m_TimeForceExternalView", 0.0);
				}
			}
		}
	}
}