// ============================================================================
// Agentforce SDO Assets - Sample Data Seeding Script
// ============================================================================
// This script creates sample data for demo/POC purposes:
// - 10 Meeting__c records (field rep meetings with healthcare customers)
// - 10 CustomerOrders__c records (medical device orders)
// - 20 Customer_Order_Line_Item__c records (2 per order)
//
// All data is fictitious and designed for health/life sciences/med tech context.
// ============================================================================

// First, ensure we have some Accounts and Contacts to work with
// Create fictitious healthcare facility accounts if they don't exist
List<Account> accounts = new List<Account>();
List<String> accountNames = new List<String>{
    'Regional Medical Center',
    'Community Health Hospital',
    'Metropolitan Healthcare System',
    'Valley Medical Group',
    'Coastal Health Network',
    'Mountain View Hospital',
    'Riverside Medical Center',
    'Sunset Healthcare Facility',
    'Oakwood Medical Group',
    'Pine Grove Hospital'
};

Map<String, Account> accountMap = new Map<String, Account>();
for (Account acc : [SELECT Id, Name FROM Account WHERE Name IN :accountNames LIMIT 20]) {
    accountMap.put(acc.Name, acc);
}

for (String accName : accountNames) {
    if (!accountMap.containsKey(accName)) {
        accounts.add(new Account(
            Name = accName,
            Industry = 'Healthcare',
            Type = 'Customer',
            BillingCity = 'San Francisco',
            BillingState = 'CA',
            Phone = '415-555-0100'
        ));
    }
}

if (!accounts.isEmpty()) {
    insert accounts;
    System.debug('✅ Created ' + accounts.size() + ' Account records');
    for (Account acc : accounts) {
        accountMap.put(acc.Name, acc);
    }
}

// Get all accounts (existing + newly created)
List<Account> allAccounts = [SELECT Id, Name FROM Account WHERE Name IN :accountNames LIMIT 20];
if (allAccounts.isEmpty()) {
    System.debug('❌ ERROR: No accounts available. Please create accounts first.');
    return;
}

// Create Contacts for the accounts
List<Contact> contacts = new List<Contact>();
List<String> contactNames = new List<String>{
    'Dr. Sarah Chen',
    'Dr. Michael Rodriguez',
    'Dr. Jennifer Park',
    'Dr. Robert Thompson',
    'Dr. Lisa Anderson',
    'Dr. James Wilson',
    'Dr. Maria Garcia',
    'Dr. David Lee',
    'Dr. Emily Martinez',
    'Dr. Christopher Brown'
};

Map<String, Contact> contactMap = new Map<String, Contact>();
for (Contact con : [SELECT Id, Name, AccountId FROM Contact WHERE Name IN :contactNames LIMIT 20]) {
    contactMap.put(con.Name, con);
}

Integer accountIndex = 0;
for (String conName : contactNames) {
    if (!contactMap.containsKey(conName) && accountIndex < allAccounts.size()) {
        contacts.add(new Contact(
            FirstName = conName.split(' ')[1],
            LastName = conName.split(' ')[2],
            AccountId = allAccounts[accountIndex].Id,
            Title = 'Chief Medical Officer',
            Email = conName.split(' ')[1].toLowerCase() + '.' + conName.split(' ')[2].toLowerCase() + '@healthcare.com',
            Phone = '415-555-' + String.valueOf(1000 + accountIndex)
        ));
        accountIndex++;
    }
}

if (!contacts.isEmpty()) {
    insert contacts;
    System.debug('✅ Created ' + contacts.size() + ' Contact records');
    for (Contact con : contacts) {
        contactMap.put(con.FirstName + ' ' + con.LastName, con);
    }
}

// Get all contacts
List<Contact> allContacts = [SELECT Id, Name, AccountId FROM Contact WHERE Name IN :contactNames OR (FirstName + ' ' + LastName) IN :contactNames LIMIT 20];
if (allContacts.isEmpty()) {
    System.debug('❌ ERROR: No contacts available.');
    return;
}

