@IsTest(SeeAllData=true)
private class DocusignReportController_Test {
	@isTest
    static void testGetChartData() {
       // Step 1: Ensure a RecordType exists
        RecordType accountRecType = [SELECT Id FROM RecordType WHERE DeveloperName = 'SIG_Advisors_Agents_and_their_affiliated_staff' AND SObjectType = 'Account' and IsPersonType = true  LIMIT 1];
        System.assertNotEquals(null, accountRecType, 'Record Type SIG_Advisors_Agents_and_their_affiliated_staff should exist.');

        RecordType accountRecType1 = [SELECT Id FROM RecordType WHERE DeveloperName = 'IndustriesHousehold' AND SObjectType = 'Account' and IsPersonType = false LIMIT 1];
        System.assertNotEquals(null, accountRecType1, 'Record Type IndustriesHousehold should exist.');
        // Create a test Account with a RepAdvisorEntity__pc value
        Account acc1 = new Account(
            Name = 'TestEntity', 
            RecordTypeId = accountRecType1.Id, // Ensure this record type is valid for the user profile
            Industry = 'Engineering',
            SIS_Advisor_Affiliation__c='Sub-Advisor',
            RIA_Firm__c ='TestEntity'
        );
        insert acc1;
        
		RecordType accountRecType2 = [SELECT Id FROM RecordType WHERE DeveloperName = 'SIG_Advisors_Agents_Business_Name' AND SObjectType = 'Account' and IsPersonType = false LIMIT 1];
        System.assertNotEquals(null, accountRecType1, 'Record Type SIG_Advisors_Agents_Business_Name should exist.');
        // Create a test Account with a RepAdvisorEntity__pr value
        Account acc2 = new Account(
            Name = 'TestEntity', // This should match the User's CompanyName
            RecordTypeId = accountRecType2.Id,
            Industry = 'Test Industry'
        );
        insert acc2;
        
        // Create Accounts that reference the above entities
        Account account1 = new Account(
            LastName = 'Test Account 1',
            FirstName = 'Test Account 1',
            Industry = 'Test Industry',
            RecordTypeId = accountRecType.Id, // Ensure this record type is valid for the user profile
            RepAdvisorEntity__pc = acc2.Id // Ensure this matches the entityName parameter
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
            RepAdvisorEntity__c = acc2.Id // Ensure this matches the entityName parameter
        );
        insert con;
        
        // Create Financial Account
        FinServ__FinancialAccount__c financialAccount = new FinServ__FinancialAccount__c(
            Name = 'Test Financial Account',
            FinServ__PrimaryOwner__c = acc2.Id,
            FinServ__JointOwner__c = account1.Id,
            FinServ__Household__c = acc1.Id,
            RepAdvisor__c = con.id
        );
        insert financialAccount;	
        
        // Create Financial Account
        FinServ__FinancialAccount__c financialAccount1 = new FinServ__FinancialAccount__c(
           Name = 'Test Financial Account11',
            FinServ__PrimaryOwner__c = acc2.Id,
            FinServ__JointOwner__c = account1.Id,
            FinServ__Household__c = acc1.Id,
            RepAdvisor__c = con.id
        );
        insert financialAccount1;
        
        // Create Envelope Status records
        dfsle__EnvelopeStatus__c envelopeStatus1 = new dfsle__EnvelopeStatus__c(dfsle__Account__c=account1.Id, dfsle__Status__c='Sent');
        dfsle__EnvelopeStatus__c envelopeStatus2 = new dfsle__EnvelopeStatus__c(dfsle__Account__c=account2.Id, dfsle__Status__c='Completed');        
        dfsle__EnvelopeStatus__c envelopeStatus3 = new dfsle__EnvelopeStatus__c(dfsle__Account__c=account1.Id, dfsle__Status__c='Completed');
        
        insert new List<dfsle__EnvelopeStatus__c> { envelopeStatus1, envelopeStatus2, envelopeStatus3 };
		
             // Create Envelope records associated with these accounts
        dfsle__Envelope__c envelope1 = new dfsle__Envelope__c(
            CreatedDate = System.now(),
            Financial_Account__c = financialAccount.Id,
            DocuSign_Status_Record__c = envelopeStatus1.id
        );
        
        dfsle__Envelope__c envelope2 = new dfsle__Envelope__c(
            CreatedDate = System.now().addDays(-1),
            Financial_Account__c = financialAccount1.Id,
            DocuSign_Status_Record__c = envelopeStatus2.id
        );
        
        dfsle__Envelope__c envelope3 = new dfsle__Envelope__c(
            CreatedDate = System.now().addDays(-1),
            Financial_Account__c = financialAccount.Id,
            DocuSign_Status_Record__c = envelopeStatus3.id
        );

        insert new List<dfsle__Envelope__c> { envelope1, envelope2, envelope3 };
        // Test getChartData method
        Test.startTest();
        DocusignReportByCompany reportByCompany = new DocusignReportByCompany();
        
        // Create a user with the same company name as the account's entity
        User currentUser = new User(
            Username = 'testuser221@example.com',
            Email = 'testuser221@example.com',
            Alias = 'tuser',
            ProfileId =  [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1].Id,
            CompanyName = 'TestEntity', // This should match the entity name
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LastName = 'User',
            FirstName = 'Test',
                RepAdvisorId__c= acc1.Id
        );
        insert currentUser;
        
        // Set the current user's context
        System.runAs(currentUser) {
            // Step 3: Instantiate the controller
            DocusignReportController controller = new DocusignReportController();

            // Step 4: Validate the chart data JSON
            List<DocusignReportController.ChartData> chartData = (List<DocusignReportController.ChartData>) JSON.deserialize(controller.chartDataJson, List<DocusignReportController.ChartData>.class);
            
            // Step 5: Assertions
            System.assertNotEquals(null, chartData, 'Chart data should not be null');
            //System.assertEquals(1, chartData.size(), 'There should be one entity in the chart data');
            
            // Step 4: Validate the chart data JSON
            List<DocusignReportController.ChartDataByStatus> chartDataByStatus = (List<DocusignReportController.ChartDataByStatus>) JSON.deserialize(controller.chartDataJsonStatus, List<DocusignReportController.ChartDataByStatus>.class);
            
            // Step 5: Assertions
            System.assertNotEquals(null, chartDataByStatus, 'Chart data should not be null');
            //System.assertEquals(1, chartDataByStatus.size(), 'There should be one entity in the chart data');
        }
        
        Test.stopTest();
    }
    
