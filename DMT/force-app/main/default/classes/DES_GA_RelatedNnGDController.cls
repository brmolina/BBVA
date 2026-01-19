/**********************************************************************************
* @author       Global Desktop
* @description  DES_GA_RelatedNnGDController
* @Revision     
**********************************************************************************/
public with sharing class DES_GA_RelatedNnGDController {

    /*
	* @author Global Desktop
	* @description Recupera la cuenta relacionada con el Group Analysis
	*/
  	@auraEnabled
  	public static String gtGAAPId(String gaId) {
        return [SELECT gf_account_planning_id__c FROM DES_Group_Analysis__c WHERE Id = :gaId].gf_account_planning_id__c;
    }

	/*
	* @author Global Desktop
	* @description Recupera los Needs relacionados con la cuenta
	*/
  	@auraEnabled
  	public static String getRelatedNeeds(String tableSize, String apId) {
	    List<bupl__BP_Need__c> relatedNeeds = new list<bupl__BP_Need__c>();
        relatedNeeds = [SELECT id,bupl__gf_bus_pl_cust_lock_desc__c, bupl__gf_business_plan_lock_name__c, bupl__gf_bus_pl_cust_lock_name__c,
                        bupl__gf_bus_pl_sales_goal_name__c, bupl__country_id__c, CreatedBy.Name, CreatedById, CreatedDate 
                  		FROM bupl__BP_Need__c WHERE acpl__gf_account_planning_id__c =: apId];

        final Integer recNumber = relatedNeeds.size();
	    Integer tSize;
	    if(tableSize != null){
	      tSize = Integer.valueOf(tableSize);
	    }

	    List<wrapperClass> listWCNeed = new List<wrapperClass>();
	    for(bupl__BP_Need__c i :relatedNeeds){
	          listWCNeed.add(new wrapperClass(i.Id,i.bupl__gf_bus_pl_cust_lock_desc__c, i.bupl__gf_business_plan_lock_name__c,
                                              i.bupl__gf_bus_pl_cust_lock_name__c, i.bupl__gf_bus_pl_sales_goal_name__c,
                                              i.bupl__country_id__c,i.CreatedBy.Name, i.CreatedById, i.CreatedDate,
                                              null,null,null,null,null,null,null,null, recNumber));
	    }

	  if(tSize != null) {
	    List<wrapperClass> listaWAuxNeed = new List<wrapperClass>();
	      Integer regTable = tSize;
	      if(tSize > listWCNeed.size()) {
	        regTable = listWCNeed.size();
	      }
	      for(Integer cn = 0; cn < regTable ; cn++){
	        if(!listWCNeed.isEmpty() && listWCNeed.get(cn) != null) {
	          listaWAuxNeed.add(listWCNeed.get(cn));
	        }
	      }
	      return JSON.serialize(listaWAuxNeed);
	  }else{
	    system.debug('>>>>> listWCNeed tSize NULL : ' + listWCNeed);
	    return JSON.serialize(listWCNeed);
	  }
    }

	/*
	* @author Global Desktop
	* @description Recupera los Needs relacionados con la cuenta
	*/
  	@auraEnabled
  	public static String getRelatedDrivers(String tableSize, String apId) {
	    List<bupl__BP_GrowthDriver__c> relatedDrivers = new list<bupl__BP_GrowthDriver__c>();
        relatedDrivers = [SELECT id,bupl__gf_growth_drvr_prdt_short_desc__c, DES_GD_Name__c, bupl__solution_category_id__c,
                        bupl__solution_category_desc__c, bupl__country_id__c, bupl__gf_growth_drvr_prdt_desc__c, CreatedDate 
                  		FROM bupl__BP_GrowthDriver__c WHERE acpl__gf_account_planning_id__c =: apId];

        final Integer recNumber = relatedDrivers.size();
	    Integer tSize;
	    if(tableSize != null){
	      tSize = Integer.valueOf(tableSize);
	    }

	    List<wrapperClass> listWCDriver = new List<wrapperClass>();
	    for(bupl__BP_GrowthDriver__c i :relatedDrivers){
	          listWCDriver.add(new wrapperClass(null,null,null,null,null,null,null,null,null,
                                                i.Id, i.bupl__gf_growth_drvr_prdt_short_desc__c,i.DES_GD_Name__c,
                                                i.bupl__solution_category_id__c, i.bupl__solution_category_desc__c,
                                                i.bupl__country_id__c,i.bupl__gf_growth_drvr_prdt_desc__c, i.CreatedDate, recNumber));
	    }

	  if(tSize != null) {
	    List<wrapperClass> listaWAuxDriver = new List<wrapperClass>();
	      Integer regTable = tSize;
	      if(tSize > listWCDriver.size()) {
	        regTable = listWCDriver.size();
	      }
	      for(Integer cn = 0; cn < regTable ; cn++){
	        if(!listWCDriver.isEmpty() && listWCDriver.get(cn) != null) {
	          listaWAuxDriver.add(listWCDriver.get(cn));
	        }
	      }
	      return JSON.serialize(listaWAuxDriver);
	  }else{
	    system.debug('>>>>> listWCDriver tSize NULL : ' + listWCDriver);
	    return JSON.serialize(listWCDriver);
	  }
    }

	/*
	* @author Global Desktop
	* @description clase wrapper para devolver la informacion al componente lightning
	*/
    public class wrapperClass {
	/*
    * @author Global Desktop
    * @description Declaracion de los campos de la lista wrapper
    */
    /*
    * wrapper field
    */
      private String needUrl; //NOSONAR
    /*
    * wrapper field
    */
      private String needId; //NOSONAR
    /*
    * wrapper field
    */
      private String needDesc; //NOSONAR
    /*
    * wrapper field
    */
      private String needName; //NOSONAR
    /*
    * wrapper field
    */
      private String needPain; //NOSONAR
    /*
    * wrapper field
    */
      private String needNeed; //NOSONAR
    /*
    * wrapper field
    */
      private String needCountry; //NOSONAR
    /*
    * wrapper field
    */
      private String needCrName; //NOSONAR
    /*
    * wrapper field
    */
      private Id needCrId; //NOSONAR
    /*
    * wrapper field
    */
      private String needCrea; //NOSONAR
    /*
    * wrapper field
    */
      private Date needDate; //NOSONAR
    /*
    * wrapper field
    */
      private String driverUrl; //NOSONAR
    /*
    * wrapper field
    */
      private String driverId; //NOSONAR
    /*
    * wrapper field
    */
      private String driverShort; //NOSONAR
    /*
    * wrapper field
    */
      private String driverName; //NOSONAR
    /*
    * wrapper field
    */
      private String driverFam; //NOSONAR
    /*
    * wrapper field
    */
      private String driverProd; //NOSONAR
    /*
    * wrapper field
    */
      private String driverCountry; //NOSONAR
    /*
    * wrapper field
    */
      private String driverDesc; //NOSONAR
    /*
    * wrapper field
    */
      private Date driverDate; //NOSONAR
	/*
    * wrapper field
    */
	  private integer recNumber; //NOSONAR   

    /* @author Global Desktop
    * @description Construye la lista wrapper
    */
      public wrapperClass(String needId, String needDesc, String needName, String needPain, String needNeed, String needCountry, String needCrName, Id needCrId, Datetime needDate, 
                          String driverId, String driverShort, String driverName, String driverFam, String driverProd, String driverCountry, String driverDesc, Datetime driverDate,
                         Integer recNumber) {
        if(needId == null) {
        this.needUrl = null;
        } else {
        this.needUrl = '/lightning/r/bupl__BP_Need__c/' + needId + '/view';
        }
        this.needDesc = needDesc;
        this.needName = needName;
        this.needPain = needPain;
        this.needNeed = needNeed;
        this.needCountry = needCountry;
        this.needCrName = needCrName;
        this.needCrea = '/lightning/r/User/' + needCrId + '/view';
        if(needId == null) {
        this.needDate = null;
        } else {
        this.needDate = needDate.date();
        }
        if(driverId == null) {
           this.driverUrl = null;
        } else {
            this.driverUrl = '/lightning/r/bupl__BP_GrowthDriver__c/' + driverId + '/view';
        }
        this.driverShort = driverShort;
        this.driverName = driverName;
        this.driverFam = driverFam;
        this.driverProd = driverProd;
        this.driverCountry = driverCountry;
        this.driverDesc = driverDesc;
        if(driverId == null) {
           this.driverDate = null;
        } else {
        this.driverDate = driverDate.date();
        }
        this.recNumber = recNumber;
    }
  }
}