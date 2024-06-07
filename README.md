# CloudRackFireWallClient (CRFW-CLI) Installation Guide

## Step 1: Download the Script
Download the CRFW-CLI script to your server.

Fixing line endings without dos2unix: You can manually convert the line endings using a tool like sed. Try running the following command:
```sh
wget -O block_subnets.sh https://fw.cloudrack.ca/block_subnets.sh && sed -i 's/\r//' block_subnets.sh
```
This command will replace all instances of carriage return (\r) characters, which are typical of Windows line endings, with Unix line endings.

## Step 2: Make the Script Executable
Change the permissions of the script to make it executable.
```sh
chmod +x block_subnets.sh
```

## Step 3: Run the Script
Execute the script with superuser privileges.
```sh
sudo ./block_subnets.sh
```

## Step 4: Adding an Alias (Optional)
You can create an alias for the script to simplify running it. Edit the `.bashrc` or `.bash_profile` file and add the following line:
```sh
alias crfw-cli="sudo ./block_subnets.sh"
```
Save the file and apply the changes by running:
```sh
source ~/.bashrc
```
Now you can simply type `crfw-cli` to run the script.

## Step 5: Initializing the Script
To initialize the script, run the following command:
```sh 
crfw-cli init
```
This will bring up the CloudRackFireWallClient (CRFW-CLI) script, allowing you to interactively manage the IP blocking rules.

## Step 6: Setting up as a Daemon (Optional)
If you want to run the CRFW-CLI script as a daemon to ensure it starts automatically and runs in the background, follow these steps:

1. Create a systemd service file for CRFW-CLI. For example, create a file named `iptables.service` in `/etc/systemd/system/` directory.
2. Add the following content to the service file:
```sh
[Unit]
Description=Restore iptables rules
After=network.target

[Service]
Type=oneshot
ExecStart=/usr/sbin/iptables-restore /etc/iptables/rules.v4
ExecReload=/usr/sbin/iptables-restore /etc/iptables/rules.v4
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
```
3. Reload systemd to read the new service file:
```sh
sudo systemctl daemon-reload
```
4. Enable the service to start on boot:
```sh
sudo systemctl enable iptables.service
```
5. Start the service:
```sh
sudo systemctl start iptables.service
```
The CRFW-CLI script will now run as a daemon, ensuring it starts automatically on system boot and runs in the background.
