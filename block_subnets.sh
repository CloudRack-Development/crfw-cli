#!/bin/bash

BLACKLIST_FILE="/etc/blacklist.txt"
WHITELIST_FILE="/etc/whitelist.txt"
FAIL2BAN_JAILS=("sshd")  # Add more jails as needed

# Function to initialize files if they don't exist
initialize_files() {
    if [ ! -f "$BLACKLIST_FILE" ]; then
        touch "$BLACKLIST_FILE"
        echo "Created $BLACKLIST_FILE."
    fi
    if [ ! -f "$WHITELIST_FILE" ]; then
        touch "$WHITELIST_FILE"
        echo "Created $WHITELIST_FILE."
    fi
}

# Function to sync existing iptables rules to files
sync_iptables_to_files() {
    echo "Syncing existing iptables rules to blacklist and whitelist files..."
    iptables-save | grep -- '-A INPUT -s' | grep -v ' -j ACCEPT' | awk '{print $4}' > $BLACKLIST_FILE
    iptables-save | grep -- '-A INPUT -s' | grep ' -j ACCEPT' | awk '{print $4}' > $WHITELIST_FILE
    echo "Sync completed."
}

# Function to display the menu
display_menu() {
    echo "CloudRackFireWallClient (CRFW-CLI)"
    echo "1. Add an IP/Subnet to the block list"
    echo "2. Add a Domain to the block list"
    echo "3. Remove an IP/Subnet or Domain from the block list"
    echo "4. Add an IP/Subnet to the allow list"
    echo "5. Remove an IP/Subnet or Domain from the allow list"
    echo "6. Sync IPs from fail2ban"
    echo "7. Apply iptables rules"
    echo "8. List current iptables rules"
    echo "9. Global reset"
    echo "10. Exit"
}

# Function to add a new IP/Subnet to the block list
add_ip_subnet() {
    read -p "Enter the IP/Subnet or Domain to block: " new_entry
    echo "You entered: $new_entry"
    read -p "Are you sure you want to add this entry to the block list? (yes/no): " confirm
    if [ "$confirm" == "yes" ]; then
        echo "$new_entry" >> $BLACKLIST_FILE
        echo "Added $new_entry to the block list."
    else
        echo "Did not add $new_entry to the block list."
    fi
}

# Function to remove an existing IP/Subnet or Domain from the block list
remove_entry() {
    echo "Select an IP/Subnet to remove from the block list:"
    mapfile -t SUBNET_LIST < $BLACKLIST_FILE
    for i in "${!SUBNET_LIST[@]}"; do
        echo "$i) ${SUBNET_LIST[$i]}"
    done
    read -p "Enter the number corresponding to the IP/Subnet you want to remove: " remove_index
    if [[ "$remove_index" =~ ^[0-9]+$ ]] && [ "$remove_index" -ge 0 ] && [ "$remove_index" -lt "${#SUBNET_LIST[@]}" ]; then
        remove_entry="${SUBNET_LIST[$remove_index]}"
        sed -i "${remove_index}d" $BLACKLIST_FILE
        echo "Removed $remove_entry from the block list."
        apply_iptables_rules
    else
        echo "Invalid selection. Please try again."
    fi
}

# Function to add a new IP/Subnet to the allow list
add_allow() {
    read -p "Enter the IP/Subnet or Domain to allow: " new_entry
    echo "You entered: $new_entry"
    read -p "Are you sure you want to add this entry to the allow list? (yes/no): " confirm
    if [ "$confirm" == "yes" ]; then
        echo "$new_entry" >> $WHITELIST_FILE
        echo "Added $new_entry to the allow list."
    else
        echo "Did not add $new_entry to the allow list."
    fi
}

