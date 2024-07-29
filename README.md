# Setting Up NVIDIA GPU Power Limit on Boot 

This guide provides step-by-step instructions for setting up automatic power limit configuration for NVIDIA GPUs on system boot **(Ubuntu/Fedora/etc)**. This method works for both single and multiple NVIDIA GPU setups. By following these steps, you can ensure that your GPU(s) always operate within your desired power limits, potentially reducing energy consumption and heat output without the need for manual configuration after each system restart.

## Instructions

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
   sudo nvidia-smi -pl 250
   ```

5. Create a script:
   ```
   sudo nano ~/nvidia-pl.sh
   ```
   Script content:
   ```bash
   #!/bin/bash
   sudo nvidia-smi -pm ENABLED
   sudo nvidia-smi -pl 250
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

## Note
Make sure to replace `(your_username)` and `(username)` with your actual username. Also, adjust the power limit (240W in this example) to suit your specific GPU model and requirements. You can find the acceptable range for your GPU in the output of the command in step 2.

For systems with multiple GPUs, the script in step 5 can be customized to set different power limits for each GPU. Use the `-i` flag followed by the GPU index to specify individual GPUs.

## Tnx
The author of this method is [benhaube](https://www.reddit.com/r/Fedora/comments/11lh9nn/set_nvidia_gpu_power_and_temp_limit_on_boot/)
Thanks bro!
