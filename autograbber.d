module autograbber;

import commondata;
import timing;
import tango.io.File;
import pathfinder;

bool[OBJECT_TYPES] grabThis;
private File f;

static this()
{
	// grab everything by default
	grabThis[] = true;
	f = new File("data/User_Data/grablist.bin");
	if(f.path.exists)
		grabThis[] = cast(bool[])f.read();
}

void saveGrabList()
{
	f.write(grabThis);
}

bool[SCREEN_SIZE][SCREEN_SIZE] hasGoodItems;

int lastX, lastY;

bool autoGrab(bool hax)
{
	CameraObject*[] cameraObjects;
	foreach(ref obj;&camera.objIterator)
		cameraObjects ~= &obj;

	if(hax)
	{
		foreach_reverse(obj;cameraObjects)
			with(*obj)
				if(distance<=1)       // in grab reach
				{
					auto glb = globalObjects[ID];
					if(objectData[glb.objType].flags&ObjectDataFlags.Item)
						if(grabThis[glb.objType])
						{
							Stdout.format("AutoGrab: Hax-Grabbing {} at {}x{}", objectData[glb.objType].nameStr, X, Y).newline;
							clientServices.SendBeginDrag(ID, true);
							clientServices.SendDropOnItemAt(playerData.BackpackID, -1, -1);
							//glb.flags &= ~ObjectFlags.Visible;
							//return true;
						}
				}
	}
	else
	{
		bool haveItems;
	
		for(int x=0;x<SCREEN_SIZE;x++)
			for(int y=0;y<SCREEN_SIZE;y++)						
				hasGoodItems[x][y] = false;

		foreach(obj;cameraObjects)
			with(*obj)
				if(objectData[globalObjects[ID].objType].flags&ObjectDataFlags.Item && grabThis[globalObjects[ID].objType] && distance==1)
					hasGoodItems[X][Y] = haveItems = true;

		if(!haveItems) return false;
	
		if(lastX!=myX || lastY!=myY)
		{
			Stdout("AutoGrab: pre-grab delay").newline;
			wait(300 + rand(300));
			lastX = myX;
			lastY = myY;
			return true;
		}

		foreach_reverse(obj;cameraObjects)
			with(*obj)
				if(mobMap[X][Y] is null)  // no monster on top of it
					if(distance==1)       // in grab reach
					{
						auto glb = globalObjects[ID];
						if(objectData[glb.objType].flags&ObjectDataFlags.Item)
							if(grabThis[glb.objType])
							{
								Stdout.format("AutoGrab: Grabbing {} at {}x{}", objectData[glb.objType].nameStr, X, Y).newline;
								clientServices.SendBeginDrag(ID, true);
								clientServices.SendDropOnItemAt(playerData.BackpackID, -1, -1);
								glb.flags &= ~ObjectFlags.Visible;
								wait(200 + rand(200));
								return true;
							}
							else
							if(hasGoodItems[X][Y])
							{
								for(int sx=SCREEN_SIZE/2-1;sx<=SCREEN_SIZE/2+1;sx++)
									for(int sy=SCREEN_SIZE/2-1;sy<=SCREEN_SIZE/2+1;sy++)
										if(!hasGoodItems[sx][sy] && mobMap[sx][sy] is null && !isSolid(myMap, myX-SCREEN_SIZE/2+sx, myY-SCREEN_SIZE/2+sy))
										{
											Stdout.format("AutoGrab: Moving away {} from {}x{} to unused tile {}x{}", objectData[glb.objType].nameStr, X, Y, sx, sy).newline;
											//dragMap(x, y, sx, sy);
											clientServices.SendBeginDrag(ID, true);
											clientServices.SendDropAt(myX-SCREEN_SIZE/2+sx, myY-SCREEN_SIZE/2+sy);
											glb.flags &= ~ObjectFlags.Visible;
											wait(200 + rand(200));
											return true;
										}
								for(int sx=SCREEN_SIZE/2-1;sx<=SCREEN_SIZE/2+1;sx++)
									for(int sy=SCREEN_SIZE/2-1;sy<=SCREEN_SIZE/2+1;sy++)
										if(mobMap[sx][sy] is null && !(X==sx && Y==sy) && !isSolid(myMap, myX-SCREEN_SIZE/2+sx, myY-SCREEN_SIZE/2+sy))
										{
											Stdout.format("AutoGrab: Moving away {} from {}x{} to temporary tile {}x{}", objectData[glb.objType].nameStr, X, Y, sx, sy).newline;
											//dragMap(x, y, sx, sy);
											clientServices.SendBeginDrag(ID, true);
											clientServices.SendDropAt(myX-SCREEN_SIZE/2+sx, myY-SCREEN_SIZE/2+sy);
											glb.flags &= ~ObjectFlags.Visible;
											wait(200 + rand(200));
											return true;
										}
								//Stdout.format("AutoGrab: Can't get to goodies at {}x{} due to some {} which can't be moved").newline;
							}
					}
	}
	return false;
}
