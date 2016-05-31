/*
	Filterscript Credits:
	
	Pembuat Script: Agus Syahputra
	Tanggal pembuatan: 22/05/2016 - 19:19
	Nama Script: Dynamic Board System (board.pwn)
	
	BlueG & maddinat0r untuk plugin MySql
	Zeex untuk include ZCMD
	Incognito untuk plugin streamer
	Y_Less untuk plugin sscanf

*/

#include 	<a_samp>
#include    <a_mysql>
#include 	<streamer>
#include    <sscanf2>
#include    <ZCMD>

#define 	MYSQL_HOST 		"" //Isi host databasenya, seperti: 127.0.0.1.
#define 	MYSQL_USER 		"" //Isi user yang ada di database MySql.
#define 	MYSQL_DATABASE 	"" //Masukkan nama database yang di buat.
#define 	MYSQL_PASSWORD 	"" //Password database

#define COLOR_GREY	(0xAFAFAFFF)

#define MAX_BOARD 200

#define DIALOG_MATERIAL_SIZE	2080
#define DIALOG_OBJECT_MODEL     2081
#define DIALOG_FONT_TEXT 	    2082

#define SendErrorMessage(%0,%1) \
	SendClientMessage(%0, COLOR_GREY, "ERROR: {FFFFFF}"%1)
	
#define SendSyntaxMessage(%0,%1) \
	SendClientMessage(%0, COLOR_GREY, "SYNTAX: {FFFFFF}"%1)
	
stock const FontSizes[][] = {
	{OBJECT_MATERIAL_SIZE_32x32, "32x32" },
	{OBJECT_MATERIAL_SIZE_64x32, "64x32" },
	{OBJECT_MATERIAL_SIZE_64x64, "64x64" },
	{OBJECT_MATERIAL_SIZE_128x32, "128x32" },
	{OBJECT_MATERIAL_SIZE_128x64, "128x64" },
	{OBJECT_MATERIAL_SIZE_128x128, "128x128" },
	{OBJECT_MATERIAL_SIZE_256x32, "256x32" },
	{OBJECT_MATERIAL_SIZE_256x64, "256x64" },
	{OBJECT_MATERIAL_SIZE_256x128 ,"256x128" },
	{OBJECT_MATERIAL_SIZE_256x256 ,"256x256" },
	{OBJECT_MATERIAL_SIZE_512x64, "512x64" },
	{OBJECT_MATERIAL_SIZE_512x128, "512x128" },
	{OBJECT_MATERIAL_SIZE_512x256, "512x256" },
	{OBJECT_MATERIAL_SIZE_512x512, "512x512" }
};

stock const Font[][] = {
	"Ariel",
	"Courier",
	"Calibri",
	"Fixedsys",
	"Times New Roman",
	"Comic Sans MS"
};

stock const ObjectList[][] = {
	{18244, "cuntw_stwnmotsign1"},
	{9314, "advert01_sfn"},
    {19475,	"Plane001"},
	{19475,	"Plane001"},
	{19476,	"Plane002"},
	{19477,	"Plane003"},
	{19478,	"Plane004"},
	{19479,	"Plane005"},
	{19480,	"Plane006"},
	{19481,	"Plane007"},
	{19482,	"Plane008"},
	{19483, "Plane009"}
};
	
enum board
{
	bID,
	bName[128],
	bExists,
	Float:bX,
	Float:bY,
	Float:bZ,
	Float:bRX,
	Float:bRY,
	Float:bRZ,
	bObject,
	bFontColor,
	bBackColor,
	bFontSize,
	bMaterialSize,
	bObjectModel,
	bFontText[28]
};

new
	database = -1,
	EditBoard[MAX_PLAYERS] = {-1, ...};

new
	BoardData[MAX_BOARD][board];

