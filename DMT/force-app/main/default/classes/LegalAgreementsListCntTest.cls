/*
* @author Global Desktop
* @name LegalAgreementsListCntTest
* @description Test de la clase apex LegalAgreementsListCnt
*/
@isTest
public class LegalAgreementsListCntTest {
	
	/**
	* @author Global Desktop
	* @description Test de la clase AlertsRelatedListCnt
	*/
	@IsTest
	public static void testMethod1() {
		
		/*Instancia de la clase DES_UtilTestClass*/
		final DES_UtilTestClass utilTestClass = new DES_UtilTestClass();
		
		final Account acc = utilTestClass.createClient();
		insert acc;
		
		Contrato_Marco__c cm1 = new Contrato_Marco__c();
		cm1.participant_id__c = '0015800001FOZdBAWQ';
		cm1.Name = 'Contrato marco 1';
		cm1.participant_id__c = acc.Id;
		cm1.gf_agree_annex_typo_desc__c = 'CSAENGLAW';
		cm1.master_agreement_type__c = 'CMOF09';
		cm1.star_counterparty_oper_desc__c = 'Counterparty 1';
		cm1.bbva_entity_name__c = 'Entity 1';
		cm1.gf_deal_signing_date__c = system.today();
		cm1.gf_agree_version_id__c = 'V1';
        //VERSION
		insert cm1;
		
		Test.StartTest();
        LegalAgreementsListCnt.relateContratos('5',acc.Id);
        //LegalAgreementsListCnt.relatedAlerts(null,acc.Id);
        system.assertNotEquals(cm1,null,'Correcto');
        Test.StopTest();
		
	}
	
}