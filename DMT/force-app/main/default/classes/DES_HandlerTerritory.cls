/*
 *  @AUTHOR         Global Desktop
 *  @DESCRIPTION    Clase con los methods necesarios para dar soporte a las clases que
 *                   necesitan alguna funcionalidad de los territorios de roles y perfiles
 *
 *
**/
@SuppressWarnings('sf:ConfusingTernary, sf:AvoidSoqlWithNegativeLogic, sf:UseSingleton, sf:CyclomaticComplexity, sf:TooManyMethods, sf:NPathComplexity')
public without sharing class DES_HandlerTerritory {

    /*Declarando variable*/
    private static final CIB_Bypass__c bypassSettings = CIB_Bypass__c.getInstance();//NOSONAR
    /*Declarando variable*/
    private static String na = 'N/A'; //NOSONAR
    /*Declarando variable*/
    private static Set<String> listaPaises;

    /**
    * Devuelve shares a partir de un objecto
    **/
  public static List<sObject> shareWithTerritory(sObject objecto, sObject objectToShare) {
        List<Territory2> territorys;
        territorys = obtainTerritorys(objecto);

        List<sObject> shares;
        shares = createObjectShare(objectToShare,territorys);

        System.debug('>>>>> Territorios ' + territorys);
        return shares;
  }
      /**
    * Devuelve shares a partir de una Lista objecto
    **/
  public static List<sObject> shareWithTerritory(List<sObject> objects, sObject objectToShare) {
        Map<String, List<sObject>> mapName = new Map<String, List<sObject>>();
        for ( sObject so : objects) {
            String soName=  so.getSObjectType().getDescribe().getName();
            if (mapName.get(soName)!=null) {
                mapName.get(soName).add(so);
            }else {
                List<SObject> newSo = new List<SObject>();
                newSo.add(so);
                mapName.put(soName, newSo);
            }
        }
        List<Territory2> territorys= new List<Territory2>();
        for (String key : mapName.keySet()) {
            List<Territory2> territorysToAdd= obtainTerritorysList(key, mapName.get(key));
            if (!territorysToAdd.isEmpty()) {
                territorys.addAll(territorysToAdd);
            }
        
        }
               System.debug('>>>>> Territorios ' + territorys);


        List<sObject> shares;
        shares = createObjectShare(objectToShare,territorys);

        return shares;
  }
   /**
     * Devuelve un listado de territorios asociados a un objeto
     **/
    public static List<Territory2> obtainTerritorysList (String objectName, List<sObject> objects) {//NOSONAR (strin sobjectName, listsobject)
        List<Territory2> territorys = new List<Territory2>();

        if (listaPaises == null ) {
            fillCountriesList();
        }
        System.debug('objectName::::: '+objectName);
        final TerritoryConfiguration__mdt terrConf = [SELECT Business_Area__c, Country__c, Segment__c, Confidential__c  FROM TerritoryConfiguration__mdt WHERE SObject__c = :objectName];
        
        for ( SObject objecto  : objects) {
            String query;
            query = 'Select Id, product_name_type__c, country_name__c, segment_name__c';
            String whereQuery;
            whereQuery = ' from Territory2 where ';
            system.debug('::::: terrConf.Business_Area__c : ' + terrConf.Business_Area__c);
            if(terrConf.Business_Area__c != null) {
                Object bussArea;
                bussArea = readField(terrConf.Business_Area__c, objecto);
                system.debug('::::: bussArea : ' + bussArea);
                if (bussArea != null) {
                System.debug('>>>>>> bussArea ' + bussArea);
                String strBussArea;
                strBussArea = (String) bussArea;
                System.debug('::::: strBussArea ' + strBussArea);
                if (strBussArea.contains(';')) {
                    final List<String> listStrProdAux = strBussArea.split(';');
                    system.debug('::::: listStrProdAux: ' + listStrProdAux);
                    whereQuery += 'product_name_type__c IN :listStrProdAux and ';
                } else {
                    whereQuery += 'product_name_type__c = :bussArea and ';
                }

                }
            }
            system.debug('::::: whereQuery : ' + whereQuery);

            if(terrConf.Country__c != null) {
                Object pais;
                pais = readField(terrConf.Country__c, objecto);
                if(pais != null) {
                    final String paisStr = String.valueOf(pais);
                    System.debug('>>>>>>pais ' + pais);
                    if(paisStr.containsIgnoreCase(';')) {
                        System.debug('>>>>>>pais es una lista');
                        final Set<String> listPaisStr = new Set<String> ();
                        for(String paisInd :paisStr.split(';') ) {
                            if(paisInd.containsIgnoreCase('us')) {
                                System.debug('>>>>>>pais tiene us' );
                                listPaisStr.add(paisInd.toUpperCase().replace('US', 'NY;Compass'));//NOSONAR
                            } else if(listaPaises.contains(paisInd)) {
                                listPaisStr.add(paisInd);
                            } else {
                                listPaisStr.add(na);
                            }
                        }
                        whereQuery += '(country_name__c in :listPaisStr ) and ';
                    } else {
                        if(paisStr.containsIgnoreCase('us')) {
                            System.debug('>>>>>>pais tiene us' );
                            final Set<String> setUS = new Set<String>{'NY', 'Compass'};//NOSONAR
                            whereQuery += '(country_name__c in :setUS ) and ';
                        } else if(listaPaises.contains(paisStr)) {
                            System.debug('>>>>>>pais pais reconocido' );
                                whereQuery += 'country_name__c = :pais and ';
                        } else {
                            whereQuery += 'country_name__c = :na and ';
                        }
                    }
                } else {
                    whereQuery += 'country_name__c = :na and ';
                }
            }

            if(terrConf.Segment__c != null) {
                Object segment;
                segment = readField(terrConf.Segment__c, objecto);
                if (segment != null) {
                    System.debug('>>>>>>segment ' + segment);
                    final String segStr = String.valueOf(segment);
                    if (segStr.containsIgnoreCase(';')) {
                        final List<String> listSegStr = segStr.split(';');
                        system.debug('::::: listSegStr: ' + listSegStr);
                        whereQuery += 'segment_name__c IN :listSegStr and ';
                    } else {
                        whereQuery += 'segment_name__c = :segStr and ';
                    }
                } else {

                    whereQuery += 'segment_name__c = :na and ';
                }
            }

            if(terrConf.Confidential__c != null) {
                Object conf;
                conf = readField(terrConf.Confidential__c, objecto);
                if (conf != null) {
                    System.debug('>>>>>>conf ' + conf);
                    whereQuery += 'gf_user_auth_level_name__c = :conf and ';
                }
            }
        
       
        whereQuery = whereQuery.removeEndIgnoreCase('and ');
        query += whereQuery;
        System.debug('>>>>>>Query ' + query);
        system.debug('::::: String.escapeSingleQuotes(query) : ' + query);
        List<Territory2> territoryList= Database.query(String.escapeSingleQuotes(query));
        
        if (!territoryList.isEmpty()) {
            territorys.addAll(territoryList);
        }
        
        }

        return territorys;
    }


  /**
   * Devuelve listado de shares segun los territorios
   **/
    private static List<sObject> createObjectShare(sObject objecto, List<Territory2> territorios ) {
        List<sObject> listaShare;
        listaShare = new List<sObject>();
        final Boolean isCustom = objecto.getSobjectType().getDescribe().isCustom();
        final String objectName = objecto.getSObjectType().getDescribe().getName();
        String objectShare;
        objectShare = '';
        if (isCustom) {
            objectShare = objectName.removeEndIgnoreCase('c') + 'Share';//NOSONAR
        } else {
            objectShare = objectName + 'Share';//NOSONAR
        }

        sObject sObj;
        sObj = createDefaultShare(objectShare, objectName, objecto, isCustom);

        for(Group grupo :  listGroups(territorios)) {
            sObject clonado;
            clonado = sObj.clone();
            updateValue(clonado,'UserOrGroupId',grupo.Id);
            listaShare.add(clonado);
        }
        System.debug('>>>>>listaShare ' + listaShare);
        return listaShare;
    }

    /**
     * Devuelve un objecto share segun la configuracion
     **/
    private static sObject createDefaultShare(String objectShare, String objectName, sObject objecto, Boolean isCustom ) {
        System.debug('>>>>>objectShare ' + objectShare);
        sObject sObj;
        sObj = Schema.getGlobalDescribe().get(objectShare).newSObject();
        updateValue(sObj,'RowCause','Manual');
        //Pattern regEx = Pattern.compile('^\\w*?__\\B\\w*__');
        //Matcher filter = regEx.matcher(objectName.toLowerCase());

        if (isCustom) {
            //if(!filter.find()) {
               //updateValue(sObj,'RowCause','TerritoryShare');
            //}
            updateValue(sObj,'ParentId',objecto.get('Id'));
            updateValue(sObj,'AccessLevel','Edit');
        } else {
            updateValue(sObj,objectName+'Id',objecto.get('Id'));
            updateValue(sObj,objectName+'AccessLevel','Edit');
        }
        if(objectName.equalsIgnoreCase('Account')) {
            updateValue(sObj,'OpportunityAccessLevel','None');
            updateValue(sObj,'CaseAccessLevel','None');
            updateValue(sObj,'ContactAccessLevel','None');
        }

        return sObj;
    }

    /**
     * Actualiza el valor en un campo
     **/
    private static void updateValue(sObject sObj, String field, Object value) {
        Object fieldObject;
        fieldObject = sObj.get(field);
        fieldObject = value;
        sObj.put(field,fieldObject);
    }

    /**
     * Devuelve la lista de grupos asociados a los territorios
     **/
    private static List<Group> listGroups(List<Territory2> territorios) {
        List<Id> idsTerritories;
        idsTerritories = new List<Id>();
        for(Territory2 territory: territorios) {
            idsTerritories.add(territory.Id);
        }
        List<Group> grupos;
        grupos = [SELECT Id FROM Group WHERE RelatedId IN :idsTerritories and Type='Territory'];

        return grupos;
    }

    /**
     * Devuelve el valor de un campo
     **/
    private static Object readField (String field, sObject objecto) {
        Object obj;
        obj = null;//NOSONAR
        System.debug('>>>>field: ' + field );
        if(field.contains('.')) {
            List<String> listaCampos;
            listaCampos = field.split('\\.');
            sObject temp;
            temp = null;//NOSONAR
            for (Integer i = 0; i < listaCampos.size(); i++) {
                System.debug('>>>>listaCampos[i]: ' + listaCampos[i] );
                if(i == listaCampos.size() - 1) {
                    obj = temp.get(listaCampos[i]);
                } else if(temp == null) {
                    temp = objecto.getSObject(listaCampos[i]);
                } else {
                    temp = temp.getSObject(listaCampos[i]);
                }
            }
            system.debug('::::: temp: ' + temp);
        } else {
          obj = objecto.get(field);
        }

        return obj;
    }

    /**
     * Rellena la lista de paises
     **/
    private static void fillCountriesList () {
        Set<String> setCountries;
        setCountries = new Set<String>();
        TerritoryConfiguration__mdt terry;
        terry =  [Select Countries_available__c from TerritoryConfiguration__mdt where DeveloperName = 'List_countries'];
        setCountries.addAll(terry.Countries_available__c.split(';'));
        listaPaises = setCountries;
    }

    /**
     * Comparte una lista de objetos con los territorios correspondientes
     **/
    public static void shareWithTerritoryList (List<sObject> objectos, List<sObject> oldObjects) {
        System.debug('>>>>> Entrando shareWithTerritoryList');
        List<sObject> objList;
        objList = new List<sObject>();
        for (sObject objecto : objectos) {
            objList.addAll(shareWithTerritory(objecto, objecto));
        }
        insert objList;

    }



    /**
     * Comparte una oportunidad con los territorios a partir de sus productos
     **/
    public static void shareOpportunity (List<OpportunityLineItem> objectos) {
      if (!bypassSettings.CIB_skip_trigger__c) {
          final String profileName = [SELECT Name FROM Profile WHERE Id =: UserInfo.getProfileId()].get(0).Name;
            if (profileName != LABEL.DES_ADMIN_PROFILE && profileName != Label.DES_INTEGRATION_PROFILE  && profileName != Label.DES_DATALOADER_PROFILE) {
                Map<Id,Id> idsOpp;
                idsOpp = new Map<Id,Id>();
                //Map<Id,Opportunity> lineItemOpp;
                //lineItemOpp = new Map<Id,Opportunity>();
                List<sObject> inserts;
                inserts = new List<sObject>(); //NOSONAR
                for (OpportunityLineItem objecto : objectos) {
                    idsOpp.put(objecto.Id,objecto.OpportunityId);
                }
                Map<ID,Opportunity> opps;
                opps = new Map<ID, Opportunity>([SELECT Id, DES_Booking_Geography__c, disclosure_info_type__c, Account.DES_Segment__c
                                                                    FROM Opportunity
                                                                    WHERE Id IN :idsOpp.values() AND disclosure_info_type__c != :Label.DES_OP_Inside AND StageName != :Label.DES_Draft]);//NOSONAR

                if(!opps.isEmpty()) {
                for (OpportunityLineItem objecto : objectos) {
                    OpportunityLineItem obj;
                    obj = objecto.clone();
                    obj.Opportunity = opps.get(obj.OpportunityId);
                    inserts.addAll(shareWithTerritory(obj, opps.get(obj.OpportunityId)));

                }
                system.debug('::::: inserts : ' + inserts);
                insert inserts;
                }
            }
      }
    }

    /**
     * Inserta registros con un limite entre comits
     **/
    public static void insertRecords (List<sObject> myList, Integer maxRecords) {
        system.debug('::::: maxRecords: ' + maxRecords);
        system.debug('::::: myList.size(): ' + myList.size());
        if(myList.size() > maxRecords) {
            system.debug('::::: ANTES DE INSERTAR: myList: ' + myList);
            insert myList;
            system.debug('::::: DESPUES DE INSERTAR: myList: ' + myList);
            myList.clear();
        }
    }

    /**
     * Comparte objetos con sus territorios. Utilizar en trigger
     **/
    public static void shareWithTerriVisitInsert (Map<Id, dwp_kitv__Visit__c> triggerNewMap) {
        String strSELECT;
        strSELECT = 'SELECT ';
        String query;
        query = strSELECT;
        final Schema.DescribeSObjectResult visitSch = dwp_kitv__Visit__c.sObjectType.getDescribe();

        for(String apiName : visitSch.fields.getMap().keySet()) {
            system.debug('>>>>> apiName : ' + apiName);
            if(query == strSELECT) {
                query += apiName;
            } else {
                query += ', ' + apiName;
            }
        }
        final Set<Id> setIds = triggerNewMap.keySet();
        system.debug('::::: setIds : ' + setIds);
        final String insidInfoStr = Label.DES_OP_Inside;
        system.debug('::::: insidInfoStr : ' + insidInfoStr);
        query += ' FROM dwp_kitv__Visit__c WHERE Id IN :setIds AND disclosure_info_type__c != :insidInfoStr';
        system.debug('>>>>> query: ' + JSON.serialize(query));
        shareWithTerritoryListTrigger(Database.query(String.escapeSingleQuotes(query)), null);
    }

    /**
     * Comparte objetos con sus territorios. Utilizar en trigger
     **/

    public static void shareWithTerritoryListTriggerFuture (String objetos, String objetosOld, String profileName) {
            if (profileName != LABEL.DES_ADMIN_PROFILE && profileName != Label.DES_INTEGRATION_PROFILE  && profileName != Label.DES_DATALOADER_PROFILE) {
                shareFutureTrigger (objetos, objetosOld);
            }
    }

     /**
     * Comparte objetos con sus territorios. Utilizar en trigger
     **/

    public static void shareWithFutureInititiative (String objetos, String objetosOld, String profileName, Boolean parent) {
        if (profileName != Label.DES_INTEGRATION_PROFILE  && profileName != Label.DES_DATALOADER_PROFILE) {
            if(parent) {
                shareFutureTriggerInitiativeParent (objetos, objetosOld);
            } else {
                shareFutureTriggerInitiative (objetos);
            }

        }
    }
    /**
     * Comparte objetos con sus territorios. Utilizar en trigger
     **/
    @Future
    public static void shareFutureTrigger (String objetos, String objetosOld) {
        if(objetosOld == null) {
            shareWithTerritoryListTrigger((List<sObject>)Json.deserialize(objetos,List<sObject>.class), null);
        } else {
            shareWithTerritoryListTrigger((List<sObject>)Json.deserialize(objetos,List<sObject>.class), (List<sObject>)Json.deserialize(objetosOld,List<sObject>.class));
        }

    }

    /**
    * @description
    * @author Global Desktop | 29/5/2020
    * @param objetos
    * @return void
    **/
    @Future
    public static void shareFutureTriggerInitiative (String objetos) {
        final List<cond__Account_Campaign__c> listCampaingNew = (List<cond__Account_Campaign__c>)Json.deserialize(objetos,List<cond__Account_Campaign__c>.class);
        final Set<id> campIds = new Set<id>();
        for (cond__Account_Campaign__c cac : listCampaingNew) {
            campIds.add(cac.cond__campaign_id__c);
        }
        final Map<id, Campaign> campaingMap = new Map<id, Campaign>(
            [SELECT gf_user_country_name__c, solution_name_path_desc__c, segment_desc__c FROM Campaign WHERE Id IN :campIds]);
        for(cond__Account_Campaign__c cac : listCampaingNew) {
            cac.cond__campaign_id__r = campaingMap.get(cac.cond__campaign_id__c);
        }
        shareWithTerritoryListTrigger(listCampaingNew, null);


    }
    /**
    * @description
    * @author Global Desktop | 29/5/2020
    * @param objetos
    * @param objetosOld
    * @return void
    **/
    @Future
    public static void shareFutureTriggerInitiativeParent (String objetos, String objetosOld) {
        final Map<Id,Campaign> listCampaingNew = (Map<Id,Campaign>)Json.deserialize(objetos,Map<Id,Campaign>.class);
        final Map<Id,Campaign> listCampaingOld = (Map<Id,Campaign>)Json.deserialize(objetosOld,Map<Id,Campaign>.class);
        final Set<id> campIdsNew = new Set<id>();
        final Set<id> campIdsOld = new Set<id>();
        for (Campaign cac : listCampaingNew.values()) {
            campIdsNew.add(cac.Id);
        }
        for (Campaign cac : listCampaingOld.values()) {
            campIdsOld.add(cac.Id);
        }
        final List<cond__Account_Campaign__c> campAccNew = new List<cond__Account_Campaign__c>(
            [SELECT id, cond__campaign_id__c FROM cond__Account_Campaign__c WHERE cond__campaign_id__c IN :campIdsNew]);
        final List<cond__Account_Campaign__c> campAccOld = new List<cond__Account_Campaign__c>(
            [SELECT id, cond__campaign_id__c FROM cond__Account_Campaign__c WHERE cond__campaign_id__c IN :campIdsOld]);
        for (cond__Account_Campaign__c cac: campAccNew) {
            cac.cond__campaign_id__r = listCampaingNew.get(cac.cond__campaign_id__c);
        }
        for (cond__Account_Campaign__c cac: campAccOld) {
            cac.cond__campaign_id__r = listCampaingOld.get(cac.cond__campaign_id__c);
        }

        shareWithTerritoryListTrigger(campAccNew, campAccOld);


    }
    /**
     *
     * Comparte objetos con sus territorios. Utilizar en trigger
     **/
    public static void shareWithTerritoryListTrigger (List<sObject> objectos, List<sObject> objectosOld) {
        Id idRegistro;
        String tipoObj;
        final List<String> literals = new List<String>{'dwp_kitv__Visit__c', 'opportunity', 'VE'};
        if (!bypassSettings.CIB_skip_trigger__c) {
            final String profileName = [SELECT Name FROM Profile WHERE Id =: UserInfo.getProfileId()].get(0).Name;
            if (profileName != LABEL.DES_ADMIN_PROFILE && profileName != Label.DES_INTEGRATION_PROFILE  && profileName != Label.DES_DATALOADER_PROFILE) {
                Boolean continuar = true;
                System.debug('>>>>> Entrando shareWithTerritoryListTrigger');
                List<sObject> objListDelete;
                objListDelete = new List<sObject>(); //NOSONAR
                if(objectosOld != null) {
                    for (sObject objecto : objectosOld) {
                        idRegistro = objecto.Id;
                        tipoObj = idRegistro.getSObjectType().getDescribe().getName();
                        if(tipoObj == literals[0]) {
                            if(objecto.get('Private_Visit__c') != true) {
                                objListDelete.addAll(deleteShares(objecto));
                            }
                        } else if(tipoObj == literals[1]) {
                            if(objecto.get('DES_Client_Country__c') != literals[2]) {
                                objListDelete.addAll(deleteShares(objecto));
                            }
                        } else {
                            objListDelete.addAll(deleteShares(objecto));
                        }
                    }
                    system.debug('::::: objListDelete A BORRAR : ' + objListDelete);
                    try {
                        delete objListDelete;
                    } catch (Exception e) {
                        continuar = false;
                    }
                }
                if(continuar) {
                    List<sObject> objList;
                    objList = new List<sObject>();//NOSONAR
                    for (sObject objecto : objectos) {
                    idRegistro = objecto.Id;
                    tipoObj = idRegistro.getSObjectType().getDescribe().getName();
                    if(tipoObj == literals[0]) {
                        if(objecto.get('Private_Visit__c') != true) {
                            objList.addAll(shareWithTerritory(objecto, objecto));
                        }
                    } else if(tipoObj == literals[1]) {
                        if(objecto.get('DES_Client_Country__c') != literals[2]) {
                            objList.addAll(shareWithTerritory(objecto, objecto));
                        }
                    } else {
                        objList.addAll(shareWithTerritory(objecto, objecto));
                    }
                    }
                    
                    if(!objList.isEmpty()) {
                        system.debug('::::: objList A INSERTAR : ' + objList);
                        Desktop_Utils utils = Desktop_Utils.getInstance();
                        utils.upsertWithRetry(objList, 'insert');
                    }
                }
            }
        }
    }


    /**
     * Comparte objetos con sus territorios. Utilizar en trigger
     **/
    // public static void shareWithTerritoryVisitListTrigger (List<sObject> objectos, List<sObject> objectosOld) {
    //     if (!bypassSettings.CIB_skip_trigger__c) {
    //         System.debug('>>>>> Entrando shareWithTerritoryListTrigger');
    //         List<sObject> objListDelete;
    //         objListDelete = new List<sObject>();//NOSONAR
    //         if(objectosOld != null) {
	//             for (sObject objecto : objectosOld) {
	//             	objListDelete.addAll(deleteShares(objecto));
	//             }
	//             delete objListDelete;
    //         }
    //         List<sObject> objList;
    //         objList = new List<sObject>();
    //         for (sObject objecto : objectos) {
    //             objList.addAll(shareWithTerritory(objecto, objecto));
    //         }
    //         insert objList;
    //     }
    // }

    /**
     * Borra una lista de sharing
     **/
    public static void deleteSharing (List<sObject> listaObjectos) {
      delete listaObjectos;
    }

    /**
     * Devuelve un listado de territorios asociados a un objeto
     **/
    public static List<Territory2> obtainTerritorys (sObject objecto) {//NOSONAR
        List<Territory2> territorys;

        if (listaPaises == null ) {
            fillCountriesList();
        }
        String objectName;
        objectName = objecto.getSObjectType().getDescribe().getName();
        final TerritoryConfiguration__mdt terrConf = [SELECT Business_Area__c, Country__c, Segment__c, Confidential__c  FROM TerritoryConfiguration__mdt WHERE SObject__c = :objectName];
        String query;
        query = 'Select Id, product_name_type__c, country_name__c, segment_name__c';
        String whereQuery;
        whereQuery = ' from Territory2 where ';
        system.debug('::::: terrConf.Business_Area__c : ' + terrConf.Business_Area__c);
        if(terrConf.Business_Area__c != null) {
            Object bussArea;
            bussArea = readField(terrConf.Business_Area__c, objecto);
            system.debug('::::: bussArea : ' + bussArea);
            if (bussArea != null) {
              System.debug('>>>>>> bussArea ' + bussArea);
              String strBussArea;
              strBussArea = (String) bussArea;
              System.debug('::::: strBussArea ' + strBussArea);
              if (strBussArea.contains(';')) {
                  final List<String> listStrProdAux = strBussArea.split(';');
                  system.debug('::::: listStrProdAux: ' + listStrProdAux);
                  whereQuery += 'product_name_type__c IN :listStrProdAux and ';
              } else {
                  whereQuery += 'product_name_type__c = :bussArea and ';
              }

            }
        }
        system.debug('::::: whereQuery : ' + whereQuery);

        if(terrConf.Country__c != null) {
            Object pais;
            pais = readField(terrConf.Country__c, objecto);
            if(pais != null) {
                final String paisStr = String.valueOf(pais);
                System.debug('>>>>>>pais ' + pais);
                if(paisStr.containsIgnoreCase(';')) {
                    System.debug('>>>>>>pais es una lista');
                    final Set<String> listPaisStr = new Set<String> ();
                    for(String paisInd :paisStr.split(';') ) {
                        if(paisInd.containsIgnoreCase('us')) {
                            System.debug('>>>>>>pais tiene us' );
                            listPaisStr.add(paisInd.toUpperCase().replace('US', 'NY;Compass'));//NOSONAR
                        } else if(listaPaises.contains(paisInd)) {
                            listPaisStr.add(paisInd);
                        } else {
                            listPaisStr.add(na);
                        }
                    }
                    whereQuery += '(country_name__c in :listPaisStr ) and ';
                } else {
                    if(paisStr.containsIgnoreCase('us')) {
                        System.debug('>>>>>>pais tiene us' );
                        final Set<String> setUS = new Set<String>{'NY', 'Compass'};//NOSONAR
                        whereQuery += '(country_name__c in :setUS ) and ';
                    } else if(listaPaises.contains(paisStr)) {
                        System.debug('>>>>>>pais pais reconocido' );
                            whereQuery += 'country_name__c = :pais and ';
                    } else {
                        whereQuery += 'country_name__c = :na and ';
                    }
                }
            } else {
                whereQuery += 'country_name__c = :na and ';
            }
        }

        if(terrConf.Segment__c != null) {
            Object segment;
            segment = readField(terrConf.Segment__c, objecto);
            if (segment != null) {
                System.debug('>>>>>>segment ' + segment);
                final String segStr = String.valueOf(segment);
                if (segStr.containsIgnoreCase(';')) {
                    final List<String> listSegStr = segStr.split(';');
                    system.debug('::::: listSegStr: ' + listSegStr);
                    whereQuery += 'segment_name__c IN :listSegStr and ';
                } else {
                    whereQuery += 'segment_name__c = :segStr and ';
                }
            } else {

                whereQuery += 'segment_name__c = :na and ';
            }
        }

        if(terrConf.Confidential__c != null) {
            Object conf;
            conf = readField(terrConf.Confidential__c, objecto);
            if (conf != null) {
                System.debug('>>>>>>conf ' + conf);
                whereQuery += 'gf_user_auth_level_name__c = :conf and ';
            }
        }
        whereQuery = whereQuery.removeEndIgnoreCase('and ');
        query += whereQuery;
        System.debug('>>>>>>Query ' + query);
        system.debug('::::: String.escapeSingleQuotes(query) : ' + query);

        territorys = Database.query(String.escapeSingleQuotes(query));


        return territorys;
    }

    /**
     * Elimina los shares asociados a un OpportunityLineItem
     **/
    public static void deleteOppShare (List<OpportunityLineItem> objectos) {
      if (!bypassSettings.CIB_skip_trigger__c) {
            final String profileName = [SELECT Name FROM Profile WHERE Id =: UserInfo.getProfileId()].get(0).Name;
            if (profileName != LABEL.DES_ADMIN_PROFILE && profileName != Label.DES_INTEGRATION_PROFILE  && profileName != Label.DES_DATALOADER_PROFILE) {
                Map<Id,Id> idsOpp;
                idsOpp = new Map<Id,Id>();
                //Map<Id,Opportunity> lineItemOpp;
                //lineItemOpp = new Map<Id,Opportunity>();
                final List<Territory2> territories = new List<Territory2>();//NOSONAR
                for (OpportunityLineItem objecto : objectos) {
                    idsOpp.put(objecto.Id,objecto.OpportunityId);
                }
                final Map<ID,Opportunity> opps = new Map<ID, Opportunity>([SELECT Id, DES_Booking_Geography__c, disclosure_info_type__c, Account.DES_Segment__c
                                                                        FROM Opportunity
                                                                        WHERE Id IN :idsOpp.values() and disclosure_info_type__c != :Label.DES_OP_Inside and recordType.DeveloperName != 'DMT_Opportunity']);//NOSONAR

                if(!opps.isEmpty()) {
                    for (OpportunityLineItem objecto : objectos) {
                        OpportunityLineItem obj;
                        obj = objecto.clone();
                        obj.Opportunity = opps.get(obj.OpportunityId);
                        territories.addAll(obtainTerritorys(obj));
                    }
                    system.debug('::::: territories : ' + territories);
                    List<Id> idsGroup;
                    idsGroup = new List<Id>();
                    for(Group grupo : listGroups(territories)) {
                        idsGroup.add(grupo.Id);
                    }

                    List<OpportunityShare> objetosBorrar;
                    objetosBorrar = [Select id from OpportunityShare  Where OpportunityId in :idsOpp.values() and UserOrGroupId in :idsGroup];

                    delete objetosBorrar;
                }
            }
      }
    }

    /**
     * Elimina los shares asociados a un Opportunity
     **/
    public static void updateOppShare (Map<Id,Opportunity> objectosOld, Map<Id,Opportunity> objectosNew) {
      if (!bypassSettings.CIB_skip_trigger__c) {
            final String profileName = [SELECT Name FROM Profile WHERE Id =: UserInfo.getProfileId()].get(0).Name;
            if (profileName != LABEL.DES_ADMIN_PROFILE && profileName != Label.DES_INTEGRATION_PROFILE  && profileName != Label.DES_DATALOADER_PROFILE) {
                Boolean isChanged;
                isChanged = false;
                Iterator<Opportunity> iter;
                system.debug('::::: objectosOld: ' + objectosOld);
                system.debug('::::: objectosNew: ' + objectosNew);
                system.debug('::::: objectosNew.values(): ' + objectosNew.values());
                iter = objectosNew.values().iterator();
                system.debug('::::: iter: ' + iter);
                while (iter.hasNext() && !isChanged) {
                        Opportunity opp;
                        opp = iter.next();
                        if(opp.disclosure_info_type__c != Label.DES_OP_Inside && ((opp.DES_Booking_Geography__c != null
                        && opp.DES_Booking_Geography__c != objectosOld.get(opp.Id).DES_Booking_Geography__c)
                        || opp.disclosure_info_type__c != objectosOld.get(opp.Id).disclosure_info_type__c ||
                        (opp.StageName != Label.DES_Draft && objectosOld.get(opp.Id).StageName == Label.DES_Draft)) ) {
                            isChanged = true;
                    }
                }
                system.debug('::::: isChanged: ' + isChanged);
                if(isChanged) {

                    final List<OpportunityShare> objetosBorrar = [select id from OpportunityShare where UserOrGroupId in (select id from Group where Type = 'Territory') and RowCause = 'Manual' and OpportunityId in :objectosNew.keySet()];

                    delete objetosBorrar;

                    List<sObject> inserts;
                    inserts = new List<sObject>();

                    final Map<ID,OpportunityLineItem> oppsLineItemNew = new Map<ID, OpportunityLineItem>([SELECT Id, ProductCode, OpportunityId, Opportunity.DES_Booking_Geography__c, Opportunity.Account.DES_Segment__c, Opportunity.disclosure_info_type__c
                                                                                                    FROM OpportunityLineItem
                                                                                                    WHERE OpportunityId in :objectosNew.keySet() AND Opportunity.AccountId != null ]);

                    for (OpportunityLineItem objecto : oppsLineItemNew.values()) {
                        OpportunityLineItem obj = objecto.clone();//NOSONAR
                        inserts.addAll(shareWithTerritory(obj, objectosNew.get(obj.OpportunityId)));
                    }
                    system.debug('::::: inserts: ' + inserts);
                    insert inserts;
                }
            }
      }
    }

    /**
     * Devuelve listado de shares para nbc
     **/
    public static List<sObject> createShareNBC (NBC__c nbc,List<Id> triggerNewMap) {
       // if (!bypassSettings.CIB_skip_trigger__c) {
			List<sObject> inserts;
            inserts = new List<sObject>();
            final Map<ID,OpportunityLineItem> oppsLineItem = new Map<ID, OpportunityLineItem>([SELECT Id, ProductCode, OpportunityId, Opportunity.DES_Booking_Geography__c, Opportunity.Account.DES_Segment__c, Opportunity.disclosure_info_type__c
                                                                                            FROM OpportunityLineItem
                                                                                            WHERE OpportunityId in :triggerNewMap and Opportunity.disclosure_info_type__c != :Label.DES_OP_Inside AND Opportunity.AccountId != null]); //NOSONAR
			System.debug('>>>> oppsLineItem' + oppsLineItem.size());
          /*   for (OpportunityLineItem objecto : oppsLineItem.values()) {
                OpportunityLineItem obj;
                obj = objecto.clone();
                inserts.addAll(shareWithTerritory(obj, nbc));
            } */
            inserts.addAll(shareWithTerritory(oppsLineItem.values(), nbc));
            return inserts;
        //}
    }

    /**
     * Comparte nbc con sus territorios
     **/
    public static void shareNBC(Map<Id, Opportunity> triggerNewMap, Map<Id, Opportunity> triggerOldMap) {
        //Mapa que tendrá como key el id de la opSet<E> como value el id del NBC asociado
    	if (!bypassSettings.CIB_skip_trigger__c) {
            system.debug('entro if  bypass');
	    	final Set<ID> mapDeleteNBC = new Set<Id>();
	        final Map<Id, Id> mapOppNBC = new Map<Id, Id>();
	        final List<sObject> inserts = new List<sObject>();//NOSONAR
	        for(Opportunity opp : triggerNewMap.values()) {
                if(opp.AccountId != null) {
                                system.debug('entro if account notnull');

	                if(opp.disclosure_info_type__c != Label.DES_OP_Inside && opp.Committee_id__c != null
	                && opp.Committee_id__c != triggerOldMap.get(opp.Id).Committee_id__c) {//NOSONAR
	                  mapOppNBC.put(opp.Id, opp.Committee_id__c);
	                  mapDeleteNBC.add(opp.Committee_id__c);
                                    system.debug('entro if  mapoppnbc' +mapOppNBC+'delete '+mapDeleteNBC);

	                } else if(opp.disclosure_info_type__c != Label.DES_OP_Inside && opp.Committee_id__c == null
	                        && triggerOldMap.get(opp.Id).Committee_id__c != null) {
	            	  mapDeleteNBC.add(triggerOldMap.get(opp.Id).Committee_id__c);
	            	  mapOppNBC.put(opp.Id, triggerOldMap.get(opp.Id).Committee_id__c);
                  system.debug('entro  else if  mapoppnbc' +mapOppNBC+'delete '+mapDeleteNBC);

	                }
                }
	        }

	        if (!mapDeleteNBC.isEmpty()) {
	        	final List<NBC__Share> sharesBorrar = [select id from NBC__Share where UserOrGroupId in (select id from Group where Type = 'Territory') and RowCause = 'Manual' and ParentId in :mapDeleteNBC];
	        	delete sharesBorrar;
	        }

	        if(!mapOppNBC.isEmpty()) {
	        	final Map<Id,NBC__c> nbcs = new Map<Id,NBC__c>([Select Id from NBC__c where id in :mapOppNBC.values()]);
	        	final Map<Id,List<Id>> listaOpp = new Map<Id,List<Id>>();

	        	final List<Opportunity> opptnys = [Select Id, Committee_id__c from Opportunity Where Committee_id__c in :nbcs.keySet() and disclosure_info_type__c != :Label.DES_OP_Inside];//NOSONAR
	        	System.debug('>>>> Opportunities opptnys ' + opptnys.size());
                      system.debug('entro  mapoonb not empty ');

	        	for(Opportunity oppty : opptnys) {
	        		if(oppty.Committee_id__c != null) {
	        			if(listaOpp.containsKey(oppty.Committee_id__c)) {
	        				List<Id> oppsNbc;
                            oppsNbc = listaOpp.get(oppty.Committee_id__c);
	        				oppsNbc.add(oppty.Id);
	        				listaOpp.put(oppty.Committee_id__c,oppsNbc );
	        			} else {
	        				List<Id> oppsNbc;
                            oppsNbc = new List<Id>();
	        				oppsNbc.add(oppty.Id);
	        				listaOpp.put(oppty.Committee_id__c,oppsNbc );
	        			}
	        		}
	        	}

	        	System.debug('>>>> Opportunities listaOpp ' + opptnys.size());

	        	for (NBC__c nbc : nbcs.values()) {
	        		if(listaOpp.containsKey(nbc.Id)) {
	                    System.debug('>>>> Entra ');
	        			inserts.addAll(createShareNBC(nbc,listaOpp.get(nbc.Id)));
	        		}
	        	}

	        	insert inserts;
	        }
            shareOppTeamMemberNbc(triggerOldMap.keySet(),triggerNewMap.keySet());
    	}
    }

    /**
     * Devuelve un listado de territorios asociados a un objeto
     **/
    public static List<sObject> deleteShares(sObject objecto) {

    	List<sObject> territories;
        territories = new List<sObject>();
    	List<sObject> shares;
        territories.addAll(obtainTerritorys(objecto));

        List<Id> idsGroup = new List<Id>();//NOSONAR
        for(Group grupo : listGroups(territories)) {
          idsGroup.add(grupo.Id);
        }
        String manual = 'Manual';
    	Boolean isCustom;
        isCustom = objecto.getSobjectType().getDescribe().isCustom();
        String objectName;
        objectName = objecto.getSObjectType().getDescribe().getName();
        String objectShare;
        objectShare = '';
        String fieldId;
        fieldId = '';
        Id identificador;
        identificador = objecto.Id;
        system.debug('::::: identificador : ' + identificador);
        if (isCustom) {
        	 fieldId = 'ParentId';
        	 objectShare = objectName.removeEndIgnoreCase('c') + 'Share';//NOSONAR
        } else {
        	fieldId = objectName + 'Id';
        	 objectShare = objectName + 'Share';//NOSONAR
        }
        String query;
        query = 'Select Id';
        String whereQuery;
        whereQuery = ' from ' + objectShare + ' where ';
        whereQuery += fieldId +' = :identificador and ';
        whereQuery += ' UserOrGroupId in :idsGroup and RowCause= :manual';
        whereQuery = whereQuery.removeEndIgnoreCase('and ');

        query += whereQuery;
        System.debug('>>>>>>Query delete ' + query);

        shares = Database.query(String.escapeSingleQuotes(query));

        return shares;
    }

/**
* Method shareOppTeamMemberNbc
 */
    public static void shareOppTeamMemberNbc (Set<ID> oppIdsOld, Set<Id> oppIdNew) {
        System.debug('>>>>Entra shareOppTeamMemberNbc OppIdsOld' +OppIdsOld);
        //Borramos anteriores
        final List<NBC__Share> sharesBorrar = [select id from NBC__Share where RowCause = 'Manual' and UserOrGroupId in (SELECT UserId from OpportunityTeamMember where OpportunityId = :OppIdsOld)];
        delete sharesBorrar;
        if (oppIdNew != null) {
            //Creamos objeto base
            NBC__Share nbcShare;
            nbcShare = new NBC__Share();
            updateValue(nbcShare,'RowCause','Manual');
            updateValue(nbcShare,'AccessLevel','Edit');

            List<NBC__Share> listNbcShare;
            listNbcShare = new List<NBC__Share>();
            final List<OpportunityTeamMember> listOppTeamMemb =  [select id, OpportunityId, Opportunity.Committee_id__c, UserId from OpportunityTeamMember where OpportunityId = :OppIdNew and Opportunity.Committee_id__c != null and Opportunity.disclosure_info_type__c != :Label.DES_OP_Inside and User.isActive = true];
            final Set<Id> parentIds = new Set<Id>();
            final Set<Id> userIds = new Set<Id>();
            Set<String> clavesExistentes = new Set<String>();
            clavesExistentes = getIdsShare(listOppTeamMemb,parentIds,userIds,clavesExistentes);
            for (OpportunityTeamMember otm : listOppTeamMemb) {
            final String clave = otm.Opportunity.Committee_id__c + '-' + otm.UserId;    
                if (!clavesExistentes.contains(clave)) {
                    final NBC__Share objClon = nbcShare.clone();
                    updateValue(objClon, 'UserOrGroupId', otm.UserId);
                    updateValue(objClon, 'ParentId', otm.Opportunity.Committee_id__c);
                    listNbcShare.add(objClon);
                }
            }
            if (!listNbcShare.isEmpty()) {
                insert listNbcShare;
            }

        }

    }
    /* 
    * @Description Method que devuelve nbc__share creados por el usuario y ligados a la oportunidad 
    * @Author Pedro Antonio Lozano Rios pedroantonio.lozano@bbva.com
    * @Date 08-05-25
    * @Params List<OpportunityTeamMember> listOppTeamMemb lista de oppteamMember
    * @Params Set<Id> parentIds set para almacenar ids parentid
    * @Params Set<Id> userIds set para almacenar userIds
    * @Params Set<String> Claves Existentes  
    * @return Set<String> retorna un set con ids parent y userid 
    */ 
    public static Set<String> getIdsShare(List<OpportunityTeamMember> listOppTeamMemb, Set<Id> parentIds,Set<Id> userIds,Set<String> clavesExistentes) {
    for (OpportunityTeamMember otm : listOppTeamMemb) {
                parentIds.add(otm.Opportunity.Committee_id__c);
                userIds.add(otm.UserId);
     }
    final List<NBC__Share> shareExiste = [SELECT Id, ParentId, UserOrGroupId FROM NBC__Share WHERE ParentId IN :parentIds AND UserOrGroupId IN :userIds];
    for (NBC__Share lstShare : shareExiste) {
    clavesExistentes.add(lstShare.ParentId + '-' + lstShare.UserOrGroupId);
    }
    return clavesExistentes;
    }
    /*
     *  Global Desktop
     *
    **/
    public static void shareOTM (Map<Id,OpportunityTeamMember> triggerNewMap, Map<Id,OpportunityTeamMember> triggerOldMap) {
        Set<Id> oppIdNew;
        oppIdNew = new Set<Id>();
        Set<Id> oppIdsOld;
        oppIdsOld = new Set<Id>();
        if(triggerNewMap != null) {
            for(OpportunityTeamMember oppTeamMb: triggerNewMap.values()) {
                oppIdNew.add(oppTeamMb.OpportunityId);
            }
        }

        for(OpportunityTeamMember oppTeamMb: triggerOldMap.values()) {
            oppIdsOld.add(oppTeamMb.OpportunityId);
        }

        shareOppTeamMemberNbc(oppIdsOld,oppIdNew);
    }

}