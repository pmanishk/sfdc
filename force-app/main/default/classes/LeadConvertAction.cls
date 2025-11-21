global class LeadConvertAction {
  @InvocableMethod(
    label='Lead Convertor'
    description='Given a Lead record to convert to Person Account'
  )
  global static List<ConvertLeadActionResult> convertLead(
    List<Lead> incomingLead
  ) {
    //get convertStatus label
    LeadStatus convertStatus = [
      SELECT Id, MasterLabel
      FROM LeadStatus
      WHERE IsConverted = TRUE
      LIMIT 1
    ];
    list<Database.LeadConvert> leadConverts = new List<Database.LeadConvert>();
    list<ConvertLeadActionResult> result = new List<ConvertLeadActionResult>();
    List<Database.LeadConvertResult> lcr = new List<database.LeadConvertResult>();

    for (Lead currLead : incomingLead) {
      Database.LeadConvert lc = new Database.LeadConvert();
      lc.setLeadId(currLead.id);
      lc.setConvertedStatus(convertStatus.MasterLabel);
      lc.getRelatedPersonAccountRecord();
      //optional disable opportunity convert
      lc.setDoNotCreateOpportunity(true);
      leadConverts.add(lc);
    }

    if (!leadConverts.isEmpty()) {
      lcr = Database.convertLead(leadConverts);
      System.debug(+'result' + lcr);
    }

    for (Database.LeadConvertResult currLCR : lcr) {
      if (currLCR.isSuccess()) {
        ConvertLeadActionResult newResult = new ConvertLeadActionResult();
        newResult.convertedAccount = currLCR.getAccountId();
        result.add(newResult);
      }
    }

    return result;
  }

  global class ConvertLeadActionResult {
    @InvocableVariable
    global Id convertedAccount;
  }
}