public class DocusignReportController {
    public String chartDataJson { get; set; }
     public String selectedTimeRange { get; set; } // Store selected time range
     public String chartDataJsonStatus { get; set; }
     public String selectedTimeRange1 { get; set; } // Store selected time range
     public List<List<String>> docusignRecordsMatrix { get; set; } // To hold the matrix data

    public DocusignReportController() {
        	selectedTimeRange = 'Last 30 Days'; // Default selection
            refreshChart(); // Load initial chart data based on selection
            selectedTimeRange1 = 'Last 30 Days'; // Default selection            
            refreshChart1(); // Load initial chart data based on selection
        // Get the entity name and status list from the URL parameters
        String entityName = ApexPages.currentPage().getParameters().get('entityName');
        String selectedTimeRange = ApexPages.currentPage().getParameters().get('selectedTimeRange');
        //system.debug(selectedTimeRange);
        String statusList = ApexPages.currentPage().getParameters().get('statusList');
        system.debug('1st :'+statusList);
        // Initialize the matrices
        docusignRecordsMatrix = new List<List<String>>();
        
        // Fetch detailed case records based on the entity name
        if (entityName != null) {
            fetchDetailedData(entityName,selectedTimeRange);
        }
        
        // Fetch detailed case records based on the entity name and status list
        if (statusList != null) {
            fetchDetailedDataByStatus(statusList,selectedTimeRange);
        }
    }
    public void refreshChart() {
        List<ChartData> chartData = getChartData(selectedTimeRange); // Pass default selection to get initial data
        chartDataJson = JSON.serialize(chartData); // Serialize the chart data to JSON
    }