public OnFilterScriptInit()
{
	database = mysql_connect(MYSQL_HOST, MYSQL_USER, MYSQL_DATABASE, MYSQL_PASSWORD);
	if (mysql_errno())
		printf("Board Text database can't loaded. (Error #%d)", mysql_errno());
	else
	    print("Board Text system loaded.");

	mysql_tquery(database, "SELECT * FROM `board`", "Board_Load");
	
	mysql_tquery(database, "CREATE TABLE IF NOT EXISTS `board` ( \
	  `ID` int(11) NOT NULL, \
	  `posX` float NOT NULL, \
	  `posY` float NOT NULL, \
	  `posZ` float NOT NULL, \
	  `posRX` float NOT NULL, \
	  `posRY` float NOT NULL, \
	  `posRZ` float NOT NULL, \
	  `name` varchar(128) NOT NULL, \
	  `fontsize` int(11) NOT NULL, \
	  `materialsize` int(11) NOT NULL, \
	  `fontcolor` int(11) NOT NULL, \
	  `backcolor` int(11) NOT NULL, \
	  `objectmodel` int(11) NOT NULL, \
	  `fonttext` varchar(28) NOT NULL \
	) ENGINE=InnoDB AUTO_INCREMENT=15 DEFAULT CHARSET=latin1;");

	mysql_tquery(database, "ALTER TABLE `board` \
 	ADD PRIMARY KEY (`ID`);");

	return 1;
}

public OnFilterScriptExit()
{
	for (new i=0; i != MAX_BOARD; i++) if (BoardData[i][bExists]) {
	    Board_Save(i);
	}
	return 1;
}

forward Board_Load();
public Board_Load()
{
    new rows = cache_num_rows();
	if (rows)
	{
	    for (new i; i < rows; i++)
	    {
			BoardData[i][bExists] = true;
			
			BoardData[i][bID] = cache_get_field_content_int(i, "ID", database);
			
			cache_get_field_content(i, "name", BoardData[i][bName], database, 128);
			cache_get_field_content(i, "fonttext", BoardData[i][bFontText], database, 28);
			
			BoardData[i][bX] = cache_get_field_content_float(i, "posX", database);
			BoardData[i][bY] = cache_get_field_content_float(i, "posY", database);
			BoardData[i][bZ] = cache_get_field_content_float(i, "posZ", database);

			BoardData[i][bRX] = cache_get_field_content_float(i, "posRX", database);
			BoardData[i][bRY] = cache_get_field_content_float(i, "posRY", database);
			BoardData[i][bRZ] = cache_get_field_content_float(i, "posRZ", database);
			
			BoardData[i][bFontSize] = cache_get_field_content_int(i, "fontsize", database);
			BoardData[i][bMaterialSize] = cache_get_field_content_int(i, "materialsize", database);

            BoardData[i][bFontColor] = cache_get_field_content_int(i, "fontcolor", database);
			BoardData[i][bBackColor] = cache_get_field_content_int(i, "backcolor", database);

            BoardData[i][bObjectModel] = cache_get_field_content_int(i, "objectmodel", database);

			Board_Refresh(i);
	    }
	}
	return 1;
}

Board_Save(id)
{
	new string[1024];
	
	format(string, sizeof(string),"UPDATE `board` SET `posX`='%f',`posY`='%f',`posZ`='%f',`posRX`='%f',`posRY`='%f',`posRZ`='%f',`name`='%s',`fontcolor`='%d',`backcolor`='%d',`fontsize`='%d', `materialsize`='%d', `objectmodel` = '%d', `fonttext`='%s' WHERE `ID` = '%d'",
	    BoardData[id][bX],
	    BoardData[id][bY],
	    BoardData[id][bZ],
	    BoardData[id][bRX],
	    BoardData[id][bRY],
	    BoardData[id][bRZ],
	    BoardData[id][bName],
	    BoardData[id][bFontColor],
	    BoardData[id][bBackColor],
	    BoardData[id][bFontSize],
	    BoardData[id][bMaterialSize],
	    BoardData[id][bObjectModel],
	    BoardData[id][bFontText],
	    BoardData[id][bID]);
	    
	return mysql_tquery(database, string);
}

