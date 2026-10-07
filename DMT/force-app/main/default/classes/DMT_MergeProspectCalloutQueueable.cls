/**
 * @description Queueable class to handle DMT_MergeProspect callout asynchronously
 * Avoids "uncommitted work pending" error by executing callout outside the synchronous DML context
 * Implements retry logic with maximum 3 attempts
 */
public without sharing class DMT_MergeProspectCalloutQueueable implements Queueable, Database.AllowsCallouts {
  private final Integer attemptNumber;
  private final List<Account> prospectAccounts;
  private final Account clientAccount;
  private static final Integer MAX_ATTEMPTS = 3;

  // Constructor único público
  public DMT_MergeProspectCalloutQueueable(List<Account> prospectAccounts, Account clientAccount) {
    this(prospectAccounts, clientAccount, 1);
  }

  // Constructor privado con retry logic
  @TestVisible
  private DMT_MergeProspectCalloutQueueable(List<Account> prospectAccounts, Account clientAccount, Integer attemptNumber) {
    this.prospectAccounts = prospectAccounts;
    this.clientAccount = clientAccount;
    this.attemptNumber = attemptNumber;
  }

  public void execute(QueueableContext context) {
    Boolean hasError = false;
    String lastErrorMessage = '';

    // Iterar sobre todos los prospects a notificar (normalmente 1-2)
    for (Account prospectAcc : prospectAccounts) {
      String customerId;
      String customerProspectId;
      String groupId;
      String groupProspectId;

      if (prospectAcc.RecordType == null) {
        System.debug('** Error: Prospect account RecordType not loaded for Id: ' + prospectAcc.Id);
        hasError = true;
        lastErrorMessage = 'RecordType not loaded for prospect: ' + prospectAcc.Id;
        continue;
      }

      String prospectRecordType = prospectAcc.RecordType.DeveloperName;

      // Determinar parámetros según RecordType
      if (prospectRecordType == 'Prospect_Subsidiary') {
        customerId = clientAccount.g_customer_id__c;
        customerProspectId = prospectAcc.g_customer_id__c;
        groupId = null;
        groupProspectId = null;

      } else if (prospectRecordType == 'Prospect_Group') {
        customerId = null;
        customerProspectId = null;
        groupId = String.isNotBlank(clientAccount.DES_Group_Code__c) 
          ? clientAccount.DES_Group_Code__c 
          : clientAccount.DES_Main_Parent__r?.DES_Group_Code__c;
        groupProspectId = prospectAcc.DES_Group_Code__c;

      } else {
        System.debug('** Error: Unknown RecordType: ' + prospectRecordType + ' for prospect: ' + prospectAcc.Id);
        hasError = true;
        lastErrorMessage = 'Unknown RecordType: ' + prospectRecordType;
        continue;
      }

      System.debug('** Executing DMT_MergeProspectCallout (' + prospectRecordType + ') - Attempt: ' + attemptNumber + '/' + MAX_ATTEMPTS + 
                   ' - Prospect: ' + prospectAcc.Id + ' - customerId: ' + customerId + ', customerProspectId: ' + customerProspectId + 
                   ', groupId: ' + groupId + ', groupProspectId: ' + groupProspectId);
      try {
        Map<String, Object> serviceResult = DMT_ProspectCallService.callMergeProspectService(customerId, customerProspectId, groupId, groupProspectId);

        if (serviceResult != null && serviceResult.containsKey('error') && (Boolean) serviceResult.get('error') == true) {
          String errorMessage = serviceResult.containsKey('errorMessage') ? String.valueOf(serviceResult.get('errorMessage')) : 'Unknown integration error';
          throw new CalloutException(errorMessage);
        }

        System.debug('** DMT_MergeProspectCallout completed successfully for prospect ' + prospectAcc.Id + ' (attempt ' + attemptNumber + ')');
      } catch (Exception e) {
        hasError = true;
        lastErrorMessage = e.getMessage();
        System.debug('** Error in DMT_MergeProspectCallout for prospect ' + prospectAcc.Id + ' (Attempt ' + attemptNumber + '): ' + e.getMessage());
        System.debug('** Stack trace: ' + e.getStackTraceString());
      }
    }

    // Retry logic
    if (hasError && attemptNumber < MAX_ATTEMPTS) {
      System.debug('** Errors encountered. Retrying... Enqueueing job for attempt ' + (attemptNumber + 1));
      System.enqueueJob(new DMT_MergeProspectCalloutQueueable(prospectAccounts, clientAccount, attemptNumber + 1));
    } else if (hasError) {
      System.debug('** Maximum retry attempts (' + MAX_ATTEMPTS + ') exceeded. Callout failed with last error: ' + lastErrorMessage);
    } else {
      System.debug('** All callouts completed successfully');
    }
  }
}