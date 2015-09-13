public Action:CheckTeleport(Handle:timer, any:client)
{
	if (!IsValidClient(client) || !IsPlayerAlive(client))
		return;

	new Float:diff = GetEngineTime() - g_fLastTimeBhopBlock[client];
	new Float:diff2 = GetEngineTime() - g_fTeleportValidationTime[client];
	if (!g_bRestorePosition[client] && !g_bRespawnPosition[client] && diff > 1.0 && diff2 > 2.0)
	{
		ResetJump(client);
		/*if (g_bTimeractivated[client])
		{
			decl Float:org[3];
			GetClientAbsOrigin(client,org);
			PrintToChat(client,"[%cKZ%c] Unverified client teleport detected. Your position: %f, %f, %f on %s",MOSSGREEN,WHITE,org[0],org[1],org[2],g_szMapName);
			PrintToConsole(client,"[KZ] Unverified client teleport detected. Your position: %f, %f, %f on %s",org[0],org[1],org[2],g_szMapName);
			Client_Stop(client,0);
		}*/
	}
}	
	
public Action:SpecAdvertTimer(Handle:timer)
{
	new count;
	decl String:szNameList[1024];
	Format(szNameList,1024,"");
	for (new i = 1; i <= MaxClients; i++)
	{	
		if (!IsClientInGame(i) || IsFakeClient(i) || IsPlayerAlive(i))
			continue;		
		if (GetClientTeam(i) == 1)
		{
			decl String:clientname[16];
			GetClientName(i,clientname,16);
			if (StrEqual(szNameList,""))
				Format(szNameList,1024,"%s",clientname);
			else
				Format(szNameList,1024,"%s%c;%c %s",szNameList, MOSSGREEN,WHITE,clientname);
			count++;
		}
	}
	if (count>2)
		PrintToChatAll(" %c>>%c Spectators (%c%i%c):%c %s",YELLOW,GRAY,LIMEGREEN,count,GRAY,WHITE,szNameList);
	return Plugin_Continue;
}

public Action:OpenOptionsMenu(Handle:timer, any:client)
{
	if (IsValidClient(client) && !IsFakeClient(client))
	{
		OptionMenu(client);
	}
}

public Action:GiveUsp(Handle:timer, any:client)
{
	if (IsValidClient(client) && IsPlayerAlive(client))
	{
		new weapon = GetPlayerWeaponSlot(client, 2);
		GivePlayerItem(client, "weapon_usp_silencer");
		if (!g_bStartWithUsp[client] && !IsFakeClient(client))
		{
			if (weapon != -1)
				 SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", weapon);
		}
	}
}

public Action:OpenCheckpointMenu(Handle:timer, any:client)
{
	if (IsValidClient(client) && !IsFakeClient(client))
	{
		ClimbersMenu(client); 
	}
}

public Action:OpenMeasureMenu(Handle:timer, any:client)
{
	if (IsValidClient(client) && !IsFakeClient(client))
	{
		DisplayMenu(g_hMainMenu,client,MENU_TIME_FOREVER)
	}
}
public Action:OpenTopMenu(Handle:timer, any:client)
{
	if (IsValidClient(client) && !IsFakeClient(client))
	{
		KZTopMenu(client);
	}
}
public Action:OpenAdminMenu(Handle:timer, any:client)
{
	if (IsValidClient(client) && !IsFakeClient(client))
	{
		KzAdminMenu(client);
	}
}

public Action:RefreshAdminMenu(Handle:timer, any:client)
{
	if (IsValidEntity(client) && !IsFakeClient(client))
		KzAdminMenu(client);
}

public Action:SetPlayerWeapons(Handle:timer, any:client)
{
	if ((GetClientTeam(client) > 1) && IsValidClient(client))
	{			
		StripAllWeapons(client);
		if (!IsFakeClient(client))
			GivePlayerItem(client, "weapon_usp_silencer");
		if (!g_bStartWithUsp[client])
		{
			new weapon = GetPlayerWeaponSlot(client, 2);
			if (weapon != -1 && !IsFakeClient(client))
				 SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", weapon);
		}
	}	
}

