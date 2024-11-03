module utils;

import tango.stdc.stringz;

public alias void[] buffer;

struct BufferEx
{
	union
	{
		buffer buf;
		struct Fields
		{
			size_t length;
			void* ptr;
		} Fields fields;
	}
}

buffer toBuffer(T)(inout T data)
{
	BufferEx b;
	b.fields.ptr = &data;
	b.fields.length = T.sizeof;
	return b.buf;
}

T[] readStringZ(T)(T* p)
{
	if(p is null)
		return null;
	T[] s;
	while(*p)
		s~=*p++;
	return s;
}

bool isInArray(T)(T[] arr, T elem)
{
	foreach(e;arr)
		if(e==elem)
			return true;
	return false;
}

void deleteFromArray(T)(ref T[] arr, T elem)
{
	foreach_reverse(i,e;arr)
		if(e==elem)
			arr = arr[0..i] ~ arr[i+1..$];
}

// **********************************************************

pragma(lib,"winmm.lib");
extern(Windows) bool sndPlaySoundA(char* pszSound, uint fuSound);
void playSound(char[] s)
{
	sndPlaySoundA(toStringz(myPath ~ s), 3);
//	Stdout("Playing "~s).newline;
}

// **********************************************************

import tango.text.convert.Layout;

Layout!(char) formatter;

static this()
{
	formatter = new Layout!(char);
}

// **********************************************************

import tango.io.FilePath;

import win32.windows;

char[] myPath()
{
	char[1024] fn;
	GetModuleFileNameA(GetModuleHandleA("DrunkSick2.dll".toStringz()), fn.ptr, fn.length);
	return FilePath(readStringZ(fn.ptr)).path;
}

// **********************************************************

import tango.math.Random;

// shorthand name
int rand(int max)
{
	return Random.shared.next(max);
}

int interpolate(int a, int b, float point)
{
	return a + cast(int)((b-a)*point);
}
