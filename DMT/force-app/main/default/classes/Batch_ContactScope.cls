/********************************************************************************************
 *   @author: GlobalDesktop - APC
 *   @Method: Batch_ContactScope
 *   @Description: Batch to update previous data related to scope field of contacts - related to ContactScopeManagement.class

 *   @Versions:
        v1 - 2019/01/28 - Initial version
 ******************************************************************************************************************************************************/
public without sharing class Batch_ContactScope implements Database.Batchable<Sobject>, Database.Stateful {
  /**
   * @author Global Desktop
   * @description Variable para filtrar en la query dinamica
   */
  final private Id rtDesktopContact = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Desktop Contact').getRecordTypeId();
  /**
   * @author Global Desktop
   * @description Variable para filtrar en la query dinamica
   */
  final String labSubsidiary = Label.DES_RT_Subsidiary;
  /**
   * @author Global Desktop
   * @description Variable para filtrar en la query dinamica
   */
  final String labGroup = Label.DES_RT_Group;
  /**
   * @author Global Desktop
   * @description Variable para filtrar en la query dinamica
   */
  Integer rowsProcessed = 0;
  /**
   * @author Global Desktop
   * @description Query dinamica para recuperar los registros de contacto
   */
  final private String pQuery = 'SELECT Id, Name, DES_Scope__c, Email_ExternalID__c, AccountId, Account.RecordType.Name, RecordTypeId' +
                                + ' , Account.DES_Entity_Hierarchy__c, Account.DES_Structure_Type__c, Account.DES_Country_Client__c, Account.DES_Main_Parent__c, Account.DES_Main_Parent__r.DES_Country_Client__c, Account.DES_Main_Parent__r.DES_Client_Matrix__r.DES_Country_Client__c'
                                + ' FROM Contact' +
                                + ' WHERE RecordTypeId = :rtDesktopContact' +
                                + (Test.isRunningTest() ? ' LIMIT 200' : '');

  /**
   * @author Global Desktop
   * @description Variable para guardar literal 'S'
   */
  private final static String STRING_S = 'S';

  /**
   * @author Global Desktop
   * @description Constructor del batch
   */
  public Batch_ContactScope() {
    system.debug('Constructor del batch');
    system.debug(rtDesktopContact);
    system.debug(labSubsidiary);
    system.debug(labGroup);
    system.debug(rowsProcessed);
  }

  /**
   * @author Global Desktop
   * @description Start del batch
   */
  public Database.QueryLocator start(Database.BatchableContext bContext) {
    System.debug('::::Query: ' + pQuery);
    return Database.getQueryLocator(pQuery);
  }

  /**
   * @author Global Desktop
   * @description Execute del batch
   */
  public void execute(Database.BatchableContext bContext, List<Contact> scope) {
    final Set<String> setIdAcc = new Set<String>();
    for(Contact con : scope) {
      setIdAcc.add(con.AccountId);
    }

    final Map<String, List<AccountContactRelation> > mapAcr = new Map<String, List<AccountContactRelation> >();
    final List<AccountContactRelation> lstACRprevious = [SELECT Id, AccountId, ContactId, Account.DES_Entity_Hierarchy__c, Account.RecordType.Name,
                                                         Account.DES_Structure_Type__c, Account.DES_Country_Client__c,
                                                         Account.DES_Main_Parent__c, Account.DES_Main_Parent__r.DES_Country_Client__c,
                                                         Account.DES_Main_Parent__r.DES_Client_Matrix__r.DES_Country_Client__c,
                                                         isDirect,record_created_hierarchy_type__c
                                                         FROM AccountContactRelation WHERE AccountId IN :setIdAcc ];
    for(AccountContactRelation acr : lstACRprevious) {
      List<AccountContactRelation> lstACR = mapAcr.get(acr.ContactId);
      if(lstACR == null) {
        lstACR = new List<AccountContactRelation>();
        lstACR.add(acr);
      } else {
        lstACR.add(acr);
      }
      mapAcr.put(acr.ContactId, lstACR);
    }
    final List<Contact> lstContact = new List<Contact>();
    for(Contact con : scope) {
      // con.validat eEditMode__c = true;
      con.editable_field_type__c = true;
      con.DES_Scope__c = '';
      final List<AccountContactRelation> relatedACR = mapAcr.get(con.Id);
      if(relatedACR != null) {
        final Contact contAux = setContactScope(relatedACR,con);
        con.DES_SCOPE__c = contAux.DES_SCOPE__c;
      }
      lstContact.add(con);
    }
    rowsProcessed = scope.size();
    update lstContact;
  }


  /**
   * @author Global Desktop
   * @description Finish del batch
   */
  public void finish(Database.BatchableContext bContext) {
    System.debug('::::finish init: ');


    final AsyncApexJob job = [SELECT Id, Status, NumberOfErrors, JobItemsProcessed, TotalJobItems, CreatedBy.Email
                              FROM AsyncApexJob WHERE Id = :bContext.getJobId()];
    //Debugs: summary
    System.debug('::::SUMMARY: ');
    System.debug('::::Batches Created: ' + job.JobItemsProcessed);
    System.debug('::::Number of Errors: ' + job.NumberOfErrors);
    System.debug('::::Status: ' + job.Status);

    // Send an email to the Apex job's submitter notifying of job completion.
    final Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
    final String[] toAddresses = new String[] { job.CreatedBy.Email };
    mail.setToAddresses(toAddresses);
    mail.setSubject('Apex Sharing Recalculation ' + job.Status);
    mail.setPlainTextBody('The batch Apex job processed ' + job.TotalJobItems +
                          ' batches with '+ job.NumberOfErrors + ' failures.' +
                          ' Items processed: ' + rowsProcessed);
    Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
  }

  //////////////////////////////// PRIVATE METHODS

  /**
   * @author Global Desktop
   * @description check Direct contact in AccountContactRelation
   */
  private static Contact checkAccount4ACRdirect (AccountContactRelation acr, Contact contacto) {
    System.debug('::::checkAccount4ACRdirect init ');

    System.debug('::::acr: ' + acr);
    System.debug('::::contacto: ' + contacto);
    final Contact cont = contacto;

    // a) acc group -  DES_Structure_Type__c == 'Group'
    if(checkRTName(acr.Account.RecordType.Name)) {
      System.debug('::::group ');
      cont.DES_Scope__c = 'Global';      //acc.DES_Country_Client__c;

      // b) Subsidiariy == Matriz: -> DES_Structure_Type__c == 'Subsidiary' y DES_Entity_Hierarchy__c == S
    } else if(acr.Account.DES_Entity_Hierarchy__c == STRING_S) {
      System.debug('::::Subsidiariy == Matriz: ');
      final String pGrupo = acr.Account.DES_Main_Parent__r.DES_Country_Client__c;
      final String pMatrix = acr.Account.DES_Main_Parent__r.DES_Client_Matrix__r.DES_Country_Client__c;           //informado sólo a nivel de "Grupo"
      //a1 || a2
      cont.DES_Scope__c = pMatrix == pGrupo ? 'Global' : pMatrix;

      // c) subsidiario != matriz -> DES_Structure_Type__c == 'Subsidiary' y DES_Entity_Hierarchy__c == N o null
    } else  {
      System.debug('::::Subsidiariy != Matriz: ');
      final String pDirectAcc = acr.Account.DES_Country_Client__c;
      cont.DES_Scope__c = pDirectAcc;
    }
    return cont;
  }

  /**
   * @author Global Desktop
   * @description check Direct contact in AccountContactRelation
   */
  private static Contact setContactScope (list<AccountContactRelation> relatedACR, Contact contacto) {
    // final Set<String> setRelatedScopes = new Set<String>();
    final Set<String> setScopes = new Set<String>();
    final Contact con = contacto;
    String scopeAux;
    for(AccountContactRelation acr : relatedACR) {
      // final Contact conAux;
      if(acr.isDirect == true) {
        //directa
        Contact conDir;
        conDir = checkAccount4ACRdirect(acr, con);
        scopeAux = conDir.DES_Scope__c;             //NOSONAR
        setScopes.add(conDir.DES_Scope__c);
      }

      // final Contact conAux = checkAccount4ACRdirect(acr, con);
      // setRelatedScopes.add(conAux.DES_Scope__c);
    }
    // con.DES_Scope__c = String.join((Iterable<String>)setRelatedScopes, ';');
    con.DES_Scope__c = String.join((Iterable<String>)setScopes, ';');

    return con;
  }
  /**
   * @uthor Global Desktop
   * @description validates the recordTypeName
   * @Input RecordTypeName
   * @Output Boolean (true when rtn IN Grupo{2},Supragrupo,Subgrupo,G.Gestión Compartida)
   */
  private static Boolean checkRTName(String rtn) {
    return rtn == Label.DES_RT_NAME_COMMERCIAL_CLIENT || rtn == Label.DES_STR_TYPE_Group || rtn == Label.DES_RT_Supragroup || rtn == Label.DES_RT_Subgroup || rtn == Label.DES_STR_TYPE_Shared_Manag_Group ? true : false;
  }
}