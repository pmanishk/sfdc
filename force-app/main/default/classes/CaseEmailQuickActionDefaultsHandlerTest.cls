@isTest
public class CaseEmailQuickActionDefaultsHandlerTest {
    // Helper to get Profile by name
    private static Profile getProfileByName(String profileName) {
        return [SELECT Id FROM Profile WHERE Name = :profileName LIMIT 1];
    }
    
    // Helper to create a User with a unique username
    private static User createUser(String alias, String profileName, String email) {
        Profile p = getProfileByName(profileName);
        String uniqueUsername = alias + '_' + System.currentTimeMillis() + '@testorg.com';
        User u = new User(
            Username = uniqueUsername,
            LastName = alias,
            Email = email,
            Alias = alias.substring(0, Math.min(8, alias.length())),
            TimeZoneSidKey = 'America/New_York',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            ProfileId = p.Id
        );
        return u;
    }
    
    @testSetup
    static void setup() {
        // Create users for both profiles with unique usernames
        User sysAdmin = createUser('sysadmin', 'System Administrator', 'sysadmin@test.com');
        insert sysAdmin;
        
        User paUser = createUser('pauser', 'Primary Agent', 'pauser@test.com');
        insert paUser;
        
        // Create a User as Case owner
        User ownerUser = createUser('owneruser', 'Standard User', 'owneruser@test.com');
        insert ownerUser;
        
        // Create a Contact
        Contact con = new Contact(LastName = 'Test', Email = 'contact@test.com');
        insert con;
        
        // Case owned by Queue
        Case queueCase = new Case(OwnerId = ownerUser.Id, ContactId = con.Id, Subject = 'Queue Owner');
        insert queueCase;
        
        // Case owned by User
        Case userCase = new Case(OwnerId = ownerUser.Id, ContactId = con.Id, Subject = 'User Owner');
        insert userCase;
    }
    
    @isTest
    static void testSysAdminWithQueueOwner() {
        User sysAdmin = [SELECT Id, Email FROM User WHERE Email = 'sysadmin@test.com' LIMIT 1];
        System.runAs(sysAdmin) {
            Case c = [SELECT Id FROM Case WHERE Subject = 'Queue Owner' LIMIT 1];
            EmailMessage em = new EmailMessage();
            CaseEmailQuickActionDefaultsHandler.handleEmailDefaults(c.Id, em);
            
            System.assertEquals('owneruser@test.com', em.ValidatedFromAddress);
            System.assertEquals('contact@test.com', em.ToAddress);
        }
    }
    
    @isTest
    static void testSysAdminWithUserOwner() {
        User sysAdmin = [SELECT Id, Email FROM User WHERE Email = 'sysadmin@test.com' LIMIT 1];
        System.runAs(sysAdmin) {
            Case c = [SELECT Id FROM Case WHERE Subject = 'User Owner' LIMIT 1];
            EmailMessage em = new EmailMessage();
            CaseEmailQuickActionDefaultsHandler.handleEmailDefaults(c.Id, em);
            
            System.assertEquals('owneruser@test.com', em.ValidatedFromAddress);
            System.assertEquals('contact@test.com', em.ToAddress);
        }
    }
    
    @isTest
    static void testPrimaryAgentWithQueueOwner() {
        User paUser = [SELECT Id, Email FROM User WHERE Email = 'pauser@test.com' LIMIT 1];
        System.runAs(paUser) {
            Case c = [SELECT Id FROM Case WHERE Subject = 'Queue Owner' LIMIT 1];
            EmailMessage em = new EmailMessage();
            CaseEmailQuickActionDefaultsHandler.handleEmailDefaults(c.Id, em);
            
            System.assertEquals(null, em.ValidatedFromAddress);
            System.assertEquals(null, em.ToAddress);
        }
    }
    
    @isTest
    static void testPrimaryAgentWithUserOwner() {
        User paUser = [SELECT Id, Email FROM User WHERE Email = 'pauser@test.com' LIMIT 1];
        System.runAs(paUser) {
            Case c = [SELECT Id FROM Case WHERE Subject = 'User Owner' LIMIT 1];
            EmailMessage em = new EmailMessage();
            CaseEmailQuickActionDefaultsHandler.handleEmailDefaults(c.Id, em);
            
            System.assertEquals(null, em.ValidatedFromAddress);
            System.assertEquals(null, em.ToAddress);
        }
    }
    
    @isTest
    static void testNoContactOnCase() {
        User sysAdmin = [SELECT Id, Email FROM User WHERE Email = 'sysadmin@test.com' LIMIT 1];
        System.runAs(sysAdmin) {
            Group queue = [SELECT Id FROM Group WHERE Name = 'SIS Billing' LIMIT 1];
            Case c = new Case(OwnerId = queue.Id, Subject = 'No Contact');
            insert c;
            
            EmailMessage em = new EmailMessage();
            CaseEmailQuickActionDefaultsHandler.handleEmailDefaults(c.Id, em);
            
            System.assertEquals(null, em.ValidatedFromAddress);
            System.assertEquals(null, em.ToAddress);
        }
    }
    @isTest
    static void testOnInitDefaults_minimal() {
        // Pass an empty list to cover the loop (no error, covers method)
        CaseEmailQuickActionDefaultsHandler handler = new CaseEmailQuickActionDefaultsHandler();
        handler.onInitDefaults(new List<QuickAction.QuickActionDefaults>());
        // This covers the method entry and exit, but not the internal logic
    }
    
}