#!/bin/bash

SUBNET_LIST=(
    "193.201.9.156"
    "141.98.10.125"
    "180.101.88.205"
    "185.36.228.110"
    "194.169.175.36"
    "85.209.11.227"
    "170.64.158.223"
    "218.92.0.0/16"
    "61.177.0.0/16"
    "183.81.0.0/16"
    "212.113.0.0/16"
    "185.36.0.0/16"
    "180.101.0.0/16"
    "194.169.0.0/16"
    "180.101.88.205"
    "180.101.88.197"
    # Add more subnets as needed
)

# Function to display the menu
display_menu() {
    echo "CloudRackFireWallClient (CRFW-CLI)"
    echo "1. Add an IP/Subnet to the block list"
    echo "2. Add a Domain to the block list"
    echo "3. Remove an IP/Subnet or Domain from the block list"
    echo "4. Restart and reload the script"
    echo "5. Exit"
}

# Function to add a new IP/Subnet
add_ip_subnet() {
    read -p "Enter the IP/Subnet or Domain to block: " new_entry
    echo "You entered: $new_entry"
    read -p "Are you sure you want to add this entry to the block list? (yes/no): " confirm
    if [ "$confirm" == "yes" ]; then
        SUBNET_LIST+=("$new_entry")
        echo "Added $new_entry to the block list."
    else
        echo "Did not add $new_entry to the block list."
    fi
}

# Function to remove an existing IP/Subnet or Domain from the block list
remove_entry() {
    read -p "Enter the IP/Subnet or Domain to remove from the block list: " remove_entry
    if [[ " ${SUBNET_LIST[@]} " =~ " $remove_entry " ]]; then
        SUBNET_LIST=("${SUBNET_LIST[@]/$remove_entry}")
        echo "Removed $remove_entry from the block list."
    else
        echo "$remove_entry is not in the block list."
    fi
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

    # Loop through the subnet list and remove existing rules
    for SUBNET in "${SUBNET_LIST[@]}"; do
        remove_existing_rules "$SUBNET"
    done

    # Add the iptables rules
    for SUBNET in "${SUBNET_LIST[@]}"; do
        iptables -A INPUT -s "$SUBNET" -j DROP
        echo "Blocked Subnet: $SUBNET"
    done

    # Save the iptables rules to a file
    iptables-save > /etc/iptables/rules.v4

    # Reload the iptables service to apply changes
    systemctl reload iptables

    # Display the rules
    iptables -L -v
}

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
            apply_iptables_rules
            ;;
        4)
            apply_iptables_rules
            ;;
        5)
            echo "Exiting CloudRackFireWallClient."
            exit 0
            ;;
        *)
            echo "Invalid option. Please try again."
            ;;
    esac
done
