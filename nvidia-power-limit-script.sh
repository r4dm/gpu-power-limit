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
