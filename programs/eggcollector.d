module programs.eggcollector;

import dranscript;

class EggCollector : Program
{
	override void execute()
	{
		while(true)
		{
			try
				useNearbyNPC(ObjectType.Chicken);
			catch
			{
				wait();
				continue;
			}
			try
				waitForMessage(MessageType.EggSearchStart, 30);
			catch
			{
				Stdout("[EggCollector] Escaping chicken").newline;
				continue;
			}
			waitForMessage([MessageType.EggSearchSuccess, MessageType.EggSearchFailure]);
		}
	}
}

static this()
{
	programs ~= new EggCollector;
}
