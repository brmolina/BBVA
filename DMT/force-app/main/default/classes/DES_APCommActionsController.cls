/**********************************************************************************
* @author       Accenture
* @date         01/10/2019
* @description  Clase que calcula los datos del componente DES_APRevenuesEvolutionChart
* @Revision
**********************************************************************************/
public with sharing class DES_APCommActionsController {
 
    
    /*Mapa que contiene como key la familia y como value el color*/
    private static Map<String, String> familyColorMap = new Map<String, String>();
    /*Set que contiene la lista de familias de booking*/
    private static Set<String> bookingFamilySet = new Set<String>();
    /*Mapa que contiene year-family-revenues*/
    private static Map<String, Map<String, Double>> yearMap = new Map<String, Map<String, Double>>();
    
    /*
    * @author Global Desktop
    * @description Recupera el id del cliente del AP
    */
    @AuraEnabled
    public static String getClientId(String gaId) {
        return [SELECT participant_id__c FROM DES_Group_Analysis__c WHERE Id = :gaId].participant_id__c;
    }
    
    
    /*
    * @author Global Desktop
    * @description Recupera las oportunidades denormalizadas relacionadas con la cuenta
    */
    @AuraEnabled
    public static String getData(String gaId, String chartFilter) {
        system.debug('>>>>> FUNCION getData. ID Account Plan : ' + gaId);
        
        final String clientId = getClientId(gaId);
        final List<DES_Denorm_AccountVisits__c> visitList = getVisitList(clientId);
        String wrapperString;
        
        if(chartFilter == Label.DES_Status) {
            wrapperString = buildDataByStatus(visitList);
        } else {
          	wrapperString = buildDataByType(visitList);  
        }
        System.debug('wrapperString: ' + wrapperString);
        return wrapperString;
    }
    
    /*
    * @author Global Desktop
    * @description Datos para el gráfico por estado
    */
    public static String buildDataByStatus(List<DES_Denorm_AccountVisits__c> visitList) {
        
        final Map<Integer, String> monthsMap = getMonths();
        System.debug('visitList buildDataByStatus: ' + visitList);
        
        //Creo el mapa(estado, número de visitas)
        for(DES_Denorm_AccountVisits__c visitAux : visitList) {
            System.debug('visitAux: ' + visitAux);
            //si no tengo mes, tampoco tengo estado
            if(yearMap.get(monthsMap.get(visitAux.DES_Visit_new__r.dwp_kitv__visit_start_date__c.month())) == null) {
                System.debug('yearMap - si no tengo mes, tampoco tengo estado antes: ' + yearMap);
                Map<String, Double> stageNumMapAux;
                stageNumMapAux = new Map<String, Double>(); 
                stageNumMapAux.put(visitAux.DES_Visit_new__r.dwp_kitv__visit_status_type__c, 1);    
                yearMap.put(monthsMap.get(visitAux.DES_Visit_new__r.dwp_kitv__visit_start_date__c.month()), stageNumMapAux);
                System.debug('stageNumMapAux - si no tengo mes, tampoco tengo estado después: ' + stageNumMapAux);
                System.debug('yearMap - si no tengo mes, tampoco tengo estado después: ' + yearMap);
                
                if(!bookingFamilySet.contains(visitAux.DES_Visit_new__r.dwp_kitv__visit_status_type__c)) {
                	bookingFamilySet.add(visitAux.DES_Visit_new__r.dwp_kitv__visit_status_type__c);
                }
            } else {
                //si tengo mes
                //si no tengo estado
                if(yearMap.get(monthsMap.get(visitAux.DES_Visit_new__r.dwp_kitv__visit_start_date__c.month())).get(visitAux.DES_Visit_new__r.dwp_kitv__visit_status_type__c) == null) {
                    System.debug('yearMap - si tengo mes, si no tengo estado antes: ' + yearMap);
                    Map<String, Double> stageNumMapAux2;
                    stageNumMapAux2 = new Map<String, Double>(); 
                	stageNumMapAux2.putAll(yearMap.get(monthsMap.get(visitAux.DES_Visit_new__r.dwp_kitv__visit_start_date__c.month())));                        
                    stageNumMapAux2.put(visitAux.DES_Visit_new__r.dwp_kitv__visit_status_type__c, 1);    
                	yearMap.put(monthsMap.get(visitAux.DES_Visit_new__r.dwp_kitv__visit_start_date__c.month()), stageNumMapAux2);
                    System.debug('stageNumMapAux2 - si tengo mes, si no tengo estado después: ' + stageNumMapAux2);
                    System.debug('yearMap - si tengo mes, si no tengo estado después: ' + yearMap);
                    
                    if(!bookingFamilySet.contains(visitAux.DES_Visit_new__r.dwp_kitv__visit_status_type__c)) {
                        bookingFamilySet.add(visitAux.DES_Visit_new__r.dwp_kitv__visit_status_type__c);
                    }
                } else {
                    //si tengo estado
                    System.debug('yearMap - si tengo mes, si tengo estado antes: ' + yearMap);
                    Map<String, Double> stageNumMapAux3;
                    stageNumMapAux3 = new Map<String, Double>();
					stageNumMapAux3 = yearMap.get(monthsMap.get(visitAux.DES_Visit_new__r.dwp_kitv__visit_start_date__c.month()));
                   	stageNumMapAux3.put(visitAux.DES_Visit_new__r.dwp_kitv__visit_status_type__c ,
                    yearMap.get(monthsMap.get(visitAux.DES_Visit_new__r.dwp_kitv__visit_start_date__c.month())).get(visitAux.DES_Visit_new__r.dwp_kitv__visit_status_type__c) + 1);
                    
                    yearMap.put(monthsMap.get(visitAux.DES_Visit_new__r.dwp_kitv__visit_start_date__c.month()), stageNumMapAux3);
                    System.debug('stageNumMapAux3 - si tengo mes, si tengo estado después: ' + stageNumMapAux3);
                    System.debug('yearMap - si tengo mese, si tengo estado después: ' + yearMap);
                }
            }
        }
        System.debug('yearMap final: ' + yearMap);
        System.debug('bookingFamilySet: ' + bookingFamilySet);
		
        familyColorMap = UtilsFichaGrupo.getCountryColor(bookingFamilySet);
        System.debug('familyColorMap = '+JSON.serialize(familyColorMap));
        
        final WrapperGlobalData wrapperGlobal = new WrapperGlobalData(familyColorMap, yearMap);

        System.debug('jsonGlobal = '+JSON.serialize(wrapperGlobal));
        
        return JSON.serialize(wrapperGlobal);
    }
    
    /*
    * @author Global Desktop
    * @description Datos para el gráfico por tipo
    */
    public static String buildDataByType(List<DES_Denorm_AccountVisits__c> visitList) {
        
        final Map<Integer, String> monthsMap = getMonths();
        System.debug('visitList buildDataByType: ' + visitList);
        
        //Creo el mapa(estado, número de visitas)
        for(DES_Denorm_AccountVisits__c visitAux : visitList) {
            System.debug('visitAux: ' + visitAux);
            //si no tengo mes, tampoco tengo tipo
            if(yearMap.get(monthsMap.get(visitAux.DES_Visit_new__r.dwp_kitv__visit_start_date__c.month())) == null) {
                System.debug('yearMap - si no tengo mes, tampoco tengo tipo antes: ' + yearMap);
                Map<String, Double> stageNumMapAux;
                stageNumMapAux = new Map<String, Double>(); 
                stageNumMapAux.put(visitAux.DES_Visit_new__r.dwp_kitv__visit_channel__c, 1);    
                yearMap.put(monthsMap.get(visitAux.DES_Visit_new__r.dwp_kitv__visit_start_date__c.month()), stageNumMapAux);
                System.debug('stageNumMapAux - si no tengo mes, tampoco tengo tipo después: ' + stageNumMapAux);
                System.debug('yearMap - si no tengo mes, tampoco tengo tipo después: ' + yearMap);
                
                if(!bookingFamilySet.contains(visitAux.DES_Visit_new__r.dwp_kitv__visit_channel__c)) {
                	bookingFamilySet.add(visitAux.DES_Visit_new__r.dwp_kitv__visit_channel__c);
                }
            } else {
                //si tengo mes
                //si no tengo tipo
                if(yearMap.get(monthsMap.get(visitAux.DES_Visit_new__r.dwp_kitv__visit_start_date__c.month())).get(visitAux.DES_Visit_new__r.dwp_kitv__visit_channel__c) == null) {
                    System.debug('yearMap - si tengo mes, si no tengo tipo antes: ' + yearMap);
                    Map<String, Double> stageNumMapAux2;
                    stageNumMapAux2 = new Map<String, Double>(); 
                	stageNumMapAux2.putAll(yearMap.get(monthsMap.get(visitAux.DES_Visit_new__r.dwp_kitv__visit_start_date__c.month())));                        
                    stageNumMapAux2.put(visitAux.DES_Visit_new__r.dwp_kitv__visit_channel__c, 1);    
                	yearMap.put(monthsMap.get(visitAux.DES_Visit_new__r.dwp_kitv__visit_start_date__c.month()), stageNumMapAux2);
                    System.debug('stageNumMapAux2 - si tengo mes, si no tengo tipo después: ' + stageNumMapAux2);
                    System.debug('yearMap - si tengo mes, si no tengo tipo después: ' + yearMap);
                    
                    if(!bookingFamilySet.contains(visitAux.DES_Visit_new__r.dwp_kitv__visit_channel__c)) {
                        bookingFamilySet.add(visitAux.DES_Visit_new__r.dwp_kitv__visit_channel__c);
                    }
                } else {
                    //si tengo estado
                    System.debug('yearMap - si tengo mes, si tengo tipo antes: ' + yearMap);
                    Map<String, Double> stageNumMapAux3;
                    stageNumMapAux3 = new Map<String, Double>();
					stageNumMapAux3 = yearMap.get(monthsMap.get(visitAux.DES_Visit_new__r.dwp_kitv__visit_start_date__c.month()));
                   	stageNumMapAux3.put(visitAux.DES_Visit_new__r.dwp_kitv__visit_channel__c ,
                    yearMap.get(monthsMap.get(visitAux.DES_Visit_new__r.dwp_kitv__visit_start_date__c.month())).get(visitAux.DES_Visit_new__r.dwp_kitv__visit_channel__c) + 1);
                    yearMap.put(monthsMap.get(visitAux.DES_Visit_new__r.dwp_kitv__visit_start_date__c.month()), stageNumMapAux3);
                    System.debug('stageNumMapAux3 - si tengo mes, si tengo tipo después: ' + stageNumMapAux3);
                    System.debug('yearMap - si tengo mese, si tengo tipo después: ' + yearMap);
                }
            }
        }
        System.debug('yearMap final: ' + yearMap);
        System.debug('bookingFamilySet: ' + bookingFamilySet);
		
        familyColorMap = UtilsFichaGrupo.getCountryColor(bookingFamilySet);
        System.debug('familyColorMap = '+JSON.serialize(familyColorMap));
        
        final WrapperGlobalData wrapperGlobal = new WrapperGlobalData(familyColorMap, yearMap);

        System.debug('jsonGlobal = '+JSON.serialize(wrapperGlobal));
        
        return JSON.serialize(wrapperGlobal);
    }

    /*
    * @author Global Desktop
    * @description Recupera la lista de visitas
    */
    public static List<DES_Denorm_AccountVisits__c> getVisitList(String clientId) {
        final Date todayDate = date.today();
        final date nextYearDate = date.newInstance(todayDate.year()+1, todayDate.month(), 1);        
        System.debug('nextYearDate: ' + nextYearDate);
        return [SELECT Id, DES_Visit_new__r.dwp_kitv__visit_start_date__c, toLabel(DES_Visit_new__r.dwp_kitv__visit_status_type__c), toLabel(DES_Visit_new__r.dwp_kitv__visit_channel__c)
                FROM DES_Denorm_AccountVisits__c 
                WHERE DES_Client__c = :clientId AND DES_Visit_new__r.dwp_kitv__visit_start_date__c >= :todayDate AND DES_Visit_new__r.dwp_kitv__visit_start_date__c < :nextYearDate
               ORDER BY DES_Visit_new__r.dwp_kitv__visit_start_date__c DESC];
    }
    
    /*
    * @author Global Desktop
    * @description Recupera la lista de meses
    */
    public static Map<Integer, String> getMonths() {
        final List<DES_Months__mdt> monthsList = [SELECT DeveloperName , DES_Month_number__c FROM DES_Months__mdt ORDER BY DES_Month_number__c LIMIT 12];
        Map<Integer, String> monthsMap;
        monthsMap = new Map<Integer, String>();
        for(DES_Months__mdt monthAux : monthsList) {
            monthsMap.put(integer.valueOf(monthAux.DES_Month_number__c), monthAux.DeveloperName );
        }
        return monthsMap;
    }  
    
    /**
	* @author Global Desktop
	* @description Clase wrapper para devolver los datos
	*/
    public class WrapperGlobalData {
        /**
        * @author Global Desktop
        * @description mapDepCols
        */
        private Map<String, String> familyColorMap;//NOSONAR . used in client side
        /**
        * @author Global Desktop
        * @description mapData
        */
        private Map<String, Map<String, Double>> yearMap; //NOSONAR
        /**
		* @author Global Desktop
		* @description Construye la lista wrapper
		*/
        public WrapperGlobalData (Map<String, String> familyColorMap, Map<String, Map<String, Double>> yearMap) {
            this.familyColorMap = familyColorMap;
            this.yearMap = yearMap;
        }
    }
    

    /*
    * @author Global Desktop
    * @description Recupera los datos de la tabla
    */
    @AuraEnabled
    public static String getTableData(String gaId) {
        final String clientId = getClientId(gaId);
        final List<DES_Denorm_AccountVisits__c> visitList = getVisitListTable(clientId);
        
        List<WrapperClass> listWrapper;
        listWrapper = new List<WrapperClass>();
        for(DES_Denorm_AccountVisits__c visitAux : visitList) {
			listWrapper.add(
                          	new WrapperClass(visitAux.DES_Visit_new__r.dwp_kitv__account_id__c, visitAux.DES_Visit_new__r.dwp_kitv__account_id__r.Name, visitAux.DES_Visit_new__c, visitAux.DES_Visit_new__r.Name,
                                             visitAux.DES_Visit_new__r.dwp_kitv__visit_channel__c,
                                             date.newinstance(visitAux.DES_Visit_new__r.dwp_kitv__visit_start_date__c.year(), visitAux.DES_Visit_new__r.dwp_kitv__visit_start_date__c.month(), visitAux.DES_Visit_new__r.dwp_kitv__visit_start_date__c.day())
                                             ));
        }
        
        
        system.debug('>>>>>listWrapper : ' + listWrapper);
        return JSON.serialize(listWrapper); 
        
    }
    
    /*
    * @author Global Desktop
    * @description Recupera la lista de visitas para la tabla
    */
    public static List<DES_Denorm_AccountVisits__c> getVisitListTable(String clientId) {
        final Date todayDate = date.today();
        final date nextYearDate = date.newInstance(todayDate.year()+1, todayDate.month(), 1);        
        System.debug('nextYearDate: ' + nextYearDate);
        return [SELECT DES_Visit_new__r.dwp_kitv__account_id__c, DES_Visit_new__r.dwp_kitv__account_id__r.Name, 
                DES_Visit_new__c, DES_Visit_new__r.Name, DES_Visit_new__r.dwp_kitv__visit_start_date__c, toLabel(DES_Visit_new__r.dwp_kitv__visit_status_type__c),
                toLabel(DES_Visit_new__r.dwp_kitv__visit_channel__c)
                FROM DES_Denorm_AccountVisits__c 
                WHERE DES_Client__c = :clientId AND DES_Visit_new__r.dwp_kitv__visit_start_date__c >= :todayDate AND DES_Visit_new__r.dwp_kitv__visit_start_date__c < :nextYearDate
               ORDER BY DES_Visit_new__r.dwp_kitv__account_id__c, DES_Visit_new__r.dwp_kitv__visit_start_date__c];
    }

    
    /*
    * @author Global Desktop
    * @description construye la lista wrapper que devuelve la informacion al componente lightning
    */
    public class WrapperClass {
        /**
    * @author Global Desktop
    * @description Variables de la lista wrapper
    */
        private String clientUrl; //NOSONAR
        /*
        * wrapper field
        */
        private String clientName; //NOSONAR
        /*
        * wrapper field
        */
        private String visitUrl; //NOSONAR
        /*
        * wrapper field
        */
        private String visitName; //NOSONAR
        /*
        * wrapper field
        */
        private String visitType; //NOSONAR
        /*
        * wrapper field
        */
        private Date startDate; //NOSONAR
        
        /**
        * @author Global Desktop
        * @description Construye la clase wrapper
        */
        public WrapperClass(Id clientId, String clientName, Id visitId, String visitName, String visitType, Date startDate) {
            this.clientUrl = '/lightning/r/Account/' + clientId + '/view';
            this.clientName = clientName;
            this.visitUrl = '/lightning/r/dwp_kitv__Visit__c/' + visitId + '/view';
            this.visitName = visitName;
            this.visitType = visitType;
            this.startDate = startDate;
        }
    }
}