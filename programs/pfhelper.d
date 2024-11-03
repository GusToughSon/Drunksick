module programs.pfhelper;
// PathFinder helper stuff

import dranscript;
import pathfinder;
import tango.math.Math;

class PersistentPF : Program
{
	override void execute()
	{
		Object result;
		while((result=call(pathFinder)) !is null)
		{
			Stdout("[PersistentPF] PathFinder error (")(result.toString)("), retrying").newline;
			wait();
		}
	}
}

class ScreenFinder : Program
{
	/// return -1 on unneeded tile, otherwise return penalty
	alias int delegate(int sx, int sy) TileValidator;

	TileValidator validator;
	
	this(TileValidator _validator)
	{
		validator = _validator;
	}

	override void execute()
	{
		PathFinder.reset();
		bool haveTargets = false;
		for(int y=0;y<SCREEN_SIZE;y++)
			for(int x=0;x<SCREEN_SIZE;x++)
			{
				int gx=x+myX-SCREEN_SIZE/2, gy=y+myY-SCREEN_SIZE/2;
				if(isSolid(myMap, gx, gy))
					continue;
				int result = validator(x, y);
				if(result>=0)
				{
					PathFinder.addFinish(myMap, x+myX-SCREEN_SIZE/2, y+myY-SCREEN_SIZE/2, result);
					haveTargets = true;
				}
			}
		
		if(!haveTargets)
			throw new Exception("No targets set");
		PersistentPF ppf = new PersistentPF;
		call(ppf);
	}
}

class ProximityScreenFinder : Program
{
	/// return the "score" for this tile (should be <=100) - 0 means tile is worthless
	alias int delegate(int sx, int sy) TileValidator;

	TileValidator validator;
	int originX, originY, distanceFactor;
	
	this(TileValidator _validator, int ox, int oy, int _distanceFactor=0)
	{
		validator = _validator;
		originX = ox;
		originY = oy;
		distanceFactor = _distanceFactor;
	}

	private int myValidator(int sx, int sy)
	{
		int gx=sx+myX-SCREEN_SIZE/2, gy=sy+myY-SCREEN_SIZE/2;
		int n=0;
		for(int dy=-1;dy<=1;dy++)
			if(sy+dy>=0 && sy+dy<SCREEN_SIZE)
				for(int dx=-1;dx<=1;dx++)
					if(sx+dx>=0 && sx+dx<SCREEN_SIZE)
						if(dx!=0 || dy!=0)
							n+=validator(sx+dx, sy+dy);
		assert(n>=0 && n<=800, "score out of range");
		if(distanceFactor)
			n-=cast(int)(distanceFactor*sqrt(cast(float)(gx-originX)*(gx-originX)+(gy-originY)*(gy-originY)));
		if(n<=0)
			return -1;
		else
			return 800-n;
	}

	override void execute()
	{
		ScreenFinder sf = new ScreenFinder(&myValidator);
		call(sf);
	}
}

