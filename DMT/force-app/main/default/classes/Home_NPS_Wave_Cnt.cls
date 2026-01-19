/******************************************************************************
*   @author: GlobalDesktop
*   @Class: Home_NPS_Wave_Test
*   @Description:  Home_NPS_Wave_Cnt - Tests

*   @Versions:
        v1 - 2019/11/06 - Initial version
******************************************************************************/
public with sharing class Home_NPS_Wave_Cnt {
  /**
   * @author Global Desktop
   * @description SINGLETON PATTERN
   */
  private static Home_NPS_Wave_Cnt instance;
  /**
   * @author Global Desktop
   * @description getInstance
   */
  public static Home_NPS_Wave_Cnt getInstance() { //NOSONAR
    if (instance == null) {
      instance = new Home_NPS_Wave_Cnt();
    }
    return instance;
  }
  /**
   * @author Global Desktop
   * @description Empty Constructor
   */
  private Home_NPS_Wave_Cnt() {
  }

  /**
   * Completa el primer formulario de forma dinámica
   */
  @AuraEnabled
    public static list<objectwrapper> completeForm(String objName, String fieldsNamePar) {
      final Map<String, Schema.SObjectType> global_describe = Schema.getGlobalDescribe();
      final Map<String, Schema.SObjectField> object_fields_map = global_describe.get(objName).getDescribe().fields.getMap();
      final list<string> fieldsname = new list<string>();
      final list<string> fieldsapiname = new list<string>();
      for(String str : fieldsNamePar.split(',')) {
         final String apiName = object_fields_map.get(str).getDescribe().getName();
         final String labelName = object_fields_map.get(str).getDescribe().getLabel();
         fieldsapiname.add(apiName);
         fieldsname.add(labelName);
      }

      final list<objectwrapper> wrapList = new list<objectwrapper>();
      for(Integer i = 0; i < fieldsname.size(); i++) {
        final objectwrapper wrap=new objectwrapper();
        wrap.fname=fieldsname[i];
            wrap.fapiname=fieldsapiname[i];
            wrap.fobjectname=objName;
            wrapList.add(wrap);
      }
      return wrapList;
    }

  /**
   * Clase wrapper para devolver campo y valor de cada formulario
   */
  public class objectwrapper {
    /*Nombre del objeto*/
    @AuraEnabled
    public string fobjectname {get; set;}
    /*Nombre del campo*/
    @AuraEnabled
    public string fname {get; set;}
    /*Nombre api del campo*/
    @AuraEnabled
    public string fapiname {get; set;}
    /*Valor del campo*/
    @AuraEnabled
    public string value {get; set;}

    /*Construye el objeto wrapper*/
    public objectwrapper(String fobject,String fname,String fapi, String fvalue) {
      this.fobjectname = fobject;
      this.fname = fname;
      this.fapiname = fapi;
      this.value = fvalue;
    }
    /*Constructor*/
    public objectwrapper() {
    }
  }

  /**
   * Recupera los valores introducidos en el formulario
   */
@AuraEnabled
public static String getData(String dataSet, String oFilter, String fFilter, String rtFilter, String otherFilter) { // NOSONAR

    final List<objectwrapper> oList = (List<objectwrapper>)JSON.deserialize(dataSet, List<objectwrapper>.class);

    final Map<String, String> apivaluesSelect = new Map<String, String>();
    for(objectwrapper owr : oList) {
        apivaluesSelect.put(owr.fapiname, owr.value);
    }

    final Map<String, String> fFilterPar = new Map<String, String>();
    for(String str : fFilter.split(',')) {
        final String left = str.substringBefore('=');
        final String right = str.substringAfter('=');
        fFilterPar.put(right, left);
    }

    final Map<String, String> apiValues = new Map<String, String>();
    for(String key : fFilterPar.keySet()) {
        String value = apivaluesSelect.get(key);
        List<String> valuesList = new List<String>();
        if (fFilterPar.get(key).contains('DES_Segment__c') || fFilterPar.get(key).contains('DES_Tier__c')) {
          for (String eachValue : value.split(';')) {
            valuesList.add(Util_PickList.getAPIFromLabel('Account', fFilterPar.get(key), eachValue));
          }
          value = String.join(valuesList, ';');
        }
        apiValues.put(fFilterPar.get(key), value);
    }

    String result = Home_NPS_Wave_Cnt_Aux.buildQuery(apiValues, oFilter, rtFilter, otherFilter, apivaluesSelect);

    return result;
}

  /**
   * Clase Wrapper para construir el formato de cuentas del treeGrid
   */
  public Class groupWrapper {
    /*Campo Id*/
    @AuraEnabled
    public String id {get; set;} //NOSONAR
    /*Campo nombre*/
    @AuraEnabled
    public String name {get; set;}
    /*Lista de cuentas hija*/
    @AuraEnabled
    public List<Items> items {get; set;}
  }

  /**
   * Clase de las cuentas hija
   */
  public Class Items {
    /*Campo Id*/
    @AuraEnabled
    public String id {get; set;} //NOSONAR
    /*Campo Nombre*/
    @AuraEnabled
    public String name {get; set;}
  }

  /**
   * Clase que construye la wrapper del treeGrid
   */
  public class accountWrapper {
    /*Variable nombre*/
    @AuraEnabled
    public string name {get; set;}
    /*Variable Id*/
    @AuraEnabled
    public string id {get; set;} //NOSONAR
    /**
    * Mapea el Id
    */
    public accountWrapper(String fName, String fId) {
      this.name = fname;
      this.id = fId;
    }
  }

  /**
   * Recupera la información del perímetro NPS
   */
  @AuraEnabled
  public static void getPerimeter(String dataSet, String accSelect) {
    final List<objectwrapper> oList = (List<objectwrapper>)JSON.deserialize(dataSet, List<objectwrapper>.class);
    final Map<String, String> apivaluesSelect = new Map<String, String>();
    for(objectwrapper owr : oList) {
      apivaluesSelect.put(owr.fapiname, owr.value);
    }

    final NPS_Wave__c iWavePerimeter = new NPS_Wave__c();
    for(String key: apivaluesSelect.keySet()) {
      final SObjectType iObject = ((SObject)(Type.forName('Schema.'+'NPS_Wave__c').newInstance())).getSObjectType();
      final DescribeSObjectResult descObject = iObject.getDescribe();
      if(descObject.fields.getMap().get(key).getDescribe().getType() == Schema.DisplayType.Date) {
        if(apivaluesSelect.get(key) != null && !String.isEmpty(apivaluesSelect.get(key)) && !String.isBlank(apivaluesSelect.get(key))) {
          final Date datefield = date.ValueOf(apivaluesSelect.get(key));
          iWavePerimeter.put(key,datefield);
        }
      } else {
        iWavePerimeter.put(key,apivaluesSelect.get(key));
      }
    }

    iWavePerimeter.put('Name', 'NPS perimeter ' + Date.Today().Year());
    iWavePerimeter.put('RecordTypeId', Schema.SObjectType.NPS_Wave__c.getRecordTypeInfosByDeveloperName().get(Label.RT_NPS_Perimeter).getRecordTypeId());

    final Boolean yearHasChanged = Home_NPS_Wave_Cnt_Aux.resetPerimeter();

    final Batch_Update_NPS iBatch = new Batch_Update_NPS(accSelect, yearHasChanged, iWavePerimeter, apivaluesSelect);
    Database.executeBatch(iBatch, 1);
  }

  /**
   * Recupera los países de los países del perímetro
   */
  @AuraEnabled
  public static Map<String, String> getSelectOptions(String objName, String fieldsNamePar) {
    final Map<String, String> allOpts = new Map<String, String>();
    // Get the object type of the SObject.

    final Map<String, Schema.SObjectType> globalDescribe = Schema.getGlobalDescribe();
    final Map<String, Schema.SObjectField> objectFieldsMap = globalDescribe.get(objName).getDescribe().fields.getMap();

    // Get the list of picklist values for this field.
    final List<Schema.PicklistEntry> values =
      objectFieldsMap.get(fieldsNamePar).getDescribe().getPickListValues();

    // Add these values to the selectoption list.
    for (Schema.PicklistEntry a: values) {
      allOpts.put(a.getValue(), a.getLabel());
    }

    final Map<String, String> mapCountry = new Map<String, String>();
    for(Account iAccount : [SELECT Id,
                              survey_nps_contact_type__c,
                              DES_Country_Client__c
                            FROM Account
                            WHERE survey_nps_contact_type__c = true]) {
      if(!mapCountry.containsKey(iAccount.DES_Country_Client__c)) {
        mapCountry.put(iAccount.DES_Country_Client__c, allOpts.get(iAccount.DES_Country_Client__c));
      }
    }

    return mapCountry;
  }

  /**
   * Comprueba si existe o no un perímetro NPS
   */
  @AuraEnabled
  public static Integer checkPerimeter() {
    final List<NPS_Wave__c> listPerimeter = [SELECT Id
                                            FROM NPS_Wave__c
                                            WHERE RecordTypeId = :Schema.SObjectType.NPS_Wave__c.getRecordTypeInfosByDeveloperName().get(Label.RT_NPS_Perimeter).getRecordTypeId()
                                            LIMIT 1];

    final List<AsyncApexJob> listAsyncJob = [SELECT Id,
                                              Status,
                                              ApexClass.Name
                                            FROM AsyncApexJob
                                            WHERE ApexClass.Name = 'Batch_Update_NPS'
                                              AND Status IN ('Holding', 'Queued', 'Preparing', 'Processing')
                                            LIMIT 1];

    Integer iReturn = 0;
    if(listPerimeter.isEmpty() == true
      && listAsyncJob.isEmpty() == true) {
      iReturn = 1;
    } else if(listPerimeter.isEmpty() == true
      && listAsyncJob.isEmpty() == false) {
      iReturn = 2;
    } else if(listPerimeter.isEmpty() == false
      && listAsyncJob.isEmpty() == true) {
      iReturn = 3;
    }

    return iReturn;
  }

  /**
   * Comprueba si existe o no un perímetro NPS
   */
  @AuraEnabled
  public static String checkValidWave(String dataSet2, List<String> dataSet3list) {
    final List<objectwrapper> oList2 = (List<objectwrapper>)JSON.deserialize(dataSet2, List<objectwrapper>.class);

    String ret = 'OK';
    if(dataSet3list.isEmpty()) {
      ret = 'COUNTRY_KO';
    }

    for(objectwrapper owr : oList2) {
      if(owr.value == null || owr.value == '') {
        ret = 'KO';
      }
    }

    return ret;
  }

  /**
   * Recupera la información de las waves
   */
  @AuraEnabled
  @future
  public static void getWaves(String dataSet, String dataSet2, List<String> dataSet3list) {
    final List<Account> listNPSAccount = [SELECT Id,
                                            survey_nps_contact_type__c
                                          FROM Account
                                          WHERE survey_nps_contact_type__c = true];

    final List<Account> npsAccounts = [SELECT Id,
                                        Name
                                      FROM Account
                                      WHERE Id not In (select AccountId from Contact)
                                        AND Id IN: listNPSAccount]; //Los que si tienen contacto

    final NPS_Wave__c iWavePerimeter = [SELECT Id,
                                          gf_nps_sv_cust_prfsnl_seg_desc__c,
                                          gf_nps_survey_cust_tier_desc__c,
                                          gf_nps_sv_cust_rev_ind_type__c
                                        FROM NPS_Wave__c
                                        WHERE RecordTypeId = :Schema.SObjectType.NPS_Wave__c.getRecordTypeInfosByDeveloperName().get(Label.RT_NPS_Perimeter).getRecordTypeId()
                                        LIMIT 1];

    final List<objectwrapper> oList2 = (List<objectwrapper>)JSON.deserialize(dataSet2, List<objectwrapper>.class);
    final Map<String, String> apivaluesSelect = new Map<String, String>();

    apivaluesSelect.put('gf_nps_sv_cust_oper_cntry_desc__c', String.join(dataSet3list, ';'));
    apivaluesSelect.put('gf_nps_survey_cust_tier_desc__c', iWavePerimeter.gf_nps_survey_cust_tier_desc__c);
    apivaluesSelect.put('gf_nps_sv_cust_rev_ind_type__c', iWavePerimeter.gf_nps_sv_cust_rev_ind_type__c);
    apivaluesSelect.put('gf_nps_sv_cust_prfsnl_seg_desc__c', iWavePerimeter.gf_nps_sv_cust_prfsnl_seg_desc__c);

    for(objectwrapper owr : oList2) {
      apivaluesSelect.put(owr.fapiname,owr.value);
    }
    final NPS_Wave__c wave = new NPS_Wave__c();
    for(String key: apivaluesSelect.keySet()) {
      final SObjectType iObject = ((SObject)(Type.forName('Schema.'+'NPS_Wave__c').newInstance())).getSObjectType();
      final DescribeSObjectResult descObject = iObject.getDescribe();
      if(descObject.fields.getMap().get(key).getDescribe().getType() == Schema.DisplayType.Date) {
        if(apivaluesSelect.get(key) != null && !String.isEmpty(apivaluesSelect.get(key)) && !String.isBlank(apivaluesSelect.get(key))) {
          final Date datefield = date.ValueOf(apivaluesSelect.get(key));
          wave.put(key,datefield);
        }
      } else {
        wave.put(key,apivaluesSelect.get(key));
      }
    }

    wave.put('gf_total_customer_number__c', listNPSAccount.size());
    wave.put('gf_customer_wth_cntct_number__c', npsAccounts.size());
    wave.put('gf_customer_wo_cntct_number__c', listNPSAccount.size() - npsAccounts.size());
    wave.put('Name','Nps review contact period ' + Date.Today().Year());

    insert wave;

    final Schema.DescribeFieldResult fieldResult = NPS_Wave__c.gf_nps_sv_cust_oper_cntry_desc__c.getDescribe();
    final List<Schema.PicklistEntry> values = fieldResult.getPicklistValues();
    final Map<String,String> mapValueLabel = new Map<String,String>();
    for( Schema.PicklistEntry v : values) {
        mapValueLabel.put(v.getValue(),v.getLabel());
    }

    final List<NPS_Wave__c> listWaveNPS = new List<NPS_Wave__c>();
    listWaveNPS.add(wave);
    //NPS_Wave_Helper.npsNotification(listWaveNPS, listNPSAccount);

    if(!Test.isRunningTest()) { //NOSONAR
      final Batch_Create_Task_NPS iBatch = new Batch_Create_Task_NPS(wave, listNPSAccount);
      Database.executeBatch(iBatch, 10);
    }
  }

  /**
   * Clase Wrapper para devolver la informacion de la wave
   */
  public Class WaveWrapper {
    /*Variable Id*/
    @AuraEnabled
    public String id {get;set;} //NOSONAR
    /*Variable Name*/
    @AuraEnabled
    public String name {get;set;}
    /*Variable countries*/
    @AuraEnabled
    public String countries {get;set;}
    /*Variable endDate*/
    @AuraEnabled
    public Date endDate {get;set;}
    /*Variable startDate*/
    @AuraEnabled
    public Date startDate {get;set;}
    /*Variable reminderDate*/
    @AuraEnabled
    public Date reminderDate {get;set;}
    /*Variable totalClients*/
    @AuraEnabled
    public String totalClients {get;set;}
    /*Variable npsClients*/
    @AuraEnabled
    public String npsClients {get;set;}
    /*Variable noNpsClients*/
    @AuraEnabled
    public String noNpsClients {get;set;}
  }
}