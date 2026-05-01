#!/bin/bash

export HSA_IGNORE_AMD_PLATFORM_CHECK=1
export HIP_VISIBLE_DEVICES=0,1
export HSA_ENABLE_SDMA=0

# ROCm 7 supports gfx1030 natively — no HSA_OVERRIDE needed
# Keep NO_ROCBLAS since gfx906 (Radeon VII) has no Tensile kernels
export GGML_HIP_NO_ROCBLAS=1

# Ollama settings
export OLLAMA_LIBRARY_PATH=~/ollama-build/dist/lib/ollama:~/ollama-build/dist/lib/ollama/rocm
export OLLAMA_NUM_THREADS=6
export OLLAMA_HOST=0.0.0.0
export OLLAMA_CONTEXT_LENGTH=4096
export OLLAMA_DEBUG=2
export OLLAMA_FLASH_ATTENTION=true
export OLLAMA_KV_CACHE_TYPE=q8_0
export OLLAMA_LOAD_TIMEOUT=5m   # increased from 5m for first-time kernel setup

~/ollama-build/dist/bin/ollama serve
