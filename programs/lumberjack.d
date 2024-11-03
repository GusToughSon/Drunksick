module programs.lumberjack;

import programs.planter;
import programs.pfhelper;
import dranscript;
import tango.math.Math;

class LumberJack : Program
{
    struct Coord { int x, y; }
    Coord[] depletedTrees;

    bool isDepleted(int x, int y)
    {
    	foreach(coord;depletedTrees)
    		if(coord.x==x && coord.y==y)
    			return true;
    	return false;
    }
    
    int validator(int sx, int sy)
    {
    	int gx=sx+myX-SCREEN_SIZE/2, gy=sy+myY-SCREEN_SIZE/2;
    	if(getTile(myMap, gx, gy)==Sprites.LargeTree &&
    		objMap[sx][sy] is null &&
    		mobMap[sx][sy] is null &&
    		!isDepleted(gx, gy))
    		return 100;
    	else
    		return 0;
    }

    bool process(int dx, int dy)
    {
		if(getTile(myMap, myX+dx, myY+dy)!=Sprites.LargeTree 
			|| objMap[SCREEN_SIZE/2+dx][SCREEN_SIZE/2+dy]!is null 
			|| mobMap[SCREEN_SIZE/2+dx][SCREEN_SIZE/2+dy]!is null 
			|| isDepleted(myX+dx, myY+dy))
			return false;
		useInvItem([ObjectType.LumberjackAxe, ObjectType.MagicLumberjackAxe]);
		if(waitForMessage([MessageType.ChopLumberPrompt, MessageType.ReUseFailServer])==MessageType.ReUseFailServer)
			return true;
		waitForUseCursor();
		selectTile(myX+dx, myY+dy);
		if(waitForMessage([MessageType.ChopLumberStart, MessageType.ChopLumberDepleted])==MessageType.ChopLumberDepleted)
			depletedTrees ~= Coord(myX+dx, myY+dy);
		else
			waitForMessage([MessageType.ChopLumberSuccess, MessageType.GatherResourceFailure]);
		return true;
    }

	void work()
	{
		if(playerData.Weight >= playerData.MaxWeight*6/5)
		{
			done = true;
			return playSound("Sounds/ContainerFull.wav");
		}

		bool worked;
		do
		{
			worked = false;
			for(int dx=-1;dx<=1;dx++)
				for(int dy=-1;dy<=1;dy++)
				{
					worked |= process(dx, dy);
					if(done || playerData.Weight >= playerData.MaxWeight*6/5)
						return;
				}
		} while(worked);

		ProximityScreenFinder psf = new ProximityScreenFinder(&validator, myX, myY);
		try
			call(psf);
		catch(Object o)  // no targets?
			depletedTrees = null;
	}
	
	void execute()
	{
		while(!done)
			work();
	}
}

static this()
{
	dranscript.programs ~= new LumberJack;
}
