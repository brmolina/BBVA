/*-----------------------------------------------------------------------------------------------
    Author:        Rodrigo Fdez-Victorio
    Company:       Accenture
    Description:   Subclass to handle email methods called when the triggers over Case object are fired

    History:
    <Date>          <Author>                <Description>
    08/07/2017      Juan Carlos Terrón        Initial version
    -------------------------------------------------------------------------------------------------*/
public without sharing class SER_CaseMethodsEmail {

  /*Constante texto identificador de test*/
  final static string LOG_TEST = 'Catch testing';
  /*Null para los strings */
  final static String STR_NULL;

  private SER_CaseMethodsEmail() {
  }
  /*-------------------------------------------------------------------------
      Author:        Juan Carlos Terrón
      Company:       Accenture
      Description:   Method to avoid duplicated cases from Email 2 Case

      IN:            Case Trigger structures.
      OUT:           void

      History:
      <Date>                  <Author>                <Change Description>
      24/04/2017              Juan Carlos Terrón      Initial Version
      --------------------------------------------------------------------------*/
  public static void checkerDuplicatedEmail2Case(Map<Id,Case> newMap) {
    try {
      CIB_Log__c log = new CIB_Log__c();
      log.CIB_Subject__c = 'checker_DuplicatedEmail2Case LOG';
      log.CIB_ErrorMessage__c = '';

      Set<Id> setnewIds;
      setnewIds = new Set<Id>();
      Set<String> setE2CCodes;
      setE2CCodes = new Set<String>();

      //Map<Id,Case> map_E2CCases = new Map<Id,Case>();
      log.CIB_ErrorMessage__c += 'UserInfo:' + UserInfo.getUserId() + '\n';
      for(Case casoItem : newMap.values()) {
        boolean incluirCaso = String.isNotBlank(casoItem.Origin)
                              && casoItem.Origin.startswithIgnoreCase('Email')
                              && casoItem.SER_EmailToCaseCode__c != null;
        if (incluirCaso && casoItem.SuppliedEmail==null) {
          log.CIB_ErrorMessage__c += 'e2cUser:' + Label.SER_E2C_USER_ID + ' createdBy:' + casoItem.CreatedById + '\n';
          incluirCaso = casoItem.CreatedById==Label.SER_E2C_USER_ID;
        }
        if(incluirCaso) {         //Case has email to case code.
          log.CIB_ErrorMessage__c += 'BCT: '+casoItem.SER_Business_Case_Type__c+'\n';
          setE2CCodes.add(casoItem.SER_EmailToCaseCode__c);
          setnewIds.add(casoItem.Id);

          if(!SER_Case_TriggerHelper.map_EmailToCase.containsKey(casoItem.Id)) {           //The case is added to the static map.
            SER_Case_TriggerHelper.map_EmailToCase.put(casoItem.Id,casoItem);
          }
        }
      }
      log.CIB_ErrorMessage__c += 'set de codes e2c(size) '+setE2CCodes.size()+'\n';

      if(runTest()) {
        throw new HandledException('Catch testing');         //Catch testing for code coverage.
      }

      insert log;
    } catch (Exception ex) {
      CIB_Log__c logToInsert;
      logToInsert = new CIB_Log__c();
      logToInsert.CIB_ErrorMessage__c = ex.getStackTraceString()+'\n'+ex.getMessage();
      logToInsert.CIB_Subject__c = 'SER_CaseMethods.checker_DuplicatedEmail2Case() ERROR';
      insert logToInsert;
    }
  }

  /*-------------------------------------------------------------------------------
      Author:        Juan Carlos Terrón
      Company:       Accenture
      Description:   MEthod that generates Case SER_EmailToCaseCode__c field.

      IN:            Trigger.new
      OUT:           void

      History:
      <Date>                  <Author>                <Change Description>
      Juan Carlos Terrón      24/04/2017              Initial version.
      Brian capilla Fernández 08/09/2017              Ahora se guarda un MD5
      ---------------------------------------------------------------------------------*/
  public static void generateSEREmailToCaseCode(List<Case> news) {
    try {
      for(Case casoItem : news) {
        if( String.isNotBlank(casoItem.Origin) && casoItem.Origin.containsIgnoreCase('Email')) {
          System.Debug('entro en el caso');

          //Case comes from email to case creation.
          //E2C code creation.
          final String ccat=stringToValidate(casoItem);
          if (String.isNotBlank(ccat)) {
            casoItem.SER_EmailToCaseCode__c = EncodingUtil.base64Encode(Crypto.generateDigest('MD5', Blob.valueOf(ccat)));
            casoItem.SER_Skip_validations__c = true;
          } else {
            casoItem.SER_EmailToCaseCode__c = STR_NULL;
          }

          if(!SER_Case_TriggerHelper.bl_E2CProcessing) {
            SER_Case_TriggerHelper.bl_E2CProcessing = isEmailToCase (casoItem);            //Static flag for e2c processing set to true.
          }
        } else {
          //If isn't e2c case, the code is null.
          casoItem.SER_EmailToCaseCode__c = STR_NULL;
        }
      }
      if(runTest()) {
        throw new HandledException(LOG_TEST);
      }      //Catch testing for code coverage.
    } catch (Exception ex) {
      CIB_LogUtils.create_Log('SER_CaseMethods.generateSEREmailToCaseCode()', ex.getStackTraceString()+'\n'+ex.getMessage());
    }
  }

  private static String stringToValidate (Case pCaso) {
    String res = '';

    if (String.isNotBlank(pCaso.SuppliedEmail)) {
      res = res + (pCaso.SuppliedEmail);
    }
    if (pCaso.Subject!=null) {
      res = res + pCaso.Subject;
    }
    if (pCaso.AccountId!=null) {
      res = res + pCaso.AccountId;
    }
    return res;
  }

  private static boolean isEmailToCase (Case pCaso) {
    boolean salida = false;
    string strLog = '';
    CIB_Log__c logToInsert;
    logToInsert = new CIB_Log__c();
    logToInsert.CIB_Subject__c = 'isEmailToCase';
    strLog +='UserInfo:' + UserInfo.getUserId() + '\n';

    final boolean originEmail = String.isNotBlank(pCaso.Origin) && pCaso.Origin.containsIgnoreCase('Email');
    final boolean supInformado = String.isNotBlank(pCaso.SuppliedEmail);
    strLog += 'origin:' + originEmail + '\n';
    strLog += 'supInformado:' + supInformado + '\n';

    System.Debug('origin:'+ originEmail + ' supInformado:'+ supInformado);
    if (originEmail && supInformado) {
      salida = true;
    } else if (originEmail && UserInfo.getUserId()==Label.SER_E2C_USER_ID) {
      salida = true;
    }
    strLog = strLog + 'salida:' + salida + '\n';
    logToInsert.CIB_ErrorMessage__c = strLog;
    insert logToInsert;
    return salida;
  }

  /*------------------------------------------------------------------------------------
      Author:        Juan Carlos Terrón
      Company:       Accenture
      Description:   Assigns SER_MailingGroup__c field whenever the ownerid id updated.

      IN:            Map<Id,Case>x2(Triggernew and old maps)
      OUT:           void

      History:
      <Date>                  <Author>                <Change Description>
      19/06/2017              Juan Carlos Terrón      Initial version.
      --------------------------------------------------------------------------------------*/
  public static void assignerMailingGroup(Map<Id,Case> newMap, Map<Id,Case> oldMap) {
    try {
      //Maps for Queues Owned Cases mailbox and mailing group values
      Map<Id,String> mapQueIDMG;
      mapQueIDMG = new Map<Id,String>();       //map_queue_ID_MailingGroup
      System.debug ('mapQueIDMG'+ mapQueIDMG);

      Map<Id,String> mpQueIDdfltMBx;       //map_Queue_Id_DefaultMailbox
      mpQueIDdfltMBx = new Map<Id,String>();
      System.debug('mpQueIDdfltMBx'+ mpQueIDdfltMBx);

      Map<String,String> mpQueNMDfltMBx;      //map_QueueName_DefaultMailbox
      mpQueNMDfltMBx = new Map<String,String>();

      Map<String,String> mpQueNmMG;       //map_QueueName_MailingGroup
      mpQueNmMG = new Map<String,String>();
      System.debug('mpQueNmMG'+ mpQueNmMG);

      Map<Id,Case> mpReas2Queue;       //map_ReassignedToQueue
      mpReas2Queue = new Map<Id,Case>();
      System.debug('mpReas2Queue'+ mpReas2Queue);

      assigDefValues(mpQueNmMG, mpQueNMDfltMBx);

      for(Case casoItem : newMap.values()) {
        Case oldCase = new Case();
        oldCase = oldMap.get(casoItem.Id);
        boolean tratarCaso;
        tratarCaso = casoItem.OwnerId != oldCase.OwnerId && String.valueOf(casoItem.OwnerId).startswithIgnoreCase('00G');
        if(tratarCaso) {
          //Owner is a QUEUE
          mpReas2Queue.put(casoItem.Id,casoItem);
          mapQueIDMG.put(casoItem.OwnerId,'');
        }
      }
      if(!mpReas2Queue.isEmpty() && mailingGroupRelated(mapQueIDMG, mpQueIDdfltMBx, mpQueNMDfltMBx, mpQueNmMG)) {
        //There are reassignments to queue to process
        for(Case casoItem : mpReas2Queue.values()) {
          //We do the Mailing group field assignment
          newMap.get(casoItem.Id).SER_MailingGroup__c = mapQueIDMG.get(casoItem.OwnerId);
          boolean actOutMlbx;
          actOutMlbx = mpQueIDdfltMBx.containsKey(casoItem.OwnerId) && String.isNotBlank(mpQueIDdfltMBx.get(casoItem.OwnerId));
          if(actOutMlbx) {
            //Only if the mailing group record has a value for outbound mailbox we set it.
            newMap.get(casoItem.Id).SER_Outbound_Mailbox__c = mpQueIDdfltMBx.get(casoItem.OwnerId);
          }
        }
      }
      if(runTest()) { throw new HandledException(LOG_TEST); }      //Catch testing for code coverage.
    } catch (Exception ex) {
      CIB_LogUtils.create_Log('SER_CaseMethods.assignerMailingGroup()', ex.getStackTraceString()+'\n'+ex.getMessage());
    }
  }

  private static boolean mailingGroupRelated(Map<Id,String> mapQueIDMG, Map<Id,String> mpQueIDdfltMBx,Map<String,String> mpQueNMDfltMBx, Map<String,String> mpQueNmMG) {
    boolean res = false;

    for(Group groupItem : [select Id,DeveloperName from Group where DeveloperName in :mpQueNmMG.keySet() and Id in :mapQueIDMG.keySet()]) {
      //We search for the related mailing group for the queues and fills the maps to process
      mapQueIDMG.put(groupItem.Id,mpQueNmMG.get(groupItem.DeveloperName));
      mpQueIDdfltMBx.put(groupItem.Id,mpQueNMDfltMBx.get(groupItem.DeveloperName));

      res = true;       //Flag to process if there are mailing groups.
    }

    return res;
  }

  private static void assigDefValues(Map<String,String> pMpQueNmMG,Map<String,String> pMpQueNMDfltMBx) {
    for(SER_EmailDefaultValues_Assignment__c csr : SER_EmailDefaultValues_Assignment__c.getAll().values()) {

      //Custom setting map QueueName-MGroup & QueueName-OBOX
      pmpQueNmMG.put(csr.SER_Queue__c,csr.SER_MailingGroup__c);
      pmpQueNMDfltMBx.put(csr.SER_Queue__c,csr.SER_OutboundMailbox__c);
    }
  }

  private static boolean runTest() {
    return Test.isRunningTest();
  }
}