/**
* ────────────────────────────────────────────────────────────────────────────────────
* DPMX_NewDPWithouFamily_ctrl_Test
* Test class for DPMX_NewDynamicPricing_Ctrl apex class
* ────────────────────────────────────────────────────────────────────────────────────
* @author      Cosme Alcázar <cosme.alcazar.contractor@bbva.com>
* @modifiedBy
* @version     1.0
* @created     2024-02-01
* @modified
* @systemLayer Test
* ────────────────────────────────────────────────────────────────────────────────────
* @changes
*
* ────────────────────────────────────────────────────────────────────────────────────
*/
@IsTest
public class DPMX_NewDPWithouFamily_ctrl_Test {
    
    @TestSetup
    static void createData() {
    }
    
    @IsTest
    static void getInitialData(){   
        Test.startTest();
        	Map<String, Object> retMap = DPMX_NewDPWithouFamily_ctrl.getInitialData(); 
            System.assertEquals(retMap.get('isCustom'), true ,'getInitialData OK');
        	Test.stopTest();
    }
    
    @IsTest
    static void saveDynamicPricingTest(){  
        DPMX_Dynamic_Pricing__c newDycPrg = new DPMX_Dynamic_Pricing__c();
        newDycPrg.Name = 'Dynamic Pricing Test';
        newDycPrg.Product__c = 'Acquirer';
        newDycPrg.familia__c = 'Otro';
        newDycPrg.familia_AcquiererCategories_Id__c = '13';
        String newDycPrgJSON = JSON.serialize(newDycPrg);
        insert newDycPrg;

        Test.startTest();
            Map<String, Object> retMap = DPMX_NewDPWithouFamily_ctrl.saveDynamicPricing(newDycPrgJSON, 'Otro' ,'13', true); 
            System.assertEquals(retMap.get('success'), true,'saveDynamicPricingTest OK');

        Test.stopTest();
    }

}