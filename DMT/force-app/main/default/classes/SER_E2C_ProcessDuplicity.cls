/*------------------------------------------------------------
    Author:        Juan Carlos Terrón
    Company:       Accenture
    Description:   Duplicated cases processes to check duplicity

    History:
    <Date>          <Author>                <Description>
    30/11/2018      Juan Carlos Terrón        Initial version
--------------------------------------------------------------*/
public with sharing class SER_E2C_ProcessDuplicity {
  /*Seems like its fixed*/
  /*Mapa de emails para procesar
  */
  Map<Id,EmailMessage> mapEmails;
  /*Mapa de direcciones definidas en el custom setting.
  */
  Map<String,String> mapAddresses;
  /*Valor único de lista de direcciones.
  */
  final static Integer ONE = 1;
  /*------------------------------------------------------------
      Author:        Juan Carlos Terrón
      Company:       Accenture
      Description:   Constructor

      History:
      <Date>          <Author>                <Description>
      30/11/2018      Juan Carlos Terrón        Initial version
  --------------------------------------------------------------*/
  public SER_E2C_ProcessDuplicity(Map<Id,EmailMessage> mapEmails) {
    if(mapEmails == null || mapEmails.isempty()) {
      this.mapEmails = new Map<Id,EmailMessage>();
    } else {
      this.mapEmails = mapEmails;
    }
  }
  /*------------------------------------------------------------
      Author:        Juan Carlos Terrón
      Company:       Accenture
      Description:   Main method to check duplicity.

      History:
      <Date>          <Author>                <Description>
      30/11/2018      Juan Carlos Terrón        Initial version
  --------------------------------------------------------------*/
  public Map<Id,EmailMessage> processDuplicity() {
    Map<Id,EmailMessage> result; result = new Map<Id,EmailMessage>();
    Map<Id,EmailMessage> mapThreads; mapThreads = new Map<Id,EmailMessage>();
    Map<Id,Case> mapDuplicates; mapDuplicates = new Map<Id,Case>();
    for(EmailMessage email : this.mapEmails.values()) {
      final Boolean isThread = email.Incoming && !(email.ParentId <> null && SER_Case_TriggerHelper.map_EmailToCase.containsKey(email.ParentId));
      final Boolean isE2C = email.Incoming && email.ParentId <> null && SER_Case_TriggerHelper.map_EmailToCase.containsKey(email.ParentId);
      if(isThread) {
        mapThreads.put(email.Id,email);
      } else if(isE2C) {
        final List<String> definedAddresses = this.calculateDefinedAddresses(email);
        result.put(email.Id,email);
        if(definedAddresses.size() > SER_E2C_ProcessDuplicity.ONE) {
          mapDuplicates.put(email.ParentId, SER_Case_TriggerHelper.map_EmailToCase.get(email.ParentId));
        }
      }
    }
    if(mapThreads.isEmpty() == false) {
      System.enqueueJob(new SER_E2C_DuplicatedThreadCleaner(mapThreads));
    }
    if(mapDuplicates.isEmpty() == false) {
      System.enqueueJob(new SER_E2CCLEANER(mapDuplicates));
    }
    return result;
  }
  /*
      Author:        Juan Carlos Terrón
      Company:       Accenture
      Description:   Método para calcular cuántas direcciONEs definidas hay en total.

      History:
      <Date>          <Author>                <Description>
      30/11/2018      Juan Carlos Terrón        Initial version */
  private List<String> calculateDefinedAddresses(EmailMessage email) {
    List<String> definedAddresses;
    if(String.isNotBlank(String.valueOf(email.ToAddress)) || String.isNotBlank(String.valueOf(email.CcAddress))) {
      definedAddresses = new List<String>();
      if(String.isNotBlank(String.valueOf(email.ToAddress))) {
        final List<String> toAddresses = SER_EmailMessageMethods.customSplit(email.ToAddress,';');
        definedAddresses.addAll(SER_E2C_CaseRedirect.getDefinedAddresses(toAddresses));
      }
      if(String.isNotBlank(String.valueOf(email.CcAddress))) {
        final List<String> ccAddresses = SER_EmailMessageMethods.customSplit(email.CcAddress,';');
        definedAddresses.addAll(SER_E2C_CaseRedirect.getDefinedAddresses(ccAddresses));
      }
    } else {
      definedAddresses = new List<String>();
    }
    return definedAddresses;
  }
}