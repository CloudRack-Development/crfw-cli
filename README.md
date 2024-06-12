# VirtCloudPro & CloudRackFireWallClient (CRFW-CLI)

![image (2) (1)](https://github.com/CloudRack-Development/crfw-cli/assets/170158299/b786abbf-f01d-4cc2-9b1e-8bee3d06a53c)

![CloudRackFireWallClient](https://github.com/CloudRack-Development/crfw-cli/assets/170158299/db2e11d0-241a-4494-8457-e1193ad44579)



## Overview

The **VirtCloudPro CloudRackFireWallClient (CRFW-CLI)** is a powerful and user-friendly script designed to manage IP blocking and allowing rules using `iptables`. It integrates seamlessly with `fail2ban` to dynamically block malicious IPs and works in conjunction with VirtFusion for enhanced security.

## Features

- **Manage IP Blocking Rules**: Easily add or remove IPs/subnets from block and allow lists.
- **Integration with fail2ban**: Automatically syncs banned IPs from fail2ban jails to the block list.
- **VirtFusion Compatibility**: Works hand in hand with VirtFusion to secure your virtual environments.
- **ASN Blocking**: Block IP ranges associated with specific ASNs.
- **Dynamic Updates**: Reads the latest changes from `blacklist.txt`, `whitelist.txt`, and `asn_blacklist.txt` files and applies them.
- **Deduplication**: Ensures no duplicate entries in the blacklist and whitelist files.
- **Interactive Menu**: User-friendly CLI menu for managing firewall rules.
- **Utilizes bgpq3**: Blocking ASN utilizing [BGP](https://github.com/snar/bgpq3) please note if you block many ASN's you maybe stuck waiting anywhere from 5minutes to 30minutes+ for full ASN ban to be applied 
(this is based off our one asn block ourselfs).
## Installation Guide

### Step 1: Download the Script

Download the CRFW-CLI script to your server.

```bash
sudo yum install bgpq3 -y
wget -O block_subnets.sh https://fw.cloudrack.ca/block_subnets.sh
sed -i 's/\r//' block_subnets.sh
```

### Step 2: Make the Script Executable

Change the permissions of the script to make it executable.

```bash
chmod +x block_subnets.sh
```

### Step 3: Run the Script

Execute the script with superuser privileges.

```bash
sudo ./block_subnets.sh
```

### Step 4: Adding an Alias (Optional)

Create an alias for the script to simplify running it. Edit the `.bashrc` or `.bash_profile` file and add the following line:

```bash
alias crfw-cli="sudo ./block_subnets.sh"
```

Save the file and apply the changes by running:

```bash
source ~/.bashrc
```

Now you can simply type `crfw-cli` to run the script.

### Step 5: Initializing the Script

To initialize the script, run the following command:

```bash
crfw-cli init
```

This will bring up the CloudRackFireWallClient (CRFW-CLI) script, allowing you to interactively manage the IP blocking rules.

### Step 6: Setting up as a Daemon (Optional)

If you want to run the CRFW-CLI script as a daemon, follow these steps:

1. Create a systemd service file for CRFW-CLI. For example, create a file named `iptables.service` in `/etc/systemd/system/` directory.
2. Add the following content to the service file:

    ```ini
    [Unit]
    Description=CloudRackFireWallClient (CRFW-CLI) Daemon
    After=network.target

    [Service]
    Type=simple
    ExecStart=/path/to/block_subnets.sh daemon
    Restart=always

    [Install]
    WantedBy=multi-user.target
    ```

    Replace `/path/to/block_subnets.sh` with the actual path to your CRFW-CLI script.

3. Reload systemd to read the new service file:

    ```bash
    sudo systemctl daemon-reload
    ```

4. Enable the service to start on boot:

    ```bash
    sudo systemctl enable iptables.service
    ```

5. Start the service:

    ```bash
    sudo systemctl start iptables.service
    ```

The CRFW-CLI script will now run as a daemon, ensuring it starts automatically on system boot and runs in the background.

## Usage Guide

### Interactive Menu

The script provides an interactive CLI menu for managing IP blocking and allowing rules. Run the script and choose from the following options:

1. **Add an IP/Subnet to the block list**: Block a specific IP or subnet.
2. **Add a Domain to the block list**: Block a specific domain.
3. **Remove an IP/Subnet or Domain from the block list**: Remove a specific IP or subnet from the block list.
4. **Add an IP/Subnet to the allow list**: Allow a specific IP or subnet.
5. **Remove an IP/Subnet or Domain from the allow list**: Remove a specific IP or subnet from the allow list.
6. **Sync IPs from fail2ban**: Automatically sync IPs banned by fail2ban jails to the block list.
7. **Apply iptables rules**: Apply the current block and allow lists to `iptables`.
8. **List current iptables rules**: Display the current `iptables` rules.
9. **Block an ASN**: Block IP ranges associated with a specific ASN.
10. **Remove an ASN from the block list**: Remove a specific ASN from the block list.
11. **Global reset**: Reset all IPs from `iptables`, blacklist, and whitelist (requires multiple confirmations).
12. **Exit**: Exit the script.

### Integration with fail2ban

The script integrates with `fail2ban` to dynamically update the block list with IPs banned by fail2ban jails. This enhances the security of your system by automatically blocking known malicious IPs.

### ASN Blocking

The script allows you to block IP ranges associated with specific Autonomous System Numbers (ASNs). This is useful for blocking large ranges of IPs managed by organizations known to be a source of malicious traffic.

### Dynamic Updates and Deduplication

The `apply_iptables_rules` function reads the latest content from the `blacklist.txt`, `whitelist.txt`, and `asn_blacklist.txt` files each time it is called, ensuring that any manual changes to these files are recognized and applied. It also removes duplicate entries before applying the rules.

## Contribution

Contributions are welcome! If you have any suggestions, improvements, or bug fixes, feel free to open an issue or submit a pull request.

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for more details.

## Support

For support and further information, visit our [website](https://cloudrack.ca) or join our community.

---

Crafted with ❤️ by the CloudRack & VirtCloudPro team(s).
