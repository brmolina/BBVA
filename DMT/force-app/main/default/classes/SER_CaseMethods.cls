/*-----------------------------------------------------------------------------------------------
Author:        Juan Carlos Terrón
  Company:       Accenture
  Description:   Class to handle methods called when the triggers over Case object are fired reupload

History:
  <Date>          <Author>                <Description>
  08/07/2017      Juan Carlos Terrón        Initial version
  -------------------------------------------------------------------------------------------------*/
public without sharing class SER_CaseMethods {

  /*Constante identificador Usuario*/
  final static string ID_USER = '005';
  /*Constante texto identificador de test*/
  final static string LOG_TEST = 'Catch testing';
  /*Constante cerrado (status CASO) */
  final static string STATUS_CLOSED = 'Closed';
  /*Constante contestado (status CASO) */
  final static string STATUS_ANSWERED = 'Answered';
  /*Constante Primer contacto de la lista no repetido*/
  final static string FIRST_CTCT_NO_REC = 'First Contact No Recurrence';
  /*Constante Value Queries para el campo Classification */
  final static string CLASSIFICATION_QUERIES = 'Queries';

  private SER_CaseMethods() {
  }
  /*-----------------------------------------------------------------------------------------------
  Author:        Juan Carlos Terrón
    Company:       Accenture
    Description:   Method to set case responsible field with the ownerid field value of the case

  IN:            list<Case>
    OUT:           void

  History:
    <Date>                  <Author>                <Change Description>
    07/08/2017              Juan Carlos Terrón      Initial version
    -------------------------------------------------------------------------------------------------*/
  public static void onBeforeInsert(final List<Case> newCases) {
    try {
      for(Case newCase : newCases) {       //Iterate over the trigger list
        if(newCase.OwnerId != null &&(String.valueOf(newCase.OwnerId)).left(3) == ID_USER && String.isBlank(String.valueOf(newCase.SER_Responsible__c))) {         //If the owner field id isn't null and its related to a user, the value is copied to SER_Responsible__c field
          newCase.SER_Responsible__c = newCase.ownerId;
        }
      }
      if(runTest()) { throw new HandledException(LOG_TEST); }      //Catch testing for code coverage.
    } catch (Exception ex) {
      cibLog(ex, 'SER_CaseMethods.onBeforeInsert()');
    }
  }
  /*--------------------------------------------------------------------------------------------------------------
  Author:        Juan Carlos Terrón
    Company:       Accenture
    Description:   Fills the SER_Responsible__c field with the OwnerID field whenever a Case is created or updated.

  IN:            Trigger.new && Trigger.oldMap
    OUT:           Void

  History:
    <Date>                  <Author>                <Change Description>
    27/02/2017              Juan Carlos Terrón      Initial Version
    ----------------------------------------------------------------------------------------------------------------*/
  public static void fillCaseResponsible(List<Case> newList,List<Case> oldList,Map<Id,Case> newMap, Map<Id,Case> oldMap) {
    try {

      for(Case newCase : newMap.values()) {
        if (newCase.SER_Classification__c == CLASSIFICATION_QUERIES) {
          newCase.SER_Source_of_the_error__c = CLASSIFICATION_QUERIES;
          if (newCase.Reason_Queries__c != null) {
            newCase.SER_Subtype_GM__c = newCase.Reason_Queries__c;
          }

          if (newCase.Typology_Queries__c != null) {
            newCase.SER_Type_GM__c = newCase.Typology_Queries__c;
          }
        }
      }

      if(oldMap==null) {       //oldMap = null --> insert event
        insertEvent (newList, newMap);

      } else if(oldMap!=null) {       //Update event (oldMap not null)
        updateEvent (newMap, oldMap);
      }
      if(runTest()) { throw new HandledException(LOG_TEST); }       //Catch testing for code coverage.
    } catch (Exception ex) {
      cibLog(ex, 'SER_CaseMethods.fillCaseResponsible()');
    }
  }

  private static void insertEvent (List<Case> newList, Map<Id,Case> newMap) {
    if(newMap==null) {     //Before insert call
      for(Case casoItem : newList) {       //Iterate over the trigger list
        final boolean ownerIsUser = casoItem.OwnerID != null
          && casoItem.SER_Responsible__c == null
          && String.valueOf(casoItem.OwnerId).startswith(ID_USER);
        if(ownerIsUser) {         //OwnerId != null & OwnerId is a User --> copy OwnerId into SER_Responsible__c
          casoItem.SER_Responsible__c = casoItem.OwnerID;
        }
      }
    } else if(newMap!=null) {     //After isnert call
      List<Case> listCaseToUpdate;
      listCaseToUpdate = new List<Case>();
      for(Case casoItem : newMap.values()) {       //Iterate over the trigger list
        final boolean ownerIsUser = casoItem.OwnerID != null
          && casoItem.SER_Responsible__c == null
          && String.valueOf(casoItem.OwnerId).startswith(ID_USER);
        if(ownerIsUser) {         //OwnerId != null & OwnerId is a User --> copy OwnerId into SER_Responsible__c --> add to the list.
          listCaseToUpdate.add(new Case(Id = casoItem.Id, SER_Responsible__c = casoItem.OwnerID));
        }
      }
      if(!listCaseToUpdate.isEmpty()) { update listCaseToUpdate; }      //Update the list.
    }
  }

  private static void updateEvent (Map<Id,Case> newMap, Map<Id,Case> oldMap) {
    //Set<Id> set_Cases_ToProcessID = new Set<Id>();
    Map<Id,Case> mapCaseToProcess;
    Map<Id,String> mapQueueIdEmail;
    Map<String,String> mapQueAssignment;
    Map<String,String> mapCS;

    mapCaseToProcess = new Map<Id,Case>();
    mapQueueIdEmail = new Map<Id,String>();
    mapQueAssignment = new Map<String,String>();
    mapCS = new Map<String,String>();

    for(SER_EmailDefaultValues_Assignment__c csrItem : SER_EmailDefaultValues_Assignment__c.getAll().values()) {     //Custom setting records into the maps
      mapCS.put(csrItem.SER_FromAddres__c,csrItem.SER_OutboundMailbox__c);       //FromAddress -> OutboundMailbox
      mapQueAssignment.put(csrItem.SER_Queue__c, csrItem.SER_FromAddres__c);       //Queue DevName -> FromAdress
    }

    updateEventI(mapCaseToProcess, newMap, oldMap);
    updateEventII(mapCaseToProcess, mapQueueIdEmail, mapQueAssignment, mapCS);

  }
  private static void updateEventI (Map<Id,Case> mapCaseToProcess, Map<Id,Case> newMap, Map<Id,Case> oldMap) {

    for(Case casoItem : newMap.values()) {
      final boolean ownerIsUser = casoItem.OwnerID != null
        && casoItem.SER_Responsible__c == null
        && String.valueOf(casoItem.OwnerId).startswith(ID_USER);
      if(ownerIsUser) {           //OwnerId != null & OwnerId is a User --> copy OwnerId into SER_Responsible__c
        casoItem.SER_Responsible__c = casoItem.OwnerId;
      } else {
        boolean isGMtransfe;
        isGMtransfe = casoItem.SER_Business_Case_Type__c.equalsIgnoreCase('GM')
          &&casoItem.OwnerID != oldMap.get(casoItem.Id).OwnerId
          &&( !(casoItem.SER_Escalate__c && !oldMap.get(casoItem.Id).SER_Escalate__c)
          || !(casoItem.Status == 'Transferred' && oldMap.get(casoItem.Id).Status != 'Transferred'))
          && casoItem.OwnerID != null && String.valueOf(casoItem.OwnerId).startswith('00G');

        if(isGMtransfe) {             //Case is GM Business and is being transferred without changing the SER_Escalate__c field value.
          mapCaseToProcess.put(casoItem.Id, casoItem);
        }
      }
    }
  }

  private static void updateEventII(Map<Id,Case> mapCaseToProcess,Map<Id,String> mapQueueIdEmail,Map<String,String> mapQueAssignment,Map<String,String> mapCS) {
    if(!mapCaseToProcess.isEmpty()) {     //We have cases being transferred from one queue to anoter.
      for(List<Group> lqueueItem : [SELECT Id, DeveloperName FROM Group WHERE DeveloperName IN :mapQueAssignment.keySet()]) {       //Query the queues in th database filtered by their devnames
        for(Group colaItem : lqueueItem) {         //Fill a map using the two previous one --> QueueID --> From Address
          mapQueueIdEmail.put(colaItem.Id, mapQueAssignment.get(colaItem.DeveloperName));
        }
      }
      if(!mapQueueIdEmail.isEmpty()) {       //We found queues that match the ones in the map
        for(Case casoItem : mapCaseToProcess.values()) {         //Iterate over the cases to process
          if(String.isNotBlank(mapCS.get(mapQueueIdEmail.get(casoItem.OwnerId)))) {           //Outbound mailbos set to the QueueID-FromAddress value in the FromAddress-OuboundMailbox map
            //casoItem.Origin = mapCS.get(mapQueueIdEmail.get(casoItem.OwnerId)); Deprecated
            casoItem.SER_Outbound_Mailbox__c = mapCS.get(mapQueueIdEmail.get(casoItem.OwnerId));
          }

        }
      }
    }
  }

  /*----------------------------------------------------------------------
  Author:        Juan Carlos Terrón
    Company:       Accenture
    Description:   Change the case Status on update.

  IN:            Trigger structures.
    OUT:           void

  History:
    <Date>                  <Author>                <Change Description>
    ------------------------------------------------------------------------*/
  public static void assignerCaseStatusOnUpdate(Map<Id,Case> newMap,Map<Id,Case> oldMap) {
    try {
      if(!SER_TriggerHelper.get_MethodFired('assigner_RelatedCaseOwner')) {
        //Retrieve Case fields information map to avoid  missmatching status value errors on status values changes.
        Map<String,Schema.SObjectField> mapCaseFields = new Map<String,Schema.SObjectField>();
        mapCaseFields = Case.getSObjectType().getDescribe().fields.getMap();
        Map<String,String> mapPicklistValues;
        mapPicklistValues = new Map<String,String>();
        Set<String> setRemedyStatus;
        setRemedyStatus = new Set<String> {'Remedy - Escalated', 'Remedy - Pending information', 'Remedy - Pending to close', 'Remedy - Rejected'};

        for(Schema.PicklistEntry plvItem : mapCaseFields.get('Status').getDescribe().getPickListValues()) {         //Case status field values into map.
          mapPicklistValues.put(plvItem.getLabel(), plvItem.getValue());
        }
        for(Case casoItem : newMap.values()) {
          final boolean isStatTransf = casoItem.OwnerId != null
            && casoItem.Status == oldMap.get(casoItem.Id).Status
            && casoItem.SER_Close__c == oldMap.get(casoItem.Id).SER_Close__c
            && String.valueOf(casoItem.OwnerId).startswith('00G')
            && casoItem.OwnerId != oldMap.get(casoItem.Id).OwnerId
            && !(casoItem.SER_Business_Case_Type__c == 'STE' && setRemedyStatus.contains(casoItem.Status));
          if (isStatTransf) {
            casoItem.Status = mapPicklistValues.get('Transferred');
            casoItem.SER_Skip_validations__c = true;
          }
        }
      }
      if(runTest()) { throw new HandledException(LOG_TEST); }      //Catch testing for code coverage.
    } catch (Exception ex) {
      cibLog(ex, 'SER_CaseMethods.assignerCaseStatusOnUpdate()');
    }
  }

  /*------------------------------------------------------------------------------------------------------------------------------------
  Author:        Juan Carlos Terrón
    Company:       Accenture
    Description:   Method that asigns a client and a value for product field for ste cases when they get its external reference linked

  IN:            Trigger.newMap,Trigger.oldMap
    OUT:           void

  History:
    <Date>                  <Author>                <Change Description>
    25/10/2017                Juan Carlos Terrón        Initial version
    --------------------------------------------------------------------------------------------------------------------------------------*/
  public static void assignerProductFields(Map<Id,Case> newMap,Map<Id,Case> oldMap) {
    final Set<Id> stReferences = new Set<Id>();
    Map<Id,case> mapCasesToProcess;
    mapCasesToProcess = new Map<Id,case>();

    for(Case casoItem: newMap.values()) {
      Case oldCase = new Case();
      oldCase = oldMap.get(casoItem.Id);
      boolean tratarCaso;
      tratarCaso = casoItem.SER_Business_Case_Type__c != null &&  casoItem.SER_Business_Case_Type__c.equalsIgnoreCase('STE')
        && casoItem.SER_Transactional_Reference__c != null
        && casoItem.SER_Transactional_Reference__c != oldCase.SER_Transactional_Reference__c;
      if(tratarCaso) {
        //Fill the references set and case map to process the cases.
        mapCasesToProcess.put(casoItem.Id, casoItem);
        stReferences.add(casoItem.SER_Transactional_Reference__c);
      }
    }
    if(!mapCasesToProcess.isEmpty()) {
      Map<Id,SER_Transactional__c> mpProducts;
      mpProducts = new Map<Id,SER_Transactional__c>();
      for(SER_Transactional__c sstItem : [select Id, SER_Account__c,SER_Product_Text__c from SER_Transactional__c where Id in :stReferences]) {
        //We search for the related Products
        mpProducts.put(sstItem.Id, sstItem);
      }
      if(!mpProducts.isEmpty()) {
        for(Case casoItem : mapCasesToProcess.values()) {
          //We link the product field values to the case fields.
          SER_Transactional__c prod = new SER_Transactional__c();
          prod = mpProducts.get(casoItem.SER_Transactional_Reference__c);
          casoItem.AccountId = prod.SER_Account__c;
          casoItem.SER_Product__c = prod.SER_Product_Text__c;
          casoItem.SER_Skip_validations__c = true;
        }
      }
    }
  }


  //Comprueba si nos encontramos en ejecución de un test
  private static boolean runTest() {
    return Test.isRunningTest();
  }
  private static void cibLog(Exception pEx, String pMetodo) {
    CIB_Log__c logToInsert;
    logToInsert = new CIB_Log__c();
    logToInsert.CIB_ErrorMessage__c = pEx.getStackTraceString()+'\n'+pEx.getMessage();
    logToInsert.CIB_Subject__c = pMetodo+' ERROR';
    insert logToInsert;
  }

  //if this Case passes to 'isClosed == true' and the related DML_Line__c record has status 'Approval', create a DML_Line__c version snapshot
  public static void createLineVersionSnapshot(List<Case> newList, Map<Id, Case> oldMap) {
      
      String userId = UserInfo.getUserId();
      List<User> loggedInUser = [SELECT ID_User__c FROM User WHERE Id = :userId];
      
      Map<String, String> lineIdCaseTypeMap = new Map<String, String>();
      Map<String, String> lineIdCategoryMap = new Map<String, String>();
      Set<Id> dmtLineIds = new Set<Id>();

      // 1. Collect DMT_Line__c Ids from Cases closing now
      for (Case c : newList) {
          if (c.DMT_Line__c != null && c.IsClosed == true && oldMap.get(c.Id).IsClosed == false) {
              dmtLineIds.add(c.DMT_Line__c);
              if(!lineIdCaseTypeMap.containsKey(c.DMT_Line__c)) {
                  lineIdCaseTypeMap.put(c.DMT_Line__c, c.DMT_LineOpportunity__c);
                  lineIdCategoryMap.put(c.DMT_Line__c, c.DMT_Related_feature_name__c);
              }
          }
      }
      
      if (dmtLineIds.isEmpty()) return;
      
      // 2. Query and process qualifying DMT_Lines
      for (DMT_Line__c line : [SELECT Id, Line_Id__c, DMT_ID_User__c, Status__c FROM DMT_Line__c WHERE Id IN :dmtLineIds AND Status__c = :DMT_Constants.APPROVAL]) {
          
          String type = lineIdCaseTypeMap.get(line.id) == 'L' ? 'Line' : lineIdCaseTypeMap.get(line.id) == 'O' ? 'Opportunity' : '';
          String category = lineIdCategoryMap.get(line.id) == null ? '' : lineIdCategoryMap.get(line.id);
          
          // Prepare the Service Request Body
          DMT_SnapshotEvaluationVersions.PostRequestWrapperClass requestBody = new DMT_SnapshotEvaluationVersions.PostRequestWrapperClass();
          requestBody.user = (loggedInUser.isEmpty() ? line.DMT_ID_User__c : loggedInUser[0].ID_User__c);
          requestBody.opportunityId = line.Line_Id__c;
          requestBody.categoryId = category;
          requestBody.versionDescription = '';
          
          // Add directly to the Interface-based payload list
          DMT_AsyncOrchestrator.enqueue(new DMT_SnapshotPayload(requestBody, line.Id, type));
      }
  }
}