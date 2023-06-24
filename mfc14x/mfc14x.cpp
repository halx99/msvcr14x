// mfc14x.cpp: ���� DLL Ӧ�ó���ĵ���������
//

#include "stdafx.h"

#include "..\msvcr14x\stdafx.c"

#ifdef _M_IX86
#pragma comment(lib,"KERNEL32.lib")
#pragma comment(lib,"win2k_kernl32p.lib")
#elif defined(_M_X64)
#pragma comment(lib,"win2k3_KERNEL32.lib")
#pragma comment(lib,"win2k3_kernl32p.lib")
#endif

#ifndef _WIN64
#define DllMain DllMain_Existence
#include "..\atlmfc\src\mfc\dllinit.cpp"
#undef DllMain
extern "C"
{
	//����һ���ⲿ�����ţ�ָʾ��ǰ�Ƿ���ǿ��ж��ģʽ��
	BOOL __YY_Thunks_Process_Terminating;
	BOOL WINAPI DllMain(HINSTANCE hInstance, DWORD dwReason, LPVOID lpReserved)
	{
		switch (dwReason)
		{
		case DLL_PROCESS_DETACH:
			//���ǿ���ͨ�� lpReserved != NULL �жϣ���ǰ�Ƿ���ǿ��ж��ģʽ��
			__YY_Thunks_Process_Terminating = lpReserved != NULL;
			break;
		}
		return DllMain_Existence(hInstance, dwReason, lpReserved);
	}
}
#else
#include "..\atlmfc\src\mfc\dllinit.cpp"
#endif

extern "C"
{
	const void* __acrt_atexit_table;
}