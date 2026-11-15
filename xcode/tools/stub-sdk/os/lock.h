#pragma once
typedef struct os_unfair_lock_s { unsigned int _os_unfair_lock_opaque; } os_unfair_lock, *os_unfair_lock_t;
#define OS_UNFAIR_LOCK_INIT ((os_unfair_lock){0})
void os_unfair_lock_lock(os_unfair_lock_t lock);
void os_unfair_lock_unlock(os_unfair_lock_t lock);
