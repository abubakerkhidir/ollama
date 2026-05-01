export HSA_IGNORE_AMD_PLATFORM_CHECK=1
export HSA_ENABLE_SDMA=0
export HIP_VISIBLE_DEVICES=0,1          # both GPUs
# REMOVE: HSA_OVERRIDE_GFX_VERSION      # was making RX 6800 use wrong kernels
export OLLAMA_LIBRARY_PATH="$HOME/ollama-build/dist/lib/ollama/rocm"
export GGML_HIP_NO_ROCBLAS=1            # bypasses rocBLAS crash on gfx906
export GGML_CUDA_FORCE_MMQ=1            # ggml MMQ kernels for both GPUs
export OLLAMA_FLASH_ATTENTION=true      # required for q8_0 KV cache
export OLLAMA_KV_CACHE_TYPE=q8_0
export OLLAMA_NUM_THREADS=6
export OLLAMA_DEBUG=2

~/ollama-build/dist/bin/ollama serve

