public class CaseSharingScheduler implements Schedulable {
    public void execute(SchedulableContext sc) {
        // Query for new cases that need sharing
       /* List<Case> newCases = [SELECT Id, AccountId,ContactId,
                               Account.RepAdvisorEntity__pr.Name, Account.RepAdvisor__pr.Account.RepAdvisorEntity__pr.Name,
                               Contact.Account.RepAdvisorEntity__pr.Name,Contact.Account.RepAdvisor__pr.Account.RepAdvisorEntity__pr.Name
                               FROM Case 
                               WHERE CreatedDate = TODAY]; // Adjust your query criteria as needed

        // Call the shareCasesWithUsers method from CaseSharingHelper
        if (!newCases.isEmpty()) {
            CaseSharingHelper.shareCasesWithUsers(newCases);
        }*/
    }
}