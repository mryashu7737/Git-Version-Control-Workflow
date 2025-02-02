#!/bin/bash

# Set the region
AWS_REGION="ap-south-1"  # Asia Pacific (Mumbai)

# Fetch all network interface IDs in the region
echo "Fetching all network interfaces in region $AWS_REGION..."
network_interfaces=$(aws ec2 describe-network-interfaces --region $AWS_REGION --query "NetworkInterfaces[*].NetworkInterfaceId" --output text)

if [ -z "$network_interfaces" ]; then
  echo "No network interfaces found in region $AWS_REGION."
  exit 0
fi

echo "Found network interfaces: $network_interfaces"

# Iterate over each network interface and delete it
for interface_id in $network_interfaces; do
  echo "Deleting network interface: $interface_id"
  aws ec2 delete-network-interface --network-interface-id $interface_id --region $AWS_REGION
  if [ $? -eq 0 ]; then
    echo "Successfully deleted network interface: $interface_id"
  else
    echo "Failed to delete network interface: $interface_id. Check if it is in use or permissions."
  fi
done

echo "All network interfaces in region $AWS_REGION processed."

