module codetools;

import win32.windows;

// **********************************************************
// code patches

alias ubyte[] Code;

struct Patch
{
	ubyte* address;
	Code originalBytes, newBytes;
	int length() { return originalBytes.length; }
}

typedef Patch[] PatchSet;

bool isPatched(PatchSet set)
{
	bool unpatched=true, patched=true;
	foreach(patch;set)
	{
		assert(patch.originalBytes.length == patch.newBytes.length);
		Code actualBytes = cast(Code) patch.address[0..patch.length];
		unpatched &= actualBytes == patch.originalBytes;
		patched &= actualBytes == patch.newBytes;
	}
	if (patched && unpatched) throw new Exception("PatchSet has identical data");
	if (!patched && !unpatched) throw new Exception("Cannot determine state (unknown EXE?)");
	return patched;
}

void patch(PatchSet set)
{
	if (isPatched(set)) return;
	foreach(patch;set)
	{
		uint old; VirtualProtect(patch.address, patch.length, PAGE_EXECUTE_WRITECOPY, &old);
		patch.address[0..patch.length] = patch.newBytes;
	}
}

void unpatch(PatchSet set)
{
	if (!isPatched(set)) return;
	foreach(patch;set)
	{
		uint old; VirtualProtect(patch.address, patch.length, PAGE_EXECUTE_WRITECOPY, &old);
		patch.address[0..patch.originalBytes.length] = patch.originalBytes;
	}
}

// **********************************************************
// hooks

struct Context
{
	uint edi, esi, ebp, esp, ebx, edx, ecx, eax;
	uint[16] stack;
}

//Code bytes(T)(T[] arr) { return cast(Code) arr; }
//Code bytes(Code arr ...) { return cast(Code) arr; }
Code bytes(T)(T i) { return cast(Code)cast(void[])[i]; }
uint calcDist(void* from, void* to) { return cast(ubyte*)to - cast(ubyte*)from; }

struct Hook
{
	Code target, origcode, hookfunc;

	/// Hooks some code with an additional trampolene, which saves registers to the stack and allows accessing them via the Context structure. 
	/// The hooked code must be at least 5 bytes in size and, unless you overwrite it, it can't contain any relative offsets (jumps, calls).
	static Hook opCall(void* addr, uint len, void function(Context*) fn, bool overwrite = false)
	{
		assert(len >= 5);
		Hook hook;
		with(hook)
		{
			target = cast(Code)addr[0..len];
			origcode = target.dup;
			auto oldcode = origcode.dup;
			if(overwrite)
				oldcode[] = 0x90;  // don't execute old code after our function exits
		
			hookfunc.length = 9 + len + 5;
			hookfunc[0..4] = cast(Code)[0x60, 0x8B, 0xC4, 0xE8];            // pushad; mov eax, esp; call ...
			hookfunc[4..8] = bytes(calcDist(hookfunc.ptr+8, fn));
			hookfunc[8]    =              0x61;                                // popad
			hookfunc[9..9+len] = oldcode;
			hookfunc[9+len]             = 0xE9;                                // jmp
			hookfunc[9+len+1..9+len+5] = bytes(calcDist(hookfunc.ptr+9+len+5, addr+len));

			uint old;
			VirtualProtect(target.ptr, target.length, PAGE_EXECUTE_WRITECOPY, &old);
			target[0]    = 0xE9;  // jmp ...
			target[1..5] = bytes(calcDist(target.ptr+5, hookfunc.ptr));
			target[5..$] = 0x90;  // nop
		}
		return hook;
	}

	/// Overwrite an address with a direct jump to your function, without a trampolene. Use to hook functions which you won't need to call yourself.
	static Hook hotwire(void* addr, void* fn)
	{
		Hook hook;
		with(hook)
		{
			target = cast(Code)addr[0..5];
			origcode = target.dup;

			uint old;
			VirtualProtect(target.ptr, target.length, PAGE_EXECUTE_WRITECOPY, &old);
			target[0]    = 0xE9;  // jmp ...
			target[1..5] = bytes(calcDist(target.ptr+5, fn));
		}
		return hook;
	}

	/// Overwrite a call at the specified address with a call to your function. You also optionally receive the address of the original function.
	static Hook hookCall(void* addr, void* fn, void** oldfn=null)
	{
		Hook hook;
		with(hook)
		{
			target = cast(Code)addr[0..5];
			origcode = target.dup;
			assert(target[0] == 0xE8, "hookCall called with an address not containing a call");

			if(oldfn)
				*oldfn = target.ptr+5 + *cast(uint*)(cast(ubyte*)addr+1);

			uint old;
			VirtualProtect(target.ptr, target.length, PAGE_EXECUTE_WRITECOPY, &old);
			target[0]    = 0xE8;  // jmp ...
			target[1..5] = bytes(calcDist(target.ptr+5, fn));
		}
		return hook;
	}

	private static Hook hookRet(void* addr)
	{
		Hook hook;
		with(hook)
		{
			target = cast(Code)addr[0..1];
			origcode = target.dup;

			uint old;
			VirtualProtect(target.ptr, target.length, PAGE_EXECUTE_WRITECOPY, &old);
			target[0]    = 0xC3;  // retn
		}
		return hook;
	}

	void unhook()
	{
		target[] = origcode;
	}
}

// **********************************************************
// random code interop

void callCode(void* start, void* end, int esi)
{
	Hook hook = Hook.hookRet(end);
	asm {
		pushad;
		mov ESI, esi;
		mov EAX, start;
		call EAX;
		popad;
	}
	hook.unhook();
}

// **********************************************************
// interop mixins

char[] mixOrdPtr(char[] typeName, char[] varName, char[] offsetName)
{
	return "auto "~varName~"Ptr = cast("~typeName~"*)Offsets."~offsetName~";"~
		typeName~" "~varName~"() { return *"~varName~"Ptr; }";
}

char[] mixObjPtr(char[] typeName, char[] varName, char[] offsetName)
{
	return mixOrdPtr(typeName ~ "*", varName, offsetName);
}

char[] mixObjPtr(char[] typeName, char[] varName)
{
	return mixObjPtr(typeName, varName, typeName);
}

char[] mixArrayIterator(char[] name, char[] type, char[] varName, char[] countVarName)
{
	return "
		int "~name~"(int delegate(ref "~type~") dg)
		{   
			int result = 0;
			for(int i=0;i<"~countVarName~";i++)
			{
				result = dg("~varName~"[i]);
				if (result)
					break;
			}
			return result;
		}
";
}

char[] mixMethod(char[] className, char[] methodName, char[][] argTypes, char[] returnType="void")
{
	char[] s = "
		"~returnType~" "~methodName~"(";
	for(int i=0;i<argTypes.length;i++)
	{
		if(i>0) s~=", ";
		s~=argTypes[i] ~ " " ~ cast(char)('a'+i);
	}
	s~=")
		{
			void* temp = this;
			asm
			{
				";
	for(int i=argTypes.length-1;i>=0;i--)
		s~="push dword ptr " ~ cast(char)('a'+i) ~ ";";
	s~=			"mov ECX, temp;
				mov EAX, Offsets."~className~"__"~methodName~";
				call EAX;
			}
		}
";
	return s;
}

// **********************************************************

