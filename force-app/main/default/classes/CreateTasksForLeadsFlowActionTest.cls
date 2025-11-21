@isTest
public class CreateTasksForLeadsFlowActionTest {
    
    @isTest
    static void testCreateTasksForLeads() {
        // Test data setup
        Campaign testCampaign = new Campaign(Name = 'Test Campaign');
        insert testCampaign;

        List<Lead> testLeads = new List<Lead>();
        for (Integer i = 0; i < 5; i++) {
            testLeads.add(new Lead(FirstName = 'Test', LastName = 'Lead ' + i, OwnerId = UserInfo.getUserId()));
        }
        insert testLeads;

        List<CampaignMember> testCampaignMembers = new List<CampaignMember>();
        for (Lead testLead : testLeads) {
            testCampaignMembers.add(new CampaignMember(CampaignId = testCampaign.Id, LeadId = testLead.Id));
        }
        insert testCampaignMembers;

        // Call the method to test
        CreateTasksForLeadsFlowAction.InputWrapper inputWrapper = new CreateTasksForLeadsFlowAction.InputWrapper();
        inputWrapper.campaignId = testCampaign.Id;
        inputWrapper.type = 'Call';
        inputWrapper.dueDate = System.today();
        inputWrapper.subject = 'Test Subject';
        inputWrapper.count = 10;

        List<CreateTasksForLeadsFlowAction.OutputWrapper> outputWrappers = CreateTasksForLeadsFlowAction.createTasksForLeads(new List<CreateTasksForLeadsFlowAction.InputWrapper>{inputWrapper});

        // Assert the results
        System.assertEquals(1, outputWrappers.size());
        CreateTasksForLeadsFlowAction.OutputWrapper outputWrapper = outputWrappers[0];

        System.assert(outputWrapper.isSuccess);
        System.assertNotEquals(null, outputWrapper.leadId);
    }
}