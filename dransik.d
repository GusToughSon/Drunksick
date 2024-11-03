module dransik;

// based on build of 21 December 2007 / MD5=aa373944d2ad89018dcbb306b5259844
// IDA 5.2 database available on request

// **********************************************************

public import utils;

import tango.stdc.stringz;

import win32.windows;
public import win32.winbase : Sleep;

// **********************************************************

HWND window;

void openGame()
{
	window = FindWindowW("DRANSIK"w.ptr, null);
	if (window is null) throw new Exception("Can't find window");
}

void focusGame()
{
	SetForegroundWindow(window);
}

bool isGameFocused()
{
	return GetForegroundWindow() == window;
}

pragma(lib, "kernel32my");
void gameSynchronized(void delegate() fn)
{
	auto id = GetWindowThreadProcessId(window, null);
	assert(id, "Can't get thread ID");
	auto handle = OpenThread(THREAD_ALL_ACCESS, false, id);
	assert(handle, "Can't open thread");
	SuspendThread(handle);
	fn();
	ResumeThread(handle);
	CloseHandle(handle);
}

// **********************************************************

enum Offsets : uint
{
	ObjectList                               = 0x46BE10, // @ ObjRef::SetX
	BattleCursorY                            = 0x477A14, // @ Camera::PrepareData+200
	BattleCursorX                            = BattleCursorY+4,
	SelectionPresent                         = BattleCursorY+8,
	Mouse                                    = 0x472040, // @ MainWindow::CreateStuff+2F6
	ObjectTypeManager                        = 0x471020, // @ CreateStuff+35D
	GameLog                                  = 0x474E4C, // @ CreateStuff+16
	ChunkDatabase                            = 0x470678, // @ CreateStuff+209
	DransikMaps                              = 0x471010, // @ CreateStuff+25F
	TileManager                              = 0x477B94, // @ CreateStuff+161

	PlayerData                               = 0x4744B8, // @ Camera::CalculateLighting+3
	PlayerData__UseObject                    = 0x414460, // PlayerData::UseObject
	PlayerData__SetTarget                    = 0x414430, // PlayerData::SetTarget
	PlayerData__ProcessClick                 = 0x416150, // PlayerData::ProcessClick
	PlayerData__AskForAmount                 = 0x415FD0, // PlayerData::AskForAmount
	PlayerData__Draw_End                     = 0x4155BB, // PlayerData::Draw+1CB      (end of function - on retn)

	PlayerInfo__Draw_End                     = 0x41D658, // PlayerInfo::Draw+AE8      (end of function - on retn)

	Camera                                   = 0x477B68, // @ PlayerData::SetMap
	Camera__DrawName                         = 0x42E460, // Camera::DrawName
	PostProcessScreenTiles                   = 0x42F7BF, // Camera::DrawMainMap+15F - after the call to Camera::CalculateLighting

	SecureDataManager                        = 0x46E610, // @ MainWindow::CreateStuff+280
	SecureDataManager__ReadValue             = 0x404B80, // SecureDataManager::ReadValue
	SecureDataManager__WriteValue            = 0x4049C0, // SecureDataManager::WriteValue

	ClientServices                           = 0x4756BC, // @ PlayerData::SetTarget+14
	ClientServices__SendBeginDrag            = 0x413490, // ClientServices::SendBeginDrag
	ClientServices__SendDropOnItemAt         = 0x413530, // ClientServices::SendDropOnItemAt
	ClientServices__SendDropAt               = 0x4135E0, // ClientServices::SendDropAt
	ClientServices__SendSelectItem           = 0x40E490, // ClientServices::SendSelectItem
	ClientServices__SendWalk                 = 0x413440, // ClientServices::SendWalk
	ClientServices__SendSelectTile           = 0x413840, // ClientServices::SendSelectTile
	ClientServices__SendAmount               = 0x413740, // ClientServices::SendAmount
	ClientServices__SendTradeSkillBoxItem    = 0x41A350, // ClientServices::SendTradeSkillBoxItem
	Packet_ProcessScan                       = 0x42B9D2, // ClientServices::ProcessPacket case 38 - directly after CreateToolhelp32Snapshot call
	Packet_AskForAmount                      = 0x42CC62, // ClientServices::ProcessPacket case 116 - at "mov ecx, PlayerData" above the only Xref to PlayerData::AskForAmount
	Packet_TradeSkillBox                     = 0x42B083, // ClientServices::ProcessPacket case 78 - directly on the "??2@YAPAXI@Z ; operator new(uint)" call

