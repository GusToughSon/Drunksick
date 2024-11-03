module gametime;

import timing;
import commondata;

Time lastChange;
uint last = -1;
bool known = false;
const hourDuration = 150.8;

void processGameTime()
{
	if(playerData is null) return;
	if(last!=playerData.Hour)
	{
		if(last!=-1)
		{
			lastChange = Clock.now;
			known = true;
		}
		last = playerData.Hour;
		//Stdout.format("[{}:{}:{}.{}] Tick... {}", lastChange.hour, lastChange.minute, lastChange.second, lastChange.millisecond, last).newline;
	}
}

char[] getTimeString()
{
	try
		if(playerData)
			if(!known)
				return formatter("{,2}:??", playerData.Hour);
			else
				return formatter("{,2}:{:d2}", playerData.Hour, cast(int)((Clock.now-lastChange).interval / hourDuration * 60));
		else
			return "??:??";
	catch(Object e)
		return "XX:XX";
}