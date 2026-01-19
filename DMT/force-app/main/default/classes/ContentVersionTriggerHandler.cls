public with sharing class ContentVersionTriggerHandler {
    private static CIB_User_Org__c userSettings = CIB_User_Org__c.getInstance();
    private static ContentVersionTriggerHandler instance;
    // mapa con la relacion de ContentDocumentId - ContentDocumentLink (objeto)
    private static Map<Id, ContentDocumentLink> mapContDocRelEntity = new Map<Id, ContentDocumentLink>();
    private static Map<Id, DES_Template__c> mapTemplatesRelated = new Map<Id, DES_Template__c>();
    final String separator = ' - ';
    public static ContentVersionTriggerHandler getInstance() {
        if (instance == null) instance = new ContentVersionTriggerHandler();
        return instance;
    }

	/*
 	 * FUNCIONALIDAD DE beforeUpdate
 	**/
    public void beforeUpdate(Map<Id, ContentVersion> triggerNewMap, Map<Id, ContentVersion> triggerOldMap){
		setDocumentTemplateName(triggerNewMap.values(), triggerNewMap, triggerOldMap, trigger.isInsert, trigger.isUpdate);
    }


	/*
	 * Función que, en caso de tener un Template asociado, concatena en el nombre del ContentVersion:
	 * el nombre de la Opp + el tipo de anexo (si tiene) + el nombre del fichero que se subía
	**/
	public void setDocumentTemplateName(List<ContentVersion> triggerNew, Map<Id, ContentVersion> triggerNewMap,  Map<Id, ContentVersion> triggerOldMap, Boolean isInsert, Boolean isUpdate){
		//Obtengo la relacion de contentdocument - entidad relacionada
		getGlobalData(triggerNew);
		String sObjectTypeName = '';
		for(ContentVersion cv : triggerNew){
			if(mapContDocRelEntity.get(cv.ContentDocumentId) != null){
				sObjectTypeName =  mapContDocRelEntity.get(cv.ContentDocumentId).LinkedEntityId.getSObjectType().getDescribe().getName();
			}
			system.debug('>>>>> sObjectTypeName : ' + sObjectTypeName);
			system.debug('>>>>> cv : ' + cv);
			/*if(isInsert
				&& sObjectTypeName == Label.DES_Template_APIName){ // si es insert y esta vinculado a un template
				//le pongo el nombre de la oportunidad que tiene relacionada el template delante del nombre del archivo
				system.debug('>>>>> mapTemplatesRelated.get(cv.ContentDocumentId) : ' + mapTemplatesRelated.get(cv.ContentDocumentId));
				cv.Title = mapTemplatesRelated.values().get(0).opportunity_id__r.Name + ' - ' + cv.Title;
				//cv.PathOnClient = mapTemplatesRelated.values().get(0).opportunity_id__r.Name + ' - ' + cv.PathOnClient;
			}else */if(isUpdate
			&& cv.Category_Type__c != null
			&& cv.Category_Type__c != triggerOldMap.get(cv.Id).Category_Type__c) {//Si es actualización (solo aquí le paso el triggerNewMap)

                if(cv.Title.contains(separator)) {
                    //borro el anexo anterior
                    List<String> categories;
                    categories = new List<String>();
                    Schema.DescribeFieldResult fieldResult;
                    fieldResult = ContentVersion.Category_Type__c.getDescribe();
                    List<Schema.PicklistEntry> ple;
                    ple = fieldResult.getPicklistValues();
                    for( Schema.PicklistEntry f : ple) {
                        categories.add(f.getValue());
                    }

                    List<String> lname;
                    lname = cv.Title.split(separator);
                    if(categories.contains(lname[lname.size()-1])) {
                        lname.remove(lname.size()-1);
                    }

                    //le pongo el nombre del anexo delante del nombre del archivo.
                    String name = '';
                    for(String s : lname) {
                        name += s + separator;
                    }

    				//le pongo el nombre del anexo delante del nombre del archivo.
    				cv.Title = name + cv.Category_Type__c;
    				//cv.PathOnClient = cv.PathOnClient + ' - ' + cv.Category_Type__c;
                } else {
                    cv.Title = cv.Title + separator + cv.Category_Type__c;
                }
			}
        }

        system.debug('>>>>> triggerNew to update: ' + triggerNew);
	}


    //FUNCIÓN QUE RECORRE TRIGGER NEW Y ALMACENA LOS DATOS NECESARIOS COMO POR EJEMPLO SETS Y ALMACENA ALGUNOS DATOS QUE VAN A SER GLOBALES PARA TODA LA CLASE, COMO SET DE ID'S, LISTAS DE CUENTAS RELACIONADAS, ETC.
    private void getGlobalData(List<ContentVersion> triggerNew){
        //Guardo en un set de id's los id's de los content documents
        Set<Id> setDocsId = new Set<Id>();
        for(ContentVersion cv : triggerNew){
        	system.debug('>>>>> cv : ' + cv);
			if(!setDocsId.contains(cv.ContentDocumentId)){
				setDocsId.add(cv.ContentDocumentId);
				system.debug('>>>>> setDocsId : ' + setDocsId);
			}
        }

        Set<Id> setTemplatesId = new Set<Id>();
        system.debug('>>>>> setDocsId : ' + setDocsId);
        //Guardo en un mapa la relacion de ContentDocumentId - ContentDocumentLink (objeto)
        for(ContentDocumentLink cdl : [SELECT Id, ContentDocumentId, LinkedEntityId, LinkedEntity.Name FROM ContentDocumentLink WHERE ContentDocumentId IN :setDocsId]){
        	mapContDocRelEntity.put(cdl.ContentDocumentId, cdl);
        	if(mapContDocRelEntity.get(cdl.ContentDocumentId).LinkedEntityId.getSObjectType().getDescribe().getName() == Label.DES_Template_APIName
        	&& !setTemplatesId.contains(cdl.LinkedEntityId)){
        		setTemplatesId.add(cdl.LinkedEntityId);
        	}
        }
        system.debug('>>>>> mapContDocRelEntity : ' + mapContDocRelEntity);

        mapTemplatesRelated = new Map<Id, DES_Template__c>([
        	SELECT Id,
        			opportunity_id__c,
        			opportunity_id__r.Name
        	FROM DES_Template__c
        ]);
        system.debug('>>>>> mapTemplatesRelated : ' + mapTemplatesRelated);

    }//FIN getGlobalData
}