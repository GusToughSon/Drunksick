module programs.test;

import dranscript;
import timing;
import tango.sys.win32.UserGdi;

class Test : Program
{
	auto interval = 2.0;

	override void execute()
	{
		beginDragInvItem(ObjectType.Gold, true);
	}

	override void configure()
	{
		clientServices.SendDropAt(myX-1, myY);
	}
}

static this()
{
	programs ~= new Test;
}
