#!/bin/bash

# Function to check if script is run with sudo privileges
check_sudo() {
    if [ "$EUID" -ne 0 ]; then
        echo "Please run this script with sudo."
        exit 1
    fi
}

# Function to set NVIDIA power limits
set_power_limit() {
    local power_limit=250

    # Enable persistence mode
    nvidia-smi -pm ENABLED
    echo "Persistence mode enabled."

    # Use a more reliable method to count GPUs
    local gpu_count=$(nvidia-smi --list-gpus | wc -l)
    
    # Check for two GPUs
    if [ "$gpu_count" -ne 2 ]; then
        echo "Warning: detected $gpu_count GPU(s), instead of expected 2."
    fi

    # Set power limit for each GPU separately
    nvidia-smi -i 0 -pl $power_limit
    echo "Power limit set to $power_limit W for GPU 0."
    
    # Set power limit for the second GPU if it exists
    if [ "$gpu_count" -ge 2 ]; then
        nvidia-smi -i 1 -pl $power_limit
        echo "Power limit set to $power_limit W for GPU 1."
    fi
}

# Function to check current power settings
check_power_settings() {
    echo "Current power settings:"
    nvidia-smi -q -d POWER
}

# Function to create systemd service
create_systemd_service() {
    local script_path=$(realpath $0)
    local service_file="/etc/systemd/system/nvidia-power-limit.service"
    
    echo "Creating systemd service..."
    
    # Create service file
    cat > "$service_file" << EOF
[Unit]
Description=Set NVIDIA GPU power limits
After=multi-user.target
After=nvidia-persistenced.service

[Service]
Type=oneshot
ExecStart=$script_path --apply
RemainAfterExit=true

[Install]
WantedBy=multi-user.target
EOF

    # Reload systemd configuration
    systemctl daemon-reload
    
    # Enable and start the service
    systemctl enable nvidia-power-limit.service
    systemctl start nvidia-power-limit.service
    
    echo "Systemd service successfully created and started."
}

# Main execution
if [ "$1" = "--apply" ]; then
    # This part runs when the service is started
    set_power_limit
else
    # This part runs during setup
    check_sudo
    set_power_limit
    create_systemd_service
    check_power_settings
    echo "Setup complete. Power limit will be applied at every system boot."
fi 
