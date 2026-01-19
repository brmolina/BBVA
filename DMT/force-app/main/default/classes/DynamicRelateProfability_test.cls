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
@isTest
public class DynamicRelateProfability_test {
    
    @testSetup static voId loadData() {
		TestFactory.createLocalClient();
        final Local_Client__c clie = [select Id,Cib_Client__c from Local_Client__c where Id !=''];
        TestFactory.createAccountProfit(clie.Id);
        final Account_Profitability__c proba = [select Id from Account_Profitability__c limit 1];
        Proba.product_desc__c='producto1';
        update proba;
    }
    @isTest static voId testRecuperaServicio() {
        final Local_Client__c temp1 = [select Id,Cib_Client__c from Local_Client__c where Id !=''];
        final List<String> lista = DynamicRelateProfability_cls.RecuperaServicio(temp1.Id);
        system.assertNotEquals(lista, null);
    }
    @isTest static voId testrecuperaDate() {
        final Local_Client__c temp1 = [select Id,Cib_Client__c from Local_Client__c where Id !=''];
        final List<Date> lista = DynamicRelateProfability_cls.recuperaDate(temp1.Id);
        system.assertNotEquals(lista, null);
    }
}