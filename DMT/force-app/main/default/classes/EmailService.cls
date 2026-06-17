/*-------------------------------------------------------------------------------
Author:        Juan Carlos Terrón
Company:       Accenture
Description:   Method that generates Email Service for GM

History:
<Author>                  <Date>                <Change Description>
Juan Carlos Terrón                              Initial version.
Adrian Salinas (NFQ)     04/02/2026          Uso de Email_Service_Config__mdt para eliminacion de hardcode.
---------------------------------------------------------------------------------*/
global with sharing class EmailService implements Messaging.InboundEmailHandler {
  /*
    handleInboudEmail
  */
  global Messaging.InboundEmailResult handleInboundEmail(Messaging.InboundEmail email, Messaging.InboundEnvelope envelope) {
    Messaging.InboundEmailResult result;

    Email_Service_Config__mdt config = EmailServiceUtils.getConfig();
    if (config.isActive__c == false) {
        return result; 
    }
    try {
      //System.debug('REFERENCES : '+email.references);

      final CIB_Log__c log = new CIB_Log__c(); //LOG de proceso
      log.CIB_Subject__c = 'Email Service Cache testing'; //Assign log subject
      log.CIB_ErrorMessage__c = ''; // Initialize log body

      final InboundEmailWrapper currentEmail = new InboundEmailWrapper(email,envelope);//WRAPPER
      //System.debug('EmailService - handleInboundEmail - Cache Key : '+currentEmail.cacheKey);
      log.CIB_ErrorMessage__c += 'MESSAGEID FIELD : ' +currentEmail.email.messageId+'\nSubject :  : ' +currentEmail.email.Subject+'\nFrom : ' +currentEmail.email.fromAddress+'\n';

      final EmailService_EmailEngine emailEngine = new EmailService_EmailEngine(currentEmail);//EMAIL ENGINE
      final Boolean isThread = emailEngine.isThread();
      emailEngine.initialize();
      if(isThread) {
        final Id emailId = emailEngine.createEmail();
        result = new Messaging.InboundEmailresult();
      } else {
        Id caseId;
        final EmailService_CaseEngine caseEngine = new EmailService_CaseEngine(currentEmail);
        // final EmailServiceUtils engine = new EmailServiceUtils('local.EmailService',currentEmail,'GM');
        final EmailServiceUtils engine = new EmailServiceUtils(config.Partition_Name__c,currentEmail,config.Business_Unit_Code__c);
        final String preassignAddress = engine.preassignAddress(currentEmail);
        final Map<String,SER_EmailDefaultValues_Assignment__c> settings = engine.getMailboxSettings();
        final Set<String> defined = settings.keySet();
        currentEmail.countDefinedAddresses(defined);
        if(String.isNotBlank(preassignAddress)) {
          //System.debug('EmailService - handleInboundEmail - Hay Dirección pre-asignada : '+preassignAddress);
          final SER_EmailDefaultValues_Assignment__c setting = settings.get(preassignAddress);
          caseEngine.setting = setting;
        } else {
          final String assignedAddress = engine.assignAddress(Label.SER_CustomerServiceMailbox,currentEmail);
          final SER_EmailDefaultValues_Assignment__c setting = settings.get(assignedAddress);
          caseEngine.setting = setting;
        }
        caseId = caseEngine.createCase();
      //System.debug('EmailService - handleInboundEmail - Case ID creado : '+caseId);
      if(caseId != null) {
          // Cache.OrgPartition orgPartition =  Cache.Org.getPartition('local.EmailService'); //NOSONAR
          Cache.OrgPartition orgPartition =  Cache.Org.getPartition(config.Partition_Name__c); //NOSONAR
          //System.debug('EmailService GM - handleInboundEmail - emailId : '+emailId);
          log.CIB_ErrorMessage__c += 'CASE ID : '+caseId+'\nEMAIL ID : '+emailEngine.createEmail(caseId)+'\n';
          //final Boolean emailResult =  (emailId != null);
          final InboundEmailWrapper currentEmailCopy = currentEmail;
          currentEmailCopy.email = null; //NOSONAR
          // orgPartition.put(currentEmail.cacheKey,currentEmailCopy,300,Cache.Visibility.NAMESPACE,false);
          Integer ttl = (Integer)config.Cache_TTL__c;
          orgPartition.put(currentEmail.cacheKey,currentEmailCopy,ttl,Cache.Visibility.NAMESPACE,false);

        }
      }
      for(String header : currentEmail.headers.keySet()) {
          log.CIB_ErrorMessage__c += header + ' : ' +currentEmail.headers.get(header)+'\n';
      }
        insert log;
        result = new Messaging.InboundEmailresult();
    } catch (Cache.Org.OrgCacheException ex1) {
      EmailServiceUtils.insertCathCibLog (email,ex1);
      result = new Messaging.InboundEmailresult();
    } catch (Cache.InvalidParamException ex2) { //NOSONAR
      EmailServiceUtils.insertCathCibLog (email,ex2);
      result = new Messaging.InboundEmailresult();
    } catch (Exception error) { //NOSONAR
      System.debug('EmailService - Error Catch - Log Creation : '+EmailServiceUtils.generateLog(error,email,config.Business_Unit_Code__c));
      result = new Messaging.InboundEmailresult();
    }
    return result;
  }
 }