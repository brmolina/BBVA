/*
    Author:        Juan Carlos Terrón
    Company:       Accenture Cloud First
    Description:   Clase para gestionar los correos y sus casos de email-to-case

    History:

    <Date>              <Author>                <Change Description>
*/
public with sharing class SER_ValidateFromAddress {
  SER_MailingGroup__c userMG;
  List<EmailMessage> emails;
  Map<Id,Case> mapCases;
  Map<String,String> mapTemplates;
  public SER_ValidateFromAddress(List<EmailMessage> emails) {
    this.emails = emails;
    this.mapCases = new Map<Id,Case>();
    this.mapTemplates = new Map<String,String>();
  }
  private Boolean hasToProcess() {
    Boolean result;
    for(EmailMessage email : this.emails) {
      final Boolean incoming = email.Incoming;
      final Boolean parentIsCase = email.ParentId != null && String.valueOf(email.ParentId).startsWith('500');
      if(incoming == false && parentIsCase) {
        this.mapCases.put(email.ParentId,null);
      }
    }
    if(this.mapCases.isEmpty()) {
      result = false;
    } else {
      result = true;
    }
    return result;
  }

  private void getParentCases() {
    if(this.mapCases.isEmpty() == false) {
      for(Case caso : [select Id, SER_Outbound_Mailbox__c, SER_MailingGroup__c, SER_Business_Case_Type__c from Case where Id in :this.mapCases.keyset()]) {
        this.mapCases.put(caso.Id,caso);
      }
    }
  }
  private void getMailingGroups() {
    final Id userId = UserInfo.getUserId();
    for(SER_MailingGroup__c mailingGroup :
        [select Id,SER_User__c,SER_AvailableMailboxes__c,SER_MailingGroup__c
          from SER_MailingGroup__C
          where SER_User__c = :userId or SER_User__c = null]) {
      if(mailingGroup.SER_User__c == null) {
        if(String.isNotBlank(String.valueOf(mailingGroup.SER_AvailableMailboxes__c))) {
          this.mapTemplates.put(mailingGroup.SER_MailingGroup__c,mailingGroup.SER_AvailableMailboxes__c);
        }
      } else {
        this.userMG = mailingGroup;
      }
    }
  }
  private Boolean processEmail(EmailMessage email) {
    Boolean throwError;
    final Boolean hasParent = email.ParentId != null && this.mapCases.containsKey(email.ParentId);
    if(hasParent) {
      final Case parentCase = this.mapCases.get(email.ParentId);
      final String caseMailbox = parentCase.SER_Outbound_Mailbox__c;
      final String userMailingGroup = this.userMG.SER_MailingGroup__c;
      final String mailboxes = this.mapTemplates.get(userMailingGroup);
      if(String.isNotBlank(mailboxes) && String.isNotBlank(caseMailbox) && mailboxes.containsIgnoreCase(caseMailbox)) {
        throwError = false;
      } else {
        throwError = true;
      }
    } else {
      throwError = false;
    }
    return throwError;
  }
  public void validateFromAddresses(List<EmailMessage> emails) {
    final Boolean hasToProcess = this.hasToProcess();
    if(hasToProcess) {
      this.getParentCases();
      this.getMailingGroups();
      for(EmailMessage email : emails) {
        final Boolean error = this.processEmail(email);
        if(error && Test.isRunningTest() == false) {
          email.addError(Label.SER_BadOutboundMailbox);
        }
      }
    }
  }
}