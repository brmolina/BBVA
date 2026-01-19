/*-----------------------------------------------------------------------------------------
* @author       Accenture
* @date            01/03/2016
* @description  Manejador para la quickAction de email en el caso
* @Revision     2018/12/19 SONAR
*------------------------*/

@isTest
private class SER_QuickActionEmailHandler_TEST {

  static testmethod void testMethodOne() {
    Exception errOnExec = null;

    final Case myCase = new Case(Status='Status',
                                  Origin='BOSS',
                                  Reason = 'Reason',
                                  SER_Outbound_Mailbox__c ='Email GM',
                                  SER_Skip_validations__c = true
                                );
    insert myCase;

    final EmailMessage myMsg = new EmailMessage(ParentId = myCase.Id, TextBody = 'Cuerpo del email', Subject = 'Subject', FromName = 'jjj@jjj.com', Incoming = true);
    insert myMsg;

    final SER_EmailDefaultValues_Assignment__c emailDefault = new SER_EmailDefaultValues_Assignment__c(Name = 'Name',
                                                                                                        SER_OutboundMailbox__c = 'Email GM',
                                                                                                        SER_TemplateDeveloperName__c  = 'Firma_1_Derivatives_HTML',
                                                                                                        SER_FromAddres__c  = 'aa@example.com',
                                                                                                        SER_OutboundFromAddress__c  = 'aa@example.com');
    insert emailDefault;

    System.runAs(new User(Id = UserInfo.getUserId())) {
      final List<BrandTemplate> lstBrand = [SELECT Id FROM BrandTemplate LIMIT 1000];
      final List<Folder> lstFolder = [SELECT Id FROM Folder WHERE Type = 'Email' AND AccessType = 'Public'];

      final EmailTemplate emailTem = new EmailTemplate(Name = 'email',
                                                        DeveloperName = 'Firma_1_Derivatives_HTML',
                                                        TemplateType = 'html',
                                                        FolderId = lstFolder[0].Id, BrandTemplateId = lstBrand[0].Id,
                                                        TemplateStyle = 'freeForm',
                                                        Body = 'Estimado cliente, Se ha creado una incidencia maestra con la referencia {!Case.CaseNumber}',
                                                        Isactive = true,
                                                        Subject = 'Case # {!Case.CaseNumber}',
                                                        HtmlValue = '<table border="0" cellpadding="5" width="550" cellspacing="5" height="400" ></table>');
      insert emailTem;
    }



    final List<Map<String, Object> > defSettAsObj = new List<Map<String, Object> >();   //defaultSettingAsObject
    final Map<String, Object> stringObject = new Map<String, Object>();
    stringObject.put('targetSObject', myMsg);
    stringObject.put('ContextId', myCase.Id);
    stringObject.put('actionType', 'Email');
    stringObject.put('actionName', 'Case.Email');
    stringObject.put('fromAddressList', new List<String> {'salesforce@test.com'});
    defSettAsObj.add(stringObject);

    final List<QuickAction.SendEmailQuickActionDefaults> defaultsSettings =
      (List<QuickAction.SendEmailQuickActionDefaults>)JSON.deserialize(JSON.serialize(defSettAsObj), List<QuickAction.SendEmailQuickActionDefaults>.class);

    Test.startTest();
    try {
      (new SER_QuickActionEmailHandler()).onInitDefaults(defaultsSettings);
    } catch(Exception e) {
      errOnExec = e;
    }

    Test.stopTest();
    System.assertEquals(null, errOnExec, 'testMethodOne');
  }
}