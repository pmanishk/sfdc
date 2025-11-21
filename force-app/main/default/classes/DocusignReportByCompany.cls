public class DocusignReportByCompany {
    public String chartDataJson { get; set; }
     public String selectedTimeRange { get; set; } // Store selected time range

    public DocusignReportByCompany() {
        selectedTimeRange = 'Last 30 Days'; // Default selection
        
        refreshChart(); // Load initial chart data based on selection
    }

    public void refreshChart() {
        List<ChartData> chartData = getChartData(selectedTimeRange); // Pass default selection to get initial data
        chartDataJson = JSON.serialize(chartData); // Serialize the chart data to JSON
    }

    @RemoteAction
    public static List<ChartData> getChartData(String selectedTimeRange) {
        // Fetch the current user's company name
        User currentUser = [SELECT CompanyName FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
        String companyName = currentUser.CompanyName;
        
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
        List<dfsle__Envelope__c> dES = [SELECT Id, CreatedDate, Name, Account__c, Financial_Account__c, Financial_Account__r.Name,
                                                      Envelope_Status__c, Financial_Account__r.FinServ__Household__r.RepAdvisor__r.RepAdvisorEntity__r.Name
                                              FROM dfsle__Envelope__c WHERE (Account__c = :companyName or 
                                       Financial_Account__r.RepAdvisor__r.RepAdvisorEntity__r.Name = :companyName or
                                          Financial_Account__r.FinServ__Household__r.RepAdvisor__r.RepAdvisorEntity__r.Name = :companyName or
                                          Financial_Account__r.FinServ__Household__r.RepAdvisorEntity__pr.Name = :companyName  )
                                        AND CreatedDate >= :startDate];
        
        // Create a map to hold the count of dES by status
        Map<String, Integer> entityRecCountMap = new Map<String, Integer>();
        
        // Populate the map with data from the dES
        for (dfsle__Envelope__c c : dES) {
            String entityName = c.Account__c ; // Ensure this is the correct field name
            if (entityRecCountMap.containsKey(entityName )) {
                entityRecCountMap.put(entityName , entityRecCountMap.get(entityName ) + 1); // Increment count
            } else {
                entityRecCountMap.put(entityName , 1); // Initialize count
            }
        }
        
        // Create a list of ChartData objects
        List<ChartData> chartData = new List<ChartData>();
        for (String entity: entityRecCountMap.keySet()) {
            chartData.add(new ChartData(entity, entityRecCountMap.get(entity)));
        }
        
        return chartData;
    }
    
    public class ChartData {
        public String entityName { get; set; }
        public Integer RecCount { get; set; }
        
        public ChartData(String entityName, Integer RecCount) {
            this.entityName = entityName;
            this.RecCount = RecCount;
        }
    }
}