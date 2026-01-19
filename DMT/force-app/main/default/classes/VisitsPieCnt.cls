/*
*   @author: GlobalDesktop
*   @Method: VisitsPieCnt
*   @Description: Class used to print Pie Charts related to Visits filtered by an Account and grouped by several options

*   @Versions:
        v1 - 2019/05/10 - Initial version
*/
public with sharing class VisitsPieCnt {

	/*
    * Labels used by chart
    */
    private final static Set<String> SETCOLUMNS = new Set<String>();
	/*
	* Others variable
	*/
	private final static String OTHERS = 'Others';
	/*
	* Others max
	*/
	private final static Integer MAX = 7;
	/**
    * SINGLETON PATTERN
    */
    private static VisitsPieCnt instance;

    /**
    * Constructor
    */
    private VisitsPieCnt() {
    }

    /**
    * getInstance
    */
    public static VisitsPieCnt gtInstance() {
        if (instance == null) {
            instance = new VisitsPieCnt();
        }
        return instance;
    }
	/**
	* @author Global Desktop
	* @description Se recuperan las visitas relacionadas con el cliente
	*/
 	@AuraEnabled
    public static String getData(String clientId, Boolean byProduct, Boolean byCountryBooking) {
        try {
			system.debug('Llamada a la funcion getData');
            // Set<Id> setIdVisDenormClient = new Set<Id>();
            final List<DES_Denorm_AccountVisits__c> denVisit = [SELECT DES_Visit_new__c, DES_Visit_new__r.dwp_kitv__country_name__c,
    															 DES_Visit_new__r.dwp_kitv__solution_name_path_desc__c
                                                            FROM DES_Denorm_AccountVisits__c
                                                            WHERE DES_Client__c = : clientId];

            // for(DES_Denorm_AccountVisits__c iDenVisit : denVisit) {
            //     setIdVisDenormClient.add(iDenVisit.DES_Visit_new__c);
            // }

            /* Mapa que con datos a devolver key = columna a filtrar (countryBooking || productLv2) y values los valores acumulados */
            final Map<String, Integer> mapData = new Map<String, Integer>();
            /* Mapa que tiene como key el prod y como value el color */
            Map<String, String> mapColors = new Map<String, String>();

            if(!denVisit.isEmpty()) {
				for(DES_Denorm_AccountVisits__c dVis : denVisit) {
					if(byProduct) {
						getDataProduct(dVis, mapData);
					} else {
						getDataCountry(dVis, mapData);
					}
				}
            }

			final Map<String, Integer> groupedMap = groupData(mapData);
			mapColors = UtilsFichaGrupo.getCountryColor(groupedMap.keySet());
            final WrapperGlobalData wrapperGlobal = new WrapperGlobalData(mapColors, groupedMap);
            return JSON.serialize(wrapperGlobal);
        } catch (Exception exc) {
            throw new AuraHandledException(Label.DES_Error + exc);
        }
    }
	/*
	* @author Global Desktop - DRL
	* @description Aux method to reduce complexity of the getData method
	*/
	private static Map<String, Integer> getDataProduct(DES_Denorm_AccountVisits__c dVis, Map<String, Integer> mapDatos) {
		final Map<String, Integer> mapData = mapDatos;
		if(dVis.DES_Visit_new__r.dwp_kitv__solution_name_path_desc__c != null && dVis.DES_Visit_new__r.dwp_kitv__solution_name_path_desc__c.contains(';')) {
			for(String sSplit : dVis.DES_Visit_new__r.dwp_kitv__solution_name_path_desc__c.split(';')) {
				if(mapData.get(sSplit) == null) {
					mapData.put(sSplit,1);
					SETCOLUMNS.add(sSplit);
				} else {
					mapData.put(sSplit,mapData.get(sSplit)+1);
				}
			}
		} else if (dVis.DES_Visit_new__r.dwp_kitv__solution_name_path_desc__c != null) {
				if(mapData.get(dVis.DES_Visit_new__r.dwp_kitv__solution_name_path_desc__c) == null) {
					mapData.put(dVis.DES_Visit_new__r.dwp_kitv__solution_name_path_desc__c,1);
					SETCOLUMNS.add(dVis.DES_Visit_new__r.dwp_kitv__solution_name_path_desc__c);
				} else {
					mapData.put(dVis.DES_Visit_new__r.dwp_kitv__solution_name_path_desc__c,mapData.get(dVis.DES_Visit_new__r.dwp_kitv__solution_name_path_desc__c)+1);
				}
		}
		return mapData;
	}

	/*
	* @author Global Desktop - DRL
	* @description Aux method to reduce complexity of the getData method
	*/
	private static Map<String, Integer> getDataCountry(DES_Denorm_AccountVisits__c dVis, Map<String, Integer> mapDatos) {
		final Map<String, Integer> mapData = mapDatos;
		final Map<String,String> mapCountries = GroupGeographyCnt.helperCreateMapCountryCodes('DEVNAME');
		final String countryLabel = mapCountries.get(dVis.DES_Visit_new__r.dwp_kitv__country_name__c);
		if(countryLabel != null) {
			SETCOLUMNS.add(countryLabel);
			if(mapData.get(countryLabel) == null) {
				mapData.put(countryLabel,1);
			} else {
				mapData.put(countryLabel,mapData.get(countryLabel)+1);
			}
		}
		return mapData;
	}

	/*
	* @author Global Desktop - DRL
	* @description Aux method group an order map. Top 7
	*/
	private static Map<String, Integer> groupData(Map<String, Integer> mapData) {
		final Map<String,Double> doubleMap = new Map<String, Double>();
		for(String aux : mapData.keySet()) {
			doubleMap.put(aux, mapData.get(aux) + 0.00);
		}

		final Map<String, Integer> groupedMap = new Map<String,Integer>();
		final Map<String, Double> orderMap = UtilsFichaGrupo.orderMap(doubleMap);
		Integer auxNumber = 0;
		for(String aux : orderMap.keySet()) {
			if(auxNumber < MAX) {
				groupedMap.put(aux, Integer.valueOf(orderMap.get(aux)));
			} else {
				if(groupedMap.get(OTHERS) == null) {
					groupedMap.put(OTHERS, Integer.valueOf(orderMap.get(aux)));
				} else {
					groupedMap.put(OTHERS, Integer.valueOf(groupedMap.get(OTHERS) + orderMap.get(aux)));
				}
			}
			auxNumber++;
			system.debug('++ auxNumber -> ' + auxNumber);
		}
		return groupedMap;
	}

    /**
	* @author Global Desktop
	* @description Clase Wrapper que construye los mapas que se envian al componente lightning como JSON
	*/
    public class WrapperGlobalData {
		/*
		* mapRowColors
		*/
        private final Map<String, String> mapRowColors; //NOSONAR
		/*
		* mapSimpleData
		*/
        private final Map<String, Integer> mapSimpleData; //NOSONAR
		/*
		* Public constructor
		*/
        public WrapperGlobalData (Map<String, String> prodColors, Map<String, Integer> data) {
            this.mapRowColors = prodColors;
            this.mapSimpleData = data;
        }

    }

    /**
	* @author Global Desktop
	* @description Se recuperan los datos para dibujar la lista relacionada del grafico
	*/
    @AuraEnabled
    public static String getRowsData(String clientId) {
        try {

			final Schema.DescribeFieldResult fieldResult = dwp_kitv__Visit__c.dwp_kitv__country_name__c.getDescribe();
			final List<Schema.PicklistEntry> values = fieldResult.getPicklistValues();
			final Map<String,String> mapValueLabel = new Map<String,String>();
			for( Schema.PicklistEntry v : values) {
			    mapValueLabel.put(v.getValue(),v.getLabel());
			}

            final List<DES_Denorm_AccountVisits__c> denVis = [SELECT DES_Visit_new__c, DES_Visit_new__r.dwp_kitv__country_name__c,
															 DES_Visit_new__r.dwp_kitv__solution_name_path_desc__c,
        												 	 DES_Visit_new__r.Name, DES_Visit_new__r.DES_AccountName__c,
        												 	 DES_Visit_new__r.dwp_kitv__visit_start_date__c,
        												 	 DES_Visit_new__r.Owner.Name
                                                    	FROM DES_Denorm_AccountVisits__c
                                                        WHERE DES_Client__c = : clientId];

            final List<WrapperClass> listWrapper = new List<WrapperClass>();

            for(DES_Denorm_AccountVisits__c vis : denVis) {

            	String labelCountry;
    			labelCountry = mapValueLabel.get(vis.DES_Visit_new__r.dwp_kitv__country_name__c);

                listWrapper.add(new WrapperClass(vis, labelCountry));
            }
            return JSON.serialize(listWrapper);
        } catch (Exception exc) {
            throw new AuraHandledException(Label.DES_Error + exc);
        }
    }

    /**
	* @author Global Desktop
	* @description Construye la lista wrapper con las columnas a imprimir en la lista relacionada
	*/
    public class WrapperClass {
		/*
		* visName
		*/
	    final private String visName; //NOSONAR
	    /*
		* accName
		*/
	    final private String accName; //NOSONAR
	    /*
		* startDate
		*/
	    final private DateTime startDate; //NOSONAR
	    /*
		* ownerName
		*/
	    final private String ownerName; //NOSONAR
	    /*
		* areas
		*/
	    final private String areas; //NOSONAR
	    /*
		* country
		*/
	    final private String country; //NOSONAR
		/*
		* Constructor de la clase wrapper
		*/
        public WrapperClass(DES_Denorm_AccountVisits__c vis, String labelCountry) {
        	this.visName = vis.DES_Visit_new__r.Name;
        	this.accName = vis.DES_Visit_new__r.DES_AccountName__c;
        	this.startDate = vis.DES_Visit_new__r.dwp_kitv__visit_start_date__c;
        	this.ownerName = vis.DES_Visit_new__r.Owner.Name;
        	this.areas = vis.DES_Visit_new__r.dwp_kitv__solution_name_path_desc__c;
        	this.country = labelCountry;
        }
    }



}