	AutoMap__ProcessClick                    = 0x40B8C0, // AutoMap::ProcessClick
	AutoMap__Draw_End                        = 0x40BC50, // AutoMap::Draw+290         (end of function)

	MainWindow                               = 0x46DEEC, // @ _WinMain@16+45
	MessageLoop                              = 0x403290, // MainWindow::MainLoop+40
	UpdateCodeStart                          = 0x4032CC, // MainWindow::MainLoop+7C - a bit lower than DispatchMessageA
	UpdateCodeEnd                            = 0x4033B5, // MainWindow::MainLoop+165 - before the last VideoSystem::xxx call

	GUIEventDispatcher                       = 0x472038, // @ Gump::ProcessMouseEvent
	TextBoxVtable                            = 0x45C320, // @ TextBox::ctor+3F

	MessageLogCapture                        = 0x426517, // ScreenLog::Log+27
	ScreenLog__Log_TempBuffer                = 0x4752B0, // @ ScreenLog::Log+1D

	Process32First                           = 0x435F30,
	Process32Next                            = 0x435F24,
}

import codetools;

const Code codeNoOp2 = [0x90, 0x90];
const Code codeNoOp6 = [0x90, 0x90, 0x90, 0x90, 0x90, 0x90];
const Code codeJumpAlways = [0xEB];

const PatchSet CavernAutoMap = 
[
	{cast(ubyte*)0x4154AA, [0x33, 0xFF], codeNoOp2},                         // PlayerData::Draw+BA - xor reg, reg
	{cast(ubyte*)0x4068A9, [0x74], codeJumpAlways},                          // DransikMap::GetMapChunkAt+A9   (gump visibility)
	{cast(ubyte*)0x406750, [0x0F, 0x85, 0x9E, 0x00, 0x00, 0x00], codeNoOp6}, // DransikMap::SetMapChunkAt+10   (enable map recording (NOTE: can be redone by setting a flag))
];

// **********************************************************

public import objtypes;

enum ObjectClass : uint
{
	None = 0,
	Player1 = 1,   // green name? human?
	Player2 = 6,   // brown name? Brimlock?
	Monster = 13
}

// **********************************************************

const SCREEN_SIZE = 21;
const SCREEN_AREA = SCREEN_SIZE*SCREEN_SIZE;
const SCREEN_ROW_SIZE = (SCREEN_SIZE+1)&~1;

// **********************************************************

mixin(mixOrdPtr("int", "battleCursorX", "BattleCursorX"));
mixin(mixOrdPtr("int", "battleCursorY", "BattleCursorY"));
mixin(mixOrdPtr("bool", "selectionPresent", "SelectionPresent"));

// **********************************************************

enum ObjectFlags : uint
{
	Visible     = 0x00000002,
	InInventory = 0x00000004,  // guessed
	PC          = 0x04000000,  // guessed
	OnMap       = 0x10000000,  // guessed
	NPC         = 0x20000000,
	Attackable  = 0x40000000,
}

struct GlobalObject
{
	GlobalObject* next, prev;
	ObjectType objType;
	uint ID;
	int x, y, map;
	uint Health, MaxHealth;
	int f24;
	ObjectFlags flags;
	ObjectClass objClass;
	int sprite;
	char* name;

	int opApply(int delegate(ref GlobalObject) dg)
	{   
		int result = 0;
		GlobalObject* obj = this;
		do
		{
			result = dg(*obj);
			if (result)
				break;
			obj = obj.next;
		} while(obj !is null);
		return result;
	}