// ============================================================================
// CREATE 10 MEETING RECORDS
// ============================================================================
List<Meeting__c> meetings = new List<Meeting__c>();
List<String> meetingSubjects = new List<String>{
    'Q1 Product Portfolio Review',
    'Surgical Device Demonstration',
    'Patient Monitoring System Discussion',
    'New Product Launch Presentation',
    'Clinical Trial Partnership Meeting',
    'Equipment Maintenance Training',
    'Regulatory Compliance Review',
    'Product Customization Requirements',
    'Annual Contract Renewal Discussion',
    'Emergency Equipment Procurement'
};

List<String> meetingTypes = new List<String>{
    'In-Person Visit',
    'Virtual Meeting',
    'In-Person Visit',
    'In-Person Visit',
    'Virtual Meeting',
    'In-Person Visit',
    'Virtual Meeting',
    'In-Person Visit',
    'In-Person Visit',
    'Virtual Meeting'
};

List<String> meetingStatuses = new List<String>{
    'Completed',
    'Scheduled',
    'Completed',
    'Completed',
    'Scheduled',
    'Completed',
    'Completed',
    'In Progress',
    'Scheduled',
    'Completed'
};

List<String> meetingOutcomes = new List<String>{
    'Positive - Follow-up Required',
    '',
    'Product Interest Expressed',
    'Contract Discussion Initiated',
    'Partnership Agreement Reached',
    'Training Completed Successfully',
    'Compliance Requirements Clarified',
    'Customization Specifications Defined',
    '',
    'Emergency Order Placed'
};

Date baseDate = Date.today();
Integer contactIndex = 0;

for (Integer i = 0; i < 10; i++) {
    Contact con = allContacts[Math.mod(contactIndex, allContacts.size())];
    Account acc = null;
    for (Account a : allAccounts) {
        if (a.Id == con.AccountId) {
            acc = a;
            break;
        }
    }
    if (acc == null) acc = allAccounts[0];
    
    meetings.add(new Meeting__c(
        Subject__c = meetingSubjects[i],
        Meeting_Date__c = baseDate.addDays(-(10 - i)),
        Meeting_Type__c = meetingTypes[i],
        Meeting_Status__c = meetingStatuses[i],
        Meeting_Outcome__c = meetingOutcomes[i],
        Account__c = acc.Id,
        Contact__c = con.Id,
        Description__c = 'Field representative meeting with ' + con.Name + ' at ' + acc.Name + ' to discuss ' + meetingSubjects[i].toLowerCase() + '.',
        Attendees_Count__c = 2 + Math.mod(i, 4),
        Product_Discussed__c = 'Surgical Instruments, Patient Monitoring Systems',
        Samples_Dropped_Off__c = (Math.mod(i, 3) == 0),
        Marketing_Materials_Provided__c = (Math.mod(i, 2) == 0),
        Follow_Up_Required__c = (i < 5),
        Signature_Obtained__c = (Math.mod(i, 4) == 0),
        Next_Steps__c = (i < 5) ? 'Schedule follow-up meeting in 2 weeks to review proposal.' : ''
    ));
    contactIndex++;
}

try {
    insert meetings;
    System.debug('✅ Created ' + meetings.size() + ' Meeting records');
} catch (Exception e) {
    System.debug('❌ ERROR creating Meetings: ' + e.getMessage());
}

// ============================================================================
// CREATE 10 CUSTOMER ORDER RECORDS
// ============================================================================
List<CustomerOrders__c> orders = new List<CustomerOrders__c>();
List<String> orderNumbers = new List<String>{
    'ORD-2024-001',
    'ORD-2024-002',
    'ORD-2024-003',
    'ORD-2024-004',
    'ORD-2024-005',
    'ORD-2024-006',
    'ORD-2024-007',
    'ORD-2024-008',
    'ORD-2024-009',
    'ORD-2024-010'
};

List<String> poNumbers = new List<String>{
    'PO-HC-2401',
    'PO-HC-2402',
    'PO-HC-2403',
    'PO-HC-2404',
    'PO-HC-2405',
    'PO-HC-2406',
    'PO-HC-2407',
    'PO-HC-2408',
    'PO-HC-2409',
    'PO-HC-2410'
};

List<String> orderStatuses = new List<String>{
    'Shipped',
    'Pending',
    'In Progress',
    'Shipped',
    'Delivered',
    'Pending',
    'In Progress',
    'Shipped',
    'Pending',
    'Delivered'
};

