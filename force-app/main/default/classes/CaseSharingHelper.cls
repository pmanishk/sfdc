public without sharing class CaseSharingHelper { 
    public static void shareCasesWithUsers(List<Case> newCases) {
		//system.debug('newCases initial----'+newCases);
        List<CaseShare> caseSharesToInsert = new List<CaseShare>();
        
        // Define the profile names you want to check against
        Set<String> allowedProfileNames = new Set<String>{'Primary Agent'}; // Add your profile names here
		// Collect Account IDs from new Cases
    Set<Id> accountIds = new Set<Id>();
    Set<Id> contactIds = new Set<Id>();

    for (Case caseRecord : newCases) {
        if (caseRecord.AccountId != null) {
            accountIds.add(caseRecord.AccountId);
        }
        if (caseRecord.ContactId != null) {
            contactIds.add(caseRecord.ContactId);
        }
    }

    // Query Accounts and Contacts to get RepAdvisorEntity names
    Map<Id, Account> accountsMap = new Map<Id, Account>(
        [SELECT Id, RepAdvisorEntity__pc, RepAdvisor__pr.Account.RepAdvisorEntity__pc , RepAdvisor__r.Account.RepAdvisorEntity__pc
         FROM Account 
         WHERE Id IN :accountIds]
    );

    Map<Id, Contact> contactsMap = new Map<Id, Contact>(
        [SELECT Id, Account.RepAdvisorEntity__pc, Account.RepAdvisor__pr.Account.RepAdvisorEntity__pc
         FROM Contact 
         WHERE Id IN :contactIds]
    );
        
        // Collect Account IDs from new Cases
        Set<String> repAdvisorEntityName = new Set<String>();
		//system.debug('repAdvisorEntityName inital----'+repAdvisorEntityName);
       // Collect RepAdvisorEntity names from Accounts
    for (Case caseRecord : newCases) {
        if (caseRecord.AccountId != null && accountsMap.containsKey(caseRecord.AccountId)) {
            Account acc = accountsMap.get(caseRecord.AccountId);
            if (acc.RepAdvisorEntity__pc != null) {
                repAdvisorEntityName.add(acc.RepAdvisorEntity__pc);
            }
          else if (acc.RepAdvisor__pr.Account.RepAdvisorEntity__pc != null) {
                repAdvisorEntityName.add(acc.RepAdvisor__pr.Account.RepAdvisorEntity__pc);
            }
            else{
                repAdvisorEntityName.add(acc.RepAdvisor__r.Account.RepAdvisorEntity__pc);
            }
        }

        // Collect RepAdvisorEntity names from Contacts
        if (caseRecord.ContactId != null && contactsMap.containsKey(caseRecord.ContactId)) {
            Contact con = contactsMap.get(caseRecord.ContactId);
            if (con.Account.RepAdvisorEntity__pc != null) {
                repAdvisorEntityName.add(con.Account.RepAdvisorEntity__pc);
            }
          else {
                repAdvisorEntityName.add(con.Account.RepAdvisor__pr.Account.RepAdvisorEntity__pc);
            }
        }
    }

    //System.debug('repAdvisorEntityNames: ' + repAdvisorEntityName);

        // Proceed only if the current user's profile matches "Primary Agent"
        if (!repAdvisorEntityName.isEmpty()) {
            // Get all users with the same profile and company name
            List<User> usersWithSameProfile = [
                SELECT Id 
                FROM User 
                 WHERE RepAdvisorId__c IN :repAdvisorEntityName AND Profile.Name IN :allowedProfileNames AND isActive = true 
            ];
	//system.debug('usersWithSameProfile----'+usersWithSameProfile);
            // Create a map of case IDs to share with users
            for (Case caseRecord : newCases) {
                for (User user : usersWithSameProfile) {
                    // Create a new CaseShare record
                    CaseShare caseShare = new CaseShare();
                    caseShare.CaseId = caseRecord.Id; // The ID of the case being shared
                    caseShare.UserOrGroupId = user.Id; // The user to share with
                    caseShare.CaseAccessLevel = 'Edit'; // Set access level (Read or Edit)
                    caseShare.RowCause = Schema.CaseShare.RowCause.Manual; // Use your defined sharing reason
                    
                    caseSharesToInsert.add(caseShare);
                }
            }

            // Insert all sharing records in a single DML operation
            if (!caseSharesToInsert.isEmpty()) {
                try {
                    insert caseSharesToInsert;
                } catch (DmlException e) {
                    // Handle DML exception appropriately, e.g., log or rethrow
                    System.debug('Error inserting CaseShares: ' + e.getMessage());
                }
            }
        }
    } 
}