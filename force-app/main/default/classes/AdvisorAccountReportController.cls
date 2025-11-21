public class AdvisorAccountReportController {
    public String userCompanyName { get; set; }
    public String userCompanyID { get; set; }
    public Decimal userCompanyInvestment { get; set; }
    public String chartDataJson { get; set; }
    public String chartAdvisorDataJson { get; set; }
    public List<List<String>> companyInvestmentRecordMatrix { get; set; }
    public List<List<String>> advisorsRecordMatrix { get; set; }
    public String selectedRadioOption { get; set; }
    public List<SelectOption> options { get; set; }
    public List<SelectOption> houseHoldAccountOptions { get; set; }
    public String selectedHouseHoldAccountName { get; set; }
    public List<AggregateResult> userCompanyInvestmentResults { get; set; }
    
    public AdvisorAccountReportController() {
        options = new List<SelectOption>();        
        options.add(new SelectOption('DGR', 'Demographics Report'));
        options.add(new SelectOption('AUM', 'AUM Report'));        
        options.add(new SelectOption('IND', 'Individual Report'));
        selectedRadioOption = 'DGR';
        
        userCompanyID = [SELECT RepAdvisorId__c FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1].RepAdvisorId__c;
        userCompanyName = [SELECT Name FROM Account WHERE Id = :userCompanyID AND IsPersonAccount = false LIMIT 1].Name;
        
        userCompanyInvestmentResults = [
            SELECT SUM(FinServ__Balance__c) totalBalance
            FROM FinServ__FinancialAccount__c
            WHERE (RepAdvisor__r.Account.RepAdvisorEntity__pc = :userCompanyID)
            AND RepAdvisor__r.Account.RepAdvisorEntity__pr.IsPersonAccount = false
        ];
        
        Decimal totalBalance = 0;
        if (!userCompanyInvestmentResults.isEmpty()) {
            totalBalance = (Decimal) userCompanyInvestmentResults[0].get('totalBalance');
        }
        userCompanyInvestment = (totalBalance != null) ? totalBalance.setScale(0, RoundingMode.FLOOR) : 0;
        
        chartDataJson = JSON.serialize(getDefaultChartData(userCompanyID, userCompanyName, userCompanyInvestmentResults));
        chartAdvisorDataJson = JSON.serialize(getAdvisorsChartData(userCompanyID));
        
        radioSelectionData();        
        houseHoldAccountOptions = getRelatedHouseholdAccounts(userCompanyID);
    }
    
    public void householdAccountChange() {
        radioSelectionData();
    }
    
    public void radioSelectionData() {
        companyInvestmentRecordMatrix = new List<List<String>>();
        advisorsRecordMatrix = new List<List<String>>();
        String advName = ApexPages.currentPage().getParameters().get('advName');
        
        if (selectedRadioOption == 'DGR') { 
            fetchDetailedData(userCompanyID, advName);
        }
        else if ((selectedRadioOption == 'AUM') || (selectedRadioOption == 'IND')) {
            fetchDetailedAUMData(userCompanyID, advName, selectedHouseHoldAccountName);
        }
    }
    
    @RemoteAction
    public static List<SelectOption> getRelatedHouseholdAccounts(String userCompanyID) {        
        List<FinServ__FinancialAccount__c> houseHoldAccounts = [
            SELECT Id, FinServ__Household__r.Name  
            FROM FinServ__FinancialAccount__c 
            WHERE (RepAdvisor__r.Account.RepAdvisorEntity__pc = :userCompanyID)
            ORDER BY FinServ__Household__r.Name ASC 
        ];
        
        Map<String, Id> nameToIdMap = new Map<String, Id>();
        List<SelectOption> options = new List<SelectOption>();
        
        for (FinServ__FinancialAccount__c pa : houseHoldAccounts) {
            if (!nameToIdMap.containsKey(pa.FinServ__Household__r.Name)) {
                nameToIdMap.put(pa.FinServ__Household__r.Name, pa.Id);
                options.add(new SelectOption(pa.FinServ__Household__r.Name, pa.FinServ__Household__r.Name));
            }
        }
        return options;
    }
    
    @RemoteAction
    public static List<ChartData> getDefaultChartData(String userCompanyID, String userCompanyName, List<AggregateResult> userCompanyInvestmentResults) {
        List<ChartData> chartData = new List<ChartData>();
        
        Decimal totalSum = (userCompanyInvestmentResults.size() > 0 && userCompanyInvestmentResults[0].get('totalBalance') != null)
            ? (Decimal) userCompanyInvestmentResults[0].get('totalBalance')
            : 0;
        
        if (userCompanyName != null) {
            chartData.add(new ChartData(userCompanyName, totalSum));
        }
        return chartData;
    }
    
    @RemoteAction
    public static List<ChartData> getAdvisorsChartData(String userCompanyID) {
        List<ChartData> chartData = new List<ChartData>();
        
        List<Account> advisorAccounts = [
            SELECT Id, Name FROM Account
            WHERE RepAdvisorEntity__pc = :userCompanyID
            AND IsPersonAccount = true
        ];
        
        if (advisorAccounts.isEmpty()) return chartData;
        
        List<AggregateResult> advisorBalances = [
            SELECT RepAdvisor__r.Name advisorName, SUM(FinServ__Balance__c) totalBalance
            FROM FinServ__FinancialAccount__c
            WHERE RepAdvisor__r.AccountId IN :advisorAccounts
            GROUP BY RepAdvisor__r.Name
        ];
        
        for (AggregateResult ar : advisorBalances) {
            String advisorName = (String) ar.get('advisorName');
            Decimal totalBalance = (Decimal) ar.get('totalBalance');
            if (advisorName != null && totalBalance != null && totalBalance != 0) {
                chartData.add(new ChartData(advisorName, totalBalance));
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
    
    private static final Integer maxRecords = 20000; 
    
    public void fetchDetailedData(String userCompanyID, String advName) {
        advisorsRecordMatrix.clear();
        
        // Start building the query
        String baseQuery = 'SELECT Id, FinServ__Household__r.Name, FinServ__FinancialAccountNumber__c, ' +
            'RepAdvisor__r.Name, FABirthday__c, FinServ__PrimaryOwner__c, HomePhone__c, FinServ__TaxID__c, ' +
            'FinServ__PrimaryOwner__r.Name, Email__c, FinServ__Address1__c, FinServ__City__c, FinServ__State__c, ' +
            'FinServ__Country__c, FinServ__PostalCode__c ' +
            'FROM FinServ__FinancialAccount__c ' +
            'WHERE RepAdvisor__r.Account.RepAdvisorEntity__pc = :userCompanyID';
        
        // Add conditions dynamically
        List<String> conditions = new List<String>();
        
        // Add advisor filter condition if 'advName' is provided
        if (String.isNotBlank(advName)) {
            conditions.add('RepAdvisor__r.Account.Name = :advName');
        }
        else {
            conditions.add('RepAdvisor__r.Account.RepAdvisorEntity__pr.IsPersonAccount = false');
        }
        
        // Combine the conditions into the base query
        if (!conditions.isEmpty()) {
            baseQuery += ' AND ' + String.join(conditions, ' AND ');
        }
        
        // Optionally limit records (for performance)
        baseQuery += ' ORDER BY FinServ__Household__r.Name ASC LIMIT :maxRecords';
        
        // Execute the query using the dynamically built query string
        List<FinServ__FinancialAccount__c> accounts = Database.query(baseQuery);
        
        List<List<String>> rows = new List<List<String>>();
        for (FinServ__FinancialAccount__c a : accounts) {
            rows.add(new List<String>{
                String.valueOf(getValue(a.FinServ__Household__r.Name)),
                    String.valueOf(getValue(a.FinServ__FinancialAccountNumber__c)),
                    String.valueOf(getValue(a.RepAdvisor__r.Name)),
                    String.valueOf(getValue(a.FABirthday__c)),
                    getTaxId(a.FinServ__TaxID__c),
                    String.valueOf(getValue(a.Email__c)),
                    String.valueOf(getValue(a.FinServ__Address1__c)),
                    String.valueOf(getValue(a.FinServ__City__c)),
                    String.valueOf(getValue(a.FinServ__State__c)),
                    String.valueOf(getValue(a.FinServ__PostalCode__c)),
                    String.valueOf(getValue(a.HomePhone__c)),
                    String.valueOf(a.FinServ__Household__c)
                    });
        }
        advisorsRecordMatrix = rows;
    }
    
    public void fetchDetailedAUMData(String userCompanyID, String advName, String selectedHouseHoldAccountName) {
        companyInvestmentRecordMatrix.clear();
        
        // Start with the base query
        String baseQuery = 'SELECT Id, FinServ__Household__r.Name, FinServ__FinancialAccountNumber__c, ' +
            'AccountType__c, Account_1_Source_of_Funds__c, FinServ__Household__r.Describe_Restriction__c, ' +
            'RiskTolerance__c, FinServ__InvestmentObjectives__c, FinServ__TimeHorizon__c, ' +
            'FinServ__Balance__c, Custodian__c, FinServ__Household__r.Annual_Fee__c, FACurrentNetCash__c, ' +
            'Billing_Frequency__c, Allocation_type__c ' +
            'FROM FinServ__FinancialAccount__c ' +
            'WHERE RepAdvisor__r.Account.RepAdvisorEntity__pc = :userCompanyID';
        
        // List to hold conditions
        List<String> conditions = new List<String>();
        
        // Add household filter if applicable
        if (String.isNotBlank(selectedHouseHoldAccountName) && (selectedRadioOption == 'IND')) {
            conditions.add('FinServ__Household__r.Name = :selectedHouseHoldAccountName');
        }
        
        // Add advisor filter if applicable
        if (String.isNotBlank(advName)) {
            conditions.add('RepAdvisor__r.Account.Name = :advName');
        } else {
            conditions.add('RepAdvisor__r.Account.RepAdvisorEntity__pr.IsPersonAccount = false');
        }
        
        // Add conditions to base query
        if (!conditions.isEmpty()) {
            baseQuery += ' AND ' + String.join(conditions, ' AND ');
        }
        
        baseQuery += ' ORDER BY FinServ__Household__r.Name ASC LIMIT :maxRecords';
        
        // Execute query
        List<FinServ__FinancialAccount__c> accounts = Database.query(baseQuery);
        
        List<List<String>> rows = new List<List<String>>();
        for (FinServ__FinancialAccount__c a : accounts) {
            rows.add(new List<String>{
                String.valueOf(getValue(a.FinServ__Household__r.Name)),
                    String.valueOf(getValue(a.FinServ__FinancialAccountNumber__c)),
                    String.valueOf(getValue(a.AccountType__c)),
                    String.valueOf(getValue(a.Account_1_Source_of_Funds__c)),
                    String.valueOf(getValue(a.FinServ__Household__r.Describe_Restriction__c)),
                    String.valueOf(getValue(a.RiskTolerance__c)),
                    String.valueOf(getValue(a.FinServ__InvestmentObjectives__c)),
                    String.valueOf(getValue(a.FinServ__TimeHorizon__c)),
                    String.valueOf(getValue(a.Custodian__c)),
                    String.valueOf(getValue(a.FinServ__Household__r.Annual_Fee__c)),
                    String.valueOf(getValue(a.Billing_Frequency__c)),
                    String.valueOf(getValue(a.Allocation_type__c)),
                    formatCurrency(a.FACurrentNetCash__c),
                    formatCurrency(a.FinServ__Balance__c),
                    String.valueOf(a.FinServ__Household__c)
                    });
        }
        companyInvestmentRecordMatrix = rows;
    }
    
    private Object getValue(Object value) {
        return value != null ? value : 'N/A';
    }
    
    private String getTaxId(String taxId) {
        return taxId != null ? 'XXXXX' + taxId.right(4) : 'N/A';
    }
    
    private String formatCurrency(Decimal value) {
        return value != null ? '$' + value.setScale(0, RoundingMode.FLOOR).format() : 'N/A';
    }
}