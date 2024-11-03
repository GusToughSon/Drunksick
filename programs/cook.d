module programs.cook;

import dranscript;

class Cook : Program
{
	override void execute()
	{
		ObjectType cookable;
		while(pickOwnedItem(cookables, cookable))
		{
			useInvItem(cookable);
			waitForUseCursor();
			selectNearbyObject([ObjectType.Oven, ObjectType.Oven2]);
			waitForMessage(MessageType.CookStart);
			waitForMessage([MessageType.CookSuccess, MessageType.CookFailure]);
		}
	}
}

static this()
{
	programs ~= new Cook;
}