# Function to remove an existing IP/Subnet or Domain from the allow list
remove_allow() {
    echo "Select an IP/Subnet to remove from the allow list:"
    mapfile -t ALLOW_LIST < $WHITELIST_FILE
    for i in "${!ALLOW_LIST[@]}"; do
        echo "$i) ${ALLOW_LIST[$i]}"
    done
    read -p "Enter the number corresponding to the IP/Subnet you want to remove: " remove_index
    if [[ "$remove_index" =~ ^[0-9]+$ ]] && [ "$remove_index" -ge 0 ] && [ "$remove_index" -lt "${#ALLOW_LIST[@]}" ]]; then
        remove_entry="${ALLOW_LIST[$remove_index]}"
        sed -i "${remove_index}d" $WHITELIST_FILE
        echo "Removed $remove_entry from the allow list."
        apply_iptables_rules
    else
        echo "Invalid selection. Please try again."
    fi
}

# Function to sync IPs from fail2ban
sync_fail2ban() {
    echo "Syncing IPs from fail2ban..."
    for jail in "${FAIL2BAN_JAILS[@]}"; do
        fail2ban-client status $jail | grep -oE '\b([0-9]{1,3}\.){3}[0-9]{1,3}\b' >> $BLACKLIST_FILE
    done
    sort -u -o $BLACKLIST_FILE $BLACKLIST_FILE
    echo "Synced IPs from fail2ban."
}

# Function to remove existing rules for a subnet
remove_existing_rules() {
    local subnet=$1
    iptables -S INPUT | grep -w "$subnet" | while read -r line; do
        rule=$(echo "$line" | sed 's/^-A/-D/')
        iptables $rule
        echo "Removed existing rule for subnet: $subnet"
    done
}

# Function to apply the iptables rules
apply_iptables_rules() {
    # Flush all existing rules
    iptables -F

    # Allow all from the allow list
    if [ -f "$WHITELIST_FILE" ]; then
        mapfile -t ALLOW_LIST < $WHITELIST_FILE
        for ALLOW in "${ALLOW_LIST[@]}"; do
            iptables -A INPUT -s "$ALLOW" -j ACCEPT
            echo "Allowed Subnet: $ALLOW"
        done
    fi

    # Block all from the block list
    if [ -f "$BLACKLIST_FILE" ]; then
        mapfile -t SUBNET_LIST < $BLACKLIST_FILE
        for SUBNET in "${SUBNET_LIST[@]}"; do
            iptables -A INPUT -s "$SUBNET" -j DROP
            echo "Blocked Subnet: $SUBNET"
        done
    fi

    # Save the iptables rules to a file
    iptables-save > /etc/iptables/rules.v4

    # Reload the iptables service to apply changes
    systemctl reload iptables

    # Display the rules
    iptables -L -v
}

# Function to list current iptables rules
list_iptables_rules() {
    iptables -L -v
}

# Function for global reset with multiple confirmations
global_reset() {
    for i in 1 2 3 4; do
        read -p "Are you absolutely sure you want to reset all IPs from iptables, blacklist, and whitelist? (yes/no): " confirm
        if [ "$confirm" != "yes" ]; then
            echo "Reset aborted."
            return
        fi
    done
    > $BLACKLIST_FILE
    > $WHITELIST_FILE
    iptables -F
    iptables-save > /etc/iptables/rules.v4
    systemctl reload iptables
    echo "All IPs have been reset from iptables, blacklist, and whitelist."
}

# Initialize blacklist and whitelist files
initialize_files

# Sync existing iptables rules to files
sync_iptables_to_files

# Main loop
while true; do
    display_menu
    read -p "Choose an option: " choice
    case $choice in
        1)
            add_ip_subnet
            ;;
        2)
            add_ip_subnet
            ;;
        3)
            remove_entry
            ;;
        4)
            add_allow
            ;;
        5)
            remove_allow
            ;;
        6)
            sync_fail2ban
            ;;
        7)
            apply_iptables_rules
            ;;
        8)
            list_iptables_rules
            ;;
        9)
            global_reset
            ;;
        10)
            echo "Exiting CloudRackFireWallClient."
            exit 0
            ;;
        *)
            echo "Invalid option. Please try again."
            ;;
    esac
done
