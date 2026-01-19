/**
* ------------------------------------------------------------------------------------------------
* @Name     DES_Arc_Account_Locator
* -----------------------------------------------------------------------------------------------
* @Description Class "Arc_GBL_Account_Locator"
* -----------------------------------------------------------------------------------------------
*/
@SuppressWarnings('sf:NPathComplexity, sf:CyclomaticComplexity, sf:TooManyMethods')
global without sharing class DES_Arc_Account_Locator implements arce.Arc_Gen_Account_Interface, arce.Arc_Gen_AccountSP2_Interface {

    /**
    * @Description: String with value "Group"
    */
    static final string S_GROUP = 'GROUP';

    /**
    * @Description: String with value "Client"
    */
    static final string CLIENT = 'SUBSIDIARY';

    /**
    * @Description: String with value "NIF"
    */
    static final string NIF = 'NIF';

    /**
    * @Description: String with value "NIF"
    */
    static final string BRANCHID = '9999';
    /**
        * @Description: String with value "Financial statement type"
    */
    private final static String TYPE = '1';
    /**
    * @Description Activity relationship metadata list
    */
    private static Set<String> actRelMdt;

    /**
  * @description
  * @author Global Desktop | 07-30-2020
  * @param listAccountId
  * @return Map<Id, arce.Arc_Gen_Account_Wrapper>
  **/
  public Map<Id, arce.Arc_Gen_Account_Wrapper> getAccountInfoById(List<Id> listAccountId) {
    Map<Id,arce.Arc_Gen_Account_Wrapper> mapWrapper = new Map<Id,arce.Arc_Gen_Account_Wrapper>();
    try {
      final List<Id> standardAccounts = new List<Id>();
      final List<Id> customAccounts = new List<Id>();
      for(Id someId: listAccountId) {
        if(someId.getSObjectType().getDescribe().getName() == 'Account'){
          standardAccounts.add(someId);
          System.debug('--------> Account: ' + someId);
        } else {
          customAccounts.add(someId);
          System.debug('---------> CustomAccount: ' + someId);
        }
      }
      if(!standardAccounts.isEmpty()) {
        mapWrapper = completeProspect(mapWrapper, standardAccounts);
      }
      if(!customAccounts.isEmpty()) {
        mapWrapper = completeLocal(mapWrapper, customAccounts);
      }
      //Fin -- Adaptación para Custom Account

    } catch(Exception ex) {
      final arce.Arc_Gen_Account_Wrapper wrapper = new arce.Arc_Gen_Account_Wrapper();
      wrapper.error = ex.getMessage();
      mapWrapper.put(null, wrapper);
    }
    return mapWrapper;
  }

  /**
  * @description
  * @author Global Desktop | 07-30-2020
  * @param listAccountNum
  * @return Map<String, Arc_Gen_Account_Wrapper>
  **/
  public Map<String, arce.Arc_Gen_Account_Wrapper> getAccountByAccNumber(List<String> listAccountNum) {
    final Map<String, arce.Arc_Gen_Account_Wrapper> mapWrapper = new Map<String, arce.Arc_Gen_Account_Wrapper>();
    System.debug('>>>>>>>>>>>>>>> Entra getAccountByAccNumber');
    try {
      final List<Account> lstProps = [
        SELECT Id, Name, gf_customer_prospect_id__c, DES_Country_Client__c, DES_ID_Fiscal__c,GDT_Delegation__c, g_country_subdivision_id__c,
        DES_Entity_Hierarchy__c, OwnerId, participant_id__c, gf_cust_orig_prospect_ind_type__c, DES_Activity__c, gf_data_institution_type_name__c,
        (select local_customer_id__c, taxpayer_id__c from Local_Clients__r LIMIT 1)
        FROM Account
        WHERE gf_customer_prospect_id__c IN: listAccountNum AND gf_customer_prospect_id__c != '' AND gf_customer_prospect_id__c != null
      ];
      if(lstProps != null && !lstProps.isEmpty()) {
        for(Account acc : lstProps) {
          final arce.Arc_Gen_Account_Wrapper wrapper = new arce.Arc_Gen_Account_Wrapper();
          wrapper.accId = acc.Id;
          wrapper.accNumber = acc.gf_customer_prospect_id__c;
          wrapper.name = acc.Name;
          wrapper.bankId = getBankId(acc.DES_Country_Client__c);
          wrapper.participantType = acc.DES_Entity_Hierarchy__c == null ? CLIENT : acc.DES_Entity_Hierarchy__c == 'S' ? S_GROUP : CLIENT;
          wrapper.docType = NIF;
          wrapper.docNumber = acc.DES_ID_Fiscal__c == null ? BRANCHID : acc.DES_ID_Fiscal__c;
          wrapper.participantOwnerId = acc.OwnerId;
          wrapper.accParentId = acc.participant_id__c;
          wrapper.branchId = BRANCHID;
          wrapper.country = acc.DES_Country_Client__c;
          wrapper.globalId = wrapper.accNumber; // Alpha code
          wrapper.isProspect = acc.gf_cust_orig_prospect_ind_type__c;
          wrapper.econActSector = Util_PickList.getLabelFromAPI('Account', 'DES_Activity__c').get(acc.DES_Activity__c);
          wrapper.delegationId = acc.GDT_Delegation__c;
          wrapper.isIFISClient = isIfisClient(wrapper.econActSector);
          wrapper.countrySubdivision  = acc.g_country_subdivision_id__c;
          if(!acc.Local_Clients__r.isEmpty()) {
              wrapper.goldenId = acc.Local_Clients__r[0].local_customer_id__c;
              wrapper.taxpayerId = acc.Local_Clients__r[0].taxpayer_id__c;
          }
          mapWrapper.put(acc.gf_customer_prospect_id__c, wrapper);
        }
      }
      final List<Local_Client__c> lstAcc = [
        SELECT Id, Name, Cib_Client__c, Cib_Client__r.GDT_Delegation__c, Cib_Client__r.DES_Activity__c, Cib_Client__r.business_group_header_type__c, Cib_Client__r.account_group__c, Cib_Client__r.account_client__c, country_id__c, g_residence_country_id__c, Alpha_code__c,taxpayer_id__c,  Cib_Client__r.DES_Entity_Hierarchy__c, OwnerId, Booking_country_code__c, gf_prtcpt_act_status_ind_type__c, entity_id__c, local_customer_id__c,gf_data_institution_type_name__c, Cib_Client__r.DES_Subsidiary_Group_Code__c
        FROM Local_Client__c
        WHERE Alpha_Code__c IN: listAccountNum AND gf_prtcpt_act_status_ind_type__c = true
      ];
      final Map<String, String> mapEntityType = getEntityType(lstAcc);
      if(lstAcc != null && !lstAcc.isEmpty()) {
        for(Local_Client__c loc : lstAcc) {
          switch on loc.entity_id__c {
            when '0182','0074','0013','0011','0017','7714','0069','9120' {
              final arce.Arc_Gen_Account_Wrapper wrapper = new arce.Arc_Gen_Account_Wrapper();
              wrapper.accId = loc.Cib_Client__c;
              wrapper.accNumber = loc.Alpha_code__c;
              wrapper.name = loc.Name;
              wrapper.bankId = loc.Alpha_code__c == null ? '' :  loc.Alpha_code__c.subString(2,6);
              wrapper.participantType = loc.Cib_Client__r.business_group_header_type__c == true ?  S_GROUP   :  CLIENT;
              wrapper.docType = loc.taxpayer_id__c == null ? null : NIF;
              wrapper.docNumber = loc.taxpayer_id__c;
              wrapper.participantOwnerId = loc.OwnerId;
              wrapper.accParentId = loc.Cib_Client__c;
              wrapper.branchId = BRANCHID;
              wrapper.customAccount = loc.Id;
              wrapper.lookupName = 'DES_Local_Client__c';
              wrapper.country = loc.g_residence_country_id__c;
              wrapper.globalId = wrapper.accNumber; // Alpha code
              wrapper.bookingCountry = loc.Booking_country_code__c;
              wrapper.isProspect = false;
              wrapper.econActSector = Util_PickList.getLabelFromAPI('Account', 'DES_Activity__c').get(loc.Cib_Client__r.DES_Activity__c);
              wrapper.isIFISClient = isIfisClient(wrapper.econActSector);
              wrapper.goldenId = loc.local_customer_id__c;
              wrapper.delegationId = loc.Cib_Client__r.GDT_Delegation__c;
              wrapper.taxpayerId = loc.taxpayer_id__c;
              wrapper.entityType = mapEntityType.containsKey(loc.Alpha_code__c) ? mapEntityType.get(loc.Alpha_code__c) : 'ENTITY';
              wrapper.groupCode = loc.Cib_Client__r.DES_Subsidiary_Group_Code__c;
              wrapper.bankEntity = loc.gf_data_institution_type_name__c;
              mapWrapper.put(loc.Alpha_Code__c, wrapper);
            }
          }
        }
      }
    } catch(Exception ex) {
      final arce.Arc_Gen_Account_Wrapper wrapper = new arce.Arc_Gen_Account_Wrapper();
      wrapper.error = ex.getMessage();
      mapWrapper.put(null, wrapper);
    }
    return mapWrapper;
  }

  /**
  * @description
  * @author Global Desktop | 07-30-2020
  * @param searchWord
  * @return List<arce.Arc_Gen_Account_Wrapper>
  **/
  public List<arce.Arc_Gen_Account_Wrapper> accountsForLookup(String searchWord) {
    final List<arce.Arc_Gen_Account_Wrapper> lstAccWrapper = new List<arce.Arc_Gen_Account_Wrapper>();
    final String searchQuery = 'FIND \'' + String.escapeSingleQuotes(searchWord) + '\' IN ALL FIELDS RETURNING Local_Client__c (id, participant_name__c, OwnerId)';
    final List < List < Local_Client__c >> accountsforshow = search.query(searchQuery);
    System.debug('>>>>>>>>>>>>>>> Entra accountsForLookup');
    if (accountsforshow != null && !accountsforshow.isEmpty()) {
      for(Local_Client__c acc : accountsforshow[0]) {
        final arce.Arc_Gen_Account_Wrapper wrapper = new arce.Arc_Gen_Account_Wrapper();
        wrapper.accId = acc.Id;
        wrapper.name = acc.participant_name__c;
        //wrapper.participantOwnerId = acc.OwnerId;
        wrapper.participantOwnerId = UserInfo.getUserId();
        lstAccWrapper.add(wrapper);
      }
    }
    final String searchQueryProps = 'FIND \'' + String.escapeSingleQuotes(searchWord) + '\' IN ALL FIELDS RETURNING Account (id, Name, OwnerId)';
    final List < List < Account >> prospforshow = search.query(searchQueryProps);
    if (prospforshow != null && !prospforshow.isEmpty()) {
      for(Account acc : prospforshow[0]) {
        final arce.Arc_Gen_Account_Wrapper wrapper = new arce.Arc_Gen_Account_Wrapper();
        wrapper.accId = acc.Id;
        wrapper.name = acc.Name;
        //wrapper.participantOwnerId = acc.OwnerId;
        wrapper.participantOwnerId = UserInfo.getUserId();
        lstAccWrapper.add(wrapper);
      }
    }
    return lstAccWrapper;
  }

  /**
  * @description
  * @author Global Desktop | 07-30-2020
  * @param lstAccUp
  * @return arce.Arc_Gen_ServiceAndSaveResponse
  **/
  private static Account putFieldsFromMap(Account acc, Map<String, Object> mapValues) {
        for (String fieldName : mapValues.keySet()) {
            acc.put(fieldName, mapValues.get(fieldName));
        }
        return acc;
  }


  /**
  * @description
  * @author Global Desktop | 07-30-2020
  * @param lstAccUp
  * @return arce.Arc_Gen_ServiceAndSaveResponse
  **/
  public static arce.Arc_Gen_ServiceAndSaveResponse accountUpdate(Map<Id, Map<String,Object>> lstAccUp) {
    final arce.Arc_Gen_ServiceAndSaveResponse result = new arce.Arc_Gen_ServiceAndSaveResponse();
        final List<Account> lstUp = new List<Account>();

        final DES_Arc_Account_Locator accLoc = new DES_Arc_Account_Locator();
        final Map<Id, arce.Arc_Gen_Account_Wrapper> localAccounts = accLoc.getAccountInfoById(new List<Id>(lstAccUp.keySet()));


        for (Id accId : lstAccUp.keySet()) {
            if(localAccounts.containsKey(accId)){
                final Id accParentId = localAccounts.get(accId).accParentId;
                Account accUp = new Account(Id = accParentId);
                accUp = putFieldsFromMap(accUp, lstAccUp.get(accId));
                lstUp.add(accUp);
            }
        }
        try {
            final List<Database.SaveResult> sare = database.update(lstUp);
            result.saveMessage = Json.serialize(sare);
        } catch (Exception ex) {
            result.saveStatus = 'false';
            result.saveMessage = ex.getMessage();
        }
        return result;
  }

  /**
  * @description
  * @author Global Desktop | 07-30-2020
  * @param accAttr
  * @return arce.Arc_Gen_ServiceAndSaveResponse
  **/
  public static arce.Arc_Gen_ServiceAndSaveResponse createGroup(Map<String,Object> accAttr) {
    return new arce.Arc_Gen_ServiceAndSaveResponse(); //NOSONAR
  }

  /**
  * @description
  * @author Global Desktop | 02-25-2021
  * @param country
  * @param countryGlobal
  * @param cclient
  * @param soloEntity
  * @return String
  **/
  private static String getBankId(String country) {
    String bankId= '';
    switch on country {
      when 'ES' {
        bankId='0182';
      }
      when 'MX' {
        bankId='0074';
      }
      when 'CO' {
        bankId='0013';
      }
      when 'PE' {
        bankId='0011';
      }
      when 'AR' {
        bankId='0017';
      }
      when 'PY' {
        bankId='7714';
      }
      when 'CH ' {
        bankId='0069';
      }
      when else {
        bankId='0182';
      }
    }
    return bankId;
  }

  /**
  *-------------------------------------------------------------------------------
  * @description  Method "getGroupStructure" gets local group Structure. (temporal)
  --------------------------------------------------------------------------------
  * @author jordana.contractor@bbva.com | 29/04/2022
  * @param String accNumber
  * @return   Map with list of Local Ids
  * @example Map<String, List<String>> getGroupStructure(AccNumber);
  **/
  global static Map<String, List<String>> getGroupStructure(String accNumber) {
    final Map<String, List<String>> toRtn = DES_Arc_Account_Hierarchy.headerFinder(accNumber);
    return toRtn;
  }

  /**
  * @description
  * @author Global Desktop | 02-25-2021
  * @param country
  * @param countryGlobal
  * @param cclient
  * @param soloEntity
  * @return String
  **/
  private static Map<Id,arce.Arc_Gen_Account_Wrapper> completeProspect(Map<Id,arce.Arc_Gen_Account_Wrapper> mapWrap, List<Id> standardAccounts) {
    final Map<Id,arce.Arc_Gen_Account_Wrapper> mapWrapper = mapWrap;
    final List<Account> lstProps = [
      SELECT Id, Name, DES_Group_Code__c, gf_customer_prospect_id__c, DES_Country_Client__c, DES_ID_Fiscal__c,GDT_Delegation__c, g_country_subdivision_id__c,
      DES_Entity_Hierarchy__c, OwnerId, participant_id__c, gf_cust_orig_prospect_ind_type__c, DES_Activity__c, gf_data_institution_type_name__c,
      (select local_customer_id__c, taxpayer_id__c, gf_data_institution_type_name__c from Local_Clients__r LIMIT 1),
      (select id from dwp_acmh__Accounts_Relationships1__r)
      FROM Account WHERE Id =: standardAccounts
    ];

    for(Account acc : lstProps) {
      final arce.Arc_Gen_Account_Wrapper wrapper = new arce.Arc_Gen_Account_Wrapper();
      wrapper.accId = acc.Id;
      wrapper.accNumber = acc.gf_customer_prospect_id__c;
      wrapper.name = acc.Name;
      wrapper.bankId = getBankId(acc.DES_Country_Client__c);
      wrapper.participantType = acc.DES_Entity_Hierarchy__c == null ? CLIENT : acc.DES_Entity_Hierarchy__c == 'S' ? S_GROUP : CLIENT;
      wrapper.docType = NIF;
      wrapper.docNumber = acc.DES_ID_Fiscal__c == null ? BRANCHID : acc.DES_ID_Fiscal__c;
      wrapper.participantOwnerId = acc.OwnerId;
      wrapper.accParentId = acc.participant_id__c;
      wrapper.branchId = BRANCHID;
      wrapper.country = acc.DES_Country_Client__c;
      wrapper.globalId = wrapper.accNumber; // Alpha code
      wrapper.parentSubsidiary = getTypes(acc.DES_Entity_Hierarchy__c, acc.dwp_acmh__Accounts_Relationships1__r);
      wrapper.isProspect = acc.gf_cust_orig_prospect_ind_type__c;
      wrapper.econActSector = Util_PickList.getLabelFromAPI('Account', 'DES_Activity__c').get(acc.DES_Activity__c);
      wrapper.isIFISClient = isIfisClient(wrapper.econActSector);
      wrapper.partOwnerIsActive = true;
      wrapper.countrySubdivision  = acc.g_country_subdivision_id__c;
      wrapper.groupCode = acc.DES_Group_Code__c;
      if(!acc.Local_Clients__r.isEmpty()) {
        wrapper.bankEntity = acc.Local_Clients__r[0].gf_data_institution_type_name__c;
        wrapper.goldenId = acc.Local_Clients__r[0].local_customer_id__c;
        wrapper.taxpayerId = acc.Local_Clients__r[0].taxpayer_id__c;
      }
      wrapper.delegationId = acc.GDT_Delegation__c;
      mapWrapper.put(acc.Id, wrapper);
    }
    return mapWrapper;
  }

  /**
  * @description
  * @author Global Desktop | 02-25-2021
  * @param country
  * @param countryGlobal
  * @param cclient
  * @param soloEntity
  * @return String
  **/
  private static Map<Id,arce.Arc_Gen_Account_Wrapper> completeLocal(Map<Id,arce.Arc_Gen_Account_Wrapper> mapWrap, List<Id> customAccounts) {
    final Map<Id,arce.Arc_Gen_Account_Wrapper> mapWrapper = mapWrap;
    final List<Local_Client__c> lstAcc = [
      SELECT Id, Name, Cib_Client__c, Booking_country_code__c, Cib_Client__r.business_group_header_type__c, Cib_Client__r.GDT_Delegation__c, Cib_Client__r.DES_Activity__c, Alpha_code__c, country_id__c, g_residence_country_id__c, taxpayer_id__c,  Cib_Client__r.DES_Entity_Hierarchy__c, OwnerId, gf_prtcpt_act_status_ind_type__c, entity_id__c, local_customer_id__c, Cib_Client__r.account_group__c, Cib_Client__r.account_client__c, Cib_Client__r.DES_Main_Parent__c, Cib_Client__r.DES_Subsidiary_Group_Code__c,gf_data_institution_type_name__c
      FROM Local_Client__c WHERE Id =: customAccounts AND gf_prtcpt_act_status_ind_type__c = true
    ];
    final Map<String, String> mapEntityType = getEntityType(lstAcc);
    final List<id> parentIds = new List<Id>();
    for (Local_Client__c acc : lstAcc) {
      parentIds.add(acc.Cib_Client__c);
    }

    final List<dwp_acmh__GBL_Account_Relationship__c > parentGroup =
      [select id, dwp_acmh__Child_Account__c
      from dwp_acmh__GBL_Account_Relationship__c
      where dwp_acmh__Child_Account__c =: parentIds
      AND dwp_acmh__Parent_Account__r.account_group__c = '3'];

      final Map<Id, List<dwp_acmh__GBL_Account_Relationship__c>> accRelMap = new Map<Id, List<dwp_acmh__GBL_Account_Relationship__c>>();
      for(dwp_acmh__GBL_Account_Relationship__c rel : parentGroup) {
        if(!accRelMap.containsKey(rel.dwp_acmh__Child_Account__c)) {
          accRelMap.put(rel.dwp_acmh__Child_Account__c, new List<dwp_acmh__GBL_Account_Relationship__c>());
        }
        accRelMap.get(rel.dwp_acmh__Child_Account__c).add(rel);
      }

    for(Local_Client__c loc : lstAcc) {
      switch on loc.entity_id__c {
        when '0182','0074','0013','0011','0017','7714','0069','9120' {
          final arce.Arc_Gen_Account_Wrapper wrapper = new arce.Arc_Gen_Account_Wrapper();
          wrapper.accId = loc.Cib_Client__c;
          wrapper.accNumber = loc.Alpha_code__c;
          wrapper.name = loc.Name;
          wrapper.bankId = loc.Alpha_code__c == null ? '' :  loc.Alpha_code__c.subString(2,6);
          wrapper.participantType = loc.Cib_Client__r.business_group_header_type__c == true ?  S_GROUP   :  CLIENT;
          wrapper.docType = loc.taxpayer_id__c == null ? null : NIF;
          wrapper.docNumber = loc.taxpayer_id__c;
          wrapper.participantOwnerId = loc.OwnerId;
          wrapper.accParentId = loc.Cib_Client__c;
          wrapper.branchId = BRANCHID;
          wrapper.customAccount = loc.Id;
          wrapper.lookupName = 'DES_Local_Client__c';
          wrapper.country = loc.g_residence_country_id__c;
          wrapper.bookingCountry = loc.Booking_country_code__c;
          wrapper.globalId = wrapper.accNumber; // Alpha code
          wrapper.parentSubsidiary = getTypes(loc.Cib_Client__r.DES_Entity_Hierarchy__c, accRelMap.containsKey(loc.Cib_Client__c)?accRelMap.get(loc.Cib_Client__c): null);
          wrapper.isProspect = false;
          wrapper.econActSector = Util_PickList.getLabelFromAPI('Account', 'DES_Activity__c').get(loc.Cib_Client__r.DES_Activity__c);
          wrapper.isIFISClient = isIfisClient(wrapper.econActSector);
          wrapper.goldenId = loc.local_customer_id__c;
          wrapper.delegationId = loc.Cib_Client__r.GDT_Delegation__c;
          wrapper.taxpayerId = loc.taxpayer_id__c;
          wrapper.partOwnerIsActive = true;
          wrapper.groupCode = loc.Cib_Client__r.DES_Subsidiary_Group_Code__c;
          wrapper.groupId = loc.Cib_Client__r.DES_Main_Parent__c;
          wrapper.entityType = mapEntityType.containsKey(loc.Alpha_code__c) ? mapEntityType.get(loc.Alpha_code__c) : 'ENTITY';
          wrapper.bankEntity = loc.gf_data_institution_type_name__c;
          wrapper.isIFISClientRTC = isIfisClientRTC(wrapper.bankEntity);
          mapWrapper.put(loc.Id, wrapper);
        }
      }
    }
    return mapWrapper;
  }
    
  /**
    *-------------------------------------------------------------------------------
    * @description  Method "isIfisClient" that retrieves if an account is a IFIS
    *-------------------------------------------------------------------------------
    * @author hectorjeshua.vasquez.contractor@bbva.com
    * @date 12-07-2023
    * @param string actSector
    * @return   Boolean
    * @example Boolean isClient = Arc_GBL_Account_Locator.isIfisClient(actSector);
    **/
    /*private static Boolean isIfisClientlcl(List<String> accountIds) {
      Boolean isIfisClient = false;
        final List<Local_Client__c> lcList = [SELECT id, Cib_Client__c, Alpha_code__c  FROM Local_Client__c WHERE id IN: accountIds LIMIT 1];
      if (!lcList.isEmpty()) {
        final List<Account> accList = [SELECT id, DES_Activity__c FROM Account WHERE Id =: lcList[0].Cib_Client__c LIMIT 1];
        final List<arce__IFIS_Activity_relationship__mdt> relat = [select arce__IFIS_ActivitySector__c from arce__IFIS_Activity_relationship__mdt where arce__IFIS_ActivitySector__c =: accList[0].DES_Activity__c];
        if(relat.size() == 0) {
          isIfisClient = false;
        } else {
          isIfisClient = true;
        }
      }
      return isIfisClient;
  }*/
    
   /**
    *-------------------------------------------------------------------------------
    * @description  Method "isIfisClient" that retrieves if an account is a IFIS
    *-------------------------------------------------------------------------------
    * @author hectorjeshua.vasquez.contractor@bbva.com
    * @date 12-07-2023
    * @param string actSector
    * @return   Boolean
    * @example Boolean isClient = Arc_GBL_Account_Locator.isIfisClient(actSector);
    **/
   /* private static Boolean isIfisClient(List<String> accountNumber) {
      Boolean isIfisClient = false;
        final List<Account> accList = [SELECT id, DES_Activity__c FROM Account WHERE Id IN: accountNumber LIMIT 1];
      if (!accList.isEmpty()) {
        final List<arce__IFIS_Activity_relationship__mdt> relat = [select arce__IFIS_ActivitySector__c from arce__IFIS_Activity_relationship__mdt where arce__IFIS_ActivitySector__c =: accList[0].DES_Activity__c];
        if(relat.size() == 0) {
          isIfisClient = false;
        } else {
          isIfisClient = true;
        }
      }
      return isIfisClient;
  }*/

  /**
    *-------------------------------------------------------------------------------
    * @description  Method "isIfisClient" that retrieves if an account is a IFIS
    *-------------------------------------------------------------------------------
    * @author hectorjeshua.vasquez.contractor@bbva.com
    * @date 12-07-2023
    * @param string actSector
    * @return   Boolean
    * @example Boolean isClient = Arc_GBL_Account_Locator.isIfisClient(actSector);
    **/
  private static Boolean isIfisClient(String econActSec) {
      if(actRelMdt == null) {
        actRelMdt = new Set<String>();
        for(arce__IFIS_Activity_relationship__mdt arMDT: [select arce__IFIS_ActivitySector__c from arce__IFIS_Activity_relationship__mdt]) {
          actRelMdt.add(arMDT.arce__IFIS_ActivitySector__c);
        }
      }
      return actRelMdt.contains(econActSec);
    }
  /**
  *-------------------------------------------------------------------------------
  * @description  Method "getRatingGCPByAccountNumber" retrieves Financial statement By Accnumbers
  --------------------------------------------------------------------------------
  * @author Global Desktop
  * @date 2021-05-26
  * @param List<String> accountNumber
  * @return   Map<String,arce__Financial_Statements__c>
  * @example Map<String,arce__Financial_Statements__c> list =  getRatingGCPByAccountNumber(List<String> accountNumber)
  **/
  public  Map<String,arce__Financial_Statements__c> getRatingGCPByAccountNumber (List<String> accountNumber) {
    // OBSOLETO
    return new Map<String, arce__Financial_Statements__c>();
  }

  /**
  *-------------------------------------------------------------------------------
  * @description  Method "getRatingGCPByAccountNumber" retrieves Financial statement By Accnumbers for RTC Flows
  --------------------------------------------------------------------------------
  * @author Global Desktop
  * @date 2023-11-29
  * @param Map<String, Object> mapInfo
  * @return   Map<String,arce__Financial_Statements__c>
  * @example Map<String,arce__Financial_Statements__c> list =  getRatingGCPByAccountNumber(Map<String, Object> mapInfo)
  **/
    public  Map<String,arce__Financial_Statements__c> getRatingGCPByAccountNumber (Map<String, Object> mapInfo) {
    final Map<String, String> mapParentIds = new Map<String, String>();

    final List<String> accountNumber = (List<String>) mapInfo.get('accountNumberList');
      final Map<String, arce.Arc_Gen_Account_Wrapper> accWrappers = getAccountByAccNumber(accountNumber);
      List<String> localIds = new List<String>();
      for (String current : accWrappers.keySet()) {
          localIds.add((String)accWrappers.get(current).customAccount);
      }

      final List<String> rating = getRARList(mapInfo, 'rating');
      final List<String> preRating = getRARList(mapInfo, 'preRating');

      if (Schema.sObjectType.arce__Account_has_Analysis__c.isAccessible()) {
        for (arce__Account_has_Analysis__c aha :
            [SELECT Id, arce__CustomAccountID__c
            FROM arce__Account_has_Analysis__c
            WHERE arce__CustomAccountID__c IN :localIds
            AND arce__Analysis__r.arce__Stage__c = '3'
            AND arce__Analysis__r.arce__wf_status_id__c = '13'
            AND ((arce__Analysis__r.arce__rating_prerating_type__c = 'Rating'    AND arce__RAR_rating_tool_id__c IN :rating)
              OR (arce__Analysis__r.arce__rating_prerating_type__c = 'Prerating' AND arce__RAR_rating_tool_id__c IN :preRating))
            AND arce__g_rtg_tool_typ_id__c != 'Clone'
            WITH SYSTEM_MODE
            ORDER BY CreatedDate DESC]) {
            final String toCompare = mapParentIds.get(aha.arce__CustomAccountID__c);
            if (String.isBlank(toCompare)) {
                mapParentIds.put(aha.arce__CustomAccountID__c, aha.Id);
            }
        }
      }
      return getFinancialStatementByAha(mapParentIds.values());
    }

    /**
    *-------------------------------------------------------------------------------
    * @description  Method "getRatingGCPByAccountNumber" gets account wrapper filtered by searchWord
    *--------------------------------------------------------------------------------
    * @author alberto.martinez.carrero.next@bbva.com
    * @date 2023-11-28
    * @param Map<String, Object> mapInfo
    * @return Map with Financial Statement
    **/
    @SuppressWarnings('sf:AvoidSoqlWithNegativeLogic')
    public Map<String, List<arce__Financial_Statements__c>> getRatingsForProposal(Map<String, Object> mapInfoProp) {
        final Map<String, List<String>> mapParentIds = new Map<String, List<String>>();
        Map<String, Object> mapInfo = (Map<String, Object>) mapInfoProp.get('getRatingsForProposal');
        if (Schema.sObjectType.arce__Account_has_Analysis__c.isAccessible()) {
            final List<String> accountNumber = (List<String>) mapInfo.get('accountNumberList');
            final Map<String, arce.Arc_Gen_Account_Wrapper> accWrappers = getAccountByAccNumber(accountNumber);
            List<String> localIds = new List<String>();
            for (String current : accWrappers.keySet()) {
                localIds.add((String)accWrappers.get(current).customAccount);
            }
            final List<String> rating = getRARList(mapInfo, 'rating');
            final List<String> preRating = getRARList(mapInfo, 'preRating');

            for (arce__Account_has_Analysis__c aha :
                    [SELECT Id, arce__CustomAccountID__c,
                    DES_Local_Client__r.Alpha_code__c
                    FROM arce__Account_has_Analysis__c
                    WHERE arce__CustomAccountID__c IN :localIds
                    AND arce__Analysis__r.arce__Stage__c = '3'
                    AND arce__Analysis__r.arce__wf_status_id__c = '13'
                    AND ((arce__Analysis__r.arce__rating_prerating_type__c = 'Rating'    AND arce__RAR_rating_tool_id__c IN :rating)
                      OR (arce__Analysis__r.arce__rating_prerating_type__c = 'Prerating' AND arce__RAR_rating_tool_id__c IN :preRating))
                    AND arce__g_rtg_tool_typ_id__c != 'Clone'
                    WITH SYSTEM_MODE
                    ORDER BY CreatedDate DESC]) {
                List<String> newList = new List<String>();
                final List<String> toCompare = mapParentIds.get(aha.DES_Local_Client__r.Alpha_code__c);
                if (toCompare == null || toCompare.isEmpty()) {
                    newList.add(aha.Id);
                    mapParentIds.put(aha.DES_Local_Client__r.Alpha_code__c, newList);
                } else {
                    newList = mapParentIds.get(aha.DES_Local_Client__r.Alpha_code__c);
                    newList.add(aha.Id);
                    mapParentIds.put(aha.DES_Local_Client__r.Alpha_code__c, newList);
                }
            }
        }
        return getFinancialStatementListByAha(mapParentIds);
    }

    /**
     *-------------------------------------------------------------------------------
    * @description Return the RAR List by rating type
    *--------------------------------------------------------------------------------
    * @author francisco.munoz.torres.tech@bbva.com
    * @date 2025-19-03
    * @param Map<String, Object> mapInfo
    * @param String ratingType
    * @return  List<String>
    **/
    private static List<String> getRARList(Map<String, Object> mapInfo, String ratingType) {
    List<String> rarList = new List<String>();

    if (mapInfo.containsKey(ratingType)) {
        final Map<String, List<String>> ratingTypeInfo = (Map<String, List<String>>) mapInfo.get(ratingType);
        if (ratingTypeInfo.containsKey('RARRatingTools')) {
            rarList = ratingTypeInfo.get('RARRatingTools');
        }
    }
    return rarList;
    }

  /**
    *-------------------------------------------------------------------------------
    * @description  Method "getFinancialStatementByAha" retrieves Financial statement By Accnumbers
    --------------------------------------------------------------------------------
    * @author alexander.munguia.contractor@bbva.com
    * @date 2021-03-17
    * @param Set<String> ahaId
    * @param String condition
    * @return   Map<String,arce__Financial_Statements__c>
    **/
    private static Map<String, arce__Financial_Statements__c> getFinancialStatementByAha (List<String> ahaId) {
      final Map<String, arce__Financial_Statements__c> result = new Map<String, arce__Financial_Statements__c>();

        if (Schema.sObjectType.arce__Financial_Statements__c.isAccessible() &&
            Schema.sObjectType.arce__account_has_analysis__c.isAccessible() &&
            Schema.sObjectType.Local_client__c.isAccessible() &&
            ahaId.size() > 0) {

            final Map<String, Id> customAccId = new Map<String, Id>();
            for(arce__account_has_analysis__c aha: [select id, arce__CustomAccountID__c FROM arce__account_has_analysis__c where id in: ahaId ORDER BY CreatedDate DESC]){
                if(!customAccId.containsKey(aha.arce__CustomAccountID__c)) {
                    customAccId.put(aha.arce__CustomAccountID__c, aha.id);
                }
            }

            final Map<String, String> customAccAplphaMap = new Map<String, String>();
            for(Local_client__c lc : [select id, Alpha_code__c FROM Local_client__c WHERE id in: customAccId.keySet()]){
                customAccAplphaMap.put(customAccId.get(lc.id), lc.Alpha_code__c);
            }

        for (arce__Financial_Statements__c ffee :
                [SELECT Id,
                arce__total_rating_score_number__c,
                arce__financial_statement_id__c,
                arce__financial_statement_start_date__c,
                arce__financial_statement_end_date__c,
                arce__rating_final__c,
                arce__account_has_analysis_id__r.DES_Local_Client__r.Alpha_code__c,
                arce__account_has_analysis_id__r.arce__total_rating_score_number__c,
                arce__rating_id__r.arce__rating_long_value_type__c,
                arce__rating_id__r.arce__rating_short_value_type__c,
                arce__account_has_analysis_id__r.arce__short_rating_value_type__c,
                arce__account_has_analysis_id__r.arce__long_rating_value_type__c,
                arce__rar_rating_tool_id__c,
                arce__rating_id__r.arce__rating_id__c,
                arce__account_has_analysis_id__r.arce__Analysis__r.arce__end_date__c
                FROM arce__Financial_Statements__c
                WHERE arce__account_has_analysis_id__c IN: ahaId
                AND arce__ffss_submitted_type__c =: TYPE
                AND arce__ffss_valid_type__c =: TYPE
                AND arce__rating_id__c != null
                ORDER BY CreatedDate DESC]) {

                final String alpha = customAccAplphaMap.get(ffee.arce__account_has_analysis_id__c);
                if(alpha != null){
                    if(!result.containsKey(alpha)) {
                        result.put(alpha, ffee);
                    }
                }
            }
        }
        return result;
    }

    /**
    *-------------------------------------------------------------------------------
    * @description  Method "getFinancialStatementByAha" retrieves Financial statement By Accnumbers
    *--------------------------------------------------------------------------------
    * @author alexander.munguia.contractor@bbva.com
    * @date 2021-03-17
    * @param Set<String> ahaId
    * @param String condition
    * @return   Map<String,arce__Financial_Statements__c>
    **/
    private static Map<String, List<arce__Financial_Statements__c>> getFinancialStatementListByAha(Map<String, List<String>> infoAHa) {
      List<String> ahaId = new List<String>();
      for (List<String> ids : infoAHa.values()) {
          ahaId.addAll(ids);
      }
      final Map<String, List<arce__Financial_Statements__c>> result = new Map<String, List<arce__Financial_Statements__c>>();
      if (Schema.sObjectType.arce__Financial_Statements__c.isAccessible() && !ahaId.isEmpty()) {
          for (arce__Financial_Statements__c ffee :
              [SELECT Id,
                  arce__total_rating_score_number__c,
                  arce__financial_statement_id__c,
                  arce__financial_statement_start_date__c,
                  arce__financial_statement_end_date__c,
                  arce__rating_final__c,
                  arce__account_has_analysis_id__r.DES_Local_Client__r.Alpha_code__c,
                  arce__account_has_analysis_id__r.arce__total_rating_score_number__c,
                  arce__rating_id__r.arce__rating_long_value_type__c,
                  arce__rating_id__r.arce__rating_short_value_type__c,
                  arce__account_has_analysis_id__r.arce__short_rating_value_type__c,
                  arce__account_has_analysis_id__r.arce__long_rating_value_type__c,
                  arce__rar_rating_tool_id__c,
                  arce__rating_id__r.arce__rating_id__c,
                  arce__account_has_analysis_id__r.arce__Analysis__r.arce__end_date__c
              FROM arce__Financial_Statements__c
              WHERE arce__account_has_analysis_id__c IN: ahaId
              AND arce__ffss_submitted_type__c =: TYPE
              AND arce__ffss_valid_type__c =: TYPE
              AND arce__rating_id__c != null
              ORDER BY CreatedDate DESC]) {
              List<arce__Financial_Statements__c> ffeeList = new List<arce__Financial_Statements__c>();
              if (!result.containsKey(ffee.arce__account_has_analysis_id__r.DES_Local_Client__r.Alpha_code__c)) {
                  ffeeList.add(ffee);
                  result.put(ffee.arce__account_has_analysis_id__r.DES_Local_Client__r.Alpha_code__c, ffeeList);
              }else {
                  ffeeList = result.get(ffee.arce__account_has_analysis_id__r.DES_Local_Client__r.Alpha_code__c);
                  ffeeList.add(ffee);
                  result.put(ffee.arce__account_has_analysis_id__r.DES_Local_Client__r.Alpha_code__c, ffeeList);
              }
          }
      }
      return result;
  }

    /**
    *-------------------------------------------------------------------------------
    * @description  Method "getGlobalByAccNumber" gets all global account fields filtered by AccountNumber
    --------------------------------------------------------------------------------
    * @author amunguia.contractor@bbva.com
    * @date 2021-12-21
    * @param List<String> listAccountNum
    * @return   Map with Account Wrappers
    * @example Map<Id,arce.Arc_Gen_Account_Wrapper> list = Arc_GBL_Account_Locator.getGlobalByAccNumber(listAccountNum);
    **/
    public Map<String,arce.Arc_Gen_Account_Wrapper> getGlobalByAccNumber(List<String> listAccountNum) {
      final Map<String,arce.Arc_Gen_Account_Wrapper> mapWrapper = new Map<String,arce.Arc_Gen_Account_Wrapper>();
      try {
        final Map<String,String> mapCClient = new Map<String,String>();
        for (String accNum: listAccountNum) {
          mapCClient.put(accNum.right(9),accNum);
        }
           System.debug('>>>>>>>>>>>>>>> Entra mapCClient' + mapCClient);
        final List<Account> lstEspej = [
          SELECT Id, Name, SER_CClient__c, DES_Country_Client__c, DES_ID_Fiscal__c, GDT_Delegation__c, g_country_subdivision_id__c,
          DES_Entity_Hierarchy__c, OwnerId, participant_id__c, gf_cust_orig_prospect_ind_type__c, DES_Activity__c, gf_data_institution_type_name__c,
          (select local_customer_id__c, taxpayer_id__c, gf_data_institution_type_name__c from Local_Clients__r LIMIT 1)
          FROM Account
          WHERE SER_CClient__c IN: mapCClient.keySet()
        ];
        if(lstEspej != null && !lstEspej.isEmpty()) {
          System.debug('>>>>>>>>>>>>>>> Entra espejo');
          for(Account acc : lstEspej) {
            final arce.Arc_Gen_Account_Wrapper wrapper = new arce.Arc_Gen_Account_Wrapper();
            wrapper.accId = acc.Id;
            wrapper.accNumber = mapCClient.get(acc.SER_CClient__c);
            wrapper.name = acc.Name;
            wrapper.bankId = getBankId(acc.DES_Country_Client__c);
            wrapper.participantType = acc.DES_Entity_Hierarchy__c == null ? CLIENT : acc.DES_Entity_Hierarchy__c == 'S' ? S_GROUP : CLIENT;
            wrapper.docType = NIF;
            wrapper.docNumber = acc.DES_ID_Fiscal__c == null ? BRANCHID : acc.DES_ID_Fiscal__c;
            wrapper.participantOwnerId = acc.OwnerId;
            wrapper.accParentId = acc.participant_id__c;
            wrapper.branchId = BRANCHID;
            wrapper.country = acc.DES_Country_Client__c;
            wrapper.globalId = wrapper.accNumber; // Alpha code
            wrapper.isProspect = acc.gf_cust_orig_prospect_ind_type__c;
            wrapper.econActSector = Util_PickList.getLabelFromAPI('Account', 'DES_Activity__c').get(acc.DES_Activity__c);
            wrapper.delegationId = acc.GDT_Delegation__c;
            wrapper.isIFISClient = isIfisClient(wrapper.econActSector);
            wrapper.countrySubdivision  = acc.g_country_subdivision_id__c;
            if(!acc.Local_Clients__r.isEmpty()) {
                          wrapper.goldenId = acc.Local_Clients__r[0].local_customer_id__c;
                          wrapper.taxpayerId = acc.Local_Clients__r[0].taxpayer_id__c;
                          wrapper.bankEntity = acc.Local_Clients__r[0].gf_data_institution_type_name__c;
            }
            mapWrapper.put(wrapper.accNumber, wrapper);
          }
        }
      } catch(Exception ex) {
          final arce.Arc_Gen_Account_Wrapper wrapper = new arce.Arc_Gen_Account_Wrapper();
          wrapper.error = ex.getMessage();
          mapWrapper.put(null, wrapper);
      }
      return mapWrapper;
  }

  /**
    * @description
    * @author Global Desktop | 19-10-2022
    * @param AlphaCode
    * @return ----
    **/
    public String getToolkitId (String alphaCode){
      System.debug('alphaCOde --> ' + alphaCode);
    String toolkitId = '';
    try{
        final List<Local_Client__c> lcClient = [SELECT Id, Cib_Client__c FROM Local_Client__c WHERE Alpha_code__c =: alphaCode LIMIT 1];
        final List<Account> lstAcc = [Select Id, DES_Main_Parent__c from Account WHERE Id =: lcClient[0].Cib_Client__c LIMIT 1];
        final list <dwp_acmh__GBL_Account_Relationship__c > parentGroup = [select id, DES_Type__c, dwp_acmh__Parent_Account__r.account_group__c, dwp_acmh__Parent_Account__c from dwp_acmh__GBL_Account_Relationship__c where dwp_acmh__Child_Account__c =: lstAcc[0].Id AND dwp_acmh__Parent_Account__r.account_group__c = '3'];
        if(parentGroup != null && !parentGroup.isEmpty()){
          Id accountId = parentGroup[0].dwp_acmh__Parent_Account__c;
          toolkitId = String.valueOf(cstk.Utils.getToolkitId(accountId));
        }else{
          Id accountId = lstAcc[0].DES_Main_Parent__c;
          toolkitId = String.valueOf(cstk.Utils.getToolkitId(accountId));
        }
    }catch(Exception ex){
        System.debug('error en DES_Arc_Account_Locator -- getToolkitId ' + ex.getMessage());
    }
    Return toolkitId;
  }

  /**
    * @description
    * @author Global Desktop | 22-10-2025
    * @param clientId
    * @return ----
    **/
    public String getToolkitProspectId (String clientId){
    String toolkitId = '';
    final List<Account> lstAcc = [Select Id, DES_Main_Parent__c from Account WHERE Id =: clientId LIMIT 1];
    try{
        Id accountId = lstAcc[0].DES_Main_Parent__c;
        toolkitId = String.valueOf(cstk.Utils.getToolkitId(accountId));
    }catch(Exception ex){
        System.debug('error en DES_Arc_Account_Locator -- getToolkitProspectId ' + ex.getMessage());
    }
    Return toolkitId;
  }

  /**
  * @description
  * @author Global Desktop | 19-06-2023
  * @param AlphaCode
  * @return ----
  **/
  public Map<Id,arce.Arc_Gen_Account_Wrapper> getRepresentativeChildAccs (Id parentAccId, String country){
      final Map<Id, arce.Arc_Gen_Account_Wrapper> mapWrapper = new Map<Id, arce.Arc_Gen_Account_Wrapper>();
        try {
            final List<Local_Client__c> lstAcc = [
                SELECT
                    Id,
                    CurrencyIsoCode,
                    Name,
                    Cib_Client__c,
                    Alpha_code__c,
                    OwnerId,
                    taxpayer_id__c,
                    Cib_Client__r.DES_Entity_Hierarchy__c,
                   g_residence_country_id__c,
                  Booking_country_code__c,
                  Cib_Client__r.GDT_Delegation__c, 
                  Cib_Client__r.DES_Activity__c,
                    local_customer_id__c,
                  country_id__c,
                  gf_data_institution_type_name__c
                FROM Local_Client__c
                WHERE Cib_Client__c = :parentAccId AND g_residence_country_id__c  = :country
                AND gf_prtcpt_act_status_ind_type__c = true
            ];

            final List<id> parentIds = new List<Id>();
            for (Local_Client__c acc : lstAcc) {
              parentIds.add(acc.Cib_Client__c);
            }

            final List<dwp_acmh__GBL_Account_Relationship__c > parentGroup =
              [select id, dwp_acmh__Child_Account__c
              from dwp_acmh__GBL_Account_Relationship__c
              where dwp_acmh__Child_Account__c =: parentIds
              AND dwp_acmh__Parent_Account__r.account_group__c = '3'];

              final Map<Id, List<dwp_acmh__GBL_Account_Relationship__c>> accRelMap = new Map<Id, List<dwp_acmh__GBL_Account_Relationship__c>>();
              for(dwp_acmh__GBL_Account_Relationship__c rel : parentGroup) {
                if(!accRelMap.containsKey(rel.dwp_acmh__Child_Account__c)) {
                  accRelMap.put(rel.dwp_acmh__Child_Account__c, new List<dwp_acmh__GBL_Account_Relationship__c>());
                }
                accRelMap.get(rel.dwp_acmh__Child_Account__c).add(rel);
              }

            for (Local_Client__c acc : lstAcc) {
                final arce.Arc_Gen_Account_Wrapper wrapper = new arce.Arc_Gen_Account_Wrapper();
                wrapper.accId = acc.Id;
                wrapper.accNumber = acc.Alpha_code__c;
                wrapper.name = acc.Name;
                wrapper.bankId = acc.Alpha_code__c == null ? '' :  acc.Alpha_code__c.subString(2,6);
                wrapper.participantType = acc.Cib_Client__r.DES_Entity_Hierarchy__c == null ? CLIENT : acc.cib_Client__r.DES_Entity_Hierarchy__c == 'S' ? S_GROUP : CLIENT;
                wrapper.docType = acc.taxpayer_id__c == null ? null : NIF;
                wrapper.docNumber = acc.taxpayer_id__c;
                wrapper.participantOwnerId = acc.OwnerId;
                wrapper.accParentId = acc.Cib_Client__c;
                wrapper.branchId = BRANCHID;
                wrapper.customAccount = acc.Id;
                wrapper.lookupName = 'DES_Local_Client__c';
                wrapper.country = acc.g_residence_country_id__c;
                wrapper.bookingCountry = acc.Booking_country_code__c;
                wrapper.globalId = wrapper.accNumber; // Alpha code
                wrapper.parentSubsidiary = getTypes(acc.Cib_Client__r.DES_Entity_Hierarchy__c, accRelMap.containsKey(acc.Cib_Client__c)?accRelMap.get(acc.Cib_Client__c): null);
                wrapper.econActSector = Util_PickList.getLabelFromAPI('Account', 'DES_Activity__c').get(acc.Cib_Client__r.DES_Activity__c);
                wrapper.isIFISClient = isIfisClient(wrapper.econActSector);
                wrapper.goldenId = acc.local_customer_id__c;
                wrapper.delegationId = acc.Cib_Client__r.GDT_Delegation__c;
                wrapper.taxpayerId = acc.taxpayer_id__c;
                wrapper.bankEntity = acc.gf_data_institution_type_name__c;
                mapWrapper.put(acc.Id, wrapper);
            }
        } catch (Exception ex) {
            final arce.Arc_Gen_Account_Wrapper wrapper = new arce.Arc_Gen_Account_Wrapper();
            wrapper.error = ex.getMessage();
            mapWrapper.put(null, wrapper);
        }
        return mapWrapper;
  }

  /**
  * @description
  * @author Global Desktop | 19-06-2023
  * @param AlphaCode
  * @return ----
  **/
  public Map<Id,arce.Arc_Gen_Account_Wrapper> getAccountsByGoldenId (List<String> goldenId){
      final Map<Id, arce.Arc_Gen_Account_Wrapper> mapWrapper = new Map<Id, arce.Arc_Gen_Account_Wrapper>();
        try {
            final List<Local_Client__c> lstAcc = [
                SELECT
                    Id,
                    CurrencyIsoCode,
                    Name,
                    Cib_Client__c,
                    Alpha_code__c,
                    OwnerId,
                    taxpayer_id__c,
                    Cib_Client__r.DES_Entity_Hierarchy__c,
                   g_residence_country_id__c,
                  Booking_country_code__c,
                  local_customer_id__c,
                  Cib_Client__r.GDT_Delegation__c, 
                  Cib_Client__r.DES_Activity__c,
                  entity_id__c,
                  country_id__c,
                  gf_data_institution_type_name__c
                FROM Local_Client__c
                WHERE local_customer_id__c IN :goldenId 
                AND gf_prtcpt_act_status_ind_type__c = true
                AND entity_id__c IN ('0182','0074','0013','0011','0017','7714','0069','9120')
            ];

            final List<id> parentIds = new List<Id>();
            for (Local_Client__c acc : lstAcc) {
              parentIds.add(acc.Cib_Client__c);
            }

            final List<dwp_acmh__GBL_Account_Relationship__c > parentGroup =
              [select id, dwp_acmh__Child_Account__c
              from dwp_acmh__GBL_Account_Relationship__c
              where dwp_acmh__Child_Account__c =: parentIds
              AND dwp_acmh__Parent_Account__r.account_group__c = '3'];

              final Map<Id, List<dwp_acmh__GBL_Account_Relationship__c>> accRelMap = new Map<Id, List<dwp_acmh__GBL_Account_Relationship__c>>();
              for(dwp_acmh__GBL_Account_Relationship__c rel : parentGroup) {
                if(!accRelMap.containsKey(rel.dwp_acmh__Child_Account__c)) {
                  accRelMap.put(rel.dwp_acmh__Child_Account__c, new List<dwp_acmh__GBL_Account_Relationship__c>());
                }
                accRelMap.get(rel.dwp_acmh__Child_Account__c).add(rel);
              }
            
            for (Local_Client__c acc : lstAcc) {
                final arce.Arc_Gen_Account_Wrapper wrapper = new arce.Arc_Gen_Account_Wrapper();
                wrapper.accId = acc.Id;
                wrapper.accNumber = acc.Alpha_code__c;
                wrapper.name = acc.Name;
                wrapper.bankId = acc.Alpha_code__c == null ? '' :  acc.Alpha_code__c.subString(2,6);
                wrapper.participantType = acc.Cib_Client__r.DES_Entity_Hierarchy__c == null ? CLIENT : acc.cib_Client__r.DES_Entity_Hierarchy__c == 'S' ? S_GROUP : CLIENT;
                wrapper.docType = acc.taxpayer_id__c == null ? null : NIF;
                wrapper.docNumber = acc.taxpayer_id__c;
                wrapper.participantOwnerId = acc.OwnerId;
                wrapper.accParentId = acc.Cib_Client__c;
                wrapper.branchId = BRANCHID;
                wrapper.customAccount = acc.Id;
                wrapper.lookupName = 'DES_Local_Client__c';
                wrapper.country = acc.g_residence_country_id__c;
                wrapper.bookingCountry = acc.Booking_country_code__c;
                wrapper.globalId = wrapper.accNumber; // Alpha code
                wrapper.parentSubsidiary = getTypes(acc.Cib_Client__r.DES_Entity_Hierarchy__c, accRelMap.containsKey(acc.Cib_Client__c)?accRelMap.get(acc.Cib_Client__c): null);
                wrapper.econActSector = Util_PickList.getLabelFromAPI('Account', 'DES_Activity__c').get(acc.Cib_Client__r.DES_Activity__c);
                wrapper.isIFISClient = isIfisClient(wrapper.econActSector);
                wrapper.goldenId = acc.local_customer_id__c;
                wrapper.delegationId = acc.Cib_Client__r.GDT_Delegation__c;
                wrapper.taxpayerId = acc.taxpayer_id__c;
                wrapper.bankEntity = acc.gf_data_institution_type_name__c;
                mapWrapper.put(acc.Id, wrapper);
            }
        } catch (Exception ex) {
            final arce.Arc_Gen_Account_Wrapper wrapper = new arce.Arc_Gen_Account_Wrapper();
            wrapper.error = ex.getMessage();
            mapWrapper.put(null, wrapper);
        }
        return mapWrapper;
  }

  /**
  * @description
  * @author Global Desktop | 19-06-2023
  * @param AlphaCode
  * @return ----
  **/
  public List<arce.Arc_Gen_Account_Wrapper> searchAccounts (string searchWord, List<Id> accountsExclude){
    final String searchW = searchWord.remove('%');
    final List<arce.Arc_Gen_Account_Wrapper> returnList = new List<arce.Arc_Gen_Account_Wrapper>();
    try {

        List<List<SObject>> searchList = [
            FIND :searchW
            in all fields
            RETURNING Local_Client__c (
                Id,
                CurrencyIsoCode,
                Name,
                Cib_Client__c,
                Alpha_code__c,
                OwnerId,
                taxpayer_id__c,
                Cib_Client__r.DES_Entity_Hierarchy__c,
                g_residence_country_id__c,
                Booking_country_code__c,
                local_customer_id__c,
                Cib_Client__r.GDT_Delegation__c,
                Cib_Client__r.DES_Activity__c,
                country_id__c

                WHERE gf_prtcpt_act_status_ind_type__c = true
                AND id NOT IN :accountsExclude
                ORDER BY LastModifiedDate DESC
            ) LIMIT 10];

        final List<Local_Client__c> accList = (List<Local_Client__c>)searchList[0];

        final List<id> parentIds = new List<Id>();
        for (Local_Client__c acc : accList) {
            parentIds.add(acc.Cib_Client__c);
        }

        final List<dwp_acmh__GBL_Account_Relationship__c > parentGroup =
            [select id, dwp_acmh__Child_Account__c
            from dwp_acmh__GBL_Account_Relationship__c
            where dwp_acmh__Child_Account__c =: parentIds
            AND dwp_acmh__Parent_Account__r.account_group__c = '3'];

            final Map<Id, List<dwp_acmh__GBL_Account_Relationship__c>> accRelMap = new Map<Id, List<dwp_acmh__GBL_Account_Relationship__c>>();
            for(dwp_acmh__GBL_Account_Relationship__c rel : parentGroup) {
                if(!accRelMap.containsKey(rel.dwp_acmh__Child_Account__c)) {
                    accRelMap.put(rel.dwp_acmh__Child_Account__c, new List<dwp_acmh__GBL_Account_Relationship__c>());
                }
                accRelMap.get(rel.dwp_acmh__Child_Account__c).add(rel);
            }

        for (Local_Client__c acc : accList) {
            final arce.Arc_Gen_Account_Wrapper wrapper = new arce.Arc_Gen_Account_Wrapper();
            wrapper.accId = acc.Id;
            wrapper.accNumber = acc.Alpha_code__c;
            wrapper.name = acc.Name;
            wrapper.bankId = acc.Alpha_code__c == null ? '' :  acc.Alpha_code__c.subString(2,6);
            wrapper.participantType = acc.Cib_Client__r.DES_Entity_Hierarchy__c == null ? CLIENT : acc.cib_Client__r.DES_Entity_Hierarchy__c == 'S' ? S_GROUP : CLIENT;
            wrapper.docType = acc.taxpayer_id__c == null ? null : NIF;
            wrapper.docNumber = acc.taxpayer_id__c;
            wrapper.participantOwnerId = acc.OwnerId;
            wrapper.accParentId = acc.Cib_Client__c;
            wrapper.branchId = BRANCHID;
            wrapper.customAccount = acc.Id;
            wrapper.lookupName = 'DES_Local_Client__c';
            wrapper.country = acc.g_residence_country_id__c;
            wrapper.bookingCountry = acc.Booking_country_code__c;
            wrapper.globalId = wrapper.accNumber; // Alpha code
            wrapper.parentSubsidiary = getTypes(acc.Cib_Client__r.DES_Entity_Hierarchy__c, accRelMap.containsKey(acc.Cib_Client__c)?accRelMap.get(acc.Cib_Client__c): null);
            wrapper.econActSector = Util_PickList.getLabelFromAPI('Account', 'DES_Activity__c').get(acc.Cib_Client__r.DES_Activity__c);
            wrapper.isIFISClient = isIfisClient(wrapper.econActSector);
            wrapper.goldenId = acc.local_customer_id__c;
            wrapper.delegationId = acc.Cib_Client__r.GDT_Delegation__c;
            wrapper.taxpayerId = acc.taxpayer_id__c;
            returnList.add(wrapper);
        }
    } catch (Exception e) {
        final arce.Arc_Gen_Account_Wrapper wrapper = new arce.Arc_Gen_Account_Wrapper();
        wrapper.error = e.getMessage();
        returnList.add(wrapper);
    }
    return returnList;
}

  /**
  * @description
  * @author Global Desktop | 19-06-2023
  * @param AlphaCode
  * @return ----
  **/
  public Map<String, Object> setDelegationId  (Id accountId, Id delegationId){
    final Map<String, Object> delegationObj = new Map<String, Object>();
    delegationObj.put('GDT_Delegation__c', delegationId);
    return delegationObj;
  }

  /**
  *-------------------------------------------------------------------------------
  * @description  Method "getGroupStructure" gets local group Structure.
  --------------------------------------------------------------------------------
  * @author jordana.contractor@bbva.com | 27/12/2022
  * @param String accNumber
  * @return   Map with list of Local Ids
  * @example Arc_Gen_Group_Structure_Wrapper getArceOverviewStrc(AccNumber);
  **/
  global static arce.Arc_Gen_Group_Structure_Wrapper getArceOverviewStrc(String accNumber) {
    final arce.Arc_Gen_Group_Structure_Wrapper toRtn = DES_Arc_Account_Hierarchy.childHierarchy(accNumber);
    return toRtn; 
  }

  /**
    * ----------------------------------------------------------------------------------------------------
    * @Description Method to get alphacodes from children accounts
    * ----------------------------------------------------------------------------------------------------
    * @author hectorjeshua.vasquez.contractor@bbva.com
    * @date 2023-12-04
    * @param String accId
    * @return Map<String,List<String>>
    * @example DES_Arc_Account_Hierarchy.getSubsByAlphaCode(accId)
    * ----------------------------------------------------------------------------------------------------
    **/
    global static Map<String, List<String>> getSubsByAlphaCode(String accId) {
      final Map<String, List<String>> toRtn = DES_Arc_Account_Hierarchy.alphaCodeHierarchy(accId);
      return toRtn; 
  }


  /**
  *-------------------------------------------------------------------------------
  * @description  Method "getTypesLcl" gets type of client of a local client.
  --------------------------------------------------------------------------------
  * @author hectorjeshua.vasquez.contractor@bbva.com | 31/03/2023
  * @param String lclNumber
  * @return   String of account type
  * @example Arc_Gen_Group_Structure_Wrapper getTypesLcl(lclNumber);
  **/
  /*global static String getTypesLcl(String lclNumber) {
    String type;
    final List<Local_Client__c> lclList = [SELECT Id, Cib_Client__c FROM Local_Client__c WHERE Id =: lclNumber];
    final List<Account> accList = [SELECT Id, account_group__c, account_client__c, DES_Entity_Hierarchy__c FROM Account WHERE Id =: lclList[0].Cib_Client__c];
    if(accList[0].DES_Entity_Hierarchy__c == 'S'){
      type = 'GROUP';
    }else{
        final list <dwp_acmh__GBL_Account_Relationship__c > parentGroup = [select id, DES_Type__c, dwp_acmh__Parent_Account__r.account_group__c from dwp_acmh__GBL_Account_Relationship__c where dwp_acmh__Child_Account__c =: accList[0].Id AND dwp_acmh__Parent_Account__r.account_group__c = '3'];
        if (parentGroup != null && !parentGroup.isEmpty()){
            type = 'SUBGROUP';
        }else{
            type = 'SUBSIDIARY';
        }
    }
    return type;
  }*/
    
  /**
  *-------------------------------------------------------------------------------
  * @description  Method "getTypesAcc" gets type of Account.
  --------------------------------------------------------------------------------
  * @author hectorjeshua.vasquez.contractor@bbva.com | 31/03/2023
  * @param String accNumber
  * @return   String of account type
  * @example Arc_Gen_Group_Structure_Wrapper getTypesAcc(accNumber);
  **/
  /*global static String getTypesAcc(String accNumber) {
    String type;
    final List<Account> accList = [SELECT Id, account_group__c, account_client__c, DES_Entity_Hierarchy__c FROM Account WHERE Id =: accNumber];
    if(accList[0].DES_Entity_Hierarchy__c == 'S'){
      type = 'GROUP';
    }else{
        final list <dwp_acmh__GBL_Account_Relationship__c > parentGroup = [select id, DES_Type__c, dwp_acmh__Parent_Account__r.account_group__c from dwp_acmh__GBL_Account_Relationship__c where dwp_acmh__Child_Account__c =: accNumber AND dwp_acmh__Parent_Account__r.account_group__c = '3'];
        if (parentGroup != null && !parentGroup.isEmpty()){
            type = 'SUBGROUP';
        }else{
            type = 'SUBSIDIARY';
        }
    }
    return type;
  }*/
  
  /**
  *-------------------------------------------------------------------------------
  * @description  Method "getTypes" gets type of Account.
  --------------------------------------------------------------------------------
  * @author hectorjeshua.vasquez.contractor@bbva.com | 31/03/2023
  * @param String accNumber
  * @return   String of account type
  * @example Arc_Gen_Group_Structure_Wrapper getTypes(accNumber);
  **/
  global static String getTypes(String entHierarchy, List<dwp_acmh__GBL_Account_Relationship__c> accRel) {
      String type;
      if(entHierarchy == 'S'){
        type = 'GROUP';
      }else{
          if (accRel != null && !accRel.isEmpty()){
              type = 'SUBGROUP';
          }else{
              type = 'SUBSIDIARY';
          }
      }
      return type;
    }
  /**
  *-------------------------------------------------------------------------------
  * @description  Method "getDataFromCibGroup"
  --------------------------------------------------------------------------------
  * @author Global Desktop
  * @date 2024-07-02
  * @param Map<String, Object> mapInfo
  * @return Map<String, Object>
  **/
    public Map<String, Object> getDataFromCibGroup (Map<String, Object> mapInfo) {
        Map<String, Object> mapData = new Map<String, Object>();
        try {
            for (String method : mapInfo.keySet()) {
                switch on method {
                    when 'getMatrixFromCibGroup' {
                        mapData = getMatrixFromCibGroup(mapInfo);
                    }
                    when 'getSubsFromCibGroup' {
                        mapData = getSubsFromCibGroup(mapInfo);
                    }
                    when 'getSubsGroupsFromCibGroup' {
                        mapData = getSubsGroupsFromCibGroup(mapInfo);
                    }
                    when 'getRatingsForProposal' {
                      mapData = getRatingsForProposal(mapInfo);
                    }
                }
            }
        } catch (Exception ex) {
            final arce.Arc_Gen_Account_Wrapper wrapper = new arce.Arc_Gen_Account_Wrapper();
            wrapper.error = ex.getMessage();
            mapData.put(null, wrapper);
        }
        return mapData;
    }
    private static Map<String, Object> getMatrixFromCibGroup(Map<String, Object> mapInfo) {
        final Map<Id, List<dwp_acmh__GBL_Account_Relationship__c>> accRelMap = new Map<Id, List<dwp_acmh__GBL_Account_Relationship__c>>();
        final arce.Arc_Gen_Account_Wrapper wrapper = new arce.Arc_Gen_Account_Wrapper();
        final Map<String, Object> mapData = new Map<String, Object>();
        String currentAcc = (String) mapInfo.get('getMatrixFromCibGroup');

        try {

			      final List<Account> lisAcc = [SELECT Id from Account WHERE DES_Main_Parent__c =:currentAcc AND business_group_header_type__c = true AND account_client__c = 'S'];
            final Local_Client__c locClient = [SELECT Id,CurrencyIsoCode,Name,Cib_Client__c,Alpha_code__c,OwnerId,taxpayer_id__c,Cib_Client__r.DES_Entity_Hierarchy__c,Cib_Client__r.DES_Main_Parent__c,Cib_Client__r.DES_Main_Parent__r.DES_Group_Code__c, g_residence_country_id__c,Booking_country_code__c,local_customer_id__c,Cib_Client__r.GDT_Delegation__c,Cib_Client__r.DES_Activity__c,entity_id__c, gf_data_institution_type_name__c from Local_Client__c WHERE Cib_Client__c = :lisAcc[0].Id AND gf_prtcpt_act_status_ind_type__c = true AND entity_id__c IN ('0182','0074','0013','0011','0017','7714','0069','9120') LIMIT 1];

            wrapper.accId = locClient.Id;
            wrapper.accNumber = locClient.Alpha_code__c;
            wrapper.name = locClient.Name;
            wrapper.bankId = locClient.Alpha_code__c == null ? '' :  locClient.Alpha_code__c.subString(2,6);
            wrapper.participantType = locClient.Cib_Client__r.DES_Entity_Hierarchy__c == null ? CLIENT : locClient.cib_Client__r.DES_Entity_Hierarchy__c == 'S' ? S_GROUP : CLIENT;
            wrapper.docType = locClient.taxpayer_id__c == null ? null : NIF;
            wrapper.docNumber = locClient.taxpayer_id__c;
            wrapper.participantOwnerId = locClient.OwnerId;
            wrapper.accParentId = locClient.Cib_Client__c;
            wrapper.branchId = BRANCHID;
            wrapper.customAccount = locClient.Id;
            wrapper.lookupName = 'DES_Local_Client__c';
            wrapper.country = locClient.g_residence_country_id__c;
            wrapper.bookingCountry = locClient.Booking_country_code__c;
            wrapper.globalId = wrapper.accNumber; // Alpha code
            wrapper.parentSubsidiary = getTypes(locClient.Cib_Client__r.DES_Entity_Hierarchy__c, accRelMap.containsKey(locClient.Cib_Client__c)?accRelMap.get(locClient.Cib_Client__c): null);
            wrapper.econActSector = Util_PickList.getLabelFromAPI('Account', 'DES_Activity__c').get(locClient.Cib_Client__r.DES_Activity__c);
            wrapper.isIFISClient = isIfisClient(wrapper.econActSector);
            wrapper.goldenId = locClient.local_customer_id__c;
            wrapper.delegationId = locClient.Cib_Client__r.GDT_Delegation__c;
            wrapper.taxpayerId = locClient.taxpayer_id__c;
            wrapper.bankEntity = locClient.gf_data_institution_type_name__c;
            wrapper.groupCode = locClient.Cib_Client__r.DES_Main_Parent__r.DES_Group_Code__c;
            mapData.put(currentAcc, wrapper);
        } catch (Exception e) {
            wrapper.error = e.getMessage();
            mapData.put(currentAcc, wrapper);
        }
        System.debug('mapData en getMatrixFromCibGroup es: ' + mapData);
        return mapData;
    }
    private static Map<String, Object> getSubsFromCibGroup(Map<String, Object> mapInfo) {
        final Map<String, List<String>> mapWrapper = new Map<String, List<String>>();
        final Map<Id, List<dwp_acmh__GBL_Account_Relationship__c>> accRelMap = new Map<Id, List<dwp_acmh__GBL_Account_Relationship__c>>();
        String currentAcc = (String) mapInfo.get('getSubsFromCibGroup');

        try {
			final List<Account> lisAcc = [SELECT Id from Account WHERE DES_Main_Parent__c =:currentAcc AND business_group_header_type__c = false];
            Set<Id> setAccounts = new Set<Id>();
            if (!lisAcc.isEmpty()) {
                for(Account acc: lisAcc) {
                    setAccounts.add(acc.Id);
                }
            }
            System.debug('setAccounts es: ' + setAccounts);
            final List<Local_Client__c> lstLocClient = [SELECT Id,CurrencyIsoCode,Name,Cib_Client__c,Alpha_code__c,OwnerId,taxpayer_id__c,Cib_Client__r.DES_Entity_Hierarchy__c,g_residence_country_id__c,Booking_country_code__c,local_customer_id__c,Cib_Client__r.GDT_Delegation__c,Cib_Client__r.DES_Activity__c,entity_id__c,country_id__c from Local_Client__c WHERE Cib_Client__c IN :setAccounts AND gf_prtcpt_act_status_ind_type__c = true AND entity_id__c IN ('0182','0074','0013','0011','0017','7714','0069','9120')];
            for(Local_Client__c locClient : lstLocClient) {
              switch on locClient.entity_id__c {
                when '0182','0074','0013','0011','0017','7714','0069','9120' {
                    if (mapWrapper.containsKey(currentAcc)) {
                        final List<String> lstAux = mapWrapper.get(currentAcc);
                        if (!lstAux.contains(locClient.Alpha_code__c)) {
                            mapWrapper.get(currentAcc).add(locClient.Alpha_code__c);
                        }
                    } else {
                        mapWrapper.put(currentAcc, new List<String>{locClient.Alpha_code__c});
                    }
                }
              }
            }
        } catch (Exception e) {
            mapWrapper.put('Error', new List<String>{e.getMessage()});
        }
        System.debug('mapData en getSubsFromCibGroup es: ' + mapWrapper);
        return mapWrapper;
    }
    private static Map<String, Object> getSubsGroupsFromCibGroup(Map<String, Object> mapInfo) {
        final Map<String, List<String>> mapWrapper = new Map<String, List<String>>();
        final Map<Id, List<dwp_acmh__GBL_Account_Relationship__c>> accRelMap = new Map<Id, List<dwp_acmh__GBL_Account_Relationship__c>>();
        final String currentAcc = (String) mapInfo.get('getSubsGroupsFromCibGroup');

        try {
      final List<dwp_acmh__GBL_Account_Relationship__c> accRelSubGroups = [SELECT Id, dwp_acmh__Child_Account__c FROM dwp_acmh__GBL_Account_Relationship__c WHERE dwp_acmh__Parent_Account__c =:currentAcc AND dwp_acmh__Vision__c = 'Riesgos' AND dwp_acmh__Child_Account__r.account_group__c = '3'];
            final Set<String> setSubGroups = getSetChildAccount(accRelSubGroups);
            final List<dwp_acmh__GBL_Account_Relationship__c> accCabSubGroups = [SELECT Id, dwp_acmh__Child_Account__c FROM dwp_acmh__GBL_Account_Relationship__c WHERE dwp_acmh__Parent_Account__c IN :setSubGroups AND dwp_acmh__Vision__c = 'Riesgos' AND dwp_acmh__Child_Account__r.account_client__c = 'S'];
            final Set<String> setCabSubGroups = getSetChildAccount(accCabSubGroups);
            final List<Local_Client__c> lstLocClient = [SELECT Id,CurrencyIsoCode,Name,Cib_Client__c,Alpha_code__c,OwnerId,taxpayer_id__c,Cib_Client__r.DES_Entity_Hierarchy__c,g_residence_country_id__c,Booking_country_code__c,local_customer_id__c,Cib_Client__r.GDT_Delegation__c,Cib_Client__r.DES_Activity__c,entity_id__c,country_id__c from Local_Client__c WHERE Cib_Client__c IN :setCabSubGroups AND gf_prtcpt_act_status_ind_type__c = true AND entity_id__c IN ('0182','0074','0013','0011','0017','7714','0069','9120')];
            for(Local_Client__c locClient : lstLocClient) {
              switch on locClient.entity_id__c {
                when '0182','0074','0013','0011','0017','7714','0069','9120' {
                    if (mapWrapper.containsKey(currentAcc)) {
                        final List<String> lstAux = mapWrapper.get(currentAcc);
                        if (!lstAux.contains(locClient.Alpha_code__c)) {
                            mapWrapper.get(currentAcc).add(locClient.Alpha_code__c);
                        }
                    } else {
                        mapWrapper.put(currentAcc, new List<String>{locClient.Alpha_code__c});
                    }
                }
              }
            }
        } catch (Exception e) {
            mapWrapper.put('Error', new List<String>{e.getMessage()});
        }
        System.debug('mapData en getSubsGroupsFromCibGroup es: ' + JSON.serialize(mapWrapper));
        return mapWrapper;
    }
    private static Set<String> getSetChildAccount(List<dwp_acmh__GBL_Account_Relationship__c> accRelSubGroups) {
        final Set<String> setChildAccount = new Set<String>();
        for(dwp_acmh__GBL_Account_Relationship__c accRel : accRelSubGroups) {
            setChildAccount.add(accRel.dwp_acmh__Child_Account__c);
        }
    return setChildAccount;
    }
  /**
  *-------------------------------------------------------------------------------
  * @description  Method "mergeProspectClient"
  --------------------------------------------------------------------------------
  * @author Global Desktop
  * @date 2024-07-02
  * @param Map<String, Object> mapInfo
  * @return Map<String, Object>
  **/
    public Boolean mergeProspectClient (String prospectId, String alphacode) {
      return false;
    }
  /**
  *-------------------------------------------------------------------------------
  * @description  Method "mergeProspectClient"
  --------------------------------------------------------------------------------
  * @author Global Desktop
  * @date 2024-07-02
  * @param Map<String, Object> mapInfo
  * @return Map<String, Object>
  **/
    public arce.Arc_Gen_Account_Wrapper getMainGroup (Id accountId) {
      return new arce.Arc_Gen_Account_Wrapper();
    }

    /**
    *-------------------------------------------------------------------------------
    * @description  Method "searchFiscalId" that retrieves Account fiscalId, groupName,name
    *-------------------------------------------------------------------------------
    * @author joseluis.miralles.tech@bbva.com@bbva.com
    * @date 2024-07-26
    * @param Map<String, String> mapifscalId
    * @return   List<Map<String, String>>
    * @example List<Map<String, String>> list = Arc_GBL_Account_Locator.searchFiscalId(mapifscalId);
    **/
    public static List<arce.Arc_Gen_Account_Wrapper> searchFiscalId(Map<String, String> mapifscalId) {
      final String fiscalNumber = '%'+mapifscalId.get('fiscalNumber')+'%';
      final List<arce.Arc_Gen_Account_Wrapper> listWrapper = new List<arce.Arc_Gen_Account_Wrapper> ();
      try {
          final List<Local_Client__c> localList = [Select
            id,
            Name,
            Alpha_code__c,
            Cib_Client__r.Name,
            Cib_Client__r.DES_ID_Fiscal__c,
            Cib_Client__r.DES_Main_Parent__r.DES_Group_Code__c,
            Cib_Client__r.DES_Main_Parent__r.Name,
            gf_data_institution_type_name__c
            FROM Local_Client__c
            WHERE Cib_Client__r.DES_ID_Fiscal__c LIKE :fiscalNumber
            AND Cib_Client__r.business_group_header_type__c = true
            ORDER BY LastModifiedDate DESC];

            for (Local_Client__c localRecord : localList) {
                final arce.Arc_Gen_Account_Wrapper wrapper = new arce.Arc_Gen_Account_Wrapper();
                wrapper.accId = localRecord.Id;
                wrapper.accNumber = localRecord.Alpha_code__c;
                wrapper.name = localRecord.Cib_Client__r.Name;
                wrapper.docNumber = localRecord.Cib_Client__r.DES_ID_Fiscal__c;
                wrapper.groupCode = localRecord.Cib_Client__r.DES_Main_Parent__r.Name;
                wrapper.bankEntity = localRecord.gf_data_institution_type_name__c;
                listWrapper.add(wrapper);
            }
      } catch (Exception e) {
          final arce.Arc_Gen_Account_Wrapper toReturn = new arce.Arc_Gen_Account_Wrapper ();
          toReturn.error = e.getMessage();
          listWrapper.add(toReturn);
      }
      return listWrapper;
  }

  public static Map<String, String> getEntityType(List<Local_Client__c> lstLocClient) {
    String entityType;
    final List<id> parentIds = new List<Id>();
    final Map<String, String> mapaAccAlphaCode = new Map<String, String>();
    final Map<String, String> mapToRet = new Map<String, String>();
    for (Local_Client__c locCli : lstLocClient) {
      parentIds.add(locCli.Cib_Client__c);
      mapaAccAlphaCode.put(locCli.Cib_Client__c, locCli.Alpha_code__c);
    }

    final List<dwp_acmh__GBL_Account_Relationship__c > parentSubGroup = [SELECT id, dwp_acmh__Child_Account__c, dwp_acmh__Parent_Account__r.account_group__c, dwp_acmh__Child_Account__r.business_group_header_type__c, dwp_acmh__Child_Account__r.account_client__c FROM dwp_acmh__GBL_Account_Relationship__c WHERE dwp_acmh__Child_Account__c =: parentIds AND dwp_acmh__Vision__c = 'Riesgos' AND dwp_acmh__Parent_Account__r.account_group__c = '3' AND dwp_acmh__Child_Account__r.account_client__c = 'S'];
    final List<dwp_acmh__GBL_Account_Relationship__c > parentGroup = [SELECT id, dwp_acmh__Child_Account__c, dwp_acmh__Parent_Account__r.account_group__c, dwp_acmh__Child_Account__r.business_group_header_type__c, dwp_acmh__Child_Account__r.account_client__c FROM dwp_acmh__GBL_Account_Relationship__c WHERE dwp_acmh__Child_Account__c =: parentIds AND dwp_acmh__Vision__c = 'Riesgos' AND dwp_acmh__Parent_Account__r.account_group__c = '1A' AND DES_Main_Parent__c = 'S' AND dwp_acmh__Child_Account__r.account_client__c = 'S'];      
    if(!parentSubGroup.isEmpty()) {
        mapToRet.put(mapaAccAlphaCode.get(parentSubGroup[0].dwp_acmh__Child_Account__c), 'PARENT_SUBGROUP');
    } else if(!parentGroup.isEmpty()) {
        mapToRet.put(mapaAccAlphaCode.get(parentGroup[0].dwp_acmh__Child_Account__c), 'PARENT_GROUP');
    }
    return mapToRet;
  }

  /**
  *-------------------------------------------------------------------------------
  * @description  Method "isIfisClientRTC" that retrieves if an account is a IFIS RTC
  *-------------------------------------------------------------------------------
  * @author Noelia.ruiz.lopez.contractor@bbva.com
  * @date 2025-04-03
  * @param string bankEntity
  * @return   Boolean
  * @example Boolean isClient = Arc_GBL_Account_Locator.isIfisClientRTC(bankEntity);
  **/
  private static Boolean isIfisClientRTC(string bankEntity) {
    final Set<String> actRelMdt = new Set<String>();
    try {
        final arce__Service_persistence__mdt servicePersis = [SELECT arce__JSON_input__c
        FROM arce__Service_persistence__mdt
        WHERE DeveloperName = 'IFIS_InstitutionTypes'
        WITH USER_MODE];

        if (servicePersis != null && servicePersis.arce__JSON_input__c != null) {
            final Map<String, Object> jsonMap = (Map<String, Object>) JSON.deserializeUntyped(
                servicePersis.arce__JSON_input__c
            );
            for (String key : jsonMap.keySet()) {
                final List<Object> values = (List<Object>) jsonMap.get(key);
                for (Object value : values) {
                    actRelMdt.add(String.valueOf(value));
                }
            }
        }
    } catch (Exception e) {
        System.debug(e.getMessage());
    }
    return actRelMdt.contains(bankEntity) ? true : false;
  }
}