/**
* ------------------------------------------------------------------------------------------------
* @Name     Arc_Gen_BusinessRisk_Pers_service
* @Author   Javier Soto Carrascosa
* @Date     Created: 04/042020
* @Group    ARCE
* -----------------------------------------------------------------------------------------------
* @Description Class that manages save for Basic Data
* -----------------------------------------------------------------------------------------------
* @Changes
*
* |2020-04-04 Javier Soto Carrascosa
*             Class creation.
* |2020-09-23 saimassimilianno.jordana.contractor@bbva.com
*             Added arce. namespace to all classes that are now in the arce-dependencies package
* |2020-03-12 juanpedro.benito.contractor@bbva.com
*             Change arce__gf_cust_economic_activity_desc__c for arce__gf_cmnt_cust_ecat_desc__c
* |2021-06-17 Juan Ignacio Hita Manso
*             Rollback last commit (PR:1231)
* |2021-06-21 juanignacio.hita.contractor@bbva.com
*             Add Geographies, Activities and Main_affiliates blocks request persistence service
* |2021-07-14 juanignacio.hita.contractor@bbva.com
*             Adds logic for the type of analysis in getValLogicGeoAct method
* |2021-08-17 juanignacio.hita.contractor@bbva.com
*             Removes logic for the "dependence on customer" field by analysis type
* |2022-06-06 juanignacio.hita.contractor@bbva.com
*             Add checkChangesQualQuestion validation
* -----------------------------------------------------------------------------------------------
*/
@SuppressWarnings('sf:TooManyMethods, PMD.UseSingleton')
global class Arc_Gen_BusinessRisk_Pers_service implements dyfr.Save_Interface {
    /*
    * @Description Description constant
    */
    private static final String DESCRIPTION = 'description';
    /** @Description: string with the recordtype Geographies */
    private static final String GEO = 'Geographies';
    /** @Description: string with the recordtype Activities */
    private static final String ACT = 'Activities';
    /** @Description: string with the recordtype Main Affiliates */
    private static final String MAFI = 'Main_affiliates';
    /** @Description: string with name main clients table */
    private static final String MAIN_CLIENTS = 'Main_clients';
    /** @Description: string with name main suppliers table */
    private static final String MAIN_SUPPL = 'Main_suppliers';
    /** @Description: string supplier constant */
    private static final String SUPPLIER = 'SUPPLIER';
    /** @Description: string customer constant */
    private static final String CUSTOMER = 'CUSTOMER';
    /** @Description: yes multi option with constant 1 */
    private static final String YES_MULTI = '1';
    /** @Description: identifier geography tables */
    private static final String GEO_ID = 'geography';
    /** @Description: idenfitifer activity table */
    private static final String ACT_ID = 'activity';
    /** @Description: idenfitifer High value for concentration_suppliers_type, cust_conc_clients_type, dependency_degree_cust_type fields */
    private static final String HIGH_VAL = '1';
    /** @Description: idenfitifer Medium value for concentration_suppliers_type, cust_conc_clients_type, dependency_degree_cust_type fields */
    private static final String MEDIUM_VAL = '2';
    /** @Description: idenfitifer Low value for concentration_suppliers_type, cust_conc_clients_type, dependency_degree_cust_type fields */
    private static final String LOW_VAL = '3';
    /** @Description: maximum length for activities name */
    private static final Integer MAXLENGTH_ACT = 11;
    /** @Description: maximum length for geographies name */
    private static final Integer MAXLENGTH_GEO = 2;
    /** @Description: api name of concentration suppliers field */
    private static final String CONCSUPL_FLD = 'arce__concentration_suppliers_type__c';
    /** @Description: identifier comments label  */
    private static final String COMMENTS = 'comments';
    /** @Description: identifier name label  */
    private static final String NAME_ID = 'name';
    /** @Description: identifier map field of dependence on customer field config */
    private static final String FLD_DEPECUST = 'arce__dependency_degree_cust_type__c';
    /** @Description: Map consolidated type */
    private static final Map<String, String> MAP_CONSOLTYPE = new Map<String, String> {
        '1' => 'FULL_CONSOLIDATION',
        '2' => 'EQUITY_METHOD',
        '3' => 'NON_CONSOLIDATED',
        '4' => 'NOT_AVAILABLE'
    };
    /**
    * -----------------------------------------------------------------------------------------------
    * @Description - Method that is responsible for invoking the classes to save the
      basic data information.
    * -----------------------------------------------------------------------------------------------
    * @Author  Javier Soto Carrascosa
    * @Date    Created: 04/04/2020
    * @param   listObject - List of the account has analisys object
    * @return  String with the execution message
    * @example save (listObject)
    * -----------------------------------------------------------------------------------------------
    **/
    public static String save(List<sObject> listObject) {
        Boolean hasPermission = Arc_Gen_TabSet_service.hasPermissionToEdit(listObject);

        String retValue;
        if (hasPermission) {
            final arce__Account_has_Analysis__c ahaData = Arc_Gen_Persistence_Utils.getAhaFromSobject(listObject);
            final arce__Account_has_Analysis__c accHasAnalysis = arce.Arc_Gen_AccHasAnalysis_Data.getAccHasAnalysis(new List<String>{(String)ahaData.Id})[0];
            final Map<Id,arce.Arc_Gen_Account_Wrapper> listacc = arce.Arc_Gen_Account_Locator.getAccountInfoById(new List<String>{accHasAnalysis.arce__Customer__c});
            final String participantId = arce.Arc_Gen_CallEncryptService.getEncryptedClient(listacc.get(accHasAnalysis.arce__Customer__c).accNumber);
            final boolean businessRisk = Arc_Gen_OraclePers_service.businessRiskWS(participantId, accHasAnalysis.Name, getFinalJsonRequest(ahaData, accHasAnalysis));
            Arc_Gen_FieldConfig_Data.checkChangesQualQuestion(ahaData, accHasAnalysis, String.valueOf(Arc_Gen_BusinessRisk_Pers_service.class.getName()));
            retValue = JSON.serialize(new arce.Arc_Gen_wrpSave(businessRisk, Label.Arc_Gen_Toast_Success_Title, listObject));
        } else {
            retValue = JSON.serialize(new arce.Arc_Gen_wrpSave(false, Label.Arc_Gen_Generic_NotAllowed, listObject));
        }
        return retValue;
    }
    /**
    * -----------------------------------------------------------------------------------------------
    * @Description - Public method that generates JSON for business risk tab
    * -----------------------------------------------------------------------------------------------
    * @Author  juanignacio.hita.contractor@bbva.com
    * @Date    Created: 28/06/2021
    * @param   arce__Account_has_Analysis__c - aha Object
    * @param   arce__Account_has_Analysis__c - acchasanalysis Object prev
    * @return  Map<String, Object> with WS structure for Business Risk
    * @example Map<String, Object> mapObj = getFinalJsonRequest(ahaData, accHasAnalysis);
    * -----------------------------------------------------------------------------------------------
    **/
    public static Map<String, Object> getFinalJsonRequest(arce__Account_has_Analysis__c ahaData, arce__Account_has_Analysis__c accHasAnalysis) {
        Map<String, Object> finalBusinessRiskMap = new Map<String, Object>();
        finalBusinessRiskMap = Arc_Gen_Persistence_Utils.addifFilled(finalBusinessRiskMap, 'businessInformation', businessRiskJSON(ahaData, accHasAnalysis));
        finalBusinessRiskMap = Arc_Gen_Persistence_Utils.addifFilled(finalBusinessRiskMap, 'affiliateInformation', affiliateInfoJSON(accHasAnalysis));
        return finalBusinessRiskMap;
    }
    /**
    * -----------------------------------------------------------------------------------------------
    * @Description - Method that generates JSON for basic-info WS
    * -----------------------------------------------------------------------------------------------
    * @Author  Javier Soto Carrascosa
    * @Date    Created: 04/04/2020
    * @param   arce__Account_has_Analysis__c - aha Object
    * @param   string - key
    * @return  Map<String, Object> with WS structure for Basic Info WS
    * @example basicInfoJSON(ahaData)
    * -----------------------------------------------------------------------------------------------
    **/
    private static Map<String, Object> businessRiskJSON (arce__Account_has_Analysis__c ahaData, arce__Account_has_Analysis__c prevAha) {
        Map<String, Object> wsObject = new Map<String, Object>();
        final Map<String, String> singleMapAPIName = new Map<String, String>{'geographicScopeType'=>'arce__conc_geography_activity_type__c',
                                                                            'exportSalesPercentage'=>'arce__export_range_year_type__c',
                                                                            'importSalesPercentage'=>'arce__import_range_year_type__c'};
        wsObject = generateSingleMap(ahaData, singleMapAPIName, wsObject);
        wsObject = mapGeoActBool(ahaData, prevAha, GEO_ID, wsObject);
        wsObject = mapGeoActBool(ahaData, prevAha, ACT_ID, wsObject);
        final Map<String, Object> ecoActivity = ecoActivity(ahaData);
        wsObject = Arc_Gen_Persistence_Utils.addifFilled(wsObject, 'economicActivity', ecoActivity);
        final Map<String, Object> diversification = diversifExchange(ahaData, prevAha, 'diversification');
        wsObject = Arc_Gen_Persistence_Utils.addifFilled(wsObject, 'diversification', diversification);
        final Map<String, Object> exchangeRate = diversifExchange(ahaData, prevAha, 'exchangeRateVulnerability');
        wsObject = Arc_Gen_Persistence_Utils.addifFilled(wsObject, 'exchangeRateVulnerability', exchangeRate);
        final Map<String, Object> relevantFacts = relevantFacts(ahaData);
        wsObject = Arc_Gen_Persistence_Utils.addifFilled(wsObject, 'relevantFacts', relevantFacts);
        final List<Map<String, Object>> thirdParties = thirdParties(ahaData, prevAha);
        wsObject = Arc_Gen_Persistence_Utils.addifFilledList(wsObject, 'thirdPartiesDependencies', thirdParties);
        return wsObject;
    }
    /**
    * -----------------------------------------------------------------------------------------------
    * @Description - Method that generates JSON affiliate info
    * -----------------------------------------------------------------------------------------------
    * @Author  juanignacio.hita.contractor@bbva.com
    * @Date    Created: 04/04/2020
    * @param   arce__Account_has_Analysis__c - aha Object
    * @return  Map<String, Object> with WS structure for affiliates
    * @example Map<String, Object> map = affiliateInfoJSON(prevAha);
    * -----------------------------------------------------------------------------------------------
    **/
    private static Map<String, Object> affiliateInfoJSON (arce__Account_has_Analysis__c prevAha) {
        final Map<String, Object> wsObject = new Map<String, Object>();
        final List<Map<String, Object>> lstAffilMap = new List<Map<String, Object>>();
        final List<arce__Third_Participant_Details__c> lstThirdPart = Arc_Gen_ThirdParticipantDetails_Data.getRecordsbyArcAcc(MAFI, new List<String>{(String)prevAha.Id});
        if (lstThirdPart.isEmpty()) {
            final Map<String,Object> fakeTpart = generateFakeThird(MAFI, '', prevAha);
            lstAffilMap.add(fakeTpart);
        } else {
            for (arce__Third_Participant_Details__c record : lstThirdPart) {
                // For arce__anlys_wkfl_cnsld_ffss_type__c == BOTTOM_UP the table doesnt have field in the form.
                final String consolType = record.arce__consolidation_method_id__c == '' || record.arce__consolidation_method_id__c == null ?
                MAP_CONSOLTYPE.get('4') : MAP_CONSOLTYPE.get(record.arce__consolidation_method_id__c);
                final Map<String, Object> affilMap = new Map<String, Object>();
                affilMap.put('isBBVACustomer', Arc_Gen_Persistence_Utils.booleanFromYesNo(record.arce__non_customer_type__c));
                affilMap.put('consolidationType', consolType);
                affilMap.put('groupParticipation', record.arce__third_participant_per__c);
                affilMap.put(ACT_ID, Arc_Gen_Persistence_Utils.cutString(record.arce__economic_activity_sector_desc__c,11));
                affilMap.put(NAME_ID, record.arce__third_participant_desc__c);
                affilMap.put('id', record.Id);
                lstAffilMap.add(affilMap);
            }
        }
        if (arce.Arc_Gen_ValidateInfo_utils.isFilled(prevAha.arce__main_affiliates_desc__c)) {
            wsObject.put(COMMENTS, prevAha.arce__main_affiliates_desc__c);
        }
        wsObject.put('affiliates', lstAffilMap);
        return wsObject;
    }
    /**
    * -----------------------------------------------------------------------------------------------
    * @Description - Method that generates single Map or default value if emput
    * -----------------------------------------------------------------------------------------------
    * @Author  Javier Soto Carrascosa
    * @Date    Created: 04/04/2020
    * @param   arce__Account_has_Analysis__c - aha Object
    * @param   Map<String, String> - singleMapAPIName
    * @param   Map<String, Object> - wsObject
    * @return  Map<String, Object> with WS structure for Basic Info WS
    * @example addSingleMap(ahaData,singleMapAPIName,wsObject)
    * -----------------------------------------------------------------------------------------------
    **/
    private static Map<String, Object> generateSingleMap (arce__Account_has_Analysis__c ahaData, Map<String, String> singleMapAPIName, Map<String, Object> wsObject) {
        for (string element : singleMapAPIName.keySet()) {
            wsObject.put(element, Arc_Gen_Persistence_Utils.defaultValueList((String)ahaData.get(singleMapAPIName.get(element))));
        }
        return wsObject;
    }
    /**
    * -----------------------------------------------------------------------------------------------
    * @Description - Method that generates single Map or default value if emput
    * -----------------------------------------------------------------------------------------------
    * @Author  Javier Soto Carrascosa
    * @Date     Created: 04/04/2020
    * @param arce__Account_has_Analysis__c - aha Object
    * @param string - geoOrAct
    * @param Map<String, Object> - wsObject
    * @return Map<String, Object> with WS structure
    * @example mapGeoActBool(ahaData,geoOrAct,wsObject)
    * -----------------------------------------------------------------------------------------------
    **/
    private static Map<String,Object> mapGeoActBool (arce__Account_has_Analysis__c ahaData, arce__Account_has_Analysis__c prevAha, String geoOrAct, Map<String, Object> wsObject) {
        Map<String,String> currentMap = new Map<String, String>();
        Map<String,Object> insideMap = new Map<String,Object>();
        switch on geoOrAct {
            when 'geography' {
                currentMap = new Map<String,String>{'isGlobalBusiness'=>'arce__customer_multi_country_type__c',COMMENTS=>'arce__breakdown_geography_desc__c'};
                final List<Map<String, Object>> lstGeoObj = getOtherGeographies(geoOrAct, Arc_Gen_TableContentPerAnalysis_Data.getRecordsbyArcAcc(GEO, new List<String>{ahaData.Id}));
                final Boolean geoObjBoolVal = getValLogicGeoAct(prevAha, ahaData, GEO_ID);
                if (!lstGeoObj.isEmpty() && geoObjBoolVal) {
                    insideMap.put('otherGeographiesResultsDistributions', lstGeoObj);
                }
            }
            when 'activity' {
                currentMap = new Map<String,String>{'hasMultiLineBusiness'=>'arce__cust_multi_business_line_type__c',COMMENTS=>'arce__breakdown_activity_desc__c'};
                final List<Map<String, Object>> lstActivityObj = getOtherGeographies(geoOrAct, Arc_Gen_TableContentPerAnalysis_Data.getRecordsbyArcAcc(ACT, new List<String>{ahaData.Id}));
                final Boolean actObjBoolVal = getValLogicGeoAct(prevAha, ahaData, ACT_ID);
                if (!lstActivityObj.isEmpty() && actObjBoolVal) {
                    insideMap.put('otherActivitiesResultsDistributions', lstActivityObj);
                }
            }
        }
        for (string element : currentMap.keySet()) {
            if (element == COMMENTS) {
                insideMap.put(element,ahaData.get(currentMap.get(element)));
            } else {
                insideMap.put(element,Arc_Gen_Persistence_Utils.booleanFromYesNo((String)ahaData.get(currentMap.get(element))));
            }
        }
        wsObject.put(geoOrAct,(Object)insideMap);
        return wsObject;
    }
    /**
    * -----------------------------------------------------------------------------------------------
    * @Description - Method that generates map for economicactivity
    * -----------------------------------------------------------------------------------------------
    * @Author  Javier Soto Carrascosa
    * @Date    Created: 04/04/2020
    * @param   arce__Account_has_Analysis__c - aha Object
    * @return  Map<String, Object> with WS structure
    * @example Map<String, Object> map = ecoActivity(ahaData)
    * -----------------------------------------------------------------------------------------------
    **/
    private static Map<String, Object> ecoActivity (arce__Account_has_Analysis__c ahaData) {
        Map<String, Object> ecoMap = new Map<String, Object>();
        if (arce.Arc_Gen_ValidateInfo_utils.isFilled((String)ahaData.get('arce__gf_cust_economic_activity_desc__c'))) {
            //ecoMap = new Map<String,Object>{DESCRIPTION=>ahaData.get('arce__gf_cust_economic_activity_desc__c')};
            String valueStr = (String) ahaData.get('arce__gf_cust_economic_activity_desc__c');
            valueStr = valueStr.length() > 1000 ? valueStr.substring(0,999) : valueStr;
            ecoMap = new Map<String,Object>{DESCRIPTION => valueStr};
        }
        return ecoMap;
    }
    /**
    * -----------------------------------------------------------------------------------------------
    * @Description - Method that generates map diversification and exchange rating vulnerability
    * -----------------------------------------------------------------------------------------------
    * @Author  Javier Soto Carrascosa
    * @Date    Created: 04/04/2020
    * @param   arce__Account_has_Analysis__c - aha Object
    * @param   arce__Account_has_Analysis__c - aha Object
    * @param   String - key
    * @return  Map<String, Object> with WS structure
    * @example Map<String, Object> map = diversifExchange(ahaData, prevAha, key)
    * -----------------------------------------------------------------------------------------------
    **/
    private static Map<String, Object> diversifExchange (arce__Account_has_Analysis__c ahaData, arce__Account_has_Analysis__c prevAha, String key) {
        final Map<String,String> diversification = new Map<String,String>{'diversificationType'=>'arce__dvrsfn_product_service_type__c',DESCRIPTION=>'arce__dvrsfn_product_service_desc__c'};
        final Map<String,String> exchangeRate = new Map<String,String>{'vulnerabilityType'=>'arce__exch_rate_vulnerability_type__c',DESCRIPTION=>'arce__exch_rate_vulnerability_desc__c'};
        Map<String,String> currentMap = key == 'diversification' ? diversification : exchangeRate;
        Map<String,Object> insideMap = new Map<String,Object>();
        boolean generateMap = false;
        for (string element : currentMap.keySet()) {
            if (element == DESCRIPTION) {
                insideMap.put(element,ahaData.get(currentMap.get(element)));
            } else if(arce.Arc_Gen_ValidateInfo_utils.isFilled((String)ahaData.get(currentMap.get(element))) || arce.Arc_Gen_ValidateInfo_utils.isFilled((String)prevAha.get(currentMap.get(element)))) {
                insideMap.put(element,Arc_Gen_Persistence_Utils.defaultValueList((String)ahaData.get(currentMap.get(element))));
                generateMap = true;
            }
        }
        return generateMap == true ? insideMap : new Map<String, Object>();
    }
    /**
    * -----------------------------------------------------------------------------------------------
    * @Description - Method that generates map for relevant facs
    * -----------------------------------------------------------------------------------------------
    * @Author  Javier Soto Carrascosa
    * @Date    Created: 04/04/2020
    * @param   arce__Account_has_Analysis__c - aha Object
    * @return  Map<String, Object> with WS structure
    * @example relevantFacts(ahaData,wsObject)
    * -----------------------------------------------------------------------------------------------
    **/
    private static Map<String, Object> relevantFacts (arce__Account_has_Analysis__c ahaData) {
        Map<String, Object> relevantFactsMap = new Map<String, Object>();
        if (arce.Arc_Gen_ValidateInfo_utils.isFilled((String)ahaData.get('arce__new_business_venture_type__c')) && arce.Arc_Gen_ValidateInfo_utils.isFilled((String)ahaData.get('arce__new_business_venture_desc__c'))) {
            relevantFactsMap = new Map<String,Object>{'hasSignificant'=>(Object)Arc_Gen_Persistence_Utils.booleanFromYesNo((String)ahaData.get('arce__new_business_venture_type__c')), DESCRIPTION => ahaData.get('arce__new_business_venture_desc__c')};
        }
        return relevantFactsMap;
    }
    /**
    * -----------------------------------------------------------------------------------------------
    * @Description - Method that generates map for third participants
    * -----------------------------------------------------------------------------------------------
    * @Author  Javier Soto Carrascosa
    * @Date    Created: 04/04/2020
    * @param   arce__Account_has_Analysis__c - aha Object
    * @param   arce__Account_has_Analysis__c - aha Object
    * @return  List<Map<String,Object>>
    * @example List<Map<String,Object>> lst = thirdParties (ahaData, prevAha);
    * -----------------------------------------------------------------------------------------------
    **/
    private static List<Map<String,Object>> thirdParties (arce__Account_has_Analysis__c ahaData, arce__Account_has_Analysis__c prevAha) {
        List<Map<String,Object>> listThirdParties = new List<Map<String,Object>>();
        List<arce__Third_Participant_Details__c> listadoSupAndClients = new List<arce__Third_Participant_Details__c>();
        if (arce.Arc_Gen_ValidateInfo_utils.isFilled((String)ahaData.get(CONCSUPL_FLD)) || arce.Arc_Gen_ValidateInfo_utils.isFilled((String)prevAha.get(CONCSUPL_FLD))) {
            listadoSupAndClients = Arc_Gen_ThirdParticipantDetails_Data.getRecordsbyArcAcc(MAIN_SUPPL, new List<String>{(String)ahaData.Id});
            listThirdParties.addAll(processThirdParties(listadoSupAndClients,SUPPLIER,ahaData,getValFillVal(prevAha, ahaData, CONCSUPL_FLD)));
        }
        if (arce.Arc_Gen_ValidateInfo_utils.isFilled((String)ahaData.get(FLD_DEPECUST)) || arce.Arc_Gen_ValidateInfo_utils.isFilled((String)prevAha.get(FLD_DEPECUST))) {
            listadoSupAndClients = Arc_Gen_ThirdParticipantDetails_Data.getRecordsbyArcAcc(MAIN_CLIENTS, new List<String>{(String)ahaData.Id});
            listThirdParties.addAll(processThirdParties(listadoSupAndClients,CUSTOMER,ahaData,getValFillVal(prevAha, ahaData, FLD_DEPECUST)));
        }
        return listThirdParties;
    }
    /**
    * -----------------------------------------------------------------------------------------------
    * @Description - Method that generates map for relevant facs
    * -----------------------------------------------------------------------------------------------
    * @Author  Javier Soto Carrascosa
    * @Date    Created: 04/04/2020
    * @param   List<arce__Third_Participant_Details__c> listThird
    * @param   String key
    * @param   arce__Account_has_Analysis__c ahaData
    * @param   arce__Account_has_Analysis__c prevAha
    * @param   String fldClientDep
    * @return  List<Map<String,Object>>
    * @example List<Map<String,Object>> lst = processThirdParties(listThird, key, ahaData, fldClientDep);
    * -----------------------------------------------------------------------------------------------
    **/
    private static List<Map<String,Object>> processThirdParties (List<arce__Third_Participant_Details__c> listThird, String key, arce__Account_has_Analysis__c ahaData, String fldClientStr) {
        List<Map<String,Object>> listThirdParties = new List<Map<String,Object>>();
        if (listThird.isEmpty() || fldClientStr == LOW_VAL) {
            final Map<String,Object> fakeTpart = generateFakeThird(key, fldClientStr, ahaData);
            listThirdParties.add(fakeTpart);
        } else if (!listThird.isEmpty() && (fldClientStr == MEDIUM_VAL || fldClientStr == HIGH_VAL)) {
            for(arce__Third_Participant_Details__c thirdPart : listThird) {
                Map<String,Object> tPart = new Map<String,Object>();
                tpart.put('percentage',thirdPart.get('arce__third_participant_per__c'));
                tpart.put(NAME_ID,thirdPart.get('arce__third_participant_desc__c'));
                tpart.put('dependencyDegree', fldClientStr);
                tpart.put('thirdPartyDependencyType',key);
                tpart.put('id',thirdPart.get('Id'));
                listThirdParties.add(tPart);
            }
        }
        return listThirdParties;
    }
    /**
    * -----------------------------------------------------------------------------------------------
    * @Description - Method that generates map for relevant facs
    * -----------------------------------------------------------------------------------------------
    * @Author  Javier Soto Carrascosa
    * @Date    Created: 04/04/2020
    * @param   String key
    * @param   String value
    * @param   arce__Account_has_Analysis__c ahaData
    * @return  Map<String, Object> with WS structure
    * @example relevantFacts(ahaData,wsObject)
    * -----------------------------------------------------------------------------------------------
    **/
    private static Map<String, Object> generateFakeThird(String key, String value, arce__Account_has_Analysis__c ahaData) {
        final Map<String,Object> tPart = new Map<String,Object>();
        if (key == MAFI) {
            tpart.put('isBBVACustomer', false);
            tpart.put('consolidationType', 'NOT_AVAILABLE');
            tpart.put('groupParticipation', 0);
            tpart.put(ACT_ID, 'ACTIVITY');
            tpart.put(NAME_ID, 'PLACEHOLDER NAME');
            tpart.put('id', ahaData.GET('Id'));
        } else {
            tpart.put('percentage',(Object)0);
            tpart.put(NAME_ID,(Object)'PLACEHOLDER NAME');
            tpart.put('dependencyDegree', value);
            tpart.put('thirdPartyDependencyType',(Object)key);
            tpart.put('id', ahaData.GET('Id'));
        }
        return tPart;
    }
    /**
    * -----------------------------------------------------------------------------------------------
    * @Description - Method that generates JSON geographies info
    * -----------------------------------------------------------------------------------------------
    * @Author  juanignacio.hita.contractor@bbva.com
    * @Date    Created: 21/06/2021
    * @param   String geoOrAct
    * @param   List<arce__Table_Content_per_Analysis__c> lstTableContent
    * @return  List<Map<String, String>>
    * @example List<Map<String, String>> lstTable = getOtherGeographies(lstTableContent);
    * -----------------------------------------------------------------------------------------------
    **/
    private static List<Map<String, Object>> getOtherGeographies(String geoOrAct, List<arce__Table_Content_per_Analysis__c> lstTableContent) {
        final List<Map<String, Object>> lstMapOtherGeo = new List<Map<String, Object>>();
        for (arce__Table_Content_per_Analysis__c record : lstTableContent) {
            final Map<String, Object> mapOtherGeo = new Map<String, Object>();
            final String collectionName = record.arce__Data_Collection_Id__r.Name;
            mapOtherGeo.put('otherConceptName', collectionName);
            mapOtherGeo.put('value', record.arce__table_content_percentage__c);
            switch on geoOrAct {
                when 'geography' {
                    final String name = collectionName.length() > MAXLENGTH_GEO ? collectionName.substring(0,2) : collectionName;
                    mapOtherGeo.put(NAME_ID, name);
                }
                when 'activity' {
                    if (record.Name.length() > MAXLENGTH_ACT) {
                        throw new AuraHandledException(String.format(Label.Arc_Gen_OraclePersistenceError, new List<String>{Label.Arc_Gen_OraclePersistenceError}));
                    } else {
                        mapOtherGeo.put(NAME_ID, record.Name);
                    }
                }
            }
            mapOtherGeo.put('id', record.arce__table_content_year__c);
            lstMapOtherGeo.add(mapOtherGeo);
        }
        return lstMapOtherGeo;
    }
    /**
    * -----------------------------------------------------------------------------------------------
    * @Description - Method that return logic for persist geographies and activities table
    * -----------------------------------------------------------------------------------------------
    * @Author  juanignacio.hita.contractor@bbva.com
    * @Date    Created: 25/06/2021
    * @param   arce__Account_has_Analysis__c prevAha
    * @param   arce__Account_has_Analysis__c ahaData
    * @param   String geoAct
    * @return  String api name field
    * @example Boolean str = getValLogicGeoAct(prevAha, ahaData, geoAct);
    * -----------------------------------------------------------------------------------------------
    **/
    private static Boolean getValLogicGeoAct(arce__Account_has_Analysis__c prevAha, arce__Account_has_Analysis__c ahaData, String geoAct) {
        Boolean boolReturn;
        if (prevAha.get('arce__anlys_wkfl_cnsld_ffss_type__c') == arce.Arc_Gen_Constants.TDBU_TOP_DOWN) {
            if (geoAct == GEO_ID) {
                boolReturn = ahaData.arce__customer_multi_country_type__c == YES_MULTI;
            } else if (geoAct == ACT_ID) {
                boolReturn = ahaData.arce__cust_multi_business_line_type__c == YES_MULTI;
            }
        } else if (prevAha.get('arce__anlys_wkfl_cnsld_ffss_type__c') == arce.Arc_Gen_Constants.TDBU_BOTTOM_UP) {
            final Boolean groupAssetGeoAct = prevAha.arce__group_asset_header_type__c == arce.Arc_Gen_Constants.GROUP_ASSET_HEADER_TYPE_HEADER;
            Boolean subsCustGeoAct;
            if (geoAct == GEO_ID) {
                subsCustGeoAct = !groupAssetGeoAct && ahaData.arce__customer_multi_country_type__c == YES_MULTI;
            } else if (geoAct == ACT_ID) {
                subsCustGeoAct = !groupAssetGeoAct && ahaData.arce__cust_multi_business_line_type__c == YES_MULTI;
            }
            boolReturn = groupAssetGeoAct || subsCustGeoAct;
        }
        return boolReturn;
    }
    /**
    * -----------------------------------------------------------------------------------------------
    * @Description - Method that return value of field in prevAha or ahaData
    * -----------------------------------------------------------------------------------------------
    * @Author  juanignacio.hita.contractor@bbva.com
    * @Date    Created: 29/06/2021
    * @param   arce__Account_has_Analysis__c prevAha: aha last version before save
    * @param   arce__Account_has_Analysis__c ahaData: current aha data object
    * @param   String field: name field
    * @example String str = getValFillVal(prevAha, ahaData, field);
    * -----------------------------------------------------------------------------------------------
    **/
    private static String getValFillVal(arce__Account_has_Analysis__c prevAha, arce__Account_has_Analysis__c ahaData, String field) {
        return ahaData.get(field) == null ? (String) prevAha.get(field) : (String) ahaData.get(field);
    }
}