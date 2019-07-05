/*

   Oblivion Gang System
	 Version : Beta
   Mysql version R41+

*/

#include <a_samp>
#include <a_mysql41>
#include <sscanf2>
#include <zcmd>
#include <YSI\y_iterate> // Y-Less

#define MAX_GANGS 100
#define GANG_RANK_FOUNDER 4
#define GANG_RANK_LEADER 3
#define GANG_RANK_MEMBER 2
#define GANG_RANK_NEWBIE 1
#define GANG_RANK_NONE 0
#define DIALOG_NONE 0
#define DIALOG_MENU 1

#define MAX_GANG_MEMBERS 20


#define SendError(%1,%2) SendClientMessage(%1, 0xFF0000FF, "[INFO] "%2)
#define strcpy(%0,%1,%2) strcat((%0[0] = '\0', %0), %1, %2)
#define OGANG "{FFFF00}Oblivion Gang{FFFFFF}"
#define RGBA(%1,%2,%3,%4) (((((%1) & 0xff) << 24) | (((%2) & 0xff) << 16) | (((%3) & 0xff) << 8) | ((%4) & 0xff)))

#define DebugOn  (true) // make it false if you want to debug!
#define RED 	"{FF0000}"
#define SBLUE 	"{56A4E4}"
#define YELLOW 	"{FFFF00}"
#define WHITE 	"{FFFFFF}"
#define GREEN 	"{3BBD44}"

new MySQL:ObliGangcon;
new Iterator:Obligang<MAX_GANGS>, String[700], CreateGangName[MAX_PLAYERS][40], CreateGangTag[MAX_PLAYERS][5];

enum pdata
{
   pGangID,
   pGangRank
};

new pInfo[MAX_PLAYERS][pdata];

enum gdata
{
   GangName[40],
   GangColor,
   GangTag[5],
   GangScore
};

new GangInfo[MAX_GANGS][gdata];


public OnFilterScriptInit()
{
	print("\n--------------------------------------");
	print(" Gang System by Oblivion || Version : Beta ");
	print("--------------------------------------\n");
	
	ObliGangcon = mysql_connect("127.0.0.1", "root", "server", "obligang");
    new Cache:LoadGang = mysql_query(ObliGangcon, "SELECT * FROM `gang`;");
    new rows = cache_num_rows(), gangid;
    if(rows)
    {
	   for(new i = 0; i < rows; i++)
	   {
	        cache_get_value_name_int(i, "id", gangid);
	        cache_get_value_name(i, "name", GangInfo[gangid][GangName]);
	        cache_get_value_name_int(i, "color", GangInfo[gangid][GangColor]);
	        cache_get_value_name(i, "tag", GangInfo[gangid][GangTag]);
	        cache_get_value_name_int(i, "score", GangInfo[gangid][GangScore]);
	        Iter_Add(Obligang, gangid);
			gangid++;
	   }
    }
    #if DebugOn == true
	printf("\n\n\n ------------ Oblivion Gang System ------------ \n\n \t\tLoaded Gangs: %d \n\n ----------------------------------------------", rows);
	#endif
    cache_delete(LoadGang);
    
	/*
	CREATE TABLE IF NOT EXISTS `gang` (
		`id` int(10) NOT NULL AUTO_INCREMENT,
		`name` varchar(30) NOT NULL DEFAULT '-',
		`tag` varchar(5) NOT NULL DEFAULT '-',
		`color` int(11) NOT NULL DEFAULT '-1',
		`founder` varchar(30) NOT NULL DEFAULT '-',
	    `score` int(10) NOT NULL DEFAULT '0',
	    PRIMARY KEY (`id`)
	    ) ENGINE=MyISAM AUTO_INCREMENT=0 DEFAULT CHARSET=latin1;*/

	/*
	CREATE TABLE IF NOT EXISTS `users` (
		`id` int(10) NOT NULL AUTO_INCREMENT,
		`name` varchar(30) NOT NULL DEFAULT '-',
		`gangid` int(10) NOT NULL DEFAULT '-1',
		`gangrank` int(11) NOT NULL DEFAULT '0',
	    PRIMARY KEY (`id`)
	    ) ENGINE=MyISAM AUTO_INCREMENT=0 DEFAULT CHARSET=latin1;*/

	return 1;
}
public OnFilterScriptExit()
{
    
	return 1;
}

