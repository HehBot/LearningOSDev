#ifndef FRAME_ALLOCATOR_H
#define FRAME_ALLOCATOR_H

#include "page.h"

#include <stdint.h>

struct multiboot_tag_mmap;

void init_pmm(struct multiboot_tag_mmap const* mmap_info);
int pmm_reserve_frame(phys_addr_t phys_addr);
phys_addr_t pmm_get_frame();
int pmm_free_frame(phys_addr_t phys_addr);

// int pmm_reserve_large_frame(uintptr_t phys_addr);
// uintptr_t pmm_get_large_frame();
// int pmm_free_large_frame(uintptr_t phys_addr);

#endif // FRAME_ALLOCATOR_H