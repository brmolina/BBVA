/**********************************************************************************
 * @author       SERBATIC (GRUPO VASS)   -   DSL
 * @description  Clase que contiene los procesos a ejecutar cuando se insertan los registros de tipo DES_Booking__c.
 * @Revision
 **********************************************************************************/
public with sharing class DES_BookingTriggerHandler{
    private static CIB_User_Org__c userSettings = CIB_User_Org__c.getInstance();
    /*
     * @author Global Desktop
     * @Description identify Year Of Booking
     */
    public static void identifyYearOfBooking(List<DES_Booking__c> triggerNew){

        if (triggerNew == null || triggerNew.isEmpty()){
            return;
        }

        if (userSettings == null || !userSettings.CIB_Is_Desktop__c){
            return;
        }

        Id clientId = triggerNew[0].DES_Client__c;
        if (clientId == null){
            return;
        }

        List<Account> listaCuentas = [SELECT Id, DES_Revenue_Update_Engloba__c
                                      FROM Account
                                      WHERE Id = :clientId
                                      LIMIT 1];

        if (listaCuentas.isEmpty()){
            return;
        }

        String engloba = listaCuentas[0].DES_Revenue_Update_Engloba__c;
        if (engloba == null || engloba.length() < 4){
            return;
        }

        Decimal maxYear = Decimal.valueOf(engloba.substring(0, 4));

        for (DES_Booking__c b : triggerNew){
            if (b.DES_Type__c == 'GF'){
                b.DES_Type__c = 'IBF';
            }

            if (b.DES_Year_Number__c == maxYear){
                b.DES_Engloba_Load_Helper__c = '0';
            } else if (b.DES_Year_Number__c == maxYear - 1){
                b.DES_Engloba_Load_Helper__c = '1';
            } else if (b.DES_Year_Number__c == maxYear - 2){
                b.DES_Engloba_Load_Helper__c = '2';
            }
        }
        update triggerNew;
    }

}