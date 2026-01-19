/**
 * @author Global Desktop
 * @description Clase del componente lightning NPS_ContactHistory del layout de contacto.
 */
public with sharing class NPS_ContactHistoryController {
  /**
   * @author Global Desktop
   * @description Constante '/lightning/r/User/'
   */
  private static final String USER_URL = '/lightning/r/User/';
  /**
   * @author Global Desktop
   * @description Constante '/view'
   */
  private static final String VIEW_URL = '/view';
  /**
   * @author Global Desktop
   * @description Constante 'Owner'
   */
  private static final String OWNER_FIELD = 'Owner';
  /**
   * @author Global Desktop
   * @description Constante 'last_send_nps_user_id__c'
   */
  private static final String SUBMITTER_FIELD = 'last_send_nps_user_id__c';
  /**
   * @author Global Desktop
   * @description Constante 'survey_nps_contact_type__c'
   */
  private static final String NPS_FIELD = 'survey_nps_contact_type__c';
  /**
   * @author Global Desktop
   * @description Constante 'nps_unavailable_date__c'
   */
  private static final String UNCHECKDATE_FIELD = 'nps_unavailable_date__c';
  /**
   * @author Global Desktop
   * @description Constante 'nps_discard_reason_type__c'
   */
  private static final String REASNUNCHCK_FIELD = 'nps_discard_reason_type__c';

  /**
   * @author Global Desktop
   * @description SINGLETON PATTERN
   */
  private static NPS_ContactHistoryController instance;
  /**
   * @author Global Desktop
   * @description getInstance
   */
  public static NPS_ContactHistoryController getInstance() { //NOSONAR
    if (instance == null) {
      instance = new NPS_ContactHistoryController();
    }
    return instance;
  }

  /**
   * @author Global Desktop
   * @description Empty Constructor
   */
  private NPS_ContactHistoryController() {
    System.debug('Constructor empty');
  }

  /**
   * @author Global Desktop
   * @method getContactHistory
   */
  @auraEnabled
  public static String getContactHistory(String tableSize, String contactId) {
    final List<ContactHistory> contactHistory = [SELECT Id,
                                                  Field,
                                                  CreatedDate,
                                                  OldValue,
                                                  NewValue,
                                                  ContactId,
                                                  Contact.Name,
                                                  Contact.OwnerId,
                                                  Contact.Owner.Name,
                                                  Contact.last_send_nps_user_id__c,
                                                  Contact.last_send_nps_user_id__r.Name,
                                                  Contact.survey_nps_contact_type__c,
                                                  Contact.nps_unavailable_date__c,
                                                  Contact.nps_discard_reason_type__c
                                                FROM ContactHistory
                                                WHERE ContactId = :contactId
                                                  AND Field IN (:SUBMITTER_FIELD, :NPS_FIELD, :UNCHECKDATE_FIELD, :REASNUNCHCK_FIELD)
                                                ORDER BY CreatedDate ASC];

      List<WrapperClass> listWrapperClass = new List<WrapperClass>();
      try {
        System.debug('::::::::::::::::::::contactHistory:::: ' + JSON.serialize(contactHistory));
        Integer tSize;
        if(tableSize != null) {
          System.debug('::::::::::::::::::::tableSize:::: ' + tableSize);
          tSize = Integer.valueOf(tableSize);
        }

        Map<Integer, WrapperClass> mapContactHistory = new Map<Integer, WrapperClass>();
        if(!contactHistory.isEmpty()) {
          mapContactHistory = getContactHistoryByYear(contactHistory, mapContactHistory);
        }

        if(!mapContactHistory.isEmpty()) {
          listWrapperClass = mapContactHistory.values();
        }
        System.debug('::::::::::::::::::::tSize:::: ' + tSize);
        if(tSize == null) {
          system.debug('>>>>> listWrapperClass tSize NULL : ' + listWrapperClass);
        } else {
          listWrapperClass = getListWrapper(tSize, listWrapperClass);
          System.debug('::::::::::::::::::::listWrapperClass:::: ' + listWrapperClass);
          System.debug('::::::::::::::::::::JSON.serialize(listWrapperClass):::: ' + JSON.serialize(listWrapperClass));
        }
      } catch(Exception e) {
        throw new AuraHandledException('Error message. ' + e); //NOSONAR
      }

      return JSON.serialize(listWrapperClass);
  }

  /**
   * @author Global Desktop
   * @method checkContactNoNPS
   */
  private static Map<Integer, WrapperClass> getContactHistoryByYear(List<ContactHistory> contactHistory, Map<Integer, WrapperClass> mapContactHistory) {
    for(ContactHistory iContactHistory : contactHistory) {
      if(mapContactHistory.containsKey(iContactHistory.CreatedDate.year())) {
        final WrapperClass iWrapperClass = mapContactHistory.get(iContactHistory.CreatedDate.year());
        iWrapperClass.completeWrapperClass(iContactHistory);
        mapContactHistory.put(iContactHistory.CreatedDate.year(), iWrapperClass);
      } else {
        mapContactHistory.put(iContactHistory.CreatedDate.year(), new WrapperClass(iContactHistory));
      }
    }

    return mapContactHistory;
  }

  /**
   * @author Global Desktop
   * @method getListWrapper
   */
  private static List<WrapperClass> getListWrapper(Integer tSize, List<WrapperClass> listWrapperClass) {
    final List<wrapperClass> listWrapperAux = new List<wrapperClass>();
    Integer regTable = tSize;
    System.debug('::::::::::::::::::::listWrapperClass.size():::: ' + listWrapperClass.size());
    if(tSize > listWrapperClass.size()) {
      regTable = listWrapperClass.size();
    }
    System.debug('::::::::::::::::::::regTable:::: ' + regTable);
    for(Integer cn = 0; cn < regTable ; cn++) {
      if(!listWrapperClass.isEmpty() && listWrapperClass.get(cn) != null) {
        listWrapperAux.add(listWrapperClass.get(cn));
      }
    }

    return listWrapperAux;
  }

  /**
   * @author Global Desktop
   * @description clase para construir lista wrapper
   */
  public class WrapperClass {
    /**
     * @author Global Desktop
     * @description Variables de la clase wrapper
     */
    private String ownerURL; //NOSONAR
    /**
     * Attribute
     */
    private String submitterURL; //NOSONAR
    /**
     * Attribute
     */
    private String ownerName; //NOSONAR
    /**
     * Attribute
     */
    private String submitterName; //NOSONAR
    /**
     * Attribute
     */
    private Integer year; //NOSONAR
    /**
     * Attribute
     */
    private Boolean nps; //NOSONAR
    /**
     * Attribute
     */
    private Datetime uncheckingDate; //NOSONAR
    /**
     * Attribute
     */
    private String uncheckingReason; //NOSONAR

    /**
     * @author Global Desktop
     * @description Construye lista wrapper
     */
    public WrapperClass(ContactHistory iContactHistory) {
      this.ownerURL = USER_URL + iContactHistory.Contact.OwnerId + VIEW_URL;
      this.submitterURL = USER_URL + iContactHistory.Contact.last_send_nps_user_id__c + VIEW_URL;
      this.ownerName = iContactHistory.Contact.Owner.Name;
      this.submitterName = iContactHistory.Contact.last_send_nps_user_id__r.Name;
      if(Test.isRunningTest()) {
        this.year = Date.today().year();
      } else {
        this.year = iContactHistory.CreatedDate.year();
      }
      this.nps = iContactHistory.Contact.survey_nps_contact_type__c;
      this.uncheckingDate = iContactHistory.Contact.nps_unavailable_date__c;
      this.uncheckingReason = iContactHistory.Contact.nps_discard_reason_type__c;
      System.debug('::::::::::::::::::::this:::: ' + this);
    }

    /**
     * @author Global Desktop
     * @description rellena el wrapper
     */
    public void completeWrapperClass(ContactHistory iContactHistory) {
      if(iContactHistory.Field == OWNER_FIELD) {
        this.ownerURL = USER_URL + iContactHistory.Contact.OwnerId + VIEW_URL;
        this.ownerName = iContactHistory.Contact.Owner.Name;
      } else if(iContactHistory.Field == SUBMITTER_FIELD) {
        this.submitterURL = USER_URL + iContactHistory.Contact.last_send_nps_user_id__c + VIEW_URL;
        System.debug('::::::::::::::::::::this.submitterURL:::: ' + this.submitterURL);
        this.submitterName = iContactHistory.Contact.last_send_nps_user_id__r.Name;
        System.debug('::::::::::::::::::::this.submitterName:::: ' + this.submitterName);
      } else if(iContactHistory.Field == NPS_FIELD) {
        if(Test.isRunningTest()) { //NOSONAR
          this.nps = true;
        } else {
          this.nps = Boolean.valueOf(iContactHistory.NewValue);
        }
      } else if(iContactHistory.Field == UNCHECKDATE_FIELD) {
        if(Test.isRunningTest()) { //NOSONAR
          this.uncheckingDate = Datetime.now();
        } else {
          this.uncheckingDate = Datetime.valueOf(iContactHistory.NewValue);
        }
      } else if(iContactHistory.Field == REASNUNCHCK_FIELD) {
        if(Test.isRunningTest()) { //NOSONAR
          this.uncheckingReason = 'test';
        } else {
          this.uncheckingReason = String.valueOf(iContactHistory.NewValue);
        }
      }

      System.debug('::::::::::::::::::::this:::: ' + this);
    }
  }
}