public Action:UpdatePlayerProfile(Handle:timer, any:client)
{
	if (IsValidClient(client) && !IsFakeClient(client))	
		db_updateStat(client);	
}

public Action:StartTimer(Handle:timer, any:client)
{
	if (IsValidClient(client) && !IsFakeClient(client))	
		CL_OnStartTimerPress(client);
}

public Action:BhopCheck(Handle:timer, any:client)
{
	if (!g_js_bBhop[client])
		g_js_GODLIKE_Count[client] = 0;
}

public Action:AttackTimer(Handle:timer)
{
	for (new i = 1; i <= MaxClients; i++)
	{	
		if (!IsValidClient(i) || IsFakeClient(i))
			continue;	
		
		if (g_AttackCounter[i] > 0)
		{
			if (g_AttackCounter[i] < 5)
				g_AttackCounter[i] = 0;
			else
				g_AttackCounter[i] = g_AttackCounter[i]  - 5;
		}
	}
	return Plugin_Continue;
}

public Action:PlayerRanksTimer(Handle:timer)
{
	for (new i = 1; i <= MaxClients; i++)
	{	
		if (!IsValidClient(i) || IsFakeClient(i))
			continue;			
		db_GetPlayerRank(i);
	}
	return Plugin_Continue;
}

public Action:KZTimer1(Handle:timer)
{
	if (g_bRoundEnd)
		return Plugin_Continue;
		
	if (g_bAllowCheckpoints && (StrEqual("kzpro", g_szMapPrefix[0])))
		ServerCommand("kz_checkpoints 0");
		
	decl client;
	for (client = 1; client <= MaxClients; client++)
	{		
		if (IsValidClient(client))
		{			
			if(IsPlayerAlive(client))
			{			
				//1st team join + in-game
				if (g_bFirstTeamJoin[client])		
				{
					CreateTimer(0.0, StartMsgTimer, client,TIMER_FLAG_NO_MAPCHANGE);
					CreateTimer(10.0, WelcomeMsgTimer, client,TIMER_FLAG_NO_MAPCHANGE);
					CreateTimer(70.0, HelpMsgTimer, client,TIMER_FLAG_NO_MAPCHANGE);	
					g_bFirstTeamJoin[client] = false;
				}
				CenterHudAlive(client);			
				
				//bhop plattform & movement direction
				if (g_bOnGround[client])
					g_js_TotalGroundFrames[client]++;
				else
				{
					if(g_bLadderJump[client])
					{
						g_js_fLadderDirection[client]+= GetClientMovingDirection(client,true);
						g_js_LadderDirectionCounter[client]++;						
					}		
					g_fMovingDirection[client]+= GetClientMovingDirection(client,false);
					g_js_TotalGroundFrames[client] = 0;				
				}
				if (g_js_TotalGroundFrames[client] > 1 && g_bOnBhopPlattform[client])	
					g_bOnBhopPlattform[client] = false;	
				
				SurfCheck(client);
				MovementCheck(client);
			}
			else
				CenterHudDead(client);				
		}
	}	
	return Plugin_Continue;		
}

public Action:LoadPlayerSettings(Handle:timer)
{
	for(new c=1;c<=MaxClients;c++)
	{
		if(IsValidClient(c))
			OnClientPutInServer(c);
	}
}


