/**
* ------------------------------------------------------------------------------------------------
* @Name     PRW_SendBundleEmailBuilder
* @Author   Global Hub
* @Date     Created: 2022-07-07
* ------------------------------------------------------------------------------------------------
* @Description Send Email for pricewise
* ------------------------------------------------------------------------------------------------
* @Changes
*
* |2022-07-07 ivan.garces.contractor@bbva.com
*             Class Creation
* -----------------------------------------------------------------------------------------------
*/
@SuppressWarnings('sf:AvoidFinalLocalVariable, sf:LogicInversion, sf:DUDataflowAnomalyAnalysis, sf:NcssMethodCount, sf:NPathComplexity, sf:CyclomaticComplexity, sf:TooManyMethods')
global with sharing class PRW_SendBundleEmailBuilder implements Callable {

  /**
  * GLOBAL VARIABLE specialP
  */
  private static String specialP = 'p';
  /**
  * GLOBAL VARIABLE specialQ
  */
  private static String specialQ = 'q';
  /**
  * GLOBAL VARIABLE specialName
  */
  private static String specialName = 'bndleProductAdded';
  /**
  * GLOBAL VARIABLE bundleProd
  */
  private static String bundleProd = 'bundle';
  /**
  * GLOBAL VARIABLE special
  */
  private static String special = 'special';

  /**
  * GLOBAL VARIABLE bName
  */
  private static String bName = 'bundleName';

  /**
  * GLOBAL VARIABLE bProdN
  */
  private static String bProdN = 'bndleProduct';

  /**
  * GLOBAL VARIABLE bProdQ
  */
  private static String bProdQ = 'q';

  /**
  * GLOBAL VARIABLE bPrice
  */
  private static String bPrice = 'bundlePrice';

  /**
  * --------------------------------------------------------------------------------------
  * @Description - Method that return the content wrapper
  * --------------------------------------------------------------------------------------
  * @Author   Global Hub
  * @Date     Created: 2021-11-19
  * @param recordId - String with information necessary to send email
  * @return tmpb.TemplateBuilder.TemplateBuilderContent - Wrapper
  * --------------------------------------------------------------------------------------
  **/
  tmpb.TemplateBuilder.TemplateBuilderContent getContent(String recordId) {
    //Selectable Content
    final tmpb.TemplateBuilder.TemplateBuilderContent content = new tmpb.TemplateBuilder.TemplateBuilderContent();
    content.id = 'Content';
    content.name = 'Sample result content elements';
    content.categories = new List<tmpb.TemplateBuilder.TemplateBuilderContentCategory>();

    //Signature blocks
    final tmpb.TemplateBuilder.TemplateBuilderContentCategory signatureBlock = new  tmpb.TemplateBuilder.TemplateBuilderContentCategory();
    signatureBlock.id = 'sigblock';
    signatureBlock.title = 'Owner Signature';
    signatureBlock.description = 'Please select whether you want to include the signature in the email';
    signatureBlock.items = new List<tmpb.TemplateBuilder.TemplateBuilderContentItem>();


    final User userOwner = gtOwnUser().get(0);

    final tmpb.TemplateBuilder.TemplateBuilderContentItem member = new tmpb.TemplateBuilder.TemplateBuilderContentItem();
    member.id = userOwner.id;
    member.title = userOwner.Name;
    member.description = '';
    member.disabled = false;
    member.checked = true;
    signatureBlock.items.add(member);

    content.categories.add(signatureBlock);

    return content;
  }

  /**
  * --------------------------------------------------------------------------------------
  * @Description - Method that return the recipientd
  * --------------------------------------------------------------------------------------
  * @Author   Global Hub
  * @Date     Created: 2021-11-19
  * @param recordId - String with information necessary to send email
  * @return tmpb.TemplateBuilder.TemplateBuilderContent - Wrapper
  * --------------------------------------------------------------------------------------
  **/
  tmpb.TemplateBuilder.TemplateBuilderContent getRecipients(String recordId) {
    final tmpb.TemplateBuilder.TemplateBuilderContent recipients = new tmpb.TemplateBuilder.TemplateBuilderContent();
    recipients.id = 'PricewiseRecipients';
    recipients.name = 'Recipients  pricewise';
    recipients.categories = new List<tmpb.TemplateBuilder.TemplateBuilderContentCategory>();

    //User BBVA
    final tmpb.TemplateBuilder.TemplateBuilderContentCategory bbvaTeam = new  tmpb.TemplateBuilder.TemplateBuilderContentCategory();
    bbvaTeam.id = 'bbvauser';
    bbvaTeam.title = 'BBVA User';
    bbvaTeam.icon = 'standard:user';
    bbvaTeam.description = 'Please, select which BBVA User to send email to';
    bbvaTeam.items = new List<tmpb.TemplateBuilder.TemplateBuilderContentItem>();

    final List<User> bbvaMembers = gtOwnUser();

    for(User  m : bbvaMembers) {
      final tmpb.TemplateBuilder.TemplateBuilderContentItem member = new tmpb.TemplateBuilder.TemplateBuilderContentItem();
      member.id = m.id;
      member.title = m.Name;
      member.value = m.Email;
      member.description = 'to';
      member.disabled = true;
      member.checked = false;
      bbvaTeam.items.add(member);
    }
    recipients.categories.add(bbvaTeam);

    return recipients;
  }

  /**
  * --------------------------------------------------------------------------------------
  * @Description - Method that render content
  * --------------------------------------------------------------------------------------
  * @Author   Global Hub
  * @Date     Created: 2021-11-19
  * @param recordId - String with information necessary to send email
  * @param args - Content check
  * @return tmpb.TemplateBuilder.TemplateBuilderContent - Wrapper
  * --------------------------------------------------------------------------------------
  **/
  tmpb.TemplateBuilder.TemplateBuilderContent renderContent(String recordId, Object args) {
    final List<String> lJSON = recordId.split(':::::');
    final tmpb.TemplateBuilder.TemplateBuilderContent renderedContent = new tmpb.TemplateBuilder.TemplateBuilderContent();
    renderedContent.rendered = new List<tmpb.TemplateBuilder.TemplateBuilderRenderedElement>();
    tmpb.TemplateBuilder.TemplateBuilderArgs ids;
	final String sigblock = 'sigblock';
    
    try {
      ids = (tmpb.TemplateBuilder.TemplateBuilderArgs) System.JSON.deserialize((String)args, tmpb.TemplateBuilder.TemplateBuilderArgs.class);

      final List<String> sigBlockIds = new List<String>();
        
      for(String selected : ids.selectedIds ) {
        final List<String> pair = selected.split('-');
        if (pair[0] == sigblock) {
          sigBlockIds.add(pair[1]);
        }
      }

      //Sacamos el nombre del cliente
      String accName = ''; //NOSONAR
      if(!(lJSON.get(2) == null)) {
        final List<Account> lAcc = [SELECT id, Name FROM Account WHERE id = :lJSON.get(2)];
        accName = !lAcc.isEmpty() ? lAcc.get(0).name : ''; //NOSONAR
      }
      // Company Name
      final tmpb.TemplateBuilder.TemplateBuilderRenderedElement company = new tmpb.TemplateBuilder.TemplateBuilderRenderedElement();
      company.key = 'company_name';
      company.value = accName;
      renderedContent.rendered.add(company);
      //Sacamos las listas de productos
      String listObject ='';
      if(!(lJSON.get(1) == null)) {
        listObject = (String) JSON.deserializeUntyped(lJSON.get(1));
      }
      List<Map<String,String>> listBundles = new List<Map<String,String>>();
      if(!(lJSON.get(6) == null )) {
        listBundles = (List<Map<String,String>>) JSON.deserialize(lJSON.get(6), List<Map<String,String>>.class);
      }
      List<Map<String,String>> listSpecial = new List<Map<String,String>>();
      if(!(lJSON.get(7) == null )) {
        listSpecial = (List<Map<String,String>>) JSON.deserialize(lJSON.get(7), List<Map<String,String>>.class);
      }
      // Visit date to human readable
      //
      final tmpb.TemplateBuilder.TemplateBuilderRenderedElement datefmtd = renderComplete('date_today', null, null, null , listBundles);
      renderedContent.rendered.add(datefmtd);
      // Add bundle products selected
      final tmpb.TemplateBuilder.TemplateBuilderRenderedElement bundleElement = renderComplete(bundleProd, listObject,sigBlockIds,listSpecial , listBundles);
      renderedContent.rendered.add(bundleElement);
      
      final tmpb.TemplateBuilder.TemplateBuilderRenderedElement block = renderComplete('signatureBlock', listObject, sigBlockIds, null ,listBundles);
      renderedContent.rendered.add(block);

    } catch(Exception e) {
      final tmpb.TemplateBuilder.TemplateBuilderRenderedElement element = new tmpb.TemplateBuilder.TemplateBuilderRenderedElement();
      element.key ='error';
      element.value = e.getMessage();
      renderedContent.rendered.add(element);
    }

    return renderedContent;
  }

  /**
  * --------------------------------------------------------------------------------------
  * @Description - Method to complete render element
  * --------------------------------------------------------------------------------------
  * @Author   Global Hub
  * @Date     Created: 2021-11-22
  * --------------------------------------------------------------------------------------
  **/
  private tmpb.TemplateBuilder.TemplateBuilderRenderedElement renderComplete(String key,String bundlePrice, List<String> selected,List<Map<String,String>> listSpecial ,List<Map<String,String>> listBundleProds) {
    final tmpb.TemplateBuilder.TemplateBuilderRenderedElement element = new tmpb.TemplateBuilder.TemplateBuilderRenderedElement();
    element.key = key;
    final String datetod = 'date_today';
    final String signatureBlock = 'signatureBlock';
    if(key.contains(bundleProd)) {
      element.value = renderedBundle(bundlePrice, listBundleProds ,listSpecial);
    } else if(key == signatureBlock) {
      element.value = '';
      final List<User> owners = [SELECT Id, Name, Email, Phone, EMPLOYEE_DEPARTMENT_DESC__c, Extension FROM User WHERE Id IN :selected];
      for(User  member : owners) {
        element.value = element.value + '<div style="margin:20px 20px;padding:0px 0px;float:left;">';
        element.value = element.value + '<div style="font-size:12px;font-weight:bold;">' + member.Name + '</div>';
        element.value = element.value + '<div style="font-size:12px;">Phone: ' + member.Phone + '  (ext. ' + member.Extension + ')</div>';
        element.value = element.value + '<div style="font-size:12px;"><a href="mailto:' + member.Email + '">' + member.Email + '</a></div></div>';
      }
    } else if(key == datetod) {
      element.value = Datetime.now().format('MMMM') + ' ' + Datetime.now().format('dd') + ', ' + Datetime.now().format('yyyy');
    }
    return element;
  }

  /**
  * --------------------------------------------------------------------------------------
  * @Description - Method that render bundles
  * --------------------------------------------------------------------------------------
  * @Author   Global Hub
  * @Date     Created: 2022-07-08
  * --------------------------------------------------------------------------------------
  **/
  private String renderedBundle(String bundlePrice, List<Map<String,String>> bundleList ,List<Map<String,String>> specialList) {
    String res = '<div><table style="margin:10px;width: -webkit-fill-available;border-top: 0.5px solid  rgb(201, 201, 201);border-collapse: collapse;border-bottom: 0.5px solid  rgb(201, 201, 201)"><thead style="background-color:rgb(243, 243, 243);border-bottom: 0.5px solid  rgb(201, 201, 201);border-collapse: collapse;"><tr><th><p style="text-align: left;margin-left:10px"> Products Bundle</p></th><th><p  style="text-align: right;margin-right:20px"> Transactions</p></th></tr></thead><tbody>';
    for(Map<String,String> element : bundleList) {  
      res = res + '<tr style="border-bottom: 0.5px solid  rgb(201, 201, 201);border-collapse: collapse;"><td><div style="text-align: left;margin-left:10px;margin:5px">' + element.get(bProdN) + '</div></td>';
      res = res + '<td><div style="text-align: right;margin-right:20px">' + element.get(bProdQ) + '</div></td></tr>';
    }
    //added special products
    String specialPrice = '';
    String specialQuantity = '';
    if(specialList != null){
    res = res + '<div><table style="margin:10px;width: -webkit-fill-available;border-top: 0.5px solid  rgb(201, 201, 201);border-collapse: collapse;border-bottom: 0.5px solid  rgb(201, 201, 201)"><thead style="background-color:rgb(243, 243, 243);border-bottom: 0.5px solid  rgb(201, 201, 201);border-collapse: collapse;"><tr><th><p style="text-align: left;margin-left:10px"> Added Special Conditions</p></th><th><p  style="text-align: right;margin-right:20px"> Price</p></th><th><p  style="text-align: right;margin-right:20px"> Transactions</p></th></tr></thead><tbody>';
      for(Map<String,String> elementSpecial : specialList) {  
        specialPrice = elementSpecial.get(specialP) == '' ? '0 �' : elementSpecial.get(specialP);
        specialQuantity = elementSpecial.get(specialQ) == '' ? '0' : elementSpecial.get(specialQ);
        res = res + '<tr style="border-bottom: 0.5px solid  rgb(201, 201, 201);border-collapse: collapse;"><td><div style="text-align: left;margin-left:10px;margin:5px">' + elementSpecial.get(specialName) + '</div></td>';
        res = res + '<td><div style="text-align: right;margin-right:20px">' + specialPrice + '</div></td>';
        res = res + '<td><div style="text-align: right;margin-right:20px">' + specialQuantity + '</div></td></tr>';
      }
    }
    res = res + '</tbody></table><footer style="display:flex;justify-content: center;border-style: solid;border-color: rgb(201, 201, 201);border-width: thin;background-color:rgb(243, 243, 243);margin:15px;text-align: center;"><p> TOTAL ANNUAL PRICE: </p>';
    res = res + '<p style="font-weight: bold;margin-left: 10px;">' + bundlePrice + '</p></footer></div></article>';
    return res;
  }

  /**
  * --------------------------------------------------------------------------------------
  * @Description - Method that gets current User
  * --------------------------------------------------------------------------------------
  * @Author   Global Hub
  * @Date     Created: 2021-11-19
  * --------------------------------------------------------------------------------------
  **/
  private List<User> gtOwnUser() {
    return [SELECT Id, Name, Email, gf_pricing_gtb_type__c FROM User WHERE Id =:UserInfo.getUserId()];
  }

  Boolean handleResult(String recordId, Object args) {
    return true;
  }

  Boolean isUserAllowed(String recordId) {
    return gtOwnUser()?.get(0)?.gf_pricing_gtb_type__c;
  }



  /**
  * --------------------------------------------------------------------------------------
  * @Description - Method to call methods
  * --------------------------------------------------------------------------------------
  * @Author   Global Hub
  * @Date     Created: 2021-11-19
  * --------------------------------------------------------------------------------------
  **/
  public Object call(String action, Map<String, Object> args) {
    Object obj;
    final String recordIdvar = 'recordId';
    switch on action {
      when 'isUserAllowed' {
        obj = this.isUserAllowed((String)args.get(recordIdvar));
      }
      when 'getContent' {
        obj = this.getContent((String)args.get(recordIdvar));
      }
      when 'getRecipients' {
        obj = this.getRecipients((String)args.get(recordIdvar));
      }
      when 'renderContent' {
        obj = this.renderContent((String)args.get(recordIdvar), args.get('args'));
      }
      when 'handleResult' {
        obj = this.handleResult((String)args.get(recordIdvar), args.get('args'));
      }
      when 'sendEmail' {
        final Map<String, Object> argsMap = (Map<String, Object>) JSON.deserializeUntyped((String)args.get('args'));
        obj = customEmail(argsMap);
      }
      when else {
        throw new tmpb.TemplateBuilder.TemplateBuilderMalformedCallException('Method not implemented: ' + action +  ', recordId: ' + (Id)args.get(recordIdvar));
      }
    }
    return obj;
  }

  /**
  * --------------------------------------------------------------------------------------
  * @Description - Method to send email
  * --------------------------------------------------------------------------------------
  * @Author   Global Hub
  * @Date     Created: 2021-11-19
  * --------------------------------------------------------------------------------------
  **/
  public static Boolean customEmail(Map<String, Object> argsMap) {

    String parsedSubject = (String)argsMap.get('subject');
    String parsedTemplate = (String)argsMap.get('template');
    Boolean result = false;
    final String targetObjectId = (String)argsMap.get('targetObjectId');
    final Map<String, Object> recipients = (Map<String, Object>) argsMap.get('recipients');
    final List<String> content = new List<String>();
    final String recordId = null;

    try {
      /**
      * Init to, cc and bcc lists
      */
      final List<String> toAddresses = new List<String>();
      final List<String> ccAddresses = new List<String>();
      final List<String> bccAddresses = new List<String>();
      for(String sendType : recipients.keySet()) {
        for (Object recipient : (List<Object>)recipients.get(sendType)) {
          switch on sendType {
            when 'to' {
              toAddresses.add(String.ValueOf(recipient));
            }
            when 'cc' {
              ccAddresses.add(String.ValueOf(recipient));
            }
            when 'bcc' {
              bccAddresses.add(String.ValueOf(recipient));
            }
            when else {
            }
          }
        }
      }

      final List<Messaging.SingleEmailMessage> mails = new List<Messaging.SingleEmailMessage>();
      final Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();

      mail.setToAddresses(toAddresses);
      mail.setccAddresses(ccAddresses);
      mail.setbccAddresses(bccAddresses);
      mail.setBccSender(false);
      mail.setSaveAsActivity(false);
      mail.setUseSignature(false);

      /**
      * Remove any Object related {{{Object.tags}}} if there is no whatId
      * so it doesnt' crash when parsing the template/subject
      */
      if(String.isBlank(recordId)) {
        final String matchWhatIdTags = '\\{{3}[a-zA-Z0-9\\_\\-\\.]+(?<!Sender|Recipient|Contact|User|Lead)\\.[a-zA-Z0-9\\_\\-\\.]+\\}{3}';
        parsedSubject = parsedSubject.replaceAll(matchWhatIdTags,'');
        parsedTemplate = parsedTemplate.replaceAll(matchWhatIdTags,'');
      }

      /**
      * Remove any Recipient related {{{Recipient.tags}}} if there is no whoId
      * so it doesn't crash when parsing the template/subject
      */
      if(String.isBlank(targetObjectId)) {
        final String matchWhoIdTags = '\\{{3}[a-zA-Z0-9\\_\\-\\.]+(?<!Sender|Contact|User|Lead)\\.[a-zA-Z0-9\\_\\-\\.]+\\}{3}';
        parsedSubject = parsedSubject.replaceAll(matchWhoIdTags,'');
        parsedTemplate = parsedTemplate.replaceAll(matchWhoIdTags,'');
      } else {
        mail.setTargetObjectId(targetObjectId);
      }

      final List<Messaging.RenderEmailTemplateBodyResult> merged = Messaging.renderEmailTemplate(targetObjectId, recordId, new List<String>{parsedSubject, parsedTemplate});

      mail.setSubject(merged[0].getMergedBody());
      mail.setHtmlBody(merged[1].getMergedBody());

      mails.add(mail);
      system.debug('** antes envio');
      if(!Test.isRunningTest()){
          final Messaging.SendEmailResult[] resultMail = Messaging.sendEmail(mails, false);
    
          for (Messaging.SendEmailResult mr : resultMail) {
            if (mr.isSuccess()) {
              System.debug('Succcc');
            } else {
              for(Messaging.SendEmailError err : mr.getErrors()) {
                System.debug('The following error has occurred.');
                System.debug(err.getStatusCode() + ': ' + err.getMessage());
                System.debug('fields that affected this error: ' + err.getFields());
              }
      		}
    	}
      system.debug('** despues envio');
      result = true;
    }
        } catch(EmailException e) {
          System.debug('ERROR SENDING EMAIL: ' + e.getMessage());
          System.debug('id: ' + recordId);
          System.debug('recipients: ' + recipients);
          System.debug('content: ' + content);
          System.debug('subject: ' + parsedSubject);
          System.debug('template: ' + parsedTemplate);
        }
    return result;
  }
}