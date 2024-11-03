module programs.carpenter;

import dranscript;

class Carpenter : Program
{
	override void execute()
	{
		while(haveItem(ObjectType.Plank))
		{
			useInvItem(ObjectType.CarpentersTools);
			waitForMessage(MessageType.CarpenterPrompt);
			waitForUseCursor();
			
			tradeSkillItem = ObjectType.Club;
			selectInvItem(ObjectType.Plank);
			waitForMessage(MessageType.CarpenterStart);
			waitForMessage([MessageType.CarpenterSuccess, MessageType.CarpenterFailure]);
		}
	}
}

static this()
{
	programs ~= new Carpenter;
}
