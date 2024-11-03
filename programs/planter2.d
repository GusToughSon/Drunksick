module programs.planter2;

import programs.planter;
import programs.pfhelper;
import dranscript;
import tango.math.Math;

class Planter2 : Planter
{
    int startX, startY;

    bool harvest()
    {
    	return false;
    }
    
    int validator(int sx, int sy)
    {
    	int gx=sx+myX-SCREEN_SIZE/2, gy=sy+myY-SCREEN_SIZE/2;
    	if(getTile(myMap, gx, gy)==Sprites.FertileLand &&
    		objMap[sx][sy] is null &&
    		mobMap[sx][sy] is null)
    		return 100;
    	else
    		return 0;
    }

	void work()
	{
		if(harvest())
			return;
		
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

		if(harvest())
			return;
			
		ProximityScreenFinder psf = new ProximityScreenFinder(&validator, startX, startY, 5);
		call(psf);
	}
	
	override void execute()
	{
		startX = myX;
		startY = myY;
		while(!done)
			work();
	}
}

static this()
{
	dranscript.programs ~= new Planter2;
}
