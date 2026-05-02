sudo systemctl disable amdgpu-compute-profile.service

Actual file:
vi /etc/systemd/system/amdgpu-compute-profile.service

[Unit]
Description=Set AMD RX 6800 to COMPUTE power profile
After=multi-user.target

[Service]
Type=oneshot
ExecStart=/bin/bash -c "echo 5 > /sys/class/drm/card2/device/pp_power_profile_mode && echo 2 > /sys/class/drm/card2/device/pp_dpm_sclk"
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