public OnPlayerConnect(playerid)
{
	pInfo[playerid][pGangID] = -1;
	pInfo[playerid][pGangRank] = GANG_RANK_NONE;
	format(String, sizeof(String), "SELECT gangid, gangrank FROM users WHERE name = '%s'", _GetName(playerid));
    mysql_tquery(ObliGangcon, String, "LoadPlayerGangData", "i", playerid);
	return 1;
}

forward LoadPlayerGangData(playerid);
public LoadPlayerGangData(playerid)
{
   if(!cache_num_rows()) return true;
   
   cache_get_value_index_int(0, 0, pInfo[playerid][pGangID]);
   cache_get_value_index_int(0, 1, pInfo[playerid][pGangRank]);
   format(String, sizeof(String), ""OGANG" %s has logged on!", _GetName(playerid));
   gang_announce(pInfo[playerid][pGangID], String);
   // DEBUG
   #if DebugOn == true
   printf("%s Gang ID: %d, GangRank: %i Loaded",_GetName(playerid), pInfo[playerid][pGangID],pInfo[playerid][pGangRank]);
   #endif
   return 1;
}
public OnPlayerDisconnect(playerid, reason)
{

    if(pInfo[playerid][pGangID] != -1)
    {
	  format(String, sizeof(String), ""OGANG" %s has logged out!", _GetName(playerid));
	  gang_announce(pInfo[playerid][pGangID], String);
	}
	return 1;
}

CMD:gcreate(playerid, params[])
{
    if(pInfo[playerid][pGangID] != -1) return SendError(playerid,"You are already a gang member!");
   
 	new gtag[5], gname[40], query[500];
 	
	if(sscanf(params, "s[40]s[5]", gname, gtag)) return SendError(playerid, "/gcreate <Gang name> <Gang tag>");
	if(strlen(gname) < 1 || strlen(gname) > 40) return SendError(playerid, "Gang name min - 1 and max -40");
	if(strlen(gtag) < 1 || strlen(gtag) > 5) return SendError(playerid, "Gang name min - 1 and max - 5");
	if(!strcmp(_GetName(playerid), gname, true)) return SendError(playerid, "You can't set your name as your gang name.");
	//
	format(query, sizeof(query), "SELECT * FROM gang WHERE name = '%s'", gname); //First search (Gang Name)
	new Cache:grn_result = mysql_query(ObliGangcon, query);
	if(cache_num_rows())
	{
	    SendError(playerid, "This gang name already exists in our database, search another one.");
	    cache_delete(grn_result);
	    return 1;
	}
	cache_delete(grn_result);
	//
	format(query, sizeof(query), "SELECT * FROM gang WHERE tag = '%s'", gtag); //Second search (Gang Tag)
	new Cache:grt_result = mysql_query(ObliGangcon,query);
	if(cache_num_rows())
	{
	    SendError(playerid, "This gang tag already exists in our database, search another one.");
        cache_delete(grt_result);
	    return 1;
	}
	cache_delete(grt_result);
	//If name/tag is unique
	strcpy(CreateGangName[playerid], gname, 40);
	strcpy(CreateGangTag[playerid], gtag,  5);
	
	new escapestrh[40], escapestrg[5];
	mysql_escape_string(gname, escapestrh);
	mysql_escape_string(gtag, escapestrg);

	format(query, sizeof(query), "INSERT INTO `gang` (`name`, `color`, `tag`, `founder`) VALUES ('%s', '-1', '%s', '%s')", escapestrh,  escapestrg, _GetName(playerid));
	mysql_tquery(ObliGangcon, query, "OnGangCreate", "i", playerid);
	//
    return 1;
}

forward OnGangCreate(playerid);
public OnGangCreate(playerid)
{
	new i = cache_insert_id(), query[400];
	//
	strcpy(GangInfo[i][GangName], CreateGangName[playerid], 40);
	strcpy(GangInfo[i][GangTag], CreateGangTag[playerid],  5);
	GangInfo[i][GangScore] += 5;
	//
	pInfo[playerid][pGangID] = i;
	pInfo[playerid][pGangRank] = GANG_RANK_FOUNDER;
	//

	Iter_Add(Obligang, i);
	format(String, sizeof(String), ""OGANG" %s(%d) has registered his gang [%s]%s", _GetName(playerid), playerid , CreateGangTag[playerid],CreateGangName[playerid]);
	SendClientMessageToAll(-1, String);
	GameTextForPlayer(playerid, "~g~~h~Gang Created!", 4000, 3);
	
	format(query, sizeof(query), "INSERT INTO `users` (`name`, `gangid`, `gangrank`)  VALUES ('%s','%d','%d')",
	_GetName(playerid), pInfo[playerid][pGangID], pInfo[playerid][pGangRank]);
    mysql_query(ObliGangcon,query);
    
    UpdateGangScore( pInfo[playerid][pGangID], 5);

    // DEBUG
    #if DebugOn == true
	printf("%s created Gang ID: %d, GangName: %s, (Table ID: %d)",_GetName(playerid), i,GangInfo[i][GangName]);
	#endif
	return 1;
}