public Action:KZTimer2(Handle:timer)
{
	if (g_bRoundEnd)
		return Plugin_Continue;
	
	if (g_bMapEnd)
	{
		new Handle:hTmp;	
		hTmp = FindConVar("mp_timelimit");
		decl iTimeLimit;
		iTimeLimit = GetConVarInt(hTmp);			
		if (hTmp != INVALID_HANDLE)
			CloseHandle(hTmp);	
		if (iTimeLimit > 0)
		{
			decl timeleft;
			GetMapTimeLeft(timeleft);			
			switch(timeleft)
			{
				case 1800: PrintToChatAll("%t", "TimeleftMinutes",LIGHTRED,WHITE,timeleft/60);
				case 1200: PrintToChatAll("%t", "TimeleftMinutes",LIGHTRED,WHITE,timeleft/60);
				case 600:  PrintToChatAll("%t", "TimeleftMinutes",LIGHTRED,WHITE,timeleft/60);
				case 300:  PrintToChatAll("%t", "TimeleftMinutes",LIGHTRED,WHITE,timeleft/60);
				case 120:  PrintToChatAll("%t", "TimeleftMinutes",LIGHTRED,WHITE,timeleft/60);
				case 60:   PrintToChatAll("%t", "TimeleftSeconds",LIGHTRED,WHITE,timeleft); 
				case 30:   PrintToChatAll("%t", "TimeleftSeconds",LIGHTRED,WHITE,timeleft); 
				case 15:   PrintToChatAll("%t", "TimeleftSeconds",LIGHTRED,WHITE,timeleft); 		
				case -1:   PrintToChatAll("%t", "TimeleftCounter",LIGHTRED,WHITE,3); 	
				case -2:   PrintToChatAll("%t", "TimeleftCounter",LIGHTRED,WHITE,2); 	
				case -3:
				{
					if (!g_bRoundEnd)
					{
						g_bRoundEnd=true;			
						ServerCommand("mp_ignore_round_win_conditions 0");
						PrintToChatAll("%t", "TimeleftCounter",LIGHTRED,WHITE,1); 	
						CreateTimer(1.0, TerminateRoundTimer, INVALID_HANDLE, TIMER_FLAG_NO_MAPCHANGE);
					}
				}
			}
		}
	}

	//replay route
	SetReplayRoute();
	
	//info bot name
	SetInfoBotName(g_InfoBot);	
	
	for (new i = 1; i <= MaxClients; i++)
	{	
		if (!IsValidClient(i) || i == g_InfoBot)
			continue;	

		//bot color
		if (i == g_ProBot)
			SetEntityRenderColor(i, g_ReplayBotProColor[0], g_ReplayBotProColor[1], g_ReplayBotProColor[2], g_TransPlayerModels);
		else
			if (i == g_TpBot)
			SetEntityRenderColor(i, g_ReplayBotTpColor[0], g_ReplayBotTpColor[1], g_ReplayBotTpColor[2], g_TransPlayerModels); 
		
		//set route
		if (g_hRouteArray[i] != INVALID_HANDLE && g_RouteTick[i] == 3 && g_fCurrentRunTime[i] <= 3600.0)
		{				
			//route
			decl Float:origin[3];
			decl Float:ground_origin[3];
			GetClientAbsOrigin(i, origin);
			if (g_bOnGround[i])
				origin[2]+=10;
			GetGroundOrigin(i,ground_origin);
			if (FloatAbs(origin[2]-ground_origin[2]) < 66.0)
			{
				origin = ground_origin;
				origin[2]+=15;
			}
			PushArrayArray(g_hRouteArray[i], origin,3);		
			g_RouteTick[i] = 0;
		}
		g_RouteTick[i]++;
		
		if (!IsFakeClient(i))
		{
			//anticheat
			BhopPatternCheck(i);	
			
			//check skill group
			if (g_Skillgroup[i] != 0 && g_Skillgroup[i] < g_MinSkillGroup && !(GetUserFlagBits(i) & ADMFLAG_RESERVATION) && !(StrEqual(g_pr_rankname[i],"ADMIN")))
			{
				CreateTimer(3.0, KickPlayerHighRankOnly, i, TIMER_FLAG_NO_MAPCHANGE);
				g_bKickStatus[i]=true;
			}
			
		}

		if(g_hRecording[i] != INVALID_HANDLE && g_fCurrentRunTime[i] > 3600.0)
		{
			StopRecording(i);
			g_hRecording[i] = INVALID_HANDLE;
		}	
		
		if (!IsFakeClient(i) && !g_bKickStatus[i])
			QueryClientConVar(i, "fps_max", ConVarQueryFinished:FPSCheck, i);

		//overlay check
		if (g_bOverlay[i] && GetEngineTime()-g_fLastOverlay[i] > 5.0)
			g_bOverlay[i] = false;

		//Scoreboard			
		if (!g_bPause[i]) 
		{
			decl Float:fltime;
			fltime = GetEngineTime() - g_fStartTime[i] - g_fPauseTime[i] + 1.0;
			if (IsPlayerAlive(i) && g_bTimeractivated[i])
			{
				decl time; 
				time = RoundToZero(fltime);
				Client_SetScore(i,time); 
				Client_SetAssists(i,g_OverallCp[i]);		
				Client_SetDeaths(i,g_OverallTp[i]);								
			}
			else
			{		
				Client_SetScore(i,0);
				Client_SetDeaths(i,0);
				Client_SetAssists(i,0);
			}
			if (!IsFakeClient(i) && !g_pr_Calculating[i])
				CreateTimer(0.0, SetClanTag, i,TIMER_FLAG_NO_MAPCHANGE);		
		}
		
		
		if (IsPlayerAlive(i)) 
		{	
			SetEntData(i, FindSendPropOffs("CBaseEntity", "m_CollisionGroup"), 2, 4, true);
				
			//spec hud
			SpecListMenuAlive(i);
			
				
			//challenge check
			if (g_bChallenge_Request[i])
			{
				decl Float:time;
				time= GetEngineTime() - g_fChallenge_RequestTime[i];
				if (time>20.0)
				{
					PrintToChat(i, "%t", "ChallengeRequestExpired", RED,WHITE,YELLOW);
					g_bChallenge_Request[i] = false;
				}
			}
	
			//Last Time, Cords & Angles		
			if (GetEntityFlags(i)&FL_ONGROUND)
			{
				if (g_bTimeractivated[i])
				{
					if (g_bPause[i])
					{
						new Float: flPt = GetEngineTime() - g_fStartPauseTime[i];
						g_fPlayerLastTime[i] = GetEngineTime() - g_fStartTime[i] - flPt;	
					}
					else
						g_fPlayerLastTime[i] = GetEngineTime() - g_fStartTime[i] - g_fPauseTime[i];
				}
				GetClientAbsOrigin(i,g_fPlayerCordsLastPosition[i]);
				GetClientEyeAngles(i,g_fPlayerAnglesLastPosition[i]);
			}
		}
		else
			SpecListMenuDead(i);
	}
	
	//clean weapons on ground
	decl maxEntities;
	maxEntities = GetMaxEntities();
	decl String:classx[20];
	if (g_bCleanWeapons)
	{
		decl j;
		for (j = MaxClients + 1; j < maxEntities; j++)
		{
			if (IsValidEdict(j) && (GetEntDataEnt2(j, g_ownerOffset) == -1))
			{
				GetEdictClassname(j, classx, sizeof(classx));
				if ((StrContains(classx, "weapon_") != -1) || (StrContains(classx, "item_") != -1))
				{
					AcceptEntityInput(j, "Kill");
				}
			}
		}
	}
	return Plugin_Continue;
}

		
public Action:OnMapStartTimer(Handle:timer)
{
	if (FileExists("cfg/sourcemod/kztimer/main.cfg"))
		ServerCommand("exec sourcemod/kztimer/main.cfg");
	else
		SetFailState("<KZTIMER> cfg/sourcemod/kztimer/main.cfg not found.");
	db_selectMapButtons();
	LoadReplays();
	LoadInfoBot();
	
}

