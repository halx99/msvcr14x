// mfc14x.cpp: ���� DLL Ӧ�ó���ĵ���������
//

#include "stdafx.h"

#include "..\msvcr14x\stdafx.cpp"

#ifdef _M_IX86
#pragma comment(lib,"KERNEL32.lib")
#pragma comment(lib,"win2k_kernl32p.lib")
#elif defined(_M_X64)
#pragma comment(lib,"win2k3_KERNEL32.lib")
#pragma comment(lib,"win2k3_kernl32p.lib")
#endif

#pragma comment(linker, "/ENTRY:DllMainCRTStartupForYY_Thunks")
extern "C"
{
	const void* __pfnDllMainCRTStartupForYY_Thunks;
	BOOL __YY_Thunks_Disable_Rreload_Dlls;
	const void* __pfnYY_Thunks_CustomLoadLibrary;
	const void* __acrt_atexit_table;
}