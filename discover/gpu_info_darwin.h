#import <Metal/Metal.h>
#include <stdint.h>
#include <stdbool.h>

// System memory helpers
uint64_t getRecommendedMaxVRAM(void);
uint64_t getPhysicalMemory(void);
uint64_t getFreeMemory(void);

// ---------------------------------------------------------------------------
// Multi-device Metal enumeration — needed for AMD eGPU support on macOS.
//
// MTLCreateSystemDefaultDevice() returns only the default (usually internal)
// GPU.  MTLCopyAllDevices() enumerates every Metal-capable device, including
// external AMD GPUs connected via Thunderbolt (eGPUs such as the Radeon VII
// and RX 6800).  The functions below expose that list to Go code.
// ---------------------------------------------------------------------------

typedef struct {
    char     name[256];
    uint64_t recommended_max_vram;
    bool     removable;         // true  → eGPU (external, e.g. Radeon VII / RX 6800)
    bool     headless;          // true  → headless/compute-only device
    bool     has_unified_memory; // true → Apple Silicon unified memory
    uint64_t registry_id;       // unique per-device identifier
} MetalDeviceInfo;

// Returns the total number of Metal-capable GPUs visible to the process,
// including any attached eGPUs.
int getMetalDeviceCount(void);

// Returns device metadata for the device at the given zero-based index.
// Indices match those exposed by MTLCopyAllDevices().
// Out-of-range indices return a zeroed struct.
MetalDeviceInfo getMetalDeviceInfoAtIndex(int index);
