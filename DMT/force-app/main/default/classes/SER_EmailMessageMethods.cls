/*
    Author:        Juan Carlos Terrón
    Company:       Accenture Cloud First
    Description:   Clase para gestionar los correos y sus casos de email-to-case

    History:

    <Date>              <Author>                <Change Description>
    ??/06/2017          Juan Carlos Terrón          Initial Version.
    01/09/2017          Brian Capilla               Corregidos varios errores en validate_Addresses que evitaban la correcta distribución entre buzones.
    06/09/2017          Brian Capilla               Corregido un error que provocaba la llegada de casos ya borrados del metodo 
                                                    checker_duplicatedEmailToCase, al validate_Addresses.
    07/09/2017          Brian Capilla               Englobados los metodos con captura de errores para mayor control sobre estos.
    07/04/2022          Miriam Simón                Validación de ToAddress y CcAddress desde un buzón STE.
*/
public with sharing class SER_EmailMessageMethods {
  /*Constante LOCALE*/
  public static final String LOCALE = 'es_ES';
  /*Constructor*/
  private SER_EmailMessageMethods() {

  }

/*  Author:        Juan Carlos Terrón
    Company:       Accenture
    Description:   Method to assign the cases to the correct owner and some of its field when they're created by email to case

    IN:            map<Id,EmailMessage>(Trigger)
    OUT:           void

    History:
    <Date>                  <Author>                <Change Description>
    08/07/2017              Juan Carlos Terrón      Initial version */
  public static void assigner_RelatedCaseOwner(Map<Id,EmailMessage> newMap) {
    try {
      Map<Id,Case> mapToUpdate;
      SER_TriggerHelper.set_MetodFired('assigner_RelatedCaseOwner', true);
      SER_E2C_CaseRedirect redirectEngine = new SER_E2C_CaseRedirect(newMap);
      mapToUpdate = redirectEngine.processCases();
      if(mapToUpdate.isempty() == false) {
        update mapToUpdate.values();
      }
    } catch (Exception error) {
      final CIB_Log__c log = new CIB_Log__c();
      log.CIB_ErrorMessage__c = error.getStackTraceString()+'\n'+error.getMessage();
      log.CIB_Subject__c = 'SER_EmailMessageMethods.assigner_RelatedCaseOwner() ERROR';
      insert log;
    }
  }

  /*
      Author:        Juan Carlos Terrón
      Company:       Accenture
      Description:   method to prevent the creation of duplicated email to case cases due to multiaddress emails.

      IN:            map<Id,EmailMessage>(Trigger)
      OUT:           map<Id,EmailMessage>

      History:
      <Date>                  <Author>                <Change Description>
      08/07/2017              Juan Carlos Terrón      Initial version */
  public static Map<Id,EmailMessage> checker_duplicatedEmailToCase(Map<Id,EmailMessage> newMap) {
    Map<Id, EmailMessage> newMapCopy;
    try {
      newMapCopy = new Map<id, EmailMessage>(newMap);
      SER_E2C_ProcessDuplicity duplicityChecker = new SER_E2C_ProcessDuplicity(newMap);
      newMapCopy = duplicityChecker.processDuplicity();
    } catch (Exception error) {
      final CIB_Log__c log = new CIB_Log__c();
      log.CIB_ErrorMessage__c = error.getStackTraceString()+'\n'+error.getMessage();
      log.CIB_Subject__c = 'SER_EmailMessageMethods.checker_duplicatedEmailToCase() ERROR';
      insert log;
    }
    return newMapCopy;
  }
  /*
      Author:        Juan Carlos Terrón
      Company:       Accenture
      Description:   Method to generate email to case code before creation for email message records

      IN:            List<EmailMessage>(trigger)
      OUT:           void

      History:
      <Date>                  <Author>                <Change Description>
      08/07/2017              Juan Carlos Terrón      Initial version */
  public static void generate_UniqueCode(List<EmailMessage> news) {
    String subject,sender,reference;
    try {
      for(EmailMessage email : news) {
        subject = email.Subject;
        sender = email.FromAddress;
          
// Cambiamos la forma de recoger la referencia por el nuevo formato del Ref Id con ! en lugar de con _ //          
/*        if(String.isNotBlank(email.TextBody)) {       //Extract the case reference from the text body if possible
          reference = email.TextBody.substringBetween('ref:_',':ref');
        } else if(String.isNotBlank(email.HtmlBody)) {       //Extract the case reference from the htmlbody
          reference = email.HtmlBody.substringBetween('ref:_',':ref');
        }
*/
        if(String.isNotBlank(email.TextBody)) {       //Extract the case reference from the text body if possible
          reference = email.TextBody.substringBetween('ref:_',':ref');
          if(string.isblank(reference)) {
            reference = email.TextBody.substringBetween('ref:!',':ref');
          }
          system.debug('reference: '+reference);
        } else if(String.isNotBlank(email.HtmlBody)) {       //Extract the case reference from the htmlbody
          reference = email.HtmlBody.substringBetween('ref:_',':ref');
          if(string.isblank(reference)) {
            reference = email.HtmlBody.substringBetween('ref:!',':ref');
          }
        }
          
        //Use the the field processed to generate the code transforming it to a MD5 code.
        email.SER_UniqueCode__c = EncodingUtil.base64Encode(Crypto.generateDigest('MD5', Blob.valueOf(sender+subject+reference)));
      }
    } catch(Exception error) {
      final CIB_Log__c log = new CIB_Log__c();
      log.CIB_ErrorMessage__c = error.getStackTraceString()+'\n'+error.getMessage();
      log.CIB_Subject__c = 'SER_EmailMessageMethods.generate_UniqueCode() ERROR';
      insert log;
    }
  }

  /*--------------------------------------------------------------------------------------------------------------------------
      Author:        Juan Carlos Terrón
      Company:       Accenture
      Description:   Method to properly split the address fields of an incoming email message.

      IN:            String(Address field), String(split key)
      OUT:           list<String>

      History:
      <Date>                  <Author>                <Change Description>
      08/07/2017              Juan Carlos Terrón      Initial version
  ----------------------------------------------------------------------------------------------------------------------------*/
  public static List<String> customSplit(String toSplit, String splitKey) {
    final List<String> result = new List<String>();
    if(String.isNotBlank(toSplit) && toSplit.contains(splitKey)) {  //the string is not null and contains the split key
      for(String word : toSplit.split(splitKey)) {    //We add every splitted string to the returned list.
        result.add(word.trim().toLowerCase());
      }
    } else if(String.isNotBlank(toSplit)) {     //The string si not null but does not contains the split key
      result.add(toSplit);
    }
    return result;
  }

/*---------------------------------------------------------------------------------------------------------------------------
      Author:        Juan Carlos Terrón
      Company:       Accenture
      Description:   Method to cleaner_MasterCaseNotifications.

      IN:            Map<Id,EmailMessage>
      OUT:           void

      History:
      <Date>                  <Author>                <Change Description>
      08/07/2017              Juan Carlos Terrón      Initial version
  -------------------------------------------------------------------------------------------------------------------------*/
  public static void cleaner_MasterCaseNotifications(Map<Id,EmailMessage> news) {
    if( SER_TriggerHelper.get_MethodFired('send_ChildCasesEmail_UPDATE_PRESENDING') || SER_TriggerHelper.get_MethodFired('send_ChildCasesEmail_INSERT_PRESENDING')) {
      try {
        final List<EmailMessage> listToDelete = new List<EmailMessage>();
        for(EmailMessage email : news.values()) {
          if(SER_Case_TriggerHelper.map_NotifiedMasterCases.containsKey(email.ParentId)) {
            listToDelete.add(new EmailMessage(Id = email.Id));
          }
        }
        if(listToDelete.isEmpty() == false) {
          delete listToDelete;
        }
      } catch(Exception error) {
        final CIB_Log__c log = new CIB_Log__c();
        log.CIB_ErrorMessage__c = error.getStackTraceString()+'\n'+error.getMessage();
        log.CIB_Subject__c = 'SER_EmailMessageMethods.validate_Addresses() ERROR';
        insert log;
      }
    }
  }
  /*----------------------------------------------------------------------------------------------------------------------
      Author:        Juan Carlos Terrón
      Company:       Accenture
      Description:   Method to validate outgoing emails

      IN:            List<EmailMessage>
      OUT:           void

      History:
      <Date>                  <Author>                <Change Description>
      30/01/2018              Juan Carlos Terrón      Initial version
  ------------------------------------------------------------------------------------------------------------------------*/
  public static void validateFromAddress(List<EmailMessage> news) {
    try {
      SER_ValidateFromAddress validation = new SER_ValidateFromAddress(news);
      validation.validateFromAddresses(news);
    } catch (Exception error) {
      final CIB_Log__c log = new CIB_Log__c();
      log.CIB_Subject__c = 'SER_EmailMessageMethods.validateFromAddress ERROR';
      log.CIB_ErrorMessage__c = 'Error Message : '+error.getMessage()+'\nStackTrace : '+error.getStackTraceString();
      insert log;
    }

  }

  /*------------------------------------------------------------------------------------------------------------------
      Author:        Juan Carlos Terrón
      Company:       Accenture
      Description:   Método para evitar fallos al copiar direcciones demasiado largas en lso campos del caso
          SER_CCAddresses y SER_TOAddressses al procesar email-to-case que necesiten ser redirigidos.

      IN:            Trigger.New
      OUT:           void

      History:
      <Date>                  <Author>                <Change Description>
      16/05/2018        Juan Carlos Terrón    Initial Version
  ---------------------------------------------------------------------------------------------------------------------*/
  public static void UpdateAddress(List<EmailMessage> emails) {
    Set<Id> setCaseId;
    setCaseId = SER_E2C_FormatAddressFields.checkAddressesLength(emails);
    if(setCaseId.isEmpty() == false) {
      for(Case c : [select Id, SER_CCAddresses__c, SER_ToAddresses__c from Case where id in :setCaseId]) {
        if(String.isBlank(c.SER_ToAddresses__c) && String.isBlank(c.SER_CCAddresses__c)) {
          setCaseId.remove(c.Id);
        }
      }
      if(setCaseId.isEmpty() == false) {
        List<Case> listToUpdate;
        listToUpdate = new List<Case>();
        for(EmailMessage email : emails) {
          final Boolean condition = ((email.ToAddress != null && String.valueOf(email.ToAddress).length()>40) || (email.CcAddress != null && String.valueOf(email.CcAddress).length()>40)) && email.Incoming && setCaseId.contains(email.ParentId) && String.valueOf(email.ParentId).startswith('500');
          if(condition) { //Procesas con el metodo auxiliar pasandole email como parámetro y el set de definidas.
            final SER_E2C_FormatAddressFields formatter = new SER_E2C_FormatAddressFields(email);
            final Map<String,String> mapAddressFields = formatter.processEmailAddresses();
            final String ccAddress = mapAddressFields.get('CC');
            final String toAddress = mapAddressFields.get('TO');
            listToUpdate.add(new Case(Id = email.ParentId, SER_CCAddresses__c = ccAddress, SER_ToAddresses__c = toAddress));
          }
        }
        if(listToUpdate.isEmpty() == false) {
          update listToUpdate;
        }
      }
    }
  }
}