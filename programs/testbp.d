module programs.testbp;

import dranscript;
import timing;
import tango.sys.win32.UserGdi;

class TestBP : Program
{
	override void execute()
	{
		foreach(item;*backPack)
			Stdout(objectData[globalObjects[item.ID].objType].name).newline;
		Stdout.newline;
	}
}

static this()
{
	programs ~= new TestBP;
}
