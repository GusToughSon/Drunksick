module dllmain;

import tango.stdc.stringz;
import win32.windows;

import mainui;

extern (C)
{
	void gc_init();
	void gc_term();
	void _minit();
	void _moduleCtor();
	void _moduleDtor();
}

extern (Windows)
uint ThreadProc(void* parameter)
{
	auto hInstance = cast(HINSTANCE)parameter;
	gc_init();					// initialize GC
	_minit();					// initialize module list
	initializeConsole();    	// initialize console window before Tango module constructors
	initializeDFL(hInstance);	// initialize DFL library with the hInstance
	_moduleCtor();				// run module constructors
	runMainUI(hInstance);		// run main code
	auto me = GetModuleHandleA(toStringz("DrunkSick2.dll")); // need to do this before GC shuts down
	_moduleDtor();				// run module constructors
	gc_term();					// shut down GC
	FreeLibraryAndExitThread(me, 0);  // self-destruct
	assert(0);
}

extern (Windows)
BOOL DllMain(HINSTANCE hInstance, ULONG ulReason, LPVOID pvReserved)
{
	switch (ulReason)
	{
	case DLL_PROCESS_ATTACH:
		CloseHandle(CreateThread(null, 0, &ThreadProc, hInstance, 0, null));
		ExitThread(0);
		break;

	case DLL_PROCESS_DETACH:
		MessageBoxA(null, "hm, detach, wtf?", null, 0);
		break;

	case DLL_THREAD_ATTACH:
	case DLL_THREAD_DETACH:
		// Multiple threads not supported yet
		return false;
	}
	//g_hInst=hInstance;
	return true;
}
