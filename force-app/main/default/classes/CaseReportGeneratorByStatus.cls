public class CaseReportGeneratorByStatus {
    public String chartDataJson { get; set; }
    public String selectedTimeRange { get; set; } // Store selected time range
    
    public CaseReportGeneratorByStatus() {
        selectedTimeRange = 'Last 30 Days'; // Default selection
        
        refreshChart(); // Load initial chart data based on selection
    }
    
    public void refreshChart() {
        List<ChartData> chartData = getChartData(selectedTimeRange); // Pass default selection to get initial data
        chartDataJson = JSON.serialize(chartData); // Serialize the chart data to JSON
    }
    
    @RemoteAction
    public static List<ChartData> getChartData(String selectedTimeRange) {
        // Fetch the current user's company name and profile
        User currentUser = [SELECT Id, CompanyName, Profile.Name FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
        String companyName = currentUser.CompanyName;
        String userProfile = currentUser.Profile.Name;
        //String adminPortalUser = '005VJ000001mHE5YAM'; // Admin Portal User Id
        
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
        List<Case> cases = [SELECT Id, CaseNumber, Subject, Status, Priority, Account.RepAdvisorEntity__pr.Name, Account.Name, ClosedDate, CreatedDate
                            FROM Case 
                            WHERE (Account.RepAdvisorEntity__pr.Name = :companyName 
                                    OR Account.RepAdvisor__pr.Account.RepAdvisorEntity__pr.Name = :companyName
                                    OR Account.RepAdvisor__r.Account.RepAdvisorEntity__pr.Name = :companyName
                                    OR Contact.Account.RepAdvisorEntity__pr.Name = :companyName
                                    OR Contact.Account.RepAdvisor__pr.Account.RepAdvisorEntity__pr.Name = :companyName)  AND CreatedDate >= :startDate];
        
        // Create a map to hold the count of cases by status
        Map<String, Integer> entityCaseCountMap = new Map<String, Integer>();
        
        // Define allowed statuses for specific profiles
        Set<String> allowedStatuses = new Set<String>{'Closed', 'New', 'Waiting on Review', 'Waiting on Customer'};
            
             if (userProfile == 'Agent 2' || userProfile == 'Primary Agent') {
                // Add all relevant statuses here
                for (String status : allowedStatuses) {
                    entityCaseCountMap.put(status, 0);
                }
            }
        // Populate the map with data from the cases based on user profile
        for (Case c : cases) {
            String statusName = c.Status; // Ensure this is the correct field name
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
        List<ChartData> chartData = new List<ChartData>();
        for (String status : entityCaseCountMap.keySet()) {
            chartData.add(new ChartData(status, entityCaseCountMap.get(status)));
        }
        
        return chartData;
    }
    
    public class ChartData {
        public String statusName { get; set; }
        public Integer caseCount { get; set; }
        
        public ChartData(String statusName, Integer caseCount) {
            this.statusName = statusName;
            this.caseCount = caseCount;
        }
    }
}