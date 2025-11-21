@IsTest(SeeAllData=true)
public class AdvisorAccountReportControllerTest {
    
    // Setup mock data for testing
    static void setupTestData() {
        
        
        // Step 1: Ensure a RecordType exists
        RecordType accountRecType = [SELECT Id FROM RecordType WHERE DeveloperName = 'SIG_Advisors_Agents_and_their_affiliated_staff' AND SObjectType = 'Account' and IsPersonType = true  LIMIT 1];
        System.assertNotEquals(null, accountRecType, 'Record Type SIG_Advisors_Agents_and_their_affiliated_staff should exist.');
        
        RecordType accountRecType1 = [SELECT Id FROM RecordType WHERE DeveloperName = 'IndustriesHousehold' AND SObjectType = 'Account' and IsPersonType = false LIMIT 1];
        System.assertNotEquals(null, accountRecType1, 'Record Type IndustriesHousehold should exist.');
        
        // Create a test Account with a RepAdvisorEntity__pc value
        Account acc1 = new Account(
            Name = 'Test Company', 
            RecordTypeId = accountRecType1.Id, // Ensure this record type is valid for the user profile
            Industry = 'Engineering',
            SIS_Advisor_Affiliation__c='Sub-Advisor',
            RIA_Firm__c ='Test Company',
            HHCurrentCash__c =5000,
            HHCurrentMktVal__c = 5000
        );
        insert acc1;
        
        RecordType accountRecType2 = [SELECT Id FROM RecordType WHERE DeveloperName = 'SIG_Advisors_Agents_Business_Name' AND SObjectType = 'Account' and IsPersonType = false LIMIT 1];
        System.assertNotEquals(null, accountRecType2, 'Record Type SIG_Advisors_Agents_Business_Name should exist.');
        // Create a test Account with a RepAdvisorEntity__pr value
        Account acc2 = new Account(
            Name = 'Sound Income Group', // This should match the User's CompanyName
            RecordTypeId = accountRecType2.Id,
            Industry = 'Test Industry',
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
            RepAdvisorEntity__pc = acc1.Id // Ensure this matches the entityName parameter
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
        // Create test data
        User testUser = new User(
            FirstName = 'Test',
            LastName = 'User',
            Email = 'test@example.com',
            Username = 'test@example.com' + System.currentTimeMillis(),
            CompanyName = 'Test Company',
            Alias = 'tuser',
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            isActive = true,
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'System Administrator'].Id,
            LanguageLocaleKey = 'en_US',
            RepAdvisorId__c = acc2.id
        );
        insert testUser;
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
            FinServ__FinancialAccount__c financialAccount = new FinServ__FinancialAccount__c(
                Name = 'Test Financial Account',
                FinServ__PrimaryOwner__c = acc2.Id,
                FinServ__JointOwner__c = account1.Id,
                FinServ__Household__c = acc1.Id,
                RepAdvisor__c = con.id,
                RepIDLink__c = repIDManagedFalse.id,
                RepID__c = repIDManagedFalse.Name,
                FinServ__Balance__c =5000
            );
        insert financialAccount;	
        
        // Create Financial Account
        FinServ__FinancialAccount__c financialAccount1 = new FinServ__FinancialAccount__c(
            Name = 'Test Financial Account11',
            FinServ__PrimaryOwner__c = acc2.Id,
            FinServ__JointOwner__c = account1.Id,
            FinServ__Household__c = acc1.Id,
            RepAdvisor__c = con.id,
            RepIDLink__c = repIDManagedTrue.id,            
            RepID__c = repIDManagedTrue.Name,
            FinServ__Balance__c =5000
        );
        insert financialAccount1;
    }
    
    @isTest
    static void testAdvisorAccountReportControllerConstructor() {
        setupTestData();
        
        Test.startTest();
        AdvisorAccountReportController controller = new AdvisorAccountReportController();
        Test.stopTest();
        
        // Check that the userCompanyName is set correctly
        System.assertEquals('Sound Income Strategies LLC', controller.userCompanyName, 'User company name should match Sound Income Strategies LLC');
        
        // Verify chartDataJson is populated
        System.assertNotEquals(null, controller.chartDataJson, 'chartDataJson should not be null');
    }
    @isTest
    static void testConstructor() {
         setupTestData();        
        Test.startTest();
            AdvisorAccountReportController controller = new AdvisorAccountReportController();
            System.assertNotEquals(null, controller.userCompanyName, 'User company name should not be null');
            System.assertNotEquals(null, controller.userCompanyInvestment, 'User company investment should not be null');
            System.assertNotEquals(null, controller.chartDataJson, 'Chart data JSON should not be null');
            System.assertNotEquals(null, controller.chartAdvisorDataJson, 'Chart advisor data JSON should not be null');
            System.assertNotEquals(null, controller.options, 'Options should not be null');
            System.assertEquals('DGR', controller.selectedRadioOption, 'Default radio option should be DGR');
            System.assertNotEquals(null, controller.companyInvestmentRecordMatrix, 'Company investment record matrix should not be null');
            System.assertNotEquals(null, controller.advisorsRecordMatrix, 'Advisors record matrix should not be null');
        //} 
       Test.stopTest();
        
    }
    @isTest
    static void testHouseholdAccountChange() {
       setupTestData();        
        Test.startTest();
            AdvisorAccountReportController controller = new AdvisorAccountReportController();
            controller.householdAccountChange();
            System.assertNotEquals(null, controller.companyInvestmentRecordMatrix, 'companyInvestmentRecordMatrix should be initialized');
            System.assertNotEquals(null, controller.advisorsRecordMatrix, 'advisorsRecordMatrix should be initialized');
        Test.stopTest();
    }

	 @isTest
    static void testRadioSelectionDataDGR() {
         setupTestData();        
        Test.startTest();
            AdvisorAccountReportController controller = new AdvisorAccountReportController();
            controller.selectedRadioOption = 'DGR';
            controller.radioSelectionData();
            System.assertNotEquals(null, controller.advisorsRecordMatrix, 'Advisors record matrix should not be null for DGR');
        Test.stopTest();
    }
	@isTest
    static void testRadioSelectionDataAUM() {
        setupTestData();        
        Test.startTest();
            AdvisorAccountReportController controller = new AdvisorAccountReportController();
            controller.selectedRadioOption = 'AUM';
            controller.radioSelectionData();
            System.assertNotEquals(null, controller.companyInvestmentRecordMatrix, 'Company investment record matrix should not be null for AUM');
        Test.stopTest();
    }
}