public Action:KickPlayer(Handle:Timer, any:client)
{
	if (IsValidClient(client) && !IsFakeClient(client))
	{
		decl String:szReason[128];
		Format(szReason, 128, "%T", "kick_msg_low_fps", client);
		KickClient(client, "%s", szReason);
	}
}

public Action:KickPlayerHighRankOnly(Handle:Timer, any:client)
{
	if (IsValidClient(client) && !IsFakeClient(client))
	{
		decl String:szReason[128];
		Format(szReason, 128, "%T", "kick_msg_skill_group", client, g_szSkillGroups[g_MinSkillGroup-1]);	
		KickClient(client, "%s", szReason);
	}
}

//challenge start countdown
public Action:Timer_Countdown(Handle:timer, any:client)
{
	if (IsValidClient(client) && g_bChallenge[client] && !IsFakeClient(client))
	{
		PrintToChat(client,"[%cKZ%c] %c%i",RED,WHITE,YELLOW,g_CountdownTime[client]);
		g_CountdownTime[client]--;
		if(g_CountdownTime[client] <= 0) 
		{
			SetEntityMoveType(client, MOVETYPE_WALK);
			PrintToChat(client, "%t", "ChallengeStarted1",RED,WHITE,YELLOW);
			PrintToChat(client, "%t", "ChallengeStarted2",RED,WHITE,YELLOW);
			PrintToChat(client, "%t", "ChallengeStarted3",RED,WHITE,YELLOW);
			PrintToChat(client, "%t", "ChallengeStarted4",RED,WHITE,YELLOW);
			return Plugin_Stop;
		}
	}
	return Plugin_Continue;
}

