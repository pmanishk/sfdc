@IsTest(SeeAllData=true)
public class CaseMatrixPageController_Test {
    
    @isTest
    static void testCaseMatrixPageController() {
        // Step 1: Set up test data
        
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
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1].Id,
            CompanyName = 'Test Entity' // This should match the entity name in the Account
        );
        insert testUser;
        
        // Log in as the test user
        System.runAs(testUser) {
            
            // Create an Account with the matching RepAdvisorEntity__pr.Name
           // Step 1: Ensure a RecordType exists
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
            
            // Create cases for the test Account
            Case case1 = new Case(
                Subject = 'Case 1',
                Status = 'New',
                Priority = 'High',
                ClosedDate = Date.today(),
            CreatedDate = Date.today(),
                AccountId = account1.Id
            );
            Case case2 = new Case(
                Subject = 'Case 2',
                Status = 'In Progress',
                Priority = 'Medium',
                ClosedDate = Date.today(),
            CreatedDate = Date.today(),
                AccountId = account1.Id
            );
            Case case3 = new Case(
                Subject = 'Case 3',
                Status = 'Closed',
                Priority = 'Low',
                ClosedDate = Date.today(),
            CreatedDate = Date.today(),
                AccountId = account1.Id
            );
            insert new List<Case>{case1, case2, case3};
            
            // Step 2: Test fetchDetailedData
            
            // Set the URL parameters
            ApexPages.currentPage().getParameters().put('entityName', 'Test Entity');
            
            // Instantiate the controller
            CaseMatrixPageController controller = new CaseMatrixPageController();
            
            // Check the matrix data
            System.assertEquals(3, controller.caseRecordsMatrix.size(), 'The number of case records should be 3.');
            
            // Validate individual rows
            //System.assertEquals('0001', controller.caseRecordsMatrix[0][0], 'Case number should be 0001.');
            System.assertEquals('Case 1', controller.caseRecordsMatrix[0][1], 'Subject should be Case 1.');
            System.assertEquals('New', controller.caseRecordsMatrix[0][4], 'Status should be New.');
            //System.assertEquals('N/A', controller.caseRecordsMatrix[0][3], 'Closed Date.');
            //System.assertEquals('09/22/2024 5:00 PM', controller.caseRecordsMatrix[0][2], 'Created Date.');
            
            // Step 3: Test fetchDetailedDataByStatus
            
            // Clear the matrix and set new URL parameters
            controller.caseRecordsMatrix.clear();
            ApexPages.currentPage().getParameters().put('statusList', 'New,Closed');
            
            // Instantiate the controller again to use the new parameters
            CaseMatrixPageController controllerByStatus = new CaseMatrixPageController();
            
            // Check the matrix data
            System.assertEquals(5, controllerByStatus.caseRecordsMatrix.size(), 'The number of case records with the specified statuses should be 2.');
            
            // Validate individual rows
            //System.assertEquals('0001', controllerByStatus.caseRecordsMatrix[0][0], 'Case number should be 0001.');
            System.assertEquals('Case 1', controllerByStatus.caseRecordsMatrix[0][1], 'Subject should be Case 1.');
            System.assertEquals('New', controllerByStatus.caseRecordsMatrix[0][4], 'Status should be New.'); 
            
            //System.assertEquals('0003', controllerByStatus.caseRecordsMatrix[1][0], 'Case number should be 0003.');
            System.assertEquals('Case 2', controllerByStatus.caseRecordsMatrix[1][1], 'Subject should be Case 2.');
            System.assertEquals('In Progress', controllerByStatus.caseRecordsMatrix[1][4], 'Status should be In Progress.');  
            
        }
    }
}