/******************************************************************************
*   @author: GlobalDesktop
*   @Class: Home_NPS_Wave_Cnt_Aux
*   @Description:  Home_NPS_Wave_Cnt_Aux
*   @Versions:
        v1 - 2019/11/26 - Initial version
******************************************************************************/
public with sharing class Home_NPS_Wave_Cnt_Aux {
  /**
   * @author Global Desktop
   * @description SINGLETON PATTERN
   */
  private static Home_NPS_Wave_Cnt_Aux instance;
  /**
   * @author Global Desktop
   * @description getInstance
   */
  public static Home_NPS_Wave_Cnt_Aux getInstance() { //NOSONAR
    if (instance == null) {
      instance = new Home_NPS_Wave_Cnt_Aux();
    }
    return instance;
  }
  /**
   * @author Global Desktop
   * @description Empty Constructor
   */
  private Home_NPS_Wave_Cnt_Aux() {
    System.debug('Constructor empty');
  }

  /**
   * Aplica el filtro cross a los revenues asociados
   */
  public static Set<Id> otherFilters(Set<Id> accIds, Map<String,String> apivaluesSelect) {
    final set<Id> setIds = new set<Id>();
    for(String ids : accIds) {
      setIds.add(ids); //NOSONAR
    }
    final String countryVal = apivaluesSelect.get('gf_nps_sv_cust_rev_ind_type__c');
    final List<AggregateResult> bookList = [SELECT COUNT(Id), DES_Client__c
                                            FROM DES_Booking__c
                                            WHERE DES_Engloba_Load_Helper__c = '1'
                                              AND DES_Country__c IN :countryVal.split(';')
                                              AND DES_Client__c IN (SELECT participant_child_id__c
                                                                    FROM DES_Subsidiary_Group_Relation__c
                                                                    WHERE participant_parent_id__c IN :accIds)
                                                                    GROUP BY DES_Client__c];
    final Integer remainingRows = Limits.getLimitQueryRows() - Limits.getQueryRows();
    System.debug('::::::::::remainingRows: '  + remainingRows);

    final Set<Id> setIdFilial = new Set<Id>();
    for (AggregateResult iAggResult : bookList) {
      final Id cliente = (Id) iAggResult.get('DES_Client__c');
      setIdFilial.add(cliente);
    }

    return setIdFilial;
  }

  /**
   * Construye query dinamica y parametrizable
   */
  public static String buildQuery(Map<String,String> apiValues, String oFilter, String rtFilter, String otherFilter, Map<String,String> apivaluesSelect) {
    String filter;
    for(String key : apiValues.keySet()) {
      if(apiValues.get(key).contains(';')) {
        Boolean firstEl = true;
        for(String str: apiValues.get(key).split(';')) {
          if(firstEl == true) {
            filter += '(';
            firstEl = false;
          }
          filter += key + '=';
          filter += '\'' + str + '\' OR ';
        }
        filter += ') AND ';
      } else {
        filter += key + '=';
        filter +=  '\'' +  apiValues.get(key) + '\' AND ';
      }
    }
    filter = filter.removeEndIgnoreCase('AND ');
    filter = filter.removeEndIgnoreCase('OR ');
    filter = filter.replace('OR )',')');
    filter = filter.replace(')(',') AND (');
    filter = filter.replace('null','');

    final String query = 'SELECT Id, Name FROM ' + String.escapeSingleQuotes(oFilter) + ' WHERE ' + filter + ' AND RecordType.DeveloperName IN ' + rtFilter;
    System.debug('::::::::::query: ' + query);
    final List<Account> accList = Database.query(query); //NOSONAR
    final Integer remainingRows = Limits.getLimitQueryRows() - Limits.getQueryRows();
    System.debug('::::::::::remainingRows: '  + remainingRows);

    return treeGridInfo(accList, apivaluesSelect);
  }

  /**
   * Recupera los datos a mostrar en el treeGrid
   */
  public static String treeGridInfo(List<Account> accList, Map<String,String> apivaluesSelect) {
    final set<Id> gIds = new set<Id>();
    final Map<String,Account> grupogrupo = new Map<String,Account>();
    for(Account acc : accList) {
      grupogrupo.put(acc.Id, acc);
      gIds.add(acc.Id);
    }

    final List<Home_NPS_Wave_Cnt.groupWrapper> allWrapper = new List<Home_NPS_Wave_Cnt.groupWrapper>();
    for(Account accGrpoup : grupogrupo.values()) {
      final Home_NPS_Wave_Cnt.groupWrapper gWraper = new Home_NPS_Wave_Cnt.groupWrapper();
      gWraper.name = accGrpoup.Name;
      gWraper.id = accGrpoup.Id;
      allWrapper.add(gWraper);
    }

    return JSON.serializePretty(allWrapper);
  }

  /**
   * Resetea el perímetro de la ola
   */
  public static Boolean resetPerimeter() {
    final List<NPS_Wave__c> listPerimeter = [SELECT Id,
                                              CreatedDate
                                            FROM NPS_Wave__c
                                            WHERE RecordTypeId = :Schema.SObjectType.NPS_Wave__c.getRecordTypeInfosByDeveloperName().get(Label.RT_NPS_Perimeter).getRecordTypeId()
                                            LIMIT 1];

    Boolean yearHasChanged = false;

    if(!listPerimeter.isEmpty()) {
      if(listPerimeter[0].CreatedDate.year() != Date.today().year()) {
        yearHasChanged = true;
      }
      delete listPerimeter;
    }

    return yearHasChanged;
  }

  /**
   * Resetea las cuentas del perímetro NPS
   */
  public static void resetNPSAccount(List<Account> accList) { //NOSONAR
    final List<Account> listAccount = new List<Account>();
    for(Account iAccount : [SELECT Id,
                              survey_nps_contact_type__c,
                              NPS_Year_History__c
                            FROM Account
                            WHERE survey_nps_contact_type__c = true
                              AND id IN :accList]) {
      iAccount.survey_nps_contact_type__c = false;
      if(iAccount.NPS_Year_History__c != null) {
        iAccount.NPS_Year_History__c = iAccount.NPS_Year_History__c.replace(String.valueOf(Date.today().year()) + ';', ''); //NOSONAR
      }
      listAccount.add(iAccount);
    }

    if(!listAccount.isEmpty()) {
      update listAccount;
    }
  }

  /**
   * Resetea los contacto de expción NPS
   */
  public static void resetNPSContact() {
    final List<Contact> listContact = new List<Contact>();
    for(Contact iContact : [SELECT Id,
                              survey_nps_contact_type__c
                            FROM Contact
                            WHERE survey_nps_contact_type__c = true]) {
      iContact.survey_nps_contact_type__c = false;
      listContact.add(iContact);
    }

    if(!listContact.isEmpty()) {
      update listContact;
    }
  }

  /**
   * Marca las cuentas del perímetro NPS
   */
  public static void checkNPSAccount(List<Account> listAccount) {
    final List<Account> listAccountUpdate = new List<Account>();
    for(Account iAccount: listAccount) {
      iAccount.survey_nps_contact_type__c = true;
      iAccount.NPS_Year_History__c = iAccount.NPS_Year_History__c == null ? String.valueOf(Date.today().year()) + ';' : iAccount.NPS_Year_History__c + String.valueOf(Date.today().year()) + ';'; //NOSONAR
      listAccountUpdate.add(iAccount);
    }

    if(!listAccountUpdate.isEmpty()) {
      update listAccountUpdate;
    }
  }

  /**
   * Crea la tarea NPS para los owner de los contactos
   */
  /*public static void createNPSTask(List<Account> listNPSAccount, NPS_Wave__c wave) {
    final List<Contact> listContact = new List<Contact>();
    final Map<Id, Account> mapAccount = new Map<Id, Account>([SELECT Id,
                                                                (SELECT Id,
                                                                  OwnerId
                                                                FROM Contacts)
                                                              FROM Account
                                                              WHERE Id IN :listNPSAccount]);

    final map<Id,List<Contact>> accContacts = new map<Id,List<Contact>>();
    for(Account iAccount : listNPSAccount) {
      listContact.addAll(mapAccount.get(iAccount.Id).Contacts);
      accContacts.put(iAccount.Id, mapAccount.get(iAccount.Id).Contacts);
    }

    final Map<Id, Contact> mapOwnerId = new Map<Id, Contact>();
    // final List<Contact> listContacWave = new List<Contact>();
    for(Contact iContact : listContact) {
      if(!mapOwnerId.containsKey(iContact.OwnerId)) {
        mapOwnerId.put(iContact.OwnerId, iContact);
      }
      // listContacWave.add(iContact);
    }

    // if(!listContacWave.isEmpty()) {
    //   update listContacWave;
    // }

    final List<Task> listTask = new List<Task>();
    for(Id iUserId : mapOwnerId.keySet()) {
      final Task iTask = new Task(
        OwnerId = iUserId,
        ActivityDate = wave.gf_nps_survey_cust_send_date__c,
        IsReminderSet = true,
        ReminderDateTime = DateTime.newInstance(wave.gf_nps_survey_cust_send_date__c.year(), wave.gf_nps_survey_cust_send_date__c.month(), wave.gf_nps_survey_cust_send_date__c.day(), 16, 30, 00),
        Status = 'In Progress',
        Subject = 'Remember! Check out you contact for NPS Review Contact Period ' + wave.nps_start_date__c.year() + '. '
      );
      listTask.add(iTask);
    }
    insert listTask;
  }*/

  /**
   * Devuelve todas las olas existentes
   */
  public static List<Home_NPS_Wave_Cnt.WaveWrapper> getAllWaves(List<NPS_Wave__c> waveList, Map<String,String> mapValueLabel) {
    final List<Home_NPS_Wave_Cnt.WaveWrapper> allWaves = new List<Home_NPS_Wave_Cnt.WaveWrapper>();
    for(NPS_Wave__c iWave: waveList) {
      final Home_NPS_Wave_Cnt.WaveWrapper waveWrap = new Home_NPS_Wave_Cnt.WaveWrapper();
      waveWrap.name = iwave.Name;
      if(iWave.gf_nps_sv_cust_oper_cntry_desc__c != null && iWave.gf_nps_sv_cust_oper_cntry_desc__c.contains(';')) {
        for(String str: iWave.gf_nps_sv_cust_oper_cntry_desc__c.split(';')) {
          if(waveWrap.countries == null) {
            waveWrap.countries = mapValueLabel.get(str);
          } else {
            waveWrap.countries = waveWrap.countries + ',' + mapValueLabel.get(str);
          }
        }
      } else if(iWave.gf_nps_sv_cust_oper_cntry_desc__c != null) {
        waveWrap.countries = mapValueLabel.get(iWave.gf_nps_sv_cust_oper_cntry_desc__c);
      }
      waveWrap.endDate = iWave.nps_end_date__c;
      waveWrap.startDate = iWave.nps_start_date__c;
      waveWrap.reminderDate = iWave.gf_nps_survey_cust_send_date__c;
      waveWrap.totalClients = String.valueOf(iWave.gf_total_customer_number__c);
      waveWrap.npsClients = String.valueOf(iWave.gf_customer_wth_cntct_number__c);
      waveWrap.noNpsClients = String.valueOf(iWave.gf_customer_wo_cntct_number__c);
      allWaves.add(waveWrap);
    }

    return allWaves;
  }
   /**
   * carga los usuarios para crear las tareas
   */
  public static void loadNPSTask(Map<Id, Contact> mapOwnerId,List<Account> listNPSAccount, NPS_Wave__c wave) {
    final List<Contact> listContact = new List<Contact>();
    final Map<Id, Account> mapAccount = new Map<Id, Account>([SELECT Id,
                                                                (SELECT Id,
                                                                  OwnerId
                                                                FROM Contacts)
                                                              FROM Account
                                                              WHERE Id IN :listNPSAccount]);

    final map<Id,List<Contact>> accContacts = new map<Id,List<Contact>>();
    for(Account iAccount : listNPSAccount) {
      system.debug('mapAccount.get(iAccount.Id).Contacts==='+mapAccount.get(iAccount.Id).Contacts);
      listContact.addAll(mapAccount.get(iAccount.Id).Contacts);
      accContacts.put(iAccount.Id, mapAccount.get(iAccount.Id).Contacts);
    }

    // final List<Contact> listContacWave = new List<Contact>();
    for(Contact iContact : listContact) {
      if(!mapOwnerId.containsKey(iContact.OwnerId)) {
        mapOwnerId.put(iContact.OwnerId, iContact);
      }
      // listContacWave.add(iContact);
    }

    system.debug('FIN==='+mapOwnerId);
  }
  
   /**
   * Crea los usuarios para crear las tareas
   */
  public static void createAlerts(Map<Id, Contact> mapOwnerId,NPS_Wave__c wave) {
	  
	final List<Task> listTask = new List<Task>();
    for(Id iUserId : mapOwnerId.keySet()) {
      final Task iTask = new Task(
        OwnerId = iUserId,
        ActivityDate = wave.gf_nps_survey_cust_send_date__c,
        IsReminderSet = true,
        ReminderDateTime = DateTime.newInstance(wave.gf_nps_survey_cust_send_date__c.year(), wave.gf_nps_survey_cust_send_date__c.month(), wave.gf_nps_survey_cust_send_date__c.day(), 16, 30, 00),
        Status = 'In Progress',
        Subject = 'Remember! Check out you contact for NPS Review Contact Period ' + wave.nps_start_date__c.year() + '. '
      );
      listTask.add(iTask);
    } 
    insert listTask;
    system.debug('Task Creadas ====='+listTask.size());
  }
}