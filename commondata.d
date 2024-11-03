module commondata;

public import dransik;
public import tango.io.Stdout : Stdout;

GlobalObject*[int] globalObjects;
CameraObject*[SCREEN_SIZE][SCREEN_SIZE] mobMap, objMap;
Container* backPack;

// **************************************************

void getGlobalObjects()
{
	globalObjects = null;

	foreach(ref obj;*objectList)
		with(obj)
			if(ID)
			{
				assert(!(ID in globalObjects), "ID already in list");
				globalObjects[ID] = &obj;
			}
}

void mapMobs()
{
	for(int x=0;x<SCREEN_SIZE;x++)
		for(int y=0;y<SCREEN_SIZE;y++)						
			mobMap[x][y] = null;

	foreach(ref mob;&camera.mobIterator)
		with(mob)
			mobMap[X][Y] = &mob;
}

void mapObjs()
{
	for(int x=0;x<SCREEN_SIZE;x++)
		for(int y=0;y<SCREEN_SIZE;y++)						
			objMap[x][y] = null;

	foreach(ref obj;&camera.objIterator)
		with(obj)
			objMap[X][Y] = &obj;
}

void findBackPack()
{
	backPack = null;
	foreach(ref container;&playerData.containerIterator)
		if(container.ID == playerData.BackpackID)
		{
			backPack = &container;
			break;
		}
}

// **************************************************

void readGameData()
{
	if(playerData is null || camera is null) throw new Exception("Game not initialized");
	getGlobalObjects();
	mapMobs();
	mapObjs();
	findBackPack();
}

// **************************************************
