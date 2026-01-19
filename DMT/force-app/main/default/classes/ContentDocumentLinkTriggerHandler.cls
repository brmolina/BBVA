public with sharing class ContentDocumentLinkTriggerHandler {
    private static CIB_User_Org__c userSettings = CIB_User_Org__c.getInstance();
    private static ContentDocumentLinkTriggerHandler instance;

	//Mapa con el Id del ContentDocument como key y el objeto ContentVersion como value
	private static Map<Id, ContentVersion> mapContDocContVer = new Map<Id, ContentVersion>();
	//Mapa con las entidades Template relacionadas como key el id del ContentDocument y como value el objeto template
	private static Map<Id, DES_Template__c> mapContDocTemplate = new Map<Id, DES_Template__c>();
	//Lista de ContentVersion que se va a actualizar
	private static List<ContentVersion> listContVersionToUpd = new List<ContentVersion>();

    public static ContentDocumentLinkTriggerHandler getInstance() {
        if (instance == null) instance = new ContentDocumentLinkTriggerHandler();
        return instance;
    }

 	/*
 	 *	FUNCIONALIDAD AFTER INSERT
 	**/
    public void afterInsert(Map<Id, ContentDocumentLink> triggerNewMap, Map<Id, ContentDocumentLink> triggerOldMap){

    	getGlobalData(triggerNewMap);

    	//Llamo a la funcion que, si es de template renombro el file
    	setFileName();

    	addToFolder(triggerNewMap);


    }//FIN afterInsert


    /*
     *	FUNCIONALIDAD DE PARA RECOGER TODOS LOS DATOS NECESARIOS
    **/
    private void getGlobalData(Map<Id, ContentDocumentLink> triggerNewMap){
    	Set<Id> setContentDocumentIds = new Set<Id>();
    	Set<Id> setTemplateIds = new Set<Id>();
    	for(ContentDocumentLink cdl : triggerNewMap.values()){
    		if(!setContentDocumentIds.contains(cdl.ContentDocumentId)){
    			setContentDocumentIds.add(cdl.ContentDocumentId);
    		}
    		system.debug('>>>>> LinkedEntityId sObject Type : ' + cdl.LinkedEntityId.getSObjectType().getDescribe().getName());
    		system.debug('>>>>> cdl.LinkedEntityId : ' + cdl.LinkedEntityId);
    		if(cdl.LinkedEntityId.getSObjectType().getDescribe().getName() == Label.DES_Template_APIName
    		&& !setTemplateIds.contains(cdl.LinkedEntityId)){
    			setTemplateIds.add(cdl.LinkedEntityId);
    		}
    	}
    	system.debug('>>>>> setTemplateIds : ' + setTemplateIds);
    	system.debug('>>>>> setContentDocumentIds : ' + setContentDocumentIds);
    	if(!setTemplateIds.isEmpty()){
    		mapContDocContVer = new Map<Id, ContentVersion>([SELECT Id, ContentDocumentId, Title, Category_Type__c FROM ContentVersion WHERE ContentDocumentId IN :setContentDocumentIds]);
	    	system.debug('>>>>> mapContDocContVer : ' + mapContDocContVer);

	    	Map<Id, DES_Template__c> mapRelTemplates = new Map<Id, DES_Template__c>([
	    				SELECT Id,
	    						Name,
	    						opportunity_id__c,
	    						opportunity_id__r.Name
	    				FROM DES_Template__c
	    				WHERE Id IN :setTemplateIds
	    	]);

	    	system.debug('>>>>> mapRelTemplates : ' + mapRelTemplates);
	    	for(ContentDocumentLink cdl : triggerNewMap.values()){
	    		mapContDocTemplate.put(cdl.ContentDocumentId, mapRelTemplates.get(cdl.LinkedEntityId));
	    	}
    	}

    }//Fin getGlobalData


	/*
	 *	FUNCION QUE PONE EL TITLE EN FUNCION DE SI TIENE EL CAMPO ANEXO RELLENO Y DE SI ESTÁ RELACIONADO A UN TEMPLATE O NO
	**/
	private void setFileName(){

		listContVersionToUpd = new List<ContentVersion>();

		for(ContentVersion cv : mapContDocContVer.values()){
			system.debug('>>>>> cv.Title : ' + cv.Title);
			system.debug('>>>>> mapContDocTemplate : ' + mapContDocTemplate);
			system.debug('>>>>> mapContDocTemplate.get(cv.ContentDocumentId) : ' + mapContDocTemplate.get(cv.ContentDocumentId));
			system.debug('>>>>> mapContDocTemplate.get(cv.ContentDocumentId).opportunity_id__r.Name : ' + mapContDocTemplate.get(cv.ContentDocumentId).opportunity_id__r.Name);
			//if(!cv.Title.contains(mapContDocTemplate.get(cv.ContentDocumentId).opportunity_id__r.Name)){
				if(cv.Category_Type__c != null){
					cv.Title = /*mapContDocTemplate.get(cv.ContentDocumentId).opportunity_id__r.Name + ' - ' + */cv.Category_Type__c + ' - ' + cv.Title;
					listContVersionToUpd.add(cv);
				}

		}

		system.debug('>>>>> listContVersionToUpd : ' + listContVersionToUpd);
		if(!listContVersionToUpd.isEmpty()){
			update listContVersionToUpd;
		}
	}//Fin setFileName


	/*
	 *	FUNCION QUE AÑADE EL DOCUMENTO A LA CARPETA COMPARTIDA CON S&P
	**/
	private void addToFolder(Map<Id, ContentDocumentLink> triggerNewMap) {
		ContentWorkspaceDoc docLink;
		List<ContentWorkspace> lcwsp = new List<ContentWorkspace>();
		List<ContentWorkspaceDoc> ldocLink;
		ldocLink = new List<ContentWorkspaceDoc>();

		if(Test.isRunningTest()) {
        	lcwsp = new List<ContentWorkspace>();
        } else {
        	lcwsp = new List<ContentWorkspace>([select Id, Name FROM ContentWorkspace WHERE Name = 'NBC Files' LIMIT 1]);
        }

        if(!lcwsp.isEmpty()) {
        	for(String idCntDoc : triggerNewMap.keySet()) {
			System.debug('triggerNewMap.get(idCntDoc).LinkedEntity.getSObjectType().getDescribe().getName()' + triggerNewMap.get(idCntDoc).LinkedEntityId.getSObjectType().getDescribe().getName());
			if(triggerNewMap.get(idCntDoc).LinkedEntityId.getSObjectType().getDescribe().getName() == Label.DES_Template_APIName) {
				System.debug('1');
			    docLink = new ContentWorkspaceDoc();
		        docLink.ContentDocumentId = triggerNewMap.get(idCntDoc).ContentDocumentId;
		        docLink.ContentWorkspaceId = Test.isRunningTest()?null:lcwsp.get(0).Id;
		        ldocLink.add(docLink);
			}
		}
		if(!ldocLink.isEmpty() && !lcwsp.isEmpty() && lcwsp.get(0) != null) {
			insert ldocLink;
		}
        }

	}

}//Fin ContentDocumentLinkTriggerHandler