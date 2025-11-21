global class DocusignResendEnvelopeController {      
    public String docuSignId { get; set; }
    public String message { get; set; }
    
    global PageReference resendEnvelope() {
        docuSignId = ApexPages.currentPage().getParameters().get('id');
        try {
            List<String> envelopeStatuses = getEnvelopeStatuses(docuSignId);
            
            // Check if any status is not Completed or Voided
            Boolean canResend = false;
            for (String envelopeStatus : envelopeStatuses) {
                if ((envelopeStatus != 'Completed') && (envelopeStatus != 'Voided')) {
                    canResend = true;
                    break;
                }
            }
            
            if (canResend) {
                Boolean success = sendEnvelope(docuSignId);
                if (success) {
                    message = 'Envelope resent successfully.';
                } else {
                    message = 'Failed to resend the envelope.';
                }
            } else {
                message = 'The envelope has already been completed or voided. So, It cannot be resent.';
            }
        } catch (Exception e) {
            message = 'Error while resending envelope: ' + e.getMessage();
        }
        return null;
    }
    
    
    private static List<String> getEnvelopeStatuses(String docuSignId) {
        try {
            List<dfsle__EnvelopeStatus__c> envelopeStatuses = [
                SELECT dfsle__Status__c 
                FROM dfsle__EnvelopeStatus__c 
                WHERE dfsle__DocuSignId__c = :docuSignId
            ];
            
            // Extract statuses into a list
            List<String> statuses = new List<String>();
            for (dfsle__EnvelopeStatus__c envStatus : envelopeStatuses) {
                statuses.add(envStatus.dfsle__Status__c);
            }
            
            if (statuses.isEmpty()) {
                throw new QueryException('No matching Envelope statuses found for DocuSign ID: ' + docuSignId);
            }
            
            return statuses;
        } catch (QueryException qe) {
            System.debug('Query Exception: ' + qe.getMessage());
            throw qe; // Re-throw the exception for higher-level handling
        }
    }
    
    private static Boolean sendEnvelope(String docuSignId) {
        try {
            Http http = new Http();
            HttpRequest req = new HttpRequest();
            
            req.setEndpoint('callout:Docusign_API/v2.1/accounts/30407774/envelopes/' + docuSignId + '?resend_envelope=true');// SIS
            //req.setEndpoint('callout:Docusign_API/v2.1/accounts/10866685/envelopes/' + docuSignId + '?resend_envelope=true'); //Prod
            req.setMethod('PUT'); // Use PUT for resending envelopes        
            req.setHeader('Content-Type', 'application/json');
            
            req.setBody('{}'); // Empty body for resend operation
            
            HttpResponse res = http.send(req);
            
            if (res.getStatusCode() == 200) {
                System.debug('Successfully resent envelope: ' + res.getBody());
                return true;
            } else {
                System.debug('Failed to resend envelope: ' + res.getBody());
                return false;
            }
        } catch (Exception e) {
            System.debug('Error in sendEnvelope: ' + e.getMessage());
            return false;
        }
    }
}