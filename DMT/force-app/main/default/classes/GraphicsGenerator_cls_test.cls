/**
*Developed by:       	Indra
*Autor:                 Isaías Velázquez
*Project:               DWP Sales
*Description:           Test Class to handle GraphicsGenerator_cls.
*
*Changes (Version)       
*No.        CreationDate            Autor                      Description
*-------------------------------------------------------------------------------
*------   ----------------   --------------------   ----------------------------
*1.0       	19-03-2018        Isaías Velázquez                   Creation
*
*Modificado por Eduardo Castillo Sunahata 02-10-2018
*
**/
@isTest
public class GraphicsGenerator_cls_test {
	


	@isTest static void TestSBSGrafica(){
	    final Desktop_Utils util = Desktop_Utils.getInstance();
	    User u = new User();
	    u.Username = util.getRandNumber() + '@test.comm';
	    u.LastName = 'uLast2';
	    u.Email = 'u2@u.com';
	    u.Alias = 'uAlias2';
		u.ID_User__c = util.getRandNumber();
	    u.CommunityNickname = util.getRandNumber();
	    u.TimeZoneSidKey = 'America/Mexico_City';
	    u.LocaleSidKey = 'en_US';
	    u.EmailEncodingKey = 'ISO-8859-1';
	    u.ProfileId=  userinfo.getProfileId();
	    u.LanguageLocaleKey='en_US';
	    insert u;

	    Local_Client__c ac = TestFactory.createLocalClient();

	    Account_Banking_System_Debt__c sbs = new Account_Banking_System_Debt__c();        
	    sbs.debt_quote_amount__c=100;
	    sbs.entity_name__c='BBVA';
	    sbs.year_month_day_date__c=Date.today().addMonths(-1);
	    sbs.Local_Client_id__c=ac.Id;
	    insert sbs;


	    Account_Banking_System_Debt__c sbs1 = new Account_Banking_System_Debt__c();        
	    sbs1.debt_quote_amount__c=200;
	    sbs1.entity_name__c='BBVA';
	    sbs1.year_month_day_date__c=Date.today().addMonths(-1);
	    sbs1.Local_Client_id__c=ac.Id;
	    insert sbs1;

   	    Account_Indicator__c v1 = new Account_Indicator__c();        
	    v1.indicator_num__c=3;
	    v1.indicator_name__c='Celeste';
	    v1.year_month_day_date__c=Date.today().addMonths(-1);
	    v1.Local_Client_id__c=ac.Id;
	    insert v1;
	    
	    test.startTest();
	    System.runAs(u){                       
			GraphicsGenerator_cls.getGeneraJSONReporte('EVOLUCION_CUOTA_SBS','Total','2017',ac.Id);
			GraphicsGenerator_cls.getGeneraJSONReporte('EVOLUCION_CUOTA_SBS','Indirecta','2017',ac.Id);
			GraphicsGenerator_cls.getGeneraJSONReporte('EVOLUCION_CUOTA_SBS','Directa','2017',ac.Id);
			GraphicsGenerator_cls.getGeneraJSONReporte('EVOLUCION_CUOTA_SBS','Otros directas','2017',ac.Id);
			GraphicsGenerator_cls.getGeneraJSONReporte('EVOLUCION_CUOTA_SBS','Otros indirectas','2017',ac.Id);
			GraphicsGenerator_cls.getGeneraJSONReporte('EVOLUCION_CUOTA_SBS','','2017',ac.Id);
			GraphicsGenerator_cls.getGeneraJSONReporte('VINCULACION','','2017',ac.Id);
	        System.assert(true,'This Works!');            
	    } 
	    test.stopTest();
	}


}