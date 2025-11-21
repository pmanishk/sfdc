public class AdvisorMatrixPageController {
    public List<List<String>> companyInvestmentRecordMatrix { get; set; }
    public String advisorName { get; set; }
    public String entityName { get; set; }
    public String userCompanyID { get; set; }
    public String retURL { get; set; } // Add this property
    
    public AdvisorMatrixPageController() {
         retURL = ApexPages.currentPage().getParameters().get('retURL'); // Capture return URL
        // Get the entity name and account ID from URL parameters
        userCompanyID = [SELECT RepAdvisorId__c FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1].RepAdvisorId__c;
        entityName = [SELECT Name FROM Account WHERE Id = :userCompanyID  and IsPersonAccount = false LIMIT 1].Name;
        String accountId = ApexPages.currentPage().getParameters().get('accountId');    // Advisor Id
        String custodian = ApexPages.currentPage().getParameters().get('custodian');    // Custodian
        String managed = ApexPages.currentPage().getParameters().get('managed');    // managed
        advisorName = [SELECT RepAdvisor__r.Name FROM FinServ__FinancialAccount__c WHERE RepAdvisor__r.AccountId = :accountId limit 1].RepAdvisor__r.Name;
        
        System.debug('entityName is ' + entityName);
        
        // Initialize the matrices
        companyInvestmentRecordMatrix = new List<List<String>>();
        
        // Fetch detailed case records based on the entity name
        if((accountId != null) && (custodian != null) && (managed != null))
        {
            fetchDetailedacmData(accountId,custodian,managed); 
        }
        else if((accountId != null) && (custodian != null))
        {
            fetchDetailedacData(accountId,custodian); 
        }
        else if((accountId != null) && (managed != null))
        {
            fetchDetailedamData(accountId,managed); 
        }
        else if((custodian != null) && (managed != null))
        {
            fetchDetailedcmData(custodian,managed); 
        }
        else if(custodian != null)
        {
            fetchDetailedCustodianData(custodian); 
        }
        else if(managed != null)
        {
            fetchDetailedManagedData(managed); 
        }
        else if (accountId != null) {  
            fetchDetailedAdvisorData(accountId);
        }
        else  if (entityName != null) {            
            fetchDetailedData(entityName);
        }
        
    }
    
    public void fetchDetailedData(String entityName) {
        Integer batchSize = 1000;
        Integer offset = 0;
        Boolean hasMoreRecords = true;
        Integer maxRecords = 1000; // Max records to store in memory
         companyInvestmentRecordMatrix.clear();
        while (hasMoreRecords) {
            List<FinServ__FinancialAccount__c> detailedAccounts = [SELECT Id, FinServ__Balance__c, RepAdvisor__r.Name, CreatedDate,
                                                                   FinServ__PrimaryOwner__c, FinServ__FinancialAccountNumber__c,
                                                                   AccountType__c, FinServ__PrimaryOwner__r.Name
                                                                   FROM FinServ__FinancialAccount__c 
                                                                   WHERE ( RepAdvisor__r.Account.RepAdvisorEntity__pr.Name = :entityName
                                                       ) 
                                                       AND ( RepAdvisor__r.Account.RepAdvisorEntity__pr.IsPersonAccount = false
                                                       )
                                                                   LIMIT :batchSize OFFSET :offset];
            
            if (detailedAccounts.size() < batchSize) {
                hasMoreRecords = false;  // End when fewer records are returned than the batch size
            }
            
            for (FinServ__FinancialAccount__c a : detailedAccounts) {
                if (companyInvestmentRecordMatrix.size() >= maxRecords) {
                    hasMoreRecords = false;
                    break;
                }
                
                List<String> row = new List<String>{
                    (a.FinServ__FinancialAccountNumber__c != null) ? String.valueOf(a.FinServ__FinancialAccountNumber__c) : 'N/A',
                        a.FinServ__PrimaryOwner__r.Name,               
                        (a.AccountType__c != null) ? String.valueOf(a.AccountType__c) : 'N/A',
                            (a.FinServ__Balance__c != null) ? '$' + String.valueOf(a.FinServ__Balance__c.setScale(0, RoundingMode.FLOOR)).replaceAll('(\\d)(?=(\\d{3})+$)', '$1,') : 'N/A', 
                                a.Id
                                };
                                    companyInvestmentRecordMatrix.add(row);
            }
            
            offset += batchSize;  // Update offset for next batch
        }
    }
    
    // Method to fetch detailed advisor data with pagination
    public void fetchDetailedAdvisorData(Id accountId) {
        Integer batchSize = 1000;  // Adjust as needed
        Integer offset = 0;
        Boolean hasMoreRecords = true;
        Integer maxRecords = 1000; // Max records to store in memory
         companyInvestmentRecordMatrix.clear();
        while (hasMoreRecords) {
            // Paginated query to fetch the financial account data
            List<FinServ__FinancialAccount__c> advisorDetailedData = [SELECT Id, FinServ__Balance__c, RepAdvisor__r.Name, CreatedDate,
                                                                      FinServ__PrimaryOwner__c, FinServ__FinancialAccountNumber__c,
                                                                      AccountType__c, FinServ__PrimaryOwner__r.Name
                                                                      FROM FinServ__FinancialAccount__c
                                                                      WHERE ( RepAdvisor__r.AccountId = :accountId
                                                       )
                                                                      LIMIT :batchSize OFFSET :offset];
            
            // Stop if no records are returned or we've reached max records
            if (advisorDetailedData.size() < batchSize) {
                hasMoreRecords = false;
            }
            
            for (FinServ__FinancialAccount__c a : advisorDetailedData) {
                if (companyInvestmentRecordMatrix.size() >= maxRecords) {
                    hasMoreRecords = false;
                    break;
                }
                
                List<String> row = new List<String> {
                    (a.FinServ__FinancialAccountNumber__c != null) ? String.valueOf(a.FinServ__FinancialAccountNumber__c) : 'N/A',
                        a.FinServ__PrimaryOwner__r.Name,               
                        (a.AccountType__c != null) ? String.valueOf(a.AccountType__c) : 'N/A',
                            (a.FinServ__Balance__c != null) ? '$' + String.valueOf(a.FinServ__Balance__c.setScale(0, RoundingMode.FLOOR)).replaceAll('(\\d)(?=(\\d{3})+$)', '$1,') : 'N/A', // Convert Decimal to String
                                a.Id
                                };
                                    companyInvestmentRecordMatrix.add(row);
            }
            
            // Update the offset for the next batch
            offset += batchSize;
        }
    }
    
    // Method to fetch detailed custodian data with pagination
    public void fetchDetailedCustodianData(String custodian) {  
        String userCompanyID = [SELECT RepAdvisorId__c FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1].RepAdvisorId__c;
        String entityName = [SELECT Name FROM Account WHERE Id = :userCompanyID  and IsPersonAccount = false LIMIT 1].Name;
        Integer batchSize = 1000;  // Adjust as needed
        Integer offset = 0;
        Boolean hasMoreRecords = true;
        Integer maxRecords = 1000; // Max records to store in memory
        
        // Get custodian details for pagination
        List<EAST_RepID__c> custodianDetailedData = [SELECT Id, Name, Total_AUM__c, CreatedDate, Primary_Rep_Contact__r.Name, 
                                                     Primary_Rep_User__r.Name
                                                     FROM EAST_RepID__c 
                                                     WHERE Custodian__c = :custodian
                                                     //AND Primary_Rep_User__r.CompanyName = :entityName
                                                    ];
         List<String> custodianIds = new List<String>();
            for (EAST_RepID__c rep : custodianDetailedData) {
                custodianIds.add(rep.Name);
            }
        while (hasMoreRecords) {
            // Paginated query to fetch financial account data linked to custodian
            List<FinServ__FinancialAccount__c> detailedAccounts = [SELECT Id, FinServ__Balance__c, RepAdvisor__r.Name, CreatedDate,
                                                                   FinServ__PrimaryOwner__c, FinServ__FinancialAccountNumber__c,
                                                                   AccountType__c, FinServ__PrimaryOwner__r.Name
                                                                   FROM FinServ__FinancialAccount__c 
                                                                   WHERE RepID__c IN :custodianIds 
                                                                   AND  ( RepAdvisor__r.Account.RepAdvisorEntity__pr.Name = :entityName
                                                        ) 
                                                       AND ( RepAdvisor__r.Account.RepAdvisorEntity__pr.IsPersonAccount = false
                                                        ) 
                                                                   LIMIT :batchSize OFFSET :offset];
            
            // Stop if no records are returned or we've reached max records
            if (detailedAccounts.size() < batchSize) {
                hasMoreRecords = false;
            }
            
            for (FinServ__FinancialAccount__c a : detailedAccounts) {
                if (companyInvestmentRecordMatrix.size() >= maxRecords) {
                    hasMoreRecords = false;
                    break;
                }
                
                List<String> row = new List<String> {
                    (a.FinServ__FinancialAccountNumber__c != null) ? String.valueOf(a.FinServ__FinancialAccountNumber__c) : 'N/A',
                        a.FinServ__PrimaryOwner__r.Name,               
                        (a.AccountType__c != null) ? String.valueOf(a.AccountType__c) : 'N/A',
                            (a.FinServ__Balance__c != null) ? '$' + String.valueOf(a.FinServ__Balance__c.setScale(0, RoundingMode.FLOOR)).replaceAll('(\\d)(?=(\\d{3})+$)', '$1,') : 'N/A', // Convert Decimal to String
                                a.Id
                                };
                                    companyInvestmentRecordMatrix.add(row);
            }
            
            // Update the offset for the next batch
            offset += batchSize;
        }
    }
    // Fetch Detailed Managed Data with Pagination
    public void fetchDetailedManagedData(String managedValue) {
       String userCompanyID = [SELECT RepAdvisorId__c FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1].RepAdvisorId__c;
        String entityName = [SELECT Name FROM Account WHERE Id = :userCompanyID  and IsPersonAccount = false LIMIT 1].Name;
        Boolean managedValue1 = (managedValue == 'Managed'); // Simplified boolean assignment
        
        Integer batchSize = 1000;  // Batch size for pagination
        Integer offset = 0;
        Boolean hasMoreRecords = true;
        Integer maxRecords = 1000; // Max records to store in memory
        
        List<EAST_RepID__c> custodianDetailedData = [SELECT Id, Name, Total_AUM__c, CreatedDate, Primary_Rep_Contact__r.Name, 
                                                     Primary_Rep_User__r.Name
                                                     FROM EAST_RepID__c 
                                                     WHERE Managed__c = :managedValue1
                                                     //AND Primary_Rep_User__r.CompanyName = :entityName
                                                    ];
         List<String> custodianIds = new List<String>();
            for (EAST_RepID__c rep : custodianDetailedData) {
                custodianIds.add(rep.Name);
            }
        while (hasMoreRecords) {
            List<FinServ__FinancialAccount__c> detailedAccounts = [SELECT Id, FinServ__Balance__c, RepAdvisor__r.Name, CreatedDate,
                                                                   FinServ__PrimaryOwner__c, FinServ__FinancialAccountNumber__c,
                                                                   AccountType__c, FinServ__PrimaryOwner__r.Name
                                                                   FROM FinServ__FinancialAccount__c 
                                                                   WHERE RepID__c IN :custodianIds
                                                                   AND  ( RepAdvisor__r.Account.RepAdvisorEntity__pr.Name = :entityName
                                                        ) 
                                                       AND ( RepAdvisor__r.Account.RepAdvisorEntity__pr.IsPersonAccount = false
                                                        )
                                                                   LIMIT :batchSize OFFSET :offset];
            
            if (detailedAccounts.size() < batchSize) {
                hasMoreRecords = false;
            }
            
            for (FinServ__FinancialAccount__c a : detailedAccounts) {
                if (companyInvestmentRecordMatrix.size() >= maxRecords) {
                    hasMoreRecords = false;
                    break;
                }
                
                List<String> row = new List<String> {
                    (a.FinServ__FinancialAccountNumber__c != null) ? String.valueOf(a.FinServ__FinancialAccountNumber__c) : 'N/A',
                        a.FinServ__PrimaryOwner__r.Name,               
                        (a.AccountType__c != null) ? String.valueOf(a.AccountType__c) : 'N/A',
                            (a.FinServ__Balance__c != null) ? '$' + String.valueOf(a.FinServ__Balance__c.setScale(0, RoundingMode.FLOOR)).replaceAll('(\\d)(?=(\\d{3})+$)', '$1,') : 'N/A', // Convert Decimal to String
                                a.Id
                                };
                                    companyInvestmentRecordMatrix.add(row);
            }
            
            // Update the offset for the next batch
            offset += batchSize;
        }
    }
    
    // Fetch Detailed Account Data with Pagination
    public void fetchDetailedacData(Id accountId, String custodian) {    
        Integer batchSize = 1000;  // Batch size for pagination
        Integer offset = 0;
        Boolean hasMoreRecords = true;
        Integer maxRecords = 1000; // Max records to store in memory
        String userCompanyID = [SELECT RepAdvisorId__c FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1].RepAdvisorId__c;
        String entityName = [SELECT Name FROM Account WHERE Id = :userCompanyID  and IsPersonAccount = false LIMIT 1].Name;
        while (hasMoreRecords) {
            // Paginated query to fetch managed data based on custodian and account
            List<EAST_RepID__c> managedData = [SELECT Id, Name, Total_AUM__c, CreatedDate
                                               FROM EAST_RepID__c 
                                               WHERE Custodian__c = :custodian
                                               //AND Primary_Rep_User__r.CompanyName = :entityName
                                               LIMIT :batchSize OFFSET :offset];
            
            if (managedData.size() < batchSize) {
                hasMoreRecords = false; // Stop if fewer than batch size are returned
            }
            
            List<FinServ__FinancialAccount__c> acData = new List<FinServ__FinancialAccount__c>();
            
            if (!managedData.isEmpty()) {
                List<String> custodianIds = new List<String>();
                    for (EAST_RepID__c rep : managedData) {
                        custodianIds.add(rep.Name);
                    }
                
                acData = [SELECT Id, FinServ__Balance__c, RepAdvisor__r.Name, CreatedDate, RepAdvisor__r.AccountId, RepIDLink__c,
                          FinServ__PrimaryOwner__c, FinServ__FinancialAccountNumber__c,
                          AccountType__c, FinServ__PrimaryOwner__r.Name
                          FROM FinServ__FinancialAccount__c
                          WHERE ( RepAdvisor__r.AccountId = :accountId
                                                       )
                          AND RepID__c IN :custodianIds];
            }
            
            for (FinServ__FinancialAccount__c a : acData) {
                if (companyInvestmentRecordMatrix.size() >= maxRecords) {
                    hasMoreRecords = false; // Stop if the matrix exceeds max record limit
                    break;
                }
                
                List<String> row = new List<String> {
                    (a.FinServ__FinancialAccountNumber__c != null) ? String.valueOf(a.FinServ__FinancialAccountNumber__c) : 'N/A',
                        a.FinServ__PrimaryOwner__r.Name,               
                        (a.AccountType__c != null) ? String.valueOf(a.AccountType__c) : 'N/A',
                            (a.FinServ__Balance__c != null) ? '$' + String.valueOf(a.FinServ__Balance__c.setScale(0, RoundingMode.FLOOR)).replaceAll('(\\d)(?=(\\d{3})+$)', '$1,') : 'N/A', // Convert Decimal to String
                                a.Id
                                };
                                    companyInvestmentRecordMatrix.add(row);
            }
            
            offset += batchSize;  // Update offset for next batch
        }
    }
    
    // Fetch Detailed Asset Management Data with Pagination
    public void fetchDetailedamData(Id accountId, String managedValue) {
       String userCompanyID = [SELECT RepAdvisorId__c FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1].RepAdvisorId__c;
        String entityName = [SELECT Name FROM Account WHERE Id = :userCompanyID  and IsPersonAccount = false LIMIT 1].Name;
        Boolean managedValue1 = (managedValue == 'Managed'); // Simplified boolean assignment
        
        Integer batchSize = 1000;  // Batch size for pagination
        Integer offset = 0;
        Boolean hasMoreRecords = true;
        Integer maxRecords = 1000; // Max records to store in memory
        
        while (hasMoreRecords) {
            // Paginated query to fetch managed data
            List<EAST_RepID__c> managedData = [SELECT Id, Name, Total_AUM__c, CreatedDate
                                               FROM EAST_RepID__c 
                                               WHERE Managed__c = :managedValue1
                                               //AND Primary_Rep_User__r.CompanyName = :entityName
                                               LIMIT :batchSize OFFSET :offset];
            
            if (managedData.size() < batchSize) {
                hasMoreRecords = false; // Stop if fewer than batch size are returned
            }
            
            List<FinServ__FinancialAccount__c> amData = new List<FinServ__FinancialAccount__c>();
            
            if (!managedData.isEmpty()) {
                List<String> custodianIds = new List<String>();
                    for (EAST_RepID__c rep : managedData) {
                        custodianIds.add(rep.Name);
                    }
                
                amData = [SELECT Id, FinServ__Balance__c, RepAdvisor__r.Name, CreatedDate, RepAdvisor__r.AccountId , RepIDLink__c,
                          FinServ__PrimaryOwner__c, FinServ__FinancialAccountNumber__c,
                          AccountType__c, FinServ__PrimaryOwner__r.Name
                          FROM FinServ__FinancialAccount__c
                          WHERE ( RepAdvisor__r.AccountId = :accountId
                                                        )
                          AND RepID__c IN :custodianIds];
            }
            
            for (FinServ__FinancialAccount__c a : amData) {
                if (companyInvestmentRecordMatrix.size() >= maxRecords) {
                    hasMoreRecords = false;  // Stop if the matrix exceeds max record limit
                    break;
                }
                
                List<String> row = new List<String> {
                    (a.FinServ__FinancialAccountNumber__c != null) ? String.valueOf(a.FinServ__FinancialAccountNumber__c) : 'N/A',
                        a.FinServ__PrimaryOwner__r.Name,               
                        (a.AccountType__c != null) ? String.valueOf(a.AccountType__c) : 'N/A',
                            (a.FinServ__Balance__c != null) ? '$' + String.valueOf(a.FinServ__Balance__c.setScale(0, RoundingMode.FLOOR)).replaceAll('(\\d)(?=(\\d{3})+$)', '$1,') : 'N/A', // Convert Decimal to String
                                a.Id
                                };
                                    companyInvestmentRecordMatrix.add(row);
            }
            
            offset += batchSize;  // Update offset for next batch
        }
    }
    
    // Fetch Detailed Custodian Managed Data with Pagination
    public void fetchDetailedcmData(String custodian, String managedValue) {    
        Boolean managedValue1 = (managedValue == 'Managed'); // Simplified boolean assignment
        String userCompanyID = [SELECT RepAdvisorId__c FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1].RepAdvisorId__c;
        String entityName = [SELECT Name FROM Account WHERE Id = :userCompanyID  and IsPersonAccount = false LIMIT 1].Name;
        Integer batchSize = 1000;  // Batch size for pagination
        Integer offset = 0;
        Boolean hasMoreRecords = true;
        Integer maxRecords = 1000; // Max records to store in memory
        
        while (hasMoreRecords) {
            // Paginated query to fetch managed data based on custodian and account
            List<EAST_RepID__c> managedData = [SELECT Id, Name, Total_AUM__c, CreatedDate
                                               FROM EAST_RepID__c 
                                               WHERE Managed__c = :managedValue1
                                               AND Custodian__c = :custodian
                                               //AND Primary_Rep_User__r.CompanyName = :entityName
                                               LIMIT :batchSize OFFSET :offset];
            
            if (managedData.size() < batchSize) {
                hasMoreRecords = false; // Stop if fewer than batch size are returned
            }
            
            List<FinServ__FinancialAccount__c> cmData = new List<FinServ__FinancialAccount__c>();
            
            if (!managedData.isEmpty()) {
                 List<String> custodianIds = new List<String>();
                    for (EAST_RepID__c rep : managedData) {
                        custodianIds.add(rep.Name);
                    }
                
                cmData = [SELECT Id, FinServ__Balance__c, RepAdvisor__r.Name, CreatedDate, RepAdvisor__r.AccountId, RepIDLink__c,
                          FinServ__PrimaryOwner__c, FinServ__FinancialAccountNumber__c,
                          AccountType__c, FinServ__PrimaryOwner__r.Name
                          FROM FinServ__FinancialAccount__c
                          WHERE RepID__c IN :custodianIds
                         AND  ( RepAdvisor__r.Account.RepAdvisorEntity__pr.Name = :entityName
                                                       ) 
                                                       AND ( RepAdvisor__r.Account.RepAdvisorEntity__pr.IsPersonAccount = false
                                                       ) ];
            }
            
            for (FinServ__FinancialAccount__c a : cmData) {
                if (companyInvestmentRecordMatrix.size() >= maxRecords) {
                    hasMoreRecords = false; // Stop if the matrix exceeds max record limit
                    break;
                }
                
                 List<String> row = new List<String> {
                    (a.FinServ__FinancialAccountNumber__c != null) ? String.valueOf(a.FinServ__FinancialAccountNumber__c) : 'N/A',
                        a.FinServ__PrimaryOwner__r.Name,               
                        (a.AccountType__c != null) ? String.valueOf(a.AccountType__c) : 'N/A',
                            (a.FinServ__Balance__c != null) ? '$' + String.valueOf(a.FinServ__Balance__c.setScale(0, RoundingMode.FLOOR)).replaceAll('(\\d)(?=(\\d{3})+$)', '$1,') : 'N/A', // Convert Decimal to String
                                a.Id
                                };
                                    companyInvestmentRecordMatrix.add(row);
            }
            
            offset += batchSize;  // Update offset for next batch
        }
    }
    
    // Fetch Detailed Account Managed Data with Pagination
    public void fetchDetailedacmData(Id accountId, String custodian, String managedValue) {    
        Boolean managedValue1 = (managedValue == 'Managed');
        Integer batchSize = 1000;  // Batch size for pagination
        Integer offset = 0;
        Boolean hasMoreRecords = true;
        Integer maxRecords = 1000; // Max records to store in memory
        
        while (hasMoreRecords) {
            // Paginated query to fetch managed data based on custodian and account
            List<EAST_RepID__c> managedData = [SELECT Id, Name, Total_AUM__c, CreatedDate
                                               FROM EAST_RepID__c 
                                               WHERE Managed__c = :managedValue1
                                               AND Custodian__c = :custodian
                                               LIMIT :batchSize OFFSET :offset];
            
            if (managedData.size() < batchSize) {
                hasMoreRecords = false; // Stop if fewer than batch size are returned
            }
            
            List<FinServ__FinancialAccount__c> acmData = new List<FinServ__FinancialAccount__c>();
            
            if (!managedData.isEmpty()) {
                 List<String> custodianIds = new List<String>();
                    for (EAST_RepID__c rep : managedData) {
                        custodianIds.add(rep.Name);
                    }
                
                acmData = [SELECT Id, FinServ__Balance__c, RepAdvisor__r.Name, CreatedDate, RepAdvisor__r.AccountId, RepIDLink__c,
                           FinServ__PrimaryOwner__c, FinServ__FinancialAccountNumber__c,
                           AccountType__c, FinServ__PrimaryOwner__r.Name
                           FROM FinServ__FinancialAccount__c
                           WHERE ( RepAdvisor__r.AccountId = :accountId
                                                       )
                           AND RepID__c IN :custodianIds];
            }
            
            for (FinServ__FinancialAccount__c a : acmData) {
                if (companyInvestmentRecordMatrix.size() >= maxRecords) {
                    hasMoreRecords = false; // Stop if the matrix exceeds max record limit
                    break;
                }
                
                 List<String> row = new List<String> {
                    (a.FinServ__FinancialAccountNumber__c != null) ? String.valueOf(a.FinServ__FinancialAccountNumber__c) : 'N/A',
                        a.FinServ__PrimaryOwner__r.Name,               
                        (a.AccountType__c != null) ? String.valueOf(a.AccountType__c) : 'N/A',
                            (a.FinServ__Balance__c != null) ? '$' + String.valueOf(a.FinServ__Balance__c.setScale(0, RoundingMode.FLOOR)).replaceAll('(\\d)(?=(\\d{3})+$)', '$1,') : 'N/A', // Convert Decimal to String
                                a.Id
                                };
                                    companyInvestmentRecordMatrix.add(row);
            }
            
            offset += batchSize;  // Update offset for next batch
        }
    }
}