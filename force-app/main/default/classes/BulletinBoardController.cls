public class BulletinBoardController {
    public List<Announcement__c> announcements { get; set; }
    public String selectedAnnouncementId { get; set; }
    public Announcement__c selectedAnnouncement { get; set; }

    public BulletinBoardController() {
        announcements = [SELECT Id, Name, Details__c, CreatedDate FROM Announcement__c WHERE  CreatedDate = LAST_N_DAYS:90 ORDER BY CreatedDate DESC]; // Fetch all announcements
        selectedAnnouncementId = null; // Initialize the instance variable
        selectedAnnouncement = null;
    }

    public void showDetails() {
        if (selectedAnnouncementId != null) {
            selectedAnnouncement = [SELECT Id, Name, Details__c, CreatedDate FROM Announcement__c WHERE Id = :selectedAnnouncementId  LIMIT 1];
        }
    }

    public void hideModal() {
        selectedAnnouncementId = null;
    }
  
}