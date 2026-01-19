/*------------------------------------------------------------
    Author:        Juan Carlos Terrón
    Company:       Accenture
    Description:   Case redirect logic

    History:
    <Date>          <Author>                <Description>
    30/11/2018      Juan Carlos Terrón        Initial version
--------------------------------------------------------------*/
public with sharing class SER_E2C_CaseRedirect {
  /*Log to insert*/
  public CIB_Log__c log {get; set;}
  /*Emails to process*/
  public Map<Id,EmailMessage> mapEmails {get; set;}
  /*Cases related to the emails to process*/
  public Map<Id,Case> mapCases {get; set;}
  /*Map of case id and their related destiny addresses*/
  public Map<Id,String> mapIdAddress {get; set;}
  /*Map of processed cases ready to eb updated*/
  public Map<Id,Case> mapCasesToUpdate {get; set;}
  /*Map of queues related to configuration settings*/
  public Map<String,Id> mapQueues {get; set;}
  /*Map of settings by address*/
  public Map<String,String> mapCSAddress {get; set;}
  /*Map of settings by address*/
  public Map<String,SER_EmailDefaultValues_Assignment__c> mapConfigurations {get; set;}
  /** Mapa email.ParentId - email.FromAddress */
  public Map<Id,String> mapCaseFromEmail {get; set;}
  /*@Author : Juan Carlos Terrón Ruiz
    @Método : Constructor*/
  public SER_E2C_CaseRedirect(Map<Id,EmailMessage> mapEmails) {
    this.mapEmails = mapEmails;
    this.log = new CIB_Log__c();
    if(SER_Case_TriggerHelper.map_EmailToCase <> null) {
      this.mapCases = SER_Case_TriggerHelper.map_EmailToCase;
    }
    this.mapIdAddress = new Map<Id,String>();
    this.mapCasesToUpdate = new Map<Id,Case>();
    this.mapQueues = new Map<String,Id>();
    this.mapCSAddress = new Map<String,String>();
    this.mapConfigurations = new Map<String,SER_EmailDefaultValues_Assignment__c>();
    this.mapCaseFromEmail = new Map<Id,String>();
    for(SER_EmailDefaultValues_Assignment__c config : SER_EmailDefaultValues_Assignment__c.getAll().values()) {
      this.mapCSAddress.put(config.SER_FromAddres__c.toLowerCase(),config.SER_OutboundMailbox__c); //NOSONAR
      this.mapCSAddress.put(config.SER_OutboundFromAddress__c.toLowerCase(),config.SER_OutboundMailbox__c); //NOSONAR
      this.mapConfigurations.put(config.SER_FromAddres__c.toLowerCase(), config); //NOSONAR
      this.mapConfigurations.put(config.SER_OutboundFromAddress__c.toLowerCase(), config); //NOSONAR
      this.mapQueues.put(config.SER_Queue__c,null);
    }
  }
  /*@Author : Juan Carlos Terrón Ruiz
    @Método : procesameinto de todos los casos relacionados a los emails*/
  public Map<Id,Case> processCases() {
    for(EmailMessage email : this.mapEmails.values()) {
      final Id parentId = email.ParentId;
      final Boolean validParentId = parentId != null && String.valueOf(parentId).startswith('500') && SER_Case_TriggerHelper.map_EmailToCase.containsKey(parentId);
      if(validParentId) {
        final String defaultMailbox = this.getDefaultMailbox(parentId);
        final Boolean reassigned = this.processAddresses(defaultMailbox,email);
        this.fillUpdateMap(reassigned,email);
      }
      mapCaseFromEmail.put(email.ParentId,email.FromAddress);
    }
    if(this.mapCasesToUpdate.isEmpty() == false) {
      this.getQueues();
      for(Case caso : this.mapCasesToUpdate.values()) {
        this.setCaseFields(caso);
      }
    }
    System.debug(this.mapCasesToUpdate);
    return this.mapCasesToUpdate;
  }
  /*@Author : Juan Carlos Terrón Ruiz
    @Método : extraer las colas relacionadas con los sutom settings*/
  public void getQueues() {
    Map<String,Id> mapQueues;
    if(this.mapQueues.isEmpty()) {
      mapQueues = new Map<String,Id>();
    } else {
      mapQueues = new Map<String,Id>();
      for(Group grupo : [select Id,DeveloperName from Group where DeveloperName in :this.mapQueues.keyset()]) {
        mapQueues.put(grupo.DeveloperName, grupo.Id);
      }
    }
    this.mapQueues = mapQueues;
  }
  /*@Author : Juan Carlos Terrón Ruiz
    @Método : Obtener el default mailbox que aplica según el bussines type*/
  public String getDefaultMailbox(Id parentId) {
    String result;
    if(this.mapCases.containskey(parentId)) {
      final Case caso = mapCases.get(parentId);
      if(String.isNotBlank(String.valueOf(caso.SER_Business_Case_Type__c))) {
        final String btype = caso.SER_Business_Case_Type__c;
        if(btype.equalsignorecase('GM')) {
          result = Label.SER_CustomerServiceMailbox;
        }
      } else {
        result = '';
      }
    } else {
      result = '';
    }
    return result;
  }
  /*@Author : Juan Carlos Terrón Ruiz
    @Método : Rellenar el mapa de update según se haya hecho un reasigamiento a default o no*/
  public void fillUpdateMap(Boolean reassigned,EmailMessage email) {
    Case caso;
    if(reassigned == null) {
      caso = new Case(Id = email.ParentId, SER_ReassignedToCustomerSupport__c = true, SER_CCAddresses__c = email.CcAddress, SER_ToAddresses__c = email.toAddress);
      this.mapCasesToUpdate.put(email.ParentId,caso);
    } else if(reassigned) {
      caso = new Case(Id = email.ParentId, SER_ReassignedToCustomerSupport__c = true, SER_CCAddresses__c = email.CcAddress, SER_ToAddresses__c = email.toAddress);
      this.mapCasesToUpdate.put(email.ParentId,caso);
    } else {
      caso = new Case(Id = email.ParentId);
      this.mapCasesToUpdate.put(email.ParentId,caso);
    }
  }
  /*@Author : Juan Carlos Terrón Ruiz
    @Método : procesamiento de la casuística según los campos de dirección en el to y luego CC*/
  public Boolean processAddresses(String defaultemail, EmailMessage email) {
    Boolean result;
    result = true;
    final List<String> toAddresses = new List<String>(SER_EmailMessageMethods.customSplit(email.toAddress,';'));
    final Boolean exceptions = this.definedExceptions(email);
    if(exceptions == false) {
      if(toAddresses.isempty() == false) {
        final List<String> definedToAddresses = this.getDefAddresses(toAddresses);
        final Integer numToAddress = definedToAddresses.size();
        switch on numToAddress {
          when 0 {
            this.processCCAddresses(defaultemail,email);
          }
          when 1 {
            this.mapIdAddress.put(email.ParentId,definedToAddresses[0]);
            result = false;
          }
          when else {
            this.mapIdAddress.put(email.ParentId,defaultemail);
          }
        }
      } else {
        final List<String> ccAddresses = new List<String>(SER_EmailMessageMethods.customSplit(email.ccAddress,';'));
        if(ccAddresses.isempty() == false) {
          result =  this.processCCAddresses(defaultemail,email);
        } else {
          this.mapIdAddress.put(email.ParentId,defaultemail);
        }
      }
    } else {
      result = false;
    }
    return result;
  }
  /*@Author : Juan Carlos Terrón Ruiz
    @Método : procesamiento de la casuística según los campos de dirección en el cc*/
  public Boolean processCCAddresses(String defaultemail,EmailMessage email) {
    Boolean result;
    result = true;
    final List<String> definedCCAddresses = this.getDefAddresses(SER_EmailMessageMethods.customSplit(email.CcAddress,';'));
    switch on definedCCAddresses.size() {
      when 0 {
        this.mapIdAddress.put(email.ParentId,defaultemail);
      }
      when 1 {
        this.mapIdAddress.put(email.ParentId,definedCCAddresses[0]);
        result = false;
      }
      when else {
        this.mapIdAddress.put(email.ParentId,defaultemail);
      }
    }
    return result;
  }
  /*@Author : Juan Carlos Terrón Ruiz
    @Método : Extraer cuántas direcciones definidas hay en la lista de direcciones dadas*/
  public List<String> getDefAddresses(List<String> addresses) {
    List<String> defined; defined = new List<String>();
    for(String address : addresses) {
      if(this.mapCSAddress.containsKey(address)) {
        defined.add(address);
      }
    }
    return defined;
  }
  /*@Author : Juan Carlos Terrón Ruiz
    @Método : aplicar los valores del customs etting correspondiente a los campos del caso*/
  public void setCaseFields(Case caso) {
    final String emailAddress = mapIdAddress.get(caso.Id);
    if(this.mapConfigurations.containskey(emailAddress)) {
      final SER_EmailDefaultValues_Assignment__c config = this.mapConfigurations.get(emailAddress);
      final String queueName = config.SER_Queue__c;
      final String mailingGroup = config.SER_MailingGroup__c;
      final String emailOutbox = config.SER_OutboundMailbox__c;
      Boolean definedQueue;
      definedQueue = String.isNotBlank(queueName) && this.mapQueues.containskey(queueName);
      if(definedQueue) {
        final String queueId = this.mapQueues.get(queueName);
        if(String.isNotBlank(queueId)) {
          Case casoInfo;
          casoInfo = [Select Id,Origin,SER_EmailToCaseCode__c,Recordtype.DeveloperName FROM Case WHERE Id = :caso.Id];
          if(casoInfo.origin.equalsignorecase('Email GTB')) {
            SER_CaseMethodsGTB.assigGtbOwners(casoInfo,caso,queueId,mapCaseFromEmail);
          } else {
            caso.OwnerId = queueId;
          }
          Boolean definedE2C;
          definedE2C = String.isNotBlank(mailingGroup) && String.isNotBlank(emailOutbox);
          if(definedE2C) {
            caso.SER_MailingGroup__c = mailingGroup;
            caso.SER_Outbound_Mailbox__c = emailOutbox;
            caso.origin = emailOutbox;
            caso.SER_Skip_validations__c = true;
          }
        }
      }
    } else {
      this.mapCasesToUpdate.remove(caso.Id);
    }
  }
  /*@Author : Juan Carlos Terrón Ruiz
    @Método : Extraer cuántas direcciones definidas hay en la lista de direcciones dadas*/
  public static List<String> getDefinedAddresses(List<String> addresses) {
    Map<String,String> mapCSAddress; mapCSAddress = new Map<String,String>();
    for(SER_EmailDefaultValues_Assignment__c config : SER_EmailDefaultValues_Assignment__c.getAll().values()) {
      mapCSAddress.put(config.SER_FromAddres__c.toLowerCase(),config.SER_OutboundMailbox__c);  //NOSONAR
      mapCSAddress.put(config.SER_OutboundFromAddress__c.toLowerCase(),config.SER_OutboundMailbox__c);  //NOSONAR
    }
    List<String> defined; defined = new List<String>();
    for(String address : addresses) {
      if(mapCSAddress.containsKey(address)) {
        defined.add(address);
      }
    }
    return defined;
  }
  /*@Author : Juan Carlos Terrón Ruiz
    @Método : procesar en primer lugar las excepciones dadas*/
  public Boolean definedExceptions(EmailMessage email) {
    /*Middle afirmations exception*/
    Boolean result;
    result = false;
    final SER_EmailDefaultValues_Assignment__c middleConfig = SER_EmailDefaultValues_Assignment__c.getInstance('Email Middle Affirmations');
    if(middleConfig != null) {
      final String middleFA = middleConfig.SER_FromAddres__c;
      final String middleOFA = middleConfig.SER_OutboundFromAddress__c;
      final List<String> addresses = new List<String>();
      addresses.addall(SER_EmailMessageMethods.customSplit(email.toAddress,';'));
      addresses.addall(SER_EmailMessageMethods.customSplit(email.ccAddress,';'));
      if((String.isNotBlank(middleFA) && addresses.contains(middleFA)) || (String.isNotBlank(middleOFA) && addresses.contains(middleOFA))) {
        if(this.mapCSAddress.containskey(middleFA)) {
          result = true;
          this.mapIdAddress.put(email.ParentId,middleFA);
        } else if(this.mapCSAddress.containskey(middleOFA)) {
          result = true;
          this.mapIdAddress.put(email.ParentId,middleOFA);
        }
      }
    }
    return result;
  }
}