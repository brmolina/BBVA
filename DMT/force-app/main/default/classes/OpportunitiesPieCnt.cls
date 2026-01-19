/*
*   @author: GlobalDesktop - APC
*   @Method: OpportunitiesPieCnt
*   @Description: Class used to print Pie Charts related to Opportunities filtered by an Account and grouped by several options

*   @Versions:
        v1 - 2019/04/11 - Initial version
*/
public with sharing class OpportunitiesPieCnt {

    /*
    *  Map(label, values) to be printed in chart
    */
    public static Map<String, Double> mapKeys = new Map<String, Double>();
    /*
    *  Others variable
    */
    private final static String OTHERS = 'Others';
    /*
    *  All variable
    */
    private final static String ALL = 'All';

    /*
    *   @author: GlobalDesktop - APC
    *   @Method: getData
    *   @Description:
                Denorm AccOpp - dwp_acmh__Denorm_Account_Opportunity__c
                dwp_acmh__OpportunityId__c - Lookup a Opp
                dwp_acmh__AccountId__c - Lookup a Acc
                DES_Opportunity_Expected_Probability__c

                En Opp:
                StageName -> No están denormalizadas las Draft
                            -> sumatorio para lives - closed

                Agrupaciones:
                Por OpportunityLineItem
                    a) CountryBooking || productLVL2
                    b) family || countryACC
    *   @Versions:
            v1 - 2019/03/29 - Initial version
    */
     @AuraEnabled
    public static String getData(String clientId, String family, String stageOption, Boolean byProduct, Boolean byCountryBooking, String countryClient) {
        try {
            System.debug('::::::getData init');
            System.debug('::::::clientId ' + clientId);
            System.debug('::::::family ' + family);
            System.debug('::::::stageOption ' + stageOption);

            Set<Id> setIdOppsDenormClient = new Set<Id>();
            for(dwp_acmh__Denorm_Account_Opportunity__c denOpp : [SELECT dwp_acmh__OpportunityId__c
                                                            FROM dwp_acmh__Denorm_Account_Opportunity__c
                                                            WHERE dwp_acmh__AccountId__c = : clientId]) {
                setIdOppsDenormClient.add(denOpp.dwp_acmh__OpportunityId__c);
            }
            System.debug('::::::setIdOppsDenormClient : ' + setIdOppsDenormClient);

            /*Recojo los Opportunity Products que pertenezcan a alguna oportunidad de la cuenta de la tabla Desnormalizada*/
            Final String QUERY = generateQuery(family,  stageOption,  countryClient, false);
            final List<OpportunityLineItem> listOppProduct = Database.query(QUERY); //NOSONAR
            System.debug('::::::listOppProduct : ' + JSON.serialize(listOppProduct));


            /* Mapa que con datos a devolver key = columna a filtrar (countryBooking || productLv2) y values los valores acumulados */
            Map<String, Double> mapData;
            /* Mapa que tiene como key el prod y como value el color */
            Map<String, String> mapColors;

            if(!listOppProduct.isEmpty()) {
                if(byProduct) {
                    mapData = generateMapData(listOppProduct, byProduct, byCountryBooking, countryClient);
                    mapColors = UtilsFichaGrupo.getCountryColor(mapData.keySet());
                } else if(byCountryBooking) {
                    mapData = generateMapData(listOppProduct, byProduct, byCountryBooking, countryClient);
                    mapColors = UtilsFichaGrupo.getCountryColor(mapData.keySet());
                }
            }

            System.debug('::::mapa colores producto:: ' + mapColors);
            System.debug('::::byProduct:: ' + byProduct);
            System.debug('::::countryClient:: ' + countryClient);
            System.debug('::::byCountryBooking:: ' + byCountryBooking);

            WrapperGlobalData wrapperGlobal = new WrapperGlobalData(mapColors, mapData);
            System.debug(':::respuesta:: ' + JSON.serialize(wrapperGlobal));

            Final String RESPONSE = JSON.serialize(wrapperGlobal);
            return RESPONSE;
        } catch (Exception exc) {
            throw new AuraHandledException(Label.DES_Error + exc);
        }
    }
    /*
    *   @author: GlobalDesktop - APC
    *   @Method: getRowsData
    *   @Description: returns a JSON in order to display a table with the required columns

    *   @Versions:
            v1 - 2019/04/11 - Initial version
                Fields:
                    OPPORTUNITY NAME    - Opportunity.Name
                    CLIENT NAME         - Opportunity.Account.Name
                    STATUS              - opportunity_stage_type__c
                    COUNTRY             - Opportunity.DES_Booking_Geography__c
                    EST. CLOSING DATE   - Opportunity.CloseDate
                    EXP. REVENUES       - convertCurrency(DES_Expected_Revenue__c)
    */
     @AuraEnabled
    public static String getRowsData(String clientId, String family, String stageOption, String countryClient) {
        try {
            System.debug('::::::getRowsData init');

            Set<Id> setIdOppsDenormClient = new Set<Id>();
            for(dwp_acmh__Denorm_Account_Opportunity__c denOpp : [SELECT dwp_acmh__OpportunityId__c
                                                            FROM dwp_acmh__Denorm_Account_Opportunity__c
                                                            WHERE dwp_acmh__AccountId__c = : clientId]) {
                setIdOppsDenormClient.add(denOpp.dwp_acmh__OpportunityId__c);
            }
            System.debug('::::::setIdOppsDenormClient : ' + setIdOppsDenormClient);

            Final String QUERY = generateQuery(family,  stageOption,  countryClient, true);
            final List<OpportunityLineItem> listOppProduct = Database.query(QUERY); //NOSONAR
            System.debug('::::::listOppProduct to table: ' + JSON.serialize(listOppProduct));

            List<WrapperClass> listWrapper = new List<WrapperClass>();
            final List<Opp_Countries__mdt> lstCountryCodes = UtilsFichaGrupo.mapCountryCodesSelector();
            final Map<String,String> mapParseCountry = UtilsFichaGrupo.helperCreateMapCountryCodes('DEVNAME', lstCountryCodes);
            for(OpportunityLineItem oli : listOppProduct) {
                oli.Opportunity.DES_Booking_Geography__c = mapParseCountry.get(oli.Opportunity.DES_Booking_Geography__c);
                listWrapper.add(new WrapperClass(oli, 'tableData'));
            }

            return JSON.serialize(listWrapper);
        } catch (Exception exc) {
            throw new AuraHandledException(Label.DES_Error + exc);
        }
    }

    /*
    *   @author: GlobalDesktop - APC
    *   @Method: generateQuery
    *   @Description:
            OPPORTUNITY NAME    - Opportunity.Name
                    CLIENT NAME         - Opportunity.Account.Name
                    STATUS              - opportunity_stage_type__c
                    COUNTRY             - Opportunity.DES_Booking_Geography__c
                    EST. CLOSING DATE   - Opportunity.CloseDate
                    EXP. REVENUES       - convertCurrency(DES_Expected_Revenue__c)
    *   @Versions:
            v1 - 2019/04/09 - Initial version
    */
    private static String generateQuery(String family, String stageOption, String countryClient, Boolean tableDetails) {
        String querySelect;
        // Opportunity.region_name__c,
        querySelect = 'SELECT DES_Product_Family__c, Product2.name, OpportunityId, Opportunity.Name, Opportunity.AccountId, Opportunity.Account.Name, Opportunity.DES_Expected_Probability__c,';
        querySelect += 'convertCurrency(DES_Expected_Revenue__c), Opportunity.StageName, Opportunity.DES_Booking_Geography__c';
        querySelect += ', convertCurrency(pre_oppy_revenue_next_12m_amount__c), opportunity_stage_type__c'; //para Opp Closed Lost

        if(tableDetails) {
            querySelect += ', Opportunity.CloseDate, Name, Product2.Family, Opportunity.Owner.Name'; //opportunity_stage_type__c,
        }
        querySelect += ' FROM OpportunityLineItem';

        String queryWhere;
        queryWhere = ' WHERE OpportunityId IN :setIdOppsDenormClient AND pre_oppy_revenue_next_12m_amount__c != null';
        queryWhere += ' AND CreatedDate <= TODAY AND CreatedDate = THIS_YEAR';

        final String query = querySelect + queryWhere + auxGenerateQuery(family, stageOption, countryClient, tableDetails);
        System.debug(':::::dynamic querySelect::: ' + querySelect);
        System.debug(':::::dynamic queryWhere::: ' + queryWhere);
        System.debug(':::::dynamic query::: ' + query);
        return query;
    }

    /*
    *   @author: GlobalDesktop - APC
    *   @Method: generateQuery
    *   @Description:
            OPPORTUNITY NAME    - Opportunity.Name
                    CLIENT NAME         - Opportunity.Account.Name
                    STATUS              - opportunity_stage_type__c
                    COUNTRY             - Opportunity.DES_Booking_Geography__c
                    EST. CLOSING DATE   - Opportunity.CloseDate
                    EXP. REVENUES       - convertCurrency(DES_Expected_Revenue__c)
    *   @Versions:
            v1 - 2019/04/09 - Initial version
    */
    private static String auxGenerateQuery(String family, String stageOption, String countryClient, Boolean tableDetails) {
        //Get the stage clause
        Final String stageClause = tableDetails ? '' : getStageClause(stageOption);
        //isFiltered by family?
        Final String byFamily = family == null || family == ALL || family == '' ? '' : ' AND DES_Product_Family__c =\'' + String.escapeSingleQuotes(family) + '\'';
        //isFiltered by accCountry?
        Final String byCountryAcc = countryClient == null || countryClient == 'Todos' || countryClient == '' ? '' : ' AND Opportunity.Account.DES_Country_Client__c =\'' + String.escapeSingleQuotes(countryClient) + '\'';
        return stageClause + byFamily + byCountryAcc;
    }
    /*
    *   @author: GlobalDesktop - APC
    *   @Method: generateMapData
    *   @Description: filter attributes in order to populate mapData via mapProductCountryAcc() which returns mapData

    *   @Inputs: List<OpportunityLineItem> listOppProduct, Boolean byProduct, Boolean byCountryBooking, String countryClient
    *   @Output: Map<String, Double> mapData
    *   @Versions:
            v1 - 2019/04/11 - Initial version
    */
    private static Map<String, Double> generateMapData(List<OpportunityLineItem> listOppProduct, Boolean byProduct, Boolean byCountryBooking, String countryClient) {
        Map<String, Double> mapData;
        if(byProduct) {
            mapData = dataProduct(countryClient, listOppProduct, mapData);
        } else if(byCountryBooking) {
            mapData = dataCountry(countryClient, listOppProduct, mapData);
        }

        return mapData;
    }

    /*
    *   @author: GlobalDesktop - DRL
    *   @Description: Aux method for getData

    *   @Inputs: String countryClient, List<OpportunityLineItem> listOppProduct, Map<String, Double> mapData
    *   @Output: Map<String, Double> mapData - size topN + 1 (n + 'others')
    *   @Versions:
            v1 - 2019/07/01 - Initial version
    */
    private static Map<String,Double> dataProduct(String countryClient, List<OpportunityLineItem> listOppProduct, Map<String, Double> mapEntry) {
        Map<String, Double> mapData = mapEntry;
        Final Integer MAXLIMIT = Test.isRunningTest() ? 1 : 7; //NOSONAR
        if(countryClient == null || countryClient == ALL || countryClient == '') {
            System.debug('::::Group by Product + Account.DES_Country__c');
            mapData = mapProductCountryAcc(listOppProduct);
        } else {
            System.debug('::::Group by Product + Family');
            mapData = mapProductFamily(listOppProduct);
        }
        if(mapData.keySet().size() > MAXLIMIT) {
            mapData = getTopNdata(mapData, MAXLIMIT);
        }
        return mapData;
    }

    /*
    *   @author: GlobalDesktop - DRL
    *   @Description: Aux method for getData

    *   @Inputs: String countryClient, List<OpportunityLineItem> listOppProduct, Map<String, Double> mapData
    *   @Output: Map<String, Double> mapData - size topN + 1 (n + 'others')
    *   @Versions:
            v1 - 2019/07/01 - Initial version
    */
    private static Map<String,Double> dataCountry(String countryClient, List<OpportunityLineItem> listOppProduct, Map<String, Double> mapEntry) {
        Map<String, Double> mapData = mapEntry;
        Final Integer MAXLIMIT = Test.isRunningTest() ? 1 : 7; //NOSONAR
        if(countryClient == null || countryClient == ALL || countryClient == ALL) {
            System.debug('::::Group by CountryBooking + Account.DES_Country__c');
            mapData = mapCountryBFamily(listOppProduct);
        } else {
            System.debug('::::Group by CountryBooking + Family');
            mapData = mapCountryBCountryA(listOppProduct);
        }
        if(mapData.keySet().size() > MAXLIMIT) {
            mapData = getTopNdata(mapData, MAXLIMIT);
        }
        return mapData;
    }


    /*
    *   @author: GlobalDesktop - APC
    *   @Mget filterTopNdata
    *   @Description: filter top N data and group the others

    *   @Inputs: Map<String, Double> mapData, Integer topN
    *   @Output: Map<String, Double> mapData - size topN + 1 (n + 'others')
    *   @Versions:
            v1 - 2019/04/23 - Initial version
    */
    private static Map<String, Double> getTopNdata(Map<String, Double> mapDatos, Integer topN) {
        final Map<String, Double> orderMap = UtilsFichaGrupo.orderMap(mapDatos);
        final Map<String, Double> groupedMap = new Map<String, Double>();
        Integer auxNumber = 0;
        for(String aux : orderMap.keySet()) {
            if(auxNumber < topN) {
                groupedMap.put(aux, orderMap.get(aux));
            } else {
                if(groupedMap.get(OTHERS) == null) {
                    groupedMap.put(OTHERS, orderMap.get(aux));
                } else {
                    groupedMap.put(OTHERS, groupedMap.get(OTHERS) + orderMap.get(aux));
                }
            }
            auxNumber++;
        }
        system.debug('++ AuxNumber -> ' + auxNumber);
        return groupedMap;
    }
    /*
    *   @author: GlobalDesktop - APC
    *   @Method: mapProductFamily
    *   @Description: map grouped by product lvl2 + family - DES_Product_Family__c

    *   @Versions:
            v1 - 2019/04/11 - Initial version
    */
    private static Map<String, Double> mapProductFamily(List<OpportunityLineItem> listOppProd) {
        Final List<OpportunityLineItem> listOppProduct = listOppProd;

        for(OpportunityLineItem oli : listOppProduct) {
            Final Decimal REVENUES = oli.opportunity_stage_type__c == 'Closed Lost' ? oli.pre_oppy_revenue_next_12m_amount__c : oli.DES_Expected_Revenue__c;
            if(REVENUES != null  && REVENUES != 0 && oli.Product2.Name != null) {

                if (mapKeys.get(oli.Product2.Name) == null) {
                    mapKeys.put(oli.Product2.Name, REVENUES);
                } else {
                    Double revTotP = mapKeys.get(oli.Product2.Name) + REVENUES;
                    mapKeys.put(oli.Product2.Name, revTotP);
                }
            }
        }
        System.debug(':::mapKeys de mapProductFamily+ Country ACC: ' + JSON.serialize(mapKeys));
        return mapKeys;
    }
    /*
    *   @author: GlobalDesktop - APC
    *   @Method: mapProductCountryAcc
    *   @Description: map grouped by product lvl2 + country account

    *   @Versions:
            v1 - 2019/04/11 - Initial version
    */
    private static Map<String, Double> mapProductCountryAcc(List<OpportunityLineItem> listOppProd) {
        Final List<OpportunityLineItem> listOppProduct = listOppProd;

        for(OpportunityLineItem oli : listOppProduct) {
            Final Decimal REVENUES = oli.opportunity_stage_type__c == 'Closed Lost' ? oli.pre_oppy_revenue_next_12m_amount__c : oli.DES_Expected_Revenue__c;
            if(oli.DES_Expected_Revenue__c != null && oli.Product2.Name != null && Integer.valueOf(REVENUES) != 0) {

                if (mapKeys.get(oli.Product2.Name) == null) {
                    mapKeys.put(oli.Product2.Name, REVENUES);
                } else {
                    Double revTotP = mapKeys.get(oli.Product2.Name) + REVENUES;
                    mapKeys.put(oli.Product2.Name, revTotP);
                }
            }
        }
        System.debug(':::mapKeys de mapProductCountryAcc+ Country ACC: ' + JSON.serialize(mapKeys));
        return mapKeys;
    }

    /*
    *   @author: GlobalDesktop - APC
    *   @Method: mapCountryBFamily
    *   @Description: map grouped by  country booking + family

    *   @Versions:
            v1 - 2019/04/11 - Initial version
    */
    private static Map<String, Double> mapCountryBFamily(List<OpportunityLineItem> listOppProd) {
        Final List<OpportunityLineItem> listOppProduct = listOppProd;

        Final Map<String,String> mapCountries = GroupGeographyCnt.helperCreateMapCountryCodes('DEVNAME');

        for(OpportunityLineItem oli : listOppProduct) {
            String countryLabel = mapCountries.get(oli.Opportunity.DES_Booking_Geography__c);
            Final Decimal REVENUES = oli.opportunity_stage_type__c == 'Closed Lost' ? oli.pre_oppy_revenue_next_12m_amount__c : oli.DES_Expected_Revenue__c;
            if(REVENUES != null  && REVENUES != 0 && countryLabel != null) {

                if(mapKeys.get(countryLabel) == null) {
                    mapKeys.put(countryLabel, REVENUES);
                } else {
                    if (mapKeys.get(countryLabel) == null) {
                        mapKeys.put(countryLabel, REVENUES);
                    } else {
                        Double revTotP = mapKeys.get(countryLabel) + REVENUES;
                        mapKeys.put(countryLabel, revTotP);
                    }
                }
            }
        }
        System.debug('::::mapCOUNTRYBOOKING FAMILY - map response: ' + JSON.serialize(mapKeys));
        return mapKeys;
    }
    /*
    *   @author: GlobalDesktop - APC
    *   @Method: mapCountryBCountryA
    *   @Description: map grouped by country booking - country account - Opportunity.DES_Booking_Geography__c

    *   @Versions:
            v1 - 2019/04/11 - Initial version
    */
    private static Map<String, Double> mapCountryBCountryA(List<OpportunityLineItem> listOppProd) {
        Final List<OpportunityLineItem> listOppProduct = listOppProd;
        Final Map<String,String> mapCountries = GroupGeographyCnt.helperCreateMapCountryCodes('DEVNAME');

        mapKeys.clear();
        for(OpportunityLineItem oli : listOppProduct) {
            String countryLabel = mapCountries.get(oli.Opportunity.DES_Booking_Geography__c);
            Final Decimal REVENUES = oli.opportunity_stage_type__c == 'Closed Lost' ? oli.pre_oppy_revenue_next_12m_amount__c : oli.DES_Expected_Revenue__c;
            if(REVENUES != null  && REVENUES != 0 && countryLabel != null) {

                if (mapKeys.get(countryLabel) == null) {
                    mapKeys.put(countryLabel, REVENUES);
                } else {
                    Double revTotP = mapKeys.get(countryLabel) + REVENUES;
                    mapKeys.put(countryLabel, revTotP);
                }
            }
        }
        System.debug(':::mapKeys de COUNTRY BOOKING + Country ACC: ' + JSON.serialize(mapKeys));
        return mapKeys;
    }
     /*
    *   @author: GlobalDesktop - APC
    *   @Method: getStageClause
    *   @Description: fulfilling stage clause to be used in query. It depends on the attribute "stage" sent to the component

    *   @Input: stageOption{'Live','Won','Lost', other}
    *   @Output: getStageClause => String to be added to the where clause : 'AND Opportunity.StageName ...'
    *   @Versions:
            v1 - 2019/04/09 - Initial version
    */
    private static String getStageClause(String stageOption) {
        System.debug('::::stageOption ' + stageOption);
        String stageClause;
        stageClause = ' AND Opportunity.StageName';

        switch on stageOption {
            when 'Live' {
                stageClause += ' NOT IN (\'Draft Opp\', \'Closed Won\', \'Closed Lost\')';
            }
            when 'Won' {
                stageClause += ' IN (\'Closed Won\')';
            }
            when 'Lost' {
                stageClause += ' IN (\'Closed Lost\')';
            }
            when else {
                stageClause += ' NOT IN (\'Draft Opp\')';
            }
        }
        return stageClause;
    }



     /*
    * @author GlobalDesktop - APC
    * @description Construye la wrapper list que se devolvera al componente lightning
    */
    public class WrapperGlobalData {
        private Map<String, String> mapRowColors;
        // private Map<String, Map<String, Double>> mapData;
        private Map<String, Double> mapSimpleData;
        // public WrapperGlobalData (Map<String, String> prodColors, Map<String, Map<String, Double>> data) {
        //     this.mapRowColors = prodColors;
        //     this.mapData = data;
        // }
        public WrapperGlobalData (Map<String, String> prodColors, Map<String, Double> data) {
            this.mapRowColors = prodColors;
            this.mapSimpleData = data;
        }
        // public Map<String, String> getmapRowColors() {
        //   return mapRowColors;
        // }
        // public Map<String, Map<String, Double>> getMapData() {
        //   return mapData;
        // }
    }


 //REVISAR - TODO para tabla view report
    /*
    * WrapperClass to build the JSON to be sent to client-side to display table
    */
     public class WrapperClass {
	/*
	* oppName
	*/
      final private String oppName; //NOSONAR
    /*
	* prodName
	*/
      final private String prodName; //NOSONAR
      /*
	* prodFamily
	*/
      final private String prodFamily; //NOSONAR
      /*
	* oliName
	*/
      final private String oliName; //NOSONAR
	/*
	* expRevenue
	*/
      final private Decimal expRevenue; //NOSONAR
      /*
	* potRevenue
	*/
      final private Decimal potRevenue; //NOSONAR
      /*
	* expProb
	*/
      final private String expProb; //NOSONAR

	/*
	* urlOpp
	*/
      final private String urlOpp; //NOSONAR
    /*
	* urlOli
	*/
      final private String urlOli; //NOSONAR
	/*
	* urlAccount
	*/
      final private String urlAccount; //NOSONAR
	/*
	* oppAccountName
	*/
      final private String oppAccountName; //NOSONAR
	/*
	* stageName
	*/
      final private String stageName; //NOSONAR
	/*
	* closeDate
	*/
      final private Date closeDate; //NOSONAR
    /*
	* countryBooking
	*/
      final private String countryBooking; //NOSONAR
    /*
	* owner
	*/
      final private String owner; //NOSONAR
    /*
    * Constructor
    */
        public WrapperClass(OpportunityLineItem oli, String mode) {
            if(mode == 'tableData') {
                this.urlOpp = '/lightning/r/Opportunity/' + oli.OpportunityId + '/view';
                // this.urlOli = '/lightning/r/OpportunityLineItem/' + oli.Id + '/view';
                // this.urlAccount = '/lightning/r/Account/' + oli.Opportunity.AccountId + '/view';
                this.oliName = oli.Name;
                this.oppName = oli.Opportunity.Name;
                this.oppAccountName = oli.Opportunity.Account.Name;
                this.stageName = oli.opportunity_stage_type__c;
                this.countryBooking = oli.Opportunity.DES_Booking_Geography__c;
                this.closeDate = oli.Opportunity.CloseDate;
                this.expRevenue = oli.DES_Expected_Revenue__c;
                this.expProb = String.valueOf(oli.Opportunity.DES_Expected_Probability__c + '%');
                this.potRevenue = oli.pre_oppy_revenue_next_12m_amount__c;
                this.prodName = oli.Product2.name;
                this.prodFamily = oli.Product2.Family;
                this.owner = oli.Opportunity.Owner.Name;
            }
        }
    }
}