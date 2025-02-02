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

    # Fetch all VPCs in the region
    vpc_ids=$(aws ec2 describe-vpcs --region $region --query "Vpcs[].VpcId" --output text)

    if [ -z "$vpc_ids" ]; then
        echo "No VPCs found in region $region."
    else
        echo "Found VPCs in region $region: $vpc_ids"

        for vpc_id in $vpc_ids; do
            echo "Processing VPC: $vpc_id"

            # Step 1: Delete all related resources like Subnets, Internet Gateways, and Security Groups
            echo "Deleting subnets in VPC: $vpc_id"
            subnet_ids=$(aws ec2 describe-subnets --region $region --filters Name=vpc-id,Values=$vpc_id --query "Subnets[].SubnetId" --output text)
            for subnet_id in $subnet_ids; do
                aws ec2 delete-subnet --region $region --subnet-id $subnet_id
            done

            echo "Deleting internet gateways in VPC: $vpc_id"
            igw_ids=$(aws ec2 describe-internet-gateways --region $region --query "InternetGateways[].InternetGatewayId" --output text)
            for igw_id in $igw_ids; do
                aws ec2 detach-internet-gateway --region $region --internet-gateway-id $igw_id --vpc-id $vpc_id
                aws ec2 delete-internet-gateway --region $region --internet-gateway-id $igw_id
            done

            echo "Deleting security groups in VPC: $vpc_id"
            sg_ids=$(aws ec2 describe-security-groups --region $region --filters Name=vpc-id,Values=$vpc_id --query "SecurityGroups[].GroupId" --output text)
            for sg_id in $sg_ids; do
                aws ec2 delete-security-group --region $region --group-id $sg_id
            done

            # Step 2: Delete the VPC
            echo "Deleting VPC: $vpc_id"
            aws ec2 delete-vpc --region $region --vpc-id $vpc_id

            echo "VPC $vpc_id deleted successfully."
        done
    fi

    echo "---------------------------------------------"
done

echo "Script execution completed."