    @RemoteAction
    public static List<ChartData> getChartData(String selectedTimeRange) {
        // Fetch the current user's company name
        User currentUser = [SELECT RepAdvisorId__c FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
        String companyName = [SELECT Name FROM Account WHERE Id = :currentUser.RepAdvisorId__c AND IsPersonAccount = false LIMIT 1].Name;
        
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
    public void refreshChart1() {
        List<ChartDataByStatus> chartDataByStatus = getChartDataByStatus(selectedTimeRange1); // Pass default selection to get initial data
        chartDataJsonStatus = JSON.serialize(chartDataByStatus); // Serialize the chart data to JSON
    }

   @RemoteAction
        public static List<ChartDataByStatus> getChartDataByStatus(String selectedTimeRange1) {
            // Fetch the current user's company name
            User currentUser = [SELECT RepAdvisorId__c FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
        String companyName = [SELECT Name FROM Account WHERE Id = :currentUser.RepAdvisorId__c AND IsPersonAccount = false LIMIT 1].Name;
            DateTime startDate;
        
            // Determine start date based on selected time range
            if (selectedTimeRange1 == 'All') {
                startDate = DateTime.newInstance(1970, 1, 1, 0, 0, 0); 
            } else if (selectedTimeRange1 == 'Last 30 Days') {
                startDate = DateTime.now().addDays(-30);
            } else if (selectedTimeRange1 == 'Last 60 Days') {
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
        
            // Create a list of ChartDataByStatus objects and sort by predefined order
            List<ChartDataByStatus> chartDataByStatus = new List<ChartDataByStatus>();
            
            // Define the order of statuses
            List<String> statusOrder = new List<String>{'Sent', 'Delivered', 'Completed', 'Voided'};
            
            for (String status : statusOrder) {
                if (entityStatusCountMap.containsKey(status)) {
                    chartDataByStatus.add(new ChartDataByStatus(status, entityStatusCountMap.get(status)));
                }
            }
        
            System.debug('Chart Data: ' + chartDataByStatus);
            
            return chartDataByStatus;
        }
    
    public class ChartDataByStatus {
        public String statusName { get; set; }
        public Integer recCount { get; set; }
        
        public ChartDataByStatus(String statusName, Integer recCount) {
            this.statusName = statusName;
            this.recCount = recCount;
        }
    }
    private void fetchDetailedData(String entityName, String selectedTimeRange) {
        // Fetch the current user's company name
        User currentUser = [SELECT RepAdvisorId__c FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
        String companyName = [SELECT Name FROM Account WHERE Id = :currentUser.RepAdvisorId__c AND IsPersonAccount = false LIMIT 1].Name;
         //system.debug(selectedTimeRange);
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
          //system.debug('startDate:'+startDate);
       // Fetch detailed case records based on the entity name and status list
        List<dfsle__Envelope__c> detailedDES = [SELECT Id, CreatedDate, Name, Account__c, Financial_Account__c, Financial_Account__r.Name,
                                                      Envelope_Status__c, Financial_Account__r.FinServ__Household__r.RepAdvisor__r.RepAdvisorEntity__r.Name
                                              FROM dfsle__Envelope__c WHERE (Account__c = :companyName or 
                                       Financial_Account__r.RepAdvisor__r.RepAdvisorEntity__r.Name = :companyName or
                                          Financial_Account__r.FinServ__Household__r.RepAdvisor__r.RepAdvisorEntity__r.Name = :companyName or
                                          Financial_Account__r.FinServ__Household__r.RepAdvisorEntity__pr.Name = :companyName  )  AND CreatedDate >= :startDate];
        
        // Populate the matrix with detailed case records
        for (dfsle__Envelope__c c : detailedDES) {
            List<String> row = new List<String>{
                c.Name,
                    (c.CreatedDate != null) ? c.CreatedDate.format('MM/dd/yyyy h:mm a') : 'N/A', // Convert Datetime to String
                     (c.Envelope_Status__c != null && c.Envelope_Status__c != '') ? c.Envelope_Status__c : 'N/A'     ,          
                            (c.Financial_Account__c != null) ? c.Financial_Account__r.Name : 'N/A' // Check for null before accessing
                        ,c.Id};
                                        docusignRecordsMatrix.add(row);
        }
    }
    
    private void fetchDetailedDataByStatus(String statusList, String selectedTimeRange) {
        // Fetch the current user's company name
        User currentUser = [SELECT RepAdvisorId__c FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
        String companyName = [SELECT Name FROM Account WHERE Id = :currentUser.RepAdvisorId__c AND IsPersonAccount = false LIMIT 1].Name;
        //system.debug('Status of SelectedTimeRange:'+selectedTimeRange);
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
         //system.debug('startDate:'+startDate);
        // Split the statusList into a list
        List<String> statusFilter = statusList.split(',');
        system.debug('statusFilter:'+statusFilter);
        // Fetch detailed case records based on the entity name and status list
        List<dfsle__Envelope__c> detailedDES = [SELECT Id, CreatedDate, Name, Account__c, Financial_Account__c, Financial_Account__r.Name,
                                                      Envelope_Status__c, Financial_Account__r.FinServ__Household__r.RepAdvisor__r.RepAdvisorEntity__r.Name
                                              FROM dfsle__Envelope__c WHERE (Account__c = :companyName or 
                                       Financial_Account__r.RepAdvisor__r.RepAdvisorEntity__r.Name = :companyName or
                                          Financial_Account__r.FinServ__Household__r.RepAdvisor__r.RepAdvisorEntity__r.Name = :companyName ) 
                                    AND  DocuSign_Status_Record__r.dfsle__Status__c IN :statusFilter  
                                                AND CreatedDate >= :startDate]; // Use IN for multiple statuses
        
        // Populate the matrix with detailed case records
        for (dfsle__Envelope__c c : detailedDES) {
            List<String> row = new List<String>{
                c.Name,
                    (c.CreatedDate != null) ? c.CreatedDate.format('MM/dd/yyyy h:mm a') : 'N/A', // Convert Datetime to String
                  (c.Envelope_Status__c != null && c.Envelope_Status__c != '') ? c.Envelope_Status__c : 'N/A',                 
                            (c.Financial_Account__c != null) ? c.Financial_Account__r.Name : 'N/A' // Check for null before accessing
                        ,c.Id};
                                        docusignRecordsMatrix.add(row);
        }
    }
}