List<String> orderTypes = new List<String>{
    'Standard',
    'Rush',
    'Standard',
    'Standard',
    'Rush',
    'Standard',
    'Standard',
    'Standard',
    'Rush',
    'Standard'
};

List<String> shippingMethods = new List<String>{
    'Ground',
    'Express',
    'Ground',
    'Overnight',
    'Express',
    'Ground',
    'Ground',
    'Overnight',
    'Express',
    'Ground'
};

List<String> priorities = new List<String>{
    'Normal',
    'High',
    'Normal',
    'Normal',
    'High',
    'Normal',
    'Normal',
    'Normal',
    'High',
    'Normal'
};

contactIndex = 0;
for (Integer i = 0; i < 10; i++) {
    Contact con = allContacts[Math.mod(contactIndex, allContacts.size())];
    Account acc = null;
    for (Account a : allAccounts) {
        if (a.Id == con.AccountId) {
            acc = a;
            break;
        }
    }
    if (acc == null) acc = allAccounts[0];
    
    Decimal orderTotal = 50000 + (i * 7500) + (Math.mod(i, 3) * 2500);
    Date orderDate = baseDate.addDays(-(15 - i));
    Date deliveryDate = orderDate.addDays(7 + Math.mod(i, 5));
    Date shipDate = orderDate.addDays(2 + Math.mod(i, 3));
    
    orders.add(new CustomerOrders__c(
        Name = orderNumbers[i],
        Order_Number__c = orderNumbers[i],
        PO_Number__c = poNumbers[i],
        Account__c = acc.Id,
        Contact__c = con.Id,
        Order_Date__c = orderDate,
        Order_Type__c = orderTypes[i],
        Status__c = orderStatuses[i],
        Priority__c = priorities[i],
        Shipping_Method__c = shippingMethods[i],
        Requested_Delivery_Date__c = deliveryDate,
        Scheduled_Shipment_Date__c = shipDate,
        Order_Total__c = orderTotal,
        Temperature_Controlled__c = (Math.mod(i, 3) == 0),
        Address__c = acc.BillingCity + ', ' + acc.BillingState,
        Order_Notes__c = 'Medical device order for ' + acc.Name + '. Contact: ' + con.Name + '.'
    ));
    contactIndex++;
}

try {
    insert orders;
    System.debug('✅ Created ' + orders.size() + ' Customer Order records');
} catch (Exception e) {
    System.debug('❌ ERROR creating Orders: ' + e.getMessage());
    return;
}

// ============================================================================
// CREATE 20 CUSTOMER ORDER LINE ITEM RECORDS (2 per order)
// ============================================================================
List<Customer_Order_Line_Item__c> lineItems = new List<Customer_Order_Line_Item__c>();

List<String> productNames = new List<String>{
    'Surgical Forceps Set - Premium',
    'Patient Monitor - Wireless',
    'Sterilization Equipment - Autoclave',
    'Surgical Scissors - Precision',
    'IV Pump System - Programmable',
    'Defibrillator - Portable',
    'Surgical Lights - LED',
    'Anesthesia Machine - Advanced',
    'Ultrasound Scanner - Portable',
    'X-Ray Machine - Digital',
    'Endoscope - Flexible',
    'Surgical Table - Electric',
    'Ventilator - ICU Grade',
    'Blood Pressure Monitor - Automated',
    'Surgical Drapes - Sterile',
    'Surgical Gloves - Nitrile',
    'Surgical Masks - N95',
    'Surgical Gowns - Disposable',
    'Surgical Instruments - Basic Set',
    'Surgical Instruments - Advanced Set'
};

List<String> skus = new List<String>{
    'MD-SF-PREM-001',
    'MD-PM-WIRE-002',
    'MD-SE-AUTO-003',
    'MD-SS-PREC-004',
    'MD-IV-PROG-005',
    'MD-DEF-PORT-006',
    'MD-SL-LED-007',
    'MD-AM-ADV-008',
    'MD-US-PORT-009',
    'MD-XR-DIG-010',
    'MD-EN-FLEX-011',
    'MD-ST-ELEC-012',
    'MD-VT-ICU-013',
    'MD-BP-AUTO-014',
    'MD-SD-STER-015',
    'MD-SG-NIT-016',
    'MD-SM-N95-017',
    'MD-SG-DISP-018',
    'MD-SI-BASIC-019',
    'MD-SI-ADV-020'
};

