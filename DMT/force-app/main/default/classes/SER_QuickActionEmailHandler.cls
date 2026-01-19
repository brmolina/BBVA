/*-----------------------------------------------------------------------------------------
* @author       Accenture
* @date			01/03/2016
* @description  Manejador para la quickAction de email en el caso
* @Revision    2018/12/19 SONAR
*-----------------------------------------------------------------------------------------*/
global without sharing class SER_QuickActionEmailHandler implements QuickAction.QuickActionDefaultsHandler {

  /*----------------------------------------------------------------------------------------
  * @author       Accenture
  * @date			01/03/2016
  * @description       // The main interface method
                  IN		QuickActionDefaults
  * @Revision  2018/12/19 SONAR
  *-----------------------------------------------------------------------------------------*/
  global void onInitDefaults(QuickAction.QuickActionDefaults[] defaults) {

    final QuickAction.SendEmailQuickActionDefaults emailDefaults = calcDefaults(defaults);
    if (emailDefaults != null) {
      Id idReplyId = null;
      idReplyId = emailDefaults.getInReplyToId();
      final EmailMessage emailMessage = (EmailMessage) emailDefaults.getTargetSObject();
      final Case caso = [SELECT Id, CaseNumber,Origin,SER_Outbound_Mailbox__c,SER_Business_Case_Type__c,
                          (select Id, FromAddress,ToAddress,CcAddress from EmailMessages where Incoming = true order by CreatedDate desc )
                          FROM Case
                          WHERE Id=:emailDefaults.getContextId()];

      final Map<String,SER_EmailDefaultValues_Assignment__c> mpEmailDef = new Map<String,SER_EmailDefaultValues_Assignment__c>();                  //map_EmailDefaults
      final Map<String,SER_EmailDefaultValues_Assignment__c> mpEmailDefVal = SER_EmailDefaultValues_Assignment__c.getAll();                  //map_EmailDefaultValues

      final Map<String,String> mpTmpltAssig   = new Map<String,String>();                   //map_TemplateAssignment
      for(SER_EmailDefaultValues_Assignment__c csrItem : mpEmailDefVal.values()) {
        mpEmailDef.put(csrItem.SER_OutboundMailbox__c, csrItem);
        mpTmpltAssig.put(csrItem.SER_OutboundMailbox__c, csrItem.SER_TemplateDeveloperName__c);
      }

      final Map<String,EmailTemplate> mpEmailTmplt = calcMapEmailTemplate (mpTmpltAssig);                  //map_EmailTemplates

      System.debug('JCT - Mapa de Templates : '+mpEmailTmplt.keySet());
      final boolean asignarDefVal = caso != null
                                    && !mpEmailTmplt.isEmpty()
                                    && !mpEmailDef.isEmpty()
                                    && mpEmailDef.containsKey(caso.SER_Outbound_Mailbox__c)
                                    && String.isNotBlank(mpEmailDef.get(caso.SER_Outbound_Mailbox__c).SER_OutboundFromAddress__c);

      if(asignarDefVal) {
        final SER_EmailDefaultValues_Assignment__c csr = mpEmailDef.get(caso.SER_Outbound_Mailbox__c);
        emailMessage.FromAddress = csr.SER_OutboundFromAddress__c.toLowerCase('en US');
      }
      final boolean blCasoConMail = !caso.EmailMessages.isEmpty() && caso.EmailMessages.size() == 1;
      if(blCasoConMail && idReplyId == null) {
        final EmailMessage eMsg = caso.EmailMessages[0];
        List<String> lstFromAddrs = new List<String>();
        lstFromAddrs = SER_EmailMessageMethods.customSplit(eMsg.FromAddress,';');
        List<String> lstToAddrs = new List<String>();
        lstToAddrs = SER_EmailMessageMethods.customSplit(eMsg.ToAddress,';');
        List<String> lstCCAddrs = new List<String>();
        lstCCAddrs = SER_EmailMessageMethods.customSplit(eMsg.CcAddress,';');
        final Set<String> stToAddr = new Set<String>(lstToAddrs);                        //st_toaddresses
        System.debug('JCT - fromaddress : '+emailMessage.fromAddress);
        System.debug('JCT - toaddress : '+stToAddr);
        stToAddr.remove(emailMessage.FromAddress);
        lstToAddrs = new List<String>(stToAddr);
        System.debug('JCT - toaddress NEXT : '+stToAddr);
        lstToAddrs.addAll(lstFromAddrs);
        System.debug('JCT - lstCCAddrs : '+lstCCAddrs);
        System.debug('JCT - lstCCAddrs : NEXT'+String.join(lstCCAddrs, ';'));
        emailMessage.ToAddress = String.join(lstToAddrs, ';');
        emailMessage.CcAddress = String.join(lstCCAddrs, ';');
      }

      if((caso.Origin == 'BOSS' || caso.Origin == 'WEB_FORM')
          && !emailMessage.Subject.contains(' - Caso ')) {
        emailMessage.Subject = emailMessage.Subject  + ' - Caso ' + caso.CaseNumber;
      }
    }
  }

  private static QuickAction.SendEmailQuickActionDefaults calcDefaults (QuickAction.QuickActionDefaults[] defaults) {
    QuickAction.SendEmailQuickActionDefaults salida = null;

    for(QuickAction.QuickActionDefaults qAdItem : defaults) {
      if(qAdItem instanceof QuickAction.SendEmailQuickActionDefaults
          && qAdItem.getTargetSObject().getSObjectType() == EmailMessage.sObjectType
          && (
            (qAdItem.getActionName().equals('Case.Email') && qAdItem.getActionType().equals('Email'))
            || (qAdItem.getActionName().equals('Case.SendEmail') && qAdItem.getActionType().equals('SendEmail'))
            )) {

        salida = (QuickAction.SendEmailQuickActionDefaults) qAdItem;
        break;
      }
    }
    return salida;
  }

  private static Map<String,EmailTemplate> calcMapEmailTemplate (Map<String,String> pmTmplAssig) {
    final Map<String,EmailTemplate> salida = new Map<String,EmailTemplate>();            //map_EmailTemplates

    System.debug('JCT - Mapa de CS : '+pmTmplAssig);
    for(EmailTemplate etItem : [SELECT Id, DeveloperName FROM EmailTemplate WHERE DeveloperName IN :pmTmplAssig.values() limit 1])  {
      salida.put(etItem.DeveloperName, etItem);
    }

    return salida;
  }
}