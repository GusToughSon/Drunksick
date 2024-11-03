module customMM;

import win32.windows;

void[] malloc(size_t nbytes)
{
	void* p = VirtualAlloc(null, nbytes, MEM_COMMIT, PAGE_READWRITE);
	if (p is null)
	    return null;
	else
	    return p[0..nbytes];
}

void free(void* p)
{
	VirtualFree(p, 0, MEM_RELEASE);
}
