module programs.plantharvest;

import programs.planter2;
import programs.pfhelper;
import dranscript;
import tango.math.Math;

class PlanterHarvester : Planter2
{
	override char[] name()
	{
		return "Plant+Harvest";
	}

	int harvestValidator(int sx, int sy)
	{
		if(mobMap[sx][sy] !is null)
			return 0;
		auto obj = objMap[sx][sy];
		if(obj is null)
			return 0;
		if(!(obj.ID in globalObjects))
			return 0;
		auto glb = globalObjects[obj.ID];
		if(!isInArray(harvestable~harvestableCrop, glb.objType))
			return 0;
		return 100;
	}

	bool gotHarvest()
	{
		if(playerData.Weight+50 > playerData.MaxWeight)
			return false;
		for(int y=0;y<SCREEN_SIZE;y++)
			for(int x=0;x<SCREEN_SIZE;x++)
				if(harvestValidator(x, y)>0)
					return true;
		//Stdout("[Harvester] No harvest").newline;
		return false;
	}
	
	override bool harvest()
	{
		Stdout("[Harvester] Checking for harvest").newline;
		if(!gotHarvest())
			return false;
		Stdout("[Harvester] Got harvest!").newline;
		ProximityScreenFinder psf = new ProximityScreenFinder(&harvestValidator, myX, myY);
		call(psf);
		for(int dx=-1;dx<=1;dx++)
			for(int dy=-1;dy<=1;dy++)
			{
				auto obj = objMap[SCREEN_SIZE/2+dx][SCREEN_SIZE/2+dy];
				if(obj && obj.ID in globalObjects)
				{
					ObjectType objType = globalObjects[obj.ID].objType;
					if(isInArray(harvestable~harvestableCrop, objType))
					{
						if(isInArray(harvestable, objType))
							playerData.UseObject(obj.ID);
						else
						{
							useInvItem(ObjectType.FarmScythe);
							waitForUseCursor();
							selectObject(obj.ID);
							waitForMessage(MessageType.HarvestCropStart);
							waitForMessage([MessageType.HarvestCropSuccess, MessageType.HarvestCropFailure]);
						}
						do 
						{
							wait();
							obj = objMap[SCREEN_SIZE/2+dx][SCREEN_SIZE/2+dy];
						} while(obj && obj.ID in globalObjects && isInArray(harvestable~harvestableCrop, globalObjects[obj.ID].objType));
					}
				}
			}
		return true;
	}
}

static this()
{
	dranscript.programs ~= new PlanterHarvester;
}
