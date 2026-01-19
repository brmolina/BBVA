/**********************************************************************************
* @author       Global Desktop
* @date         15/03/2019
* @description  Test de la case BatchUpdateParentAccount
* @Revision

Version        Date            Author            Summary of changes
-------------------------------------------------------------------------------------
0.1            15/03/2020      Global Desktop    Testeo de la clase BatchUpdateParentAccount
**********************************************************************************/
@isTest
public class Batch_UpdateParentAccount_Test {

  /**
  * @author Global Desktop
  * @description Test de la clase BatchUpdateParentAccount
  */
  @isTest
  public static void batch1() {
    Test.startTest();
    final DES_UtilTestClass utilTestClass = new DES_UtilTestClass();

    List<Account> lstGroup;
    lstGroup = new List<Account>();
    List<Account> lstFilial;
    lstFilial = new List<Account>();
    //Creacion grupo
    final Account accGroup = utilTestClass.createClient();
    accGroup.DES_Structure_Type__c = 'Group';
    accGroup.DES_BBVA_Segmentation__c = 'C';
    lstGroup.add(accGroup);
    final Account accGroup0 = utilTestClass.createClient();
    accGroup0.DES_Structure_Type__c = 'Group';
    accGroup0.DES_BBVA_Segmentation__c = 'C';
    lstGroup.add(accGroup0);
    insert lstGroup;

    //Creacion grupo
    final Account accGroup2 = utilTestClass.createClient();
    accGroup2.DES_Entity_Hierarchy__c ='S';
    accGroup2.DES_Main_Parent__c =accGroup.id;
    lstFilial.add(accGroup2);

    //Creacion grupo
    final Account accGroup3 = utilTestClass.createClient();
    accGroup3.DES_Entity_Hierarchy__c ='S';
    accGroup3.DES_Subsidiary_Group_Code__c = 'Prueba';
    accGroup3.DES_Main_Parent__c =accGroup.id;
    lstFilial.add(accGroup3);

    //Creacion grupo
    final Account accGroup4 = utilTestClass.createClient();
    accGroup4.DES_Entity_Hierarchy__c ='S';
    accGroup4.DES_Subsidiary_Group_Code__c = 'Prueba';
    accGroup4.DES_Main_Parent__c =accGroup0.id;
    lstFilial.add(accGroup4);

    insert lstFilial;

    //actualiza los parent de los grupos
    final Batch_UpdateParentAccount batchPrntAcc = new Batch_UpdateParentAccount();
    final Id batchId = Database.executeBatch(batchPrntAcc,200);
    System.Assert(batchId<>null,'error');
    Test.stopTest();
  }

  /**
  * @author Global Desktop
  * @description Test de la clase BatchUpdateParentAccount
  */
  @isTest
  public static void batch2() {
    Test.startTest();
    final DES_UtilTestClass utilTestClass = new DES_UtilTestClass();

    //Creacion grupo
    final Account accGroup = utilTestClass.createClient();
    accGroup.DES_Structure_Type__c = 'Group';
    accGroup.DES_BBVA_Segmentation__c = 'C';
    insert accGroup;

    //Creacion grupo
    final Account accGroup2 = utilTestClass.createClient();
    accGroup2.DES_Entity_Hierarchy__c ='S';
    accGroup2.DES_Subsidiary_Group_Code__c = 'Prueba';
    insert accGroup2;

    //actualiza los parent de los grupos
    final Batch_UpdateParentAccount batchPrntAcc = new Batch_UpdateParentAccount();
    final Id batchId = Database.executeBatch(batchPrntAcc,200);
    System.Assert(batchId<>null,'error');
    Test.stopTest();
  }

}