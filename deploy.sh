#!/bin/bash

# Agentforce SDO Assets - Deployment Script
# This script deploys all assets and assigns the critical AgentCourseSDOCustomAssetPermissions permission set

set -e  # Exit on error

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Check if org alias was provided
if [ -z "$1" ]; then
    echo -e "${RED}Error: Org alias is required${NC}"
    echo "Usage: ./deploy.sh <org-alias> [username]"
    echo "Example: ./deploy.sh myorg"
    echo "Example: ./deploy.sh myorg user@example.com"
    exit 1
fi

ORG_ALIAS=$1
USERNAME=$2

echo -e "${GREEN}🚀 Deploying Agentforce SDO Assets${NC}"
echo "Target org: $ORG_ALIAS"
echo ""

# Step 1: Deploy all metadata
echo -e "${YELLOW}Step 1: Deploying metadata...${NC}"
sf project deploy start \
    --source-dir force-app/main/default \
    --target-org "$ORG_ALIAS" \
    --wait 10

if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Deployment failed!${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Deployment successful!${NC}"
echo ""

# Step 2: Assign permission set
echo -e "${YELLOW}Step 2: Assigning AgentCourseSDOCustomAssetPermissions permission set...${NC}"

if [ -z "$USERNAME" ]; then
    # Assign to current user
    echo "Assigning to current user..."
    sf org assign permset \
        --name AgentCourseSDOCustomAssetPermissions \
        --target-org "$ORG_ALIAS"
else
    # Assign to specific user
    echo "Assigning to user: $USERNAME"
    sf org assign permset \
        --name AgentCourseSDOCustomAssetPermissions \
        --on-behalf-of "$USERNAME" \
        --target-org "$ORG_ALIAS"
fi

if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Permission set assignment failed!${NC}"
    echo -e "${YELLOW}You may need to assign it manually via Setup → Permission Sets → Agentforce SDO Custom Asset Permissions${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Permission set assigned!${NC}"
echo ""

# Step 3: Verify
echo -e "${YELLOW}Step 3: Verifying deployment...${NC}"

# Check if we can query the permission set
sf data query \
    --query "SELECT Id, Name FROM PermissionSet WHERE Name = 'AgentCourseSDOCustomAssetPermissions' LIMIT 1" \
    --target-org "$ORG_ALIAS" \
    --json > /dev/null 2>&1

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Verification successful!${NC}"
else
    echo -e "${YELLOW}⚠️  Could not verify permission set (this is okay if you don't have query permissions)${NC}"
fi

echo ""
echo -e "${GREEN}🎉 Deployment complete!${NC}"
echo ""
echo "Next steps:"
echo "1. Go to Setup → Agentforce Agents"
echo "2. Create or edit your agent"
echo "3. Add the deployed actions to your agent's action library"
echo ""
echo -e "${YELLOW}⚠️  Important: Make sure the AgentCourseSDOCustomAssetPermissions permission set is assigned to any users who will use Agentforce!${NC}"

