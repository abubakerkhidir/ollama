export HSA_OVERRIDE_GFX_VERSION=9.0.6
export HSA_IGNORE_AMD_PLATFORM_CHECK=1
export HSA_ENABLE_SDMA=0
export OLLAMA_DEBUG=2
export OLLAMA_LIBRARY_PATH="$HOME/ollama-build/dist/lib/ollama/rocm"
export GGML_HIP_NO_ROCBLAS=1

export GGML_CUDA_FORCE_MMQ=1          # Force ggml's own gfx906-compiled MMQ kernels
export OLLAMA_KV_CACHE_TYPE=q8_0      # Halve KV cache bandwidth (512MB → 256MB)
export OLLAMA_NUM_THREADS=6
#export ROCBLAS_TENSILE_LIBPATH="$HOME/rocm5/extract/opt/rocm-5.7.0/lib/rocblas/library"

~/ollama-build/dist/bin/ollama serve

