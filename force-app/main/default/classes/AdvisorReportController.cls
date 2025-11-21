public class AdvisorReportController {
    public String userCompanyName { get; set; }
    public Decimal userCompanyInvestment { get; set; }
    public String chartDataJson { get; set; }
    public List<SelectOption> personAccountOptions { get; set; }
    public List<AggregateResult> userCompanyInvestmentResults { get; set; }
	// User and company info
    private User currentUser;
    
    public AdvisorReportController() {   
        currentUser = [SELECT RepAdvisorId__c FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
        userCompanyName = [SELECT Name FROM Account WHERE Id = :currentUser.RepAdvisorId__c AND IsPersonAccount = false LIMIT 1].Name;
        userCompanyInvestmentResults = [SELECT SUM(FinServ__Balance__c) totalBalance
                                                       FROM FinServ__FinancialAccount__c
                                                       WHERE RepAdvisor__r.Account.RepAdvisorEntity__pr.Name = :userCompanyName
                                                       AND RepAdvisor__r.Account.RepAdvisorEntity__pr.IsPersonAccount = false];

        // Check if there are results and extract the total balance
        Decimal totalBalance = 0;
        if (!userCompanyInvestmentResults.isEmpty()) {
            totalBalance = (Decimal)userCompanyInvestmentResults[0].get('totalBalance');
        }
        
        // Round down the total balance using RoundingMode.FLOOR
		userCompanyInvestment = (totalBalance != null) ? totalBalance.setScale(0, RoundingMode.FLOOR) : 0;
                
        personAccountOptions = getRelatedPersonAccounts(userCompanyName);
        chartDataJson = JSON.serialize(getDefaultChartData(userCompanyInvestmentResults, userCompanyName));
    }

    @RemoteAction
    public static List<ChartData> getDefaultChartData(List<AggregateResult> userCompanyInvestmentResults, String userCompanyName) {
        List<ChartData> chartData = new List<ChartData>();
        
        // Get the total balance from the aggregate result
        Decimal totalSum = (userCompanyInvestmentResults.size() > 0 && userCompanyInvestmentResults[0].get('totalBalance') != null) 
                           ? (Decimal)userCompanyInvestmentResults[0].get('totalBalance') 
                           : 0;
        
        //System.debug('Total Balance: ' + totalSum);
        
        Set<String> addedCompany = new Set<String>();        
            if (userCompanyInvestmentResults!= null && !addedCompany.contains(userCompanyName)) {
                chartData.add(new ChartData(userCompanyName, totalSum));
                addedCompany.add(userCompanyName); // Mark this advisor as added
            }
        return chartData;
    }

    @RemoteAction
    public static List<SelectOption> getRelatedPersonAccounts(String userCompanyName) {
        List<Account> personAccounts = [SELECT Id, Name FROM Account 
                                        WHERE RepAdvisorEntity__pr.Name = :userCompanyName and IsPersonAccount = true];

        List<SelectOption> options = new List<SelectOption>();
        for (Account pa : personAccounts) {
            options.add(new SelectOption(pa.Id, pa.Name));
        }

        return options;
    }

    @RemoteAction
    public static List<ChartData> getChartData(String accountId, String custodianValue, String managedValue) {
        String userCompanyName = [SELECT CompanyName FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1].CompanyName;
        List<ChartData> chartData = new List<ChartData>();
		
        // Handle combination of all three filters
        if ( accountId != '-- Select Advisor --' && custodianValue != '-- Select Custodian --' && managedValue != '-- Select Managed/Unmanaged --') {
            chartData.addAll(getChartDataByAllFilters(accountId, custodianValue, managedValue, userCompanyName));
        }
        // Handle combination of Account and Custodian
        else if (accountId != '-- Select Advisor --' && custodianValue != '-- Select Custodian --') {
            chartData.addAll(getChartDataByAccountAndCustodian(accountId, custodianValue, userCompanyName));
        }
        // Handle combination of Account and Managed
        else if ( accountId != '-- Select Advisor --' && managedValue != '-- Select Managed/Unmanaged --') {
            chartData.addAll(getChartDataByAccountAndManaged(accountId, managedValue, userCompanyName));
        }
        // Handle combination of Custodian and Managed
        else if (custodianValue != '-- Select Custodian --' && managedValue != '-- Select Managed/Unmanaged --') {
            chartData.addAll(getChartDataByCustodianAndManaged(custodianValue, managedValue, userCompanyName));
        }
        // Handle the advisor-based filtering
        else if (accountId != '-- Select Advisor --') {
            chartData.addAll(getChartDataByAdvisor(accountId));
        }
        // Handle the custodian-based filtering
        else if (custodianValue != '-- Select Custodian --') {
            chartData.addAll(getChartDataByCustodian(custodianValue, userCompanyName));
        }
        // Handle the managed/unmanaged filtering
        else if (managedValue != '-- Select Managed/Unmanaged --') {
            chartData.addAll(getChartDataByManaged(managedValue, userCompanyName));
        }     
        return chartData;
    }

    // Helper methods to avoid code repetition

    public static List<ChartData> getChartDataByAdvisor(String accountId) {
        List<ChartData> chartData = new List<ChartData>();

        // Query to get all financial accounts for the advisor
        List<FinServ__FinancialAccount__c> advisorData = [SELECT Id, FinServ__Balance__c, RepAdvisor__r.Name 
                                                          FROM FinServ__FinancialAccount__c
                                                          WHERE RepAdvisor__r.AccountId = :accountId];
        
        // Aggregate query to calculate the total balance
        AggregateResult[] results = [SELECT SUM(FinServ__Balance__c) totalBalance
                                      FROM FinServ__FinancialAccount__c
                                      WHERE RepAdvisor__r.AccountId = :accountId];
        
        // Get the total balance from the aggregate result
        Decimal totalSum = (results.size() > 0 && results[0].get('totalBalance') != null) 
                           ? (Decimal)results[0].get('totalBalance') 
                           : 0;
        
        System.debug('Total Balance: ' + totalSum);
        
        // Use a Set to track which advisors have been added to chartData
        Set<String> addedAdvisors = new Set<String>();
        
        // Loop through individual financial accounts and add to chart data
        for (FinServ__FinancialAccount__c advisorDetails : advisorData) {
            String advisorName = advisorDetails.RepAdvisor__r.Name;
            
            // Check if this advisor's name has already been added
            if (advisorDetails.FinServ__Balance__c != null && !addedAdvisors.contains(advisorName)) {
                chartData.add(new ChartData(advisorName, totalSum));
                addedAdvisors.add(advisorName); // Mark this advisor as added
            }
        }
        
        return chartData;	
    }

    public static List<ChartData> getChartDataByCustodian(String custodianValue, String userCompanyName) {
       List<ChartData> chartData = new List<ChartData>();
		
        // Query to get custodian data based on specified criteria
        List<EAST_RepID__c> custodianData = [SELECT Id, Name, Custodian__c, Total_AUM__c
                                              FROM EAST_RepID__c 
                                              WHERE Custodian__c = :custodianValue
                                              //AND Primary_Rep_User__r.CompanyName = :userCompanyName
                                            ];
        List<String> custodianIds = new List<String>();
            for (EAST_RepID__c rep : custodianData) {
                custodianIds.add(rep.Name);
            }
        AggregateResult[] results = [SELECT  SUM(FinServ__Balance__c) totalBalance
                                                          FROM FinServ__FinancialAccount__c 
                                     WHERE RepAdvisor__r.Account.RepAdvisorEntity__pr.Name  = :userCompanyName 
                                     and RepAdvisor__r.Account.RepAdvisorEntity__pr.IsPersonAccount = false
                                     AND RepID__c =:custodianIds ];        
        
        // Get the total balance from the aggregate result
        Decimal totalSum = (results.size() > 0 && results[0].get('totalBalance') != null) 
                           ? (Decimal)results[0].get('totalBalance') 
                           : 0;
        
        System.debug('Total Balance: ' + totalSum);
        
        // Use a Set to track which custodians have been added to chartData
        Set<String> addedCustodians = new Set<String>();
        
        // Loop through custodian data and add to chart data
        for (EAST_RepID__c custodianDetail : custodianData) {
            String custodianName = custodianDetail.Custodian__c;
        
            // Check if this custodian's name has already been added
            if (custodianName != null && !addedCustodians.contains(custodianName)) {
                // Use Total_AUM__c instead of balance
                chartData.add(new ChartData(custodianName, totalSum));
                addedCustodians.add(custodianName); // Mark this custodian as added
            }
        }
        
        return chartData;
    }

    public static List<ChartData> getChartDataByManaged(String managedValue, String userCompanyName) {
         List<ChartData> chartData = new List<ChartData>();

        // Query to get custodian data based on specified criteria
        boolean managedValue1 = (managedValue == 'Managed');
        List<EAST_RepID__c> managedData = [SELECT Id, Name, Managed__c, Total_AUM__c
                                           FROM EAST_RepID__c 
                                           WHERE Managed__c = :managedValue1
                                           //AND Primary_Rep_User__r.CompanyName = :userCompanyName
                                           ];
        List<String> managedIds = new List<String>();
            for (EAST_RepID__c rep : managedData) {
                managedIds.add(rep.Name);
            }
        AggregateResult[] results = [SELECT  SUM(FinServ__Balance__c) totalBalance
                                                          FROM FinServ__FinancialAccount__c 
                                     WHERE RepAdvisor__r.Account.RepAdvisorEntity__pr.Name  = :userCompanyName 
                                     and RepAdvisor__r.Account.RepAdvisorEntity__pr.IsPersonAccount = false
                                     AND RepID__c =:managedIds];        
        
        // Get the total balance from the aggregate result
        Decimal totalSum = (results.size() > 0 && results[0].get('totalBalance') != null) 
                           ? (Decimal)results[0].get('totalBalance') 
                           : 0;
        
        System.debug('Total Balance: ' + totalSum);
        
        Set<boolean> addedManaged = new Set<boolean>();
        
        // Loop through custodian data and add to chart data
        for (EAST_RepID__c managedDetail : managedData) {
            boolean managed = managedDetail.Managed__c;
        
            // Check if this custodian's name has already been added
            if (managed != null && !addedManaged.contains(managed)) {
                // Use totalSum instead of balance
                chartData.add(new ChartData(String.valueOf(managedValue), totalSum));
                addedManaged.add(managed); // Mark this custodian as added
            }
        }
        
        return chartData;
        
    }

    public static List<ChartData> getChartDataByAccountAndCustodian(String accountId, String custodianValue, String userCompanyName) {
        List<ChartData> chartData = new List<ChartData>();

        // Query to get custodian data based on specified criteria
        List<EAST_RepID__c> custodianData = [SELECT Id, Name, Custodian__c, Total_AUM__c
                                              FROM EAST_RepID__c 
                                              WHERE Custodian__c = :custodianValue
                                              //AND Primary_Rep_User__r.CompanyName = :userCompanyName
                                            ];
        List<String> custodianIds = new List<String>();
            for (EAST_RepID__c rep : custodianData) {
                custodianIds.add(rep.Name);
            }
        AggregateResult[] results = [SELECT  SUM(FinServ__Balance__c) totalBalance
                                                          FROM FinServ__FinancialAccount__c 
                                     WHERE RepAdvisor__r.Account.RepAdvisorEntity__pr.Name  = :userCompanyName 
                                     and RepAdvisor__r.Account.RepAdvisorEntity__pr.IsPersonAccount = false
                                     AND RepAdvisor__r.AccountId = :accountId
                                     AND RepID__c =:custodianIds ];        
        
        // Get the total balance from the aggregate result
        Decimal totalSum = (results.size() > 0 && results[0].get('totalBalance') != null) 
                           ? (Decimal)results[0].get('totalBalance') 
                           : 0;
        
        System.debug('Total Balance: ' + totalSum);
        List<FinServ__FinancialAccount__c> advisorData = [SELECT Id, FinServ__Balance__c, RepAdvisor__r.Name 
                                                          FROM FinServ__FinancialAccount__c
                                                          WHERE RepAdvisor__r.AccountId = :accountId];
        // Use a Set to track which advisors have been added to chartData
        Set<String> addedAdvisors = new Set<String>();
        
        // Loop through individual financial accounts and add to chart data
        for (FinServ__FinancialAccount__c advisorDetails : advisorData) {
            String advisorName = advisorDetails.RepAdvisor__r.Name;
            
            // Check if this advisor's name has already been added
            if (advisorDetails.FinServ__Balance__c != null && !addedAdvisors.contains(advisorName)) {
                chartData.add(new ChartData(advisorName, totalSum));
                addedAdvisors.add(advisorName); // Mark this advisor as added
            }
        }
        
        return chartData;
    }

    public static List<ChartData> getChartDataByAccountAndManaged(String accountId, String managedValue, String userCompanyName) {
        List<ChartData> chartData = new List<ChartData>();

        // Query to get custodian data based on specified criteria
        boolean managedValue1 = (managedValue == 'Managed');
        List<EAST_RepID__c> managedData = [SELECT Id, Name, Managed__c, Total_AUM__c
                                           FROM EAST_RepID__c 
                                           WHERE Managed__c = :managedValue1
                                           //AND Primary_Rep_User__r.CompanyName = :userCompanyName
                                          ];
        List<String> managedIds = new List<String>();
            for (EAST_RepID__c rep : managedData) {
                managedIds.add(rep.Name);
            }
        AggregateResult[] results = [SELECT  SUM(FinServ__Balance__c) totalBalance
                                                          FROM FinServ__FinancialAccount__c 
                                     WHERE RepAdvisor__r.Account.RepAdvisorEntity__pr.Name  = :userCompanyName 
                                     and RepAdvisor__r.Account.RepAdvisorEntity__pr.IsPersonAccount = false
                                      AND RepAdvisor__r.AccountId = :accountId
                                     AND RepID__c =:managedIds];        
        
        // Get the total balance from the aggregate result
        Decimal totalSum = (results.size() > 0 && results[0].get('totalBalance') != null) 
                           ? (Decimal)results[0].get('totalBalance') 
                           : 0;
        
        System.debug('Total Balance: ' + totalSum);
        
        List<FinServ__FinancialAccount__c> advisorData = [SELECT Id, FinServ__Balance__c, RepAdvisor__r.Name 
                                                          FROM FinServ__FinancialAccount__c
                                                          WHERE RepAdvisor__r.AccountId = :accountId];
        // Use a Set to track which advisors have been added to chartData
        Set<String> addedAdvisors = new Set<String>();
        
        // Loop through individual financial accounts and add to chart data
        for (FinServ__FinancialAccount__c advisorDetails : advisorData) {
            String advisorName = advisorDetails.RepAdvisor__r.Name;
            
            // Check if this advisor's name has already been added
            if (advisorDetails.FinServ__Balance__c != null && !addedAdvisors.contains(advisorName)) {
                chartData.add(new ChartData(advisorName, totalSum));
                addedAdvisors.add(advisorName); // Mark this advisor as added
            }
        }
        return chartData;
        
    }

    public static List<ChartData> getChartDataByCustodianAndManaged(String custodianValue, String managedValue, String userCompanyName) {
       List<ChartData> chartData = new List<ChartData>();

        // Query to get custodian data based on specified criteria
        boolean managedValue1 = (managedValue == 'Managed');
        List<EAST_RepID__c> managedData = [SELECT Id, Name, Managed__c, Total_AUM__c, Custodian__c
                                           FROM EAST_RepID__c 
                                           WHERE Managed__c = :managedValue1 AND  Custodian__c = :custodianValue
                                           //AND Primary_Rep_User__r.CompanyName = :userCompanyName
                                          ];
        List<String> managedIds = new List<String>();
            for (EAST_RepID__c rep : managedData) {
                managedIds.add(rep.Name);
            }
        AggregateResult[] results = [SELECT  SUM(FinServ__Balance__c) totalBalance
                                                          FROM FinServ__FinancialAccount__c 
                                     WHERE RepAdvisor__r.Account.RepAdvisorEntity__pr.Name  = :userCompanyName 
                                     and RepAdvisor__r.Account.RepAdvisorEntity__pr.IsPersonAccount = false
                                     AND RepID__c =:managedIds];        
        
        // Get the total balance from the aggregate result
        Decimal totalSum = (results.size() > 0 && results[0].get('totalBalance') != null) 
                           ? (Decimal)results[0].get('totalBalance') 
                           : 0;
        
        System.debug('Total Balance: ' + totalSum);
        
        // Use a Set to track which custodians have been added to chartData
        Set<String> addedCustodians = new Set<String>();
        
        // Loop through custodian data and add to chart data
        for (EAST_RepID__c custodianDetail : managedData) {
            String custodianName = custodianDetail.Custodian__c;
        
            // Check if this custodian's name has already been added
            if (custodianName != null && !addedCustodians.contains(custodianName)) {
                // Use Total_AUM__c instead of balance
                chartData.add(new ChartData(custodianName, totalSum));
                addedCustodians.add(custodianName); // Mark this custodian as added
            }
        }
        
        return chartData;
    }

    public static List<ChartData> getChartDataByAllFilters(String accountId, String custodianValue, String managedValue, String userCompanyName) {
        List<ChartData> chartData = new List<ChartData>();

        // Query to get custodian data based on specified criteria
        boolean managedValue1 = (managedValue == 'Managed');
        List<EAST_RepID__c> managedData = [SELECT Id, Name, Managed__c, Total_AUM__c
                                           FROM EAST_RepID__c 
                                           WHERE Managed__c = :managedValue1 AND  Custodian__c = :custodianValue
                                           //AND Primary_Rep_User__r.CompanyName = :userCompanyName
                                          ];
        List<String> managedIds = new List<String>();
            for (EAST_RepID__c rep : managedData) {
                managedIds.add(rep.Name);
            }
        AggregateResult[] results = [SELECT  SUM(FinServ__Balance__c) totalBalance
                                                          FROM FinServ__FinancialAccount__c 
                                     WHERE RepAdvisor__r.Account.RepAdvisorEntity__pr.Name  = :userCompanyName 
                                     and RepAdvisor__r.Account.RepAdvisorEntity__pr.IsPersonAccount = false
                                       AND RepAdvisor__r.AccountId = :accountId
                                     AND RepID__c =:managedIds];        
        
        // Get the total balance from the aggregate result
        Decimal totalSum = (results.size() > 0 && results[0].get('totalBalance') != null) 
                           ? (Decimal)results[0].get('totalBalance') 
                           : 0;
        
        System.debug('Total Balance: ' + totalSum);
        // Query to get all financial accounts for the advisor
        List<FinServ__FinancialAccount__c> advisorData = [SELECT Id, FinServ__Balance__c, RepAdvisor__r.Name 
                                                          FROM FinServ__FinancialAccount__c
                                                          WHERE RepAdvisor__r.AccountId = :accountId];
        // Use a Set to track which advisors have been added to chartData
        Set<String> addedAdvisors = new Set<String>();
        
        // Loop through individual financial accounts and add to chart data
        for (FinServ__FinancialAccount__c advisorDetails : advisorData) {
            String advisorName = advisorDetails.RepAdvisor__r.Name;
            
            // Check if this advisor's name has already been added
            if (advisorDetails.FinServ__Balance__c != null && !addedAdvisors.contains(advisorName)) {
                chartData.add(new ChartData(advisorName, totalSum));
                addedAdvisors.add(advisorName); // Mark this advisor as added
            }
        }
        
        return chartData;
    }

    public class ChartData {
        public String entityName { get; set; }
        public Decimal investment { get; set; } 
        
        public ChartData(String entityName, Decimal investment) {
            this.entityName = entityName;
            this.investment = investment;
        }
    }
}