trigger CaseSharingTrigger on Case (after insert, after update) {
    if (Trigger.isAfter) {
        
        List<Case> casesToProcess = new List<Case>();

        if (Trigger.isInsert) {
            // On insert, process cases where Household_Account__c is not null
            for (Case c : Trigger.new) {
                if (c.Household_Account__c != null) {
                    casesToProcess.add(c);
                }
            }
        } else if (Trigger.isUpdate) {
            // On update, process cases where Household_Account__c has changed
           
            // Collect Case Ids and old advisor entity Ids
            Map<Id, Set<Id>> caseRepAdvMap = new Map<Id, Set<Id>>();
            Set<Id> oldRepIds = new Set<Id>();
            for(Case newCase : Trigger.new) {
                Case oldCase = Trigger.oldMap.get(newCase.Id);
                if(newCase.Household_Account__c != null) {
                    casesToProcess.add(newCase);
                }
                // Compare and detect which field changed
                Set<Id> oldAdvisorEntityIdSet = new Set<Id>();
                if(oldCase.Household_Account__c != null && newCase.Household_Account__c != oldCase.Household_Account__c) {
                    oldAdvisorEntityIdSet.add(oldCase.Household_Account__r?.RepAdvisor__r?.RepAdvisorEntity__c);
                } 
                if(oldCase.AccountId != null && newCase.AccountId != oldCase.AccountId) {
                    oldAdvisorEntityIdSet.add(oldCase.Account?.RepAdvisor__r?.RepAdvisorEntity__c);
                } 
                if (oldCase.ContactId != null && newCase.ContactId != oldCase.ContactId) {
                    oldAdvisorEntityIdSet.add(oldCase.Contact?.Account?.RepAdvisor__r?.RepAdvisorEntity__c);
                }

                if (!oldAdvisorEntityIdSet.isEmpty()) {
                    oldRepIds.addAll(oldAdvisorEntityIdSet);
                    caseRepAdvMap.put(newCase.Id, oldAdvisorEntityIdSet);
                }
            }

            if(!caseRepAdvMap.isEmpty()){
                // Find users whose RepAdvisorId__c matched those old AdvisorEntity Ids
                Map<Id, Set<Id>> repIdUsersMap = new Map<Id, Set<Id>>();

                for (User u : [SELECT Id, RepAdvisorId__c FROM User WHERE RepAdvisorId__c IN :oldRepIds]) {
                    if (repIdUsersMap.get(u.RepAdvisorId__c) == null) {
                        repIdUsersMap.put(u.RepAdvisorId__c, new Set<Id>());
                    }
                    repIdUsersMap.get(u.RepAdvisorId__c).add(u.Id);
                }

                if(!repIdUsersMap.isEmpty()) {
                    // Find CaseShare records for those users
                    Map<Id,CaseShare> sharesToDeleteMap = new Map<Id,CaseShare>();
                    for(CaseShare cs : [SELECT Id, CaseId, UserOrGroupId FROM CaseShare WHERE CaseId IN :caseRepAdvMap.keySet() and rowCause = 'Manual']) {
                        if(caseRepAdvMap.containsKey(cs.CaseId)) {
                           for(Id repId : caseRepAdvMap.get(cs.CaseId)) {
                               if(repIdUsersMap.containsKey(repId)) {
                                   for(Id uId : repIdUsersMap.get(repId)) {
                                       // Mark for deletion
                                       sharesToDeleteMap.put(cs.Id, cs);
                                   }

                               }

                           }
                        }
                    }

                    if(!sharesToDeleteMap.values().isEmpty()) {
                        delete sharesToDeleteMap.values();
                    }
                }                
            }            
        }

        if (!casesToProcess.isEmpty()) {
            XFP_CaseFilesExportHandler.XFP_ExportCaseFiles(casesToProcess);
            CaseFilesLinkToHousehold.linkCaseFilesToHouseholdViaCase(casesToProcess);
            CaseFilesLinkToHousehold.linkEmailAttachmentsFilesToCase(casesToProcess);
        }
    }
}