static Board_Refresh(id)
{
    if (id != -1 && BoardData[id][bExists])
    {
		if (IsValidDynamicObject(BoardData[id][bObject]))
			DestroyDynamicObject(BoardData[id][bObject]);

	    BoardData[id][bObject] = CreateDynamicObject(BoardData[id][bObjectModel], BoardData[id][bX], BoardData[id][bY], BoardData[id][bZ], BoardData[id][bRX], BoardData[id][bRY], BoardData[id][bRZ]);
		SetDynamicObjectMaterial(BoardData[id][bObject], 1, 18646, "matcolours", "grey-80-percent", 0);
		SetDynamicObjectMaterialText(BoardData[id][bObject], 0, BoardData[id][bName], BoardData[id][bMaterialSize], BoardData[id][bFontText], BoardData[id][bFontSize], 1, BoardData[id][bFontColor], BoardData[id][bBackColor], 1);
	}
	return 1;
}

static Board_FreeID()
{
	for (new i; i != MAX_BOARD; i++) if (!BoardData[i][bExists]) {
	    return i;
	}
	return -1;
}

static Board_Nearest(playerid)
{
	for (new id; id != MAX_BOARD; id++) if (BoardData[id][bExists] && IsPlayerInRangeOfPoint(playerid, 5, BoardData[id][bX], BoardData[id][bY], BoardData[id][bZ])) {
		return id;
	}
	return -1;
}

static Board_Create(name[], Float:x, Float:y, Float:z, Float:rx, Float:ry, Float:rz, font[] = "Arial", fontsize = 30, fontcolor = 0xFFFFFFFF, backcolor = 0xFF000000, model = 9314, materialsize = 130)
{
	new	i = -1;

	if ((i = Board_FreeID()) != -1)
	{

        FixText(name);

        BoardData[i][bExists] = true;
	    format(BoardData[i][bName], 128, "%s", ColouredText(name));
	    format(BoardData[i][bFontText], 28, font);

		BoardData[i][bX] = x;
	 	BoardData[i][bY] = y;
	 	BoardData[i][bZ] = z;
	 	
		BoardData[i][bFontColor] = fontcolor;
		BoardData[i][bBackColor] = backcolor;
		BoardData[i][bFontSize] = fontsize;
		BoardData[i][bMaterialSize] = materialsize;
		BoardData[i][bObjectModel] = model;

		BoardData[i][bObject] = CreateDynamicObject(BoardData[i][bObjectModel], x, y, z, rx, ry, rz);
		SetDynamicObjectMaterial(BoardData[i][bObject], 1, 18646, "matcolours", "grey-80-percent", 0);
		SetDynamicObjectMaterialText(BoardData[i][bObject], 0, BoardData[i][bName], BoardData[i][bMaterialSize], BoardData[i][bFontText], BoardData[i][bFontSize], 1, BoardData[i][bFontColor], BoardData[i][bBackColor], 1);

        mysql_tquery(database, "INSERT INTO `board`(`fontsize`) VALUES (30)", "BoardCreated", "d", i);
		return i;
	}
	return 1;
}

FixText(text[])
{
    //Credits from Texture Studio Filterscript (Pottus)
    
	new len = strlen(text);
	if (len > 1)
	{
		for(new i = 0; i < len; i++)
		{
			if (text[i] == 92)
			{
			    if (text[i+1] == 'n')
			    {
					text[i] = '\n';
					for(new j = i+1; j < len; j++) text[j] = text[j+1], text[j+1] = 0;
					continue;
			    }
			}
		}
	}
	return 1;
}

ColouredText(text[])
{
	//Credits to RyDeR`
	new
	    pos = -1,
	    string[(128 + 16)]
	;
	strmid(string, text, 0, 128, (sizeof(string) - 16));

	while((pos = strfind(string, "#", true, (pos + 1))) != -1)
	{
	    new
	        i = (pos + 1),
	        hexCount
		;
		for( ; ((string[i] != 0) && (hexCount < 6)); ++i, ++hexCount)
		{
		    if (!(('a' <= string[i] <= 'f') || ('A' <= string[i] <= 'F') || ('0' <= string[i] <= '9')))
		    {
		        break;
		    }
		}
		if ((hexCount == 6) && !(hexCount < 6))
		{
			string[pos] = '{';
			strins(string, "}", i);
		}
	}
	return string;
}

