#import <Foundation/Foundation.h>
#import <mach/mach.h>
#include <string.h>
#include "gpu_info_darwin.h"

// ---------------------------------------------------------------------------
// Original system-memory helpers (unchanged from upstream)
// ---------------------------------------------------------------------------

uint64_t getRecommendedMaxVRAM() {
    id<MTLDevice> device = MTLCreateSystemDefaultDevice();
    uint64_t result = device.recommendedMaxWorkingSetSize;
    CFRelease(device);
    return result;
}

// getPhysicalMemory returns the total physical memory in bytes.
uint64_t getPhysicalMemory() {
    return [NSProcessInfo processInfo].physicalMemory;
}

// getFreeMemory returns the total free memory in bytes, including inactive
// memory that can be reclaimed by the system.
uint64_t getFreeMemory() {
    mach_port_t host_port = mach_host_self();
    mach_msg_type_number_t host_size = sizeof(vm_statistics64_data_t) / sizeof(integer_t);
    vm_size_t pagesize;
    vm_statistics64_data_t vm_stat;

    host_page_size(host_port, &pagesize);
    if (host_statistics64(host_port, HOST_VM_INFO64, (host_info64_t)&vm_stat, &host_size) != KERN_SUCCESS) {
        return 0;
    }

    uint64_t free_memory = (uint64_t)vm_stat.free_count * pagesize;
    free_memory += (uint64_t)vm_stat.speculative_count * pagesize;
    free_memory += (uint64_t)vm_stat.inactive_count * pagesize;

    return free_memory;
}

// ---------------------------------------------------------------------------
// Multi-device Metal enumeration for AMD eGPU support
//
// MTLCopyAllDevices() (macOS-only API) returns every Metal-capable GPU,
// including external AMD GPUs connected via Thunderbolt (eGPUs).  External
// devices are identifiable via the `removable` property.
// ---------------------------------------------------------------------------

int getMetalDeviceCount() {
    @autoreleasepool {
        NSArray<id<MTLDevice>> *devices = MTLCopyAllDevices();
        int count = (int)devices.count;
        [devices release];
        return count;
    }
}

MetalDeviceInfo getMetalDeviceInfoAtIndex(int index) {
    MetalDeviceInfo info;
    memset(&info, 0, sizeof(info));

    @autoreleasepool {
        NSArray<id<MTLDevice>> *devices = MTLCopyAllDevices();
        if (index >= 0 && index < (int)devices.count) {
            id<MTLDevice> device = devices[index];
            const char *name = [device.name UTF8String];
            if (name != NULL) {
                strncpy(info.name, name, sizeof(info.name) - 1);
                info.name[sizeof(info.name) - 1] = '\0';
            }
            info.recommended_max_vram = device.recommendedMaxWorkingSetSize;
            info.removable           = (bool)device.removable;
            info.headless            = (bool)device.headless;
            info.has_unified_memory  = (bool)device.hasUnifiedMemory;
            info.registry_id         = device.registryID;
        }
        [devices release];
    }
    return info;
}