	bool attackable()
	{
		if(flags & ObjectFlags.Attackable)
			return objClass == ObjectClass.Monster;
		else
			return objectData[objType].alignment >= 20000;
	}
}

mixin(mixObjPtr("GlobalObject", "objectList", "ObjectList"));

/+GlobalObject[] getObjectList()
{
	GlobalObject[] list;
	GlobalObject* obj = *objectList;
	while(obj !is null)
	{
		list ~= [*obj];
		obj = obj.next;
	}
	return list;
}+/

// **********************************************************

enum GumpType : uint
{
	Log        = 0x0107,
	Container  = 0x7000,
	PlayerInfo = 0x7001,
	AutoMap    = 0x7002,
}

struct Gump
{
	void** vtbl;
	uint f4;
	void* nextPtr;
	GumpType type;
	uint f10, f14;
	void* children2;
	void* children;
	uint f20;
	void* parent;
	uint buttonState;
	uint f2C;
	uint x1, y1, x2, y2;
	uint f40, f44;
	static assert(this.sizeof == 0x48);

	Gump* next()
	{
		return (nextPtr is null) ? null : cast(Gump*)(nextPtr-4);
	}

	// iterate through list
	int childrenIterator(int delegate(ref Gump) dg)
	{   
		int result = 0;
		if(children is null) return 0;
		Gump* obj = cast(Gump*)(children-4);
		do
		{
			result = dg(*obj);
			if (result)
				break;
			obj = obj.next;
		} while(obj !is null);
		return result;
	}

	Gump* findChild(GumpType type)
	{
		foreach(ref gump;&childrenIterator)
			if(gump.type == type)
				return &gump;
		return null;
	}
}

struct PlayerData
{
	Gump gump;
	uint f48, f4C, f50;
	uint BackpackID;
	uint MyID;
	uint AttackMode;
	uint f60, f64, f68, f6C, f70, f74, f78;
	char[32] GuildTag;
	uint Health;
	uint fA0;
	uint Weight;
	uint Level;
	uint Exp;
	uint fB0, fB4;
	uint ExpPool;
	uint Str;
	uint StrBonus;
	uint Int;
	uint IntBonus;
	uint Dex;
	uint DexBonus;
	uint Con;
	uint ConBonus;
	uint UpgradePoints;
	uint Sta;
	uint Armor;
	uint fE8, fEC, fF0, fF4;
	uint Deaths;
	uint Kills;
	uint f100, f104, f108, f10C;
	uint[2300] f110;
	uint Equipment[6];
	uint Hour;    
	static assert(Hour.offsetof==0x2518);
	uint IsSunrise;
	uint IsSunset;
	uint ActualLightLevel;
	uint TimeOfDayCounter;
	uint WorldLightLevel;
	uint f2520;
	bool TargetingLocked;
	uint Target;
	uint TargetProtection;
	uint f2530;
	bool WaitingForItemSelection;
	uint f2538, f253C, f2540, f2544;
	bool IsDragging;
	uint DraggedItemID;
	uint HeldItemID;
	uint DragIcon;
	uint DragDestX;
	uint DragDestY;
	uint f2560, f2564, f2568;
	bool DragAll;
	uint f2570, f2574, f2578;
	bool ChatMaximized;
	uint f2580;
	static assert(this.sizeof == 0x2594);

	uint MaxHealth()
	{
		return (Level*3 + Con+ConBonus + 4)*5 + (Str+StrBonus)*2;
	}

	uint MaxWeight()
	{
		return 150 + (Str+StrBonus)*3;
	}

	int containerIterator(int delegate(ref Container) dg)
	{   
		int result = 0;
		if(gump.children is null) return 0;
		Gump* obj = cast(Gump*)(gump.children-4);
		do
		{
			if(obj.type == GumpType.Container)
			{
				result = dg(*cast(Container*)obj);
				if (result)
					break;
			}
			obj = obj.next;
		} while(obj !is null);
		return result;
	}

	char[] guildTag()
	{
		return readStringZ(GuildTag.ptr);
	}

