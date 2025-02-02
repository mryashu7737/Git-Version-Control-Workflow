#!/bin/bash

# Check if AWS CLI is installed
if ! command -v aws &> /dev/null
then
    echo "AWS CLI is not installed. Please install it and configure credentials."
    exit 1
fi

# Fetch all available AWS regions
echo "Fetching AWS regions..."
regions=$(aws ec2 describe-regions --query "Regions[].RegionName" --output text)

# Iterate through each region
for region in $regions; do
    echo "Checking region: $region"

    # Fetch all DHCP options sets
    dhcp_ids=$(aws ec2 describe-dhcp-options --region $region --query "DhcpOptions[].DhcpOptionsId" --output text)

    if [ -z "$dhcp_ids" ]; then
        echo "No DHCP options sets found in region $region."
    else
        echo "Found DHCP options sets in region $region: $dhcp_ids"

        for dhcp_id in $dhcp_ids; do
            echo "Processing DHCP Options Set: $dhcp_id"

            # Delete the DHCP options set
            aws ec2 delete-dhcp-options --region $region --dhcp-options-id $dhcp_id

            if [ $? -eq 0 ]; then
                echo "Successfully deleted DHCP Options Set: $dhcp_id"
            else
                echo "Failed to delete DHCP Options Set: $dhcp_id"
            fi
        done
    fi

    echo "---------------------------------------------"
done

echo "Script execution completed."

