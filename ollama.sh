# Force 6800 (card2) to COMPUTE power profile and max sclk so it ramps to 2475MHz under load
sudo bash -c "echo 5 > /sys/class/drm/card2/device/pp_power_profile_mode && echo 2 > /sys/class/drm/card2/device/pp_dpm_sclk" 2>/dev/null

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
export OLLAMA_CONTEXT_LENGTH=32768

export OLLAMA_DEBUG=0
export OLLAMA_FLASH_ATTENTION=true
#export OLLAMA_KV_CACHE_TYPE=q8_0
export OLLAMA_KV_CACHE_TYPE=q4_0
#unset OLLAMA_KV_CACHE_TYPE

# NEW: bias layer assignment toward Radeon VII (2x HBM2 bandwidth vs RX 6800 GDDR6).
# Format: comma-separated multipliers in GPU detection order (ROCm0, ROCm1, ...).
# With 2.0,1.0: Radeon VII effective VRAM ~30 GiB → gets ~42 layers (up from 31).
#               RX 6800 effective VRAM ~15 GiB → gets ~23 layers (down from 34).
# This balances layers/bandwidth between both GPUs → expected +30-60% decode speed.
#export OLLAMA_GPU_VRAM_WEIGHTS=1.1,1.0
#export OLLAMA_GPU_VRAM_WEIGHTS=1.25,0.58
#export OLLAMA_GPU_VRAM_WEIGHTS=0.58,1.25
#export OLLAMA_GPU_VRAM_WEIGHTS=0.58,0.75
export OLLAMA_GPU_LAYER_SPLIT=27,73
#export OLLAMA_GPU_LAYER_SPLIT=73,27


~/ollama-build/dist/bin/ollama serve


