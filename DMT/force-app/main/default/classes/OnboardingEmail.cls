/*
* Class to send the email to notify the onboarding of a prospect
*/
public with sharing class OnboardingEmail {
  /*
  * Invocable variables from flow
  */
  public class FlowInputs {
    @InvocableVariable
    public String record; //NOSONAR
    @InvocableVariable
    public String onboardingTeam; //NOSONAR
  }

  /*
  * Method that sends the email
  */
  @InvocableMethod(label='Send Onboarding Mail' description='Send Onboarding Mail')
  public static void sendEmail(List<FlowInputs> inputs) {
    final FlowInputs input = inputs.get(0);
    final List<EmailTemplate> templates = new List<EmailTemplate>([
      SELECT Id, HtmlValue from EmailTemplate Where DeveloperName = 'Onboarding_prospect'
    ]);

    final Account prospect = [
      SELECT Id, Name, toLabel(DES_Country_Client__c), owner.Email, participant_id__c, participant_id__r.Name, CIB_Commercial_Prospect__c, DES_ID_Fiscal__c, customer_stock_exchange_name__c,
      DES_Segment__c, DES_Subsegment__c, DES_AGGR_Sector__c, DES_Activity__c, DES_Tier__c, Website, BillingAddress
      FROM Account
      WHERE Id = :input.record LIMIT 1
    ];
    final List <Opportunity> opps = new List<Opportunity>([
      SELECT Id, Name, toLabel(DES_Countries__c),toLabel(DES_Booking_Geography__c), toLabel(gf_opportunity_nbc_name__c), sustainable_finance_ind_type__c, owner.Name, owner.EMPLOYEE_DEPARTMENT_DESC__c,
      DES_Description_rich__c, owner.Email
      FROM Opportunity
      WHERE AccountId = :input.record
    ]);
    final Set<Id> oppsIds = new Set<Id>();
    for(Opportunity opp : opps) {
      oppsIds.add(opp.Id);
    }
    final List<DES_Opportunity_Management_member__c> members = new List<DES_Opportunity_Management_member__c>([
      SELECT Id, Name, DES_BBVA_Opportunity_Role__c, DES_Email__c, DES_Opportunity__c
      FROM DES_Opportunity_Management_member__c
      WHERE DES_Opportunity__c IN :oppsIds
    ]);

    String body = templates.get(0).HtmlValue;
    body = body.replace('**ACCNAME**', prospect.Name);
    final String infoList = setBody(opps, members, prospect);
    body = body.replace('**INFOLIST**', infoList);
    final List <String> addresses = getAddresses(input.onboardingTeam);
    addresses.add(prospect.Owner.Email);

    final OrgWideEmailAddress orgmail = [Select Id from OrgWideEmailAddress where Address ='no-reply_sf_globaldesktop@bbva.com' limit 1];
    final Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
    message.toAddresses = addresses;
    message.optOutPolicy = 'FILTER';
    message.setSaveAsActivity(false);
    message.setTargetObjectId(UserInfo.getUserId());
    message.setWhatId(input.record);
    //message.setTemplateId(input.templateId);
    message.setHtmlBody(body);
    message.setOrgWideEmailAddressId(orgmail.Id);
    final Messaging.SingleEmailMessage[] messages = new List<Messaging.SingleEmailMessage> {message};
    final Messaging.SendEmailResult[] results = Messaging.sendEmail(messages);
    if (results[0].success) {
      System.debug('The email was sent successfully.');
    } else {
      System.debug('The email failed to send: ' + results[0].errors[0].message);
    }
  }


  /*
  * Method to replace tags of email template with the correct info of the prospect
  */
  private static String setBody(List <Opportunity> opps, List<DES_Opportunity_Management_member__c> members, Account prospect) {
    String closeLine;
    Address add;
    closeLine ='</li>';
    add = prospect.BillingAddress;
    System.debug(add);
    String sectorLabel = Util_PickList.getLabelFromAPI('Account', 'DES_AGGR_Sector__c').get(prospect.DES_AGGR_Sector__c);
    String segmentLabel = Util_PickList.getLabelFromAPI('Account', 'DES_Segment__c').get(prospect.DES_Segment__c);
    String tierLabel = Util_PickList.getLabelFromAPI('Account', 'DES_Tier__c').get(prospect.DES_Tier__c);
    String subsegmentLabel = Util_PickList.getLabelFromAPI('Account', 'DES_Subsegment__c').get(prospect.DES_Subsegment__c);
    String activityLabel = Util_PickList.getLabelFromAPI('Account', 'DES_Activity__c').get(prospect.DES_Activity__c);

    String infoList = '<ul type = "square"><li>Name: <a href="'+URL.getOrgDomainURL().toExternalForm()+'/'+prospect.Id+'">'+prospect.Name+'</a></li>';
    infoList += '<li>Group: ' + (prospect.participant_id__c == null ? '' : '<a href="'+URL.getOrgDomainURL().toExternalForm()+'/'+prospect.participant_id__c+'">'+prospect.participant_id__r.Name+'</a>') + closeLine;
  	infoList += '<li>CIB / Commercial: ' + getBodyLine(prospect.CIB_Commercial_Prospect__c) + closeLine;
    infoList += '<li>Country: '+ getBodyLine(prospect.DES_Country_Client__c) + closeLine;
    infolist += '<li>ID Fiscal: ' + getBodyLine(prospect.DES_ID_Fiscal__c) + closeLine;
    infolist += '<li>Global Stock Exchange: ' + getBodyLine(prospect.customer_stock_exchange_name__c) + closeLine;
    infolist += '<li>Segment: ' + getBodyLine(segmentLabel) + closeLine;
    infolist += '<li>Subsegment: ' + getBodyLine(subsegmentLabel) + closeLine;
    infolist += '<li>Sector: ' + getBodyLine(sectorLabel) + closeLine;
    infolist += '<li>Activity: ' + getBodyLine(activityLabel) + closeLine;
    infolist += '<li>Tier: ' + getBodyLine(tierLabel) + closeLine;
    infolist += getWebsite(prospect, closeLine);
    infolist += getBilling(prospect, closeLine);
    /* Añadir resto de campos de client */
    for(Opportunity opp : opps) {
      infoList += '<li>Opportunity: <a href="'+URL.getOrgDomainURL().toExternalForm()+'/'+opp.Id+'">'+opp.Name+'</a><ul>';
      infoList += getBodyLine2(opp.DES_Description_rich__c, '<li>Client need\'s description: ', closeLine);
      infoList += getBodyLine2(opp.DES_Countries__c, '<li>BBVA Countries Participants: ', closeLine);
      infoList += getBodyLine2(opp.DES_Booking_Geography__c,'<li>Booking Geography: ', closeLine);
      infoList += getBodyLine2(opp.gf_opportunity_nbc_name__c, '<li>Booking Portfolio: ', closeLine);
      infoList += '<li>Sustainable Finance: '+opp.sustainable_finance_ind_type__c+closeLine;
      infoList += getBodyLine2(opp.owner.Name, '<li>Owner: ', closeLine);
      infoList += getBodyLine2(opp.owner.Email, '<li>Owner Email: ', closeLine);
      infoList += getBodyLine2(opp.owner.EMPLOYEE_DEPARTMENT_DESC__c, '<li>Owner Department: ', closeLine);
      infoList += members.isEmpty() ? '' : '<li>Opportunity members: <ul>';
      infoList = setMembers(infoList, opp, members);
      infoList += members.isEmpty() ? '' : '</ul></li>';
      infoList += '</ul></li>';
    }
    infoList += '</ul>';
    return infoList;
  }

  /*
  * Method to set strings
  */
  private static String getBodyLine(String field) {
    return (field == null ? '' : field);
  }

  /*
  * Method to set strings
  */
  private static String getBodyLine2(String field, String tagHTML, String closeLine) {
    return (field == null ? '' : tagHTML + field + closeLine);
  }

  /*
  * Method to set strings
  */
  private static String getBilling(Account prospect, String closeLine) {
    return '<li>Address: ' + (prospect.BillingAddress == null ? '' : setBillingAddres(prospect.BillingAddress)) + closeLine;
  }

  /*
  * Method to set strings
  */
  private static String getWebsite(Account prospect, String closeLine) {
    return '<li>Website: ' + (prospect.Website == null ? '' : prospect.Website) + closeLine;
  }



  /*
  * Method to get addresses from Metadata
  */
  private static List<String> getAddresses(String team) {
    final List <Onboarding_Email__mdt> emails = new List<Onboarding_Email__mdt>([
      SELECT DeveloperName, Emails__c from Onboarding_Email__mdt LIMIT 50000
    ]);
    List <String> addresses = new List<String>();
    for (Onboarding_Email__mdt ema : emails) {
      if(team == ema.DeveloperName) {
        addresses = ema.Emails__c.split(';');
      }
    }
    system.debug('++addresses -> ' + addresses);
    return addresses;
  }

  /*
  * Method to set members
  */
  private static String setMembers(String infoList1, Opportunity opp, List<DES_Opportunity_Management_member__c> members) {
    String infoList = infoList1;
    for(DES_Opportunity_Management_member__c member : members) {
      if(member.DES_Opportunity__c == opp.Id) {
        infoList += '<li>';
        infoList += member.Name == null ? '' : member.Name + ' ; ';
        infoList += member.DES_Email__c == null ? '' : member.DES_Email__c;
        infoList += member.DES_BBVA_Opportunity_Role__c == null ?  '' :  ' ; ' + member.DES_BBVA_Opportunity_Role__c;
        infoList += '</li>';
      }
    }
    return infoList;
  }

  /*
  * Method to concatenate the billing address
  */
  private static String setBillingAddres(Address address) {
    List<String> strList;
    strList = new List<String>();
    String result;

    if(address.getStreet() != null) {
      strList.add(address.getStreet());
    }
    if(address.getPostalCode() != null) {
      strList.add(address.getPostalCode());
    }
    if(address.getCity() != null) {
      strList.add(address.getCity());
    }
    if(address.getState() != null) {
      strList.add(address.getState());
    }
    result = String.join(strList, ', ');

    return result;
  }
}