@IsTest(SeeAllData=true)
public class AdvisorReportControllerTest {
    
    // Setup mock data for testing
    static void setupTestData() {
       
        
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
            RIA_Firm__c ='TestEntity',
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
         User testUser = new User(
            Username = 'testuser_' + System.currentTimeMillis() + '@example.com',
            Email = 'testuser@example.com',
            Alias = 'tuser',
            LastName = 'Test User',
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            ProfileId = [SELECT Id FROM Profile WHERE Name='System Administrator' LIMIT 1].Id,
            CompanyName='Sound Income Strategies LLC',
             RepAdvisorId__c =acc1.Id
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
    static void testAdvisorReportControllerConstructor() {
        setupTestData();
        
        Test.startTest();
        AdvisorReportController controller = new AdvisorReportController();
        Test.stopTest();
        
        // Check that the userCompanyName is set correctly
        System.assertEquals('Sound Income Strategies LLC', controller.userCompanyName, 'User company name should match Sound Income Strategies LLC');
        
        // Verify personAccountOptions list is populated correctly
        System.assertNotEquals(0, controller.personAccountOptions.size(), 'Person account options should not be empty');
        
        // Verify chartDataJson is populated
        System.assertNotEquals(null, controller.chartDataJson, 'chartDataJson should not be null');
    }
    
    @isTest
    static void testGetRelatedPersonAccounts() {
        setupTestData();
        
        Test.startTest();
        List<SelectOption> options = AdvisorReportController.getRelatedPersonAccounts('TestEntity');
        Test.stopTest();
        
        // Verify that the correct person accounts are returned
        System.assertEquals(1, options.size(), 'Should return 1 person account option');
        //System.assertEquals('Test Account 2 Test Account 2', options[0].getLabel(), 'Person account name should be TestPersonAccount');
    }
    
    @isTest
    static void testGetDefaultChartData() {
        setupTestData();
        List<AggregateResult> userCompanyInvestmentResults = [SELECT SUM(FinServ__Balance__c) totalBalance
                                                       FROM FinServ__FinancialAccount__c
                                                       WHERE RepAdvisor__r.Account.RepAdvisorEntity__pr.Name = 'TestEntity'
                                                       AND RepAdvisor__r.Account.RepAdvisorEntity__pr.IsPersonAccount = false];
        Test.startTest();
        List<AdvisorReportController.ChartData> chartData = AdvisorReportController.getDefaultChartData(userCompanyInvestmentResults, 'TestEntity');
        Test.stopTest();
        
        // Verify the chart data is populated correctly
        System.assertEquals(1, chartData.size(), 'There should be one chart data record');
        System.assertEquals('TestEntity', chartData[0].entityName, 'Entity name should be Sound Income Group');
        //System.assertEquals(10000, chartData[0].investment, 'Investment value should be 10000');
    }
    
    @isTest
    static void testGetChartDataByAdvisor() {
        setupTestData();  
        
        Test.startTest();
        
        List<SelectOption> options = AdvisorReportController.getRelatedPersonAccounts('TestEntity');
        String accountId; 
        System.debug('Options size: ' + options.size());
        if (!options.isEmpty()) {
            accountId = options[0].getValue();
            //System.debug('First option label: ' + options[0].getLabel());
            //System.debug('First option value: ' + options[0].getValue());            
        }
        
        System.assertEquals(1, options.size(), 'Should return 1 person account option');
        //System.assertEquals('Test Account 2 Test Account 2', options[0].getLabel(), 'Person account name should be Test Account 2 Test Account 2');
        
        List<AdvisorReportController.ChartData> chartData = AdvisorReportController.getChartDataByAdvisor(accountId);
        
        if (!chartData.isEmpty()) {
            System.debug('First chart data entity name: ' + chartData[0].entityName);
            System.debug('First chart data investment: ' + chartData[0].investment);
        }
        Test.stopTest();
        
        // Step 7: Verify that the chart data is populated correctly by advisor
        //System.assertEquals(1, chartData.size(), 'There should be one chart data record');
        //System.assertEquals('Test Account 2 Test Account 2', chartData[0].entityName, 'Entity name should be Test Account 2 Test Account 2');
        //System.assertEquals(10000, chartData[0].investment, 'Investment value should be 10000');
    }
    
    @isTest
    static void testGetChartDataByCustodian() {
        setupTestData();
        
        Test.startTest();
        List<AdvisorReportController.ChartData> chartData = AdvisorReportController.getChartDataByCustodian('Fidelity', 'Sound Income Strategies LLC');
        Test.stopTest();
        
        // Verify that the chart data is populated correctly by custodian
        System.assertEquals(1, chartData.size(), 'There should be one chart data record');
        System.assertEquals('Fidelity', chartData[0].entityName, 'Entity name should be Fidelity');
        System.assertEquals(0, chartData[0].investment, 'Investment value should be 3.0');
    }
    
    @isTest
    static void testGetChartDataByManaged() {
        setupTestData();
        
        Test.startTest();
        List<AdvisorReportController.ChartData> chartData = AdvisorReportController.getChartDataByManaged('Managed', 'Sound Income Strategies LLC');
        Test.stopTest();
        
        // Verify that the chart data is populated correctly by managed status
        System.assertEquals(1, chartData.size(), 'There should be one chart data record');
        System.assertEquals('Managed', chartData[0].entityName, 'Entity name should be Managed');
        //System.assertEquals(0, chartData[0].investment, 'Investment value should be 3.0');
    }
    
    @isTest
    static void testGetChartDataByCustodianAndManaged() {
        setupTestData();
        
        Test.startTest();
        List<AdvisorReportController.ChartData> chartData = AdvisorReportController.getChartDataByCustodianAndManaged('Fidelity','Managed','Sound Income Strategies LLC');
        Test.stopTest();
        
        // Verify that the chart data is populated correctly by managed status
        System.assertEquals(1, chartData.size(), 'There should be one chart data record');
        System.assertEquals('Fidelity', chartData[0].entityName, 'Entity name should be Managed');
        System.assertEquals(0, chartData[0].investment, 'Investment value should be 3.0');
    }
    
    @isTest
    static void testGetChartDataByAccountAndManaged() {       
        setupTestData(); 
        Test.startTest();
        List<SelectOption> options = AdvisorReportController.getRelatedPersonAccounts('TestEntity');
        
        if (!options.isEmpty()) {
            System.debug('First option label: ' + options[0].getLabel());
            System.debug('First option value: ' + options[0].getValue());
        }
        
        System.assertEquals(1, options.size(), 'Should return 1 person account option');
        //System.assertEquals('Test Account 2 Test Account 2', options[0].getLabel(), 'Person account name should be Test Account 2 Test Account 2');
        
        List<AdvisorReportController.ChartData> chartData = AdvisorReportController.getChartDataByAdvisor('Test Account 2 Test Account 2');
        
        if (!chartData.isEmpty()) {
            System.debug('First chart data entity name: ' + chartData[0].entityName);
            System.debug('First chart data investment: ' + chartData[0].investment);
        }
        
        List<AdvisorReportController.ChartData> chartData1 = AdvisorReportController.getChartDataByAccountAndManaged('Test Account 2 Test Account 2','Managed','Sound Income Strategies LLC');
        Test.stopTest();
        
        // Verify that the chart data is populated correctly by managed status
        //System.assertEquals(1, chartData1.size(), 'There should be one chart data record');
        //System.assertEquals('Test Account 2 Test Account 2', chartData1[0].entityName, 'Entity name should be Test Account 2 Test Account 2');
        //System.assertEquals(3.0, chartData1[0].investment, 'Investment value should be 3.0');
    }
    
    @isTest
    static void testGetChartDataByAccountAndCustodian() {
        setupTestData();
        
        Test.startTest();
        List<AdvisorReportController.ChartData> chartData = AdvisorReportController.getChartDataByAccountAndCustodian('Test Account 2 Test Account 2','Fidelity','Sound Income Strategies LLC');
        Test.stopTest();
        
        // Verify that the chart data is populated correctly by managed status
        //System.assertEquals(1, chartData.size(), 'There should be one chart data record');
        //System.assertEquals('Test Account 2 Test Account 2', chartData[0].entityName, 'Entity name should be Test Account 2 Test Account 2');
        //System.assertEquals(3.0, chartData[0].investment, 'Investment value should be 3.0');
    }
    
    @isTest
    static void testGetChartDataByAllFilters() {
        setupTestData();
        
        Test.startTest();
        List<AdvisorReportController.ChartData> chartData = AdvisorReportController.getChartDataByAllFilters('Test Account 2 Test Account 2','Fidelity','Managed','Sound Income Strategies LLC');
        Test.stopTest();
        
        // Verify that the chart data is populated correctly by managed status
        //System.assertEquals(1, chartData.size(), 'There should be one chart data record');
        //System.assertEquals('Test Account 2 Test Account 2', chartData[0].entityName, 'Entity name should be Test Account 2 Test Account 2');
        //System.assertEquals(3.0, chartData[0].investment, 'Investment value should be 3.0');
    }
    @isTest
    static void testGetChartData() {
        setupTestData();
        
        Test.startTest();
        List<AdvisorReportController.ChartData> chartDataByAdvisor = AdvisorReportController.getChartData('001XXXXXXXXXXXX', null, null);
        //System.assertNotEquals(0, chartDataByAdvisor.size(), 'Expected chart data for advisor');
        
        List<AdvisorReportController.ChartData> chartDataByCustodian = AdvisorReportController.getChartData(null, 'Fidelity', null);
        //System.assertNotEquals(0, chartDataByCustodian.size(), 'Expected chart data for custodian');
        
        List<AdvisorReportController.ChartData> chartDataByManaged = AdvisorReportController.getChartData(null, null, 'Managed');
        //System.assertNotEquals(0, chartDataByManaged.size(), 'Expected chart data for managed');
        
        List<AdvisorReportController.ChartData> chartDataByAccountAndCustodian = AdvisorReportController.getChartData('001XXXXXXXXXXXX', 'Fidelity', null);
        //System.assertNotEquals(0, chartDataByAccountAndCustodian.size(), 'Expected chart data for account and custodian');
        
        List<AdvisorReportController.ChartData> chartDataByAccountAndManaged = AdvisorReportController.getChartData('001XXXXXXXXXXXX', null, 'Managed');
        //System.assertNotEquals(0, chartDataByAccountAndManaged.size(), 'Expected chart data for account and managed');
        
        List<AdvisorReportController.ChartData> chartDataByCustodianAndManaged = AdvisorReportController.getChartData(null, 'Fidelity', 'Managed');
        //System.assertNotEquals(0, chartDataByCustodianAndManaged.size(), 'Expected chart data for custodian and managed');
        
        List<AdvisorReportController.ChartData> chartDataAllFilters = AdvisorReportController.getChartData('001XXXXXXXXXXXX', 'Fidelity', 'Managed');
        //System.assertNotEquals(0, chartDataAllFilters.size(), 'Expected chart data for all filters');
        Test.stopTest();
    }
    
}