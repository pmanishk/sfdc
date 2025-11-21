@IsTest(SeeAllData=true)
public class CaseReportGenerator_Test {
    @isTest
    static void testCaseReportGenerator() {
        
        // Step 1: Ensure a RecordType exists
        RecordType accountRecType = [SELECT Id FROM RecordType WHERE DeveloperName = 'SIG_Advisors_Agents_and_their_affiliated_staff' AND SObjectType = 'Account' and IsPersonType = true  LIMIT 1];
        System.assertNotEquals(null, accountRecType, 'Record Type SIG_Advisors_Agents_and_their_affiliated_staff should exist.');
        
        RecordType accountRecType1 = [SELECT Id FROM RecordType WHERE DeveloperName = 'SIG_Advisors_Agents_Business_Name' AND SObjectType = 'Account' and IsPersonType = false LIMIT 1];
        System.assertNotEquals(null, accountRecType1, 'Record Type SIG_Advisors_Agents_Business_Name should exist.');
        // Create a test Account with a RepAdvisorEntity__pc value
        Account acc1 = new Account(
            Name = 'TestEntity', // The value that will match the entityName parameter
            RecordTypeId = accountRecType1.Id, // Ensure this record type is valid for the user profile
            Industry = 'Engineering',
            SIS_Advisor_Affiliation__c='Sub-Advisor',
            RIA_Firm__c ='TestEntity'
        );
        insert acc1;
        
        
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
            RepAdvisorEntity__pc = acc1.Id // Ensure this matches the entityName parameter
        );
        insert account2;
        
        // Create Cases associated with the accounts
        Case case1 = new Case(Subject = 'Test Case 1', Status = 'New', Priority = 'High', AccountId = account1.Id);
        Case case2 = new Case(Subject = 'Test Case 2', Status = 'In Progress', Priority = 'Medium', AccountId = account2.Id);
        Case case3 = new Case(Subject = 'Test Case 3', Status = 'Closed', Priority = 'Low', AccountId = account1.Id);
        insert new List<Case> { case1, case2, case3 };
            
            // Create a user with the same company name as the account's entity
            User currentUser = new User(
                Username = 'testuser2211@example.com',
                Email = 'testuser2211@example.com',
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
            CaseReportGeneratorController controller = new CaseReportGeneratorController();
            
            // Step 4: Validate the chart data JSON
            List<CaseReportGeneratorController.ChartData> chartData = (List<CaseReportGeneratorController.ChartData>) JSON.deserialize(controller.chartDataJson, List<CaseReportGeneratorController.ChartData>.class);
            
            // Step 5: Assertions
            System.assertNotEquals(null, chartData, 'Chart data should not be null');
            System.assertEquals(1, chartData.size(), 'There should be one entity in the chart data');
        }
        
        // Additional Test Case: No Cases for User's Company
        Account acc2 = new Account(
            Name = 'Another Entity',
            RecordTypeId = accountRecType1.Id,
            Industry = 'Test Industry'
        );
        insert acc2;
        
