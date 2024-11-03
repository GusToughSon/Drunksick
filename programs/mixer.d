module programs.mixer;

import dranscript;

class Mixer : Program
{
    this()
    {
		messageFilter ~= [MessageType.SkillLevelUp, MessageType.ReUseReady, MessageType.OutOfFlour];
    }
	
	override void execute()
	{
		while(haveItem(ObjectType.BucketOfWater) && haveItem(ObjectType.FlourBag) && haveItem(ObjectType.EmptyMeasuringCup) && haveItem(ObjectType.MixingBowl) && haveItem(ObjectType.MixingSpoon))
		{
			useInvItem(ObjectType.BucketOfWater);
			waitForMessage(MessageType.MixWaterSelect);
			waitForUseCursor();
			selectInvItem(ObjectType.EmptyMeasuringCup);
			waitForMessage(MessageType.Adding);
			waitForMessage(MessageType.MixWaterAddedToCup);
			while(!haveItem(ObjectType.MeasuringCupBlue))
				wait();

			useInvItem(ObjectType.MeasuringCupBlue);
			waitForMessage(MessageType.MixWaterSelect);
			waitForUseCursor();
			selectInvItem(ObjectType.MixingBowl);
			waitForMessage(MessageType.Adding);
			waitForMessage(MessageType.MixWaterAddedToBowl);
			while(!haveItem(ObjectType.EmptyMeasuringCup))
				wait();

			useInvItem(ObjectType.FlourBag);
			waitForMessage(MessageType.MixFlourSelectCup);
			waitForUseCursor();
			selectInvItem(ObjectType.EmptyMeasuringCup);
			waitForMessage(MessageType.Adding);
			waitForMessage(MessageType.MixFlourAddedToCup);
			while(!haveItem(ObjectType.MeasuringCupWhite))
				wait();

			useInvItem(ObjectType.MeasuringCupWhite);
			waitForMessage(MessageType.MixFlourSelectBowl);
			waitForUseCursor();
			selectInvItem(ObjectType.UsedMixingBowl);
			waitForMessage(MessageType.Adding);
			waitForMessage(MessageType.MixFlourAddedToBowl);
			while(!haveItem(ObjectType.EmptyMeasuringCup))
				wait();

			useInvItem(ObjectType.MixingSpoon);
			waitForMessage(MessageType.MixSpoonSelectBowl);
			waitForUseCursor();
			selectInvItem(ObjectType.UsedMixingBowl);
			waitForMessage(MessageType.Mixing);
			if(waitForMessage([MessageType.MixSuccess, MessageType.MixFailure])==MessageType.MixSuccess)
				waitForMessage(MessageType.MixSuccess2);
			while(!haveItem(ObjectType.MixingBowl))
				wait();

			if(!haveItem(ObjectType.BucketOfWater) && haveItem(ObjectType.EmptyBucket) && isObjectNearby(ObjectType.Well))
			{
				useNearbyObject(ObjectType.Well);
				waitForMessage(MessageType.MixWaterSelectBucket);
				waitForUseCursor();
				selectInvItem(ObjectType.EmptyBucket);
				waitForMessage(MessageType.Adding);
				waitForMessage(MessageType.MixWaterAddedToBucket);
				while(!haveItem(ObjectType.BucketOfWater))
					wait();
			}
		}
		Stdout("Mixer: no ingridients/prerequisites.").newline;
	}
}

static this()
{
	programs ~= new Mixer;
}
