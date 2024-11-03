module programs.planter;

import dranscript;

class Planter : Program
{
    this()
    {
		messageFilter ~= [MessageType.DigShovelBroken];
    }
	
	bool process(int dx, int dy)
	{
		int sx = SCREEN_SIZE/2 + dx;
		int sy = SCREEN_SIZE/2 + dy;
		if(objMap[sx][sy] is null)  // dig
		{
			if(getTile(myMap, myX+dx, myY+dy)!=Sprites.FertileLand || mobMap[sx][sy]!is null)
				return false;
			debug Stdout("Planter: Digging hole").newline;
			useInvItem(ObjectType.Shovel);
			waitForUseCursor();
			waitForMessage(MessageType.DigPrompt);
			selectTile(myX+dx, myY+dy);
			waitForMessages([MessageType.DigStart, MessageType.DigDone]);
			debug Stdout("Planter: Dig: Waiting for result").newline;
			while(objMap[sx][sy] is null) 
				wait();
			return true;
		}
		else
		if(globalObjects[objMap[sx][sy].ID].objType == ObjectType.FreshSoil)  // plant
		{
		    debug Stdout("Planter: Planting seed").newline;
			foreach(seed;seeds)
				if(haveItem(seed))
				{
					useInvItem(seed);
					waitForUseCursor();
					selectObject(objMap[sx][sy].ID);
					waitForMessages([MessageType.PlantStart, MessageType.PlantSuccess, MessageType.PlantFailure], 2);
					debug Stdout("Planter: Plant: Waiting for result").newline;
					while(objMap[sx][sy] !is null && globalObjects[objMap[sx][sy].ID].objType == ObjectType.FreshSoil)
						wait();
					wait(); // safety
					return true;
				}
			// out of seeds
			Stdout("Planter: Out of seeds").newline;
			done = true;
			return true;
		}
		else
			return false;
	}
	
	override void execute()
	{
		while(!done)
		{
			if(process(-1, 0)) continue; // left
			if(process(+1, 0)) continue; // right
			walkSouth();
		}
	}
}

static this()
{
	programs ~= new Planter;
}
