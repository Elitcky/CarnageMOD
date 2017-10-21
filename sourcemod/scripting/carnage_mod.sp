#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <multicolors>
#include <smlib>
#include <emitsoundany>
#include <cstrike>

#define Prefix "CARNAGE"
#pragma newdecls required

//Version 1.1 Agregado hud 
//Version 1.2 fix bug carnage aleatorio

int g_Carnage; //Varible que nos indicara si es carngae o no
int g_Round; //Varible q se encargara de contar las rondas para saber si es carnage

bool g_NoScope = false;
//enum PACK_CARNAGE
//{
//	WEAPON[18]
//};

//new const String:g_Packcarnage[][PACK_CARNAGE] =  { "weapon_deagle", "weapon_awp" };

public Plugin myinfo = 
{
	name = "Carnage Round HNS", 
	author = "Elitcky", 
	description = "Normal carnage mod for my HNS SERVER", 
	version = "1.00", 
	url = ""
};

public void OnPluginStart()
{
	HookEvent("round_start", OnRoundStart);
	HookEvent("round_end", OnRoundEnd);
	HookEvent("player_spawn", OnPlayerSpawn); //Registramos cuando un jugador spawnea
	HookEvent("weapon_zoom", Fun_EventWeaponZoom, EventHookMode_Post);
	
	RegConsoleCmd("sm_carnage", CMD_MENSAJECARNAGE); //Registramos el /carnagee para informar cuantas rondas faltan
	RegConsoleCmd("sm_awp", CMD_AWP); //Registramos el /carnagee para informar cuantas rondas faltan
	RegConsoleCmd("sm_forcecarnage", CMD_TEST); //Registramos el /carnagee para informar cuantas rondas faltan
	
	CreateConVar("carnage_round", "5");
	
}

public void OnMapStart()
{
	AddFilesFromFolder("sound/misc/hnschile/");
	
	// COUNT SOUND 1
	PrecacheSoundAny("*misc/hnschile/ronda_carnageR.mp3");
	PrecacheSoundAny("*misc/hnschile/ronda_carnage2R.mp3");
	
	g_Round = 0;
}

public void OnRoundStart(Event hEvent, const char[] sName, bool dontBroadcast)
{
	g_NoScope = false;
	g_Carnage = 0; //Desimos q no es carnage seteandola esta variable en 0
	g_Round++; //Incrementamos el contador de rondas
	
	//if(FindConVar(CvarModCarnage) &&  g_Round+1 == FindConVar(CvarRoundCarnage))
	
	if (g_Round == 5) //Si la ronda es carnage...
	{
		g_Carnage = 1; //Seteamos la variable indicadora de carnage en 1
		g_Round = 0; //Reseteamos el contador de rondas
		SetConVarInt(FindConVar("hns_decoy_chance"), 0); // this need to be changed for RM
		SetConVarInt(FindConVar("hns_flashbang_chance"), 0); // this need to be changed for RM
		SetConVarInt(FindConVar("hns_he_grenade_chance"), 0); // this need to be changed for RM
		//SetConVarInt(hns_decoy_chance, 0, true, false);
		//SetConVarInt(hns_flashbang_chance, 0, true, false);
		//SetConVarInt(hns_he_grenade_chance, 0, true, false); 
	}
	
	for (int client = 1; client < MaxClients; client++)
	if (g_Carnage) //Si es carnage le informamos q carnage es y si es only headshoot
	{
		CPrintToChat(client, "{green}[%s] {default}Es MODO CARNAGE", Prefix);
	}
	else
	{  //Si no le informamos cuantas rondas faltan
		int g_RestaRound = 5 - g_Round;
		CPrintToChat(client, "{green}[%s] {default}Faltan %d rondas para carnage", Prefix, g_RestaRound);
	}
}

public void OnRoundEnd(Event hEvent, const char[] name, bool dontBroadcast)
{
	if (g_Round + 1 == 5) //Si la proxima ronda es carnage
		SetConVarInt(FindConVar("hns_countdown_time"), 0); // this need to be changed for RM
	//NOTA:Lo hago aca para evitar bugs
	if (g_Carnage) //Si ya termino el carnage volvemos a los valores por default
	{
		SetConVarInt(FindConVar("hns_decoy_chance"), 1); // this need to be changed for RM
		SetConVarInt(FindConVar("hns_flashbang_chance"), 1); // this need to be changed for RM
		SetConVarInt(FindConVar("hns_he_grenade_chance"), 1); // this need to be changed for RM
		SetConVarInt(FindConVar("hns_countdown_time"), 11); // this need to be changed for RM
		
		//NO SCOPE
		g_NoScope = false;
	}
}

public void OnPlayerSpawn(Event hEvent, const char[] sName, bool bDontBroadcast)
{
	for (int client = 1; client <= MaxClients; client++)
	if (IsPlayerAlive(client))
	{
		CreateTimer(2.0, chequear_carnage, client + 100); // Timer Carnage
	}
}
/*Hacemos que chequee en 2 seg si es carnage, algunos se preguntaran por q aca y no en el round start, la respuesta es 
simple por q si alguien entra al sv cuando ya comenzo la ronda y aparece vivo no se le setearian las armas del carnage*/