forward BoardCreated(id);
public BoardCreated(id)
{
	BoardData[id][bID] = cache_insert_id(database);
	Board_Save(id);
	return 1;
}

CMD:near(playerid, params[])
{
	new
		id,
		string[128];

    if (!IsPlayerAdmin(playerid))
	    return SendErrorMessage(playerid, "Kamu harus login sebagai admin untuk menggunakan perintah ini (RCON Login).");
	
	if ((id = Board_Nearest(playerid)) != -1)
	{
	    format(string, sizeof(string), "Kamu berada di sekitar board ID: %d.", id);
	    SendClientMessage(playerid, -1, string);
	}
	return 1;
}

CMD:createboard(playerid, params[])
{
	new
		name[128],
		id,
		string[128],
		Float:x,
		Float:y,
		Float:z,
		Float:angle;
	    
    GetPlayerPos(playerid, x, y, z);
	GetPlayerFacingAngle(playerid, angle);
	    
    x += 5.0 * floatsin(-angle, degrees);
    y += 5.0 * floatcos(-angle, degrees);
	    
    if (!IsPlayerAdmin(playerid))
	    return SendErrorMessage(playerid, "Kamu harus login sebagai admin untuk menggunakan perintah ini (RCON Login).");

	if (sscanf(params, "s[128]", name))
	    return SendSyntaxMessage(playerid, "/createboard [name]");
	    
    if (strlen(name) > 128)
    	return SendErrorMessage(playerid, "Text untuk board terlalu panjang.");
		    
	id = Board_Create(name, x, y, z, 0, 0, angle);

	if (id == -1)
	    return SendErrorMessage(playerid, "Board telah membatasi batas yang di tentukan.");

    EditDynamicObject(playerid, BoardData[id][bObject]);
	EditBoard[playerid] = id;
	
	format(string,sizeof(string),"( ! ) {FFFFFF}Board telah berhasi di buat. (ID: %d)",id);
	SendClientMessage(playerid, 0xC0C0C0FF, string);
	return 1;
}

