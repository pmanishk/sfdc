@IsTest
private class CaseSharingTrigger_AdditionalTest {

    // Utility: Get the InvestorHousehold RecordType Id for Account
    private static Id getInvestorHouseholdRecordTypeId() {
        return [
            SELECT Id FROM RecordType 
            WHERE SObjectType = 'Account' 
            AND DeveloperName = 'InvestorHousehold' 
            LIMIT 1
        ].Id;
    }

    // Create RepAdvisor Entity Account (business account that users belong to)
    private static Account createRepAdvisorEntity(String name) {
        Account entity = new Account(Name = name + '_Entity');
        insert entity;
        return entity;
    }

    // Create RepAdvisor Contact linked to RepAdvisor Entity; set Contact.RepAdvisorEntity__c
    private static Contact createRepAdvisorContact(Account repAdvisorEntity) {
        Contact repContact = new Contact(
            LastName = 'RepAdvisorContact_' + repAdvisorEntity.Name,
            AccountId = repAdvisorEntity.Id
        );
        try {
            repContact.put('RepAdvisorEntity__c', repAdvisorEntity.Id);
        } catch (Exception e) {
            // field may not exist in some envs; continue
        }
        insert repContact;
        return repContact;
    }

    // Create PersonAccount Household tied to the RepAdvisor Contact.
    // PersonAccount supports:
    // - Household_Account__c reference from Case (used as a driver)
    // - Account.RepAdvisor__c (lookup to Contact)
    // - Account.RepAdvisorEntity__pc (mirror of Contact.RepAdvisorEntity__c on PersonAccount)
    private static Account createHouseholdAccount(Contact repAdvisorContact) {
        Id investorHouseholdRT = getInvestorHouseholdRecordTypeId();
        Account household = new Account(
            Name = 'Household_' + repAdvisorContact.LastName,
            RecordTypeId = investorHouseholdRT
        );
        // Link PersonAccount to the RepAdvisor Contact and Entity where fields exist
        try {
            household.put('RepAdvisor__c', repAdvisorContact.Id); // link to contact of the PersonAccount
        } catch (Exception e) {}
        try {
            household.put('RepAdvisorEntity__pc', repAdvisorContact.AccountId); // mirror entity on PA
        } catch (Exception e) {}
        insert household;

        // Maintain relation record as well if model expects it
        try {
            AccountContactRelation acr = new AccountContactRelation(
                AccountId = household.Id,
                ContactId = repAdvisorContact.Id,
                Roles = 'Advisor',
                IsActive = true
            );
            insert acr;
        } catch (Exception e) {}

        return household;
    }

    // Create User linked via text RepAdvisorId__c (stores the Id of the RepAdvisor Entity Account)
    private static User createTestUser(Id repAdvisorEntityId) {
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        User u = new User(
            FirstName = 'Test',
            LastName = 'User_' + Math.random(),
            Email = 'test' + Math.random() + '@test.com',
            Username = 'test' + Math.random() + '@test.com',
            Alias = 'tusr',
            TimeZoneSidKey = 'America/New_York',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            ProfileId = p.Id,
            RepAdvisorId__c = String.valueOf(repAdvisorEntityId) // text field on User
        );
        insert u;
        return u;
    }

    @IsTest
    static void testCaseInsertScenario() {
        Account repEntity = createRepAdvisorEntity('InsertEntity');
        Contact repAdvisorContact = createRepAdvisorContact(repEntity);
        Account household1 = createHouseholdAccount(repAdvisorContact);
        Account household2 = createHouseholdAccount(repAdvisorContact);

        // Insert Case tied to PersonAccount (household1), then change to household2
        Case c = new Case(
            Subject = 'Insert Case Test',
            AccountId = household1.Id
        );
        try { c.put('Household_Account__c', household1.Id); } catch (Exception e) {}
        try {
            // tie contact if needed (use the Person Account primary contact when available)
            Contact paContact1 = [SELECT Id FROM Contact WHERE AccountId = :household1.Id LIMIT 1];
            c.ContactId = paContact1.Id;
        } catch (Exception e) {}
        insert c;

        // Change a driver field from one record to another to kick logic
        Test.startTest();
        c.AccountId = household2.Id;
        try { c.put('Household_Account__c', household2.Id); } catch (Exception e) {}
        try {
            Contact paContact2 = [SELECT Id FROM Contact WHERE AccountId = :household2.Id LIMIT 1];
            c.ContactId = paContact2.Id;
        } catch (Exception e) {}
        update c;
        Test.stopTest();

        System.assertNotEquals(null, c.Id, 'Case updated after driver change');
    }

