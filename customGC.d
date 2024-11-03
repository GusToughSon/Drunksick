module customGC;

import tango.core.Thread;
import tango.core.Memory;
import win32.windows;
import tango.io.Stdout;

void customGCstart()
{
	GC.disable();
	last = GetTickCount();
}

void customGCstop()
{
	// nothing in this implementation
}

void doGarbageCollect()
{
	Stdout("Collecting garbage... ")();
	GC.collect();
	Stdout("Done.").newline;
	last = GetTickCount();
}

void scheduledGarbageCollect()
{
	if(GetTickCount()-last > 30*1000)
		doGarbageCollect();
}

private uint last;