CMD:grename(playerid, params[])
{
  	if(pInfo[playerid][pGangID] == -1) return SendError(playerid, "You are not in a gang!");
  	if(pInfo[playerid][pGangRank] != GANG_RANK_FOUNDER) return SendError(playerid, "You must be the gang founder to change the gang name!");
	if(GetPlayerMoney(playerid) < 1000) return SendError(playerid, "You must have 1000 to create a gang!");
	new gtag[5], gname[40], query[300];
	if(sscanf(params, "s[40]s[5]", gname, gtag)) return SendError(playerid, "/grename <Gang name> <Gang tag>");
	if(strlen(gname) < 1 || strlen(gname) > 40) return SendError(playerid, "Gang name min - 1 and max -40");
	if(strlen(gtag) < 1 || strlen(gtag) > 5) return SendError(playerid, "Gang name min - 1 and max - 5");
	if(!strcmp(_GetName(playerid), gname, true)) return SendError(playerid, "You can't set your name as your gang name.");

	//
	format(query, sizeof(query), "SELECT id FROM gang WHERE name = '%s'", gname); //First search (Gang Name)
	new Cache:grn_result = mysql_query(ObliGangcon,query);
	if(cache_num_rows())
	{
	    SendError(playerid, "This gang name already exists in our database, search another one.");
	    cache_delete(grn_result);
	    return 1;
	}
	cache_delete(grn_result);
	//
	format(query, sizeof(query), "SELECT id FROM gang WHERE tag = '%s'", gtag); //Second search (Gang Tag)
	new Cache:grt_result = mysql_query(ObliGangcon, query);
	if(cache_num_rows())
	{
	    SendError(playerid, "This gang tag already exists in our database, search another one.");
	    cache_delete(grt_result);
	    return 1;
	}
    cache_delete(grt_result);
	//If name/tag is unique
	new escapestrh[40], escapestrg[5];
	mysql_escape_string(gname, escapestrh);
	mysql_escape_string(gtag, escapestrg);
	format(query, sizeof(query), "UPDATE gang SET name = '%s', tag = '%s' WHERE id = %d", escapestrh, escapestrg, pInfo[playerid][pGangID]);
	mysql_query(ObliGangcon, query);
	//
	strcpy(GangInfo[pInfo[playerid][pGangID]][GangName], gname, 40);
	strcpy(GangInfo[pInfo[playerid][pGangID]][GangTag], gtag,  5);
	//

	format(String, sizeof(String), ""OGANG" Gang Founder %s(%i) has changed the gang name to '[%s] %s'!", _GetName(playerid), playerid, gtag,gname);
	gang_announce(pInfo[playerid][pGangID], String);
	GivePlayerMoney(playerid, GetPlayerMoney(playerid)-1000);
	
	return 1;
}
CMD:gmenu(playerid)
{
  	if(pInfo[playerid][pGangID] == -1) return SendError(playerid, "You are not in a gang!");

    ShowPlayerDialog(playerid, DIALOG_MENU, DIALOG_STYLE_LIST, ""YELLOW"Obli Gang System "WHITE"- Gang Menu","Gang Info\nGang Members\nKick Player\nSet Rank\nTop Gangs List", "Select", "Cancel");
	return 1;
}

