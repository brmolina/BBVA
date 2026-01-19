/**********************************************************************************
* @author       Global Desktop
* @date         01/04/2020
* @description  Batch para actualizar el check NPS de la cuenta
**********************************************************************************/
public with sharing class Batch_Update_NPS implements Database.Batchable<Sobject>, Database.Stateful {
  /**
   * @author Global Desktop
   * @description Email 'NPS_Perimeter_created'
   */
  private static List<EmailTemplate> iEmailToUser {
    get {
      if(iEmailToUser == null) {
        iEmailToUser = [SELECT Id,
                          DeveloperName,
                          Subject,
                          HtmlValue,
                          Markup
                        FROM EmailTemplate
                        WHERE DeveloperName = 'NPS_New_Perimeter'];
      }
      return iEmailToUser;
    } set;
  }
  /**
  * @author Global Desktop
  * @Description iQuery
  */
  private static Map<String, String> mapCountryAbbrv {
    get {
      if(mapCountryAbbrv == null) {
        mapCountryAbbrv = new Map<String, String>();
        mapCountryAbbrv.put('ARGENTINA', 'AR');
        mapCountryAbbrv.put('BELGICA', 'BE');
        mapCountryAbbrv.put('CHINA', 'CN');
        mapCountryAbbrv.put('COLOMBIA', 'CO');
        mapCountryAbbrv.put('FRANCIA', 'FR');
        mapCountryAbbrv.put('ALEMANIA', 'DE');
        mapCountryAbbrv.put('HONG-KONG', 'HK');
        mapCountryAbbrv.put('ITALIA', 'IT');
        mapCountryAbbrv.put('JAPON', 'JP');
        mapCountryAbbrv.put('MEXICO', 'MX');
        mapCountryAbbrv.put('PERU', 'PE');
        mapCountryAbbrv.put('PORTUGAL', 'PT');
        mapCountryAbbrv.put('SINGAPUR', 'SG');
        mapCountryAbbrv.put('ESPAÑA', 'ES');
        mapCountryAbbrv.put('TAIWAN', 'TW');
        mapCountryAbbrv.put('TURQUIA', 'TR');
        mapCountryAbbrv.put('REINO UNIDO', 'GB');
        mapCountryAbbrv.put('URUGUAY', 'UY');
        mapCountryAbbrv.put('EEUU', 'US');
        mapCountryAbbrv.put('VENEZUELA', 'VE');
      }
      return mapCountryAbbrv;
    } set;
  }
  /**
  * @author Global Desktop
  * @Description iQuery
  */
  private final String iQuery;
  /**
  * @author Global Desktop
  * @Description yearHasChanged
  */
  private final Boolean yearHasChanged;
  /**
  * @author Global Desktop
  * @Description tierPerimeter
  */
  private  String tierPerimeter;
  /**
  * @author Global Desktop
  * @Description segmentPerimeter
  */
  private  String segmentPerimeter;
  /**
  * @author Global Desktop
  * @Description countryPerList
  */
  private final List<String> countryPerList;
  /**
  * @author Global Desktop
  * @Description listAccountQuery
  */
  private List<Account> listAccountQuery; //NOSONAR
  /**
  * @author Global Desktop
  * @Description iWavePerimeter
  */
  private NPS_Wave__c iWavePerimeter; //NOSONAR
  /**
  * @author Global Desktop
  * @Description apivaluesSelect
  */
  private Map<String,String> apivaluesSelect; //NOSONAR
  /**
  * @author Global Desktop
  * @Description listAccNPS
  */
  private List<Account> listAccNPS; //NOSONAR

  /**
  * @author Global Desktop
  * @Description constructor
  */
  public Batch_Update_NPS(String accSelect, Boolean yearHasChangedPar, NPS_Wave__c iWavePerimeterPar, Map<String,String> apivaluesSelPar) {
    iWavePerimeter = iWavePerimeterPar;
    yearHasChanged = yearHasChangedPar;
    apivaluesSelect = apivaluesSelPar;
    tierPerimeter = '';
    segmentPerimeter = '';
    tierPerimeter = '';
    segmentPerimeter = '';

    countryPerList = new List<String>();
    for(String iCountry : iWavePerimeterPar.gf_nps_sv_cust_rev_ind_type__c.split(';')) {
      countryPerList.add(mapCountryAbbrv.get(iCountry));
    }
    listAccountQuery = (List<Account>) JSON.deserialize(accSelect, List<Account>.class);
    iQuery = 'SELECT Id, survey_nps_contact_type__c FROM Account WHERE Id IN :listAccountQuery OR (survey_nps_contact_type__c = true AND RecordType.DeveloperName IN (\'Group\',\'DES_Commercial_Client\'))';
    listAccNPS = new List<Account>();
  }

  /**
  * @author Global Desktop
  * @Description start
  */
  public Database.QueryLocator start(Database.BatchableContext iBatchableContext) {
    return Database.getQueryLocator(iQuery);
  }

  /**
  * @author Global Desktop
  * @Description execute
  */
  public void execute(Database.BatchableContext iBatchableContext, List<Account> listAccount) {
    String tierDesc = iWavePerimeter.gf_nps_survey_cust_tier_desc__c;
    if (tierDesc != null) {
        List<String> apiValues = new List<String>();

        for (String eachTierLabel : tierDesc.split(';')) {
            apiValues.add(Util_Picklist.getAPIFromLabel('Account', 'DES_Tier__c', eachTierLabel));
        }

        tierPerimeter = String.join(apiValues, ';');
    }

    String segmentLabels = iWavePerimeter.gf_nps_sv_cust_prfsnl_seg_desc__c;
    if (segmentLabels != null) {
        List<String> apiValues = new List<String>();

        for (String eachSegmentLabel : segmentLabels.split(';')) {
            apiValues.add(Util_Picklist.getAPIFromLabel('Account', 'DES_Segment__c', eachSegmentLabel));
        }

        segmentPerimeter = String.join(apiValues, ';');
    }



    final List<Account> listAccToUncheck = [SELECT Id,
                                              survey_nps_contact_type__c,
                                              NPS_Year_History__c
                                            FROM Account
                                            WHERE Id IN (SELECT participant_child_id__c
                                                        FROM DES_Subsidiary_Group_Relation__c
                                                        WHERE participant_parent_id__c IN :listAccount)];
    listAccToUncheck.addAll(listAccount);
    Home_NPS_Wave_Cnt_Aux.resetNPSAccount(listAccToUncheck);

    final String countryVal = apivaluesSelect.get('gf_nps_sv_cust_rev_ind_type__c');
    final List<AggregateResult> bookList = [SELECT COUNT(Id), DES_Client__c
                                            FROM DES_Booking__c
                                            WHERE DES_Engloba_Load_Helper__c = '1'
                                              AND DES_Country__c IN :countryVal.split(';')
                                              AND DES_Client__c IN (SELECT participant_child_id__c
                                                                    FROM DES_Subsidiary_Group_Relation__c
                                                                    WHERE participant_parent_id__c IN :listAccountQuery
                                                                      AND participant_parent_id__c IN :listAccount
                                                                      AND participant_child_id__r.DES_Tier__c IN :tierPerimeter.split(';')
                                                                      AND participant_child_id__r.DES_Segment__c IN :segmentPerimeter.split(';')
                                                                      AND participant_child_id__r.DES_Country_Client__c IN :countryPerList)
                                                                    GROUP BY DES_Client__c];
    final Integer remainingRows = Limits.getLimitQueryRows() - Limits.getQueryRows();

    final Set<Id> setIdFilial = new Set<Id>();
    for (AggregateResult iAggResult : bookList) {
      final Id cliente = (Id) iAggResult.get('DES_Client__c');
      setIdFilial.add(cliente);
    }

    final List<Account> listAccToCheck = [SELECT Id,
                                            survey_nps_contact_type__c,
                                            NPS_Year_History__c
                                          FROM Account
                                          WHERE ((Id IN :listAccountQuery
                                            AND Id IN :listAccount)
                                              OR Id IN :setIdFilial)
                                            AND DES_Country_Client__c IN :countryPerList];
    Home_NPS_Wave_Cnt_Aux.checkNPSAccount(listAccToCheck);
    listAccNPS.addAll(listAccToCheck);

    //if(yearHasChanged == true) {
     // Home_NPS_Wave_Cnt_Aux.resetNPSContact(); re comento esta linea para dar solucion a la solicitud del cliente
    //}
  }

  /**
  * @author Global Desktop
  * @Description finish
  */
  public void finish(Database.BatchableContext iBatchableContext) {
    insert iWavePerimeter;

    List<Account> listAccToUncheck = new List<Account>();
    for(Account iAccount : [SELECT Id,
                              survey_nps_contact_type__c
                            FROM Account
                            WHERE Id NOT IN :listAccNPS
                              AND survey_nps_contact_type__c = true]) {
      iAccount.survey_nps_contact_type__c = false;
      listAccToUncheck.add(iAccount);
    }

    update listAccToUncheck;

    sendNPSPerimeterCreatedEmail(iWavePerimeter);

    final AsyncApexJob iJob = [SELECT Id,
                          Status,
                          NumberOfErrors,
                          JobItemsProcessed
                        FROM AsyncApexJob
                        WHERE Id = :iBatchableContext.getJobId()];
  }

  /**
   * @author Global Desktop
   * @method sendNPSPerimeterCreatedEmail
   */
  public static void sendNPSPerimeterCreatedEmail(NPS_Wave__c iWavePerimeter) {
    final List<Messaging.SingleEmailMessage> listMails = new List<Messaging.SingleEmailMessage>();

    final Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
    mail.setTemplateId(iEmailToUser[0].Id);
    mail.setTargetObjectId(UserInfo.getUserId());
    mail.setOrgWideEmailAddressId(Label.SER_MasterCaseInternalNotificationSender);
    mail.setSaveAsActivity(false);
    // mail.setWhatId(iWavePerimeter.Id);
    listMails.add(mail);

    if(!listMails.isEmpty() && !Test.isRunningTest()) { //NOSONAR
      Messaging.sendEmail(listMails);
    }
  }
}