module programs.fisher;

import programs.pfhelper;
import dranscript;
import tango.math.Math;

class Fisher : Program
{
    int startX, startY;

    struct Coord { int x, y; }
    Coord[] depletedSpots;

    bool isDepleted(int x, int y)
    {
    	foreach(coord;depletedSpots)
    		if(coord.x==x && coord.y==y)
    			return true;
    	return false;
    }
    
    int validator(int sx, int sy)
    {
    	int gx=sx+myX-SCREEN_SIZE/2, gy=sy+myY-SCREEN_SIZE/2;
    	if(getTile(myMap, gx, gy)==Sprites.Water &&
    		objMap[sx][sy] is null &&
    		mobMap[sx][sy] is null &&
    		!isDepleted(gx, gy))
    		return 100;
    	else
    		return 0;
    }

    bool process(int dx, int dy)
    {
		if(getTile(myMap, myX+dx, myY+dy)!=Sprites.Water
			|| objMap[SCREEN_SIZE/2+dx][SCREEN_SIZE/2+dy]!is null 
			|| mobMap[SCREEN_SIZE/2+dx][SCREEN_SIZE/2+dy]!is null 
			|| isDepleted(myX+dx, myY+dy))
			return false;
		useInvItem(ObjectType.FishingPole);
		if(waitForMessage([MessageType.FishPrompt, MessageType.ReUseFailServer])==MessageType.ReUseFailServer)
			return true;
		waitForUseCursor();
		selectTile(myX+dx, myY+dy);
		if(waitForMessage([MessageType.FishStart, MessageType.FishDepleted])==MessageType.FishDepleted)
			depletedSpots ~= Coord(myX+dx, myY+dy);
		else
			waitForMessage([MessageType.FishSuccess, MessageType.FishFailure, MessageType.FishLineBroke]);
		return true;
    }

	void work()
	{
		if(!haveItem(ObjectType.FishingPole) && haveItem(ObjectType.Pole) && haveItem(ObjectType.String))  // pole broke, make a new one
		{
			useInvItem(ObjectType.String);
			waitForUseCursor();
			selectInvItem(ObjectType.Pole);
			waitForMessage(MessageType.Working);
			waitForMessage(MessageType.MakeFishingPoleDone);
			while(!haveItem(ObjectType.FishingPole))
				wait();
			return true;
		}
		
		if(playerData.Weight >= playerData.MaxWeight*6/5)
		{
			done = true;
			return playSound("Sounds/ContainerFull.wav");
		}

		for(int dx=-1;dx<=1;dx++)
			for(int dy=-1;dy<=1;dy++)
				if(process(dx, dy))
					return;

		ProximityScreenFinder psf = new ProximityScreenFinder(&validator, startX, startY, 5);
		try
			call(psf);
		catch(Object o)  // no targets?
			depletedSpots = null;
	}
	
	void execute()
	{
		startX = myX;
		startY = myY;
		while(!done)
			work();
	}
}

static this()
{
	dranscript.programs ~= new Fisher;
}
