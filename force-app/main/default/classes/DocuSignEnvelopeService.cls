public with sharing class DocuSignEnvelopeService {
    // Method to void the envelope
    @future(callout=true)
    public static void voidEnvelope(String envelopeId) {
        String docusignEndpoint = 'callout:Docusign_API/v2.1/accounts/10866685/envelopes/' + envelopeId;
        String voidedReason = 'Voided from Salesforce'; // Default voided reason

        Http http = new Http();
        HttpRequest request = new HttpRequest();
        request.setEndpoint(docusignEndpoint);
        request.setMethod('PUT');
        request.setHeader('Content-Type', 'application/json');

        // Set the void reason
        String requestBody = '{"status": "voided", "voidedReason": "' + voidedReason + '"}';
        request.setBody(requestBody);

        try {
            HttpResponse response = http.send(request);
            if (response.getStatusCode() == 200) {
                System.debug('Envelope voided successfully. Response: ' + response.getBody());
            } else {
                System.debug('Failed to void envelope. Status Code: ' + response.getStatusCode() + ', Response: ' + response.getBody());
                throw new CalloutException('Failed to void envelope. Response: ' + response.getBody());
            }
        } catch (Exception ex) {
            System.debug('Error while voiding envelope: ' + ex.getMessage());
            throw new CalloutException('Error while voiding envelope: ' + ex.getMessage());
        } 
    }
}