@isTest
public class TestLeadConvertAction {
   
    @isTest static void testConvertLead(){
        Lead tempLead = new Lead();
        templead.lastName = 'test';
        
    

        insert tempLead;
        
        List<Lead> newLeads = [SELECT id,Company FROM Lead WHERE id = :tempLead.id];

        List<LeadConvertAction.ConvertLeadActionResult> result = LeadConvertAction.convertLead(newLeads);

        for(LeadConvertAction.ConvertLeadActionResult currResult : result){
            List<Account> tempAccount = [SELECT id, isPersonAccount FROM Account WHERE id = :currResult.convertedAccount];
            for(Account temp : tempAccount){
                system.debug(temp.isPersonAccount);
            }
            
        }
    }
}