	mixin(mixMethod("PlayerData", "UseObject", ["uint"]));            // ID
	mixin(mixMethod("PlayerData", "SetTarget", ["uint"]));            // ID
	mixin(mixMethod("PlayerData", "AskForAmount", ["uint"]));         // max amount
}

mixin(mixObjPtr("PlayerData", "playerData"));

struct ContainerItem
{
	uint ID, anim, spriteOrAnim;
	bool isAnimated;
	static assert(this.sizeof == 0x10);
}

struct Container
{
	Gump gump;
	uint f48, f4C, f50, f54;
	uint ID;
	uint hasAnimations;
	ContainerItem[768] items;
	uint itemCount;
	uint f3064;
	static assert(this.sizeof == 0x3068);

	mixin(mixArrayIterator("opApply", "ContainerItem", "items", "itemCount"));
}

// **********************************************************

struct Camera
{
	uint[SCREEN_SIZE][SCREEN_SIZE]* ScreenTiles;
	uint[SCREEN_SIZE][SCREEN_SIZE]* MaskedScreenTiles;
	uint[SCREEN_SIZE][SCREEN_SIZE]* Lighting;
	uint[SCREEN_SIZE][SCREEN_SIZE]* MapTiles;
	uint[9] NeighboringTiles;
	CameraObject* Objects;
	CameraObject* Mobs;
	private uint f3C;
	uint ObjectCount;
	uint MobCount;
	private uint f48;
	uint[SCREEN_ROW_SIZE][SCREEN_ROW_SIZE]* TileLighting;
	private uint f50, f54, f58;
	uint SizeX;
	uint SizeY;
	uint Target;
	uint XSecureIndex;
	uint YSecureIndex;
	uint f70;
	uint MapNumberSecureIndex;
	uint f78;
	static assert(this.sizeof==0x7C);

	mixin(mixArrayIterator("objIterator", "CameraObject", "Objects", "ObjectCount"));
	mixin(mixArrayIterator("mobIterator", "CameraObject", "Mobs",    "MobCount"   ));

	mixin(mixMethod("Camera", "DrawName", ["uint", "uint", "char*", "char*", "ubyte"]));  // X, Y, name, name2, colour
}

mixin(mixObjPtr("Camera", "camera"));

import tango.math.Math : abs;

int calcDistance(int x, int y)  // distance to player
{
	return max(abs(10-x), abs(10-y));
}

struct CameraObject
{
	uint Sprite;                                                // display sprite... can be part of an animation (and change for the same object)
	uint ScreenPosition;                                        // X*22+Y
	uint X;
	uint Y;
	uint f10;
	uint ID;
	uint Health;
	uint MaxHealth;
	char* Name;
	char* GuildTag;
	uint NameColour;

	int distance()  // distance to player
	{
		return calcDistance(X, Y);
	}

	char[] name()
	{
		return readStringZ(Name);
	}

	char[] guildTag()
	{
		return readStringZ(GuildTag);
	}
}

enum ObjectFamily : uint
{
	StaticObject  = 0,
	Character     = 2,
	Projectile    = 3,
	Weapon        = 4,
	Armor         = 5,
	Egg           = 6,
	Sign          = 7,
	Material      = 8,
	Gold          = 9
}

enum ObjectDataFlags : uint
{
	Blocking         = 0x00000002,
	Object           = 0x00000004,
	Stackable        = 0x00000008,
	Unknown          = 0x00000010,
	Item             = 0x00000020,
	Transparent      = 0x00000040,
	Glowing          = 0x00000080,
	Egg              = 0x00000100,
	Peaceful         = 0x00000200,
	ShipEntrance     = 0x00000400,
}                        

struct ObjectData
{
	char[32] name;
	uint anim, icon;
	ObjectFamily family;
	ObjectDataFlags flags;
	uint alignment;
	uint f34, f38, f3C;
	
	char[] nameStr()
	{
		return readStringZ(name.ptr);
	}
}

const OBJECT_TYPES = 2048;

struct ObjectTypeManager
{
	ObjectData[OBJECT_TYPES]* objectData;
}

