module programs.weaver;

import dranscript;

class Weaver : Program
{
	override void execute()
	{
		while(haveItem(ObjectType.Cotton) && isObjectNearby(ObjectType.SpinningWheel))
		{
			useInvItem(ObjectType.Cotton);
			waitForUseCursor();
			selectNearbyObject(ObjectType.SpinningWheel);
			while(!isObjectNearby(ObjectType.SpinningWheelActive))
				wait();
			while(!isObjectNearby(ObjectType.SpinningWheel))
				wait();

			//waitForMessage(MessageType.ReUseReady);
			if(playerData.Weight >= playerData.MaxWeight*6/5)
				return playSound("Sounds/ContainerFull.wav");
		}
	}
}

static this()
{
	programs ~= new Weaver;
}