CMD:gtop(playerid)
{
	mysql_tquery(ObliGangcon, "SELECT name,color,score FROM gang WHERE id ORDER BY score DESC LIMIT 10;", "ShowTop10", "i", playerid);
	return true;
}
forward ShowTop10(playerid);
public ShowTop10(playerid)
{
	new rows = cache_num_rows();
	if(!rows) return SendError(playerid, "No gangs found");
	if(rows)
	{
		new count = 0;
        new  memberstring[2400], cmString[2400];
        new ggname[MAX_PLAYER_NAME], color,  gscore;
		for(new i = 0; i < rows; i++)
		{
	        cache_get_value_name(i, "name",ggname);
	        cache_get_value_name_int(i, "color", color);
	        cache_get_value_name_int(i, "score", gscore);
	        
	        
			format(memberstring, sizeof(memberstring), "\n{%06x}%i - %s [%d]", color >>> 8, count + 1, ggname, gscore);
			strcat(cmString, memberstring);
			count++;
		}
		ShowPlayerDialog(playerid, DIALOG_NONE, DIALOG_STYLE_MSGBOX, ""YELLOW"Obli Gang System "WHITE"- Top 10 Gangs", cmString, "OK", "Cancel");

	}
    return 1;
}
CMD:gmembers(playerid)
{
  	if(pInfo[playerid][pGangID] == -1) return SendError(playerid, "You are not in a gang!");
	new query[500], mStrng[400];
	format(query, sizeof(query),"SELECT name, gangrank FROM `users` WHERE gangid = %i",pInfo[playerid][pGangID]);
    new Cache:GetMembers = mysql_query(ObliGangcon,query);
    if(cache_num_rows())
    {
		new mname[MAX_PLAYER_NAME], mrank;
		for(new i =0; i < cache_num_rows(); i++)
		{
	        cache_get_value_name(i, "name", mname);
	        cache_get_value_name_int(i, "gangrank",mrank);
	        format(mStrng, sizeof(mStrng),"%s - %s\n",  mname, GetGangRank(mrank) );
	        strcat(String, mStrng);

		}
		ShowPlayerDialog(playerid, DIALOG_NONE, DIALOG_STYLE_LIST, ""YELLOW"Obli Gang System "WHITE"- GANG MEMBERS", String, "OK", "Cancel");
    }
    cache_delete(GetMembers);
    return 1;
}
CMD:ginfo(playerid)
{
  	if(pInfo[playerid][pGangID] == -1) return SendError(playerid, "You are not in a gang!");

	new query[500], memberstring[800];
	format(query, sizeof(query), "SELECT name, color, tag, score, founder FROM gang WHERE id = %i", pInfo[playerid][pGangID]);
	new Cache:GangInfoCMD = mysql_query(ObliGangcon, query);
    if(cache_num_rows())
    {
    	new ggname[MAX_PLAYER_NAME], color, ggtag[5], gscore, ggfound[MAX_PLAYER_NAME];
        cache_get_value_index(0, 0,ggname);
        cache_get_value_index_int(0, 1, color);
        cache_get_value_index(0,2,ggtag);
        cache_get_value_index_int(0, 3, gscore);
        cache_get_value_index(0, 4,ggfound);

        format(memberstring, sizeof(memberstring), ""WHITE"Gang Founder: %s\nGang Name: %s\nGang Tag: %s\nGang Score: %i\nGang Color: {%06x}COLOR",
        ggfound, ggname, ggtag, gscore, color >>> 8);
        ShowPlayerDialog(playerid,DIALOG_NONE, DIALOG_STYLE_MSGBOX, ""YELLOW"Obli Gang System "WHITE"- GANG Information", memberstring, "OK", "Cancel");
    }
	cache_delete(GangInfoCMD);
	return true;
}

