@isTest
public class BulletinBoardController_Test {
    
    static testMethod void testBulletinBoardController() {
        // Step 1: Setup test data
        List<Announcement__c> announcements = new List<Announcement__c>();
        for (Integer i = 0; i < 5; i++) {
            announcements.add(new Announcement__c(
                Name = 'Announcement ' + i,
                Details__c = 'Details for announcement ' + i,
                CreatedDate = System.now().addDays(-i)
            ));
        }
        insert announcements;

        // Step 2: Instantiate the controller
        BulletinBoardController controller = new BulletinBoardController();
        
        // Step 3: Test the announcements list
        System.assertEquals(5, controller.announcements.size(), 'The announcements list should have 5 items.');

        // Step 4: Test the showDetails method
        controller.selectedAnnouncementId = announcements[0].Id;
        controller.showDetails();
        System.assertNotEquals(null, controller.selectedAnnouncement, 'Selected announcement should not be null.');
        System.assertEquals(announcements[0].Id, controller.selectedAnnouncement.Id, 'The selected announcement should match the expected announcement.');

        // Step 5: Test the hideModal method
        controller.hideModal();
        System.assertEquals(null, controller.selectedAnnouncementId, 'selectedAnnouncementId should be null after hiding modal.');
    }
}