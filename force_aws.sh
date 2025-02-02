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

    # Fetch instances regardless of state
    instance_ids=$(aws ec2 describe-instances \
        --region $region \
        --query "Reservations[].Instances[].InstanceId" \
        --output text)

    if [ -z "$instance_ids" ]; then
        echo "No instances found in region $region."
    else
        echo "Found instances in region $region: $instance_ids"
        
        # Attempt forced termination
        for instance_id in $instance_ids; do
            echo "Attempting forced termination of instance: $instance_id"
            aws ec2 terminate-instances --region $region --instance-ids $instance_id || echo "Failed to terminate instance $instance_id."
        done
    fi

    echo "---------------------------------------------"
done

echo "Script execution completed."

