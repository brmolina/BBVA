/**********************************************************************************
* @author       Accenture
* @date         
* @description  Batch para el borrado de DES_Group_Subsidiary_Matrix__c
* @Revision     
                03/12/2018 Se añade la instrucción después de cada borrado masivo para vaciar la papelera de reciclaje
**********************************************************************************/
public without sharing class DES_Batch_deleteGBMatrix implements Database.Batchable<Sobject>, Database.Stateful {
    
    private String pQuery;
    private Integer recordsProcessed = 0;
    
    public DES_Batch_deleteGBMatrix(){
        pQuery = 'SELECT Id FROM DES_Group_Subsidiary_Matrix__c';
    }
    
    public Database.QueryLocator start(Database.BatchableContext bc){
        return Database.getQueryLocator(pQuery);
    }

    public void execute(Database.BatchableContext bc,List<DES_Group_Subsidiary_Matrix__c> scope){
        if(!scope.isEmpty()){
            delete scope;
            Database.emptyRecycleBin(scope);
        }
        recordsProcessed+=scope.size();
    }
    
    public void finish(Database.BatchableContext bc){
    	Id batchInstanceId = Database.executeBatch(new DES_Batch_createGBMatrix(), 10);
    }

}