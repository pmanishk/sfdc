@isTest
public class ResourceControllerTest {
    
    @isTest
    static void testResourceControllerForAdmin() {
        // Setup: Create a test System Administrator user
        Profile sysAdminProfile = [SELECT Id FROM Profile WHERE Name='System Administrator' LIMIT 1];
        User sysAdminUser = new User(
            Alias = 'sysadmin',
            Email = 'sysadmin@example.com',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = sysAdminProfile.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            UserName = 'sysadmin123@example.com',
            IsActive = true,
            lastname = 'Test'
        );
        insert sysAdminUser;

        // Simulate login as System Administrator
        System.runAs(sysAdminUser) {
            // Execute: Instantiate the controller
            ResourceController controller = new ResourceController();
            
            // Validate: Check if resources are populated
            System.assertNotEquals(0, controller.sisResourceList.size(), 'Resource list should not be empty for System Administrator');
        }
    }

    @isTest
    static void testResourceControllerForNonAdmin() {
        // Setup: Create a test non-Administrator user
        Profile userProfile = [SELECT Id FROM Profile WHERE Name='Standard User' LIMIT 1];
        User nonAdminUser = new User(
            Alias = 'standard',
            Email = 'standard@example.com',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = userProfile.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            UserName = 'standard123@example.com',
            Advisor_Type__c = 'IAR', // Setting advisor type
            IsActive = true,
            lastname = 'Test'
        );
        insert nonAdminUser;
        
        // Simulate login as non-Administrator
        System.runAs(nonAdminUser) {
            // Execute: Instantiate the controller
            ResourceController controller = new ResourceController();
            
            // Validate: Check if resources are populated
            System.assertNotEquals(0, controller.sisResourceList.size(), 'Resource list should not be empty for non-Administrator');
        }
    }

}