//go:build darwin

package discover

import (
	"log/slog"
	"strconv"

	"github.com/ollama/ollama/envconfig"
)

// logAndPrepareMetalEnvs enumerates all Metal-capable GPUs at startup, logs
// them for diagnostic purposes, and emits a hint when an external AMD eGPU is
// detected but OLLAMA_METAL_DEVICE has not been set.
//
// This function is called once during the GPU bootstrap phase on macOS.
func logAndPrepareMetalEnvs() {
	LogMetalDevices()

	envs := metalDeviceEnvs()
	for k, v := range envs {
		slog.Info("applying Metal device override", "env", k, "value", v)
	}
}

// metalDeviceEnvs returns a map of environment variables to forward to the
// llm runner subprocess for Metal device selection on macOS.
//
// When OLLAMA_METAL_DEVICE is set, it is mapped to GGML_METAL_DEVICE_INDEX
// so that the ggml/llama.cpp Metal backend targets the specified GPU (e.g. an
// external AMD Radeon VII or RX 6800 connected via Thunderbolt).
//
// When OLLAMA_METAL_DEVICE is not set and an external AMD eGPU is detected,
// a hint is logged but the default device is left unchanged to preserve
// existing behaviour.
func metalDeviceEnvs() map[string]string {
	envs := map[string]string{}

	// Explicit user override takes priority.
	if idx := envconfig.MetalDeviceIndex(); idx != "" {
		envs["GGML_METAL_DEVICE_INDEX"] = idx
		return envs
	}

	// Auto-detect: log a helpful hint if an eGPU is present but not yet
	// selected.  We do not auto-select because the default device may be
	// intentional (e.g. when benchmarking internal vs external GPU).
	if eGPUIdx := FindExternalAMDGPUIndex(); eGPUIdx >= 0 {
		slog.Warn(
			"external AMD GPU (eGPU) detected but OLLAMA_METAL_DEVICE is not set; "+
				"inference will use the default Metal device",
			"hint", "set OLLAMA_METAL_DEVICE="+strconv.Itoa(eGPUIdx)+" to use the eGPU",
		)
	}

	return envs
}
