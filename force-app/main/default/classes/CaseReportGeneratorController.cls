public class CaseReportGeneratorController {
    public String chartDataJson { get; set; }
    public String chartDataJsonStatus { get; set; }
    public String selectedTimeRange { get; set; }
    public List<List<String>> caseRecordsMatrix { get; set; }
    
    public String sortField { get; set; }
    public String sortDirection { get; set; }
    
    // User and company info
    private User currentUser;
    private String companyName;
    private String userProfile;
    
    public CaseReportGeneratorController() {
        // Initialize sorting defaults
        sortField = 'CreatedDate';
        sortDirection = 'DESC';
        
        // Load user info
        currentUser = [SELECT RepAdvisorId__c, Profile.Name FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
        companyName = [SELECT Name FROM Account WHERE Id = :currentUser.RepAdvisorId__c AND IsPersonAccount = false LIMIT 1].Name;
        userProfile = currentUser.Profile.Name;
        
        selectedTimeRange = 'Last 30 Days'; // default
        
        // Initialize matrix
        caseRecordsMatrix = new List<List<String>>();
        
        // Load initial charts
        refreshChart();
        refreshChart1();
        
        // Load initial case data based on URL parameters if any
        String entityName = ApexPages.currentPage().getParameters().get('entityName');
        String statusList = ApexPages.currentPage().getParameters().get('statusList');
        String urlSelectedTimeRange = ApexPages.currentPage().getParameters().get('selectedTimeRange');
        if (urlSelectedTimeRange != null) {
            selectedTimeRange = urlSelectedTimeRange;
        }
        
        if (entityName != null) {
            fetchDetailedData(entityName, selectedTimeRange);
        } else if (statusList != null) {
            fetchDetailedDataByStatus(statusList, selectedTimeRange);
        } else {
            loadCases(); // Load default case list with sorting
        }
    }
    
    // Load cases with sorting applied
    public void loadCases() {
        caseRecordsMatrix.clear();        
        // Load initial case data based on URL parameters if any
        String entityName = ApexPages.currentPage().getParameters().get('entityName');
        String statusList = ApexPages.currentPage().getParameters().get('statusList');
        String urlSelectedTimeRange = ApexPages.currentPage().getParameters().get('selectedTimeRange');
        if (urlSelectedTimeRange != null) {
            selectedTimeRange = urlSelectedTimeRange;
        }
        
        if (entityName != null) {
            fetchDetailedData(entityName, selectedTimeRange);
        } else if (statusList != null) {
            fetchDetailedDataByStatus(statusList, selectedTimeRange);
        } 
    }
    
    // Toggle sort direction for CreatedDate column and reload data
    public void toggleSort() {
        if (sortField == 'CreatedDate') {
            sortDirection = (sortDirection == 'ASC') ? 'DESC' : 'ASC';
        } else {
            sortField = 'CreatedDate';
            sortDirection = 'ASC';
        }
        loadCases();
    }
    
    // Helper to get the start date based on selectedTimeRange string
    private DateTime getStartDate(String selectedTimeRange) {
        if (selectedTimeRange == 'All') {
            return DateTime.newInstance(1970, 1, 1, 0, 0, 0);
        } else if (selectedTimeRange == 'Last 30 Days') {
            return DateTime.now().addDays(-30);
        } else if (selectedTimeRange == 'Last 60 Days') {
            return DateTime.now().addDays(-60);
        } else {
            return DateTime.now().addDays(-90); // Default Last 90 Days
        }
    }
    
    // Refresh chart data methods (unchanged)
    public void refreshChart() {
        List<ChartData> chartData = getChartData(selectedTimeRange);
        chartDataJson = JSON.serialize(chartData);
    }
    
    public void refreshChart1() {
        List<ChartDataByStatus> chartDataByStatus = getChartDataByStatus(selectedTimeRange);
        chartDataJsonStatus = JSON.serialize(chartDataByStatus);
    }
 
    // Fetch detailed data filtered by entity name
    private void fetchDetailedData(String entityName, String selectedTimeRange) {
        caseRecordsMatrix.clear();
        DateTime startDate = getStartDate(selectedTimeRange);
        
        Set<String> allowedStatuses = new Set<String>{'Closed', 'New', 'In Process', 'NIGO'};
        
        String query = 'SELECT Id, CaseNumber, Subject, Status, ClosedDate, CreatedDate, Advisor_Status__c,' +
                       'Account.RepAdvisorEntity__pr.Name, Account.Name, Account.RecordType.Name ' +
                       'FROM Case ' +
                       'WHERE (Account.RepAdvisorEntity__pr.Name = :companyName ' +
                       'OR Account.RepAdvisor__pr.Account.RepAdvisorEntity__pr.Name = :companyName ' +
                       'OR Account.RepAdvisor__r.Account.RepAdvisorEntity__pr.Name = :companyName ' +
                       'OR Contact.Account.RepAdvisorEntity__pr.Name = :companyName ' +
                       'OR Contact.Account.RepAdvisor__pr.Account.RepAdvisorEntity__pr.Name = :companyName) ' +
                       'AND CreatedDate >= :startDate ';
        
        if (userProfile == 'Agent 2' || userProfile == 'Primary Agent') {
            query += 'AND Advisor_Status__c IN :allowedStatuses ';
        }
        
        query += 'ORDER BY ' + sortField + ' ' + sortDirection;
        
        List<Case> detailedCases = Database.query(query);
        
        for (Case c : detailedCases) {
            caseRecordsMatrix.add(new List<String>{
                c.CaseNumber,
                //c.Account.Name = (c.Account.RecordType != null && c.Account.RecordType.Name == 'Household')? c.Account.Name: 'N/A',
                c.Account.Name,
                c.Subject != null ? c.Subject : 'N/A',
                c.CreatedDate != null ? c.CreatedDate.format('MM/dd/yyyy h:mm a') : 'N/A',
                c.ClosedDate != null ? c.ClosedDate.format('MM/dd/yyyy h:mm a') : 'N/A',
                //c.Status,
                    c.Advisor_Status__c,
                c.Id
            });
        }
    }
    
    // Fetch detailed data filtered by status list
    private void fetchDetailedDataByStatus(String statusList, String selectedTimeRange) {
        caseRecordsMatrix.clear();
        DateTime startDate = getStartDate(selectedTimeRange);
        
        List<String> statusFilter = statusList.split(',');
        Set<String> allowedStatuses = new Set<String>{'Closed', 'New', 'In Process', 'NIGO', 'Waiting on Customer', 'Waiting on Review'};//Shikha - Added the statuses NIGO, In Process
        
        List<String> filteredStatusList = new List<String>();
        if (userProfile == 'Agent 2' || userProfile == 'Primary Agent') {
            for (String status : statusFilter) {
                if (allowedStatuses.contains(status.trim())) {
                    filteredStatusList.add(status.trim());
                }
            }
        } else {
            filteredStatusList = statusFilter;
        }
        
        String query = 'SELECT Id, CaseNumber, Subject, Status, ClosedDate, CreatedDate, Advisor_Status__c, ' +
                       'Account.RepAdvisorEntity__pr.Name, Account.Name, Account.RecordType.Name ' +
                       'FROM Case ' +
                       'WHERE (Account.RepAdvisorEntity__pr.Name = :companyName ' +
                       'OR Account.RepAdvisor__pr.Account.RepAdvisorEntity__pr.Name = :companyName ' +
                       'OR Account.RepAdvisor__r.Account.RepAdvisorEntity__pr.Name = :companyName ' +
                       'OR Contact.Account.RepAdvisorEntity__pr.Name = :companyName ' +
                       'OR Contact.Account.RepAdvisor__pr.Account.RepAdvisorEntity__pr.Name = :companyName) ' +
                       'AND CreatedDate >= :startDate ' +
                       'AND Advisor_Status__c IN :filteredStatusList ' +
                       'ORDER BY ' + sortField + ' ' + sortDirection;
        
        List<Case> detailedCases = Database.query(query);
        
        for (Case c : detailedCases) {
            caseRecordsMatrix.add(new List<String>{
                c.CaseNumber,
                //c.Account.Name = (c.Account.RecordType != null && c.Account.RecordType.Name == 'Household')? c.Account.Name: 'N/A',
                c.Account.Name,
                c.Subject != null ? c.Subject : 'N/A',
                c.CreatedDate != null ? c.CreatedDate.format('MM/dd/yyyy h:mm a') : 'N/A',
                c.ClosedDate != null ? c.ClosedDate.format('MM/dd/yyyy h:mm a') : 'N/A',
                //c.Status,
                    c.Advisor_Status__c,
                c.Id
            });
        }
    }
    
    // Sort arrow for UI
    public String getSortArrow() {
        return sortDirection == 'ASC' ? '▲' : '▼';
    }
    
   
    @RemoteAction
    public static List<ChartData> getChartData(String selectedTimeRange) {
        // Fetch the current user's company name
        User currentUser = [SELECT RepAdvisorId__c, Profile.Name FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
        String companyName = [SELECT Name FROM Account WHERE Id = :currentUser.RepAdvisorId__c  and IsPersonAccount = false LIMIT 1].Name;
        String userProfile = currentUser.Profile.Name;
        //System.debug('2nd selection time: ' + selectedTimeRange);
        DateTime startDate;
        if (selectedTimeRange == 'All') {
            startDate = DateTime.newInstance(1970, 1, 1, 0, 0, 0); 
        } else if (selectedTimeRange == 'Last 30 Days') {
            startDate = DateTime.now().addDays(-30);
        } else if (selectedTimeRange == 'Last 60 Days') {
            startDate = DateTime.now().addDays(-60);
        } else { // Default to Last 90 Days
            startDate = DateTime.now().addDays(-90);
        }
        //System.debug('startDate: ' + startDate);
        // Query to fetch cases for the current user's company within the selected date range
        List<Case> cases = [SELECT Id, CaseNumber, Subject, Status, Priority, 
                            Account.RepAdvisorEntity__pr.Name, Account.Name, ClosedDate, CreatedDate,Advisor_Status__c, 
                            Contact.Account.RepAdvisorEntity__pr.Name, Contact.Account.RepAdvisor__pr.Account.RepAdvisorEntity__pr.Name
                            FROM Case 
                            WHERE  (Account.RepAdvisorEntity__pr.Name = :companyName 
                                    OR Account.RepAdvisor__pr.Account.RepAdvisorEntity__pr.Name = :companyName
                                    OR Account.RepAdvisor__r.Account.RepAdvisorEntity__pr.Name = :companyName
                                    OR Contact.Account.RepAdvisorEntity__pr.Name = :companyName
                                    OR Contact.Account.RepAdvisor__pr.Account.RepAdvisorEntity__pr.Name = :companyName) AND CreatedDate >= :startDate];
        
        // Create a map to hold the count of cases by status
        Map<String, Integer> entityCaseCountMap = new Map<String, Integer>();
        
        // Define allowed statuses for specific profiles
        Set<String> allowedStatuses = new Set<String>{'Closed', 'New', 'In Process', 'NIGO'};
            for (Case c : cases) {
                //String entityName = c.Account.RepAdvisorEntity__pr.Name; 
                String statusName = c.Advisor_Status__c; 
                if (userProfile == 'Agent 2' || userProfile == 'Primary Agent') {
                    if(allowedStatuses.contains(statusName)){
                        entityCaseCountMap.put(companyName , entityCaseCountMap.get(companyName) == null ? 1 : entityCaseCountMap.get(companyName) + 1); 
                    }
                } else {
                    entityCaseCountMap.put(companyName , entityCaseCountMap.get(companyName) == null ? 1 : entityCaseCountMap.get(companyName) + 1); 
                }
            }
        
        // Create a list of ChartData objects
        List<ChartData> chartData = new List<ChartData>();
        for (String entity : entityCaseCountMap.keySet()) {
            chartData.add(new ChartData(entity, entityCaseCountMap.get(entity)));
        }
        
        return chartData;
    }
    
    public class ChartData {
        public String entityName { get; set; }
        public Integer caseCount { get; set; }
        
        public ChartData(String entityName, Integer caseCount) {
            this.entityName = entityName;
            this.caseCount = caseCount;
        }
    }
    
    @RemoteAction
    public static List<chartDataByStatus> getChartDataByStatus(String selectedTimeRange) {
        // Fetch the current user's company name and profile
        User currentUser = [SELECT RepAdvisorId__c, Profile.Name FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
        String companyName = [SELECT Name FROM Account WHERE Id = :currentUser.RepAdvisorId__c  and IsPersonAccount = false LIMIT 1].Name;
        String userProfile = currentUser.Profile.Name;
        
        DateTime startDate;
        if (selectedTimeRange == 'All') {
            startDate = DateTime.newInstance(1970, 1, 1, 0, 0, 0); 
        } else if (selectedTimeRange == 'Last 30 Days') {
            startDate = DateTime.now().addDays(-30);
        } else if (selectedTimeRange == 'Last 60 Days') {
            startDate = DateTime.now().addDays(-60);
        } else { // Default to Last 90 Days
            startDate = DateTime.now().addDays(-90);
        }
        
        // Query to fetch cases for the current user's company
        List<Case> cases = [SELECT Id, CaseNumber, Subject, Status, Advisor_Status__c, Priority, Account.RepAdvisorEntity__pr.Name, Account.Name, ClosedDate, CreatedDate
                            FROM Case 
                            WHERE (Account.RepAdvisorEntity__pr.Name = :companyName 
                                   OR Account.RepAdvisor__pr.Account.RepAdvisorEntity__pr.Name = :companyName
                                   OR Account.RepAdvisor__r.Account.RepAdvisorEntity__pr.Name = :companyName
                                   OR Contact.Account.RepAdvisorEntity__pr.Name = :companyName
                                   OR Contact.Account.RepAdvisor__pr.Account.RepAdvisorEntity__pr.Name = :companyName)  AND CreatedDate >= :startDate];
        
        // Create a map to hold the count of cases by status
        Map<String, Integer> entityCaseCountMap = new Map<String, Integer>();
        
        // Define allowed statuses for specific profiles
        Set<String> allowedStatuses = new Set<String>{'Closed', 'New', 'In Process', 'NIGO'};
            
            if (userProfile == 'Agent 2' || userProfile == 'Primary Agent') {
                // Add all relevant statuses here
                for (String status : allowedStatuses) {
                    entityCaseCountMap.put(status, 0);
                }
            }
        // Populate the map with data from the cases based on user profile
        for (Case c : cases) {
            String statusName = c.Advisor_Status__c; // Ensure this is the correct field name
            // Check if user profile is one of the specified profiles
            if (userProfile == 'Agent 2' || userProfile == 'Primary Agent') {
                // Only allow specific statuses for these profiles
                if (allowedStatuses.contains(statusName)) { 
                    if (entityCaseCountMap.containsKey(statusName)) {
                        entityCaseCountMap.put(statusName , entityCaseCountMap.get(statusName) == null ? 1 : entityCaseCountMap.get(statusName) + 1);  // Increment count
                    } else {
                        entityCaseCountMap.put(statusName, 1); // Initialize count
                    }
                }
            } else {
                // Allow all statuses for other profiles
                if (entityCaseCountMap.containsKey(statusName)) {
                    entityCaseCountMap.put(statusName , entityCaseCountMap.get(statusName) == null ? 1 : entityCaseCountMap.get(statusName) + 1);  // Increment count
                } else {
                    entityCaseCountMap.put(statusName, 1); // Initialize count
                }
            }
        }
        
        // Create a list of ChartData objects
        List<ChartDataByStatus> chartDataByStatus = new List<ChartDataByStatus>();
        for (String status : entityCaseCountMap.keySet()) {
            chartDataByStatus.add(new ChartDataByStatus(status, entityCaseCountMap.get(status)));
        }
        
        return chartDataByStatus;
    }
    public class ChartDataByStatus {
        public String statusName { get; set; }
        public Integer caseCount { get; set; }
        
        public ChartDataByStatus(String statusName, Integer caseCount) {
            this.statusName = statusName;
            this.caseCount = caseCount;
        }
    }
}