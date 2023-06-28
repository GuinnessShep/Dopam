#import "kcall.h"
#import "pplrw.h"
#import "pte.h"
#import "boot_info.h"
#import "util.h"

#define PERM_KRW_URW 0x7 // R/W for kernel and user
#define FAKE_PHYSPAGE_TO_MAP 0x13370000

kern_return_t pmap_enter_options_addr(uint64_t pmap, uint64_t pa, uint64_t va) {
    while (1) {
        kern_return_t kr = (kern_return_t) kcall8(bootInfo_getSlidUInt64(@"pmap_enter_options_addr"), pmap, va, pa, VM_PROT_READ | VM_PROT_WRITE, 0, 0, 1, 1);
        if (kr != KERN_RESOURCE_SHORTAGE) {
            return kr;
        }
    }
}

void pmap_remove(uint64_t pmap, uint64_t start, uint64_t end) {
    kcall8(bootInfo_getSlidUInt64(@"pmap_remove_options"), pmap, start, end, 0x100, 0, 0, 0, 0);
}

int pmap_map_in(uint64_t pmap, uint64_t uaddr, uint64_t pa, uint64_t size)
{
	uint64_t mappingSize = 0x4000 * 2048;
	uint64_t mappingUaddr = uaddr - (uaddr % mappingSize);
	uint64_t mappingPA = pa - (pa % mappingSize);

	uint64_t pageCount = size / 0x4000;
	uint64_t mappingCount = (pageCount / 2048) + ((pageCount % 2048) != 0);

	for (uint64_t i = 0; i < mappingCount; i++) {
		uint64_t curMappingUaddr = mappingUaddr + (i * mappingSize);
		kern_return_t kr = pmap_enter_options_addr(pmap, FAKE_PHYSPAGE_TO_MAP, curMappingUaddr);
		if (kr != KERN_SUCCESS) {
			pmap_remove(pmap, mappingUaddr, curMappingUaddr);
			return -7;
		}
	}

	// Temporarily change pmap type to nested
	pmap_set_type(pmap, 3);
	// Remove mapping (table will not be removed because we changed the pmap type)
	pmap_remove(pmap, mappingUaddr, mappingUaddr + (mappingCount * mappingSize));
	// Change type back
	pmap_set_type(pmap, 0);

	for (uint64_t i = 0; i < mappingCount; i++) {
		uint64_t curMappingUaddr = mappingUaddr + (i * mappingSize);
		uint64_t curMappingPA = mappingPA + (i * mappingSize);

		// Create full table for this mapping
		uint64_t tableToWrite[2048];
		for (int k = 0; k < 2048; k++) {
			uint64_t curMappingPage = curMappingPA + (k * 0x4000);
			if (curMappingPage >= pa || curMappingPage < (pa + size)) {
				tableToWrite[k] = curMappingPage | PERM_TO_PTE(PERM_KRW_URW) | PTE_NON_GLOBAL | PTE_OUTER_SHAREABLE | PTE_LEVEL3_ENTRY;
			}
			else {
				tableToWrite[k] = 0;
			}
		}

		// Replace table with the entries we generated
		uint64_t table2Entry = pmap_lv2(pmap, curMappingUaddr);
		if ((table2Entry & 0x3) == 0x3) {
			uint64_t table3 = table2Entry & 0xFFFFFFFFC000ULL;
			physwritebuf(table3, tableToWrite, 0x4000);

			usleep(70);
			usleep(70);
			__asm("dmb sy");
		}
		else {
			return -6;
		}
	}

	return 0;
}

int handoffPPLPrimitives(pid_t pid)
{
	if (!pid) return -1;

	int ret = 0;

	bool proc_needs_release = false;
	uint64_t proc = proc_for_pid(pid, &proc_needs_release);
	if (proc) {
		uint64_t task = proc_get_task(proc);
		if (task) {
			uint64_t vmMap = task_get_vm_map(task);
			if (vmMap) {
				uint64_t pmap = vm_map_get_pmap(vmMap);
				if (pmap) {
					// Map the entire kernel physical address space into the userland process 1:1
					uint64_t physBase = kread64(bootInfo_getSlidUInt64(@"gPhysBase"));
					uint64_t physSize = kread64(bootInfo_getSlidUInt64(@"gPhysSize"));
					ret = pmap_map_in(pmap, physBase+USER_MAPPING_OFFSET, physBase, physSize);
				}
				else { ret = -5; }
			}
			else { ret = -4; }
		}
		else { ret = -3; }
		if (proc_needs_release) proc_rele(proc);
	}
	else { ret = -2; }

	return ret;
}