mixin(mixObjPtr("ObjectTypeManager", "objectTypeManager"));

ObjectData[] objectData()
{
	return *objectTypeManager.objectData;
}

struct Canvas
{
	uint f0, characterTable, colour;
}

struct Mouse
{
	uint x, y, animationFrame, fC, attackCursor, f14, infoCursor, useCursor1, useCursor2, f24, f28;

	bool useCursor()
	{
		return useCursor1 || useCursor2;
	}
}

mixin(mixObjPtr("Mouse", "mouse"));

bool readMouseRelativeCoords(out int x, out int y)
{
	x = mouse.x;
	y = mouse.y;
	Gump* automap = playerData.gump.findChild(GumpType.AutoMap);
	if(automap && x>=automap.x1+8 && x<automap.x2-8 && y>=automap.y1+8 && y<automap.y2-8)
	{
		x -= (automap.x1+automap.x2)/2 + 1;
		y -= (automap.y1+automap.y2)/2 + 1;
		return true;
	}

	x = (mouse.x-8)/16 - SCREEN_SIZE/2;
	y = (mouse.y-8)/16 - SCREEN_SIZE/2;
	return abs(x)<=SCREEN_SIZE/2 && abs(y)<=SCREEN_SIZE/2;
}

bool readMouseGlobalCoords(out int x, out int y)
{
	if(readMouseRelativeCoords(x, y))
	{
		x+=myX;
		y+=myY;
		return x>=0 && y>=0 && x<maps.maps[myMap].width*16 && y<maps.maps[myMap].height*16 ;
	}
	else
		return false;
}

bool readMouseScreenCoords(out int x, out int y)
{
	if(readMouseRelativeCoords(x, y))
	{
		x+=SCREEN_SIZE/2;
		y+=SCREEN_SIZE/2;
		return x>=0 && x<SCREEN_SIZE && y>=0 && y<SCREEN_SIZE;
	}
	else
		return false;
}

struct MouseEvent
{
	int EventType, X, Y, fC, f10, Pressed, DoubleClick, Shift, f20, HelpCursor;
}	

// ****************************************************

struct DransikMap
{
	uint width;
	uint height;
	uint f8;
	bool noAutoMap;
	uint f10;
	uint* data1;
	uint* data2;
}

struct DransikMaps
{
	DransikMap[8] maps;
	uint fE0, fE4, fE8;
}

mixin(mixObjPtr("DransikMaps", "maps"));

const ubyte[16] ScrambleData = [1, 15, 2, 5, 14, 4, 11, 6, 8, 12, 13, 9, 0, 10, 7, 3];

int scrambleCoord(int x)
{
	return x&0xFFF0 | ScrambleData[x&0xF];
}

uint scrambleChunk(uint x, uint y, uint chunk)
{
	return (y*19) ^ chunk ^ (x*2) ^ 0x0AA7;
}

uint getChunk(int map, int x, int y)
{
	with(maps.maps[map])
	{
		if(data1 is null || data2 is null) throw new Exception("Can't get map data - map not loaded");
		int sx = scrambleCoord(x), sy = scrambleCoord(y);
		uint chunk1 = data1[ sy*width +  sx];
		assert(chunk1 < 0x10000);
		int ssx = scrambleCoord(sx), ssy = scrambleCoord(sy);
		uint chunk2 = data2[ssy*width + ssx];
		uint chunk2x = scrambleChunk(x, y, chunk1);
		if(chunk2 != chunk2x && chunk2 != 0) throw new Exception("Tile check failed" /*~ " at " ~ .toUtf8(x) ~ "x" ~ .toUtf8(y) ~ ": expected " ~ .toUtf8(chunk2x) ~ " got " ~ .toUtf8(chunk2)*/);
		return chunk1;
	}
}
void setChunk(int map, int x, int y, uint chunk)
{
	with(maps.maps[map])
	{
		if(data1 is null || data2 is null) throw new Exception("Can't set map data - map not loaded");
		int  sx = scrambleCoord( x),  sy = scrambleCoord( y);
		int ssx = scrambleCoord(sx), ssy = scrambleCoord(sy);
		data1[ sy*width +  sx] = chunk;
		data2[ssy*width + ssx] = scrambleChunk(x, y, chunk);
	}
}

