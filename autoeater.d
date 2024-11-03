module autoeater;

import dranscript;
import timing;

bool waitingForUseCursorFood;

bool autoEater()
{
	if(playerData.Sta<15)
	{
		ObjectType edible;
		if(mouse.useCursor && waitingForUseCursorFood)
		{
			waitingForUseCursorFood = false;
			Stdout("AutoEater: clicking self").newline;
			selectSelf();
			wait(1500, false);
			return true;
		}
		else
		if(!waitingForUseCursor && !mouse.useCursor && pickOwnedItem(edibles, edible))
		{
			Stdout("AutoEater: using " ~ objectData[edible].nameStr).newline;
			useInvItem(edible);
			wait(1500, false);
			waitingForUseCursorFood = true;
			return true;
		}
	}
	return false;
}
