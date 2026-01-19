/**
 * Author   :   Global Desktop
 * Desc     :   DES_AP_ReportController, controller
 * */
public with sharing class DES_AP_ReportController {
    /* Declarando variable */
    public static final String ZERONUM = '0';
    /**
    * return revenue by Country
    **/
    @AuraEnabled
    public static String revenueCountry(String recordId) {
        final String groupId = getGroupId(recordId);
        final WrapperGlobalData objDataGlobal   = new WrapperGlobalData();
        final String apId = getApId(recordId);
        final string launchPeriod = getLaunchPeriod(recordId);
        final List<String> lstCountry     = new List<String>();
        final Map<String,WrapperData> mapDatos = new Map<String,WrapperData>();
      	List<DES_Booking__c>  lstBoocking       =  DES_AP_ReportController_Utils.queryBookingCountry(true,groupId);//NOSONAR
        final List <AggregateResult> bpitemList = DES_AP_ReportController_Utils.queryBusinessPlanCountry(groupId, apId, launchPeriod); 
        system.debug(bpitemList);
        if(!bpitemList.isEmpty()) {
            //carga en las revenues por pais del account planing
            for (AggregateResult bpitemAux : bpitemList) {
                final String  country = String.ValueOf(bpitemAux.get('country'));
                final Decimal revenue = Decimal.ValueOf(String.ValueOf(bpitemAux.get('expected')));
                
                lstCountry.add(country);
                
                WrapperData wdata;
                wdata=new WrapperData();
                wdata.country=country;
                wdata.revenue=revenue;
				wdata.current=0;
                
                mapDatos.put(country.toLowerCase(),wdata);

            } 
			
			system.debug('mapDatos==='+mapDatos);
            //carga las account planing por booking
             if (lstBoocking.isEmpty()) {//NOSONAR
 		        lstBoocking       = DES_AP_ReportController_Utils.queryBookingCountry(false,groupId);
             }
            for(Integer i=0;i<lstBoocking.size();i++) {
				system.debug('PAR1==='+lstBoocking[i].DES_Country__c);
				system.debug('PAR2==='+lstBoocking[i].DES_Current_Year_Revenues__c);
				system.debug('PAR3==='+mapDatos.get(lstBoocking[i].DES_Country__c));
				final String countrykey=DES_AP_ReportController.mappingCountry(lstBoocking[i].DES_Country__c);
                if(mapDatos.get(countrykey)!=null) {
                    mapDatos.get(countrykey).current+=lstBoocking[i].DES_Current_Year_Revenues__c;
                }

                
            }   
			
			
		    for (String key : mapDatos.keySet()) {
                  system.debug('mapKEY====='+key);
				  system.debug('mapDATA====='+mapDatos.get(key));
  			      objDataGlobal.lstcurrent.add(mapDatos.get(key).current);
			      objDataGlobal.lstrevenue.add(mapDatos.get(key).revenue);
                  objDataGlobal.lstCountry.add(mapDatos.get(key).country);
				
			}
            /*for (Integer i=0;i<20;i++){
                  objDataGlobal.lstcurrent.add(5000);
			      objDataGlobal.lstrevenue.add(300);
                  objDataGlobal.lstCountry.add('españa'+i);
				
			}*/
        
        }
      
        return JSON.serialize(objDataGlobal);
    }
    
	/**
    * retorna la informacion de revenues por producto
    **/
    @AuraEnabled
    public static String revenueProduct(String recordId) {
        final String groupId = getGroupId(recordId);
        final String apId = getApId(recordId);
        final string launchPeriod = getLaunchPeriod(recordId);
        final WrapperGlobalData objDataGlobal   = new WrapperGlobalData();
        final Map<String,WrapperData> mapDatos = new Map<String,WrapperData>();
        final List <AggregateResult> bpitemList = DES_AP_ReportController_Utils.queryBusinessPlanProduct(groupId, apId, launchPeriod);
         
        if(!bpitemList.isEmpty()) {
            //carga en las revenues por pais del account planing
            for (AggregateResult bpitemAux : bpitemList) {
                final String product = String.ValueOf(bpitemAux.get('product'));
                final Decimal revenue = Decimal.ValueOf(String.ValueOf(bpitemAux.get('expected')));
                WrapperData wdata;
                wdata=new WrapperData();
                wdata.product=product;
                wdata.revenue=revenue;
				wdata.current=0;
                mapDatos.put(product,wdata);

            }

			system.debug('mapDatos==='+mapDatos);
            //carga las account planing por booking
 		    List<DES_Booking__c>  lstBoocking   = DES_AP_ReportController_Utils.queryBookingProductfalse(groupId);//NOSONAR
            for(Integer i=0;i<lstBoocking.size();i++) {
                
				system.debug('PAR1==='+lstBoocking[i].DES_Type__c);
				system.debug('PAR2==='+lstBoocking[i].DES_Current_Year_Revenues__c);
				//system.debug('PAR3==='+mapDatos.get(key));
                String key; 
                key=lstBoocking[i].DES_Type__c;
                if(!mapDatos.containsKey(key)&&mapDatos.containsKey('Others')) {
                      key='Others';
                      mapDatos.get(key).current+=lstBoocking[i].DES_Current_Year_Revenues__c;
                }else if(mapDatos.containsKey(key)) {
                    mapDatos.get(lstBoocking[i].DES_Type__c).current+=lstBoocking[i].DES_Current_Year_Revenues__c;
                }
                
                
            }   
			
			
		    for (String key : mapDatos.keySet()) {
                  system.debug('mapKEY====='+key);
                  if(!mapDatos.containsKey(key)) {
                      key='Others';
                  }
				  system.debug('mapDATA====='+mapDatos.get(key));
  			      objDataGlobal.lstcurrent.add(mapDatos.get(key).current);
			      objDataGlobal.lstrevenue.add(mapDatos.get(key).revenue);
                  objDataGlobal.lstProduct.add(mapDatos.get(key).product);
				
			}
            
        
        }
      
        return JSON.serialize(objDataGlobal);
    }
    
    /**
    * gets the group id
    **/
    public static String mappingCountry(String countryBooking) {
		Map<String,String> mapCountrys= new Map<String,String>();
		String strCountryKey;
        strCountryKey='';
		mapCountrys.put('ABU DABI (UAE)','Arab Emirates');
		mapCountrys.put('BELGICA','Belgium');
		mapCountrys.put('BRASIL','Brazil');
		mapCountrys.put('FRANCIA','France');
		mapCountrys.put('ALEMANIA','Germany');
		mapCountrys.put('HONG-KONG','Hong Kong');
		mapCountrys.put('IRLANDA','Ireland');
		mapCountrys.put('ITALIA','Italy');
		mapCountrys.put('JAPON','Japan');
		mapCountrys.put('SINGAPUR','Singapore');
		mapCountrys.put('COREA DEL SUR','South Korea');
		mapCountrys.put('ESPAÑA','Spain');
		mapCountrys.put('TAILANDIA','Thailand');
		mapCountrys.put('TURQUIA','Turkey');
		mapCountrys.put('NO DEFINIDO','Undefined');
		mapCountrys.put('REINO UNIDO','United Kingdom');
		mapCountrys.put('EEUU','USA');
       
	   if(mapCountrys.containsKey(countryBooking)) {
		  strCountryKey=mapCountrys.get(countryBooking); 
	   }else {
		  strCountryKey=countryBooking; 
	   }
	   return strCountryKey.toLowerCase();
	}
    /**
    * gets the group id
    **/
    public static String getGroupId(String recordId) {
        return [SELECT participant_id__c FROM DES_Group_Analysis__c WHERE Id = :recordId LIMIT 1].participant_id__c;
    }
    
    /**
	* gets the AP id
	**/
    public static String getApId(String recordId) {
        return [SELECT gf_account_planning_id__c FROM DES_Group_Analysis__c WHERE Id = :recordId LIMIT 1].gf_account_planning_id__c;
    }
    
     /**
	* gets the AP Launch period
	**/
    public static String getLaunchPeriod (String recordId) {
        return [SELECT gf_account_planning_id__r.acpl__gf_ap_launch_period_desc__c FROM DES_Group_Analysis__c WHERE Id = :recordId LIMIT 1].gf_account_planning_id__r.acpl__gf_ap_launch_period_desc__c;
    }
   /**
    * @author Global Desktop
    * @description Clase wrapper para devolver los datos
    */
    public class WrapperGlobalData {
        public  List<String>  lstCountry =new List<String>(); //NOSONAR
		public  List<String>  lstProduct =new List<String>(); //NOSONAR
		public  List<Decimal> lstcurrent=new List<Decimal>(); //NOSONAR
		public  List<Decimal> lstrevenue=new List<Decimal>(); //NOSONAR
    }
   /**
    * @author Global Desktop
    * @description Clase wrapper para devolver los datos
    */
    public class WrapperData {
        public  String  product; //NOSONAR
		public  String  country; //NOSONAR
        public  Decimal current; //NOSONAR
        public  Decimal revenue; //NOSONAR
    }
}