// ****************************************************

struct ChunkDatabase
{
	ChunkTileSet *[2] Tiles;
	ChunkThumbSet*[2] Thumbs;
}

mixin(mixObjPtr("ChunkDatabase", "chunkDatabase"));

struct MapChunkTiles
{
	uint[16][16] data;
	uint f400;
	static assert(this.sizeof == 1028);
}

struct MapChunkThumb
{
	ubyte[16][16] data;
	uint f100;
	static assert(this.sizeof == 260);
}

alias MapChunkThumb[0x800] ChunkThumbSet;
static assert(ChunkThumbSet.sizeof == 0x82000);
alias MapChunkTiles[0x800] ChunkTileSet;
static assert(ChunkTileSet.sizeof == 0x202000);

MapChunkTiles* getChunkTiles(uint chunk)
{
	if((chunk>=0x4000) || ((chunk&0x1FFF)>=0x800)) return null;
	return &(*chunkDatabase.Tiles [chunk>>13])[chunk&0x7FF];
}

MapChunkThumb* getChunkThumb(uint chunk)
{
	if((chunk>=0x4000) || ((chunk&0x1FFF)>=0x800)) return null;
	return &(*chunkDatabase.Thumbs[chunk>>13])[chunk&0x7FF];
}

uint getTile(uint map, uint x, uint y)
{
	uint chunk = getChunk(map, x/16, y/16);
	if(chunk==0) return 0;
	MapChunkTiles* tiles = getChunkTiles(chunk);
	if(tiles is null) return 1;
	return tiles.data[y%16][x%16];
}

ubyte getChunkPixel(uint map, uint x, uint y)
{
	uint chunk = getChunk(map, x/16, y/16);
	if(chunk==0) return 0;
	MapChunkThumb* thumb = getChunkThumb(chunk);
	if(thumb is null) return 0;
	return thumb.data[y%16][x%16];
}

// ****************************************************

enum Sprites : uint
{
	Water = 2,
	LargeTree = 16,
	FertileLand = 44,
	IronMountain1 = 12,
	IronMountain2 = 13,
}

// ****************************************************

struct Tile
{
	char[16] Name;
	uint f10, f14, f18, f1C;
	uint Flags;
	uint f24, f28, f2C;
	ubyte[16][16] Pixels;
	static assert(this.sizeof == 0x130);
}

const TILES = 0x1800;

struct TileManager
{
	Tile[TILES]* Tiles;
	uint f4;
	uint RowWidth;
	uint ResX;
	uint ResY;
	uint BoundX1;
	uint BoundY1;
	uint BoundX2;
	uint BoundY2;
	ubyte* VideoMemory;
}

mixin(mixObjPtr("TileManager", "tileManager"));

ubyte getPixel(uint x, uint y)
{
	//if(x<0 || x>=640 || y<0 || y>=480) return 0;
	with(*tileManager)
		return VideoMemory[y*RowWidth+x];
}

void putPixel(uint x, uint y, ubyte colour)
{
	//if(x<0 || x>=640 || y<0 || y>=480) return;
	with(*tileManager)
		VideoMemory[y*RowWidth+x] = colour;
}

void replacePixel(uint x, uint y, ubyte from, ubyte to)
{
	//if(x<0 || x>=640 || y<0 || y>=480) return;
	ubyte* p;
	with(*tileManager)
		p = &(VideoMemory[y*RowWidth+x]);
	if(*p==from)
		*p=to;
}

void vline(uint x, uint y1, uint y2, ubyte colour)
{
	with(*tileManager)
		for(uint y=y1;y<=y2;y++)
			VideoMemory[y*RowWidth+x] = colour;
}

void hline(uint x1, uint x2, uint y, ubyte colour)
{
	with(*tileManager)
		for(uint x=x1;x<=x2;x++)
			VideoMemory[y*RowWidth+x] = colour;
}

