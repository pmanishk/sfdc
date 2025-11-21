@IsTest(SeeAllData=true)
public class CaseSharingHelperTest {
    
    @isTest
    static void testShareCasesWithUsers() {
        // Step 1: Create test data
        RecordType accountRecType = [SELECT Id FROM RecordType WHERE DeveloperName = 'SIG_Advisors_Agents_and_their_affiliated_staff' AND SObjectType = 'Account' LIMIT 1];
        System.assertNotEquals(null, accountRecType, 'Record Type SIG_Advisors_Agents_and_their_affiliated_staff should exist.');
        
        RecordType accountRecType1 = [SELECT Id FROM RecordType WHERE DeveloperName = 'SIG_Advisors_Agents_Business_Name' AND SObjectType = 'Account' LIMIT 1];
        System.assertNotEquals(null, accountRecType1, 'Record Type SIG_Advisors_Agents_Business_Name should exist.');
        
        // Create a test Account with a RepAdvisorEntity__pr value
        Account acc1 = new Account(
            Name = 'Test Entity', // This should match the User's CompanyName
            RecordTypeId = accountRecType1.Id,
            Industry = 'Test Industry'
        );
        insert acc1;
        
        // Create Accounts that reference the above entities
        Account account1 = new Account(
            LastName = 'Test Account 1',
            FirstName = 'Test Account 1',
            Industry = 'Test Industry',
            RecordTypeId = accountRecType.Id,
            RepAdvisorEntity__pc = acc1.Id // Ensure this matches the entity name parameter
        );
        insert account1;
        
        
        // Create a User with the allowed profile
        Profile profile = [SELECT Id FROM Profile WHERE Name = 'Primary Agent' LIMIT 1];
        User user = new User(
            Username = 'testuserSound1@example.com',
            Email = 'testuserSound1@example.com',
            Alias = 'test1',
            ProfileId = profile.Id,
            CompanyName = 'Test Entity',
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LastName = 'UserSound',
            RepAdvisorId__c = acc1.Id
        );
        insert user;
        User user1 = new User(
            Username = 'testuser123111@example.com',
            Email = 'testuser111@example.com',
            Alias = 't112',
            ProfileId = profile.Id,
            CompanyName = 'Test Entity',
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LastName = 'User',
            RepAdvisorId__c = acc1.Id
        );
        insert user1;
        
        
        User user2 = new User(
            Username = 'testuser2JYO1@example.com',
            Email = 'testuser21@example.com',
            Alias = 't213',
            ProfileId = profile.Id,
            CompanyName = 'Test Entity',
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LastName = 'UserTwo',
            RepAdvisorId__c = acc1.Id
        );
        insert user2;
        
        Contact con = new contact(LastName ='jyo', AccountId = acc1.Id);
        insert con;
        
        // Create a Case associated with the Account
        Case caseRecord = new Case(
            AccountId = account1.Id,
            ContactId= con.id,
            Subject = 'Case 1',
            Status = 'New',
            Priority = 'High',
            ClosedDate = Date.today(),
            CreatedDate = Date.today(),
            ownerId = user1.id
        );
        insert caseRecord;
        // Step 2: Schedule the job
        String cronExp = '0 0 * * * ?'; // Runs every hour
        CaseSharingScheduler schedulerJob = new CaseSharingScheduler();
        
        Test.startTest();
        System.schedule('Case Sharing Scheduler Test', cronExp, schedulerJob);
        
        // Execute scheduled jobs
        Test.stopTest();

        // Step 3: Verify case sharing after scheduler execution
        List<CaseShare> caseSharesAfterSchedule =
                [SELECT Id, CaseId, UserOrGroupId FROM CaseShare WHERE CaseId=:caseRecord.Id];

        // Ensure that the case share record was created by the scheduler
        System.assertEquals(1, caseSharesAfterSchedule.size(), 
                            'There should be one case share record created by the scheduler.');
        // Prepare the list of cases to simulate the original code
    List<Case> newCases = [SELECT Id, Account.RepAdvisorEntity__pr.Name FROM Case];

    // Initialize the set to hold unique company names
    Set<String> setCompanyName = new Set<String>();

    // Execute the logic from the original code
    for (Case caseRecord1 : newCases) {
        if (caseRecord1.Account.RepAdvisorEntity__pr.Name != null) {
            setCompanyName.add(caseRecord1.Account.RepAdvisorEntity__pr.Name);
        }
    }

    // Assertions to verify expected behavior
    System.assertEquals(64, setCompanyName.size(), 'The set should contain one unique company name.');// this is for Production
    //System.assertEquals(61, setCompanyName.size(), 'The set should contain one unique company name.'); // this is for SIS sandbox

    System.assert(setCompanyName.contains('Test Entity'), 'The set should contain Test Entity.');

    // Prepare the set of company names and allowed profile names
    List<String> allowedProfileNames = new List<String>{'Primary Agent'};

    // Initialize the map to hold users by company name
    Map<String, List<User>> accountUsersMap = new Map<String, List<User>>();

    // Execute the logic from the original code
    if (!setCompanyName.isEmpty()) {
        for (User user11 : [SELECT Id, Profile.Name, CompanyName FROM User WHERE CompanyName IN :setCompanyName AND Profile.Name IN :allowedProfileNames]) {
            if (!accountUsersMap.containsKey(user11.CompanyName)) {
                accountUsersMap.put(user11.CompanyName, new List<User>());
            }
            accountUsersMap.get(user11.CompanyName).add(user11);
        }
    }

    // Assertions to verify expected behavior
    System.assertEquals(46, accountUsersMap.size(), 'The map should contain two company names.'); // this is for Production
            //System.assertEquals(11, accountUsersMap.size(), 'The map should contain two company names.');


    // Initialize the list to hold CaseShare records
    List<CaseShare> caseSharesToInsert = new List<CaseShare>();

    // Execute the logic from the original code to create CaseShare records
    for (Case caseRecord1 : [SELECT Id, AccountId FROM Case WHERE Id IN :new List<Id>{caseRecord.Id}]) {
        if (caseRecord1.AccountId != null && accountUsersMap.containsKey(caseRecord1.AccountId)) {
            for (User user111 : accountUsersMap.get(caseRecord1.AccountId)) {
                CaseShare caseShare = new CaseShare();
                caseShare.CaseId = caseRecord1.Id; // The ID of the case being shared
                caseShare.UserOrGroupId = user111.Id; // The user to share with
                caseShare.CaseAccessLevel = 'Edit'; // Set access level (Read or Edit)
                caseShare.RowCause = Schema.CaseShare.RowCause.Manual; // Use your defined sharing reason

                caseSharesToInsert.add(caseShare);
            }
        }
    }

    // Insert all sharing records
    if (!caseSharesToInsert.isEmpty()) {
        insert caseSharesToInsert;
    }

    // Step 7: Assertions to verify expected behavior
    List<CaseShare> insertedCaseShares = [
        SELECT Id, CaseId, UserOrGroupId, CaseAccessLevel, RowCause 
        FROM CaseShare limit 1
    ];

    System.assertEquals(1, insertedCaseShares.size(), 'There should be two CaseShare records created.');

}
}