/**********************************************************************************
 * @author       Accenture
 * @date
 * @description  Manejador del Batch para el borrado de Bookings
 * @Revision
 03/12/2018 Se añade la instrucción después de cada borrado masivo para vaciar la papelera de reciclaje
 **********************************************************************************/
public with sharing class DES_Booking_Batch_Handler{
    private static CIB_User_Org__c userSettings = CIB_User_Org__c.getInstance();
    public static void alternativeTopCountries(List<Account> accList){

        if (accList == null || accList.isEmpty())
            return;
        Map<Id, Account> accMap = new Map<Id, Account>();
        for (Account acc : accList){
            accMap.put(acc.Id, acc);
        }

        Map<Id, List<AggregateResult>> accToAgg = new Map<Id, List<AggregateResult>>();

        for (AggregateResult ar : [SELECT DES_Client__c, DES_Country__c, CurrencyIsoCode, SUM(DES_Revenues__c)suma
                                   FROM DES_Booking__c
                                   WHERE DES_Client__c IN:accMap.keySet()
                                   GROUP BY DES_Client__c, DES_Country__c, CurrencyIsoCode
                                   ORDER BY SUM(DES_Revenues__c) DESC]){
            Id accId = (Id) ar.get('DES_Client__c');

            if (!accToAgg.containsKey(accId)){
                accToAgg.put(accId, new List<AggregateResult>());
            }
            accToAgg.get(accId).add(ar);
        }

        List<Account> toUpdate = new List<Account>();

        for (Id accId : accToAgg.keySet()){
            Account acc = accMap.get(accId);
            if (acc == null)
                continue;
                
            if (acc.DES_Group__c == null || acc.DES_ID_Fiscal__c == null){
                continue;
            }

            List<AggregateResult> ars = accToAgg.get(accId);
            if (ars == null || ars.isEmpty())
                continue;
                
            acc.cust_first_income_country_name__c = null;
            acc.cust_first_income_country_amount__c = 0;
            acc.cust_second_income_country_name__c = null;
            acc.cust_second_income_cntry_amount__c = 0;
            acc.cust_third_income_country_name__c = null;
            acc.cust_third_income_country_amount__c = 0;

            Boolean changed = false;

            for (Integer i = 0; i < Math.min(3, ars.size()); i++){
                AggregateResult ar = ars[i];
                String label = ar.get('DES_Country__c') + ' (' + ar.get('suma') + ' ' + ar.get('CurrencyIsoCode') + ')';
                Decimal amount = (Decimal) ar.get('suma');

                if (i == 0){
                    acc.cust_first_income_country_name__c = label;
                    acc.cust_first_income_country_amount__c = amount;
                } else if (i == 1){
                    acc.cust_second_income_country_name__c = label;
                    acc.cust_second_income_cntry_amount__c = amount;
                } else if (i == 2){
                    acc.cust_third_income_country_name__c = label;
                    acc.cust_third_income_country_amount__c = amount;
                }
                changed = true;
            }

            if (changed){
                toUpdate.add(acc);
            }
        }

        if (!toUpdate.isEmpty()){
            Database.update (toUpdate, false);
        }
    }

}