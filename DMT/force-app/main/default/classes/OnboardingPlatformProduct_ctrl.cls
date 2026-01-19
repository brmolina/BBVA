/*
*Author: ADESSO
*
*/
@SuppressWarnings('sf:NPathComplexity, sf:CyclomaticComplexity, sf:TooManyMethods, sf:NcssMethodCount, sf:ExcessiveMethodLength, sf:UseObjectForClearerAPI')
public with sharing class OnboardingPlatformProduct_ctrl {
    /*
    * String
    */
    static final String NULO = 'null';
    /*
    * String
    */
    static final String CONDICION = 'BOOLEAN';
    /*
    * String
    */
    static final String LITERAL = 'STRING';
    /*
    *String
    */
    static final String OBJECTNAME = 'Asset_Product__c';

  private OnboardingPlatformProduct_ctrl() {}

  /*
  * Recoger los ids de los productos
  */
  @AuraEnabled
  public static List<String> getProductIDs(String assetID) {
    try {
      String valid;
      valid = 'Validate';
      System.debug(valid);
      Set<String> lProdIDs = new Set<String>();
      List<Asset_Product__c> lAssertProd;
      lAssertProd = [SELECT id, Asset_Template__r.Asset_Class__c, Asset_Template__r.Status__c, Trader_Group__c, Is_Clone__c, Is_cloned_from__c  FROM Asset_Product__c WHERE Asset_Template__c = :assetID ORDER BY CreatedDate ASC];

      if(lAssertProd!=null && !lAssertProd.isEmpty()) {
        //si es validate mostramos solo las operaciones de las que soy el trader, si no soy el trader muestro todas
        if(lAssertProd.get(0).Asset_Template__r.Status__c == valid) {
          lProdIDs = getProdsIfTrader(lAssertProd);
        } else {
        //si no es validate mostramos todas las operaciones
          lProdIDs = getProds(lAssertProd);
        }
      }

      return new List<String>(lProdIDs);
    } catch (Exception e) {
      throw new AuraHandledException(Label.DES_Error + e);
    }
  }

  /*
  * Selecciona los productos del asset
  */
  private static Set<String> getProds(List<Asset_Product__c> lAssertProd) {
    Set<String> lProdIDs;
    lProdIDs = new Set<String>();
    for(Asset_Product__c assetProd : lAssertProd) {
      if(!assetProd.Is_Clone__c) {
        lProdIDs.add(assetProd.id);
      }
    }
    return lProdIDs;
  }

  /*
  * Selecciona los productos de los cuales soy trader
  */
  private static Set<String> getProdsIfTrader(List<Asset_Product__c> lAssertProd) {
    String fixedIncome;
    fixedIncome = 'Fixed Income';
    System.debug(fixedIncome);
    final Id myUserID = UserInfo.getUserId();
    final Set<String> sGroups = new Set<String> ();
    final Set<String> sMyGroups = new Set<String> ();
    Set<String> lIDsResult;
    lIDsResult = new Set<String> ();
    System.debug(fixedIncome);

    for(Asset_Product__c assetProd : lAssertProd) {
      sGroups.add(assetProd.Trader_Group__c);
    }

    for(GroupMember groupMem : [SELECT id, GroupId, Group.Name, UserOrGroupId FROM GroupMember WHERE GroupId IN :sGroups AND UserOrGroupId = :myUserID]) {
      sMyGroups.add(groupMem.GroupId);
    }

    //si es clonado de fixed income mostramos el producto de que es clonado, si es de tipo fx mostramos solo sus currencies
    for(Asset_Product__c assetProd : lAssertProd) {
      if(sMyGroups.contains(assetProd.Trader_Group__c)) {
        if(assetProd.Asset_Template__r.Asset_Class__c == fixedIncome && assetProd.Is_Clone__c) {
          lIDsResult.add(assetProd.Is_cloned_from__c);
        } else {
          lIDsResult.add(assetProd.id);
        }
      }
    }

    //si no encuentra nada es que no soy validadador de ninguna, con lo que muestro todas
    if(lIDsResult.isEmpty()) {
      lIDsResult = getProds(lAssertProd);
    }
    return lIDsResult;

  }

  /*
  * Recoger los ids de los productos
  */
  @AuraEnabled
  public static String addNewAssetProduct(String assetID) {
    try {
        Asset_Product__c assetProd;
        assetProd = new Asset_Product__c (Asset_Template__c=assetID);
        insert assetProd;
        return assetProd.id;
    } catch (Exception e) {
      throw new AuraHandledException(Label.DES_Error + e);
    }
  }

  /*
  * Recoger los valores de cada producto
  */
  @AuraEnabled
  public static String getProductFields(String productID) {
    try {
      String platProd = '';
      Boolean flag;
      Boolean flagClone;
      for(Asset_Product__c onTemp : [SELECT id, Clearing_House__c, Access__c, Format__c, Prior_Platform__c, Platform__c, Trader_Group__c, Product__c, Tier__c, Asset_Template__r.Onboarding_Type__c,Asset_Template__r.OwnerId, Asset_Template__r.Asset_Class__c, Asset_Template__r.Secondary_Sales_Id__c, Asset_Template__r.Status__c, Is_Clone__c FROM Asset_Product__c WHERE id = :productID]) {
        flag = false;
        flagClone = false;

        String newS;
        newS = 'New';
        String vali;
        vali = 'Validate';
        System.debug(vali);

        Boolean user;
        user = getUserId(onTemp.Asset_Template__r.OwnerId);
        if(onTemp.Asset_Template__r.Status__c == newS && user) {
          flag = true;
        }

        if(onTemp.Is_Clone__c) {
          flagClone = true;
        } else if(onTemp.Trader_Group__c == null && onTemp.Asset_Template__r.Status__c == vali) {
          flagClone = true;
        }
        platProd += onTemp.Platform__c + '::';
        platProd += onTemp.Product__c + '::';
        platProd += onTemp.Tier__c + '::';
        platProd += onTemp.Asset_Template__r.Onboarding_Type__c + '::';
        platProd += onTemp.Asset_Template__r.Asset_Class__c + '::';
        platProd += onTemp.Prior_Platform__c + '::';
        platProd += flag + '::';
        platProd += flagClone + '::';
        platProd += onTemp.Clearing_House__c + '::';
        platProd += onTemp.Access__c + '::';
        platProd += onTemp.Format__c + '::';
        platProd += onTemp.Asset_Template__r.Status__c + '::';
        platProd += EsalesDynamicButtonsHandler.getProfile();
      }
      return platProd;
    } catch (Exception e) {
      throw new AuraHandledException(Label.DES_Error + e);
    }
  }
  /*
  * Recoger los valores de plataforma en funcion del asset
  */
  @AuraEnabled
  public static List<String> getPlatformList(String assetType, String oldPlatform) {
    try {
      Set<String> lPlatform;
      lPlatform = new Set<String>();
      for(Onboarding_Configuration__c onTemp : [SELECT id, Asset__c, Platform__c, Product__c FROM Onboarding_Configuration__c WHERE Asset__c = :assetType ORDER BY Platform__c]) {
        lPlatform.add(onTemp.Platform__c);
      }
      if(oldPlatform != null && oldPlatform != NULO && oldPlatform != '') {
        lPlatform.add(oldPlatform);
      }
      return new List<String>(lPlatform);
    } catch (Exception e) {
      throw new AuraHandledException(Label.DES_Error + e);
    }
  }

  /*
  * Recoger los valores de plataforma en funcion del asset
  */
  @AuraEnabled
  public static List<String> getProductList(String assetType, String platformType, String oldPlatform, String oldProduct) { //NOSONAR
    try {
      Set<String> lProduct;
      lProduct = new Set<String>();
      for(Onboarding_Configuration__c onTemp : [SELECT id, Asset__c, Platform__c, Product__c FROM Onboarding_Configuration__c WHERE Asset__c = :assetType AND Platform__c = :platformType ORDER BY Product__c]) {
        lProduct.add(onTemp.Product__c);
      }
      if(oldProduct != null && oldProduct != NULO && oldProduct != '' && platformType == oldPlatform) {
        lProduct.add(oldProduct);
      }
      return new List<String>(lProduct);
    } catch (Exception e) {
      throw new AuraHandledException(Label.DES_Error + e);
    }
  }

  /*
  * Recoger los valores de tier en funcion del producto
  */
  @AuraEnabled
  public static List<String> getTierList(String assetType, String platformType, String productType, String oldPlatform, String oldProduct, String oldTier) { //NOSONAR
    try {
      List<String> lTier;
      lTier = new List<String>();
      for(Onboarding_Configuration__c onTemp : [SELECT id, Asset__c, Platform__c, Product__c, Tier__c FROM Onboarding_Configuration__c WHERE Asset__c = :assetType AND Platform__c = :platformType AND Product__c = :productType ORDER BY Product__c]) {
        lTier.addAll(onTemp.Tier__c.split(';'));
      }
      if(oldTier != null && oldTier != NULO && oldTier != '' && !lTier.contains(oldTier) && platformType == oldPlatform && productType == oldProduct) {
        lTier.add(oldTier);
      }
      return lTier;
    } catch (Exception e) {
      throw new AuraHandledException(Label.DES_Error + e);
    }
  }

  /*
  * Recoger los valores de las nuevas picklist
  */
  @AuraEnabled
  public static List<String> getPickListValues(String picklistAPI, String oldValue) {
    try {
      Set<String> lassetPick;
      lassetPick = new Set<String>();
      for(Asset_Picklist__c assetPick : [SELECT id, Field_Name__c, Value__c FROM Asset_Picklist__c WHERE Field_Name__c = :picklistAPI ORDER BY Value__c]) {
        lassetPick.add(assetPick.Value__c);
      }
      if(oldValue != null && oldValue != NULO && oldValue != '') {
        lassetPick.add(oldValue);
      }
      return new List<String>(lassetPick);
    } catch (Exception e) {
      throw new AuraHandledException(Label.DES_Error + e);
    }
  }

  /*
  * Recoger los valores de plataforma en funcion del asset
  */
  @AuraEnabled
  public static void delAssetProduct (String assetProdID ) { //NOSONAR
    try {
      delete new Asset_Product__c (id=assetProdID);
    } catch (Exception e) {
      throw new AuraHandledException(Label.DES_Error + e);
    }
  }

  /*
  * Recoger los valores de plataforma en funcion del asset
  */
  @AuraEnabled
  public static void cloneAssetProduct (Asset_Product__c assetProd, String assetProdID) {
    try {
      final String assetID = [SELECT id, Asset_Template__c FROM Asset_Product__c WHERE id =: assetProdID].Asset_Template__c;
      Asset_Product__c assetProdClone;
      assetProdClone = assetProd;
      assetProdClone.Asset_Template__c= assetID;
      insert assetProd;
    } catch (Exception e) {
      throw new AuraHandledException(Label.DES_Error + e);
    }
  }


  /*
  * Recoge los campos del fieldset
  */
  @AuraEnabled
  public static List<String> getFieldSetFromAsset (String assetType, String onboardType, String platform, String product, String typeToGet, String stage) { //NOSONAR
    List<String> lFields;
    lFields = new List<String>();
    List<String> lFieldsWrong;
    List<String> lFieldsDel;
    lFieldsDel = getFieldSetExclude(onboardType, assetType, platform, product);

    final String fieldset = onboardType + assetType;
    final String excludePicklist = Label.E_Commerce_Picklist;
    System.debug('excludePicklist ' + excludePicklist);

    Schema.SObjectType sObj;
    sObj = Schema.getGlobalDescribe().get(OBJECTNAME);

    try {
      for(Schema.FieldSetMember fieldMember : sObj.getDescribe().fieldSets.getMap().get(fieldset.replace(' ', '')).getFields()) {
        //excluimos los campos dependientes de plataforma o producto
        if(!lFieldsDel.contains(fieldMember.getFieldPath())) {
          //excluimos las picklist cuando cogemos el fieldset completo
          if(typeToGet == 'ALL' || typeToGet == 'WRONG' || (typeToGet == 'EDIT' && !excludePicklist.contains(fieldMember.getFieldPath()))) {
            lFields.add(fieldMember.getFieldPath());
          }
          if(typeToGet == 'PICKLIST' && excludePicklist.contains(fieldMember.getFieldPath())) {
            lFields.add(fieldMember.getFieldPath());
          }
        }
      }
    } catch(Exception exc) {
      System.debug('exc ' + exc);
    }
    lFieldsWrong = excludeByStage(lFields, stage, false);
    lFields = excludeByStage(lFields, stage, true);
    lFields = excludeByRole(lFields, typeToGet);

	  return typeToGet=='WRONG'?lFieldsWrong:lFields;
  }

  private static List<String> excludeByStage (List<String> listAtt, String stageString, Boolean remove) {
    String wrongDataSt;
    wrongDataSt = 'Wrong Data';
    List<String> lResultRemove;
    lResultRemove = listAtt;
    List<String> lResultAdd;
    lResultAdd = new List<String>();
    if(stageString == wrongDataSt) {
      Schema.SObjectType sObj;
      sObj = Schema.getGlobalDescribe().get(OBJECTNAME);
      Integer numIndex;
      for(Schema.FieldSetMember fieldMember : sObj.getDescribe().fieldSets.getMap().get('HideWrongData').getFields()) {
        numIndex = listAtt.indexOf(fieldMember.getFieldPath());
        if(numIndex != -1 && remove) {
          lResultRemove.remove(numIndex);
        } else if (listAtt.contains(fieldMember.getFieldPath()) && !remove) {
          lResultAdd.add(fieldMember.getFieldPath());
        }
      }
    }
    return remove?lResultRemove:lResultAdd;
  }

  private static List<String> excludeByRole (List<String> listAtt, String typeString) {
    EsalesDynamicButtonsHandler buttonHandler;
    buttonHandler = new EsalesDynamicButtonsHandler();
    List<String> lResultRemove;
    lResultRemove = listAtt;
    Integer numIndex;
    numIndex = listAtt.indexOf('Set_up_of_Drop_Copy__c');
    if(numIndex != -1 && (typeString == 'EDIT' ||  typeString == 'WRONG') && !buttonHandler.rolImplement('GLOBAL MARKETS ECOMMERCE SALES') && !EsalesDynamicButtonsHandler.getProfile()) {
      lResultRemove.remove(numIndex);
    }
    return lResultRemove;
  }

  /*
  * Recoge los campos del fieldset para la edicion del trader
  */
  @AuraEnabled
  public static List<String> getTraderExclude (List<String> listAtt) {
    List<String> lResultAdd;
    lResultAdd = new List<String>();
    Schema.SObjectType sObj;
    sObj = Schema.getGlobalDescribe().get(OBJECTNAME);
    for(Schema.FieldSetMember fieldMember : sObj.getDescribe().fieldSets.getMap().get('ShowTrader').getFields()) {
      if (listAtt.contains(fieldMember.getFieldPath())) {
        lResultAdd.add(fieldMember.getFieldPath());
      }
    }
    return lResultAdd;
  }

  /*
  * Recoge los campos del fieldset a excluir
  */
  private static List<String> getFieldSetExclude (String onbType, String assetType, String platform, String product) {
    String allBloomberg;
    allBloomberg = 'AllBloomberg';
    String fxBBVAeMarkets;
    fxBBVAeMarkets = 'FXBBVAeMarkets';
    String equityTradeweb;
    equityTradeweb = 'EquityTradeweb';
    String equityRFQHub;
    equityRFQHub = 'EquityRFQHub';
    String equityBlooDLIB;
    equityBlooDLIB = 'EquityBloombergDLIB';
    String equityEmailPricer;
    equityEmailPricer = 'EquityEmailPricer';
    String equityWebPricer;
    equityWebPricer = 'EquityWebPricer';
    String usts;
    usts = 'USTs';
    String hideS;
    hideS = 'Hide';
    String onboardCompare;
    onboardCompare = onbType==null?null:onbType.replace(' ','');
    String assetCompare;
    assetCompare = assetType==null?null:assetType.replace(' ','');
    String platformCompare;
    platformCompare = platform==null?null:platform.replace(' ','');
    String productCompare;
    productCompare = product==null?null:product.replace(' ','');
    List<String> lFields;
    lFields = new List<String>();

    Schema.SObjectType sObj;
    sObj = Schema.getGlobalDescribe().get(OBJECTNAME);
    System.debug(sObj);

    try {
      if('All'+platformCompare != allBloomberg) {
        for(Schema.FieldSetMember fieldMember : sObj.getDescribe().fieldSets.getMap().get(hideS+allBloomberg).getFields()) {
          if(!lFields.contains(fieldMember.getFieldPath())) {
            lFields.add(fieldMember.getFieldPath());
          }
        }
      }

      String fxSt;
      fxSt = 'FX';
      //Quitar campos si es FX
      if(assetType == fxSt) {
        if(assetCompare+platformCompare != fxBBVAeMarkets) { //NOSONAR
          for(Schema.FieldSetMember fieldMember : sObj.getDescribe().fieldSets.getMap().get(hideS+fxBBVAeMarkets).getFields()) {
            if(!lFields.contains(fieldMember.getFieldPath())) {
              lFields.add(fieldMember.getFieldPath());
            }
          }
        }
      }

      String equitySt;
      equitySt = 'Equity';
      //Quitar campos si es Equity
      if(assetType == equitySt) {

        if(onbType == 'Reject User' || onbType == 'Reject Client') {
          platformCompare+=onboardCompare;
          equityTradeweb+=onboardCompare;
          equityRFQHub+=onboardCompare;
          equityBlooDLIB+=onboardCompare;
          equityEmailPricer+=onboardCompare;
          equityWebPricer+=onboardCompare;
        }

        if(assetCompare+platformCompare != equityTradeweb) {
          for(Schema.FieldSetMember fieldMember : sObj.getDescribe().fieldSets.getMap().get(hideS+equityTradeweb).getFields()) {
            if(!lFields.contains(fieldMember.getFieldPath())) {
              lFields.add(fieldMember.getFieldPath());
            }
          }
        }
        if(assetCompare+platformCompare != equityRFQHub) {
          for(Schema.FieldSetMember fieldMember : sObj.getDescribe().fieldSets.getMap().get(hideS+equityRFQHub).getFields()) {
            if(!lFields.contains(fieldMember.getFieldPath())) {
              lFields.add(fieldMember.getFieldPath());
            }
          }
        }
        if(assetCompare+platformCompare != equityBlooDLIB) {
          for(Schema.FieldSetMember fieldMember : sObj.getDescribe().fieldSets.getMap().get(hideS+equityBlooDLIB).getFields()) {
            if(!lFields.contains(fieldMember.getFieldPath())) {
              lFields.add(fieldMember.getFieldPath());
            }
          }
        }
        if(assetCompare+platformCompare != equityEmailPricer) {
          for(Schema.FieldSetMember fieldMember : sObj.getDescribe().fieldSets.getMap().get(hideS+equityEmailPricer).getFields()) {
            if(!lFields.contains(fieldMember.getFieldPath())) {
              lFields.add(fieldMember.getFieldPath());
            }
          }
        }
        if(assetCompare+platformCompare != equityWebPricer) {
          for(Schema.FieldSetMember fieldMember : sObj.getDescribe().fieldSets.getMap().get(hideS+equityWebPricer).getFields()) {
            if(!lFields.contains(fieldMember.getFieldPath())) {
              lFields.add(fieldMember.getFieldPath());
            }
          }
        }


        Integer numIndex;

        if(assetCompare+platformCompare == equityTradeweb) {
          for(Schema.FieldSetMember fieldMember : sObj.getDescribe().fieldSets.getMap().get(hideS+equityTradeweb).getFields()) {
            numIndex = lFields.indexOf(fieldMember.getFieldPath());
            if(numIndex != -1) {
              lFields.remove(numIndex);
            }
          }
        }
        if(assetCompare+platformCompare == equityRFQHub) {
          for(Schema.FieldSetMember fieldMember : sObj.getDescribe().fieldSets.getMap().get(hideS+equityRFQHub).getFields()) {
            numIndex = lFields.indexOf(fieldMember.getFieldPath());
            if(numIndex != -1) {
              lFields.remove(numIndex);
            }
          }
        }
        if(assetCompare+platformCompare == equityBlooDLIB) {
          for(Schema.FieldSetMember fieldMember : sObj.getDescribe().fieldSets.getMap().get(hideS+equityBlooDLIB).getFields()) {
            numIndex = lFields.indexOf(fieldMember.getFieldPath());
            if(numIndex != -1) {
              lFields.remove(numIndex);
            }
          }
        }
        if(assetCompare+platformCompare == equityEmailPricer) {
          for(Schema.FieldSetMember fieldMember : sObj.getDescribe().fieldSets.getMap().get(hideS+equityEmailPricer).getFields()) {
            numIndex = lFields.indexOf(fieldMember.getFieldPath());
            if(numIndex != -1) {
              lFields.remove(numIndex);
            }
          }
        }
        if(assetCompare+platformCompare == equityWebPricer) {
          for(Schema.FieldSetMember fieldMember : sObj.getDescribe().fieldSets.getMap().get(hideS+equityWebPricer).getFields()) {
            numIndex = lFields.indexOf(fieldMember.getFieldPath());
            if(numIndex != -1) {
              lFields.remove(numIndex);
            }
          }
        }
      }


      if(productCompare != usts) {
        for(Schema.FieldSetMember fieldMember : sObj.getDescribe().fieldSets.getMap().get(hideS+usts).getFields()) {
          lFields.add(fieldMember.getFieldPath());
        }
      }
    } catch(Exception exc) {
      System.debug('exc ' + exc);
    }

	  return lFields;
  }

  /*
  * Hace una espera
  */
  @AuraEnabled
  public static Integer waitTime(Integer timeNumber) {
    Long startingTime;
    startingTime = System.now().getTime();
    Integer delayInMill;
    delayInMill = timeNumber;
    while (System.now().getTime() - startingTime < delayInMill) {
         System.debug('wait');
     }
     return timeNumber;
  }

  /*
  * Hace una espera
  */
  @AuraEnabled
  public static void updateProduct(Asset_Product__c assetProd, String prodID, String assetType) {
    try {
      Asset_Product__c updateProd;
      updateProd = assetProd;
      updateProd.id = prodID;
      final Asset_Product__c assetProdOnb = [SELECT id, Asset_Template__r.Onboarding_Type__c FROM Asset_Product__c WHERE id = :prodID LIMIT 1];

      //vaciar los campos si no tienen valor
      updateProd.Prior_Platform__c = getPicklistValue (updateProd.Prior_Platform__c);
      updateProd.Platform__c = getPicklistValue (updateProd.Platform__c);
      updateProd.Product__c = getPicklistValue (updateProd.Product__c);
      updateProd.Tier__c = getPicklistValue (updateProd.Tier__c);
      updateProd.Clearing_House__c = getPicklistValue (updateProd.Clearing_House__c);
      updateProd.Access__c = getPicklistValue (updateProd.Access__c);
      updateProd.Format__c = getPicklistValue (updateProd.Format__c);

      final List<Onboarding_Configuration__c> onboConfig = [SELECT id, Product_support__c FROM Onboarding_Configuration__c WHERE Asset__c = :assetType AND Platform__c = :updateProd.Platform__c AND Product__c = :updateProd.Product__c ORDER BY Product__c LIMIT 1];

      if(onboConfig != null && !onboConfig.isEmpty() && onboConfig.get(0).Product_support__c != null) { //NOSONAR
        updateProd.Product_support__c = onboConfig.get(0).Product_support__c;
      } else {
        updateProd.Product_support__c = updateProd.Product__c;
      }

      //vaciar los campos que no son de su plataforma o producto
      List<String> lExclude;
      lExclude = getFieldSetExclude (assetProdOnb.Asset_Template__r.Onboarding_Type__c, assetType, updateProd.Platform__c, updateProd.Product__c);

      for(String fieldExclude : lExclude) {
        if(getTypeField(fieldExclude)==CONDICION) {
          updateProd.put(fieldExclude, false);
        }
        if(getTypeField(fieldExclude)==LITERAL) {
          updateProd.put(fieldExclude, '');
        }
        if(getTypeField(fieldExclude)=='REFERENCE' ||getTypeField(fieldExclude)=='PHONE' || getTypeField(fieldExclude)=='EMAIL' || getTypeField(fieldExclude)=='PICKLIST') {
          updateProd.put(fieldExclude, null);
        }
      }

      System.debug('updateProd '+updateProd);
      update updateProd;
    } catch (Exception e) {
      throw new AuraHandledException(Label.DES_Error + e);
    }
  }

  /*
  * Comprueba el valor de la picklist
  */
  private static String getPicklistValue (String picklistValue) {
    return picklistValue=='empty'||picklistValue==NULO?null:picklistValue; //NOSONAR
  }

  /*
  * Get field Type
  */
  private static String getTypeField (String fieldName) {
    return String.valueOf(Asset_Product__c.sObjectType.getDescribe().fields.getMap().get(fieldName).getDescribe().getType());
  }

  /*
  * Se puede editar
  */
  @AuraEnabled
  public static boolean canEditAsset(String recordID) {
    try {
      Asset_Template__c assetTemp;
      assetTemp = [SELECT id, Secondary_Sales_Id__c, Status__c, OwnerId FROM Asset_Template__c WHERE id = :recordID];

      Boolean user;
      user = getUserId(assetTemp.OwnerId);

      Boolean flag = false;
      if((assetTemp.Secondary_Sales_Id__c == UserInfo.getUserRoleId() && assetTemp.Status__c == 'Review') || (assetTemp.Status__c == 'New' && user) || assetTemp.Status__c == 'Implement' || assetTemp.Status__c == 'Wrong Data' || EsalesDynamicButtonsHandler.getProfile()) {
        flag = true;
      }
      return flag;
    } catch (Exception e) {
      throw new AuraHandledException(Label.DES_Error + e);
    }
  }

  /*
  * Se puede editar
  */
  @AuraEnabled
  public static boolean canSaveAsset(String secondary, String recordID) {
      Asset_Template__c assetTemp;
      assetTemp = [SELECT id, Onboarding_Type__c, Asset_Class__c, Status__c FROM Asset_Template__c WHERE id = :recordID];
      Boolean flag = false;

      if(assetTemp.Onboarding_Type__c == 'New User' && assetTemp.Asset_Class__c != 'Equity') {
        flag = true;
      } else if(assetTemp.Onboarding_Type__c == 'Platform Addition' || (assetTemp.Asset_Class__c == 'IRS' && assetTemp.Asset_Class__c == 'FX')) {
        flag = true;
      } else if(assetTemp.Onboarding_Type__c == 'New FX Account' || assetTemp.Onboarding_Type__c == 'Reject Client' || assetTemp.Onboarding_Type__c == 'Reject Fund' || assetTemp.Onboarding_Type__c == 'Reject User') {
        flag = true;
      } else if(assetTemp.Status__c == 'New' || (secondary != null && secondary != 'undefined' && secondary != NULO && secondary != '' && secondary != '""')) {
        flag = true;
      }

      return flag;
  }

  /**
  *getUserId
  */
  private static Boolean getUserId(String ownerRec) {
      Boolean user = false;
      String userId;
      userId = UserInfo.getUserId();
      if(ownerRec == userId) {
          user = true;
      }
      return user;
  }
}