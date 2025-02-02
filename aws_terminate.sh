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

    # Fetch all running EC2 instances in the region
    instance_ids=$(aws ec2 describe-instances \
        --region $region \
        --filters "Name=instance-state-name,Values=running" \
        --query "Reservations[].Instances[].InstanceId" \
        --output text)

    if [ -z "$instance_ids" ]; then
        echo "No running instances found in region $region."
    else
        echo "Found instances in region $region: $instance_ids"
        
        # Terminate the instances
        echo "Terminating instances in region $region..."
        aws ec2 terminate-instances --region $region --instance-ids $instance_ids

        echo "Termination initiated for instances: $instance_ids"
    fi

    echo "---------------------------------------------"
done

echo "Script execution completed."

