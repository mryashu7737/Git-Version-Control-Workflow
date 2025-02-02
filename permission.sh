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

    # Fetch all instances in the region
    instance_ids=$(aws ec2 describe-instances \
        --region $region \
        --query "Reservations[].Instances[].InstanceId" \
        --output text)

    if [ -z "$instance_ids" ]; then
        echo "No instances found in region $region."
    else
        echo "Found instances in region $region: $instance_ids"

        for instance_id in $instance_ids; do
            echo "Processing instance: $instance_id"

            # Step 1: Forcefully disable API termination protection
            echo "Disabling termination protection for instance: $instance_id"
            aws ec2 modify-instance-attribute --region $region --instance-id $instance_id --no-disable-api-termination

            # Verify the change
            termination_protection=$(aws ec2 describe-instance-attribute \
                --region $region \
                --instance-id $instance_id \
                --attribute disableApiTermination \
                --query "DisableApiTermination.Value" \
                --output text)

            if [ "$termination_protection" == "true" ]; then
                echo "Failed to disable termination protection for instance: $instance_id. Skipping."
                continue
            else
                echo "Termination protection successfully disabled for instance: $instance_id."
            fi

            # Step 2: Detach any IAM instance profiles
            echo "Detaching IAM instance profile for instance: $instance_id (if any)"
            instance_profile=$(aws ec2 describe-instances \
                --region $region \
                --instance-ids $instance_id \
                --query "Reservations[].Instances[].IamInstanceProfile.AssociationId" \
                --output text)

            if [ "$instance_profile" != "None" ] && [ -n "$instance_profile" ]; then
                aws ec2 disassociate-iam-instance-profile --region $region --association-id $instance_profile
                echo "Detached IAM instance profile from instance: $instance_id."
            fi

            # Step 3: Attempt to terminate the instance
            echo "Attempting to terminate instance: $instance_id"
            aws ec2 terminate-instances --region $region --instance-ids $instance_id

            # Step 4: Verify termination
            instance_state=$(aws ec2 describe-instances \
                --region $region \
                --instance-ids $instance_id \
                --query "Reservations[].Instances[].State.Name" \
                --output text)

            if [ "$instance_state" == "shutting-down" ] || [ "$instance_state" == "terminated" ]; then
                echo "Successfully terminated instance: $instance_id."
            else
                echo "Failed to terminate instance: $instance_id. Retrying..."
            fi
        done
    fi

    echo "---------------------------------------------"
done

echo "Script execution completed."

