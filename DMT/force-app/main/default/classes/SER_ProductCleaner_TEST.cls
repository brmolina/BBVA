/**
* Clase de TEST para las clases SER_ProductCleaner_BATCH y SER_ProductCleaner_JOB
*/
@isTest
public class SER_ProductCleaner_TEST {

  /**
  * Method auxiliar para crear los productos necesarios para el método de Test
  */
  private static void createData() {
    final List<SER_Transactional__c> productList = new List<SER_Transactional__c>();
    final Date cancellationDte = date.newinstance(2018, 6, 10);

    final SER_Transactional__c product1 = new SER_Transactional__c();
    product1.Name = 'product1';
    product1.SER_Product_Text__c = 'product1';
    product1.SER_Product_Status__c = 'CANCELADO';
    product1.SER_Product_Cancellation_Date__c = cancellationDte;
    productList.add(product1);

    final SER_Transactional__c product2 = new SER_Transactional__c();
    product2.Name = 'product2';
    product2.SER_Product_Text__c = 'product2';
    product2.SER_Product_Status__c = 'BAJA';
    product2.SER_Product_Cancellation_Date__c = cancellationDte;
    productList.add(product2);

    final SER_Transactional__c product3 = new SER_Transactional__c();
    product3.Name = 'product3';
    product3.SER_Product_Text__c = 'product3';
    product3.SER_Product_Status__c = 'CANCELADO';
    product3.SER_Product_Cancellation_Date__c = cancellationDte;
    productList.add(product3);

    insert productList;
  }

  /**
  * Method para testear las clases SER_ProductCleaner_BATCH y SER_ProductCleaner_JOB
  */
  @isTest
  static void productCleanerTest1() {
    createData();
    Test.startTest();
    final SER_ProductCleaner_JOB job = new SER_ProductCleaner_JOB();
    String sch;
    sch = '0 0 0 * * ?';
    final String jobId = System.schedule('Product cleaner batch', sch, job);
    final List<SER_Transactional__c> productList = [select Id from SER_Transactional__c
                                                    where (SER_Product_Status__c = 'CANCELADO' OR SER_Product_Status__c = 'BAJA')
                                                    AND SER_Product_Cancellation_Date_FORMULA__c < LAST_90_DAYS];
    System.debug('-----------------------' + productList);
    System.assertEquals(0, [SELECT TimesTriggered FROM CronTrigger WHERE id = : jobId].TimesTriggered, 'Error');

    final SER_ProductCleaner_JOB job2 = new SER_ProductCleaner_JOB();
    job2.execute(null, 'select Id from SER_Transactional__c');
    Test.stopTest();
  }

}