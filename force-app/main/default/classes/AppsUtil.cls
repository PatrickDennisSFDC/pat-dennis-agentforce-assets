global with sharing class AppsUtil {
  // Use this method to create a standard Map inline rather than 4+ lines of code
  public static Map<String, Object> createMap(String n, Object v) {
    return new Map<string, Object>{
            'name' => n,
            'value' => v
    };
  }

  public static Map<String,Object> hasTasksEventsHistory() {
    boolean errorFlag = false;
    Integer errorNum = 1;
    List<task> taskCount;
    List<event> eventCount;
    Integer countOfTasks;
    Integer countOfHistory;
    Integer countOfEvents;
    List<string> errorMessages = new List<string>();
    //Check for Tasks and Events linked to Oppty
    //Due to Data sizes Task and Event Query may time out. First check to see if there are any records (limit 2) This may fail if there too many tasks and events. If it fails we should proceede and assume they have something attached to opportunities.
    //Must have at least 1 task connected to an opty
    try {
      taskCount = Database.Query('SELECT id FROM task limit 1');
      if (taskCount.isEmpty()) {
        countOfTasks = 0;
        errorMessages.add('Tableau CRM requires at least one task record to exist. Create any task, then come back and finish the app creation process.');
        errorFlag = true;
      }
    }
    catch (Exception e) {
      //really big orgs may fail on this query - incase they do let's assume they have tasks
      countOfTasks = 1;
    }

    //must have at least 1 event connected to an oppty
    try {
      eventCount = Database.Query('SELECT id FROM event limit 1');
      if (eventCount.isEmpty()) {
        countOfEvents = 0;
        errorMessages.add('Tableau CRM requires at least one event record to exist. Create any event, then come back and finish the app creation process.');
        errorFlag = true;
      }
    }
    catch (Exception e) {
      //really big orgs may fail on this query - incase they do let's assume they have tasks
      countOfEvents = 1;
    }

    //Check for History - have at least one opportunity with 2 closed dates and stage change
    try {
      List<OpportunityHistory> historyCount = Database.Query('SELECT id FROM OpportunityHistory limit 2');
      if (historyCount.isEmpty()) {
        countOfHistory = 0;
        errorMessages.add('Tableau CRM requires at least three opportunity history records. If this is a Sandbox where historical data was not copied, some Tableau CRM dashboards may be incomplete. Go to any Opportunity record, update the stage name, update the amount and update the close date. Then come back and finish the app creation process.');
        errorFlag = true;
      }
    }
    catch (Exception e) {
      //really big orgs may fail on this query - incase they do let's assume they have tasks
      countOfHistory = 2;
    }

    // return the result
    if (errorFlag) {
      // return the error message
      return new Map<String, Object>{
              'success' => false,
              'messages' => errorMessages
      };
    }

    // everything alright
    // no variable settings here
    return new Map<String, Object>{
            'success' => true,
            'messages' => new List<String>{
              'Your org meets the minimum requirements for creating the app. It has at least 1 account, opportunity, task, and event records as well as 3 opportunity history rows.'
            }
    };
  }

  public static List<List<String>> getInitialMessages2d() {
    return new List<List<String>>{
            new List<String>(),
            new List<String>()
    };
  }

  public static Map<String, Object> hasManagerAndRolesSales() {
    List<Object> variableSettings = new List<Object>();
    String message;
    try {
      Integer RoleCount = 0;

      //Check for users with roles that have role parents
      RoleCount = Database.countQuery('SELECT count() FROM User WHERE userrole.parentRoleID != null');

      Integer ManagerCount = 0;

      //Check to see if users have user managers populated
      ManagerCount = Database.countQuery('SELECT count() FROM User WHERE ManagerId != null');
      if (ManagerCount > 0) {
        //Customer is using the User Manager feature so let's include this field
        variableSettings.add(createMap('Has_Managers_Sales', 'Yes'));
        message = 'Tableau CRM has detected that this org uses Manager Hierarchy ';
      } else {
        message = 'Tableau CRM has detected that this org doesn\'t use Manager Hierarchy ';
      }
      if (RoleCount > 0) {
        //Customer is using role hierarchy, so let's use it!!
        variableSettings.add(createMap('UsingRoleHierarchySales', 'Yes'));
        message += 'and uses Role Hierarchy.';
      } else {
        //Customer is not using Roles at all so we must remove it from Wave
        variableSettings.add(createMap('UsingRoleHierarchySales', 'No'));

        //Since there are no roles, we can't really use a security predicate
        variableSettings.add(new Map<string, Object>{
              'name' => 'Has_SecurityPredicate',
              'value' => 'Option 3: Users view all data',
              'eventName' => 'wizard.computed'
            });

        //Since we can't do a security predicate, there is no reason we should include these questions
        variableSettings.add(createMap('Has_SecurityPredicate_Visible', 'Disabled'));
        variableSettings.add(createMap('Has_AccountTeams_Visible', 'Hidden'));
        variableSettings.add(new Map<string, Object>{
              'name' => 'Has_OpportunityTeams',
              'value' => 'Hidden',
              'eventName' => 'wizard.computed'
            });
        message += 'and doesn\'t use Role Hierarchy.';
      }
    }
    catch (Exception e) {
      // fallback do nothing
    }
    return new Map<String, Object>{
            'success' => true,
            'variableSettings' => variableSettings,
            'messages' => new List<String>{message}
    };
  }

  public static Map<String, Object> hasManagerAndRolesNonSales() {
    List<Object> variableSettings = new List<Object>();
    String message;
    try {
      Integer RoleCount = 0;

      //Check for users with roles that have role parents
      RoleCount = Database.countQuery('SELECT count() FROM User WHERE userrole.parentRoleID != null');

      /* Disable User Manager For now in Tableau CRM
        Integer ManagerCount = 0;

        //Check to see if users have user managers populated
        ManagerCount = Database.countQuery('SELECT count() FROM User WHERE ManagerId != null');
        if(ManagerCount > 0)
        {
        //Customer is using the User Manager feature so let's include this field
        variableSettings.add(new Map<string, object>{
          'name' => 'Has_Managers_Sales',
          'value' => 'Yes'
        });
        message = 'Tableau CRM has detected that this org uses Manager Hierarchy ';
        } else {
        message = 'Tableau CRM has detected that this org doesn\'t use Manager Hierarchy ';
        }
      */
      if (RoleCount > 0) {
        //Customer is using role hierarchy, so let's use it!!
        variableSettings.add(new Map<string, object>{
              'name' => 'Has_RoleHiearchy',
              'value' => true
            });
        message = 'Uses standard Role Hierarchy.';
      } else {
        //Customer is not using Roles at all so we must remove it from Wave
        variableSettings.add(new Map<string, object>{
              'name' => 'Has_RoleHiearchy',
              'value' => false
            });

        message = 'Does not use standard Role Hierarchy.';
      }
    }
    catch (Exception e) {
      // fallback do nothing
    }
    return new Map<String, Object>{
            'success' => true,
            'variableSettings' => variableSettings,
            'messages' => new List<String>{message}
    };
  }

  /*****2.Method to Autoscan and set fiscal******/
  public static Map<String, Object> getOrgFiscalMonth() {
    List<Object> variableSettings = new List<Object>();
    String offset;
    try {
      Integer months = [SELECT
      FiscalYearStartMonth
      FROM
      Organization].FiscalYearStartMonth;

      Map<Integer, string> a = new Map<Integer, string>{
        1 => '01 - January',
        2 => '02 - February',
        3 => '03 - March',
        4 => '04 - April',
        5 => '05 - May',
        6 => '06 - June',
        7 => '07 - July',
        8 => '08 - August',
        9 => '09 - September',
        10 => '10 - October',
        11 => '11 - November',
        12 => '12 - December'
      };
      String monthOffset = a.get(months);

      variableSettings.add(createMap('Fiscal_Month', monthOffset));
      offset = monthOffset;
      // set description? No.
      // template.getVariables().get('Fiscal_Month').setDescription('Wave has selected the month based on your Salesforce settings but you may override this value. If it is different than January, you also need to update the Quota dataset JSON file.');
    }
    catch (Exception e) {
      //just in case
      variableSettings.add(createMap('Fiscal_Month', '01 - January'));
      offset = '01 - January';
    }
    return new Map<String, Object>{
            'success' => true,
            'variableSettings' => variableSettings,
            'messages' => new List<String> {'Fiscal month is set to ' + offset.substring(5) + ', '}
    };
  }

  /**
  * public method to get and assign the firstDayOfWeek
  */
  public static Map<String, Object>  getOrgFirstDayOfWeek() {
    List<Object> variableSettings = new List<Object>();

    //initialize Map with Locales and their Start Days
    Map<String, Integer> localeMap = new Map<String, Integer>();
    localeMap = Locale.getLocaleMap();
    Integer firstday;
    String firstdayName;
    List<String> dayNames = new List<String>{'Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'};

    //Check if Context User is an Integration User and get their Locale
    String contextUserType = UserInfo.getUserType();

    if (contextUserType == 'Analytics Cloud Integration User') {
      String contextUserLocale = UserInfo.getLocale();
      system.debug('This is the Integration User' + contextUserLocale);
      firstday = localeMap.get(contextUserLocale);
      system.debug(firstday);
    }
    //Else just get the current Organizations Locale
    else {
      Organization org = [SELECT DefaultLocaleSidKey FROM Organization];
      String contextOrgLocale = org.DefaultLocaleSidKey;
      system.debug('This is the Org ' + contextOrgLocale);
      firstday = localeMap.get(contextOrgLocale);
      system.debug(firstday);
    }

    if (firstday != null) {
      //Assign Start Day to First_Day_Of_Week variable in variables.json
      variableSettings.add(createMap('First_Day_Of_Week', firstday));
      firstdayName = dayNames[firstday];
    } else {
      //If the locale doesnt exist in the map, then set the variable to 0 by default.
      variableSettings.add(createMap('First_Day_Of_Week', 0));
      firstdayName = dayNames[0];
    }

    return new Map<String, Object>{
            'success' => true,
            'variableSettings' => variableSettings,
            'messages' => new List<String>{'first day of week to ' + firstdayName + '. '},
            'mergeWithPrevious' => true
    };
  }

  /**
  * public method to initialize the Locale Mapping
  * @returns Map<String, Integer>
  */

  /*****4.Method to verfiy account and opportunity teams *****/
  public static Map<String, Object> hasTeams() {
    List<Object> variableSettings = new List<Object>();
    List<List<String>> messages2d = getInitialMessages2d();

    Integer count = 0;
    /*returns a map of all SObject names to sObject tokens( values) for standard and custom objects */
    //see if an accountteam member is present, if not, Account teams are not enabled
    Schema.SObjectType targetType = Schema.getGlobalDescribe().get('AccountTeamMember');
    Schema.SObjectType targetType1 = Schema.getGlobalDescribe().get('OpportunityTeamMember');
    if (targetType != null) {
      string query = 'Select count() from AccountTeamMember limit 1';
      count = database.countQuery(query);
    }
    if (targetType == null || count == 0) {
      variableSettings.add(createMap('Has_AccountTeams_Visible', 'Hidden'));
      messages2d[1].add('Account Teams');
    } else {
      messages2d[0].add('Account Teams');
    }
    if (targetType1 != null) {
      string query1 = 'Select count() from OpportunityTeamMember limit 1';
      count = database.countQuery(query1);
    }
    if (targetType1 == null || count == 0) {
      variableSettings.add(createMap('Has_OpportunityTeams_Visible', 'Hidden'));
      messages2d[1].add('Opportunity Teams');
    } else {
      messages2d[0].add('Opportunity Teams');
    }
    return new Map<String, Object>{
            'success' => true,
            'variableSettings' => variableSettings,
            'messages2d' => messages2d
    };
  }

  /******5.Method to verify other objects on the wizard ******/
  public static Map<String, Object> hasCases(List<Object> selectedValues) {
    List<List<String>> messages2d = getInitialMessages2d();
    // where to put the message: 0 - has, 1 - doesn't have
    Integer i2d = 1;

    List<Object> variableSettings = new List<Object>();
    Schema.SObjectType targetType = Schema.getGlobalDescribe().get('Case');
    if (targetType != null) {
      try {
        Integer count = Database.countQuery('SELECT count() FROM Case where accountId != null Limit 1000');
        if (count == 0) {
          // set default - no cases
          // not now
          variableSettings.add(createMap('Has_Cases_Visible', 'Disabled'));
        } else if (count < 10) {
          //Maybe they have some cases, but not very many - we should recommend they answer no
          variableSettings.add(createMap('Has_Cases_Visible', 'Visible'));
          i2d = 0;
        } else {
          // set default to has cases - we do this always now
          selectedValues.add('Cases');
          variableSettings.add(createMap('Has_Cases_Visible', 'Visible'));
          i2d = 0;
        }
      }
      catch (Exception e) {
      }
    } else {
      variableSettings.add(createMap('Has_Cases_Visible', 'Disabled'));
    }
    messages2d[i2d].add('Cases');
    return new Map<String, Object>{
            'success' => true,
            'variableSettings' => variableSettings,
            'messages2d' => messages2d
    };
  }

  public static Map<String, Object> hasCampaigns() {
    List<List<String>> messages2d = getInitialMessages2d();
    // where to put the message: 0 - has, 1 - doesn't have
    Integer i2d = 1;

    List<Object> variableSettings = new List<Object>();
    Schema.SObjectType targetType = Schema.getGlobalDescribe().get('Campaign');
    if (targetType != null) {
      try {
        Integer count = Database.countQuery('SELECT count() FROM  Campaign WHERE NumberOfOpportunities > 0 Limit 100');
        if (count == 0) {
          // set campaigns to no
          variableSettings.add(createMap('Has_Campaigns_Visible', 'Disabled'));
        } else if (count < 10) {
          // Maybe they have some campaigns, but not very many - we should recommend they answer no
          variableSettings.add(createMap('Has_Campaigns_Visible', 'Visible'));
          i2d = 0;
        } else {
          // set campaigns to yes
          variableSettings.add(createMap('Has_Campaigns_Visible', 'Visible'));
          i2d = 0;
        }
      }
      catch (Exception e) {
      }
    } else {
      variableSettings.add(createMap('Has_Campaigns_Visible', 'Disabled'));
    }
    messages2d[i2d].add('Campaigns');
    return new Map<String, Object>{
            'success' => true,
            'variableSettings' => variableSettings,
            'messages2d' => messages2d
    };
  }

  public static Map<String, Object> getUserCurrency() {
    return new Map<String, Object>{
            'success' => true,
            'variableSettings' => new List<Object>(),
            'messages' => new List<String>{'and currency to ' + System.UserInfo.getDefaultCurrency() + '. Tableau CRM made these selections based on your Salesforce settings.'},
            'mergeWithPrevious' => true
    };
  }

  public static Map<String, Object> canUseParentAccount() {
    List<Object> variableSettings = new List<Object>();
    String message;
    try {
      // check if there is at least one account with a parent
      List<Account> accountWithParent = Database.query('SELECT ParentId FROM Account WHERE ParentId != null LIMIT 1');
      if (!accountWithParent.isEmpty()) {
        system.debug('There is at least one account with a parent');
        variableSettings.add(new Map<string, Object>{
              'name' => 'UsingAccountHierarchy',
              'value' => 'Yes',
              'eventName' => 'wizard.computed'
            });
        message = 'There is at least one account with a parent.';
      } else {
        // Hide AccountHierarchy question from wizard
        variableSettings.add(createMap('Has_AccountHierarchy_Visible', 'Hidden'));
        message = 'There is no account with a parent.';
      }
    }
    catch (Exception e) {
    }

    return new Map<String, Object>{
            'success' => true,
            'variableSettings' => variableSettings,
            'messages' => new List<String>{message}
    };
  }

  public static Map<String, Object> aggregateResults(List<Map<String, Object>> resultList) {
    Boolean allGood = true;
    List<Map<String, Object>> variableSettings = new List<Map<String, Object>>();
    List<String> messages = new List<String>();
    List<List<String>> messages2d = new List<List<String>>();

    // iterate over the results
    for (Map<String, Object> result: resultList) {
      // if one failed all failed
      if (!((boolean)result.get('success'))) {
        allGood = false;
      }

      // aggregate the variable settings
      if (result.containsKey('variableSettings')) {
        for (Object s: (List<Object>)result.get('variableSettings')) {
          variableSettings.add((Map<String, Object>)s);
        }
      }

      // and messages
      if (result.containsKey('messages')) {
        List<String> addedMessages = (List<String>)result.get('messages');
        if (result.containsKey('mergeWithPrevious')) {
          messages[messages.size() - 1] += addedMessages[0];
        } else {
          messages.addAll(addedMessages);
        }
      }

      // and array of array of messages
      if (result.containsKey('messages2d')) {
        List<Object> resultMessages = (List<Object>)result.get('messages2d');
        // for each array in 2d array
        for (Integer i = 0; i < resultMessages.size(); i++) {
          // incoming array bigger than what we have
          if ((i + 1) > messages2d.size()) {
            messages2d.add(new List<String>());
          }
          messages2d[i].addAll((List<String>)resultMessages[i]);
        }
      }
    }

    // flatten the messages2d into messages
    for (Integer i = 0; i < messages2d.size(); i++) {
      List<String> messageList = messages2d[i];
      messages.addAll((List<String>)messageList);
      if (i < messages2d.size() - 1) {
        // space between the lists - not for the last
        messages.add('');
      }
    }

    // aggregate the messages and variable settings
    return new Map<String, Object>{
            'success' => allGood,
            'messages' => messages,
            'variableSettings' => variableSettings
    };
  }

  public static Map<String, Object> chooseAdditionalsObjects(List<Object> selectedValues) {
    List<String> messages = new List<String>();
    List<Object> variableSettings = new List<Object>();

    variableSettings.add(new Map<string, Object>{
          'name' => 'SObjectChoices',
          'value' => selectedValues,
          'eventName' => 'wizard.computed'
        });

    return new Map<String, Object>{
            'success' => true,
            'messages' => messages,
            'variableSettings' => variableSettings
    };
  }
}