#import <Foundation/Foundation.h>

uint64_t kalloc(uint64_t size);
uint64_t kfree(uint64_t addr, uint64_t size);
uint64_t stringKalloc(const char *string);
void stringKFree(const char *string, uint64_t kmem);

bool cs_allow_invalid(uint64_t proc_ptr);
uint64_t ptrauth_utils_sign_blob_generic(uint64_t ptr, uint64_t len_bytes, uint64_t salt, uint64_t flags);
uint64_t kpacda(uint64_t pointer, uint64_t modifier);
uint64_t kptr_sign(uint64_t kaddr, uint64_t pointer, uint16_t salt);
void kwrite_ptr(uint64_t kaddr, uint64_t pointer, uint16_t salt);

void proc_iterate(void (^itBlock)(uint64_t, BOOL*));
uint64_t proc_for_pid(pid_t pidToFind);
uint64_t proc_get_task(uint64_t proc_ptr);
pid_t proc_get_pid(uint64_t proc_ptr);
uint64_t proc_get_ucred(uint64_t proc_ptr);
uint64_t proc_get_proc_ro(uint64_t proc_ptr);
uint64_t proc_ro_get_ucred(uint64_t proc_ro_ptr);
uint64_t proc_get_text_vnode(uint64_t proc_ptr);
uint64_t proc_get_file_glob_by_file_descriptor(uint64_t proc_ptr, int fd);
uint64_t proc_get_vnode_by_file_descriptor(uint64_t proc_ptr, int fd);
uint32_t proc_get_csflags(uint64_t proc);
void proc_set_csflags(uint64_t proc, uint32_t csflags);
uint64_t self_proc(void);

uint32_t ucred_get_svuid(uint64_t ucred_ptr);
int ucred_set_svuid(uint64_t ucred_ptr, uint32_t svuid);
uint64_t ucred_get_cr_label(uint64_t ucred_ptr);

uint64_t task_get_first_thread(uint64_t task_ptr);
uint64_t thread_get_act_context(uint64_t thread_ptr);
uint64_t task_get_vm_map(uint64_t task_ptr);
uint64_t self_task(void);

uint64_t vm_map_get_pmap(uint64_t vm_map_ptr);
void pmap_set_wx_allowed(uint64_t pmap_ptr, bool wx_allowed);
void pmap_set_type(uint64_t pmap_ptr, uint8_t type);
uint64_t pmap_lv2(uint64_t pmap_ptr, uint64_t virt);
uint64_t get_cspr_kern_intr_en(void);
uint64_t get_cspr_kern_intr_dis(void);

uint64_t vnode_get_ubcinfo(uint64_t vnode_ptr);
void ubcinfo_iterate_csblobs(uint64_t ubc_info_ptr, void (^itBlock)(uint64_t, BOOL*));
uint64_t vnode_get_csblob(uint64_t vnode_ptr);
uint64_t vnode_get_data(uint64_t vnode_ptr);
void vnode_set_data(uint64_t vnode_ptr, uint64_t data);
uint16_t vnode_get_type(uint64_t vnode_ptr);
uint32_t vnode_get_id(uint64_t vnode_ptr);
uint64_t vnode_get_mount(uint64_t vnode_ptr);

uint64_t csblob_get_pmap_cs_entry(uint64_t csblob_ptr);

NSMutableDictionary *DEREntitlementsDecode(uint8_t *start, uint8_t *end);
void DEREntitlementsEncode(NSDictionary *entitlements, uint8_t **startOut, uint8_t **endOut);

void OSEntitlements_resign(uint64_t OSEntitlements_ptr);
uint64_t cr_label_get_OSEntitlements(uint64_t cr_label_ptr);
NSData *OSEntitlements_get_cdhash(uint64_t OSEntitlements_ptr);

NSMutableDictionary *OSEntitlements_dump_entitlements(uint64_t OSEntitlements_ptr);
void OSEntitlements_replace_entitlements(uint64_t OSEntitlements_ptr, NSDictionary *newEntitlements);

NSMutableDictionary *vnode_dump_entitlements(uint64_t vnode_ptr);
void vnode_replace_entitlements(uint64_t vnode_ptr, NSDictionary *newEntitlements);
NSMutableDictionary *proc_dump_entitlements(uint64_t proc_ptr);
void proc_replace_entitlements(uint64_t proc_ptr, NSDictionary *entitlements);

bool proc_set_debugged(pid_t pid);
NSString *proc_get_path(pid_t pid);
int64_t proc_fix_setuid(pid_t pid);
