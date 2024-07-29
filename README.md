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

# Function to check if the script is run with sudo
check_sudo() {
    if [ "$EUID" -ne 0 ]; then
        echo "Please run this script with sudo."
        exit 1
    fi
}

# Function to add lines to sudoers file
add_to_sudoers() {
    local user=$(whoami)
    local sudoers_file="/etc/sudoers"
    local temp_file="/tmp/sudoers.tmp"

    # Check if lines already exist in sudoers
    if ! grep -q "$user.*nvidia-persistenced" "$sudoers_file" || ! grep -q "$user.*nvidia-smi" "$sudoers_file"; then
        # Create a temporary copy of the sudoers file
        cp "$sudoers_file" "$temp_file"

        # Add the lines to the temporary file
        echo "$user ALL=(ALL) NOPASSWD: /usr/bin/nvidia-persistenced" >> "$temp_file"
        echo "$user ALL=(ALL) NOPASSWD: /usr/bin/nvidia-smi" >> "$temp_file"

        # Check if the temporary file is valid
        visudo -c -f "$temp_file"
        if [ $? -eq 0 ]; then
            # If valid, replace the sudoers file
            mv "$temp_file" "$sudoers_file"
            echo "Sudoers file updated successfully."
        else
            echo "Failed to update sudoers file. Please check and update manually."
            rm "$temp_file"
            exit 1
        fi
    else
        echo "Sudoers entries already exist."
    fi
}

# Function to set NVIDIA power limit
set_power_limit() {
    local power_limit=$1

    # Enable persistence mode
    nvidia-smi -pm ENABLED

    # Set power limit for all GPUs
    nvidia-smi -pl $power_limit

    echo "Power limit set to $power_limit watts for all GPUs."
}

# Function to create and setup cron job
setup_cron_job() {
    local script_path=$(realpath $0)
    local cron_cmd="@reboot $script_path --apply"

    # Check if cron job already exists
    if ! crontab -l | grep -q "$cron_cmd"; then
        (crontab -l 2>/dev/null; echo "$cron_cmd") | crontab -
        echo "Cron job added successfully."
    else
        echo "Cron job already exists."
    fi
}

# Main execution
if [ "$1" = "--apply" ]; then
    # This part runs at boot time
    set_power_limit 240  # Change this value to your desired power limit
else
    # This part runs when setting up
    check_sudo
    add_to_sudoers
    set_power_limit 240  # Change this value to your desired power limit
    setup_cron_job
    echo "Setup completed. Power limit will be applied on next boot."
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
