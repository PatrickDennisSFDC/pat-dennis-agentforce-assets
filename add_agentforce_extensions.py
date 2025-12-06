#!/usr/bin/env python3
"""
Helper script to add x-sfdc extensions to VS Code generated OpenAPI YAML files
Run this after generating OpenAPI specs with the VS Code extension
"""

import yaml
import sys
import os

# Agentforce extensions for each resource
EXTENSIONS = {
    'AccountResource': {
        'x-sfdc': {
            'topics': [
                {
                    'name': 'Account Management',
                    'description': 'Operations for managing Account records in Salesforce',
                    'instructions': 'Use this API when the user wants to find, create, update, or delete accounts. When multiple accounts match a search, ask the user for additional details like city or industry to narrow down the selection.'
                }
            ],
            'agentInstructions': {
                'get': 'When retrieving accounts, if multiple matches are found, present all options and ask the user to provide more details (like city or industry) to narrow down the selection.',
                'post': 'When creating an account, ensure the Name field is provided. If the user doesn\'t specify other fields, you can ask for optional information like Industry or Billing City.',
                'put': 'When updating an account, if the user doesn\'t specify what to update, return the current account data and ask which fields they want to change.',
                'delete': 'Confirm with the user before deleting an account, as this action cannot be undone.'
            }
        }
    },
    'ContactResource': {
        'x-sfdc': {
            'topics': [
                {
                    'name': 'Contact Management',
                    'description': 'Operations for managing Contact records in Salesforce',
                    'instructions': 'Use this API when the user wants to find, create, update, or delete contacts. When creating a contact with an accountName, if the Account doesn\'t exist, ask the user the questions required to create that Account (Name is required, Industry and BillingCity are optional). When multiple contacts match a search, ask for additional details like email or account name to narrow down.'
                }
            ],
            'agentInstructions': {
                'get': 'When retrieving contacts, if multiple matches are found, present all options and ask the user to provide more details (like email or account name) to narrow down the selection.',
                'post': 'When creating a contact, ensure LastName is provided. If accountName is specified but the Account doesn\'t exist, ask the user the questions needed to create that Account (Name required, Industry and BillingCity optional).',
                'put': 'When updating a contact, if the user doesn\'t specify what to update, return the current contact data and ask which fields they want to change.',
                'delete': 'Confirm with the user before deleting a contact, as this action cannot be undone.'
            }
        }
    },
    'CaseResource': {
        'x-sfdc': {
            'topics': [
                {
                    'name': 'Case Management',
                    'description': 'Operations for managing Case records in Salesforce',
                    'instructions': 'Use this API when the user wants to find, create, update, or delete cases. When creating a case with accountName or contactNameOrEmail, if those records don\'t exist, ask the user the questions required to create them. When multiple cases match a search, ask for additional details like status or account name to narrow down.'
                }
            ],
            'agentInstructions': {
                'get': 'When retrieving cases, if multiple matches are found, present all options and ask the user to provide more details (like status or account name) to narrow down the selection.',
                'post': 'When creating a case, ensure Subject is provided. If accountName or contactNameOrEmail is specified but those records don\'t exist, ask the user the questions needed to create them (Account: Name required, Industry and BillingCity optional; Contact: LastName required, Email optional).',
                'put': 'When updating a case, if the user doesn\'t specify what to update, return the current case data and ask which fields they want to change.',
                'delete': 'Confirm with the user before deleting a case, as this action cannot be undone.'
            }
        }
    }
}

def add_extensions_to_yaml(file_path, resource_name):
    """Add x-sfdc extensions to a YAML file"""
    if resource_name not in EXTENSIONS:
        print(f"Warning: No extensions defined for {resource_name}")
        return False
    
    try:
        # Read the YAML file
        with open(file_path, 'r') as f:
            data = yaml.safe_load(f)
        
        # Add the extensions
        data.update(EXTENSIONS[resource_name])
        
        # Write back to file
        with open(file_path, 'w') as f:
            yaml.dump(data, f, default_flow_style=False, sort_keys=False, allow_unicode=True)
        
        print(f"✓ Added x-sfdc extensions to {file_path}")
        return True
    except Exception as e:
        print(f"✗ Error processing {file_path}: {e}")
        return False

def main():
    base_dir = 'force-app/main/default/externalServicesRegistrations'
    
    if not os.path.exists(base_dir):
        print(f"Error: Directory {base_dir} does not exist")
        sys.exit(1)
    
    resources = ['AccountResource', 'ContactResource', 'CaseResource']
    success_count = 0
    
    print("Adding Agentforce extensions to OpenAPI YAML files...")
    print()
    
    for resource in resources:
        yaml_file = os.path.join(base_dir, f'{resource}.yaml')
        
        if not os.path.exists(yaml_file):
            print(f"⚠ Warning: {yaml_file} not found. Make sure you've generated it using the VS Code extension.")
            continue
        
        if add_extensions_to_yaml(yaml_file, resource):
            success_count += 1
    
    print()
    if success_count == len(resources):
        print(f"✓ Successfully added extensions to all {success_count} files!")
        print("You can now deploy the OpenAPI specs to your org.")
    else:
        print(f"⚠ Processed {success_count} out of {len(resources)} files.")
        print("Make sure all YAML files have been generated using the VS Code extension first.")

if __name__ == '__main__':
    main()





