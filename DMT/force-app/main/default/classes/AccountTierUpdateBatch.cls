/**********************************************************************************
* @author  		Global Desktop
* @date         06/09/2021
* @description  Batch que actualiza el campo GTB tier de las subsidiarias
**********************************************************************************/
public without sharing class AccountTierUpdateBatch implements Database.Batchable<Sobject>, Database.Stateful {
	/*
   *  VARIABLE
  **/
  private List<sObject> myList; //NOSONAR

  /*
   *  CONSTRUCTOR
  **/
  public accountTierUpdateBatch (List<sObject> objList) {
    myList = objList;
    system.debug('>>>>> myList : ' + myList);
  }

  /*
   *  start
  **/
  public Iterable<sObject> start(Database.BatchableContext batchCntx) {
    return myList;
  }


  /*
   *  execute
  **/
  public void execute(Database.BatchableContext batchCntx, List<sObject> objetos) {
	Update objetos;

  }//FIN execute

  /*
   *  finish
  **/
  public void finish(Database.BatchableContext batchCntx) {    }


}