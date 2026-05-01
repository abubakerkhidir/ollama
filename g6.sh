#!/bin/bash
# Optimized ROCm inference: Radeon VII (gfx906, HBM2 1024GB/s) + RX 6800 (gfx1030, GDDR6 512GB/s)
#
# Key changes vs previous working script:
#   - GGML_HIP_NO_ROCBLAS removed: rocBLAS bypass is now automatic per-device (gfx906 only)
#   - OLLAMA_GPU_VRAM_WEIGHTS=2.0,1.0: gives Radeon VII 2x layer weight (matches HBM2 vs GDDR6 ratio)
#     Detection order: ROCm0=Radeon VII (device 0), ROCm1=RX 6800 (device 1)
#   - OLLAMA_CONTEXT_LENGTH=16384: now safe to increase (HSA_OVERRIDE hang is fixed)
#
# Requires rebuilding the binary after the source changes in:
#   ml/backend/ggml/ggml/src/ggml-cuda/common.cuh    (per-device rocBLAS bypass)
#   ml/backend/ggml/ggml/src/ggml-cuda/ggml-cuda.cu  (per-device batched GEMM guard)
#   envconfig/config.go                               (GpuVramWeights func)
#   llm/server.go                                     (apply weights in buildLayout)

export HSA_IGNORE_AMD_PLATFORM_CHECK=1
export HIP_VISIBLE_DEVICES=0,1
export HSA_ENABLE_SDMA=0

# REMOVED: GGML_HIP_NO_ROCBLAS=1 — rocBLAS is now auto-bypassed for gfx906 only.
# RX 6800 (gfx1030) will now use its rocBLAS Tensile kernels → faster prefill.

export OLLAMA_LIBRARY_PATH=~/ollama-build/dist/lib/ollama:~/ollama-build/dist/lib/ollama/rocm
export OLLAMA_NUM_THREADS=6
export OLLAMA_HOST=0.0.0.0
export OLLAMA_LOAD_TIMEOUT=5m

# CHANGED: increased from 4096 — safe now that HSA_OVERRIDE hang is fixed.
# 16384 uses ~2 GiB extra VRAM (q8_0 KV). 32768 uses ~6 GiB extra.
export OLLAMA_CONTEXT_LENGTH=16384

export OLLAMA_DEBUG=2
export OLLAMA_FLASH_ATTENTION=true
export OLLAMA_KV_CACHE_TYPE=q8_0

# NEW: bias layer assignment toward Radeon VII (2x HBM2 bandwidth vs RX 6800 GDDR6).
# Format: comma-separated multipliers in GPU detection order (ROCm0, ROCm1, ...).
# With 2.0,1.0: Radeon VII effective VRAM ~30 GiB → gets ~42 layers (up from 31).
#               RX 6800 effective VRAM ~15 GiB → gets ~23 layers (down from 34).
# This balances layers/bandwidth between both GPUs → expected +30-60% decode speed.
export OLLAMA_GPU_VRAM_WEIGHTS=2.0,1.0

~/ollama-build/dist/bin/ollama serve

