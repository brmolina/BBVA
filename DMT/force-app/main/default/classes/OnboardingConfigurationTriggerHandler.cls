/*
* OnboardingConfigurationTriggerHandler
*/
public without sharing class OnboardingConfigurationTriggerHandler {

  /** instance */
  private static OnboardingConfigurationTriggerHandler instance;

  /*
  * getInstance
  */
  public static OnboardingConfigurationTriggerHandler getInstance() { //NOSONAR
    if (instance == null) {
        instance = new OnboardingConfigurationTriggerHandler();
      }
      return instance;
  }

  /*
  * New public group
  */
  public void newListGroupName(List<Onboarding_Configuration__c> lProducts) { //NOSONAR
    List<String> lNewNames;
    lNewNames = new List<String>();
    List<Group> lInsertGr;
    lInsertGr = new List<Group>();
    List<Asset_Group__c> lInsertAs = new List<Asset_Group__c>();
    //new group
    Map<String, Asset_Group__c> mGroups;
    mGroups =  setGroupNames(lProducts);
    Set<String> lGroups;
    lGroups = mGroups.keySet();
    //existing group
    List<String> lOldGroup;
    lOldGroup=getGroupOnBBDD(lGroups);

    for(String name : lGroups) {
      if(!lOldGroup.contains(name)) {
        lInsertAs.add(new Asset_Group__c(Asset_Name__c=name, Asset_Type__c=mGroups.get(name).Asset_Type__c, Product__c=mGroups.get(name).Product__c, Currency__c=mGroups.get(name).Currency__c));
        lNewNames.add(name);
      }
    }
    insert lInsertAs;

    lInsertAs =[SELECT Name FROM Asset_Group__c WHERE Asset_Name__c IN :lNewNames];

    for(Asset_Group__c traderGroup : lInsertAs) {
      lInsertGr.add(new Group(Name='E-Commerce-'+traderGroup.Name,DoesIncludeBosses=false));
    }
    insert lInsertGr;
  }

  /*
  * Update public group
  */
  public void updateListGroupName(List<Onboarding_Configuration__c> lnewProducts, Map<Id, Onboarding_Configuration__c> mOldProducts) {
    List<Onboarding_Configuration__c> lOnboard;
    lOnboard = new List<Onboarding_Configuration__c>();
    for(Onboarding_Configuration__c config : lnewProducts) {
      if(mOldProducts.get(config.id).Product__c != config.Product__c || mOldProducts.get(config.id).Platform__c != config.Platform__c) {
        lOnboard.add(config);
      }
    }
    newListGroupName(lOnboard);
  }

  /*
  * Get group names
  *CAMBIADO A ESTÁTICO
  */
  private static Map<String, Asset_Group__c> setGroupNames(List<Onboarding_Configuration__c> lProducts) {
      Map<Id, RecordType> mRecordtype;
      mRecordtype = new Map<Id, RecordType> ([SELECT id, Name FROM RecordType WHERE SobjectType = 'Onboarding_Configuration__c']);
      System.debug(mRecordtype);
      Map<String, Asset_Group__c> mResult;
      mResult = new Map<String, Asset_Group__c> ();
      List<String> lGroups;
      lGroups = new List<String>();
      System.debug(lGroups);
      String name;
      String currName;
      String fxS;
      fxS = 'FX';
      System.debug(fxS);

      List<String> lExclude;
      lExclude = Label.E_Commerce_Exclude_prods.split('::');
      List<String> lExcludeAsset;
      lExcludeAsset = Label.E_Commerce_Exclude_Asset.split('::');
      for(Onboarding_Configuration__c prod : lProducts) {

        //Excluimos los productos especiales que no tienen aprovador ni
        if(!lExclude.contains(prod.Product__c) && !lExcludeAsset.contains(prod.Asset__c)) {
          name = 'E-Commerce-'+mRecordtype.get(prod.RecordTypeId).Name+'-'/*+prod.Platform__c+'-'*/+prod.Product__c;
          if(mRecordtype.get(prod.RecordTypeId).Name == fxS) {
            for(String curr : conAllCurrency()) {
              currName=name+'-'+curr;
              if(!lGroups.contains(currName.replace(' ',''))) {
                lGroups.add(currName.replace(' ',''));
                mResult.put(currName.replace(' ',''), new Asset_Group__c(Asset_Type__c=mRecordtype.get(prod.RecordTypeId).Name, Product__c=prod.Product__c,Currency__c=curr));
              }
            }
          } else {
            if(!lGroups.contains(name.replace(' ',''))) {
              lGroups.add(name.replace(' ',''));
              mResult.put(name.replace(' ',''), new Asset_Group__c(Asset_Type__c=mRecordtype.get(prod.RecordTypeId).Name, Product__c=prod.Product__c));
            }
          }
        }
      }
      return mResult;
  }

  /*
  * Get group names
  */
  private static List<String> getGroupOnBBDD(Set<String> lGroups) {
      List<String> lNames;
      lNames = new List<String>();
      for(Asset_Group__c groupName : [select Id, Asset_Name__c from Asset_Group__c Where Asset_Name__c IN :lGroups]) {
        lNames.add(groupName.Asset_Name__c);
      }
      return lNames;
  }

  /*
  * Get Currencies
  */
  private static List<String> conAllCurrency() {
    String allS;
    allS = 'All';
    List<String> pickListValL;
    pickListValL= new List<String>();
		Schema.DescribeFieldResult fieldResult;
    fieldResult = Asset_Product__c.Currency_Traded__c.getDescribe();
		List<Schema.PicklistEntry> ple;
    ple = fieldResult.getPicklistValues();
		for( Schema.PicklistEntry pickListVal : ple) {
      if(pickListVal.getLabel()!=allS) {
			  pickListValL.add(pickListVal.getLabel());
      }
		}
		return pickListValL;
  }
}