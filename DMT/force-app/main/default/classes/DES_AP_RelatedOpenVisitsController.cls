/*
* @author Global Desktop
* @description NextVisitsByFamilyCont
*/
public  with sharing class DES_AP_RelatedOpenVisitsController {
    
    /*
	* @author Global Desktop
	* @description Recupera la cuenta relacionada con el Account Plan
	*/
  	@auraEnabled
  	public static String gtAPAccountId(String apId) {
        String accId = [SELECT acpl__participant_id__c FROM acpl__Account_Planning__c WHERE Id = :apId].acpl__participant_id__c;
        return accId;
    }
    
    /*
    * @author Global Desktop
    * @description Recupera las visitas relacionadas al cliente
    */
    @auraEnabled
    public static String getRelatedVisits(String tableSize, Id accId) {
        List<DES_Denorm_AccountVisits__c> relatedVisits = new List<DES_Denorm_AccountVisits__c>();
        relatedVisits = acountVisitDenorm(accId);
        
        Integer visNumber = relatedVisits.size();
        Integer tSize;
        if(tableSize != null){
            tSize = Integer.valueOf(tableSize);
        }
        
        List<wrapperClass> listWrapperClass = new List<wrapperClass>();
        for(DES_Denorm_AccountVisits__c i :relatedVisits) {
            listWrapperClass.add(new wrapperClass(i.DES_Visit_new__c, i.DES_Visit_new__r.Name,
                                                  i.DES_Visit_new__r.dwp_kitv__account_id__c,
                                                  i.DES_Visit_new__r.DES_AccountName__c, i.DES_Visit_new__r.dwp_kitv__country_name__c,
                                                  i.CreatedBy.Name, i.DES_Visit_new__r.dwp_kitv__solution_name_path_desc__c,
                                                  i.DES_Start_Date__c , visNumber, i.DES_Client__r.DES_Structure_Type__c, i.DES_Visit_new__r.dwp_kitv__visit_channel__c));
        }
        
        String resp;
        if(tSize != null) {
            resp = JSON.serialize(wrapperListToReturn(tSize,listWrapperClass));
        } else {
            resp = JSON.serialize(listWrapperClass);
        }
        return resp;
    }
    
    
    /**
* @author Global Desktop
* @description Method auxiliar para recuperar las visitas filtradas por pais o familia
*/
    public static List<DES_Denorm_AccountVisits__c> acountVisitDenorm(Id accId) {
        List<DES_Denorm_AccountVisits__c> relatedVisitsAux = new List<DES_Denorm_AccountVisits__c>();
        System.debug('accId:' + accId);
                    relatedVisitsAux = [SELECT DES_Visit_new__c, DES_Visit_new__r.Name, DES_Visit_new__r.dwp_kitv__account_id__c,
                                DES_Visit_new__r.DES_AccountName__c, toLabel(DES_Visit_new__r.dwp_kitv__country_name__c), CreatedBy.Name,
                                DES_Visit_new__r.dwp_kitv__solution_name_path_desc__c, DES_Start_Date__c,
                                DES_Client__r.DES_Structure_Type__c, toLabel(DES_Visit_new__r.dwp_kitv__visit_channel__c)	
                                FROM DES_Denorm_AccountVisits__c
                                WHERE DES_Client__c = :accId
                                AND DES_Start_Date__c >= TODAY
                                ORDER BY DES_Start_Date__c ASC];
        return relatedVisitsAux;
    }
    
    
    /**
* @author Global Desktop
* @description Method auxiliar para construir la lista wrapper
*/
    public static List<wrapperClass> wrapperListToReturn(Integer tSize, List<wrapperClass> listWrapperClass) {
        List<wrapperClass> listaWrapperAux = new List<wrapperClass>();
        Integer regTable = tSize;
        if(tSize > listWrapperClass.size()) {
            regTable = listWrapperClass.size();
        }
        for(Integer cnt = 0; cnt < regTable ; cnt++) {
            if(!listWrapperClass.isEmpty() && listWrapperClass.get(cnt) != null) {
                listaWrapperAux.add(listWrapperClass.get(cnt));
            }
        }
        return listaWrapperAux;
    }
    
    
    /*
    * @author Global Desktop
    * @description Construye la lista wrapper para devolverla al componente lightning
    */
    public class wrapperClass {
        /*
        * @author Global Desktop
        * @description Declaracion de los canpos de la lista wrapper
        */
        private String visUrl; //NOSONAR
        /*
        * wrapper field
        */
        private String accUrl; //NOSONAR
        /*
        * wrapper field
        */
        private String visId; //NOSONAR
        /*
        * wrapper field
        */
        @Testvisible
        private String visName; //NOSONAR
        /*
        * wrapper field
        */
        private String accName; //NOSONAR
        /*
        * wrapper field
        */
        private String clientId; //NOSONAR
        /*
        * wrapper field
        */
        private String creatBy; //NOSONAR
        /*
        * wrapper field
        */
        private Datetime startDateTime; //NOSONAR
        /*
        * wrapper field
        */
        private Date startDate; //NOSONAR
        /*
        * wrapper field
        */
        private String prod; //NOSONAR
        /*
        * wrapper field
        */
        private String country; //NOSONAR
        /*
        * wrapper field
        */
        private integer visNumber; //NOSONAR
        /*
        * wrapper field
        */
        private String accType; //NOSONAR
        /*
        * wrapper field
        */
        private String visitCallType; //NOSONAR
        /*
        * @author Global Desktop
        * @description Construye la lista wrapper
        */
        public wrapperClass(String visId,String visName,String clientId,String clientName,String country,String creatBy,String prod,Datetime startDateTime,Integer visNumber,String accType, String visitCallType) { //NOSONAR
            this.visUrl = '/lightning/r/dwp_kitv__Visit__c/' + visId + '/view';
            this.accUrl = '/lightning/r/Account/' + clientId + '/view';
            this.visName = visName;
            this.accName = clientName;
            this.creatBy = creatBy;
            this.prod = prod;
            this.startDate = startDateTime.date();
            this.country = country;
            this.visNumber = visNumber;
            this.accType = accType;
            this.visitCallType = visitCallType;
        }
    }
}