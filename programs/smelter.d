module programs.smelter;

import dranscript;

class Smelter : Program
{
    this()
    {
		messageFilter ~= [MessageType.SmeltForgeCooling];
    }
	
	override void execute()
	{
		if(!isObjectNearby([ObjectType.Forge, ObjectType.FlamingForge]) || 
		   !isObjectNearby([ObjectType.Bellow, ObjectType.ActiveBellow]))
			throw new Exception("Must be near a forge and bellow");

		ObjectType ore;
		while(pickOwnedItem(ores, ore))
		{
			if(!isObjectNearby(ObjectType.FlamingForge))
			{
				if(isObjectNearby(ObjectType.Bellow))
					useNearbyObject(ObjectType.Bellow);
				while(!isObjectNearby(ObjectType.FlamingForge))
					wait();
			}
			useInvItem(ore);
			waitForMessage(MessageType.SmeltPrompt);
			waitForUseCursor();
			selectNearbyObject([ObjectType.Forge, ObjectType.FlamingForge]);
			if(waitForMessage([MessageType.SmeltStart, MessageType.SmeltForgeCooled])==MessageType.SmeltStart)
				waitForMessage([MessageType.SmeltSuccess, MessageType.SmeltFailure]);
		}
		Stdout("Smelter: no ingridients/prerequisites.").newline;
	}
}

static this()
{
	programs ~= new Smelter;
}
