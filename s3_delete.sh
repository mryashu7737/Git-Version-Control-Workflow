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

    # Fetch all S3 buckets in the region
    bucket_names=$(aws s3api list-buckets --region $region --query "Buckets[].Name" --output text)

    if [ -z "$bucket_names" ]; then
        echo "No S3 buckets found in region $region."
    else
        echo "Found S3 buckets in region $region: $bucket_names"

        for bucket_name in $bucket_names; do
            echo "Processing bucket: $bucket_name"

            # Step 1: Delete all objects in the bucket
            echo "Deleting objects in bucket: $bucket_name"
            aws s3 rm s3://$bucket_name --recursive

            # Step 2: Delete the bucket
            echo "Deleting bucket: $bucket_name"
            aws s3api delete-bucket --bucket $bucket_name --region $region

            if [ $? -eq 0 ]; then
                echo "Successfully deleted bucket: $bucket_name"
            else
                echo "Failed to delete bucket: $bucket_name"
            fi
        done
    fi

    echo "---------------------------------------------"
done

echo "Script execution completed."

