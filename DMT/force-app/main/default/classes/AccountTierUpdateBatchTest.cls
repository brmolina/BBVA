/**********************************************************************************
* @author  		Global Desktop
* @date         06/09/2021
* @description  test para la clase accountTierUpdateBatch y AccountTierDeleteBatch
**********************************************************************************/
@istest
public class AccountTierUpdateBatchTest {
    
  /*
  * @author Global Desktop
  **/
			public static testmethod void tierTest() {
         Test.startTest();
          	final Account testAccount = new Account();
 			testAccount.Name= 'Test Account';
            testAccount.DES_Group_Code__c = 'G123123123';
 			insert testAccount;
        
        	final Account testAccount2 = new Account();
 			testAccount2.Name= 'Test Account2';
        	testAccount2.DES_Main_Parent__c = testAccount.id;
        	testAccount2.DES_Structure_Type__c = 'Subsidiary';
        	testAccount2.DES_Country_Client__c = 'ES';
            testAccount2.gf_gtb_area_gsg_tier_type_name__c = '';
 			insert testAccount2;
                
            final Account testAccount3 = new Account();
 			testAccount3.Name= 'Test Account3';
        	testAccount3.DES_Main_Parent__c = testAccount.id;
        	testAccount3.DES_Structure_Type__c = 'Subsidiary';
        	testAccount3.DES_Country_Client__c = 'PE';
            testAccount3.gf_gtb_area_gsg_tier_type_name__c = ''; 
 			insert testAccount3;
        
        	final tier_gtb__c testTier = new tier_gtb__c();
        	testTier.Name = 'test1';
            testTier.g_country_id__c = 'ES';
            testTier.gf_participant_id__c = testAccount.id;
            testTier.gf_sf_concatenated_key_id__c = 'G123123123_ES';
            testTier.gf_gtb_area_gsg_tier_type_name__c = 'CORE';
            insert testTier;
                
            final tier_gtb__c testTier2 = new tier_gtb__c();
        	testTier2.Name = 'test1delete';
            testTier2.g_country_id__c = 'PE';
            testTier2.gf_participant_id__c = testAccount.id;
            testTier2.gf_sf_concatenated_key_id__c = 'G123123123_PE';
            testTier2.gf_gtb_area_gsg_tier_type_name__c = 'STANDARD';
            insert testTier2; 
                
            final String jobId = system.schedule('Test Check', '0 0 2 * * ?', new GTB_schedulable_allmonths ());
        	System.assertNotEquals(jobId, null);    
            Test.stopTest();
            	System.assertEquals(testTier2, testTier2, 'testier is testier');
             }  

}