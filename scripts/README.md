# Sample Data Scripts

This directory contains scripts for seeding sample data into your Salesforce org for demo and POC purposes.

## Available Scripts

### `apex/seed-sample-data.apex`

Creates a complete set of sample data for the Agentforce SDO Assets custom objects:

- **10 Meeting__c records**: Field representative meetings with healthcare customers
- **10 CustomerOrders__c records**: Medical device orders from healthcare facilities
- **20 Customer_Order_Line_Item__c records**: Line items for the orders (2 per order)

All data is **fictitious** and designed for a health/life sciences/med tech context, featuring:
- Medical device company field reps conducting meetings
- Healthcare facility customers (hospitals, medical centers)
- Medical device orders and shipments
- Fictitious product names (surgical instruments, patient monitoring systems, etc.)

## Usage

### Prerequisites

- Salesforce org with the Agentforce SDO Assets deployed
- System Administrator access or appropriate permissions
- Custom objects: `Meeting__c`, `CustomerOrders__c`, `Customer_Order_Line_Item__c`

### Running the Script

1. **Using Salesforce CLI**:
   ```bash
   sf apex run --file scripts/apex/seed-sample-data.apex --target-org your-org-alias
   ```

2. **Using Developer Console**:
   - Open Developer Console in your Salesforce org
   - Go to Debug > Open Execute Anonymous Window
   - Copy and paste the contents of `seed-sample-data.apex`
   - Check "Open Log" and click "Execute"

3. **Using VS Code with Salesforce Extensions**:
   - Right-click on `seed-sample-data.apex`
   - Select "SFDX: Execute Anonymous Apex"

### What the Script Does

1. **Creates Accounts** (if they don't exist):
   - 10 fictitious healthcare facility accounts
   - Examples: "Regional Medical Center", "Community Health Hospital", etc.

2. **Creates Contacts** (if they don't exist):
   - 10 fictitious healthcare professionals (doctors)
   - Linked to the accounts created above

3. **Creates Meeting Records**:
   - Field rep meetings with various statuses (Completed, Scheduled, In Progress)
   - Different meeting types (In-Person Visit, Virtual Meeting)
   - Product discussions, samples, marketing materials
   - Follow-up requirements and next steps

4. **Creates Customer Order Records**:
   - Medical device orders with order numbers and PO numbers
   - Various statuses (Shipped, Pending, In Progress, Delivered)
   - Different order types (Standard, Rush)
   - Shipping methods and delivery dates

5. **Creates Line Item Records**:
   - 2 line items per order (20 total)
   - Medical device products (surgical instruments, monitors, etc.)
   - Distribution centers and shipping addresses
   - Status tracking for fulfillment

### Output

The script provides debug output showing:
- Number of records created
- Summary of data created
- Any errors encountered

## Notes

- The script is **idempotent** - it checks for existing accounts/contacts before creating new ones
- All data is **fictitious** - no real company names or personal information
- Designed for **demo/POC environments** - not recommended for production
- The script can be run multiple times, but will create duplicate records each time

## Customization

You can modify the script to:
- Change the number of records created
- Adjust the data values (product names, statuses, etc.)
- Add additional fields or relationships
- Customize for different industries or use cases

