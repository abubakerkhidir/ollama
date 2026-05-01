package discover

/*
#cgo CFLAGS: -x objective-c
#cgo LDFLAGS: -framework Foundation -framework CoreGraphics -framework Metal
#include "gpu_info_darwin.h"
*/
import "C"

import (
	"log/slog"
	"syscall"
	"unsafe"

	"github.com/ollama/ollama/format"
)

const (
	metalMinimumMemory = 512 * format.MebiByte
)

// GetCPUMem returns total and free system memory on Darwin.
func GetCPUMem() (memInfo, error) {
	return memInfo{
		TotalMemory: uint64(C.getPhysicalMemory()),
		FreeMemory:  uint64(C.getFreeMemory()),
		// FreeSwap omitted as Darwin uses dynamic paging
	}, nil
}

// GetCPUDetails returns physical and logical CPU counts on Darwin.
func GetCPUDetails() []CPU {
	query := "hw.perflevel0.physicalcpu"
	perfCores, err := syscall.SysctlUint32(query)
	if err != nil {
		slog.Warn("failed to discover physical CPU details", "query", query, "error", err)
	}
	query = "hw.perflevel1.physicalcpu"
	efficiencyCores, _ := syscall.SysctlUint32(query) // On x86 Xeon this won't return data

	query = "hw.logicalcpu"
	logicalCores, _ := syscall.SysctlUint32(query)

	return []CPU{
		{
			CoreCount:           int(perfCores + efficiencyCores),
			EfficiencyCoreCount: int(efficiencyCores),
			ThreadCount:         int(logicalCores),
		},
	}
}

// IsNUMA returns false on Darwin; NUMA support in ggml is Linux-only.
func IsNUMA() bool {
	return false
}

// ---------------------------------------------------------------------------
// AMD eGPU support — Radeon VII (gfx906) and RX 6800 (gfx1030) on Mac
// ---------------------------------------------------------------------------

// MetalDevice holds metadata about a single Metal-capable GPU device,
// including external AMD GPUs connected via Thunderbolt (eGPUs).
type MetalDevice struct {
	// Index is the zero-based device index used with GGML_METAL_DEVICE_INDEX.
	Index int

	// Name is the human-readable device name (e.g. "AMD Radeon RX 6800").
	Name string

	// MaxVRAM is the recommendedMaxWorkingSetSize reported by Metal.
	MaxVRAM uint64

	// Removable is true for externally connected GPUs (eGPUs).
	// AMD Radeon VII and RX 6800 connected via Thunderbolt will have
	// Removable == true.
	Removable bool

	// Headless is true for GPUs without a connected display.
	Headless bool

	// HasUnifiedMemory is true for Apple Silicon with unified memory.
	HasUnifiedMemory bool

	// RegistryID is the unique IORegistry identifier for the device.
	RegistryID uint64
}

// GetAllMetalDevices enumerates every Metal-capable GPU visible to the
// process, including external AMD GPUs connected via Thunderbolt (eGPUs).
// Use the returned Index values with GGML_METAL_DEVICE_INDEX / OLLAMA_METAL_DEVICE
// to direct inference to a specific device.
func GetAllMetalDevices() []MetalDevice {
	count := int(C.getMetalDeviceCount())
	devices := make([]MetalDevice, 0, count)
	for i := 0; i < count; i++ {
		info := C.getMetalDeviceInfoAtIndex(C.int(i))
		devices = append(devices, MetalDevice{
			Index:            i,
			Name:             C.GoString((*C.char)(unsafe.Pointer(&info.name[0]))),
			MaxVRAM:          uint64(info.recommended_max_vram),
			Removable:        bool(info.removable),
			Headless:         bool(info.headless),
			HasUnifiedMemory: bool(info.has_unified_memory),
			RegistryID:       uint64(info.registry_id),
		})
	}
	return devices
}

// FindExternalAMDGPUIndex returns the zero-based Metal device index of the
// first external AMD GPU (eGPU) present in the system, or -1 if none is
// found.  This covers Radeon VII (gfx906) and RX 6800 (gfx1030) attached
// via Thunderbolt.
func FindExternalAMDGPUIndex() int {
	for _, dev := range GetAllMetalDevices() {
		if dev.Removable {
			slog.Info("external Metal GPU (eGPU) detected",
				"index", dev.Index,
				"name", dev.Name,
				"vram", format.HumanBytes2(dev.MaxVRAM),
			)
			return dev.Index
		}
	}
	return -1
}

// LogMetalDevices prints a summary of all Metal-capable GPUs.  Call this
// during startup to help users identify the correct OLLAMA_METAL_DEVICE index.
func LogMetalDevices() {
	devices := GetAllMetalDevices()
	if len(devices) == 0 {
		slog.Warn("no Metal-capable GPU devices found")
		return
	}
	for _, dev := range devices {
		deviceType := "discrete"
		if dev.HasUnifiedMemory {
			deviceType = "unified"
		}
		if dev.Removable {
			deviceType = "eGPU"
		}
		slog.Info("metal device",
			"index", dev.Index,
			"name", dev.Name,
			"type", deviceType,
			"vram", format.HumanBytes2(dev.MaxVRAM),
			"removable", dev.Removable,
		)
	}
}
