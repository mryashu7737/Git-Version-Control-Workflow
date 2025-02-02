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

    # Fetch all Managed Prefix Lists owned by the caller
    prefix_list_ids=$(aws ec2 describe-managed-prefix-lists --region $region --query "PrefixLists[?IsOwnedByCaller].PrefixListId" --output text)

    if [ -z "$prefix_list_ids" ]; then
        echo "No user-defined managed prefix lists found in region $region."
    else
        echo "Found user-defined managed prefix lists in region $region: $prefix_list_ids"

        for prefix_list_id in $prefix_list_ids; do
            echo "Processing Managed Prefix List: $prefix_list_id"

            # Delete the Managed Prefix List
            aws ec2 delete-managed-prefix-list --region $region --prefix-list-id $prefix_list_id

            if [ $? -eq 0 ]; then
                echo "Successfully deleted Managed Prefix List: $prefix_list_id"
            else
                echo "Failed to delete Managed Prefix List: $prefix_list_id"
            fi
        done
    fi

    echo "---------------------------------------------"
done

echo "Script execution completed."

