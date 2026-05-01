# ollama — AMD Radeon VII / RX 6800 eGPU patch for macOS

This repository contains a custom patch for [Ollama](https://ollama.com) that enables inference acceleration on **AMD Radeon VII** (`gfx906`) and **AMD RX 6800** (`gfx1030`) GPUs connected to a Mac as **external GPUs (eGPUs)** via Thunderbolt.

---

## Background

On macOS, AMD eGPUs are Metal-capable devices.  The stock Ollama build calls
`MTLCreateSystemDefaultDevice()` which returns only the *default* (usually
internal) Metal device, so an externally connected AMD GPU is silently ignored.

This patch switches to `MTLCopyAllDevices()` to enumerate **all** Metal GPUs
and adds a new environment variable, `OLLAMA_METAL_DEVICE`, that lets you
select a specific device by its zero-based index — including the external AMD
GPU.

The device index is forwarded to the underlying llama.cpp/ggml runner as
`GGML_METAL_DEVICE_INDEX`.

---

## Supported hardware

| GPU            | Architecture | Notes                                     |
|----------------|-------------|-------------------------------------------|
| Radeon VII     | `gfx906`    | 16 GB HBM2; excellent for large models    |
| RX 6800        | `gfx1030`   | 16 GB GDDR6; strong compute throughput    |
| RX 6800 XT     | `gfx1030`   | 16 GB GDDR6                               |
| RX 6900 XT     | `gfx1030`   | 16 GB GDDR6                               |

Any other AMD eGPU that is Metal-capable and `removable == true` will also
benefit from this patch.

---

## Changed files

| File | Change |
|------|--------|
| `discover/gpu_info_darwin.h` | Add `MetalDeviceInfo` struct; declare `getMetalDeviceCount()` and `getMetalDeviceInfoAtIndex()` |
| `discover/gpu_info_darwin.m` | Implement device enumeration with `MTLCopyAllDevices()` |
| `discover/gpu_darwin.go` | Expose `GetAllMetalDevices()`, `FindExternalAMDGPUIndex()`, `LogMetalDevices()` |
| `discover/runner.go` | Call `LogMetalDevices()` at startup; forward `GGML_METAL_DEVICE_INDEX` to the llm runner; warn when an eGPU is present but unselected; add `OLLAMA_METAL_DEVICE` / `GGML_METAL_DEVICE_INDEX` to override warnings |
| `envconfig/config.go` | Add `OLLAMA_METAL_DEVICE` (`MetalDeviceIndex`) variable and include it in `AsMap()` |

---

## Quick start

### 1 — Find your eGPU index

Start Ollama with debug logging to see all Metal devices:

```bash
OLLAMA_DEBUG=1 ollama serve 2>&1 | grep -i "metal device"
```

Example output:

```
INFO metal device index=0 name="Apple M2 Pro" type=unified vram=22 GiB removable=false
INFO metal device index=1 name="AMD Radeon RX 6800" type=eGPU  vram=16 GiB removable=true
```

### 2 — Select the eGPU

```bash
export OLLAMA_METAL_DEVICE=1   # use the index shown above
ollama serve &
ollama run llama3.2
```

Or for a one-shot run:

```bash
OLLAMA_METAL_DEVICE=1 ollama run llama3.2
```

### 3 — Verify

After the model loads, check the log for:

```
INFO inference compute id=0 library=Metal name="AMD Radeon RX 6800" ...
```

---

## Applying this patch to a full Ollama source tree

```bash
# Clone the upstream Ollama repository
git clone https://github.com/ollama/ollama
cd ollama

# Copy the patched files
cp /path/to/this-repo/discover/gpu_info_darwin.h  discover/
cp /path/to/this-repo/discover/gpu_info_darwin.m  discover/
cp /path/to/this-repo/discover/gpu_darwin.go      discover/
cp /path/to/this-repo/discover/runner.go          discover/
cp /path/to/this-repo/envconfig/config.go         envconfig/

# Build
go build ./...
```

---

## How it works

### Device enumeration (`gpu_info_darwin.m`)

```objc
// Before (upstream): returns only the default/internal GPU
id<MTLDevice> device = MTLCreateSystemDefaultDevice();

// After (this patch): returns ALL Metal GPUs, including eGPUs
NSArray<id<MTLDevice>> *devices = MTLCopyAllDevices();
```

External GPUs are identified by `device.removable == true`.

### Device selection (`discover/runner.go`)

When `OLLAMA_METAL_DEVICE=<N>` is set, the runner passes
`GGML_METAL_DEVICE_INDEX=<N>` as an environment variable to the llama.cpp/ggml
Metal backend, which then targets that specific device for all Metal compute
operations.

When the variable is **not** set but an eGPU is detected, a warning is emitted:

```
WARN external AMD GPU (eGPU) detected but OLLAMA_METAL_DEVICE is not set; \
     inference will use the default Metal device  \
     hint="set OLLAMA_METAL_DEVICE=1 to use the eGPU"
```

---

## Requirements

* macOS 10.15 Catalina or later (required for `MTLCopyAllDevices`)
* Thunderbolt 3 / USB4 eGPU enclosure
* AMD Radeon VII or RX 6800 series card installed in the enclosure
* Ollama built from source with this patch applied

> **Note**: ROCm is **not** used on macOS. The AMD eGPU runs entirely via
> Apple's Metal API and the llama.cpp Metal backend. Performance and model
> compatibility are the same as any other Metal device.

---

## Troubleshooting

| Symptom | Likely cause | Fix |
|---------|--------------|-----|
| eGPU not listed by `OLLAMA_DEBUG=1` | eGPU not powered / enclosure not recognised | Reconnect enclosure; try a different Thunderbolt port |
| Inference still on internal GPU | `OLLAMA_METAL_DEVICE` not set or wrong index | Run with `OLLAMA_DEBUG=1` and check listed indices |
| `GGML_METAL_DEVICE_INDEX` ignored | Old llama.cpp build without device-index support | Build Ollama from source with this patch |
| Crash / SIGABRT on model load | Metal tensor API incompatibility | Try `GGML_METAL_TENSOR_DISABLE=1 OLLAMA_METAL_DEVICE=<N> ollama serve` |
