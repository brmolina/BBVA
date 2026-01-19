/**********************************************************************************
* @description  Batch Ajuste permisos usuarios
* @Revision
**********************************************************************************/
public without sharing class AJustePermisosTerritorioOpportBatch  implements Database.Batchable<Sobject> {

     /*
     *  @author     Global Desktop
     *  @description    batch START method
    **/
    public Database.QueryLocator start(Database.BatchableContext batchContext) {

        //SACA LAS SHARE TIPO TERRITORIO Y SUS OPORTUNIDADES
        List<OpportunityShare> lstOpShare=[select Id, UserOrGroupId,OpportunityId from OpportunityShare where Opportunity.RecordType.name!='Privileged Opportunity' and Opportunity.Private_opportunity__c=false and Opportunity.disclosure_info_type__c!='Inside information'  and Opportunity.StageName !='Draft Opp' and RowCause ='Manual' and UserOrGroupId in (select id from Group where Type = 'Territory')];
        //Los que sean de tipo "Territory", el ID de la oportunidad se "excluyen" del paso siguiente. type='Territory'
        final Set<String> setOpr=new Set<String>();
        final Map<Id,Id> mapOport=new Map<Id,Id>();
        final Map<Id,Id> mapOportDuplicados=new Map<Id,Id>();
        // SACA LAS OPORTUNIDADES CON SOLO UN SHARE
        for(Integer i=0;i<lstOpShare.size();i++) {
            if(!mapOport.containsKey(lstOpShare[i].OpportunityId)) {
                mapOport.put(lstOpShare[i].OpportunityId,lstOpShare[i].OpportunityId);//SACA TODAS LAS OPORTUNIDADES DE LAS SHARE
            } else {
                mapOportDuplicados.put(lstOpShare[i].OpportunityId,lstOpShare[i].OpportunityId);//SACA SOLO LAS QUE TIENEN MAS DE UN SHARE
            }
        }

        for(Integer i=0;i<lstOpShare.size();i++) {
            //if(!mapOportDuplicados.containsKey(lstOpShare[i].OpportunityId)) 
            {
                setOpr.add(lstOpShare[i].OpportunityId);     
            }
           
        }
		
        //SACA LAS OPORTUNIDADES QUE NO ESTEN EN DRAF Y QUE NO TENGAN SHARE TIPO TERRITORY
		List<Opportunity> lstOportAdd=[select id from opportunity where id not in:mapOport.keySet() and RecordType.name!='Privileged Opportunity' and Private_opportunity__c=false and StageName !='Draft Opp' and disclosure_info_type__c!='Inside information'  ];
		
		
		for(Integer i=0;i<lstOportAdd.size();i++) {
           setOpr.add(lstOportAdd[i].id);
        }
		
        //SACA LOS OPPORTUNITYLINEITEM DE LAS OPORTUNIDADES FILTRADAS PARA INSERTAr LAS SHARE CORRESPONDIENTES
        String pQuery = 'SELECT Id, ProductCode, OpportunityId, Opportunity.DES_Booking_Geography__c, Opportunity.Account.DES_Segment__c, Opportunity.disclosure_info_type__c	FROM OpportunityLineItem	WHERE  OpportunityId in :setOpr AND Opportunity.AccountId != null ';
        if(Test.isRunningTest()) {
            pQuery = 'SELECT Id, ProductCode, OpportunityId, Opportunity.DES_Booking_Geography__c, Opportunity.Account.DES_Segment__c, Opportunity.disclosure_info_type__c	FROM OpportunityLineItem';
        
        }
        
        return Database.getQueryLocator(pQuery);
    }

    /*
     *  @author     Global Desktop
     *  @description    batch EXECUTE method
    **/
    public void execute(Database.BatchableContext batchContext, List<OpportunityLineItem> oppsLineItem) {
		List<sObject> inserts;
        inserts = new List<sObject>();
        
        Set<String> setOpId=new Set<String>(); 
        for(Integer i=0;i<oppsLineItem.size();i++) {
            setOpId.add(oppsLineItem[i].Opportunityid);
        }
        List<opportunity> lstop=[select id from opportunity where id in:setOpId];
        
        Map<Id,Opportunity> objectosNew=new Map<Id,Opportunity>();
		
        for(Integer i=0;i<lstop.size();i++) {
            objectosNew.put(lstop[i].id,lstop[i]);
        }

        for (OpportunityLineItem objecto : oppsLineItem) {
            OpportunityLineItem obj = objecto.clone();//NOSONAR
            inserts.addAll(DES_HandlerTerritory.shareWithTerritory(obj, objectosNew.get(obj.OpportunityId)));
        }
        system.debug('::::: inserts: ' + inserts);
        insert inserts;


    }//FIN execute

    /*
     *  @author     Global Desktop
     *  @description    batch FINISH method
    **/
    public void finish(Database.BatchableContext batchContext) {
    }

}