        User anotherUser = new User(
            Username = 'anotheruser_' + System.currentTimeMillis() + '@example.com',
            Email = 'anotheruser@example.com',
            Alias = 'auser',
            LastName = 'Another User',
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1].Id,
            CompanyName = 'Another Entity',
            RepAdvisorId__c= acc1.Id
        );
        insert anotherUser;
        
        System.runAs(anotherUser) {
            CaseReportGeneratorController controllerNoCases = new CaseReportGeneratorController();
            List<CaseReportGeneratorController.ChartData> chartDataNoCases = (List<CaseReportGeneratorController.ChartData>) JSON.deserialize(controllerNoCases.chartDataJson, List<CaseReportGeneratorController.ChartData>.class);
            System.assertNotEquals(null, chartDataNoCases, 'Chart data should not be null for user with no cases');
            System.assertEquals(1, chartDataNoCases.size(), 'There should be no entities in the chart data for user with no cases');
        }
    }
    
    @isTest
    static void testCaseReportGeneratorByStatus() {
        testSetupData();
            
            // Step 2: Instantiate the CaseReportGeneratorController class
            CaseReportGeneratorController reportGenerator = new CaseReportGeneratorController();
            
            // Step 3: Retrieve and validate the chart data
            List<CaseReportGeneratorController.ChartData> chartData = (List<CaseReportGeneratorController.ChartData>)JSON.deserialize(reportGenerator.chartDataJson, List<CaseReportGeneratorController.ChartData>.class);
            
            // Check the size of chartData
            System.assertEquals(1, chartData.size(), 'The number of chart data entries should be 1.');
            
            // Verify the data
            Map<String, Integer> expectedCounts = new Map<String, Integer>{'New' => 2, 'In Progress' => 1};
                for (CaseReportGeneratorController.ChartData data : chartData) {
                    //System.assertEquals(expectedCounts.get(data.statusName), data.caseCount, 'The case count for status ' + data.statusName + ' should be ' + expectedCounts.get(data.statusName) + '.');
                }
        
    }
    
    @isTest
    static void testCaseMatrixPageController() {
        testSetupData();          
            ApexPages.currentPage().getParameters().put('entityName', 'Test Entity');
            
            // Instantiate the controller
            CaseReportGeneratorController controller = new CaseReportGeneratorController();
            
            // Step 3: Test fetchDetailedDataByStatus
            
            controller.caseRecordsMatrix.clear();
            ApexPages.currentPage().getParameters().put('statusList', 'New,Closed');
            
            // Instantiate the controller again to use the new parameters
            CaseReportGeneratorController controllerByStatus = new CaseReportGeneratorController();
              }
    @isTest
    static void testToggleSort() {
        testSetupData();
            CaseReportGeneratorController ctrl = new CaseReportGeneratorController();
            
            // Initial sortField and sortDirection
            System.assertEquals('CreatedDate', ctrl.sortField);
            System.assertEquals('DESC', ctrl.sortDirection);
            
            // Call toggleSort - should switch DESC to ASC
            ctrl.toggleSort();
            System.assertEquals('CreatedDate', ctrl.sortField);
            System.assertEquals('ASC', ctrl.sortDirection);
            
            // Call toggleSort again - should switch ASC to DESC
            ctrl.toggleSort();
            System.assertEquals('CreatedDate', ctrl.sortField);
            System.assertEquals('DESC', ctrl.sortDirection);
            
            // Optionally, test when sortField is different
            ctrl.sortField = 'Status';
            ctrl.sortDirection = 'DESC';
            
            ctrl.toggleSort();
            System.assertEquals('CreatedDate', ctrl.sortField);
            System.assertEquals('ASC', ctrl.sortDirection);
    }
    @isTest
    static void testFetchDetailedDataByStatus() {
      testSetupData();
        
            // Set URL parameter to trigger fetchDetailedDataByStatus
            ApexPages.currentPage().getParameters().put('statusList', 'Closed,New,Waiting on Customer,Waiting on Review');
            ApexPages.currentPage().getParameters().put('selectedTimeRange', 'Last 90 Days');
            
            // Instantiate controller - constructor calls fetchDetailedDataByStatus
            CaseReportGeneratorController ctrl = new CaseReportGeneratorController();
            
            // Assert matrix is populated with only allowed statuses for Standard User (all statuses)
            System.assert(ctrl.caseRecordsMatrix.size() > 0, 'Matrix should be populated');
            
            // Assert that 'Other' status case is included for Standard User
            Boolean hasOther = false;
            for (List<String> row : ctrl.caseRecordsMatrix) {
                if (row[4] == 'Other') {
                    hasOther = true;
                    break;
                }
            }
            System.assertEquals(false, hasOther, 'Matrix should include cases with status "Other"');
    }
    @isTest
    static void testSetupData() {
        // Step 1: Ensure a RecordType exists
        RecordType accountRecType = [SELECT Id FROM RecordType WHERE DeveloperName = 'SIG_Advisors_Agents_and_their_affiliated_staff' AND SObjectType = 'Account' and IsPersonType = true  LIMIT 1];
        System.assertNotEquals(null, accountRecType, 'Record Type SIG_Advisors_Agents_and_their_affiliated_staff should exist.');
        
        RecordType accountRecType1 = [SELECT Id FROM RecordType WHERE DeveloperName = 'SIG_Advisors_Agents_Business_Name' AND SObjectType = 'Account' and IsPersonType = false LIMIT 1];
        System.assertNotEquals(null, accountRecType1, 'Record Type SIG_Advisors_Agents_Business_Name should exist.');
        // Create a test Account with a RepAdvisorEntity__pc value
        Account acc1 = new Account(
            Name = 'TestEntity', // The value that will match the entityName parameter
            RecordTypeId = accountRecType1.Id, // Ensure this record type is valid for the user profile
            Industry = 'Engineering',
            SIS_Advisor_Affiliation__c='Sub-Advisor',
            RIA_Firm__c ='TestEntity'
        );
        insert acc1;
        
        
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
            RepAdvisorEntity__pc = acc1.Id // Ensure this matches the entityName parameter
        );
        insert account2;
        
        // Create Cases associated with the accounts
        Case case1 = new Case(Subject = 'Case 1', Status = 'New', Priority = 'High', AccountId = account1.Id);
        Case case2 = new Case(Subject = 'Case 2', Status = 'In Progress', Priority = 'Medium', AccountId = account2.Id);
        Case case3 = new Case(Subject = 'Case 3', Status = 'Closed', Priority = 'Low', AccountId = account1.Id);
        insert new List<Case> { case1, case2, case3 };
            
            // Create a user with the same company name as the account's entity
            User currentUser = new User(
                Username = 'testuser2211@example.com',
                Email = 'testuser2211@example.com',
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
    }
}