    @isTest
    static void testDousignMatrixPageController() {
        // Step 1: Set up test data
         // Step 1: Ensure a RecordType exists
        RecordType accountRecType = [SELECT Id FROM RecordType WHERE DeveloperName = 'SIG_Advisors_Agents_and_their_affiliated_staff' AND SObjectType = 'Account' and IsPersonType = true  LIMIT 1];
        System.assertNotEquals(null, accountRecType, 'Record Type SIG_Advisors_Agents_and_their_affiliated_staff should exist.');

        RecordType accountRecType1 = [SELECT Id FROM RecordType WHERE DeveloperName = 'IndustriesHousehold' AND SObjectType = 'Account' and IsPersonType = false LIMIT 1];
        System.assertNotEquals(null, accountRecType1, 'Record Type IndustriesHousehold should exist.');
        // Create a test Account with a RepAdvisorEntity__pc value
        Account acc1 = new Account(
            Name = 'TestEntity', 
            RecordTypeId = accountRecType1.Id, // Ensure this record type is valid for the user profile
            Industry = 'Engineering',
            SIS_Advisor_Affiliation__c='Sub-Advisor',
            RIA_Firm__c ='TestEntity'
        );
        insert acc1;
        
        RecordType accountRecType2 = [SELECT Id FROM RecordType WHERE DeveloperName = 'SIG_Advisors_Agents_Business_Name' AND SObjectType = 'Account' and IsPersonType = false LIMIT 1];
        System.assertNotEquals(null, accountRecType1, 'Record Type SIG_Advisors_Agents_Business_Name should exist.');
        // Create a test Account with a RepAdvisorEntity__pr value
        Account acc2 = new Account(
            Name = 'TestEntity', // This should match the User's CompanyName
            RecordTypeId = accountRecType2.Id,
            Industry = 'Test Industry'
        );
        insert acc2;
        
        // Create Accounts that reference the above entities
        Account account1 = new Account(
            LastName = 'Test Account 1',
            FirstName = 'Test Account 1',
            Industry = 'Test Industry',
            RecordTypeId = accountRecType.Id, // Ensure this record type is valid for the user profile
            RepAdvisorEntity__pc = acc2.Id // Ensure this matches the entityName parameter
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
            RepAdvisorEntity__c = acc2.Id // Ensure this matches the entityName parameter
        );
        insert con;
        
        // Create Financial Account
        FinServ__FinancialAccount__c financialAccount = new FinServ__FinancialAccount__c(
            Name = 'Test Financial Account',
            FinServ__PrimaryOwner__c = acc2.Id,
            FinServ__JointOwner__c = account1.Id,
            FinServ__Household__c = acc1.Id,
            RepAdvisor__c = con.id
        );
        insert financialAccount;    
        
        // Create Financial Account
        FinServ__FinancialAccount__c financialAccount1 = new FinServ__FinancialAccount__c(
           Name = 'Test Financial Account11',
            FinServ__PrimaryOwner__c = acc2.Id,
            FinServ__JointOwner__c = account1.Id,
            FinServ__Household__c = acc1.Id,
            RepAdvisor__c = con.id
        );
        insert financialAccount1;
        
        // Create Envelope Status records
        dfsle__EnvelopeStatus__c envelopeStatus1 = new dfsle__EnvelopeStatus__c(dfsle__Account__c=account1.Id, dfsle__Status__c='Sent');
        dfsle__EnvelopeStatus__c envelopeStatus2 = new dfsle__EnvelopeStatus__c(dfsle__Account__c=account2.Id, dfsle__Status__c='Completed');        
        dfsle__EnvelopeStatus__c envelopeStatus3 = new dfsle__EnvelopeStatus__c(dfsle__Account__c=account1.Id, dfsle__Status__c='Completed');
        
        insert new List<dfsle__EnvelopeStatus__c> { envelopeStatus1, envelopeStatus2, envelopeStatus3 };
        
             // Create Envelope records associated with these accounts
        dfsle__Envelope__c envelope1 = new dfsle__Envelope__c(
            CreatedDate = System.now(),
            Financial_Account__c = financialAccount.Id,
            DocuSign_Status_Record__c = envelopeStatus1.id
        );
        
        dfsle__Envelope__c envelope2 = new dfsle__Envelope__c(
            CreatedDate = System.now().addDays(-1),
            Financial_Account__c = financialAccount1.Id,
            DocuSign_Status_Record__c = envelopeStatus2.id
        );
        
        dfsle__Envelope__c envelope3 = new dfsle__Envelope__c(
            CreatedDate = System.now().addDays(-1),
            Financial_Account__c = financialAccount.Id,
            DocuSign_Status_Record__c = envelopeStatus3.id
        );

        insert new List<dfsle__Envelope__c> { envelope1, envelope2, envelope3 };
        // Create a test User with a specific CompanyName
   User testUser = new User(
            Username = 'testuser_' + System.currentTimeMillis() + '@example.com',
            Email = 'testuser@example.com',
            Alias = 'tuser',
            LastName = 'Test User',
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1].Id,
            CompanyName = 'TestEntity',
                RepAdvisorId__c= acc1.Id
        );
        insert testUser;
        System.runAs(testUser) {
            ApexPages.currentPage().getParameters().put('entityName', 'TestEntity');
            DocusignReportController controller = new DocusignReportController();
            System.assertEquals(3, controller.docusignRecordsMatrix.size(), 'The number of case records should be 3.');
            //System.assertEquals('Completed', controller.docusignRecordsMatrix[0][2], 'Completed');
            System.assertEquals('Sent', controller.docusignRecordsMatrix[0][2], 'Sent'); //Prod
            controller.docusignRecordsMatrix.clear();
            ApexPages.currentPage().getParameters().put('statusList', 'Completed,Sent');
            DocusignReportController controllerByStatus = new DocusignReportController();
            System.assertEquals(6, controllerByStatus.docusignRecordsMatrix.size(), 'The number of records should be 3.');
            //System.assertEquals('Completed', controllerByStatus.docusignRecordsMatrix[0][2], 'Completed');
            System.assertEquals('Sent', controllerByStatus.docusignRecordsMatrix[0][2], 'Sent'); //Prod
            
        }
    }
}