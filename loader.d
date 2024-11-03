module loader;

import win32.windows;
import tango.text.Util;
import tango.stdc.stringz;
import tango.io.FilePath;
//import tango.io.Stdout;

extern(Windows)
LPVOID VirtualAllocEx(
  HANDLE hProcess,
  LPVOID lpAddress,
  size_t dwSize,
  DWORD flAllocationType,
  DWORD flProtect
);

void main(char[][] args)
{
	try
	{
		char[] myPath; myPath.length = 1024;
		myPath.length = GetModuleFileNameA(null, myPath.ptr, myPath.length);

		char[] libPath = split(myPath, \\)[0..$-1].join(\\)~"\\DrunkSick2.dll";
		if(!(new FilePath(libPath)).exists)
			throw new Exception("DrunkSick2.dll not present");
		
		HWND window = FindWindowW("DRANSIK"w.ptr, null);
		if (window is null) 
		{
			window = FindWindowW(null, toString16z("Iron Will Games Launcher (c)"w));
			if(window is null)
				throw new Exception("Can't find Dransik/Launcher window");
			HWND button = FindWindowExW(window, null, toString16z("Button"w), toString16z("Play"w));
			if(button is null)
				throw new Exception("Can't find Launcher 'Play' button");
			if(!IsWindowVisible(button) || !IsWindowEnabled(button))
			{
				//throw new Exception("Launcher 'Play' button inaccessible");
				HWND edit = FindWindowExW(window, null, toString16z("Edit"w), null);
				if(edit) edit = FindWindowExW(window, edit, toString16z("Edit"w), null);
				if(edit) SendMessageW(edit, WM_LBUTTONDOWN, MK_LBUTTON, 0x00050005);
				
				ShowWindow(window, SW_SHOWNORMAL);
				SetForegroundWindow(window);
				while(!IsWindowVisible(button) || !IsWindowEnabled(button))
					Sleep(1);
			}
			SendMessageW(button, BM_CLICK, 0, 0);
			do
			{
				Sleep(1);
				window = FindWindowW("DRANSIK"w.ptr, null);
			}
			while(window is null);
		}
		DWORD processId, threadId = GetWindowThreadProcessId(window, &processId);
	
		HANDLE hProcess = OpenProcess(PROCESS_CREATE_THREAD | PROCESS_QUERY_INFORMATION | PROCESS_VM_OPERATION | PROCESS_VM_WRITE | PROCESS_VM_READ, FALSE, processId);
		if(!hProcess) throw new Exception("OpenProcess failed");

		//Stdout("Injecting "~libPath).newline;
		libPath ~= \0;

		void* pLibRemote = VirtualAllocEx( hProcess, null, 	libPath.length, MEM_COMMIT, PAGE_READWRITE );
		if(!pLibRemote) throw new Exception("VirtualAllocEx failed");

		WriteProcessMemory(hProcess, pLibRemote, libPath.ptr, libPath.length, null);

		HMODULE hKernel32 = GetModuleHandleA("Kernel32");
		HANDLE hThread = CreateRemoteThread(hProcess, null, 0,	cast(LPTHREAD_START_ROUTINE)GetProcAddress(hKernel32, "LoadLibraryA"), 	pLibRemote, 0, null);
		if(!hThread) throw new Exception("CreateRemoteThread failed");
		//WaitForSingleObject( hThread, INFINITE );
		//Stdout("DrunkSick2 injected successfully.");
		CloseHandle( hThread );
	}
	catch (Object e)
		MessageBoxA(null, (e.toString~\0).ptr, "Error\0", MB_ICONERROR);
}
