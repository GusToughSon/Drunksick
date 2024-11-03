module timing;

import tango.math.Math;
public import tango.time.Clock;

Time waitUntil;

float speed = 1.0;

void wait(int msec, bool proportional=true)
{
	if(proportional)
		msec = cast(int)round(msec/speed);
	waitUntil = Clock.now + TimeSpan.millis(msec);
}

bool waiting()
{
	return waitUntil>Clock.now;
}

float secondsSince(Time since)
{
	return (Clock.now - since).interval;
}