CMD:ginvite(playerid, params[]) return cmd_ganginvite(playerid, params);
CMD:ganginvite(playerid, params[])
{
	if(pInfo[playerid][pGangID] == -1) return SendError(playerid,"You are not in a gang!");
	if(pInfo[playerid][pGangRank] < GANG_RANK_LEADER) return SendError(playerid, "You must be at least the leader to invite players to the gang!");

	new otherid, Float:POS[3], query[257];
	if(sscanf(params, "u", otherid))
	{
	    SendError(playerid, "/ginvite <ID>");
 		return true;
	}
	if(otherid == INVALID_PLAYER_ID)
        return SendError(playerid, "Player not connected!");
        
	if(otherid == playerid) return SendError(playerid, "You can't invite yourself to your own gang!");

	if(pInfo[otherid][pGangID] != -1) return SendError(playerid, "This player is already in a gang!");
	
	if(GetPVarInt(otherid, "ganginvplayer") == playerid) return SendError(playerid, "You have already sent a gang invite to this player!");

	GetPlayerPos(otherid, POS[0], POS[1], POS[2]);
	if(!IsPlayerInRangeOfPoint(playerid, 10.0, POS[0], POS[1], POS[2]))
	{
	    return SendError(playerid, "You must be near the player to whom you are inviting!");
	}
    //
	format(query, sizeof(query), "SELECT COUNT(*) FROM users WHERE gangid=%d", pInfo[playerid][pGangID]);
	new Cache:ggm = mysql_query(ObliGangcon, query), rowcount;
    if(cache_num_rows())
    {
        cache_get_value_index_int(0, 0, rowcount);
        #if DebugOn == true
        printf("Number of Gang members: %i in gang id : %i", rowcount, pInfo[playerid][pGangID]);
        #endif
        if( rowcount < MAX_GANG_MEMBERS)
        {
	        SendError(playerid, "You can't have more than "#MAX_GANG_MEMBERS" members in your gang!");
	        cache_delete(ggm);
	        return 1;
		}
    }
    cache_delete(ggm);
    //
	format(String, sizeof(String), ""OGANG" %s(%i) has invited you to his gang '%s'. Type /gjoin or /gdeny to respond.", _GetName(playerid), playerid, GangInfo[pInfo[playerid][pGangID]][GangName]);
	SendClientMessage(otherid, -1, String);

	format(String, sizeof(String), ""OGANG" You have invited %s(%i) to join your gang, wait for the player to respond.", _GetName(otherid), otherid);
	SendClientMessage(playerid, -1, String);
	SetPVarInt(otherid, "ganginvplayer", playerid);
	return true;
}

CMD:gchat(playerid, params[])
{
	if(pInfo[playerid][pGangID] == -1) return SendError(playerid, "You are not in a gang!");
	format(String, sizeof(String), ""WHITE"["YELLOW"GANG"WHITE"] %s(%i): %s", _GetName(playerid), playerid, params);
	gang_announce(pInfo[playerid][pGangID], String);
	return 1;
}

CMD:gkick(playerid, params[])
{
    if(pInfo[playerid][pGangID] == -1) return SendError(playerid, "You are not in a gang!");
    if(pInfo[playerid][pGangRank] < GANG_RANK_LEADER) return SendError(playerid, "You need to be leader of the gang!");
    new nametmp[24], query[300];
	if(sscanf(params, "s[24]", nametmp))
	{
	    SendError(playerid, "/gkick <name>");
	    return true;
	}
	new escapestr[24];
	mysql_escape_string(nametmp, escapestr);
	format(query, sizeof(query), "SELECT gangid FROM users WHERE name = '%s'", escapestr);
	mysql_tquery(ObliGangcon, query, "KickMember", "is", playerid, nametmp);
    return 1;
}

forward KickMember(playerid, kname[]);
public KickMember(playerid, kname[])
{
	if(!cache_num_rows())
	{
		format(String, sizeof(String), ""RED"Player '%s's' name exists in the database.", kname);
		return SendClientMessage(playerid, -1, String);
	}
	
    new pgangid, line[200],query[300];
    
    cache_get_value_index_int(0, 0, pgangid);
    
    if(pgangid != pInfo[playerid][pGangID]) return SendError(playerid, "This player is not in your gang!");

	format(line, sizeof(line), ""OGANG" %s(%i) has kicked out %s from the gang.", _GetName(playerid), playerid, kname);
	gang_announce(pInfo[playerid][pGangID], line);
	

	format(query, sizeof(query), "UPDATE users SET gangid=-1,gangrank=0 WHERE name = '%s'", kname);
	mysql_query(ObliGangcon,query);
	
	new kplayerid;
	if (!sscanf(kname, "r", kplayerid) && kplayerid != INVALID_PLAYER_ID)
	{
	     pInfo[kplayerid][pGangRank] = GANG_RANK_NONE;
	     pInfo[kplayerid][pGangID] = -1;
	}
	return 1;
}

CMD:gjoin(playerid)
{
    new  query[500];
	new Invitee = GetPVarInt(playerid, "ganginvplayer");

	if(GetPVarInt(playerid, "ganginvplayer") == -1) return SendError(playerid, "You have not been invited to any gang.");

	if(Invitee == INVALID_PLAYER_ID)
		return SendError(playerid, "The player that has invited you has left the server! Invite has been cancelled."), DeletePVar(playerid, "ganginvplayer");

	pInfo[playerid][pGangID] = pInfo[Invitee][pGangID];
	pInfo[playerid][pGangRank] = GANG_RANK_NEWBIE;
	
	format(query, sizeof(query), "INSERT INTO `users` (`name`, `gangid`, `gangrank`)  VALUES ('%s','%d','%d')",
	_GetName(playerid), pInfo[playerid][pGangID], pInfo[playerid][pGangRank]);
    mysql_query(ObliGangcon,query);


	format(String, sizeof(String), ""OGANG" %s(%i) has joined the gang! Invited by: %s(%d)", _GetName(playerid), playerid, _GetName(Invitee), Invitee);
	gang_announce(pInfo[playerid][pGangID], String);

	SetPVarInt(playerid, "ganginvplayer", -1);
	return true;
}

CMD:gdeny(playerid)
{
	new Invitee = GetPVarInt(playerid, "ganginvplayer");
	if(GetPVarInt(playerid, "ganginvplayer") == -1) return SendError(playerid, "You have not been invited to any gang.");

	if(Invitee == INVALID_PLAYER_ID)
		return SendError(playerid, "The player that has invited you has left the server! Invite has been cancelled."), DeletePVar(playerid, "ganginvplayer");

	format(String, sizeof(String), ""OGANG" You have denied the gang request from %s(%d)", _GetName(Invitee), Invitee);
	SendClientMessage(playerid, -1, String);

	format(String, sizeof(String), ""OGANG" %s(%d) has denied the gang request.", _GetName(playerid), playerid);
	SendClientMessage(Invitee, -1, String);
	
	SetPVarInt(playerid, "ganginvplayer", -1);
	return true;
}
CMD:gcolor(playerid, params[])
{

    if(pInfo[playerid][pGangID] == -1) return SendError(playerid, "You are not in a gang!");
    if(pInfo[playerid][pGangRank] < GANG_RANK_LEADER)
		return SendError(playerid, "You must be at least the leader member of the gang to set ranks!");
    
	new r, g, b;
	if(sscanf(params, "iii", r, g, b) || !(0 <= r <= 255) || !(0 <= g <= 255) || !(0 <= b <= 255))
	{
	   SendError(playerid, "/gcolor <R> <G> <B>");
	}
	else
	{
		if(r < 30 || g < 30 || b < 30)
		{
   			return SendError(playerid, "Color too dark! RGB values under 30 are not allowed!");
		}

		new GCOLOR = RGBA(r, g, b, 255);

		format(String, sizeof(String), "UPDATE `gang` SET `color` = %i WHERE `id` = %i LIMIT 1;", GCOLOR, pInfo[playerid][pGangID]);
		mysql_tquery(ObliGangcon, String);
		
        GangInfo[pInfo[playerid][pGangID]][GangColor] = GCOLOR;
        
	    format(String, sizeof(String), ""OGANG" %s(%i) set the gang color to {%06x} new color", _GetName(playerid), playerid, GCOLOR >>> 8);
		gang_announce(pInfo[playerid][pGangID], String);
	}
	return 1;
}

CMD:grank(playerid, params[])
{
	new line[300], query[300], otherid;
  	if(pInfo[playerid][pGangID] == -1) return SendError(playerid, "You are not in a gang!");
	if(pInfo[playerid][pGangRank] < GANG_RANK_LEADER)
		return SendError(playerid, "You must be at least the leader member of the gang to set ranks!");

	new level;
	if(sscanf(params, "ui", otherid, level))
	{
	    SendError(playerid, "/grank <playerid> <rank>");
 		return true;
	}
	
	if(otherid == INVALID_PLAYER_ID)
        return SendError(playerid, "Player not connected!");
        
	if(pInfo[otherid][pGangID] != pInfo[playerid][pGangID]) return SendError(playerid, "This player is not in your gang!");
	
	if(level > GANG_RANK_LEADER)
		return SendError(playerid, "Level can't be higher than leader(3)!");
		
	if(level < GANG_RANK_NEWBIE)
		return SendError(playerid, "Level can't be lower than newbie(1)!");

	if(pInfo[otherid][pGangRank] >= pInfo[playerid][pGangRank]) return SendError(playerid, "You can't set level on a gang member higher than you!");
	if(pInfo[otherid][pGangRank] == level) return SendError(playerid, "Player is already this level!");

	if(pInfo[playerid][pGangRank] != GANG_RANK_FOUNDER)
	{
		if(level == GANG_RANK_LEADER) return SendError(playerid, "Only gang founders can promote others to gang leaders.");
		if(pInfo[otherid][pGangRank] == GANG_RANK_FOUNDER)
		{
			SendError(playerid, "You can't set levels on the gang founder!");
			format(String, sizeof(String), "%s(%d) has just tried to set your gang rank level!", _GetName(playerid), playerid);
			SendClientMessage(otherid, -1, String);
			return 1;
		}
	}

	new levelstr[12];
	levelstr = (level > pInfo[otherid][pGangRank]) ? ("promoted") : ("demoted");

	pInfo[otherid][pGangRank] = level;

	format(query, sizeof(query), "UPDATE users SET gangrank=%d WHERE name='%s'", level, _GetName(otherid));
	mysql_query(ObliGangcon,query);

	if(pInfo[playerid][pGangRank] == GANG_RANK_FOUNDER)
	{
		format(String, sizeof(String), "You have been %s to %s(%d) by gang founder %s(%d)!", levelstr, GetGangRank(level), level, _GetName(playerid), playerid);
		format(line, sizeof(line), ""OGANG" %s(%i) has been %s to %s(%d) by gang founder %s(%i)", _GetName(otherid), otherid, levelstr, GetGangRank(level), level, _GetName(playerid), playerid);
	}
	else
	{
		format(String, sizeof(String), "You have been %s to %s(%d) by gang co-founder %s(%d)!", levelstr, GetGangRank(level), level, _GetName(playerid), playerid);
		format(line, sizeof(line), ""OGANG" %s(%i) has been %s to %s(%d) by gang co-founder %s(%i)", _GetName(otherid), otherid, levelstr, GetGangRank(level), level, _GetName(playerid), playerid);
	}
	ShowPlayerDialog(otherid, DIALOG_NONE, DIALOG_STYLE_MSGBOX, ""YELLOW"Obli Gang System "WHITE"- Gang Rank", String, "Close", "");
	gang_announce(pInfo[playerid][pGangID], line);
	return true;
}

CMD:gleave(playerid)
{
  	if(pInfo[playerid][pGangID] == -1) return SendError(playerid, "You are not in a gang!");

  	if(pInfo[playerid][pGangRank] == GANG_RANK_FOUNDER) return SendError(playerid, "You can't leave the gang as the gang founder, type /gclose to close the gang.");

  	format(String, sizeof(String), ""OGANG" %s(%i) has left the gang.", _GetName(playerid), playerid);
    gang_announce(pInfo[playerid][pGangID], String);

	format(String, sizeof(String), "You have left your gang '%s'.", GangInfo[pInfo[playerid][pGangID]][GangName]);
	SendClientMessage(playerid, -1, String);

	pInfo[playerid][pGangRank] = GANG_RANK_NONE;
	pInfo[playerid][pGangID] = -1;

	format(String, sizeof(String), "UPDATE users SET gangid=-1,gangrank=0 WHERE name='%s'", _GetName(playerid));
	mysql_query(ObliGangcon, String);
	return true;
}

CMD:gclose(playerid)
{
    if(pInfo[playerid][pGangID] == -1) return SendError(playerid, "You must be a gang member to use this command!");
    if(pInfo[playerid][pGangRank] != GANG_RANK_FOUNDER) return SendError(playerid, "You must be the gang founder to disband the gang!");
    
    new query[300];
	SendClientMessage(playerid, -1, ""OGANG"You have closed the gang!");
	gang_announce(pInfo[playerid][pGangID], "The gang has been closed by it's founder");

	foreach(new i : Player)
	{
		if(pInfo[i][pGangID] == pInfo[playerid][pGangID])
		{
			pInfo[i][pGangID] = -1;
			pInfo[i][pGangRank] = 0;
			format(query, sizeof(query), "UPDATE users SET `gangid`=-1,`gangrank`=0 WHERE gangid=%d", pInfo[i][pGangID]);
	        mysql_query(ObliGangcon, query);
		}
	}
	format(query, sizeof(query), "DELETE FROM `gang` WHERE `id` = %d", pInfo[playerid][pGangID]);
	mysql_query(ObliGangcon, query);
	Iter_Remove(Obligang, pInfo[playerid][pGangID]);
	return 1;
}

public OnDialogResponse(playerid, dialogid, response, listitem, inputtext[])
{
  if(dialogid == DIALOG_MENU)
  {
	switch(listitem)
	{
	   case 0: return cmd_ginfo(playerid);
	   case 1: return cmd_gmembers(playerid);
	   case 2: return cmd_gkick(playerid,"");
	   case 3: return cmd_grank(playerid,"");
	   case 4: return cmd_gtop(playerid);
	}
	return 1;
  }
  return false;
}
public OnPlayerDeath(playerid, killerid, reason)
{
   if(killerid != INVALID_PLAYER_ID)
   {
	   	if(pInfo[killerid][pGangID] != -1)
		{
		   if(pInfo[killerid][pGangID] != pInfo[playerid][pGangID])
		   {
		  	 GangInfo[pInfo[killerid][pGangID]][GangScore]++;
             UpdateGangScore(pInfo[killerid][pGangID], GangInfo[pInfo[killerid][pGangID]][GangScore] );
		   }
	 	}
   }
   return 1;
}

public OnPlayerText(playerid, text[])
{
    if(text[0] == '!' && pInfo[playerid][pGangID] != -1)
	{
		cmd_gchat(playerid, text[1]);
		return false;
	}
	// OnPlayerText
    if(pInfo[playerid][pGangID] != -1)
    {
		  format(String, sizeof(String), "[%s] %s(%i) %s",GangInfo[pInfo[playerid][pGangID]][GangTag],_GetName(playerid), playerid, text);
	}
	else format(String, sizeof(String), "%s(%i) %s",_GetName(playerid), playerid, text);
	SendClientMessageToAll(-1, String);
	return false;
}


CMD:gcmds(playerid)
{
    new gcstr[1164];
    strcat(gcstr,""WHITE"/gcreate\t\t"WHITE"-\t"SBLUE"To create a gang\n");
    strcat(gcstr,""WHITE"/gjoin\t\t\t"WHITE"-\t"SBLUE"To accept an invitation to a gang\n");
    strcat(gcstr,""WHITE"/gdeby\t\t\t"WHITE"-\t"SBLUE"To decline an invitation to a gang\n");
    strcat(gcstr,""WHITE"/gkick\t\t\t"WHITE"-\t"SBLUE"To kick a gangmember\n");
    strcat(gcstr,""WHITE"/gcolor\t\t\t"WHITE"-\t"SBLUE"To set your gang color\n");
    strcat(gcstr,""WHITE"/gmenu\t\t\t"WHITE"-\t"SBLUE"To view all gang control panel\n");
    strcat(gcstr,""WHITE"/ginvite\t\t\t"WHITE"-\t"SBLUE"To invite other players to the gang\n");
    strcat(gcstr,""WHITE"/grank\t\t\t"WHITE"-\t"SBLUE"To set a member as gang rank\n");
    strcat(gcstr,""WHITE"/grename\t\t\t"WHITE"-\t"SBLUE"To rename your gang\n");
    strcat(gcstr,""WHITE"/gleave\t\t\t"WHITE"-\t"SBLUE"To leave your gang\n");
    strcat(gcstr,""WHITE"/gclose\t\t\t"WHITE"-\t"SBLUE"To close your gang\n");
    strcat(gcstr,""WHITE"/gtop\t\t\t"WHITE"-\t"SBLUE"To view top 10 gangs\n");
    strcat(gcstr,""WHITE"/ginfo\t\t\t"WHITE"-\t"SBLUE"To view your gang information\n");
    ShowPlayerDialog(playerid, DIALOG_NONE ,DIALOG_STYLE_MSGBOX,""OGANG" - GANG COMMANDS",gcstr,"OK","");
    return 1;
}

gang_announce(id, gmsg[])
{
	foreach(new p : Player)
	{
		if(pInfo[p][pGangID] == id)
			SendClientMessage(p, -1, gmsg);
	}
	return 1;
}
GetGangRank(rank)
{
   new rk[20];
   switch(rank)
   {
	  case GANG_RANK_NONE: rk = "None";
	  case GANG_RANK_NEWBIE: rk = "Newbie";
	  case GANG_RANK_MEMBER: rk = "Member";
	  case GANG_RANK_LEADER: rk = "Leader";
	  case GANG_RANK_FOUNDER: rk = "Gang Founder";
   }
   return rk;
}


UpdateGangScore(id, score)
{
  new query[200];
  format(query, sizeof(query), "UPDATE gang SET `score` = score+%d WHERE `id` =%d", score,id);
  mysql_query(ObliGangcon, query);
}

_GetName(playerid)
{
   new name[MAX_PLAYER_NAME +1];
   GetPlayerName(playerid, name, sizeof(name));
   return name;
}