List<String> lineItemStatuses = new List<String>{
    'Shipped',
    'Pending',
    'In Progress',
    'Shipped',
    'Delivered',
    'Pending',
    'In Progress',
    'Shipped',
    'Pending',
    'Delivered',
    'Shipped',
    'Pending',
    'In Progress',
    'Shipped',
    'Delivered',
    'Pending',
    'In Progress',
    'Shipped',
    'Pending',
    'Delivered'
};

List<String> distributionCenters = new List<String>{
    'Central Distribution Hub - Midwest',
    'Regional Fulfillment Center - West',
    'Primary Distribution Facility - East',
    'Secondary Distribution Center - South',
    'Main Warehouse - Northeast',
    'Regional Distribution - Northwest',
    'Central Fulfillment - Southeast',
    'Primary Warehouse - Southwest',
    'Secondary Hub - Mid-Atlantic',
    'Regional Center - Pacific'
};

List<String> shippingAddresses = new List<String>{
    '123 Medical Center Drive\nSuite 200\nSan Francisco, CA 94102',
    '456 Healthcare Boulevard\nBuilding A\nLos Angeles, CA 90012',
    '789 Hospital Way\nFloor 3\nChicago, IL 60601',
    '321 Clinic Street\nUnit 150\nHouston, TX 77001',
    '654 Medical Plaza\nOffice 300\nPhoenix, AZ 85001',
    '987 Health Center Road\nSuite 100\nPhiladelphia, PA 19101',
    '147 Medical Park Drive\nBuilding B\nSan Antonio, TX 78201',
    '258 Healthcare Avenue\nFloor 2\nSan Diego, CA 92101',
    '369 Hospital Circle\nUnit 250\nDallas, TX 75201',
    '741 Medical Boulevard\nOffice 400\nSan Jose, CA 95101'
};

Integer productIndex = 0;
Integer dcIndex = 0;
Integer addressIndex = 0;

for (Integer i = 0; i < orders.size(); i++) {
    CustomerOrders__c order = orders[i];
    
    // Create 2 line items per order
    for (Integer j = 0; j < 2; j++) {
        Decimal unitPrice = 500 + (productIndex * 250) + (Math.mod(productIndex, 5) * 100);
        Integer quantity = 1 + Math.mod(productIndex, 5);
        Decimal total = unitPrice * quantity;
        
        lineItems.add(new Customer_Order_Line_Item__c(
            Customer_Order__c = order.Id,
            Product_Name__c = productNames[productIndex],
            SKU__c = skus[productIndex],
            Quantity__c = quantity,
            Unit_Price__c = unitPrice,
            Total__c = total,
            Status__c = lineItemStatuses[productIndex],
            Distribution_Center__c = distributionCenters[Math.mod(dcIndex, distributionCenters.size())],
            Shipping_Address__c = shippingAddresses[Math.mod(addressIndex, shippingAddresses.size())],
            Fulfillment_Notes__c = 'Standard fulfillment process. Product requires temperature-controlled storage: ' + (Math.mod(productIndex, 3) == 0 ? 'Yes' : 'No') + '.'
        ));
        
        productIndex++;
        dcIndex++;
        addressIndex++;
    }
}

try {
    insert lineItems;
    System.debug('✅ Created ' + lineItems.size() + ' Customer Order Line Item records');
    
    // Summary
    System.debug('\n📊 SAMPLE DATA SEEDING COMPLETE');
    System.debug('================================');
    System.debug('✅ Accounts: ' + allAccounts.size() + ' (existing or created)');
    System.debug('✅ Contacts: ' + allContacts.size() + ' (existing or created)');
    System.debug('✅ Meetings: ' + meetings.size());
    System.debug('✅ Customer Orders: ' + orders.size());
    System.debug('✅ Line Items: ' + lineItems.size());
    System.debug('\n🎉 All sample data has been successfully created!');
    
} catch (Exception e) {
    System.debug('❌ ERROR creating Line Items: ' + e.getMessage());
}