public Action:TpReplayTimer(Handle:timer, any:client)
{
	if (IsValidClient(client) && !IsFakeClient(client))
		SaveRecording(client,1);
}

public Action:ProReplayTimer(Handle:timer, any:client)
{
	if (IsValidClient(client) && !IsFakeClient(client))
		SaveRecording(client,0);
}

public Action:CheckChallenge(Handle:timer, any:client)
{
	decl bool:oppenent;
	oppenent=false;
	decl String:szSteamId[128];
	decl String:szName[32];
	decl String:szNameTarget[32];
	if (g_bChallenge[client] && IsValidClient(client) && !IsFakeClient(client))
	{
		for (new i = 1; i <= MaxClients; i++)
		{
			if (IsValidClient(i) && i != client)
			{			
				if (StrEqual(g_szSteamID[i],g_szChallenge_OpponentID[client]))
				{
					oppenent=true;		
					if (g_bChallenge_Abort[i] && g_bChallenge_Abort[client])
					{
						GetClientName(i,szNameTarget,32);
						GetClientName(client,szName,32);
						g_bChallenge[client]=false;
						g_bChallenge[i]=false;
						SetEntityRenderColor(client, 255,255,255,g_TransPlayerModels);
						SetEntityRenderColor(i, 255,255,255,g_TransPlayerModels);
						PrintToChat(client, "%t", "ChallengeAborted",RED,WHITE,GREEN,szNameTarget,WHITE);
						PrintToChat(i, "%t", "ChallengeAborted",RED,WHITE,GREEN,szName,WHITE);
						SetEntityMoveType(client, MOVETYPE_WALK);
						SetEntityMoveType(i, MOVETYPE_WALK);
					}				
				}
			}
		}
		if (!oppenent)
		{				
			SetEntityRenderColor(client, 255,255,255,g_TransPlayerModels);
			g_bChallenge[client]=false;
			
			//db challenge entry
			db_insertPlayerChallenge(client);
			
			//new points
			g_pr_showmsg[client]=true;
			CreateTimer(0.5, UpdatePlayerProfile, client,TIMER_FLAG_NO_MAPCHANGE);
			
			//db opponent
			Format(szSteamId,128,"%s",g_szChallenge_OpponentID[client]);
			RecalcPlayerRank(64,szSteamId);
			
			//chat msgs
			if (IsValidClient(client))
				PrintToChat(client, "%t", "ChallengeWon",RED,WHITE,YELLOW,WHITE);
					
			return Plugin_Stop;
		}
	}
	return Plugin_Continue;
}

public Action:LoadReplaysTimer(Handle:timer)
{
	if (g_bReplayBot)
		LoadReplays();
}

public Action:SetClanTag(Handle:timer, any:client)
{
	if (!IsValidClient(client) || IsFakeClient(client) || g_pr_Calculating[client])
		return;

	if (!g_bCountry && !g_bPointSystem && !g_bAdminClantag && !g_bVipClantag)
	{
		CS_SetClientClanTag(client, ""); 	
		return;
	}
	
	decl String:old_pr_rankname[32];  
	decl String:tag[32];  
	decl bool:oldrank;
	oldrank=false;
	
	if (!StrEqual(g_pr_rankname[client], "", false))
	{
		oldrank=true;
		Format(old_pr_rankname, 32, "%s", g_pr_rankname[client]); 
	}		
	SetPlayerRank(client);
		
	if (g_bCountry)
	{
		Format(tag, 32, "%s | %s",g_szCountryCode[client],g_pr_rankname[client]);	
		CS_SetClientClanTag(client, tag); 	
	}
	else
	{
		if (g_bPointSystem || ((StrEqual(g_pr_rankname[client], "ADMIN", false)) && g_bAdminClantag) || ((StrEqual(g_pr_rankname[client], "VIP", false)) && g_bVipClantag))
			CS_SetClientClanTag(client, g_pr_rankname[client]); 	
	}
	
	//new rank
	if (oldrank && g_bPointSystem)
		if (!StrEqual(g_pr_rankname[client], old_pr_rankname, false) && IsValidClient(client))
			CPrintToChat(client,"%t","SkillGroup", MOSSGREEN, WHITE, GRAY,GRAY, g_pr_chat_coloredrank[client]);
}

