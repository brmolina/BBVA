/**************************************************************************************
Name:            VisitsByRegionAndProductsYTDcnt
Description:     Apex controller of VisitsByRegionAndProductsYTD Lightning component

Version        Date            Author            Summary of changes
-----------------------------------------------------------------------------------------
0.1            14/11/2018      SunnyTrail         Initial Version
0.2            13/12/2018      VASS               New agrupation by countries dinamically
*****************************************************************************************/
public with sharing class VisitsByRegionAndProductsYTDcnt {

	/*Declarando variable instance*/
    private static VisitsByRegionAndProductsYTDcnt instance;
    /*Mapa que tiene como key el Departamento y como value el número de visitas asociado*/
    private static Map<String, Double> mapDepNum = new Map<String, Double>();
    /*Mapa que tiene como key el País y como value el mapa mapDepNum para el país*/
    private static Map<String, Map<String, Double>> mapCountry = new Map<String, Map<String, Double>>();
    /*Mapa que tiene como key el Departamento y como value el color*/
    private static Map<String, String> mapDepCol = new Map<String, String>();
    /*Declarando variable setDeps*/
    private static Set<String> setDeps = new Set<String>();

    /*SINGLETON PATTERN*/
    public static VisitsByRegionAndProductsYTDcnt getInstance() { //NOSONAR singleton creado
        if (instance == null) {
            instance = new VisitsByRegionAndProductsYTDcnt();
        }
        return instance;
    }


	/**
	* @author Global Desktop
	* @description Recupera las visitas relacionadas con el cliente
	*/
  	@auraEnabled
    public static String getData(String clientId) {
        try {

            final List<DES_Denorm_AccountVisits__c> denVisitList = [SELECT DES_Client__c, DES_Visit_new__c, DES_Visit_new__r.Name,
                                                                   DES_Visit_new__r.dwp_kitv__visit_start_date__c,
                                                                   DES_Visit_new__r.dwp_kitv__solution_name_path_desc__c,
                                                                   //DES_Visit_new__r.region_name__c,
                                                                   toLabel(DES_Visit_new__r.dwp_kitv__country_name__c)
                                                              FROM DES_Denorm_AccountVisits__c
                                                             WHERE DES_Client__c = :clientId
                                                               AND DES_Visit_new__r.dwp_kitv__visit_start_date__c = THIS_YEAR
                                                               AND DES_Visit_new__r.dwp_kitv__visit_start_date__c <= TODAY];
            System.debug(':::::denVisitList LIST: ' + denVisitList);

            if(!denVisitList.isEmpty()) {
             for (DES_Denorm_AccountVisits__c vis : denVisitList) {
                  if(vis.DES_Visit_new__r.dwp_kitv__solution_name_path_desc__c != null) {
                     List<String> listDepsParts;
                     listDepsParts = vis.DES_Visit_new__r.dwp_kitv__solution_name_path_desc__c.split(';');
                     for(String dep : listDepsParts) {
                        helperGetData(dep, vis);
                        }
                    }
                //setFams.add(opli.DES_Product_Family__c);
                }
            }//FIN !listOppProduct.isEmpty()
            getDepartmentColor(setDeps);
            System.debug('mapDepCol = '+JSON.serialize(mapDepCol));

            final WrapperGlobalData wrapperGlobal = new WrapperGlobalData(mapDepCol, mapCountry);

            System.debug('jsonGlobal = '+JSON.serialize(wrapperGlobal));

            return JSON.serialize(wrapperGlobal);
        } catch (Exception exc) {
            throw new AuraHandledException(Label.DES_Error + exc);
        }
    }
    /**
	* @author Global Desktop
	* @description Rhelper getData
	*/
    public static void helperGetData(String dep, DES_Denorm_AccountVisits__c vis) {
        if(vis.DES_Visit_new__r.dwp_kitv__country_name__c!= null) {
            if(mapCountry.get(vis.DES_Visit_new__r.dwp_kitv__country_name__c) == null) {
                mapDepNum = new Map<String, Double>();
                mapDepNum.put(dep, 1);
                mapCountry.put(vis.DES_Visit_new__r.dwp_kitv__country_name__c, mapDepNum);
            } else {
                if (mapCountry.get(vis.DES_Visit_new__r.dwp_kitv__country_name__c).get(dep) == null) {
                        mapDepNum = mapCountry.get(vis.DES_Visit_new__r.dwp_kitv__country_name__c);
                        mapDepNum.put(dep, 1);
                        mapCountry.put(vis.DES_Visit_new__r.dwp_kitv__country_name__c, mapDepNum);
                } else {
                        mapDepNum = mapCountry.get(vis.DES_Visit_new__r.dwp_kitv__country_name__c);
                        Double numTot;
                        numTot = mapCountry.get(vis.DES_Visit_new__r.dwp_kitv__country_name__c).get(dep) + 1;
                        mapDepNum.put(dep, numTot);
                        mapCountry.put(vis.DES_Visit_new__r.dwp_kitv__country_name__c, mapDepNum);
                }
            }
        }
        setDeps.add(dep);
    }

	/**
	* @author Global Desktop
	* @description Recupera los departamentos del metadato
	*/
    public static void getDepartmentColor(Set<String> setDepartmentData) {
        final List<Department__mdt> listDepColor = [select DeveloperName,  Color__c from Department__mdt where DeveloperName IN :setDepartmentData];

        if(!listDepColor.isEmpty()) {
           for(Department__mdt dep : listDepColor) {
               if(dep.DeveloperName != null && dep.Color__c != null
                && mapDepCol.get(dep.DeveloperName) == null) {
                    mapDepCol.put(dep.DeveloperName, dep.Color__c);
                }
           }
        }
    }//getDepartmentColor

	/**
	* @author Global Desktop
	* @description Clase wrapper para devolver los datos
	*/
    public class WrapperGlobalData {
        /**
        * @author Global Desktop
        * @description mapDepCols
        */
        private Map<String, String> mapDepCol;//NOSONAR . used in client side
        /**
        * @author Global Desktop
        * @description mapData
        */
        private Map<String, Map<String, Double>> mapData; //NOSONAR
        /**
		* @author Global Desktop
		* @description Construye la lista wrapper
		*/
        public WrapperGlobalData (Map<String, String> deps, Map<String, Map<String, Double>> data) {
            this.mapDepCol = deps;
            this.mapData = data;
        }
    }


	/**
	* @author Global Desktop
	* @description Recupera las visitas relacionadas con el cliente
	*/
 	@AuraEnabled
	public static String getRowsData(String clientId) {
		try {
	  		final list<DES_Denorm_AccountVisits__c> denVisitList = [SELECT DES_Client__c, DES_Client__r.Name, DES_Visit_new__c, DES_Visit_new__r.Name, DES_Visit_new__r.dwp_kitv__visit_start_date__c,
	                                                          DES_Visit_new__r.dwp_kitv__solution_name_path_desc__c, DES_Visit_new__r.dwp_kitv__country_name__c, DES_Visit_new__r.dwp_kitv__region_name__c,
	                                                          DES_Visit_new__r.dwp_kitv__account_id__c ,DES_Visit_new__r.dwp_kitv__account_id__r.Name
	                                                         FROM DES_Denorm_AccountVisits__c
	                                                         WHERE DES_Client__c = :clientId
	                                                         AND DES_Visit_new__r.dwp_kitv__visit_start_date__c = THIS_YEAR
	                                                         AND DES_Visit_new__r.dwp_kitv__visit_start_date__c <= TODAY
	                                                         ORDER BY DES_Visit_new__r.dwp_kitv__visit_start_date__c DESC];
	        final List<WrapperClass> listWrapper = new List<WrapperClass>();
	        for(DES_Denorm_AccountVisits__c i : denVisitList) {
	            listWrapper.add(new WrapperClass(i.DES_Visit_new__r.dwp_kitv__account_id__c, i.DES_Visit_new__r.dwp_kitv__account_id__r.Name, i.DES_Visit_new__c, i.DES_Visit_new__r.Name, i.DES_Visit_new__r.dwp_kitv__visit_start_date__c, i.DES_Visit_new__r.dwp_kitv__country_name__c, i.DES_Visit_new__r.dwp_kitv__region_name__c));
	        }
	        return JSON.serialize(listWrapper);
		} catch (Exception exc) {
            throw new AuraHandledException(Label.DES_Error + exc);
        }
    }

	/**
	* @author Global Desktop
	* @description Construye la lista wrapper que devuelve al componente lightning
	*/
    public class WrapperClass {
        /**
        * @author Global Desktop
        * @description accountId
        */
        private final String accountId;//NOSONAR . used in client side
        /**
        * @author Global Desktop
        * @description accountName
        */
        private final String accountName;//NOSONAR . used in client side
        /**
        * @author Global Desktop
        * @description visitId
        */
        private final String visitId;//NOSONAR . used in client side
        /**
        * @author Global Desktop
        * @description visitName
        */
        private final String visitName;//NOSONAR . used in client side
        /**
        * @author Global Desktop
        * @description startDate
        */
        private final DateTime startDate;//NOSONAR . used in client side
        /**
        * @author Global Desktop
        * @description country
        */
        private final String country;
        /**
        * @author Global Desktop
        * @description region
        */
        private final String region;//NOSONAR . used in client side

        /**
		* @author Global Desktop
		* @description Construye la lista wrapper
		*/
        public WrapperClass(String accId, String accName, String visitId, String visitName, DateTime startDate, String country, String region) {
            this.accountId = '/lightning/r/Account/' + accId + '/view';
            this.accountName = accName;
            this.visitId = '/lightning/r/dwp_kitv__Visit__c/' + visitId + '/view';
            this.visitName = visitName;
            this.startDate = startDate;
            this.country = country;
            this.region = region;
        }
    }
}