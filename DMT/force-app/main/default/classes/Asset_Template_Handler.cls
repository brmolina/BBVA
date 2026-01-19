/*
* Handler del Trigger de Asset Template
*/
@SuppressWarnings('sf:TooManyMethods,sf:NullAssignment')
public with sharing class Asset_Template_Handler {

  /** instance */
  private static Asset_Template_Handler instance;

  /*
  * getInstance
  */
  public static Asset_Template_Handler getInstance() { //NOSONAR
    if (instance == null) {
        instance = new Asset_Template_Handler();
      }
      return instance;
  }
/*
   * Met0d0 para añadir el class al asset type el Asset_Template
   */
  public void setAssetClass(List<Asset_Template__c> newList) { //NOSONAR
    system.debug(Logginglevel.INFO,'>>>>>>> Entrando trigger E-commerce Registry (before insert)');
    system.debug('>>>>>>>>>> ' + newList);
    List<String> lRTID;
    lRTID = new List<String> ();
    for (Asset_Template__c template : newList) {
      lRTID.add(template.RecordTypeID);
    }
    Map<Id, RecordType> mRecordType;
    mRecordType = new Map<Id, RecordType> ([SELECT id, Name FROM RecordType WHERE id IN :lRTID]);
    for (Asset_Template__c template : newList) {
      template.Asset_Class__c = mRecordType.get(template.RecordTypeID).Name.replace('Asset Class: ','');
    	system.debug('>>>>>>>>> ' + template.Asset_Class__c);
    	system.debug('>>>>>>>> ' + mRecordType.get(template.RecordTypeID).Name);
    	system.debug('>>>>>>> ' + mRecordType.get(template.RecordTypeID).Name.replace('Asset Class: ',''));
    }
  }
  /*
  * Met0d0 para comprobar si debe o no eliminarse el Asset_Template
  */
  public void checkDelete(List<Asset_Template__c> oldList) { //NOSONAR
    system.debug(Logginglevel.INFO,'>>>>>>> Entrando trigger E-commerce Registry (before delete)');
    Asset_Template_Handler_out.checkDelete(oldList);
  }

  /*
   * Met0d0 para añadir el grupo del trader
   */
  public void compareStageChange(List<Asset_Template__c> newList, Map<ID, Asset_Template__c> mapOldList) { //NOSONAR
    List<String> lIDs;
    lIDs = new List<String>();
    List<Asset_Template__c> tempToAssign;
    tempToAssign = new List<Asset_Template__c>();
    for (Asset_Template__c template : newList) {
      if(template.Status__c == 'Validate' && template.Status__c != mapOldList.get(template.id).Status__c) {
        tempToAssign.add(template);
        lIDs.add(template.id);
      }
    }
    splitApproves(tempToAssign, lIDs);
    setTraderGroup(tempToAssign, lIDs);
  }

  /*
   * Met0d0 para crear aprobaciones multiples por producto y currency
   */
  private static void splitApproves(List<Asset_Template__c> tempToAssign, List<String> lIDs) { //CAMBIADO A ESTÁTICO
    System.debug(tempToAssign);
    String all;
    all = 'All';
    String emProd;
    emProd = 'EM (Hard & Local Currency)';
    System.debug(emProd);

    //Recoremos los productos con currency All y guardamos sus asset type y sus prods
    List<String> lAssetFXProdID;
    lAssetFXProdID = new List<String> ();
    List<String> lAssetFXTypes;
    lAssetFXTypes = new List<String> ();
    List<String> lFXProducts;
    lFXProducts = new List<String> ();

    //Recoremos los productos EM (Hard & Local Currency) y guardamos sus asset type y sus prods
    List<String> lAssetFIProdID;
    lAssetFIProdID = new List<String> ();
    List<String> lAssetFITypes;
    lAssetFITypes = new List<String> ();
    List<String> lFIProducts;
    lFIProducts = new List<String> ();
    System.debug(lAssetFIProdID+''+lAssetFITypes+''+lFIProducts);

    for (Asset_Product__c tempProd : [SELECT id, Platform__c, Product__c, Currency_Traded__c, Asset_Template__r.Asset_Class__c FROM Asset_Product__c WHERE Asset_Template__c IN :lIDs AND (Currency_Traded__c = 'All' OR  Product__c = 'EM (Hard & Local Currency)')]) {
      if(tempProd.Currency_Traded__c == all) {
        lAssetFXTypes.add(tempProd.Asset_Template__r.Asset_Class__c);
        lFXProducts.add(tempProd.Product__c);
        lAssetFXProdID.add(tempProd.id);
      } else if(tempProd.Product__c == emProd) {
        lAssetFITypes.add(tempProd.Asset_Template__r.Asset_Class__c);
        lFIProducts.add(tempProd.Product__c);
        lAssetFIProdID.add(tempProd.id);
      }
    }

    //Recorremos tdos los grupos para esos productos y plataformas
    Map<String, Asset_Group__c> mGroup;
    mGroup = new Map<String, Asset_Group__c>();
    for (Asset_Group__c assetGroup : [SELECT id, Name, Asset_Name__c, Product__c, Currency__c, Asset_Type__c FROM Asset_Group__c WHERE Asset_Type__c IN :lAssetFXTypes AND Product__c IN :lFXProducts]) {
      mGroup.put('E-Commerce-'+assetGroup.Name, assetGroup);
    }

    Map<String, List<String>> mProdCurrency;
    mProdCurrency = getmProdCurrency(mGroup);

    cloneAssetProductFX (lAssetFXProdID, mProdCurrency);
    cloneAssetProductFI (lAssetFIProdID);

  }

  /*
   * Metd0 para añadir el grupo del trader
   * CAMBIADO A ESTÁTICO
   */
  private static void setTraderGroup(List<Asset_Template__c> tempToAssign, List<String> lIDs) {
    System.debug(tempToAssign);
    List<Asset_Product__c> lUpdate;
    lUpdate = new List<Asset_Product__c>();
    Map<String, String> mAssetName;
    mAssetName = new Map<String, String>();
    Map<String, String> mUpdateTrader;
    mUpdateTrader = new Map<String, String>();
    Set<String> sGroupIDs;
    sGroupIDs = new Set<String>();
    String fxProd;
    fxProd = 'FX';
    String name;
    for (Asset_Product__c tempProd : [SELECT id, Platform__c, Product__c, Currency_Traded__c, Asset_Template__r.Asset_Class__c FROM Asset_Product__c WHERE Asset_Template__c IN :lIDs]) {

      name = 'E-Commerce-'+tempProd.Asset_Template__r.Asset_Class__c+'-'/*+tempProd.Platform__c+'-'*/+tempProd.Product__c;
      if(tempProd.Asset_Template__r.Asset_Class__c == fxProd) {
        name+='-'+tempProd.Currency_Traded__c;
      }
      mAssetName.put(tempProd.Id, name.replace(' ',''));
    }

    for (Asset_Group__c assetGroup : [SELECT id, Name, Asset_Name__c FROM Asset_Group__c WHERE Asset_Name__c IN :mAssetName.values()]) {
      mUpdateTrader.put('E-Commerce-'+assetGroup.Name, assetGroup.Asset_Name__c);
    }

    List<Group> lTraderGroup;
    lTraderGroup = [SELECT id, Name FROM Group WHERE Name IN :mUpdateTrader.keySet()];

    for (String idTemp : mAssetName.keySet()) {
      for(Group traderGroup : lTraderGroup) {
        if(mUpdateTrader.get(traderGroup.Name) == mAssetName.get(idTemp)) {
          lUpdate.add(new Asset_Product__c(ID= idTemp, Trader_Group__c = traderGroup.Id));
          sGroupIDs.add(traderGroup.Id);
        }
      }
    }
    //lUpdate.get(9).Product__c = 'aa';
    update lUpdate;
    Buttons_Onboarding_Controller.allApprove(lIDs);

    sendTraderNotification(lIDs, sGroupIDs);
  }

  /*
  *Recorriendo los miembros de los grupos sacamos los grupos con miembros, y guardamos los productos currency que tengan miembros
  *CAMBIADO A ESTÁTICO
  */
  private static Map<String, List<String>> getmProdCurrency(Map<String, Asset_Group__c> mGroup) {
    Set<String> sGroupWithPeople;
    sGroupWithPeople = new Set<String> ();
    List<String> lCurrencies;
    lCurrencies = new List<String> ();
    System.debug(lCurrencies);
    Map<String, List<String>> mProdCurrency;
    mProdCurrency = new Map<String, List<String>>();
    for(GroupMember groupMem : [SELECT id, GroupId, Group.Name, UserOrGroupId FROM GroupMember WHERE Group.Name IN :mGroup.keySet()]) {
      if(!sGroupWithPeople.contains(groupMem.Group.Name)) {
        sGroupWithPeople.add(groupMem.Group.Name);
        if(mProdCurrency.containsKey(mGroup.get(groupMem.Group.Name).Product__c)) {
          lCurrencies = new List<String> ();
          lCurrencies.addAll(mProdCurrency.get(mGroup.get(groupMem.Group.Name).Product__c));
          lCurrencies.add(mGroup.get(groupMem.Group.Name).Currency__c);
          mProdCurrency.put(  mGroup.get(groupMem.Group.Name).Product__c  ,  lCurrencies );
        } else {
          mProdCurrency.put( mGroup.get(groupMem.Group.Name).Product__c , new list<String> {mGroup.get(groupMem.Group.Name).Currency__c} );
        }
      }
    }
    return mProdCurrency;
  }

  /*
  * Clone object for FX
  */
  private static void cloneAssetProductFX (List<String> lAssetProdID, Map<String, List<String>> mProdCurrency) {
    try {
      String getQuery = '';
      System.debug(lAssetProdID);
      getQuery = conSOQLFields() + ' where id =: lAssetProdID';

      Asset_Product__c assetProdClone;
      List<Asset_Product__c> lNewAssetProd;
      lNewAssetProd = new List<Asset_Product__c> ();

      for(Asset_Product__c assetProd : Database.query(String.escapeSingleQuotes(getQuery))) {
        for(String prodName : mProdCurrency.keySet()) {
          for(String crr : mProdCurrency.get(prodName)) {
            assetProdClone = new Asset_Product__c();
            assetProdClone = assetProd.clone(false, true, false, false);
            assetProdClone.Currency_Traded__c = crr;
            assetProdClone.Is_Clone__c = true;
            assetProdClone.Is_cloned_from__c = assetProd.id;
            lNewAssetProd.add(assetProdClone);
          }
        }
      }

      insert lNewAssetProd;
    } catch (Exception e) {
      throw new AuraHandledException(Label.DES_Error + e);
    }
  }

  /*
  * Clone object for FI
  */
  private static void cloneAssetProductFI (List<String> lAssetProdID) { //NOSONAR
    try {
      String getQuery = '';
      System.debug(lAssetProdID);
      getQuery = conSOQLFields() + ' where id =: lAssetProdID';
      //Cogemos las currency del asset Fixed income
      List<String> lAll;
      lAll = Label.E_Commerce_FI_Currency.split('::');

      Asset_Product__c assetProdClone;
      List<Asset_Product__c> lNewAssetProd;
      lNewAssetProd = new List<Asset_Product__c> ();

      for(Asset_Product__c assetProd : Database.query(String.escapeSingleQuotes(getQuery))) {
        for(String prod : lAll) {
          assetProdClone = new Asset_Product__c();
          assetProdClone = assetProd.clone(false, true, false, false);
          assetProdClone.Product__c = prod;
          assetProdClone.Is_Clone__c = true;
          assetProdClone.Is_cloned_from__c = assetProd.id;
          lNewAssetProd.add(assetProdClone);
        }
      }

      insert lNewAssetProd;
    } catch (Exception e) {
      throw new AuraHandledException(Label.DES_Error + e);
    }
  }

  /*
  * Get soql with all fields
  */
  private static String conSOQLFields () {
      Map<String, Schema.SObjectField> fieldMap;
      fieldMap = Asset_Product__c.sObjectType.getDescribe().fields.getMap();
      Set<String> fieldNames;
      fieldNames = fieldMap.keySet();
      String sFields;
      sFields = String.join(new List<String>(fieldNames), ',');
      return 'select ' + sFields + ' from Asset_Product__c ';
  }

  /*
  * Send trader notification
  */
  private static void sendTraderNotification (List<String> lIDs, Set<String> sGroupIDs) {
    FeedItem post;
    List<FeedItem> lFeed;
    lFeed = new List<FeedItem>();
    String body;
    body = 'As part of the trader team, form formName is ready for your validation. Please access the following link: ' + URL.getOrgDomainURL().toExternalForm() + '/selectedID';
    String bodyReplace;

    Map<String, List<String>> mGroupMembers;
    mGroupMembers = getGroupMember(sGroupIDs);

    Map<String, Set<String>> mAssetTrader;
    mAssetTrader = getTemplateMembers (lIDs, mGroupMembers);

    for(String assetNameID : mAssetTrader.keySet()) {
      bodyReplace = body.replace('formName', assetNameID.split('::').get(0));
      bodyReplace = bodyReplace.replace('selectedID', assetNameID.split('::').get(1));
      for(String traderID : mAssetTrader.get(assetNameID)) {
        post = new FeedItem();
        post.ParentId = traderID; // Record Id eg. Opportunity id, custom object id..
        post.Body = bodyReplace;
        //post.LinkUrl = 'http://www.infallibletechie.com';
        lFeed.add(post);
      }
    }

    insert lFeed;
  }

  /*
  * Get members group
  */
  private static Map<String, List<String>> getGroupMember (Set<String> sGroupIDs) {

    Set<String> sUserIDs;
    sUserIDs = new Set<String> ();
    List<GroupMember> lTraderMember;
    lTraderMember = [SELECT id, GroupId, UserOrGroupId FROM GroupMember WHERE GroupId IN :sGroupIDs];
    for(GroupMember traderMember : lTraderMember) {
      sUserIDs.add(traderMember.UserOrGroupId);
    }

    List<String> sActiveIDs;
    sActiveIDs = new List<String> ();
    for(User userActive : [SELECT id FROM User WHERE id IN :sUserIDs AND isActive = true AND DES_Disable_Chatter__c = false]) {
      sActiveIDs.add(userActive.id);
    }

    Map<String, List<String>> mGroupMembers;
    mGroupMembers = new Map<String, List<String>>();
    List<String> lMember;
    for(GroupMember traderMember : lTraderMember) {
      if(!mGroupMembers.containsKey(traderMember.GroupId) && sActiveIDs.contains(traderMember.UserOrGroupId)) {
        mGroupMembers.put(traderMember.GroupId, new List<String> {traderMember.UserOrGroupId});
      } else if(sActiveIDs.contains(traderMember.UserOrGroupId)) {
        lMember = new List<String> ();
        lMember.addAll(mGroupMembers.get(traderMember.GroupId));
        lMember.add(traderMember.UserOrGroupId);
        mGroupMembers.put(traderMember.GroupId, lMember);
      }
    }
    return mGroupMembers;
  }

  /*
  * Get members from asset template
  */
  private static Map<String, Set<String>> getTemplateMembers (List<String> lIDs, Map<String, List<String>> mGroupMembers) {
    Set<String> sMember;
    Map<String, Set<String>> mAssetTrader;
    mAssetTrader = new Map<String, Set<String>>();
    for (Asset_Template__c assetTemp : [SELECT id, Name, (SELECT id, Trader_Group__c FROM Asset_Products__r) FROM Asset_Template__c WHERE id IN :lIDs]) {
      sMember = new Set<String>();
      for(Asset_Product__c assetProd : assetTemp.Asset_Products__r) {
        if(mGroupMembers.containsKey(assetProd.Trader_Group__c)) {
          sMember.addAll(mGroupMembers.get(assetProd.Trader_Group__c));
        }
      }
      mAssetTrader.put(assetTemp.Name+'::'+assetTemp.id, sMember);
    }
    return mAssetTrader;
  }
}