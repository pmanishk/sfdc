public class CaseMatrixPageController {
    public List<List<String>> caseRecordsMatrix { get; set; } // To hold the matrix data
     // Fetch the current user's company name and profile
        User currentUser = [SELECT CompanyName, Profile.Name FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
        String companyName = currentUser.CompanyName;
        String userProfile = currentUser.Profile.Name;
    
    public CaseMatrixPageController() {       
        // Get the entity name and status list from the URL parameters
        String entityName = ApexPages.currentPage().getParameters().get('entityName');
        String selectedTimeRange = ApexPages.currentPage().getParameters().get('selectedTimeRange');
        //system.debug(selectedTimeRange);
        String statusList = ApexPages.currentPage().getParameters().get('statusList');
        
        // Initialize the matrices
        caseRecordsMatrix = new List<List<String>>();
        
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
        //system.debug(selectedTimeRange);
        //System.debug('selection time: ' + selectedTimeRange);
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
        // Define the allowed statuses
        Set<String> allowedStatuses = new Set<String>{'Closed', 'New', 'Waiting on Customer','Waiting on Review'};
            List<Case> detailedCases;
            if (userProfile == 'Agent 2' || userProfile == 'Primary Agent') {
                // Fetch detailed case records based on the entity name
               detailedCases = [SELECT Id, CaseNumber, Subject, Status, ClosedDate, CreatedDate, Account.RepAdvisorEntity__pr.Name, Account.Name
                                            FROM Case 
                                            WHERE  (Account.RepAdvisorEntity__pr.Name = :companyName 
                                    OR Account.RepAdvisor__pr.Account.RepAdvisorEntity__pr.Name = :companyName
                                    OR Account.RepAdvisor__r.Account.RepAdvisorEntity__pr.Name = :companyName
                                    OR Contact.Account.RepAdvisorEntity__pr.Name = :companyName
                                    OR Contact.Account.RepAdvisor__pr.Account.RepAdvisorEntity__pr.Name = :companyName) AND Status IN :allowedStatuses AND CreatedDate >= :startDate];
            }
        else
        {
            // Fetch detailed case records based on the entity name
           detailedCases = [SELECT Id, CaseNumber, Subject, Status, ClosedDate, CreatedDate, Account.RepAdvisorEntity__pr.Name, Account.Name
                                        FROM Case 
                                        WHERE  (Account.RepAdvisorEntity__pr.Name = :companyName 
                                    OR Account.RepAdvisor__pr.Account.RepAdvisorEntity__pr.Name = :companyName
                                    OR Account.RepAdvisor__r.Account.RepAdvisorEntity__pr.Name = :companyName
                                    OR Contact.Account.RepAdvisorEntity__pr.Name = :companyName
                                    OR Contact.Account.RepAdvisor__pr.Account.RepAdvisorEntity__pr.Name = :companyName) AND CreatedDate >= :startDate];
        }
        
        
        // Populate the matrix with detailed case records
        for (Case c : detailedCases) {
            List<String> row = new List<String>{
                c.CaseNumber,
                    (c.Subject != null) ? c.Subject: 'N/A', 
                    (c.CreatedDate != null) ? c.CreatedDate.format('MM/dd/yyyy h:mm a ') : 'N/A',// Convert Datetime to String
                        (c.ClosedDate != null) ? c.ClosedDate .format('MM/dd/yyyy h:mm a') : 'N/A',   // Convert Datetime to String 
                            c.Status,
                            	c.Id };
                                        caseRecordsMatrix.add(row);
        }
    }
    
    private void fetchDetailedDataByStatus(String statusList, String selectedTimeRange) {
        
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
        // Split the statusList into a list
        List<String> statusFilter = statusList.split(',');
        
        // Define the allowed statuses
        Set<String> allowedStatuses = new Set<String>{'Closed', 'New', 'Waiting on Customer','Waiting on Review'};
            
            // Determine which statuses to filter based on user profile
            List<String> filteredStatusList;
        
        if (userProfile == 'Agent 2' || userProfile == 'Primary Agent') {
            // Filter the statusFilter to only include allowed statuses for specified profiles
            filteredStatusList = new List<String>();
            for (String status : statusFilter) {
                if (allowedStatuses.contains(status.trim())) {
                    filteredStatusList.add(status.trim());
                }
            }
        } else {
            // If not one of the specified profiles, allow all statuses
            filteredStatusList = new List<String>(statusFilter); // Create a new list with all statuses
        }
        
        // Fetch detailed case records based on the company name and filtered status list
        List<Case> detailedCases = [SELECT Id, CaseNumber, Subject, Status, ClosedDate, CreatedDate, Account.RepAdvisorEntity__pr.Name, Account.Name
                                    FROM Case 
                                    WHERE  (Account.RepAdvisorEntity__pr.Name = :companyName 
                                    OR Account.RepAdvisor__pr.Account.RepAdvisorEntity__pr.Name = :companyName
                                    OR Account.RepAdvisor__r.Account.RepAdvisorEntity__pr.Name = :companyName
                                    OR Contact.Account.RepAdvisorEntity__pr.Name = :companyName
                                    OR Contact.Account.RepAdvisor__pr.Account.RepAdvisorEntity__pr.Name = :companyName)
                                    AND Status IN :filteredStatusList
                                   AND CreatedDate >= :startDate]; // Use IN for multiple statuses
        
        // Populate the matrix with detailed case records
        for (Case c : detailedCases) {
            List<String> row = new List<String>{
                c.CaseNumber,
                    (c.Subject != null) ? c.Subject: 'N/A',
                    (c.CreatedDate != null) ? c.CreatedDate.format('MM/dd/yyyy h:mm a') : 'N/A', // Convert Datetime to String
                        (c.ClosedDate != null) ? c.ClosedDate.format('MM/dd/yyyy h:mm a') : 'N/A',   // Convert Datetime to String 
                            c.Status,
                            	c.Id  };
                                        caseRecordsMatrix.add(row);
        }
    }
}