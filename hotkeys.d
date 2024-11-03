module hotkeys;

import win32.windows;
import tango.time.Clock;
import dransik;

ubyte[256] lastKS, currentKS;
POINT lastCP, currentCP;
Time lastActivity;
void function(ubyte) keyHandler;

void updateKeyboard()
{
	GetKeyState(0);
	GetKeyboardState(&currentKS[0]);
	
	foreach(i,c;currentKS)
		if(c!=lastKS[i])
		{
			lastActivity = Clock.now;
			if(c>=128 && lastKS[i]<128)  // pressed
				if(isGameFocused())
					keyHandler(i);
		}
	GetCursorPos(&currentCP);
	if(lastCP.x != currentCP.x || lastCP.y != currentCP.y)
		lastActivity = Clock.now;
	lastKS[] = currentKS;
	lastCP   = currentCP;
}

TimeSpan idleTime()
{
	return Clock.now - lastActivity;
}
