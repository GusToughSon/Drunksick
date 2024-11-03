module programs.smith;

import dranscript;

class Smith : Program
{
	override void execute()
	{
		ObjectType ignot;
		while(pickOwnedItem(ignots, ignot))
		{
			useInvItem(ObjectType.BlacksmithHammer);
			waitForMessage(MessageType.SmithPrompt);
			waitForUseCursor();
			
			tradeSkillItem = ObjectType.BattleAxe;
			selectInvItem(ignot);
			waitForMessage(MessageType.SmithStart);
			waitForMessage([MessageType.SmithSuccess, MessageType.SmithFailure]);
		}
	}
}

static this()
{
	programs ~= new Smith;
}
