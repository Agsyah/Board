/*
	Filterscript Credits:

	Pembuat Script: Agus Syahputra
	Tanggal pembuatan: 22/05/2016 - 19:19
	Nama Script: Dynamic Board System (board.pwn)

	BlueG & maddinat0r untuk plugin MySql
	Zeex untuk include ZCMD
	Incognito untuk plugin streamer
	Y_Less untuk plugin sscanf
	Y_Less untuk Y_INI

	Amunra(Natan) untuk Convert to Y_INI
*/

#include 	<a_samp> // SAMP Team
//#include    <a_mysql> // Kita menggunakan Y_ini
#include 	<streamer> // Incognito
#include    <sscanf2> // Y_Less improved Emmet_
#include    <YSI\y_ini> // Y_Less
#include    <ZCMD> // ZeeX

#define COLOR_GREY	(0xAFAFAFFF)

#define MAX_BOARD 200 // Max Board yang bisa di buat

#define DIALOG_MATERIAL_SIZE	2080
#define DIALOG_OBJECT_MODEL     2081
#define DIALOG_FONT_TEXT 	    2082

#define SendErrorMessage(%0,%1) \
	SendClientMessage(%0, COLOR_GREY, "ERROR: {FFFFFF}"%1)

#define SendSyntaxMessage(%0,%1) \
	SendClientMessage(%0, COLOR_GREY, "SYNTAX: {FFFFFF}"%1)

#define FileBoard   "Boards/%d.ini" // Ganti sama Nama Folder yang kamu inginkan
// jangan lupa di add foldernya di scriptfiles

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
	EditBoard[MAX_PLAYERS] = {-1, ...};

new
	BoardData[MAX_BOARD][board];

public OnFilterScriptInit()
{
	new folder[200];
	for(new i; i < MAX_BOARD;i++)
	{
		format(folder,sizeof(folder),FileBoard,i);
		if(fexist(folder))
		{
		    INI_ParseFile(folder,"LoadBoard_data",.bExtra = true, .extra = i);
		    printf("Board %d telah berhasil di Load !");
		}
	}
	return 1;
}

public OnFilterScriptExit()
{
	for (new i=0; i != MAX_BOARD; i++) if (BoardData[i][bExists]) {
	    Board_Save(i);
	}
	return 1;
}
forward LoadBoard_data(id, name[] ,value[]);
public LoadBoard_data(id, name[] ,value[])
{
	INI_Float("bX",BoardData[id][bX]);
	INI_Float("bY",BoardData[id][bY]);
	INI_Float("bZ",BoardData[id][bZ]);
	INI_Float("bRX",BoardData[id][bRX]);
	INI_Float("bRY",BoardData[id][bRY]);
	INI_Float("bRZ",BoardData[id][bRZ]);
	INI_String("bName",BoardData[id][bName], 128);
	INI_Int("bFontColor",BoardData[id][bFontColor]);
	INI_Int("bBackColor",BoardData[id][bBackColor]);
	INI_Int("bFontSize",BoardData[id][bFontSize]);
	INI_Int("bMaterialSize",BoardData[id][bMaterialSize]);
	INI_Int("bObjectModel",BoardData[id][bObjectModel]);
	INI_String("bFontText",BoardData[id][bFontText], 28);
	
	Board_Refresh(id);
	return 1;
}

Board_Save(id)
{
	new folder[200];
	format(folder,sizeof(folder),FileBoard,id);

	new INI:file = INI_Open(folder);
	INI_WriteFloat(file,"bX",BoardData[id][bX]);
	INI_WriteFloat(file,"bY",BoardData[id][bY]);
	INI_WriteFloat(file,"bZ",BoardData[id][bZ]);
	INI_WriteFloat(file,"bRX",BoardData[id][bRX]);
	INI_WriteFloat(file,"bRY",BoardData[id][bRY]);
	INI_WriteFloat(file,"bRZ",BoardData[id][bRZ]);
	INI_WriteString(file,"bName",BoardData[id][bName]);
	INI_WriteInt(file,"bFontColor",BoardData[id][bFontColor]);
	INI_WriteInt(file,"bBackColor",BoardData[id][bBackColor]);
	INI_WriteInt(file,"bFontSize",BoardData[id][bFontSize]);
	INI_WriteInt(file,"bMaterialSize",BoardData[id][bMaterialSize]);
	INI_WriteInt(file,"bObjectModel",BoardData[id][bObjectModel]);
	INI_WriteString(file,"bFontText",BoardData[id][bFontText]);
	INI_Close(file);
	return 1;
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

        Board_Save(i);
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

		format(query,sizeof(query), FileBoard, id);
		fremove(query);

		BoardData[id][bExists] = false;
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