void rectangle(uint x1, uint y1, uint x2, uint y2, ubyte colour)
{
	vline(x1, y1, y2, colour);
	vline(x2, y1, y2, colour);
	hline(x1, x2, y1, colour);
	hline(x1, x2, y2, colour);
}

void fillRect(uint x1, uint y1, uint x2, uint y2, ubyte colour)
{
	with(*tileManager)
		for(uint x=x1;x<=x2;x++)
			for(uint y=y1;y<=y2;y++)
				VideoMemory[y*RowWidth+x] = colour;
}

// ****************************************************

struct ObjRef
{
	uint ID;

	//mixin(mixMethod("ObjRef", "FindByID",  [], "GlobalObject*"));
	
	/+mixin(mixMethod("ObjRef", "TestFlag",  ["ObjectFlags"], "bool"));
	mixin(mixMethod("ObjRef", "SetFlag",   ["ObjectFlags"]));
	mixin(mixMethod("ObjRef", "ClearFlag", ["ObjectFlags"]));

	mixin(mixMethod("ObjRef", "GetObjType", [], "ObjectType"));+/
}

// ****************************************************

struct SecureDataManager
{
	mixin(mixMethod("SecureDataManager", "WriteValue", ["uint", "uint"]));           // index, value
	mixin(mixMethod("SecureDataManager", "ReadValue", ["uint"], "uint"));            // index
}

mixin(mixObjPtr("SecureDataManager", "secureDataManager"));

int myX()
{
	return secureDataManager.ReadValue(camera.XSecureIndex);
}

int myY()
{
	return secureDataManager.ReadValue(camera.YSecureIndex);
}

int myMap()
{
	return secureDataManager.ReadValue(camera.MapNumberSecureIndex);
}

// ****************************************************

struct Buffers
{
	uint InPosition;
	uint InSize;
	ubyte[8192] InData;
	uint OutPosition;
	ubyte[8192] OutData;
	uint OutSize;
}

enum WalkDirection : uint
{
	Nowhere, North, NorthEast, East, SouthEast, South, SouthWest, West, NorthWest
}

struct ClientServices
{
	uint f0, f4, f8;
	Buffers buffers;

	mixin(mixMethod("ClientServices", "SendBeginDrag", ["uint", "bool"]));           // ID, DragAll
	mixin(mixMethod("ClientServices", "SendDropOnItemAt", ["uint", "int", "int"]));  // ID, x, y
	mixin(mixMethod("ClientServices", "SendDropAt", ["int", "int"]));                // x, y (global coords)
	mixin(mixMethod("ClientServices", "SendSelectItem", ["int"]));                   // ID
	mixin(mixMethod("ClientServices", "SendWalk", ["WalkDirection"]));
	mixin(mixMethod("ClientServices", "SendSelectTile", ["int", "int"]));            // x, y (global coords)
	mixin(mixMethod("ClientServices", "SendAmount", ["int"]));                       // amount
	mixin(mixMethod("ClientServices", "SendTradeSkillBoxItem", ["int"]));            // ObjectType
}

mixin(mixObjPtr("ClientServices", "clientServices"));

// **********************************************************

mixin(mixObjPtr("void", "mainWindow", "MainWindow"));

// **********************************************************

struct TextBox
{
	Gump gump;
	uint Numeric;
	uint f4C;
	char* String;
	uint MaxLength;
	uint f58, f5C, f60, f64;
	static assert(this.sizeof == 0x68);

	void append(char[] str)
	{
		int len=0;
		while(String[len]) len++;
		if(len + str.length + 1 > MaxLength)
			str.length = MaxLength - len - 1;
		str ~= \0;
		foreach(i,c;str)
			String[len+i] = c;
	}

	char[] text()
	{
		return readStringZ(String);
	}
}

struct GUIEventDispatcher
{
	uint[0x180] f0;
	uint f600, f604, f608, f60C, f610;
	Gump* FocusedGump;
	static assert(this.sizeof == 0x618);
	// ...
}

mixin(mixObjPtr("GUIEventDispatcher", "guiEventDispatcher"));
