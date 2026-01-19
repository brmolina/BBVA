/*---------------------------------------------------------------------------------------------------
    Author:        Julio Liarte
    Company:       Accenture
    Description:   Class to get all emails related to a case.

    History:
    <Date>          <Author>                <Description>
    13/04/2018		Julio Liarte		Initial Version
----------------------------------------------------------------------------------------------------*/
public with sharing class SER_CaseWithAllEmail {
  /*comes from assignTo on component*/
  public ID csId {get; set;}

  /*Class Constructor*/
  public SER_CaseWithAllEmail() {
  }

  /*Class constructor with controller */
  public SER_CaseWithAllEmail (ApexPages.StandardController pCurrentCase) {
    final Case currentCase = (Case)pCurrentCase.getRecord();
    System.debug ('Current Case:' + currentCase);
  }

  /*---------------------------------------------------------------------------------------------------
      Author:        Juan Carlos Terrón
      Company:       Accenture
      Description:   Method to get all mails associated to a Case.

      History:
      <Date>          <Author>                <Description>
      16/03/1993		Juan Carlos Terrón		Initial Version
  ----------------------------------------------------------------------------------------------------*/
  public List<EmailMessage> getSortEmails() {

    return this.csId == null
            ? new List<EmailMessage>() // handles UI preview use case
            : [SELECT Id, FromAddress, ToAddress, BCCAddress, CcAddress, MessageDate, Subject, Incoming, TextBody, HtmlBody, CreatedBy.Name
              from EmailMessage where ParentId =: this.csId order by MessageDate DESC];
  }

}