/**
* @author Global Desktop
* @description Controlador del grafico de visitas
*/
public with sharing class VisitLast12MonthsQuartersCnt {


	/*SINGLETON PATTERN*/
    private static VisitLast12MonthsQuartersCnt instance;

    /**
	* @author Global Desktop
	* @description Singleton pattern
	*/
    public static VisitLast12MonthsQuartersCnt getInstance(){ //NOSONAR singleton
        if (instance == null) {
            instance = new VisitLast12MonthsQuartersCnt();
        }
        return instance;
    }

	/**
	* @author Global Desktop
	* @description Method auxiliar para calcular la fecha de hace un año
	*/
	private static date getOneYearAgo(Date dateParam, Date lastYear) {
        Date oneYearAgo = dateParam;
        if(lastYear.month() >= 1 && lastYear.month() <= 3) {
            oneYearAgo = Date.newInstance(lastYear.year(),4,1);
        } else if (lastYear.month() >= 4 && lastYear.month() <= 6) {
            oneYearAgo = Date.newInstance(lastYear.year(),7,1);
        } else if (lastYear.month() >= 7 && lastYear.month() <= 9) {
            oneYearAgo = Date.newInstance(lastYear.year(),10,1);
        } else {
            oneYearAgo = Date.newInstance(lastYear.year()+1,1,1);
        }
        return oneYearAgo.addDays(-366);

	}

	/**
	* @author Global Desktop
	* @description Method auxiliar para inicializar los mapas
	*/
    private static void inicializateMaps(Map<String, Integer> mapFirst, Map<String, Integer> mapSecond, Map<String, Integer> mapThird, Map<String, Integer> mapFourth, List<String> listFamVisit) {
		for(String fp : listFamVisit){
            system.debug('Valor de la familia fp: ' +fp);
            if(mapFirst.get(fp) == null) {
                mapFirst.put(fp,0);
            }
            if(mapSecond.get(fp) == null) {
                mapSecond.put(fp,0);
            }
            if(mapThird.get(fp) == null) {
                mapThird.put(fp,0);
            }
            if(mapFourth.get(fp) == null) {
                mapFourth.put(fp,0);
            }
        }
    }

	/*
    * @author Global Desktop
    * @description Recupera los datos de las visitas relacionadas ordenadas por tiempo
    */
    @auraEnabled
    public static String getData(String clientId){
    	Map<String, Map<String, Integer>> mapStage = new Map<String, Map<String, Integer>>();
        date dia = system.today();

        Date oneYearAgo;
        oneYearAgo = getOneYearAgo(oneYearAgo,dia);
        dia = system.today().addDays(-366);

        System.debug(dia);

        Integer FiscalYearStartMonth = [select FiscalYearStartMonth from Organization where id=:Userinfo.getOrganizationId()].FiscalYearStartMonth;
        Set<Id> setIdVisitsDenormClient = new Set<Id>();
        final list<DES_Denorm_AccountVisits__c> denVisitList = [SELECT DES_Client__c, DES_Visit_new__c, DES_Visit_new__r.Name, DES_Visit_new__r.dwp_kitv__visit_start_date__c,
                                                          DES_Visit_new__r.dwp_kitv__solution_name_path_desc__c
                                                         FROM DES_Denorm_AccountVisits__c
                                                         WHERE DES_Client__c = :clientId
                                                         AND DES_Visit_new__r.dwp_kitv__visit_start_date__c <= THIS_QUARTER	AND DES_Visit_new__r.dwp_kitv__visit_start_date__c > :oneYearAgo
                                                         ORDER BY DES_Visit_new__r.dwp_kitv__visit_start_date__c DESC];
        for(DES_Denorm_AccountVisits__c denVisit : denVisitList) {
        	if(!setIdVisitsDenormClient.contains(denVisit.DES_Visit_new__c)) {
            	setIdVisitsDenormClient.add(denVisit.DES_Visit_new__c);
          	}
        }

        final Map<String, Integer> mapFirst = new Map<String, Integer>();
        final Map<String, Integer> mapSecond = new Map<String, Integer>();
        final Map<String, Integer> mapThird = new Map<String, Integer>();
        final Map<String, Integer> mapFourth = new Map<String, Integer>();
        final List<String> listFamVisit = familyValuesIntoList();

        inicializateMaps(mapFirst,mapSecond,mapThird,mapFourth,listFamVisit);

		if(!denVisitList.isEmpty()) {
			mapStage = getValuesMap(mapStage,denVisitList,mapFirst,mapSecond,mapThird,mapFourth);
		}
        return JSON.serialize(mapStage);
    }

    /**
	* @author Global Desktop
	* @description Method auxiliar para completar los mapas
	*/
    private static Map<String, Map<String, Integer>> getValuesMap (Map<String, Map<String, Integer>> mapStage, list<DES_Denorm_AccountVisits__c> denVisitList, Map<String, Integer> mapFirst, Map<String, Integer> mapSecond, Map<String, Integer> mapThird, Map<String, Integer> mapFourth) {
    	map<String,Integer> QProduct = new map<String,Integer>();
            for(DES_Denorm_AccountVisits__c i : denVisitList) {
                if(i.DES_Visit_new__r.dwp_kitv__solution_name_path_desc__c != null) {
                	final Set<Integer> qn1 = new Set<Integer>{1,2,3};
                    System.debug('qn1: ' + qn1);
			        final Set<Integer> qn2 = new Set<Integer>{4,5,6};
                    System.debug('qn2: ' + qn2);
			        final Set<Integer> qn3 = new Set<Integer>{7,8,9};
                    System.debug('qn3: ' + qn3);
			        final Set<Integer> qn4 = new Set<Integer>{10,11,12};
                    System.debug('qn4: ' + qn4);
                	String columnDate = String.valueOf(i.DES_Visit_new__r.dwp_kitv__visit_start_date__c.year());
                    String numberQ;
                    if(qn1.contains(i.DES_Visit_new__r.dwp_kitv__visit_start_date__c.month())) {
                        columnDate += ' Q1';
                        numberQ = 'Q1';
                    } else if(qn2.contains(i.DES_Visit_new__r.dwp_kitv__visit_start_date__c.month())) {
                        columnDate += ' Q2';
                        numberQ = 'Q2';
                    } else if(qn3.contains(i.DES_Visit_new__r.dwp_kitv__visit_start_date__c.month())) {
                        columnDate += ' Q3';
                        numberQ = 'Q3';
                    } else if(qn4.contains(i.DES_Visit_new__r.dwp_kitv__visit_start_date__c.month())) {
                        columnDate += ' Q4';
                        numberQ = 'Q4';
                    }
                    system.debug(columnDate);

                    final List<String> listQs = getQs(denVisitList[0].DES_Visit_new__r.dwp_kitv__visit_start_date__c);
                    final List<String> listFamPart = i.DES_Visit_new__r.dwp_kitv__solution_name_path_desc__c.split(';');
                    system.debug(listFamPart);
                    if(numberQ == listQs[0]) {
                        for(String s : listFamPart) {
                        	mapFirst.put(s, mapFirst.get(s)+1);
                            system.debug('Valor del mapa mapFirst de visitas: ' +mapFirst);
                        	mapStage.put(columnDate, mapFirst);
                        }
                    } else if(numberQ == listQs[1]) {
						for(String s : listFamPart) {
                        	mapSecond.put(s, mapSecond.get(s)+1);
                        	mapStage.put(columnDate, mapSecond);
                    	}
                    } else if(numberQ == listQs[2]) {
						for(String s : listFamPart) {
                        	mapThird.put(s, mapThird.get(s)+1);
                        	mapStage.put(columnDate, mapThird);
                        }
                    } else if(numberQ == listQs[3]) {
						for(String s : listFamPart) {
                        	mapFourth.put(s, mapFourth.get(s)+1);
                        	mapStage.put(columnDate, mapFourth);
                        }
                    }

            	}

			}

    	return mapStage;
    }


    /*
    * @author Global Desktop
    * @description Ordena las visitas por Qs
    */
    private static List<String> getQs(DateTime dateTimeNow) {
        final List<String> pickValList = new List<String>();
        final Set<Integer> qn1 = new Set<Integer>{1,2,3};
        final Set<Integer> qn2 = new Set<Integer>{4,5,6};
        final Set<Integer> qn3 = new Set<Integer>{7,8,9};
        final Set<Integer> qn4 = new Set<Integer>{10,11,12};
        String firstColumnDate = String.valueOf(dateTimeNow.year());
        Integer firstColumn;
        if(qn1.contains(dateTimeNow.month())) {
            firstColumnDate += ' Q1';
            firstColumn = 1;
        } else if(qn2.contains(dateTimeNow.month())) {
            firstColumnDate += ' Q2';
            firstColumn = 2;
        } else if(qn3.contains(dateTimeNow.month())) {
            firstColumnDate += ' Q3';
            firstColumn = 3;
        } else if(qn4.contains(dateTimeNow.month())) {
            firstColumnDate += ' Q4';
            firstColumn = 4;
        }
        system.debug('Valor de qn1: ' +qn1);
        system.debug('Valor de qn2: ' +qn2);
        system.debug('Valor de qn3: ' +qn3);
        system.debug('Valor de qn4: ' +qn4);
        system.debug(firstColumnDate);

        for(Integer i = 0; i<4; i++) {
            if(firstColumn == 1) {
                pickValList.add('Q'+firstColumn);
                firstColumn = 4;
            } else {
            	pickValList.add('Q'+firstColumn);
                firstColumn = firstColumn -1;
            }
        }
        return pickValList;
    }

    /*
    * @author Global Desktop
    * @description Recupera los falores de las familias
    */
    public static List<String> familyValuesIntoList() {
        final List<String> pickValList= new List<String>();
        final Schema.DescribeFieldResult fieldResult = dwp_kitv__Visit__c.dwp_kitv__solution_name_path_desc__c.getDescribe();
        final List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        for( Schema.PicklistEntry pickListVal : ple) {
            pickValList.add(pickListVal.getLabel());
        }
        return pickValList;
    }

	/*
    * @author Global Desktop
    * @description Recupera los valores de las visitas relacionadas
    */
    @AuraEnabled
    public static String getOppProducts(String clientId) {
        date dia = system.today();
        
        Date oneYearAgo;
        oneYearAgo = getOneYearAgo(oneYearAgo,dia);
        dia = system.today().addDays(-366);

        System.debug(dia);

    	try {
	    	final list<DES_Denorm_AccountVisits__c> denVisitList = [SELECT DES_Client__c, DES_Client__r.Name, DES_Visit_new__c, DES_Visit_new__r.Name, DES_Visit_new__r.dwp_kitv__visit_start_date__c,
	                                                          DES_Visit_new__r.dwp_kitv__solution_name_path_desc__c, DES_Visit_new__r.dwp_kitv__country_name__c, DES_Visit_new__r.dwp_kitv__region_name__c,
	                                                          DES_Visit_new__r.dwp_kitv__account_id__c ,DES_Visit_new__r.dwp_kitv__account_id__r.Name
	                                                         FROM DES_Denorm_AccountVisits__c
	                                                         WHERE DES_Client__c = :clientId
	                                                         AND DES_Visit_new__r.dwp_kitv__visit_start_date__c <= THIS_QUARTER	AND DES_Visit_new__r.dwp_kitv__visit_start_date__c > :oneYearAgo
	                                                         ORDER BY DES_Visit_new__r.dwp_kitv__visit_start_date__c DESC];
	        final List<WrapperClass> listWrapper = new List<WrapperClass>();
	        for(DES_Denorm_AccountVisits__c i : denVisitList) {
	        	  listWrapper.add(new WrapperClass(i.DES_Visit_new__r.dwp_kitv__account_id__c, i.DES_Visit_new__r.dwp_kitv__account_id__r.Name, i.DES_Visit_new__c, i.DES_Visit_new__r.Name,
	    	  										i.DES_Visit_new__r.dwp_kitv__visit_start_date__c, i.DES_Visit_new__r.dwp_kitv__country_name__c, i.DES_Visit_new__r.dwp_kitv__region_name__c));
	        }
	        return JSON.serialize(listWrapper);
    	} catch (Exception exc) {
            throw new AuraHandledException(Label.DES_Error + exc);
        }
    }

    /*
    * @author Global Desktop
    * @description Lista wrapper
    */
    public class WrapperClass{
    	//Declaracion de variable
        private String accountId; //NOSONAR
        //Declaracion de variable
        private String accountName; //NOSONAR
        //Declaracion de variable
        private String visitId; //NOSONAR
        //Declaracion de variable
        private String visitName; //NOSONAR
        //Declaracion de variable
        private DateTime startDate; //NOSONAR
        //Declaracion de variable
        private String country; //NOSONAR
        //Declaracion de variable
        private String region; //NOSONAR

        /*
	    * @author Global Desktop
	    * @description Method que construye la lista wrapper
	    */
        public WrapperClass(String accIdParam, String accNameParam, String visIdParame, String visNameParam, DateTime startParam, String paisParam, String regParam) {
        	this.accountId = '/lightning/r/Account/' + accIdParam + '/view';
            this.accountName = accNameParam;
            this.visitId = '/lightning/r/dwp_kitv__Visit__c/' + visIdParame + '/view';
            this.visitName = visNameParam;
            this.startDate = startParam;
            this.country = paisParam;
            this.region = regParam;
        }
    }



}