@IsTest(SeeAllData=true)
public class GenerateDocuSignTest {

    public static Profile systemAdminProfile = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1];
    public static Profile primaryAgentProfile = [SELECT Id FROM Profile WHERE Name = 'Primary Agent' LIMIT 1];

   @IsTest
    static void setup() {
        // Create test users
        User testUser = new User(
            Username = 'testuser_' + System.currentTimeMillis() + '@example.com',
            Email = 'testuser@example.com',
            Alias = 'tuser',
            LastName = 'Test User',
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            isActive =true,
            ProfileId = systemAdminProfile.Id,
            Advisor_Type__c='',
            CompanyName='Sound Income Strategies LLC' // This should match the entity name in the Account (acc1)
        );
        insert testUser;
        
        User testUser1 = new User(
            Username = 'testuser_' + System.currentTimeMillis() + '@example.com',
            Email = 'testuser@example.com',
            Alias = 'tuser',
            LastName = 'Test User',
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            isActive =true,
            ProfileId = primaryAgentProfile.Id,
            Advisor_Type__c ='RIA',
            CompanyName='Sound Income Group' // This should match the entity name in the Account (acc1)
        );
        insert testUser1;


        // Create test dfsle__EnvelopeConfiguration__c records
        dfsle__EnvelopeConfiguration__c templateEsign = new dfsle__EnvelopeConfiguration__c(
            Name = 'Test E-Sign Template',
            dfsle__DocuSignId__c = 'esign123'
        );

        dfsle__EnvelopeConfiguration__c templateInPerson = new dfsle__EnvelopeConfiguration__c(
            Name = 'Test In-Person Template',
            dfsle__DocuSignId__c = 'inperson456'
        );

        insert new List<dfsle__EnvelopeConfiguration__c>{ templateEsign, templateInPerson };

        // Step 1: Ensure a RecordType exists
        RecordType accountRecType = [SELECT Id FROM RecordType WHERE DeveloperName = 'SIG_Advisors_Agents_and_their_affiliated_staff' AND SObjectType = 'Account' and IsPersonType = true  LIMIT 1];
        System.assertNotEquals(null, accountRecType, 'Record Type SIG_Advisors_Agents_and_their_affiliated_staff should exist.');
        
        RecordType accountRecType1 = [SELECT Id FROM RecordType WHERE DeveloperName = 'IndustriesHousehold' AND SObjectType = 'Account' and IsPersonType = false LIMIT 1];
        System.assertNotEquals(null, accountRecType1, 'Record Type IndustriesHousehold should exist.');
        
        // Create a test Account with a RepAdvisorEntity__pc value
        Account testHousehold = new Account(
            Name = 'TestEntity', 
            RecordTypeId = accountRecType1.Id, // Ensure this record type is valid for the user profile
            Industry = 'Engineering',
            SIS_Advisor_Affiliation__c='Sub-Advisor',
            RIA_Firm__c ='TestEntity',
            HHCurrentCash__c =5000,
            HHCurrentMktVal__c = 5000
        );
        insert testHousehold;
        
        RecordType accountRecType2 = [SELECT Id FROM RecordType WHERE DeveloperName = 'SIG_Advisors_Agents_Business_Name' AND SObjectType = 'Account' and IsPersonType = false LIMIT 1];
        System.assertNotEquals(null, accountRecType2, 'Record Type SIG_Advisors_Agents_Business_Name should exist.');
        // Create a test Account with a RepAdvisorEntity__pr value
        Account acc2 = new Account(
            Name = 'Sound Income Group TEST', // This should match the User's CompanyName
            RecordTypeId = accountRecType2.Id,
            Industry = 'Test Industry TEST',
            HHCurrentCash__c =5000,
            HHCurrentMktVal__c = 5000
        );
        insert acc2;
        
        // Create Accounts that reference the above entities
        Account account1 = new Account(
            LastName = 'Test Account 1',
            FirstName = 'Test Account 1',
            Industry = 'Test Industry',
            RecordTypeId = accountRecType.Id, // Ensure this record type is valid for the user profile
            RepAdvisorEntity__pc = testHousehold.Id // Ensure this matches the entityName parameter
        );
        insert account1;
        
        Account account2 = new Account(
            LastName = 'Test Account 2',
            FirstName = 'Test Account 2',
            Industry = 'Test Industry',
            RecordTypeId = accountRecType.Id, // Ensure this record type is valid for the user profile
            RepAdvisorEntity__pc = acc2.Id // Ensure this matches the entityName parameter
        );
        insert account2;
        
        Contact con = new Contact(
            LastName = 'Test Contact 2',
            FirstName = 'Test Contact 2',
            RepAdvisorEntity__c = account1.Id // Ensure this matches the entityName parameter
        );
        insert con;        
        
        EAST_RepID__c repIDManagedTrue = new EAST_RepID__c(Name='Managed True', Unique_Name__c ='Managed True', Custodian__c='Fidelity', Managed__c=true, Primary_Rep_User__c=testUser.Id, Total_AUM__c =3.00);
        EAST_RepID__c repIDManagedFalse = new EAST_RepID__c(Name='Managed False', Unique_Name__c ='Managed False', Custodian__c='Schwab', Managed__c=false, Primary_Rep_User__c=testUser.Id, Total_AUM__c = 3.00);
        
        insert new List<EAST_RepID__c> { repIDManagedTrue, repIDManagedFalse };
            
            // Create Financial Account
            FinServ__FinancialAccount__c testFinAcc1 = new FinServ__FinancialAccount__c(
                Name = 'Test Financial Account',
                FinServ__PrimaryOwner__c = acc2.Id,
                FinServ__JointOwner__c = account1.Id,
                FinServ__Household__c = testHousehold.Id,
                RepAdvisor__c = con.id,
                RepIDLink__c = repIDManagedFalse.id,
                RepID__c = repIDManagedFalse.Name,
                FinServ__Balance__c =5000
            );
        insert testFinAcc1;	
    }

    @isTest
    static void testAdminUserWithFinancialAccounts() {
        setup();
        User testUser = [SELECT Id FROM User WHERE ProfileId = :systemAdminProfile.Id and isActive =true  and Advisor_Type__c ='' LIMIT 1];
        Account testHousehold = [SELECT Id FROM Account LIMIT 1];
        FinServ__FinancialAccount__c testFinAcc = [SELECT Id FROM FinServ__FinancialAccount__c LIMIT 1];
        dfsle__EnvelopeConfiguration__c template = [SELECT Id FROM dfsle__EnvelopeConfiguration__c WHERE Name = 'Test E-Sign Template' LIMIT 1];

        System.runAs(testUser) {
            Test.startTest();
            // Mock the PageReference
            PageReference pageRef = Page.GenerateDocuSign;
            Test.setCurrentPage(pageRef);
            ApexPages.currentPage().getParameters().put('id', testHousehold.Id);

            GenerateDocuSign controller = new GenerateDocuSign();

            // Verify initial state
            System.assertEquals('block', controller.displayFinAccList, 'Fin Acc list should be visible');
            System.assertEquals('none', controller.displayRadioButtons, 'Radio buttons should be hidden initially');
            System.assertEquals('none', controller.displayGenDoc, 'Generate Doc button should be hidden initially');
            System.assertNotEquals(null, controller.financialAccountOptions, 'Financial Account Options should be initialized');
            System.assertEquals(14, controller.financialAccountOptions.size(), 'Should be 2 financial account options');

            // Simulate selecting a financial account
            controller.selectedFinancialAccountId = testFinAcc.Id;
            controller.finAccSelect();

            System.assertEquals('block', controller.displayGenDoc, 'Generate Doc button should be visible after selection');

            // Test viewEnvelopes
            controller.viewEnvelopes(testFinAcc.Id);
            System.assertEquals(2, controller.getItems().size(), 'Should have 2 signature options');
            // Test E-Sign Selection
            controller.signatures = 'E-Sign';
            controller.updateSelectList();
            System.assertNotEquals(0, controller.options.size(), 'E-Sign options should be populated');
			controller.refresh();
            
            // Test In-Person Selection
            controller.signatures = 'In-Person';
            controller.updateSelectList();
            System.assertNotEquals(0, controller.options.size(), 'In-Person options should be populated');

            // Test Navigate
            controller.selectedOption = template.Id;
            PageReference resultPageRef = controller.navigate();
            System.assertNotEquals(null, resultPageRef, 'Navigation should return a PageReference');

            // Test Refresh
            controller.refresh();
            Test.stopTest();
        }
    }

    @isTest
    static void testAdminUserNoFinancialAccounts() {
        setup();
        User testUser = [SELECT Id FROM User WHERE ProfileId = :systemAdminProfile.Id and isActive =true and Advisor_Type__c =''  LIMIT 1];
        Account testHousehold = new Account(Name = 'Test Household 2');
        insert testHousehold; // Create Household with no Financial Accounts

        dfsle__EnvelopeConfiguration__c template = [SELECT Id FROM dfsle__EnvelopeConfiguration__c WHERE Name = 'Test E-Sign Template' LIMIT 1];

        System.runAs(testUser) {
            Test.startTest();
            PageReference pageRef = Page.GenerateDocuSign;
            Test.setCurrentPage(pageRef);
            ApexPages.currentPage().getParameters().put('id', testHousehold.Id);

            GenerateDocuSign controller = new GenerateDocuSign();

            // Verify initial state when no Financial Accounts are present
            System.assertEquals('none', controller.displayFinAccList, 'Fin Acc list should be hidden');
            System.assertEquals('block', controller.displayGenDoc, 'Generate Doc button should be visible');

            // Test Navigate (same as before)
            controller.selectedOption = template.Id;
            PageReference resultPageRef = controller.navigate();
            System.assertNotEquals(null, resultPageRef, 'Navigation should return a PageReference');
            controller.refresh();
            Test.stopTest();
        }
    }

    @isTest
    static void testPrimaryAgentUser() {
        setup();
        User testUser = [SELECT Id, Advisor_Type__c FROM User WHERE ProfileId = :primaryAgentProfile.Id and isActive =true and Advisor_Type__c ='RIA' LIMIT 1];
       	Account testHousehold = new Account(Name = 'Test Household 2');
        	insert testHousehold; 
        dfsle__EnvelopeConfiguration__c template = [SELECT Id FROM dfsle__EnvelopeConfiguration__c WHERE Name = 'Test E-Sign Template' LIMIT 1];

        System.runAs(testUser) {
            Test.startTest();
            PageReference pageRef = Page.GenerateDocuSign;
            Test.setCurrentPage(pageRef);
            ApexPages.currentPage().getParameters().put('id', testHousehold.Id);

            GenerateDocuSign controller = new GenerateDocuSign();

            // Add assertions based on expected behavior for Primary Agent
            if (!controller.options.isEmpty()) {
                controller.selectedOption = controller.options[0].getValue(); // Select the first option
                PageReference resultPageRef = controller.navigate();
                //System.assertNotEquals(null, resultPageRef, 'Navigation should return a PageReference');
            }
            controller.refresh();
            Test.stopTest();
        }
    }

    @isTest
    static void testNavigateNoSelectedOption() {
        setup();
        User testUser = [SELECT Id FROM User WHERE ProfileId = :systemAdminProfile.Id and isActive =true and Advisor_Type__c ='' LIMIT 1];
        Account testHousehold = [SELECT Id FROM Account LIMIT 1];

        System.runAs(testUser) {
            Test.startTest();
            PageReference pageRef = Page.GenerateDocuSign;
            Test.setCurrentPage(pageRef);
            ApexPages.currentPage().getParameters().put('id', testHousehold.Id);

            GenerateDocuSign controller = new GenerateDocuSign();

            // Test navigate with no selected option
            PageReference resultPageRef = controller.navigate();
            System.assertEquals(null, resultPageRef, 'Navigation should return null if no option selected');
            controller.refresh();
            Test.stopTest();
        }
    }
}