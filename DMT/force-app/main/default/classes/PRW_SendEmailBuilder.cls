/**
* ------------------------------------------------------------------------------------------------
* @Name     PRW_SendEmailBuilder
* @Author   Global Hub
* @Date     Created: 2021-11-19
* ------------------------------------------------------------------------------------------------
* @Description Send Email for pricewise
* ------------------------------------------------------------------------------------------------
* @Changes
*
* |2021-11-19 david.rodriguez.lucena.contractor@bbva.com
*             Class Creation
* |2022-09-12 ivan.garces.contractor@bbva.com
*             Class Update
* -----------------------------------------------------------------------------------------------
*/
@SuppressWarnings('sf:AvoidFinalLocalVariable, sf:LogicInversion, sf:DUDataflowAnomalyAnalysis, sf:NcssMethodCount, sf:NPathComplexity, sf:CyclomaticComplexity, sf:TooManyMethods')
global with sharing class PRW_SendEmailBuilder implements Callable {

  /**
  * GLOBAL VARIABLE flatvar
  */
  private static String flatvar = 'flats';

  /**
  * GLOBAL VARIABLE simP
  */
  private static String simP = 'simulatedP';

  /**
  * GLOBAL VARIABLE simPC
  */
  private static String simPC = 'simulatedPC';

  /**
  * GLOBAL VARIABLE simQ
  */
  private static String simQ = 'simulatedQ';

  /**
  * GLOBAL VARIABLE simQ
  */
  private static String simQN = 'simulatedQN';

  /**
  * GLOBAL VARIABLE simRev
  */
  private static String simRev = 'simRevenue';

  /**
  * GLOBAL VARIABLE simRev
  */
  private static String simRevC = 'simRevenueC';

  /**
  * GLOBAL VARIABLE aggP
  */
  private static String aggP = 'agreedP';

  /**
  * GLOBAL VARIABLE aggP
  */
  private static String aggPC = 'agreedPC';

  /**
  * GLOBAL VARIABLE aggQ
  */
  private static String aggQ = 'agreedQ';

  /**
  * GLOBAL VARIABLE aggQ
  */
  private static String aggQN = 'agreedQN';

  /**
  * GLOBAL VARIABLE expRev
  */
  private static String expRev = 'expRevenue';

  /**
  * GLOBAL VARIABLE expRev
  */
  private static String expRevC = 'expRevenueC';

  /**
  * GLOBAL VARIABLE idProd
  */
  private static String idProd = 'id_prod';

  /**
  * GLOBAL VARIABLE euro
  */
  private static String euro = '&euro;';

  /**
  * GLOBAL VARIABLE tablavar
  */
  private static String tablavar = '<td width=25% style="text-align:right;color:#535351;font-family:\'Noto Sans\',Arial,Helvetica,sans-serif;">';

  /**
  * GLOBAL VARIABLE tdvar
  */
  private static String tdvar = '</td>';

  /**
  * GLOBAL VARIABLE trvar
  */
  private static String trvar = '</tr><tr>';

  /**
  * GLOBAL VARIABLE productvar
  */
  private static String productvar = 'product';

  /**
  * GLOBAL VARIABLE productvar
  */
  private static String tablavar2 = '<td width=33% style="text-align:right;color:#535351;font-family:\'Noto Sans\',Arial,Helvetica,sans-serif;">';

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

    final List<String> lJSON = recordId.split(':::::');
    List<Map<String,String>> listObject = new List<Map<String,String>>();

    //Sacamos las listas de productos
    if(lJSON.get(1) != null) {
      listObject = (List<Map<String,String>>) JSON.deserialize(lJSON.get(1), List<Map<String,String>>.class);
    }
    //Selectable Content
    final tmpb.TemplateBuilder.TemplateBuilderContent content = new tmpb.TemplateBuilder.TemplateBuilderContent();
    content.id = 'Content';
    content.name = 'Sample result content elements';
    content.categories = new List<tmpb.TemplateBuilder.TemplateBuilderContentCategory>();

    // flats
    final tmpb.TemplateBuilder.TemplateBuilderContentCategory flats = categoryComplete(listObject, true);
    content.categories.add(flats);

    //specials
    final tmpb.TemplateBuilder.TemplateBuilderContentCategory specials = categoryComplete(listObject, false);
    content.categories.add(specials);

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
    final String special = 'specials';
    final String sigblock = 'sigblock';
    final String truevar = 'true';

    try {
      ids = (tmpb.TemplateBuilder.TemplateBuilderArgs) System.JSON.deserialize((String)args, tmpb.TemplateBuilder.TemplateBuilderArgs.class);
      final List<String> selectedSpecIds = new List<String>();
      final List<String> selectedFlatsIds = new List<String>();
      final List<String> sigBlockIds = new List<String>();

      for(String selected : ids.selectedIds ) {
        final List<String> pair = selected.split('-');
        if (pair[0] == flatvar) {
          selectedFlatsIds.add(pair[1]);
        }
        if (pair[0] == special) {
          selectedSpecIds.add(pair[1]);
        }
        if (pair[0] == sigblock) {
          sigBlockIds.add(pair[1]);
        }
      }

      // Visit date to human readable
      //
      final tmpb.TemplateBuilder.TemplateBuilderRenderedElement datefmtd = renderComplete('date_today', null, null, false);
      renderedContent.rendered.add(datefmtd);

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

      // Cuco Code
      final tmpb.TemplateBuilder.TemplateBuilderRenderedElement cuco = new tmpb.TemplateBuilder.TemplateBuilderRenderedElement();
      cuco.key = 'cuco_code';
      cuco.value = lJSON.get(4) != null ? lJSON.get(4) : ''; //NOSONAR
      renderedContent.rendered.add(cuco);


      //Sacamos las listas de productos
      List<Map<String,String>> listObject = new List<Map<String,String>>();
      
      if(!(lJSON.get(1) == null)) {
        listObject = (List<Map<String,String>>) JSON.deserialize(lJSON.get(1), List<Map<String,String>>.class);
      }

      // Add flats selected
      final tmpb.TemplateBuilder.TemplateBuilderRenderedElement flatElement = renderComplete(flatvar, listObject, selectedFlatsIds, false);
      renderedContent.rendered.add(flatElement);

      final tmpb.TemplateBuilder.TemplateBuilderRenderedElement flatBanker = renderComplete('flats_banker', listObject, selectedFlatsIds, true);
      renderedContent.rendered.add(flatBanker);

      // Add specials selected
      final tmpb.TemplateBuilder.TemplateBuilderRenderedElement specialElement = renderComplete('specials', listObject, selectedSpecIds, false);
      renderedContent.rendered.add(specialElement);

      final tmpb.TemplateBuilder.TemplateBuilderRenderedElement specialBanker = renderComplete('specials_banker', listObject, selectedSpecIds, true);
      renderedContent.rendered.add(specialBanker);

      if(lJSON.get(lJSON.size()-1) == truevar) {
        final tmpb.TemplateBuilder.TemplateBuilderRenderedElement subsidiaryCuco = renderedAccounts(lJSON);
        renderedContent.rendered.add(subsidiaryCuco);
      }

      final tmpb.TemplateBuilder.TemplateBuilderRenderedElement block = renderComplete('signatureBlock', listObject, sigBlockIds, true);
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
  private tmpb.TemplateBuilder.TemplateBuilderRenderedElement renderComplete(String key, List<Map<String,String>> listObject, List<String> selected, Boolean isBanker) {
    final tmpb.TemplateBuilder.TemplateBuilderRenderedElement element = new tmpb.TemplateBuilder.TemplateBuilderRenderedElement();
    element.key = key;
    final String datetod = 'date_today';
    final String signatureBlock = 'signatureBlock';
    if(key.contains(flatvar)) {
      element.value = renderedFlat(listObject, selected, isBanker);
    } else if(key == signatureBlock) {
      element.value = '';
      final List<User> owners = [SELECT Id, Name, Email, MobilePhone, EMPLOYEE_DEPARTMENT_DESC__c, Extension FROM User WHERE Id IN :selected];
      for(User  member : owners) {
        element.value = element.value + '<div style="margin:20px 20px;padding:0px 0px;float:left;">';
        element.value = element.value + '<div style="font-size:12px;font-weight:bold;">' + member.Name + '</div>';
        if(member.MobilePhone != null)element.value = element.value + '<div style="font-size:12px;">Phone: ' + member.MobilePhone + '  (ext. ' + member.Extension + ')</div>';
        element.value = element.value + '<div style="font-size:12px;"><a href="mailto:' + member.Email + '">' + member.Email + '</a></div></div>';
      }
    } else if(key == datetod) {
      element.value = Datetime.now().format('MMMM') + ' ' + Datetime.now().format('dd') + ', ' + Datetime.now().format('yyyy');
    } else {
      element.value = renderedSpecial(listObject, selected, isBanker);
    }
    return element;
  }

  /**
  * --------------------------------------------------------------------------------------
  * @Description - Method that render flat
  * --------------------------------------------------------------------------------------
  * @Author   Global Hub
  * @Date     Created: 2021-11-19
  * --------------------------------------------------------------------------------------
  **/
  private String renderedFlat(List<Map<String,String>> listObject, List<String> selectedFlatsIds, Boolean isBanker) {
    String res = '<div style="background-color:#F3F2F2;border:1px solid #DDDBDA; padding: 10px;"><p style="color:#043263;font-size:15px;font-family:\'Noto Sans\',Arial,Helvetica,sans-serif;"><strong>FLAT FEES</strong></p></div><br />';
    for(Map<String,String> element : listObject) {
      if(selectedFlatsIds.contains(element.get(idProd))) {
        res = res + '<p style="border-bottom:1px solid #1464A5;font-size:14px;text-align:left;color:#1464A5;font-family:\'Noto Sans\',Arial,Helvetica,sans-serif;"><strong>' + element.get(productvar) + '</strong></p>';
        res = res + '<table style="margin-top:10px;width:100%" cellpadding="5px">';
        res = res + '<tr width=100% style="text-align:right">';
        res = cabeceraTabla(res, isBanker, true);
        res = res + trvar;
        res = cuerpoTabla(element, res, isBanker, true);
        res = res + '</tr></table><hr style="border-top: 1px dashed; margin-bottom:15px;margin-top:15px;"/>';
      }
    }
    return res;
  }

  /**
  * --------------------------------------------------------------------------------------
  * @Description - Method that render special
  * --------------------------------------------------------------------------------------
  * @Author   Global Hub
  * @Date     Created: 2021-11-19
  * --------------------------------------------------------------------------------------
  **/
  private String renderedSpecial(List<Map<String,String>> listObject, List<String> selectedSpecIds, Boolean isBanker) {
    String res = '<div style="background-color:#F3F2F2;border:1px solid #DDDBDA; padding: 10px;"><p style="color:#043263;font-size:15px;font-family:\'Noto Sans\',Arial,Helvetica,sans-serif;"><strong>SPECIAL CONDITIONS</strong></p></div><br />';
    for(Map<String,String> element : listObject) {
      if(selectedSpecIds.contains(element.get(idProd))) {
        res = res + '<p style="border-bottom:1px solid #1464A5;font-size:14px;text-align:left;color:#1464A5;font-family:\'Noto Sans\',Arial,Helvetica,sans-serif;"><strong>' + element.get(productvar) + '</strong></p>';
        res = res + '<table style="margin-top:10px;width:100%" cellpadding="5px">';
        res = res + '<tr width=100% style="text-align:right">';
        res = cabeceraTabla(res, isBanker, false);
        res = res + trvar;
        res = cuerpoTabla(element, res, isBanker, false);
        res = res + '</tr></table><hr style="border-top: 1px dashed; margin-bottom:15px;margin-top:15px;"/>';
      }
    }
    return res;
  }

  /**
  * --------------------------------------------------------------------------------------
  * @Description - Method that render flat
  * --------------------------------------------------------------------------------------
  * @Author   Global Hub
  * @Date     Created: 2021-11-22
  * --------------------------------------------------------------------------------------
  **/
  private String cabeceraTabla(String resAux, Boolean isBanker, Boolean isFlat) {
    String res = resAux;
    if(isBanker && isFlat) {
      res = res + '<th style="border:1px solid #DDDBDA;text-align:center;font-size:12px;font-family:\'Noto Sans\',Arial,Helvetica,sans-serif;">Agreed Price</th>';
      res = res + '<th style="border:1px solid #DDDBDA;text-align:center;font-size:12px;font-family:\'Noto Sans\',Arial,Helvetica,sans-serif;">Agreed Quantity</th>';
      res = res + '<th style="border:1px solid #DDDBDA;text-align:center;font-size:12px;font-family:\'Noto Sans\',Arial,Helvetica,sans-serif;">Expected Revenues</th>';
    } else if(isBanker && !isFlat) {
      res = res + '<th style="border:1px solid #DDDBDA;text-align:center;font-size:12px;font-family:\'Noto Sans\',Arial,Helvetica,sans-serif;">Agreed Price</th>';
      res = res + '<th style="border:1px solid #DDDBDA;text-align:center;font-size:12px;font-family:\'Noto Sans\',Arial,Helvetica,sans-serif;">Simulated Price</th>';
      res = res + '<th style="border:1px solid #DDDBDA;text-align:center;font-size:12px;font-family:\'Noto Sans\',Arial,Helvetica,sans-serif;">Simulated Quantity</th>';
      res = res + '<th style="border:1px solid #DDDBDA;text-align:center;font-size:12px;font-family:\'Noto Sans\',Arial,Helvetica,sans-serif;">Total Simulated</th>';
    } else {
      res = res + '<th style="border:1px solid #DDDBDA;text-align:center;font-size:12px;font-family:\'Noto Sans\',Arial,Helvetica,sans-serif;">Simulated Price</th>';
      res = res + '<th style="border:1px solid #DDDBDA;text-align:center;font-size:12px;font-family:\'Noto Sans\',Arial,Helvetica,sans-serif;">Simulated Quantity</th>';
      res = res + '<th style="border:1px solid #DDDBDA;text-align:center;font-size:12px;font-family:\'Noto Sans\',Arial,Helvetica,sans-serif;">Total simulated</th>';
    }
    return res;
  }

  /**
  * --------------------------------------------------------------------------------------
  * @Description - Method that render flat
  * --------------------------------------------------------------------------------------
  * @Author   Global Hub
  * @Date     Created: 2021-11-22
  * --------------------------------------------------------------------------------------
  **/
  private String cuerpoTabla(Map<String,String> element, String resAux, Boolean isBanker, Boolean isFlat) {
    String res = resAux;
      
      final Decimal simPr = element.get(simP) == null ? null : Decimal.valueOf(element.get(simP)).setScale(4, RoundingMode.HALF_EVEN);      
      final String simPrFormat = simPr.format();

      final Decimal simQu = element.get(simQ) == null ? null : Decimal.valueOf(element.get(simQ)).setScale(5, RoundingMode.HALF_EVEN);
      final String simQuFormat = simQu.format();

      final Decimal simReve = simQu == null || simPr == null ? null : (simPr * simQu);
      final String simReveFormat = simReve.setScale(2, RoundingMode.HALF_EVEN).format();

      final Decimal agreedPr = element.get(aggP) == null ? null : Decimal.valueOf(element.get(aggP)).setScale(4, RoundingMode.HALF_EVEN);
      final String agreedPrFormat = agreedPr.format();
      final Decimal agreedQu = element.get(aggQ) == null ? null : Decimal.valueOf(element.get(aggQ)).setScale(2, RoundingMode.HALF_EVEN);
      final Decimal expectedRev = agreedQu == null ? null : (agreedPr * agreedQu).setScale(2, RoundingMode.HALF_EVEN); 
      

      // final String price = element.get(simP) == null ? '-' : simPrFormat + euro;
      final String price = element.get(simPC) == null ? '-' : element.get(simPC);
      // final String quantity = element.get(simQ) == null ? '-' : simQuFormat;
      final String quantity = element.get(simQN) == null ? '-' : element.get(simQN);
      //final String simRevenue = element.get(simRev) == null ? '-' : simReveFormat + euro;
      final String simRevenue = element.get(simRevC) == null ? '-' : element.get(simRevC);
      
      //final String agreedP = element.get(aggP) == null ? '-' : agreedPrFormat + euro;
      final String agreedP = element.get(aggPC) == null ? '-' : element.get(aggPC);
      // final String agreedQ = element.get(aggQ) == null ? '-' : agreedQu.format();
      final String agreedQ = element.get(aggQN) == null ? '-' : element.get(aggQN);
      // final String expected = element.get(expRev) == null ? '-' : expectedRev.format() + euro;
      final String expected = element.get(expRevC) == null ? '-' : element.get(expRevC);
      if(isBanker && isFlat) {
        res = res + tablavar2+ agreedP + tdvar;
        res = res + tablavar2+ agreedQ +tdvar;
        res = res + tablavar2+ expected +tdvar;
        res = res + trvar;
        res = res + '<th style="border:1px solid #DDDBDA;text-align:center;font-size:12px;font-family:\'Noto Sans\',Arial,Helvetica,sans-serif;">Simulated Price</th>';
        res = res + '<th style="border:1px solid #DDDBDA;text-align:center;font-size:12px;font-family:\'Noto Sans\',Arial,Helvetica,sans-serif;">Simulated Quantity</th>';
        res = res + '<th style="border:1px solid #DDDBDA;text-align:center;font-size:12px;font-family:\'Noto Sans\',Arial,Helvetica,sans-serif;">Total Simulated</th>';
        res = res + trvar;
        res = res + tablavar2+ price +tdvar;
        res = res + tablavar2+ quantity +tdvar;
        res = res + tablavar2+ simRevenue +tdvar;
      } else if(isBanker && !isFlat) {
        res = res + tablavar+ agreedP + tdvar;
        res = res + tablavar+ price +tdvar;
        res = res + tablavar+ quantity +tdvar;
        res = res + tablavar+ simRevenue +tdvar;
      } else {
        res = res + '<td style="text-align:right;color:#535351;font-family:\'Noto Sans\',Arial,Helvetica,sans-serif;">'+ price + tdvar;
        res = res + '<td style="text-align:right;color:#535351;font-family:\'Noto Sans\',Arial,Helvetica,sans-serif;">'+ quantity +tdvar;
        res = res + '<td style="text-align:right;color:#535351;font-family:\'Noto Sans\',Arial,Helvetica,sans-serif;">'+ simRevenue +tdvar;
      }
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
  private tmpb.TemplateBuilder.TemplateBuilderRenderedElement renderedAccounts(List<String> lJSON) {
    final tmpb.TemplateBuilder.TemplateBuilderRenderedElement subsidiaryCuco = new tmpb.TemplateBuilder.TemplateBuilderRenderedElement();
    final List<String> idsAcc = lJSON.get(3).split('-');
    final List<Account> accs = [SELECT Id, Name FROM Account WHERE Id =: idsAcc];
    String res = '<div style="background-color:#F3F2F2;border:1px solid #DDDBDA; padding: 10px;"><p style="color:#043263;font-size:15px;font-family:\'Noto Sans\',Arial,Helvetica,sans-serif;"><strong>SUBSIDIARIES</strong></p></div><br />';
    for(Account acc : accs) {
      res = res + '<p style="font-size:14px;text-align:left;color:#1464A5;font-family:\'Noto Sans\',Arial,Helvetica,sans-serif;"><strong>' + acc.Name + '</strong></p>';
    }
    subsidiaryCuco.key = 'subsidiary_cuco';
    subsidiaryCuco.value = res;
    return subsidiaryCuco;
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


  /**
  * --------------------------------------------------------------------------------------
  * @Description - Method that create content category flat
  * --------------------------------------------------------------------------------------
  * @Author   Global Hub
  * @Date     Created: 2021-11-19
  * --------------------------------------------------------------------------------------
  **/
  private tmpb.TemplateBuilder.TemplateBuilderContentCategory categoryComplete(List<Map<String,String>> listObject, Boolean flat) {
    final tmpb.TemplateBuilder.TemplateBuilderContentCategory category = new tmpb.TemplateBuilder.TemplateBuilderContentCategory();
    if(flat) {
      category.id = flatvar;
      category.title = 'Flat fee conditions';
      category.description = 'Please select which products of the Flat fee you would like to send by email';
    } else {
      category.id = 'specials';
      category.title = 'Special conditions';
      category.description = 'Please select which Special conditions you would like to send by email';
    }
    category.items = new List<tmpb.TemplateBuilder.TemplateBuilderContentItem>();
    for(Map<String,String> element : listObject) {
      if(element.get(simQ) != null){
        if(element.get(aggP) != null && Double.ValueOf(element.get(simQ)) != 0 && (flat && element.get(idProd).contains('dypri.'))|| (!flat && !element.get(idProd).contains('dypri.') /*&& Double.ValueOf(element.get(aggP))!= 0*/)){
          final tmpb.TemplateBuilder.TemplateBuilderContentItem item = new tmpb.TemplateBuilder.TemplateBuilderContentItem();
          item.id = element.get(idProd);
          item.title = element.get(productvar);
          item.description = element.get(productvar);
          item.checked = element.get('simRevenue') != null ? true : false;
          item.disabled = false;
          category.items.add(item);
        }
      }
    }
    return category;
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
              //System.debug('unrecognized recipient type ' + sendType  + ' for recipient ' + String.ValueOf(recipient));
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