//FUNKCIJA - NOSCOPE
public Action Fun_EventWeaponZoom(Handle hEvent, const char[] name, bool bDontBroadcast) {
	
	if (g_NoScope) {
		
		int client = GetClientOfUserId(GetEventInt(hEvent, "userid"));
		if (IsClientInGame(client) && IsPlayerAlive(client) && !IsFakeClient(client)) {
			int ent = GetPlayerWeaponSlot(client, 0);
			CS_DropWeapon(client, ent, true, true);
			PrintToChat(client, "Es modo NO-SCOPE! No intentes hacer Zoom :)");
		}
	}
	
}

public Action CMD_TEST(int client, int args)
{
	if (CheckCommandAccess(client, "", ADMFLAG_ROOT))  
	{
		g_Carnage = 1;
		
		if (IsPlayerAlive(client))
		{
			CreateTimer(2.0, chequear_carnage, client + 100); // Timer Carnage
		}
	}
	else
	{
		CPrintToChat(client, "{green}[%s] {default} No eres Admin para usar este comando", Prefix);
	}
}

public Action CMD_AWP(int client, int args)
{
	if (IsClientInGame(client) && IsPlayerAlive(client) && !IsFakeClient(client))
	{
		if (g_Carnage) //Si es carnage le informamos q carnage es y si es only headshoot
		{
			g_NoScope = true;
			
			CPrintToChat(client, "{green}[%s] {default} HAS RECIBIDO UNA {green}AWP", Prefix);
			Client_GiveWeaponAndAmmo(client, "weapon_awp", _, 50, _, 100);
		}
		else
		{
			CPrintToChat(client, "{green}[%s] {default} No es modo carnage.", Prefix);
		}
	}
}

public Action CMD_MENSAJECARNAGE(int client, int args)
{
	if (g_Carnage) //Si es carnage le informamos q carnage es y si es only headshoot
	{
		CPrintToChat(client, "{green}[%s] {default}Es MODO CARNAGE", Prefix);
	}
	else
	{  //Si no le informamos cuantas rondas faltan
		int g_RestaRound = 5 - g_Round;
		CPrintToChat(client, "{green}[%s] {default}Faltan %d rondas para carnage", Prefix, g_RestaRound);
	}
}

public Action chequear_carnage(Handle timer, int client)
{
	if (!g_Carnage) //Si no es carnage volvemos
		return 
	
	client -= 100;
	
	int weapon = -1;
	for (int i = 0; i <= 5; i++)
	{
		if ((weapon = GetPlayerWeaponSlot(client, i)) != -1)
		{
			RemovePlayerItem(client, weapon);
		}
	}
	
	CreateTimer(1.0, AVISO_1);
	CreateTimer(2.0, AVISO_2);
	CreateTimer(3.0, AVISO_3);
	CreateTimer(3.5, DAR_ARMAS);
}

public Action AVISO_1(Handle timer)
{
	CPrintToChatAll("{green}[%s] {default}MODO CARNAGE en {green}3", Prefix);
}

public Action AVISO_2(Handle timer)
{
	CPrintToChatAll("{green}[%s] {default}MODO CARNAGE en {green}2", Prefix);
}

public Action AVISO_3(Handle timer)
{
	CPrintToChatAll("{green}[%s] {default}MODO CARNAGE en {green}1", Prefix);
}

public Action DAR_ARMAS(Handle timer)
{
	for (int client = 1; client < MaxClients; client++)
	{
		if (IsClientInGame(client) && IsPlayerAlive(client) && !IsFakeClient(client))
		{
			g_NoScope = true;
			
			CPrintToChat(client, "{green}[%s] {default} HAS RECIBIDO UNA {green}AWP", Prefix);
			Client_GiveWeaponAndAmmo(client, "weapon_awp", _, 50, _, 100);
			
			//Mostramos un hud para informar que es carnage
			CPrintToChatAll("{green}[%s] {default}Es MODO CARNAGE", Prefix);
			CPrintToChatAll("{green}[%s] {default}Es MODO CARNAGE", Prefix);
			CPrintToChatAll("{green}[%s] {default}Es MODO CARNAGE", Prefix);
			
			switch (GetRandomInt(1, 2))
			{
				case 1:
				{
					ClientCommand(client, "play *misc/hnschile/ronda_carnageR.mp3");
				}
				case 2:
				{
					ClientCommand(client, "play *misc/hnschile/ronda_carnage2R.mp3");
				}
			}
		}
	}
}

void AddFilesFromFolder(char path[PLATFORM_MAX_PATH])
{
	DirectoryListing dir = OpenDirectory(path, true);
	if (dir != INVALID_HANDLE)
	{
		PrintToServer("Success directory!!!");
		char buffer[PLATFORM_MAX_PATH];
		FileType type;
		
		while (dir.GetNext(buffer, PLATFORM_MAX_PATH, type))
		{
			if (type == FileType_File && (StrContains(buffer, ".mp3", false) != -1 || (StrContains(buffer, ".wav", false) != -1)) && !(StrContains(buffer, ".ztmp", false) != -1))
			{
				//Here you can precache sounds for everyfile checked, buffer is the full name of the file checked, (example: music.mp3)
				AddFileToDownloadsTable("sound/misc/hnschile/ronda_carnageR.mp3");
				AddFileToDownloadsTable("sound/misc/hnschile/ronda_carnage2R.mp3");
			}
		}
	}
} 