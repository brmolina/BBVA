/**********************************************************************************
* @author       VASS - DSL
* @date         23/04/2018
* @description  Clase que recupera las oportunidades que más tiempo llevan sin haber interaccionado con ellas
* @Revision                     
**********************************************************************************/
global with sharing class DES_CustomReportLastUpdOpps {
    
    global DES_CustomReportLastUpdOpps() {

    }
    
    @AuraEnabled
    public static String getCurrentUserISOCode(){
        
        return UserInfo.getDefaultCurrency(); 
    }
    
    @AuraEnabled
    public static String getData(String famProd, String tableSize){
        /*
        Integer tSize;
        if(tableSize != null){
            tSize = Integer.valueOf(tableSize);
        }
        //Set con el Id de las oportunidades que no se han modificado en los ultimos 30 días
        Set<Id> setIdOpps = new Set<Id>();
        //Calculo la fecha que sería hace 30 días
        Date date30Days = Date.today().addDays(-30);
        //Lista de las oportunidades que se van a mostrar en la tabla
        List<wrapperClass> listWrapperClass = new List<wrapperClass>();

        system.debug('>>>>> date30Days : ' + date30Days);
        //1. Lanzo una query a Opportunity para obtener todas las Opps del cliente, 
        //cuya ultima fecha de modificacion sea mayor a 30 días, 
        //Ordenada por Expected Revenues de mayor a menor
        List<DES_Opportunity_Management_member__c> listOMM = new List<DES_Opportunity_Management_member__c>([
                                                SELECT DES_Opportunity__c
                                                FROM DES_Opportunity_Management_member__c
                                                WHERE DES_User__c = :UserInfo.getUserId()]);
        Set<Id> setIdOppsMiembro = new Set<Id>();
        for(DES_Opportunity_Management_member__c oppmm : listOMM){
            if(!setIdOppsMiembro.contains(oppmm.DES_Opportunity__c)){
                setIdOppsMiembro.add(oppmm.DES_Opportunity__c);
            }
        }
        
        List<Opportunity> listOpp = new List<Opportunity>([ 
                                    SELECT  Id,
                                            DES_Expected_Revenues__c,
                                            Name,
                                            AccountId,
                                            Account.Name,
                                            LastModifiedDate
                                    FROM Opportunity
                                    WHERE LastModifiedDate < :date30Days 
                                            AND IsClosed = false
                                            AND Id IN ( SELECT OpportunityId 
                                                        FROM OpportunityLineItem
                                                        WHERE DES_Product_Family__c = :famProd)
                                            AND (Id IN :setIdOppsMiembro
                                                OR OwnerId = :UserInfo.getUserId())
                                                
                                    ORDER BY DES_Expected_Revenues__c DESC 
                                    LIMIT 2000
        ]);

        system.debug('>>>>> listOpp: ' + listOpp);
        if(!listOpp.isEmpty()){
            //1.2. Recorro la lista y:
            //  guardo los Id's de las oportunidades en un set
            for(Opportunity opp : listOpp){
                if(!setIdOpps.contains(opp.Id)){
                    setIdOpps.add(opp.Id);
                }
            }

            system.debug('>>>>> setIdOpps: ' + setIdOpps);
            system.debug('>>>>> setIdOppslength: ' + setIdOpps.size());
            //2. Lanzo una query a Files (Attachments) con una fecha menor a 30 días que esté vinculada a alguna de las oportunidades del set
            //2.1. Recorro el resultado de la query y quito las Opportunidades del set
            for(Attachment a : [SELECT ParentId FROM Attachment WHERE LastModifiedDate > :date30Days AND ParentId IN :setIdOpps]){
                if(setIdOpps.contains(a.ParentId)){
                    setIdOpps.remove(a.ParentId);   
                }
                
            }
            system.debug('>>>>> setIdOpps SIN VISITAS: ' + setIdOpps);
            system.debug('>>>>> setIdOpps SIN VISITAS length: ' + setIdOpps.size());
            //4. Lanzo una query a OpportunityLineItem con una fecha menor a 30 días que estén vinculadas a alguna de las oportunidades del set
            //4.1. Recorro el resultado de la query y quito las Opportunidades del set
            for(OpportunityLineItem opli : [SELECT OpportunityId FROM OpportunityLineItem WHERE LastModifiedDate > :date30Days AND OpportunityId IN :setIdOpps]){
                if(setIdOpps.contains(opli.OpportunityId)){
                    //system.debug('>>>>> BORRO opli.OpportunityId: ' + opli.OpportunityId);
                    setIdOpps.remove(opli.OpportunityId);   
                }
                
            }
            system.debug('>>>>> setIdOpps SIN OPPORTUNITY PRODUCTS: ' + setIdOpps);
            //5. Lanzo una query a BBVA Client Participants con una fecha menor a 30 días que estén vinculadas a alguna de las oportunidades del set
            //5.1. Recorro el resultado de la query y quito las Opportunidades del set
            for(DES_Opportunity_Management_member__c omm : [SELECT DES_Opportunity__c FROM DES_Opportunity_Management_member__c WHERE LastModifiedDate > :date30Days AND DES_Opportunity__c IN :setIdOpps]){
                if(setIdOpps.contains(omm.DES_Opportunity__c)){
                    setIdOpps.remove(omm.DES_Opportunity__c);   
                }
                
            }
            system.debug('>>>>> setIdOpps SIN OPP MANAG MEMBERS: ' + setIdOpps);
            //6. Lanzo una query a Notes con una fecha menor a 30 días que estén vinculadas a alguna de las oportunidades del set
            //6.1. Recorro el resultado de la query y quito las Opportunidades del set
            for(Note n : [SELECT ParentId FROM Note WHERE LastModifiedDate > :date30Days AND ParentId IN :setIdOpps]){
                if(setIdOpps.contains(n.ParentId)){
                    setIdOpps.remove(n.ParentId);   
                }
                
            }
            system.debug('>>>>> setIdOpps SIN NOTAS: ' + setIdOpps);
            //7. Lanzo una query a Tasks con una fecha menor a 30 días que estén vinculadas a alguna de las oportunidades del set
            //7.1. Recorro el resultado de la query y quito las Opportunidades del set
            for(Task t : [SELECT WhatId FROM Task WHERE LastModifiedDate > :date30Days AND WhatId IN :setIdOpps]){
                if(setIdOpps.contains(t.WhatId)){
                    setIdOpps.remove(t.WhatId); 
                }
                
            }
            system.debug('>>>>> setIdOpps SIN TAREAS: ' + setIdOpps);
            //9. Lanzo una query a ¿CHATTER FEED? con una fecha menor a 30 días que estén vinculadas a alguna de las oportunidades del set
            //9.1. Recorro el resultado de la query y quito las Opportunidades del set
            
            system.debug('>>>>> setIdOpps - DESPUES: ' + setIdOpps);

            if(!setIdOpps.isEmpty()){
                for(Opportunity  opp : listOpp){
                    if(setIdOpps.contains(opp.Id)){
                        listWrapperClass.add(new wrapperClass(opp.Id, opp.Name, opp.AccountId, opp.Account.Name, 
                                                             opp.DES_Expected_Revenues__c, date.newinstance(opp.LastModifiedDate.year(), opp.LastModifiedDate.month(), opp.LastModifiedDate.day())));
                    }
                }
            }
        }
        
        if(tSize != null){
            List<wrapperClass> listaWrapperAux = new List<wrapperClass>();
            for(Integer cn = 0; cn < tSize ; cn++){
                if( !listWrapperClass.isEmpty() && listWrapperClass.get(cn) != null){
                    listaWrapperAux.add(listWrapperClass.get(cn));
                }
            }
            system.debug('>>>>> listaWrapperAux : ' + listaWrapperAux);
            return JSON.serialize(listaWrapperAux);
        }else{
            system.debug('>>>>> listWrapperClass : ' + listWrapperClass);
            return JSON.serialize(listWrapperClass);
        }
        
    */    
    return null;
    }//FIN funcion getData
    
    /*public class wrapperClass{
        public String oppUrl;
        public String oppName;
        public String clientURL;
        public String clientName;
        public Decimal expectedRevenue;
        public Date lastModifDate;
        
        public wrapperClass(Id oppId, String oppName, Id clientId, String clientName, Decimal expRev, Date lastModDate){
            this.oppUrl = '/lightning/r/Opportunity/' + oppId + '/view';
            this.oppName = oppName;
            this.clientURL = '/lightning/r/Account/' + clientId + '/view';
            this.clientName = clientName;
            this.expectedRevenue = expRev;
            this.lastModifDate = lastModDate;
        }
        
    }*/
    

}//FIN DES_CustomReportLastUpdOpps