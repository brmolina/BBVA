/*
* Autor: Arsenio Perez Lopez
* Class: DynamicRelateProfability_cls
* Description: 
* History:
* ------------------------------------------------------
* Autor----------fecha-------------Cambio
* ------------------------------------------------------
* Arsenio Perez-----19/10/2018-----------Creacion.
* 
*/
public without sharing class DynamicRelateProfability_cls {
    
    @AuraEnabled public Static List<String> recuperaServicio(String idAccount){
        final set<String> lita = new set<String>();
        List<Account_Profitability__c> profitability = new List<Account_Profitability__c>();
        profitability =[SELECT product_desc__c FROM Account_Profitability__c where local_client_id__c =:idAccount and product_desc__c !='' order by product_desc__c ];
        for(Account_Profitability__c pro: profitability){
            if(!lita.contains(pro.product_desc__c))
                lita.add(pro.product_desc__c); 
        }
        List<String> retur = new List<String>();
        retur.addall(lita);
        retur.sort();
        return retur;
    }
    @AuraEnabled public static List<Date> recuperaDate(String idAccount){
        final set<Date> Dlita = new set<Date>();
        final List<Date> Rlita = new List<Date>();
        final List<Account_Profitability__c> profitability = new List<Account_Profitability__c>();
        final list<AggregateResult> lasDateD = [SELECT MAX(year_month_day_date__c)dateP FROM Account_Profitability__c 
                                          WHERE profitability_subcategory_type__c IN ('TOTAL','DI','Spread','Tasa','ME','MN','TOTAL CLIENTE','TOTAL DI','TOTAL SPREAD','TOTAL TASA') and 
                                          local_client_id__c=:idAccount and  is_date_type_1_within_last_6_months__c = true ];
        if(!lasDateD.isEmpty() && lasDateD[0].get('dateP')!=null){
            Dlita.add(((Date)lasDateD[0].get('dateP')).toStartofMonth().addMonths(-5));
            Dlita.add(((Date)lasDateD[0].get('dateP')).toStartofMonth().addMonths(1));
        }
        Rlita.addall(Dlita);
        Rlita.sort();
        return Rlita;
    }
}