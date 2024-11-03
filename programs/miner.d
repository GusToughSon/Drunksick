module programs.miner;

import programs.planter;
import programs.pfhelper;
import dranscript;
import tango.math.Math;

class Miner : Program
{
    struct Coord { int x, y; }
    Coord[] depletedRocks;

    bool isDepleted(int x, int y)
    {
    	foreach(coord;depletedRocks)
    		if(coord.x==x && coord.y==y)
    			return true;
    	return false;
    }
    
    int validator(int sx, int sy)
    {
    	int gx=sx+myX-SCREEN_SIZE/2, gy=sy+myY-SCREEN_SIZE/2;
    	auto tile = getTile(myMap, gx, gy);
    	if((tile==Sprites.IronMountain1 || tile==Sprites.IronMountain2) &&
    		objMap[sx][sy] is null &&
    		mobMap[sx][sy] is null &&
    		!isDepleted(gx, gy))
    		return 100;
    	else
    		return 0;
    }

    bool process(int dx, int dy)
    {
		auto tile = getTile(myMap, myX+dx, myY+dy);
		if(!((tile==Sprites.IronMountain1 || tile==Sprites.IronMountain2))
			|| objMap[SCREEN_SIZE/2+dx][SCREEN_SIZE/2+dy]!is null 
			|| mobMap[SCREEN_SIZE/2+dx][SCREEN_SIZE/2+dy]!is null 
			|| isDepleted(myX+dx, myY+dy))
			return false;
		useInvItem([ObjectType.PickAxe, ObjectType.MagicPickAxe]);
		if(waitForMessage([MessageType.MinePrompt, MessageType.ReUseFailServer])==MessageType.ReUseFailServer)
			return true;
		waitForUseCursor();
		selectTile(myX+dx, myY+dy);
		if(waitForMessage([MessageType.MineStart, MessageType.MineDepleted])==MessageType.MineDepleted)
			depletedRocks ~= Coord(myX+dx, myY+dy);
		else
			waitForMessage([MessageType.MineSuccess, MessageType.GatherResourceFailure]);
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
					if(done)
						return;
				}
		} while(worked);

		ProximityScreenFinder psf = new ProximityScreenFinder(&validator, myX, myY);
		try
			call(psf);
		catch(Object o)  // no targets?
			depletedRocks = null;
	}
	
	void execute()
	{
		while(!done)
			work();
	}
}

static this()
{
	dranscript.programs ~= new Miner;
}
