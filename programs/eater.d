module programs.eater;

import dranscript;

class Eater : Program
{
	this()
	{
		deleteFromArray(messageFilter, MessageType.EatFull);
		deleteFromArray(messageFilter, MessageType.EatDone);
	}

	override void execute()
	{
		ObjectType edible;
		while(pickOwnedItem(edibles, edible))
		{
			useInvItem(edible);
			waitForUseCursor();
			selectSelf();
			if(waitForMessage([MessageType.EatFull, MessageType.EatDone])==MessageType.EatFull)
				break;
		}
	}
}

static this()
{
	programs ~= new Eater;
}
