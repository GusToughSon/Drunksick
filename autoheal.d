module autoheal;

import dranscript;
import timing;
import messagelog;

Time lastUse;
bool poisoned, diseased;

bool autoHeal()
{
	float health = cast(float)(playerData.Health)/cast(float)(playerData.MaxHealth);
	float timeElapsed = secondsSince(lastUse);

	if (diseased && timeElapsed>1.4 && haveItem(ObjectType.GreaterCurePotion))
	{
		Stdout("Using Greater Cure Potion (disease)").newline;
		useInvItem(ObjectType.GreaterCurePotion);
		lastUse = Clock.now; return true;
	}
	
	if (poisoned && timeElapsed>1.4 && haveItem(ObjectType.CurePotion))
	{
		Stdout("Using Greater Potion (poison)").newline;
		useInvItem(ObjectType.CurePotion);
		lastUse = Clock.now; return true;
	}
	
	if (poisoned && timeElapsed>1.4 && haveItem(ObjectType.GreaterCurePotion))
	{
		Stdout("Using Greater Cure Potion (poison)").newline;
		useInvItem(ObjectType.GreaterCurePotion);
		lastUse = Clock.now; return true;
	}
	
	if (health<0.7 && timeElapsed>1.4)
	{
		if (playerData.MaxHealth - playerData.Health > 129 && haveItem(ObjectType.GreaterHealingPotion) && 
		    (health<0.4 || !haveItem(ObjectType.HealingPotion)))
		{
			Stdout.format("Using Greater Healing Potion ({}/{})", playerData.Health, playerData.MaxHealth).newline;
			useInvItem(ObjectType.GreaterHealingPotion);
			lastUse = Clock.now; return true;
		}	
		else 
		if (playerData.MaxHealth - playerData.Health >  29 && haveItem(ObjectType.HealingPotion))
		{
			Stdout.format("Using Healing Potion ({}/{})", playerData.Health, playerData.MaxHealth).newline;
			useInvItem(ObjectType.HealingPotion);
			lastUse = Clock.now; return true;
		}
	}
	return false;
}

private class MessageHandler
{
	void messageHandler(MessageType msg)
	{
		switch(msg)
		{
			case MessageType.Poisoned:
				poisoned = true;
				return;
			case MessageType.Diseased:
				diseased = true;
				return;
			case MessageType.CurePtnFailure:
				poisoned = false;
				return;
			case MessageType.GreaterCurePtnFailure:
				poisoned = diseased = false;
				return;
			case MessageType.PoisonCured:
				poisoned = false;
				return;
			case MessageType.DiseaseCured:
				diseased = false;
				return;
			default:
				return;
		}
	}
}

private MessageHandler myMessageHandler;

static this()
{
	myMessageHandler = new MessageHandler;
	messageHandlers ~= &myMessageHandler.messageHandler;
}
