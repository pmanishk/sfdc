@IsTest(SeeAllData=true)
public class CaseReportGeneratorByStatus_Test {
    
    @isTest
    static void testCaseReportGeneratorByStatus() {
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
                AccountId = account1.Id
            );
            Case case2 = new Case(
                Subject = 'Case 2',
                Status = 'In Progress',
                Priority = 'Medium',
                AccountId = account1.Id
            );
            Case case3 = new Case(
                Subject = 'Case 3',
                Status = 'New',
                Priority = 'Low',
                AccountId = account1.Id
            );
            insert new List<Case>{case1, case2, case3};
             // Step 2: Instantiate the CaseReportGeneratorByStatus class
            CaseReportGeneratorByStatus reportGenerator = new CaseReportGeneratorByStatus();
            
            // Step 3: Retrieve and validate the chart data
            List<CaseReportGeneratorByStatus.ChartData> chartData = (List<CaseReportGeneratorByStatus.ChartData>)JSON.deserialize(reportGenerator.chartDataJson, List<CaseReportGeneratorByStatus.ChartData>.class);
            
            // Check the size of chartData
            System.assertEquals(2, chartData.size(), 'The number of chart data entries should be 2.');
            
            // Verify the data
            Map<String, Integer> expectedCounts = new Map<String, Integer>{'New' => 2, 'In Progress' => 1};
            for (CaseReportGeneratorByStatus.ChartData data : chartData) {
                //System.assertEquals(expectedCounts.get(data.statusName), data.caseCount, 'The case count for status ' + data.statusName + ' should be ' + expectedCounts.get(data.statusName) + '.');
            }
        }
    }
}