# NVIDIA GPU Power Limit Setup Guide

This guide provides instructions for setting up automatic power limit configuration for NVIDIA GPUs on system boot. It works for both single and multiple NVIDIA GPU setups. By following these steps, you can ensure that your GPU(s) always operate within your desired power limits, potentially reducing energy consumption and heat output without the need for manual configuration after each system restart.

We offer two methods: a manual setup process and an automatic script-based approach.

## Method 1: Manual Setup

### Instructions

1. Edit the sudoers file:
   ```
   sudo visudo
   ```
   Add the following lines:
   ```
   (your_username) ALL=(ALL) NOPASSWD: /usr/bin/nvidia-persistenced
   (your_username) ALL=(ALL) NOPASSWD: /usr/bin/nvidia-smi
   ```

2. Check current power settings:
   ```
   sudo nvidia-smi -q -d POWER
   ```

3. Enable persistence mode:
   ```
   sudo nvidia-smi -pm ENABLED
   ```

4. Set desired power limit (e.g., 240W):
   ```
   sudo nvidia-smi -pl 240
   ```

5. Create a script:
   ```
   nano ~/nvidia-pl.sh
   ```
   Script content:
   ```bash
   #!/bin/bash
   sudo nvidia-smi -pm ENABLED
   sudo nvidia-smi -pl 240
   ```
   Note: For multiple GPUs, you can add additional lines with different power limits if needed:
   ```bash
   sudo nvidia-smi -i 0 -pl 240  # Set power limit for GPU 0
   sudo nvidia-smi -i 1 -pl 200  # Set power limit for GPU 1
   # Add more lines for additional GPUs
   ```

6. Make the script executable:
   ```
   chmod +x ~/nvidia-pl.sh
   ```

7. Add a crontab task:
   ```
   crontab -e
   ```
   Add the line:
   ```
   @reboot sh /home/(username)/nvidia-pl.sh
   ```

8. Verify settings after reboot:
   ```
   sudo nvidia-smi -q -d POWER
   ```

## Method 2: Automatic Script Setup

This method simplifies the setup process by using a single script that performs all necessary steps automatically.

### Instructions

1. Save the following script as `nvidia_power_limit_setup.sh`:

```bash
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
```

2. Make the script executable:
   ```
   chmod +x nvidia_power_limit_setup.sh
   ```

3. Run the script with sudo:
   ```
   sudo ./nvidia_power_limit_setup.sh
   ```

The script will automatically set up everything needed and add itself to crontab for execution at system boot.

### Note
For both methods, make sure to replace `(your_username)` and `(username)` with your actual username. Also, adjust the power limit (240W in these examples) to suit your specific GPU model and requirements. You can find the acceptable range for your GPU in the output of the `nvidia-smi -q -d POWER` command.

For systems with multiple GPUs, you can customize the script to set different power limits for each GPU. Use the `-i` flag followed by the GPU index to specify individual GPUs.

## Tnx
The author of this (manual) method is [benhaube](https://www.reddit.com/r/Fedora/comments/11lh9nn/set_nvidia_gpu_power_and_temp_limit_on_boot/)
Thanks bro!
