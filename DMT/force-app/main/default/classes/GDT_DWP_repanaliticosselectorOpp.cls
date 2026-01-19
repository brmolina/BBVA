/*
* getAccountsName
* Clase que recoge la parte variable de las url de micro en Opp
* @author Ander Ercilla
*/
public with sharing class GDT_DWP_repanaliticosselectorOpp {//NOSONAR
/*
* GDT_DWP_repanaliticosaccselector
* Método que devuelve el Identificador fiscal del cliente
* @author Ander Ercilla
*/ 

    @AuraEnabled
    public static string getAccountsName ( id  recordId) {
        Opportunity opp;
        if (Schema.sObjectType.Opportunity.isAccessible()) {
        opp = [SELECT AccountId FROM Opportunity WHERE id =:recordId LIMIT 1];  
        }    
        final String cifacc = [SELECT DES_ID_Fiscal__c FROM Account WHERE id =:Opp.AccountId LIMIT 1].DES_ID_Fiscal__c;
        return  cifacc;//NOSONAR
    }
/*
* getproduct
* Método que analiza el producto de la oportunidad
* @author Ander Ercilla
*/     
    @AuraEnabled
       public static string getproduct ( id  recordId) {     
        string finalproduct;    
        final String product = [SELECT gf_opportunity_product_desc__c FROM Opportunity WHERE id =:recordId LIMIT 1].gf_opportunity_product_desc__c;
           if( product != null) {//NOSONAR
               finalproduct = product;
           } else {
                 finalproduct = '';
               }
       		 return  finalproduct;
         }
    }