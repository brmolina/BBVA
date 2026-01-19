/**
 * @description       :
 * @author            : David Rodríguez
 * @group             :
 * @last modified on  : 05-05-2021
 * @last modified by  : David Rodríguez
 * Modifications Log
 * Ver   Date         Author            Modification
 * 1.0   04-20-2021   David Rodríguez   Initial Version
**/
@SuppressWarnings('sf:AvoidSoqlWithNegativeLogic')
public without sharing class MergeHasOpen {

  /**
  * SINGLETON PATTERN
  */
  private static MergeHasOpen instance;

  /**
  * Constructor
  */
  private MergeHasOpen() {
  }

  /**
  * getInstance
  */
  public static MergeHasOpen gtInstance() {
    if(instance == null) {
      instance = new MergeHasOpen();
    }
    return instance;
  }

  /*
  * Proceso de merge
  */
  @InvocableMethod(label='MergeHasOpen' description='Check if has ARCE Open')
  public static List<WrapperMerge> getOpenArce(List<WrapperMerge> mgList) {
    final List<WrapperMerge> outputList = new List<WrapperMerge>();
    final List<arce__Account_has_Analysis__c> aHaLocals = new List<arce__Account_has_Analysis__c>([
      SELECT Id, DES_Local_Client__c, arce__Customer__c, arce__Analysis__c
      FROM arce__Account_has_Analysis__c WHERE DES_Local_Client__c = :mgList[0].idLocalClient
    ]);

    final Set<Id> setArce = new Set<Id>();
    for(arce__Account_has_Analysis__c aHa : aHaLocals) {
      setArce.add(aHa.arce__Analysis__c);
    }

    final List<arce__Analysis__c> analysisLocal = new List<arce__Analysis__c>([
      SELECT Id
      FROM arce__Analysis__c
      WHERE Id IN :setArce AND arce__Stage__c != '3'
    ]);

    final WrapperMerge wrap = new WrapperMerge();
    //No tiene arces o tiene alguno abierto
    if(aHaLocals.isEmpty() || analysisLocal.isEmpty()) {
      wrap.hasOpen = false;
    } else {
      wrap.hasOpen = true;
    }
    outputList.add(wrap);
    return outputList;
  }

  /*
  * Entrada del method invocable addMemberGroup
  */
  public class WrapperMerge {
    /**
    * Id del localClient
    */
    @InvocableVariable(label='Id del cliente local' required=false)
    public String idLocalClient; //NOSONAR

    /**
    * Tiene Arces
    */
    @InvocableVariable(label='Tiene ARCE abierto' required=false)
    public Boolean hasOpen; //NOSONAR
  }
}