CMD:editboard(playerid, params[])
{
	new string[128],
		options[32],
		notice[128],
		id;
		
	if (!IsPlayerAdmin(playerid))
	    return SendErrorMessage(playerid, "Kamu harus login sebagai admin untuk menggunakan perintah ini (RCON Login).");
		
	if (sscanf(params, "ds[32]S()[128]", id, options, string))
	    return SendSyntaxMessage(playerid, "/editboard [id] [move/text/fontcolor/backcolor/refresh/destroy/fontsize/materialsize/font/model/duplicate]");
	    
	if ((id < 0 && id >= MAX_BOARD) || !BoardData[id][bExists])
	    return SendErrorMessage(playerid, "ID Yang kamu masukkan salah atau tidak terdaftar.");
	    
	if (!strcmp(options, "move"))
	{
	    EditBoard[playerid] = id;
        EditDynamicObject(playerid, BoardData[id][bObject]);
        
        SendClientMessage(playerid, -1, "Geser kursor untuk memindahkan object yang di seleksi.");
	}
	else if (!strcmp(options, "text"))
	{
	    new text[128];
	    
	    if (sscanf(string,"s[128]", text))
	        return SendSyntaxMessage(playerid, "/editboard [id] [text] 'text'");
	    	
		if (strlen(text) > 128)
		    return SendErrorMessage(playerid, "Text untuk board terlalu panjang.");
		    
        FixText(text);
		format(BoardData[id][bName], 128, "%s", ColouredText(text));
		Board_Refresh(id);
		
		format(notice,sizeof(notice),"( ! ) {FFFFFF}Board Text ID: %d telah di ubah. (%s)",id, BoardData[id][bName]);
		SendClientMessage(playerid, 0xC0C0C0FF, notice);
	}
	else if (!strcmp(options, "fontcolor"))
	{
	    new hax;
	    
	    if (sscanf(string,"h", hax))
	        return SendSyntaxMessage(playerid, "/editboard [id] [fontcolor] 'hax'");

		BoardData[id][bFontColor] = hax;

		Board_Refresh(id);
		
		format(notice,sizeof(notice),"( ! ) {FFFFFF}Warna font untuk ID: %d telah di ubah.",id);
		SendClientMessage(playerid, 0xC0C0C0FF, notice);
	}
	else if (!strcmp(options, "backcolor"))
	{
	    new hax;
	    
	    if (sscanf(string,"h", hax))
	        return SendSyntaxMessage(playerid, "/editboard [id] [backcolor] 'hax'");

        BoardData[id][bBackColor] = hax;
		Board_Refresh(id);
		
		format(notice,sizeof(notice),"( ! ) {FFFFFF}Warna background untuk ID: %d telah di ubah.",id);
		SendClientMessage(playerid, 0xC0C0C0FF, notice);
	}
	else if (!strcmp(options, "refresh"))
	{
		Board_Refresh(id);
		
		format(notice,sizeof(notice),"( ! ) {FFFFFF}Refresh Success (ID: %d).",id);
		SendClientMessage(playerid, 0xC0C0C0FF, notice);
	}
	else if (!strcmp(options, "destroy"))
	{
	    new query[64];
	    
		format(query,sizeof(query), "DELETE FROM `board` WHERE `ID` = '%d'", BoardData[id][bID]);
		mysql_tquery(database, query);
		
		BoardData[id][bExists] = false;
		BoardData[id][bID] = 0;
		DestroyDynamicObject(BoardData[id][bObject]);
		
		format(notice,sizeof(notice),"( ! ) {FFFFFF}Board (ID: %d) telah di hilangkan.",id);
		SendClientMessage(playerid, 0xC0C0C0FF, notice);
	}
	else if (!strcmp(options, "fontsize"))
	{
		new size;

	    if (sscanf(string,"d", size))
	        return SendSyntaxMessage(playerid, "/editboard [id] [fontsize]");

		if (size < 0 && size > 200)
		    return SendErrorMessage(playerid, "Ukuran harus 0 sampai 50.");

		BoardData[id][bFontSize] = size;
		Board_Refresh(id);
		
		format(notice,sizeof(notice),"( ! ) {FFFFFF}Ukuran font (ID: %d) di ubah ke angka %d.",id, size);
		SendClientMessage(playerid, 0xC0C0C0FF, notice);
	}
	else if (!strcmp(options, "materialsize"))
	{
		new dialogstr[128];
		SetPVarInt(playerid, "p_Board", id);
		for (new i = 0, j = sizeof(FontSizes); i < j; i++)
	    {
	        format(dialogstr,sizeof(dialogstr),"%s%s\n",dialogstr,FontSizes[i][1]);
	    }
	    ShowPlayerDialog(playerid, DIALOG_MATERIAL_SIZE, DIALOG_STYLE_LIST, "Material Size",dialogstr, "Select","Close");
	}
	else if (!strcmp(options, "model"))
	{
		new dialogstr[225];
		SetPVarInt(playerid, "p_Board", id);
		for (new i = 0, j = sizeof(ObjectList); i < j; i++)
	    {
	        format(dialogstr,sizeof(dialogstr),"%s%d\t\t%s\n",dialogstr,ObjectList[i][0],ObjectList[i][1]);
	    }
	    ShowPlayerDialog(playerid, DIALOG_OBJECT_MODEL, DIALOG_STYLE_LIST, "Object Model",dialogstr, "Change","Close");
	}
	else if (!strcmp(options, "font"))
	{
		new dialogstr[128];
		SetPVarInt(playerid, "p_Board", id);
		for (new i = 0, j = sizeof(Font); i < j; i++)
	    {
	        format(dialogstr,sizeof(dialogstr),"%s%s\n",dialogstr,Font[i][0]);
	    }
	    ShowPlayerDialog(playerid, DIALOG_FONT_TEXT, DIALOG_STYLE_LIST, "Font Text",dialogstr, "Change","Close");
	}
	else if (!strcmp(options, "duplicate"))
	{
	    new duplicate = -1;

	    duplicate = Board_Create(BoardData[id][bName], BoardData[id][bX], BoardData[id][bY],
			BoardData[id][bZ], BoardData[id][bRX], BoardData[id][bRY], BoardData[id][bRZ], BoardData[id][bFontText],
			BoardData[id][bFontSize], BoardData[id][bFontColor], BoardData[id][bBackColor], BoardData[id][bObjectModel],
			BoardData[id][bMaterialSize]);
	    
	    if (duplicate == -1)
		    return SendErrorMessage(playerid, "Board telah membatasi batas yang di tentukan.");
		    
        EditDynamicObject(playerid, BoardData[duplicate][bObject]);
		EditBoard[playerid] = duplicate;

		format(notice,sizeof(notice),"( ! ) {FFFFFF}Board telah berhasi di buat. (ID: %d)",duplicate);
		SendClientMessage(playerid, 0xC0C0C0FF, notice);
	}
	return 1;
}