public Action:TerminateRoundTimer(Handle:timer)
{
	CS_TerminateRound(1.0, CSRoundEnd_CTWin, true);
}

public Action:WelcomeMsgTimer(Handle:timer, any:client)
{
	if (IsValidClient(client) && !IsFakeClient(client) && !StrEqual(g_sWelcomeMsg,""))
		CPrintToChat(client, "%s", g_sWelcomeMsg);
}

public Action:HelpMsgTimer(Handle:timer, any:client)
{
	if (IsValidClient(client) && !IsFakeClient(client))
		PrintToChat(client, "%t", "HelpMsg", MOSSGREEN,WHITE,GREEN,WHITE);
}

public Action:SelectSpecTarget(Handle:timer, any:client)
{
	if (IsValidClient(client) && IsValidClient(g_SpecTarget2[client]))
	{
		SetEntProp(client, Prop_Send, "m_iObserverMode", 4);	
		SetEntPropEnt(client, Prop_Send, "m_hObserverTarget", g_SpecTarget2[client]);  				
	}
}

public Action:StartMsgTimer(Handle:timer, any:client)
{
	if (IsValidClient(client) && !IsFakeClient(client))
	{
		if (!g_bEnforcer)
			PrintToChat(client, "%t", "SettingsEnforcerDisabled", MOSSGREEN,WHITE,GRAY);	
			
		PrintMapRecords(client);	
	}
}

public Action:CenterMsgTimer(Handle:timer, any:client)
{
	if (IsValidClient(client) && !IsFakeClient(client))
	{
		if (g_bRestorePositionMsg[client])
		{
			g_bOverlay[client]=true;
			g_fLastOverlay[client] = GetEngineTime();
			PrintHintText(client,"%t", "PositionRestored");
		}
		
		if (!g_bAutoTimer && IsPlayerAlive(client) && !g_bRestorePositionMsg[client])
		{
			g_fLastOverlay[client] = GetEngineTime();
			g_bOverlay[client]=true;
			PrintHintText(client,"%t", "TimerStartReminder");
		}
		g_bRestorePositionMsg[client]=false;
	}
}

public Action:ClimbersMenuTimer(Handle:timer, any:client)
{
	if (IsValidClient(client) && !IsFakeClient(client))
	{
		if (g_bAllowCheckpoints)
			if(StrEqual(g_szMapPrefix[0],"kz") || StrEqual(g_szMapPrefix[0],"xc") || StrEqual(g_szMapPrefix[0],"bhop") || StrEqual(g_szMapPrefix[0],"bkz"))
				Client_Kzmenu(client,0);
	}
}

public Action:RemoveRagdoll(Handle:timer, any:victim)
{
    if (IsValidEntity(victim) && !IsPlayerAlive(victim))
    {
        new player_ragdoll = GetEntDataEnt2(victim, g_ragdolls);
        if (player_ragdoll != -1)
            RemoveEdict(player_ragdoll);
    }
}

public Action:HideRadar(Handle:timer, any:client)
{
	if (IsValidClient(client) && !IsFakeClient(client))
	{
		SetEntPropEnt(client, Prop_Send, "m_bSpotted", 0);
		if (g_bHideChat[client])
			SetEntProp(client, Prop_Send, "m_iHideHUD", GetEntProp(client, Prop_Send, "m_iHideHUD")|HIDE_RADAR|HIDE_CHAT);
		else
			SetEntProp(client, Prop_Send, "m_iHideHUD", HIDE_RADAR);
	}
}