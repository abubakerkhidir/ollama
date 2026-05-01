# --- ROCm runtime ---
export HSA_IGNORE_AMD_PLATFORM_CHECK=1
export HSA_ENABLE_SDMA=0                  # Keep: stable over Thunderbolt 3
export HIP_VISIBLE_DEVICES=0,1            # ADD: expose both GPUs
# REMOVE: HSA_OVERRIDE_GFX_VERSION        # Breaks gfx1030, not needed with proper build

# --- Ollama library ---
export OLLAMA_LIBRARY_PATH="$HOME/ollama-build/dist/lib/ollama/rocm"

# --- GPU compute ---
# REMOVE: GGML_HIP_NO_ROCBLAS=1           # Was disabling all of rocBLAS
# REMOVE: GGML_CUDA_FORCE_MMQ=1           # Was bypassing rocBLAS for quant ops

# --- Inference tuning ---
export OLLAMA_FLASH_ATTENTION=true        # ADD: required for q8_0 KV cache
export OLLAMA_KV_CACHE_TYPE=q8_0
export OLLAMA_NUM_THREADS=6
export OLLAMA_CONTEXT_LENGTH=8196
export OLLAMA_DEBUG=2

~/ollama-build/dist/bin/ollama serve

