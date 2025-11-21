public class DocusignReportByStatus {
    public String chartDataJson { get; set; }
     public String selectedTimeRange { get; set; } // Store selected time range

    public DocusignReportByStatus() {
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
        
            // Determine start date based on selected time range
            if (selectedTimeRange == 'All') {
                startDate = DateTime.newInstance(1970, 1, 1, 0, 0, 0); 
            } else if (selectedTimeRange == 'Last 30 Days') {
                startDate = DateTime.now().addDays(-30);
            } else if (selectedTimeRange == 'Last 60 Days') {
                startDate = DateTime.now().addDays(-60);
            } else { // Default to Last 90 Days
                startDate = DateTime.now().addDays(-90);
            }
          
            List<dfsle__Envelope__c> dES = [SELECT Id, CreatedDate, Name, Account__c, Financial_Account__c, Financial_Account__r.Name,
                                                      Envelope_Status__c, Financial_Account__r.FinServ__Household__r.RepAdvisor__r.RepAdvisorEntity__r.Name
                                              FROM dfsle__Envelope__c WHERE (Account__c = :companyName or 
                                       Financial_Account__r.RepAdvisor__r.RepAdvisorEntity__r.Name = :companyName or
                                          Financial_Account__r.FinServ__Household__r.RepAdvisor__r.RepAdvisorEntity__r.Name = :companyName or
                                          Financial_Account__r.FinServ__Household__r.RepAdvisorEntity__pr.Name = :companyName  )
                                             AND CreatedDate >= :startDate 
                                             AND Envelope_Status__c != null];
        
            System.debug('Envelope Records: ' + dES);
        
            Map<String, Integer> entityStatusCountMap = new Map<String, Integer>();
            
            for (dfsle__Envelope__c d : dES) {
                String statusName = d.Envelope_Status__c; // Ensure this is the correct field name
                if (entityStatusCountMap.containsKey(statusName)) {
                    entityStatusCountMap.put(statusName, entityStatusCountMap.get(statusName) + 1); // Increment count
                } else {
                    entityStatusCountMap.put(statusName, 1); // Initialize count
                }
            }
        
            Set<String> uniqueStatuses = new Set<String>(entityStatusCountMap.keySet());
            System.debug('Unique Statuses: ' + uniqueStatuses);
        
            // Create a list of ChartData objects and sort by predefined order
            List<ChartData> chartData = new List<ChartData>();
            
            // Define the order of statuses
            List<String> statusOrder = new List<String>{'Sent', 'Delivered', 'Completed', 'Voided'};
            
            for (String status : statusOrder) {
                if (entityStatusCountMap.containsKey(status)) {
                    chartData.add(new ChartData(status, entityStatusCountMap.get(status)));
                }
            }
        
            System.debug('Chart Data: ' + chartData);
            
            return chartData;
        }
    
    public class ChartData {
        public String statusName { get; set; }
        public Integer recCount { get; set; }
        
        public ChartData(String statusName, Integer recCount) {
            this.statusName = statusName;
            this.recCount = recCount;
        }
    }
}