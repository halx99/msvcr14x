#pragma once
#include "msvcr14x.h"
#include <ntdll.h>
#include <VersionHelpers.h>

#ifdef __cplusplus
extern "C++"
{
	extern DWORD __crt_global_state_mode_flsindex;
	namespace __crt_state_management
	{
		const size_t state_index_count = 2;
		extern bool is_teb_slot_available;

		static bool initialize_global_state_isolation()
		{
			is_teb_slot_available = IsWindows10OrGreater();
			__crt_global_state_mode_flsindex = __acrt_FlsAlloc(0);
			return __crt_global_state_mode_flsindex != FLS_OUT_OF_INDEXES;
		}

		static void uninitialize_global_state_isolation(const bool __formal)
		{
			if (__crt_global_state_mode_flsindex != FLS_OUT_OF_INDEXES)
			{
				__acrt_FlsFree(__crt_global_state_mode_flsindex);
				__crt_global_state_mode_flsindex = FLS_OUT_OF_INDEXES;
			}
		}

		static size_t get_current_state_index()
		{
			DWORD dwLastError;
			size_t current_state_index;

			dwLastError = GetLastError();
			current_state_index = (size_t)__acrt_FlsGetValue(__crt_global_state_mode_flsindex);
			SetLastError(dwLastError);
			return current_state_index;
		}

		static size_t get_current_state_index(const __crt_scoped_get_last_error_reset& __formal)
		{
			return (size_t)__acrt_FlsGetValue(__crt_global_state_mode_flsindex);
		}

		static BOOL should_use_teb_for_state_index()
		{
			return is_teb_slot_available && !__acrt_IsThreadAFiber();
		}

		ULONGLONG* get_teb_data_address();
		ULONGLONG get_teb_data_value();

		static size_t get_current_state_index2()
		{
			if (should_use_teb_for_state_index())
				return (size_t)get_teb_data_value();
			else
				return (size_t)__acrt_FlsGetValue2(__crt_global_state_mode_flsindex);
		}

		static bool is_os_call()
		{
			return get_current_state_index() == 1;
		}

		static void enter_os_call_inline(bool useTeb)
		{
			if (useTeb)
				*get_teb_data_address() = 1;
			else
				__acrt_FlsSetValue(__crt_global_state_mode_flsindex, (PVOID)1);
		}

		static void enter_os_call(bool useTeb)
		{
			enter_os_call_inline(useTeb);
		}

		static bool enter_os_call()
		{
			bool useTeb = should_use_teb_for_state_index();
			enter_os_call_inline(useTeb);
			return useTeb;
		}

		static void leave_os_call_inline(bool useTeb)
		{
			if (useTeb)
				*get_teb_data_address() = 0;
			else
				__acrt_FlsSetValue(__crt_global_state_mode_flsindex, (PVOID)0);
		}

		static void leave_os_call(bool useTeb)
		{
			leave_os_call_inline(useTeb);
		}

		static bool leave_os_call()
		{
			bool useTeb = should_use_teb_for_state_index();
			leave_os_call_inline(useTeb);
			return useTeb;
		}

		class scoped_global_state_reset
		{
			bool _was_os_call;
			bool _use_teb;
		public:
			scoped_global_state_reset()
			{
				_was_os_call = is_os_call();
				if (_was_os_call)
					_use_teb = leave_os_call();
			}
			~scoped_global_state_reset()
			{
				if (_was_os_call)
					enter_os_call(_use_teb);
			}
		};

		template <typename T>
		class dual_state_global
		{
			T _value[2];
		public:
			void initialize(T new_value)
			{
				for (T& every_value : _value)
				{
					every_value = new_value;
				}
			}

			template <typename DATA_ARRAY>
			void initialize_from_array(DATA_ARRAY data_array[2])
			{
				for (size_t i = 0; i != _countof(_value); ++i)
				{
					_value[i] = data_array[i];
				}
			}

			void uninitialize(void f(T& v))
			{
				for (T& every_value : _value)
				{
					f(every_value);
				}
			}
			T* dangerous_get_state_array()
			{
				return _value;
			}
			T& value()
			{
				return _value[get_current_state_index()];
			}
			T& value_explicit(const size_t current_global_state_index)
			{
				return _value[current_global_state_index];
			}
			__if_exists(__crt_cached_ptd_host)
			{
				T& value(__crt_cached_ptd_host & ptd) throw();
				T const& value(__crt_cached_ptd_host & ptd) const throw();
			}
		};
	}

	static __acrt_lock_id __acrt_select_exit_lock()
	{
		__acrt_lock_id lock_id;

		if (__crt_state_management::is_os_call())
			lock_id = __acrt_os_exit_lock;
		else
			lock_id = __acrt_exit_lock;
		return lock_id;
	}
}
#endif