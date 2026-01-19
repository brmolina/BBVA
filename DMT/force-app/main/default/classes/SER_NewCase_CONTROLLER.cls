/**
*  Author:    Juan Carlos Terrón
*  Company:    Accenture
*  Description:  Class to handle methods called when the triggers over Case object are fired
*
*  History:
*  <Date>        <Author>            <Description>
*  08/07/2017    Juan Carlos Terrón         Initial version
*  05/07/2018    Javier Touchard Vicente    saveNewCase method
*  05/10/2018    Victor Velandia            getMailingGroup
*  21/11/2018    Victor Velandia            Assigned to RecordType in the case its respective user
*  12/12/2018    Victor Velandia            Assigned to Email Outbox GNC and required field Account, Case Origin in GNC
*  21/03/2019    Javier Touchard            GTB
*/
public without sharing class SER_NewCase_CONTROLLER {

  /*Instancia única de la clase para implementar un patrón Singleton*/
  private static SER_NewCase_CONTROLLER instance;

  /*---------------------------------------------------------------------------------------
    Company:       BBVA
    Description:   private constructor.
  ---------------------------------------------------------------------------------------*/
  private SER_NewCase_CONTROLLER() {
  }

  /*---------------------------------------------------------------------------------------
    Company:       BBVA
    Description:   instantiation method.
    IN:            void
    OUT:           SER_NewCase_CONTROLLER
  ---------------------------------------------------------------------------------------*/
  public static SER_NewCase_CONTROLLER getInstance() {
    // lazy load the record type - only initialize if it doesn't already exist
    if(instance == null) {
      instance = new SER_NewCase_CONTROLLER();
    }
    return instance;
  }

  /**
  * description: initData
  * @author Victor Velandia
  */
  @AuraEnabled
  public static InitWrapResponse initData(String userid) {
    try {
      InitWrapResponse initData;
      initData = new InitWrapResponse();

      User currentuser;
      currentuser = new User();
      currentuser = [Select Id, ProfileId, Profile.Name, Name From user Where id =:userid limit 1][0];
      initData.user = currentuser;
      initData.hasGTBPS = hasGTBPermissionSet(userid);

      for(RecordType rt : [SELECT Id,Name FROM RecordType WHERE Name = 'GNC User' OR Name = 'GM User']) {
        if(rt.name.equalsIgnoreCase('GNC User')) {
          initData.gncRT = rt.Id;
        }
      }
      return initData;
    } catch(exception e) {
      system.debug(SER_Constant.SER_EXCEPTION);
      System.debug(e);
      throw new AuraHandledException(Label.SER_Error + ' ' + e);
    }
  }

  /**
  * description: saveNewCase
  * @author Victor Velandia
  */
  @AuraEnabled
  public static String saveNewCase(String userid, String recordType) {
    try {
      string result;
      Case newCase;
      newCase = new Case();
      if (recordType != null) {
        newCase.recordTypeId = recordType;
      }
      List<SER_MailingGroup__c> lstmailingGroup;
      lstmailingGroup = [Select Id,SER_DefaultMailbox__c,SER_MailingGroup__c From SER_MailingGroup__c Where SER_User__c =:userid limit 1];
      if(lstmailingGroup != null && !lstmailingGroup.isEmpty()) {
        newCase.SER_MailingGroup__c = lstmailingGroup[0].SER_MailingGroup__c;
        newCase.SER_Outbound_Mailbox__c = lstmailingGroup[0].SER_DefaultMailbox__c;
      }
      insert newCase;
      system.debug('inserto a savecase');
      result = newCase.Id;
      return result;
    } catch(exception e) {
      system.debug(SER_Constant.SER_EXCEPTION);
      System.debug(e);
      throw new AuraHandledException(Label.SER_Error + ' ' + e);
    }
  }

  /**
  * description: getMailingGroup
  * @author Victor Velandia
  */
  public static SER_MailingGroup__c getMailingGroup() {
    SER_MailingGroup__c objMailingGroup = new SER_MailingGroup__c();
    try {
      String userInfo = UserInfo.getUserId();
      objMailingGroup = [Select Id, SER_DefaultMailbox__c, SER_MailingGroup__c From SER_MailingGroup__c Where SER_User__c = : userInfo limit 1];
    } catch(exception e) {
      system.debug(SER_Constant.SER_EXCEPTION);
      System.debug(e);
    }
    return objMailingGroup;
  }

  /**
  * description: getDataTransCaseGNC
  * @author Victor Velandia
  */
  @AuraEnabled
  public static WrapResponseGNC getDataCaseGNC() {
    try {
      WrapResponseGNC wrapRtaGNC;
      wrapRtaGNC = new WrapResponseGNC();
      SER_MailingGroup__c objMailingGroup;
      objMailingGroup = getMailingGroup();
      if(objMailingGroup != null) {
        wrapRtaGNC.stMailingGroupGNC = objMailingGroup.SER_MailingGroup__c;
        wrapRtaGNC.strEmailOutboxGNC = objMailingGroup.SER_DefaultMailbox__c;
      }
      system.debug('--->>> wrapRtaGNC-' + wrapRtaGNC);
      return wrapRtaGNC;
    } catch(exception e) {
      system.debug(SER_Constant.SER_EXCEPTION);
      System.debug(e);
      throw new AuraHandledException(Label.SER_Error + ' ' + e);
    }
  }

  /**
  * description: hasGTBPermissionSet
  * @author Javier Touchard.
  */
  public static Boolean hasGTBPermissionSet(Id userid) {
    Boolean hasPermission = false;
    List<PermissionSetAssignment> psAssigmentList;
    psAssigmentList = new List<PermissionSetAssignment>();
    try {
      psAssigmentList = [SELECT Id FROM PermissionSetAssignment WHERE AssigneeId = :userid AND PermissionSetId IN (SELECT Id FROM PermissionSet WHERE Label = :Label.SER_GTB_Issue_Management_access)];
      if(!psAssigmentList.isEmpty()) {
        hasPermission = true;
      }
    } catch(exception e) {
      system.debug(SER_Constant.SER_EXCEPTION);
      System.debug(e);
    }
    return hasPermission;
  }

  /************************************************************************
  *******************        WRAPPERS        *********************
  ************************************************************************/
  /**
  * description: InitWrapResponse
  * @author Javier Touchard
  */
  public class InitWrapResponse {
    /**
    * description: user
    * @author Javier Touchard
    */
    @AuraEnabled
    public User user {get; set;}
    /**
    * description: id del record type de los casos de GNC.
    * @author Javier Touchard
    */
    @AuraEnabled
    public Id gncRT {get; set;}
        /**
    * description: indicates whether the user has 'GTB Issue Management access' permission set.
    * @author Javier Touchard
    */
    @AuraEnabled
    public Boolean hasGTBPS {get; set;}
  }

  /**
  * description: WrapResponseGNC
  * @author Victor Velandia
  */
  public class WrapResponseGNC {
    /**
    * description: stMailingGroupGNC
    * @author Victor Velandia
    */
    @AuraEnabled
    public String stMailingGroupGNC {get; set;}
    /**
    * description: strEmailOutboxGNC
    * @author Victor Velandia
    */
    @AuraEnabled
    public String strEmailOutboxGNC {get; set;}
  }
}