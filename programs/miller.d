module programs.miller;

import dranscript;

class Miller : Program
{
    this()
    {
		messageFilter ~= [MessageType.SkillLevelUp, MessageType.ReUseReady, MessageType.OutOfFlour];
    }
	
	override void execute()
	{
		while(haveItem(ObjectType.Log) && haveItem(ObjectType.Saw))
		{
			useInvItem(ObjectType.Saw);
			waitForMessage(MessageType.SawLumberPrompt);
			waitForUseCursor();
			selectInvItem(ObjectType.Log);
			waitForMessage(MessageType.SawLumberStart);
			waitForMessage([MessageType.SawLumberSuccess, MessageType.SawLumberFailure]);
		}
		Stdout("Miller: no ingridients/prerequisites.").newline;
	}
}

static this()
{
	programs ~= new Miller;
}