public OnPlayerEditDynamicObject(playerid, objectid, response, Float:x, Float:y, Float:z, Float:rx, Float:ry, Float:rz)
{
	if (response == EDIT_RESPONSE_FINAL)
	{
	    if (EditBoard[playerid] != -1 && BoardData[EditBoard[playerid]][bExists])
	    {
		    BoardData[EditBoard[playerid]][bX] = x;
		    BoardData[EditBoard[playerid]][bY] = y;
		    BoardData[EditBoard[playerid]][bZ] = z;
		    BoardData[EditBoard[playerid]][bRX] = rx;
		    BoardData[EditBoard[playerid]][bRY] = ry;
		    BoardData[EditBoard[playerid]][bRZ] = rz;
		    
		    Board_Refresh(EditBoard[playerid]);
		    
		    Board_Save(EditBoard[playerid]);
		}
	}
	if (response == EDIT_RESPONSE_FINAL || response == EDIT_RESPONSE_CANCEL)
	{
		if (EditBoard[playerid] != -1)
		{
		    Board_Refresh(EditBoard[playerid]);
			EditBoard[playerid] = -1;
		}
	}
	return 1;
}

public OnDialogResponse(playerid, dialogid, response, listitem, inputtext[])
{
	if (dialogid == DIALOG_MATERIAL_SIZE)
	{
	    if (response)
	    {
	        new id = GetPVarInt(playerid, "p_Board"),
				notice[128];
				
	        BoardData[id][bMaterialSize] = FontSizes[listitem][0];
	        format(notice,sizeof(notice),"( ! ) {FFFFFF}Ukuran materialsize (ID: %d) telah di ubah (%s).",id, FontSizes[listitem][1]);
			SendClientMessage(playerid, 0xC0C0C0FF, notice);
			Board_Refresh(id);
	    }
	}
	if (dialogid == DIALOG_OBJECT_MODEL)
	{
		if(response)
		{
            new id = GetPVarInt(playerid, "p_Board"),
				notice[128];

	        BoardData[id][bObjectModel] = ObjectList[listitem][0];
	        format(notice,sizeof(notice),"( ! ) {FFFFFF}Object Model (ID: %d) telah di ubah (%s).",id, ObjectList[listitem][1]);
			SendClientMessage(playerid, 0xC0C0C0FF, notice);
			Board_Refresh(id);
		}
	}
	if (dialogid == DIALOG_FONT_TEXT)
	{
		if(response)
		{
            new id = GetPVarInt(playerid, "p_Board"),
				notice[128];

	        format(BoardData[id][bFontText], 28, "%s", Font[listitem][0]);
	        format(notice,sizeof(notice),"( ! ) {FFFFFF}Font text (ID: %d) telah di ubah (%s).",id, Font[listitem][0]);
			SendClientMessage(playerid, 0xC0C0C0FF, notice);
			Board_Refresh(id);
		}
	}
	return 1;
}