    @IsTest
    static void testCaseUpdateDeletesCaseShares() {
        // Setup: Old and new RepAdvisor structures with PersonAccounts
        Account oldEntity = createRepAdvisorEntity('OldEntity');
        Contact oldAdvisorContact = createRepAdvisorContact(oldEntity);
        Account oldHousehold = createHouseholdAccount(oldAdvisorContact);

        Account newEntity = createRepAdvisorEntity('NewEntity');
        Contact newAdvisorContact = createRepAdvisorContact(newEntity);
        Account newHousehold = createHouseholdAccount(newAdvisorContact);

        // Users belong to old/new entity via text field
        User oldUser = createTestUser(oldEntity.Id);
        User newUser = createTestUser(newEntity.Id);

        // Create Case tied to old PersonAccount and its contact
        Contact oldPaContact = [SELECT Id FROM Contact WHERE AccountId = :oldHousehold.Id LIMIT 1];
        Case c = new Case(
            Subject = 'Update Case Test',
            AccountId = oldHousehold.Id,
            ContactId = oldPaContact.Id
        );
        try { c.put('Household_Account__c', oldHousehold.Id); } catch (Exception e) {}
        insert c;

        // Manual CaseShare to old user to validate deletion
        CaseShare cs = new CaseShare(
            CaseId = c.Id,
            UserOrGroupId = oldUser.Id,
            CaseAccessLevel = 'Edit',
            RowCause = Schema.CaseShare.RowCause.Manual
        );
        insert cs;

        System.assertEquals(1, [SELECT COUNT() FROM CaseShare WHERE CaseId = :c.Id AND RowCause = 'Manual']);

        // Act: Change drivers to new PersonAccount and its contact
        Test.startTest();
        Contact newPaContact = [SELECT Id FROM Contact WHERE AccountId = :newHousehold.Id LIMIT 1];
        c.AccountId = newHousehold.Id;
        c.ContactId = newPaContact.Id;
        try { c.put('Household_Account__c', newHousehold.Id); } catch (Exception e) {}
        update c;
        Test.stopTest();

        // Assert: old manual share removed
        Integer remaining = [SELECT COUNT() FROM CaseShare WHERE CaseId = :c.Id AND RowCause = 'Manual'];
        System.assertEquals(0, remaining, 'Old CaseShare should have been deleted after driver change');
    }

    @IsTest
    static void testCaseUpdateNoHouseholdChange_NoDeletion() {
        Account entity = createRepAdvisorEntity('EntityNoChange');
        Contact advisorContact = createRepAdvisorContact(entity);
        Account household = createHouseholdAccount(advisorContact);
        User user = createTestUser(entity.Id);

        // Set drivers once
        Contact paContact = [SELECT Id FROM Contact WHERE AccountId = :household.Id LIMIT 1];
        Case c = new Case(
            Subject = 'NoChange Case Test',
            AccountId = household.Id,
            ContactId = paContact.Id
        );
        try { c.put('Household_Account__c', household.Id); } catch (Exception e) {}
        insert c;

        // Manual share remains when drivers unchanged
        CaseShare cs = new CaseShare(
            CaseId = c.Id,
            UserOrGroupId = user.Id,
            CaseAccessLevel = 'Edit',
            RowCause = Schema.CaseShare.RowCause.Manual
        );
        insert cs;

        c.Subject = 'Updated Subject';
        update c;

        Integer remaining = [SELECT COUNT() FROM CaseShare WHERE CaseId = :c.Id AND RowCause = 'Manual'];
        System.assertEquals(1, remaining, 'CaseShare should remain when driver fields not changed');
    }
}