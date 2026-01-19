/**
 * Using without sharing as need to run query on Organization table
 */
public without sharing class Utilities {
    //Get instance from INSTANCE.visual.force.com page so we can build
    public Static String getInstance() {
        String instance = '';
        Organization o = [SELECT OrganizationType, InstanceName
                          FROM Organization
                          limit 1];
        String orgType = o.OrganizationType;
        String insName = o.InstanceName;
        if (orgType == 'Developer Edition' || insName.startsWithIgnoreCase('cs')) {
            List<String> parts = ApexPages.currentPage().getHeaders().get('Host').split('\\.');
            instance = parts[parts.size() - 4] + '.';
        }
        return instance;
    }

    //Needed in cases if current org is sandbox
    public static String getSubdomainPrefix() {
        Organization o = [SELECT OrganizationType, InstanceName
                          FROM Organization
                          limit 1];
        String orgType = o.OrganizationType;
        String insName = o.InstanceName;
        if (insName.startsWithIgnoreCase('cs')) {
            return UserInfo.getUserName().substringAfterLast('.') + '-';
        }
        return '';
    }

    /*-------------------------------------------------------------------------------------------------------------------------------------------------------
     Author:        Brian Capilla
     Company:       Accenture Cloud First
     Description:   metodo para obtener el prefijo del ID de un objeto por su nombre API

     History:

     <Date>                <Author>                <Change Description>
     29/09/2017            Brian Capilla            Initial Version
     --------------------------------------------------------------------------------------------------------------------------------------------------------*/
    public static String getObjectPrefix(String objectName) {

        if (objectName != null && objectName != '') {
            try {
                String keyPrefix = Schema.getGlobalDescribe().get(objectName).getDescribe().getKeyPrefix();
                return keyPrefix;
            } catch (Exception exc) {
                System.debug('Exception getKeyPrefix' + exc);
            }
        }
        return null;
    }

    /*********************************************************************************************************
     * @name            checkIsMexico
     * @author          Capgemini
     * @created         27/11/2024
     * @description     Método que verifica si los SObjects en el mapa dado pertenecen a México (MX) y actualiza
     *                  el campo 'IsOnlyMexico' como verdadero en consecuencia.
     * @param           Map<Id, SObject> newMap - Mapa de identificadores y SObject a validar.
     * @return          N/A
     **********************************************************************************************************/
    public static void checkIsMexico(Map<Id, SObject> newMap) {
        Set<Id> setAccIds = new Set<Id>();
        String sObjectType = String.valueOf(newMap.values().get(0).getSObjectType());
        for (SObject sOb : newMap.values()) {
            switch on sObjectType {
                when 'Contact' {
                    Contact con = (Contact) sOb;
                    setAccIds.add(con.AccountId);
                }	
                when 'Opportunity' {
                    Opportunity opp = (Opportunity) sOb;
                    setAccIds.add(opp.AccountId);
                }
                when 'dwp_kitv__Visit__c' {	
                    dwp_kitv__Visit__c visit = (dwp_kitv__Visit__c) sOb;
                    setAccIds.add(visit.dwp_kitv__account_id__c);
                }
            }
        }
        Map<Id, Account> mapAcc = new Map<Id, Account>([SELECT Id, Name, DES_Country_Client__c
                                                           FROM Account
                                                           WHERE Id IN:setAccIds AND DES_Country_Client__c = 'MX']);
        for (SObject sOb : newMap.values()) {
            switch on sObjectType {
                when 'Contact' {
                    Contact con = (Contact) sOb;
                    if (con.AccountId != null && mapAcc.containsKey(con.AccountId)) {
                        con.IsOnlyMexico__c = true;
                    } else {
                        con.IsOnlyMexico__c = false;
                    }
                }	
                when 'Opportunity' {
                    Opportunity opp = (Opportunity) sOb;
                    if (opp.AccountId != null && mapAcc.containsKey(opp.AccountId)) {
                        opp.IsOnlyMexicoOpportunity__c = true;
                    } else {
                        opp.IsOnlyMexicoOpportunity__c = false;
                    }
                }
                when 'dwp_kitv__Visit__c' {	
                    dwp_kitv__Visit__c visit = (dwp_kitv__Visit__c) sOb;
                    if (visit.dwp_kitv__account_id__c != null && mapAcc.containsKey(visit.dwp_kitv__account_id__c)) {
                        visit.IsOnlyMexicoVisit__c = true;
                    } else {
                        visit.IsOnlyMexicoVisit__c = false;
                    }
                }
            }
        }
    }

}