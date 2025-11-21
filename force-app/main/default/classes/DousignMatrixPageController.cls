public class DousignMatrixPageController {
    public List<List<String>> docusignRecordsMatrix { get; set; } // To hold the matrix data
    
    public DousignMatrixPageController() {
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
    
    private void fetchDetailedData(String entityName, String selectedTimeRange) {
        // Fetch the current user's company name
        User currentUser = [SELECT CompanyName FROM User WHERE Id = :UserInfo.getUserId()  LIMIT 1];
        String companyName = currentUser.CompanyName;
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
        User currentUser = [SELECT CompanyName FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
        String companyName = currentUser.CompanyName;
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