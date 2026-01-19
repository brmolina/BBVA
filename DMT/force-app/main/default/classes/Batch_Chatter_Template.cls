/**********************************************************************************
* @author
* @date
* @description  Batch para generar el objeto Chatter en los templates ya creados
* @Revision
**********************************************************************************/
public without sharing class Batch_Chatter_Template implements Database.Batchable<Sobject>, Database.Stateful {
  /*
  * Query attribute
  */
  private final String query = 'SELECT id, Name FROM DES_Template__c' + (Test.isRunningTest() ? ' LIMIT 2' : '');

  /*
  * Lanza Batch para agrefar el objeto Chatter a los template que no lo tengan
  */
  public Batch_Chatter_Template() {
    system.debug('>>>>> Query: ' + query);
  }
  /*
  * Lanza Batch para agrefar el objeto Chatter a los template que no lo tengan
  */
  public Database.QueryLocator start(Database.BatchableContext bc1) {
    system.debug('>>>>> query : ' + query);
    return Database.getQueryLocator(query);
  }
  /*
  * Lanza Batch para agrefar el objeto Chatter a los template que no lo tengan
  */
  public void execute(Database.BatchableContext bc1, List<DES_Template__c> listTemplate) {
    List<Id> listID;
    listID = new List<Id>();
    List<Chatter_NBC_Virtual__c> lstChatterNew;
    lstChatterNew = new List<Chatter_NBC_Virtual__c>();
    Map<Id, Chatter_NBC_Virtual__c> tempChat;
    tempChat = new Map<Id, Chatter_NBC_Virtual__c>();

    for(DES_Template__c temp : listTemplate) {
      listID.add(temp.id);
    }

    final List<Chatter_NBC_Virtual__c> lstChatter = [SELECT id, id_objeto__c FROM 	Chatter_NBC_Virtual__c WHERE id_objeto__c = :listID];

    for(DES_Template__c temp : listTemplate) {
      for(Chatter_NBC_Virtual__c chatter : lstChatter) {
        if(chatter.id_objeto__c == temp.id) {
          tempChat.put(temp.id, chatter);
        }
      }
    }
    for(DES_Template__c temp : listTemplate) {
      if(!tempChat.containsKey(temp.Id)) {
        Chatter_NBC_Virtual__c chat;
        chat = new Chatter_NBC_Virtual__c();
        chat.id_objeto__c = temp.Id;
        chat.tipo_objeto__c = Label.DES_Template_APIName;
        lstChatterNew.add(chat);
      }
    }

    Database.insert(lstChatterNew,false);
  }
  /*
  * Lanza Batch para agrefar el objeto Chatter a los template que no lo tengan
  */
  public void finish(Database.BatchableContext bc1) {
    final AsyncApexJob job = [SELECT Id, Status, NumberOfErrors, JobItemsProcessed, TotalJobItems, CreatedBy.Email FROM AsyncApexJob WHERE Id = :bc1.getJobId()];
    system.debug('++ job ' + job);
  }
}