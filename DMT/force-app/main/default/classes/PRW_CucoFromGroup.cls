/**
* ------------------------------------------------------------------------------------------------
* @Name     PRW_CucoFromGroup
* @Author   Global Hub
* @Date     Created: 2021-10-10
* ------------------------------------------------------------------------------------------------
* @Description Controller class for PRW_SelectCucoFromGroup component
* ------------------------------------------------------------------------------------------------
* @Changes
*
* |2021-10-10 daniel.herrero.guerrica-echev.contractor@bbva.com
*             Class Creation
* -----------------------------------------------------------------------------------------------
*/
public with sharing class PRW_CucoFromGroup {

    /**
    * SINGLETON PATTERN
    */
    private static PRW_CucoFromGroup instance;

    /**
    * Constructor
    */
    private PRW_CucoFromGroup() {}

    /**
    * getInstance
    */
    public static PRW_CucoFromGroup gtInstance() {
        if(instance == null) {
        instance = new PRW_CucoFromGroup();
        }
        return instance;
    }

    /**
    * --------------------------------------------------------------------------------------
    * @Description - Method that return a if the account is group
    * --------------------------------------------------------------------------------------
    * @Author   Global Hub
    * @Date     Created: 2021-10-10
    * @param account id
    * @return true if group
    * --------------------------------------------------------------------------------------
    **/
    @AuraEnabled
    public static Boolean isClientGroup(String accId) {
        final List<Account> acc = [SELECT id FROM Account WHERE id = :accId AND DES_Structure_Type__c = 'Group'];
        return acc == null || acc.size() == 0 ? false : true;
    }

  /**
  * --------------------------------------------------------------------------------------
  * @Description - Method that return a if the account is, or has any subsidiary entity_id 0182
  * --------------------------------------------------------------------------------------
  * @Author   Global Hub
  * @Date     Created: 2021-10-10
  * @param account id
  * @return list of IDs DES_Country_Client__c
  * --------------------------------------------------------------------------------------
  **/
  @AuraEnabled
  public static Boolean isClientSpain(String recordId) {
    final Set<Id> accountIds = new Set<Id>{recordId};
    final Set<Id> localOrSpainIds = new Set<Id>{};

    final List<Account> accounts = [SELECT Id, DES_Country_Client__c FROM Account WHERE DES_Main_Parent__c = :recordId AND SER_CClient__c != null AND ((DES_Provisioning_Method__c = 'Datio' AND DES_Structure_Type__c = 'Subsidiary') OR (DES_Structure_Type__c = 'NIF Client'))]; //NOSONAR
    final Account thisAccount = [SELECT Id ,DES_Structure_Type__c, DES_Country_Client__c FROM Account WHERE Id =:recordId LIMIT 1];//NOSONAR
    if(thisAccount.DES_Structure_Type__c == 'Subsidiary'){
       accounts.add(thisAccount);
    }
    for (Account acc : accounts) {
      accountIds.add(acc.Id);
    }
    final Set<Id> localClients = getLocalClients(accountIds);

    // If account in local_clients || Country = ES
    for (Account acc : accounts) {
      if (acc.DES_Country_Client__c == 'ES' || localClients.contains(acc.Id)) {
        localOrSpainIds.add(acc.Id);
      }
    }
    return localOrSpainIds.size() == 0 ? false : true;
  }

  /**
  * @description Returns local clients with entity 0182
  * @param accountIds : Set of the related accounts Ids
  * @return Set<Id> accounts
  */
  public static Set<Id> getLocalClients(Set<Id> accountIds) {
    final Set<Id> res = new Set<Id>();
    final List<Local_Client__c> localClients = [SELECT Cib_Client__c FROM Local_Client__c WHERE entity_id__c  = '0182' AND Cib_Client__c IN :accountIds];
    for (Local_Client__c localClient : localClients) {
        res.add(localClient.Cib_Client__c);
    }
    return res;
  }

  /**
  * --------------------------------------------------------------------------------------
  * @Description - Method that return a String with Cucos of a group and their childs
  * --------------------------------------------------------------------------------------
  * @Author   Global Hub
  * @Date     Created: 2021-10-10
  * @param account id and filter name
  * @return wrapper whit Cucos of a group and their childs
  * --------------------------------------------------------------------------------------
  **/
  @AuraEnabled
  public static String getCucoFromGroup(String accId, String accName, String table) {
      final Map<Id, String> mFilialIDName = new Map<Id, String>();
      final Map<Id, String> mFilialIDNamesp = new Map<Id, String>();
      final Set<Id> allIds = new Set<Id>();
      Set<Id> localClients = new Set<Id>();

      if(accName == null) {
        final List<DES_Subsidiary_Group_Relation__c> lMatrix = new List<DES_Subsidiary_Group_Relation__c>([
          SELECT id, participant_child_id__c, participant_child_id__r.name, participant_parent_id__c, participant_child_id__r.DES_Country_Client__c
          FROM DES_Subsidiary_Group_Relation__c
          WHERE participant_parent_id__c = :accId AND ((participant_child_id__r.DES_Provisioning_Method__c = 'Datio' AND participant_child_id__r.DES_Structure_Type__c = 'Subsidiary') OR (participant_child_id__r.DES_Structure_Type__c = 'NIF Client'))
          ORDER BY participant_child_id__c
        ]);

        // Get Local_clients with entity_id 0182
        for(DES_Subsidiary_Group_Relation__c matrix : lMatrix) {
          allIds.add(matrix.participant_child_id__c);
        }
        localClients = getLocalClients(allIds);

        for(DES_Subsidiary_Group_Relation__c matrix : lMatrix) {
          mFilialIDName.put(matrix.participant_child_id__c, matrix.participant_child_id__r.name);
          // filter Local_clients with no entity_id 0182
          if(localClients.contains(matrix.participant_child_id__c) || matrix.participant_child_id__r.DES_Country_Client__c == 'ES') {
            mFilialIDNamesp.put(matrix.participant_child_id__c, matrix.participant_child_id__r.name);
          }
        }

      } else if(accName != null) {

        final List<cucoWrapper> wrapperlist = (List<cucoWrapper>) JSON.deserialize(table, List<cucoWrapper>.class);
        final Set<Id> setAccounts = new Set<Id>();
        for(cucoWrapper wrapper : wrapperlist) {
          setAccounts.addAll(wrapper.mFilialIDName.keySet());
        }
        final List<List<SObject>> lAccInclude = [
          FIND :accName IN NAME FIELDS RETURNING Account(id, Name where Id IN :setAccounts)
        ];
        mFilialIDName.clear();
        final List<Account> searchAccounts = (List<Account>)lAccInclude[0];

        // Get Local_clients with entity_id 0182
        for(Account acc : searchAccounts) {
          allIds.add(acc.id);
        }
       localClients = getLocalClients(allIds);

        for(Account acc : searchAccounts) {
          // filter Local_clients with no entity_id 0182
          if(localClients.contains(acc.id)) {
            mFilialIDName.put(acc.id, acc.name);
          }
        }
      }

    final List<cuco__profitability_sheet_participant__c> lstProfSheet = new List<cuco__profitability_sheet_participant__c>([
        SELECT cuco__participant_id__r.name, cuco__gf_profitability_sheet_id__r.id, cuco__gf_profitability_sheet_id__r.name, cuco__gf_profitability_sheet_id__r.cuco__gf_profitability_sheet_id__c, cuco__gf_profitability_sheet_id__r.cuco__gf_prftbly_sheet_end_date__c, cuco__gf_profitability_sheet_id__r.cuco__gf_prftbly_sheet_start_date__c
        FROM cuco__profitability_sheet_participant__c
        WHERE cuco__participant_id__c IN :mFilialIDName.keySet()
        AND cuco__gf_profitability_sheet_id__r.cuco__gf_prftbly_sheet_end_date__c > TODAY
        ORDER BY cuco__gf_profitability_sheet_id__r.name
    ]);

      final Map<String, cucoWrapper> mCucoWrapper = getCucoAux(lstProfSheet, mFilialIDName, mFilialIDNamesp);
      return JSON.serialize(mCucoWrapper.values());
  }

    /**
    * --------------------------------------------------------------------------------------
    * @Description - Wrapper Class to set Cucos
    * --------------------------------------------------------------------------------------
    * @Author   Global Hub
    * @Date     Created: 2021-10-10
    * --------------------------------------------------------------------------------------
    **/
    public static Map<String, cucoWrapper> getCucoAux(List<cuco__profitability_sheet_participant__c> lstProfSheet, Map<Id, String> mFilialIDName, Map<Id, String> mFilialIDNamesp) {

        String noCuco;
        noCuco = 'nocuco';
        final Map<String, cucoWrapper> mCucoWrapper = new Map<String, cucoWrapper>();

        Map<Id, String> mCucoName;

        for(cuco__profitability_sheet_participant__c cuco : lstProfSheet) {
            if(mCucoWrapper.containsKey(cuco.cuco__gf_profitability_sheet_id__r.id)) {
                if ( mFilialIDName.get(cuco.cuco__participant_id__r.id) != null ) {
                    mCucoWrapper.get(cuco.cuco__gf_profitability_sheet_id__r.id).addFilial(cuco.cuco__participant_id__c, mFilialIDName.get(cuco.cuco__participant_id__r.id));
                }
            } else {
                mCucoName = new Map<Id, String> ();
                mCucoName.put(cuco.cuco__participant_id__c, mFilialIDName.get(cuco.cuco__participant_id__r.id));
                mCucoWrapper.put(cuco.cuco__gf_profitability_sheet_id__r.id, new cucoWrapper(mCucoName, cuco.cuco__gf_profitability_sheet_id__r.id, cuco.cuco__gf_profitability_sheet_id__r.cuco__gf_profitability_sheet_id__c, cuco.cuco__gf_profitability_sheet_id__r.name, 'Vigente', cuco.cuco__gf_profitability_sheet_id__r.cuco__gf_prftbly_sheet_end_date__c, cuco.cuco__gf_profitability_sheet_id__r.cuco__gf_prftbly_sheet_start_date__c));
            }
            mFilialIDName.remove(cuco.cuco__participant_id__c);
        }

        string FilialIDNamees;

        for(Id idClientNoCuco : mFilialIDNamesp.keySet()) {
            if(mCucoWrapper.containsKey(noCuco)) {
                FilialIDNamees = mFilialIDName.get(idClientNoCuco);
                if( FilialIDNamees == null ) {
                    FilialIDNamees ='es nula';
 		mCucoWrapper.get(noCuco).removeFilial(idClientNoCuco);
            
	    }else{

              mCucoWrapper.get(noCuco).addFilial(idClientNoCuco, FilialIDNamees);
  }
          } else {
              mCucoName = new Map<Id, String> ();
              FilialIDNamees = mFilialIDNamesp.get(idClientNoCuco);
              if( FilialIDNamees == null ) {
                  FilialIDNamees ='es nula';
              }
              mCucoName.put(idClientNoCuco, FilialIDNamees);
              mCucoWrapper.put(noCuco, new cucoWrapper(mCucoName, noCuco, noCuco,'No Cuco', null, null, null));
          }
      }
      List<String> cucoListOrdered;
      Map<String,Id> cucoMapToOrder;
      Map<Id,String> cucoMapOrdered;
      for(CucoWrapper cucowarpperToReturn :  mCucoWrapper.values()){
        cucoListOrdered = new List<String>();
        cucoMapToOrder = new Map<String,Id>();
        cucoMapOrdered = new Map<Id,String> ();
        for(Id idFilial : cucowarpperToReturn.mFilialIDName.keySet()){
          cucoListOrdered.add(cucowarpperToReturn.mFilialIDName.get(idFilial));
          cucoMapToOrder.put(cucowarpperToReturn.mFilialIDName.get(idFilial) , idFilial);
        }
        cucoListOrdered.sort();
        for(String filialName  : cucoListOrdered){
          cucoMapOrdered.put(cucoMapToOrder.get(filialName),filialName);
        }
        cucowarpperToReturn.mFilialIDName = cucoMapOrdered;
      }
      return mCucoWrapper;
  }

    /**
    * --------------------------------------------------------------------------------------
    * @Description - Wrapper Class to set Cucos
    * --------------------------------------------------------------------------------------
    * @Author   Global Hub
    * @Date     Created: 2021-10-10
    * --------------------------------------------------------------------------------------
    **/
    public class cucoWrapper {
        /**
        * @description Private constructor to avoid sonar err
        */
        public Map<Id, String> mFilialIDName {get;set;}
        /**
        * @description Private constructor to avoid sonar err
        */
        public String cucoID {get;set;}
        /**
        * @description Private constructor to avoid sonar err
        */
        public String codeID {get;set;}
        /**
        * @description Private constructor to avoid sonar err
        */
        public String cucoName {get;set;}
        /**
        * @description Private constructor to avoid sonar err
        */
        public String statement {get;set;}
        /**
        * @description Private constructor to avoid sonar err
        */
        public Date expirationDate {get;set;}
        /**
        * @description Private constructor to avoid sonar err
        */
        public Date startDate {get;set;}

        /*
        * Constructor wrapper
        */
        public cucoWrapper(Map<Id, String> mFilialIDName, String cucoID, String codeID, String cucoName, String statement, Date expirationDate, Date startDate) {
            this.mFilialIDName = mFilialIDName;
            this.cucoID = cucoID;
            this.codeID = codeID;
            this.cucoName = cucoName;
            this.statement = statement;
            this.expirationDate = expirationDate;
            this.startDate = startDate;
        }

      /*
      * Añade un cliente hijo
      */
      public void addFilial(Id idFilial, String name) {
          mFilialIDName.put(idFilial, name);
      }
      /*
      * Elimina un cliente hijo
      */
      public void removeFilial(Id idFilial) {
        mFilialIDName.remove(idFilial);
    }
  }
}