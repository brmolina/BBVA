/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 11-02-2022
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
@isTest
public class TestFactory {
    public static User createUser(String userName, String Perfil){
    	User u = new User();
        Double random = Math.random();
        u.Username=userName+'u2@u.com.u'+random;
		u.LastName=userName+'uLast2';
          u.Email=userName+'u2@u.com';
          u.Alias= String.valueOf(random).substring(0, 3)+'uAas2';
          u.TimeZoneSidKey='America/Mexico_City';
		  u.IsActive=true;
          u.LocaleSidKey='en_US';
          u.EmailEncodingKey='ISO-8859-1';
          List<Profile> prof=new List<Profile>([SELECT Id, Name FROM Profile where Name=:Perfil]);
          u.ProfileId=  prof[0].Id;
          u.LanguageLocaleKey='es';
          u.ID_User__c = 'Test' + userName.substring(0, 3) + String.valueOf(random).substring(0, 3);
          insert u;
    	return u;
    }
    
    //Eduardo Castillo S. Método creado para OpportunityPDFWrap
    public static User createUser_1(String userName, String Perfil){
    	User u = new User();
        Double random = Math.random();
        u.Username=userName+'u2@u.com.u'+random;
		u.LastName=userName+'uLast2';
          u.Email=userName+'u2@u.com';
          u.Alias= String.valueOf(random).substring(0, 3)+'uAas2';
	      u.TimeZoneSidKey='America/Lima';
		  u.IsActive=true;
          u.LocaleSidKey='es_PE';
          u.EmailEncodingKey='ISO-8859-1';
          List<Profile> prof=new List<Profile>([SELECT Id, Name FROM Profile where Name=:Perfil]);
          u.ProfileId=  prof[0].Id;
          u.LanguageLocaleKey='es';
          insert u;
    	return u;
    }
    
   public static OpportunityLineItem_Local__c createOpportunity(Id accountId,Id userId){
    	OpportunityLineItem_Local__c opp = new OpportunityLineItem_Local__c(ownerId=userId,Name='testopp', Local_Client_id__c=accountId,StageName__c='01',Amount__c=100 ,CloseDate__c=system.Date.today(),opportunity_status_type__c='01');
    	insert opp;
        return opp;
    }

    public static Attachment createAttachment(Id parentId, String attachmentName){
    	Attachment attach=new Attachment(); 
        attach.Name= attachmentName; 
        Blob bodyBlob=Blob.valueOf('Unit Test Attachment Body'); 
        attach.body=bodyBlob; 
        attach.parentId=parentId; 
        attach.ContentType = 'application/msword'; 
        attach.IsPrivate = false; 
        attach.Description = 'Test'; 
        insert attach; 
    	return attach;
    
	}
    public static Product2Local__c createProduct (){
        Product2Local__c prod = new Product2Local__c(Name = 'Swift',
                                     Family__c = 'Credit');
        insert prod;
        return prod;
    }

    public static OpportunityLineItem_Local__c createOLI (Id oppId,Id prodId){
        Id pricebookId = Test.getStandardPricebookId();

        PricebookEntry_Local__c standardPrice = new PricebookEntry_Local__c(Pricebook2id__c = pricebookId, Product2id__c = prodId,unitPrice__c = 10000, isActive__c = true);
        insert standardPrice;

        Pricebook2 customPB = new Pricebook2(Name='PriceBook', IsActive=true);
        insert customPB;

        PricebookEntry_Local__c customPrice = new PricebookEntry_Local__c(
        Pricebook2id__c = customPB.Id, Product2id__c = prodId,
        unitPrice__c = 12000, isActive__c = true);
        insert customPrice;

        OpportunityLineItem_Local__c oli = New OpportunityLineItem_Local__c(OpportunityId__c=oppId ,Quantity__c=1,TotalPrice__c=10.00,pricebookentryid__c=customPrice.Id,product2Id__c=prodId);
        insert oli;
        return oli;
    }

    public static Local_Client__c createLocalClient(){
        DES_UtilTestClass testClass = new DES_UtilTestClass();
        Account client = testClass.createClient();
        insert client;
	
        Local_Client__c acc=new Local_Client__c(Name = 'TestAcct',Cib_Client__c = client.Id, Alpha_code__c = 'ES' + Integer.valueof((Math.random() * 100000)));
        insert acc;
        return acc;
    }

    public static Account_BBVA_Classification__c createAccBBVAClass(Id acc){
        Account_BBVA_Classification__c accClass = new  Account_BBVA_Classification__c(Local_Client_id__c=acc);
        insert accClass;
        return accClass;
	}

	public static Account_Banking_System_Classification__c createAccBankingSystClass(Id acc){
        Account_Banking_System_Classification__c accClass = new  Account_Banking_System_Classification__c(Local_Client_id__c=acc);
        insert accClass;
        return accClass;
	}

    public static Contact createContact(Id acc){
        Contact c = new  Contact(AccountId=acc,LastName='test',FirstName='test');
        insert c;
        return c;
	}

    public static Commit_Inter_Garant__c createParticipants (Id oppId){
    	Commit_Inter_Garant__c part = new Commit_Inter_Garant__c (Name='Test', GBL_Opportunity_product__c='IDOP');
        insert part;
        return part;
    }

    public static Commit_Inter_Garant__c createGuarantee (Id oppId){
        Commit_Inter_Garant__c guarant = new Commit_Inter_Garant__c (GBL_Opportunity_product__c='IDOP');
        insert guarant;
        return guarant;
    }
    /**
    *Method Created: Local_Visit__c
    **/
     public static Local_Visit__c createVisitKit (){
        Local_Visit__c visit = new Local_Visit__c();
        visit.visit_duration_number__c='2';
        visit.visit_start_date__c=system.today();
        insert visit;
        return visit;
    }
    /**
    *Method Created: Visit_Contact_Local__c
    **/
    public static Visit_Contact_Local__c VisitConta(Id visit, Id contact)
    {
        Visit_Contact_Local__c visitConta = new Visit_Contact_Local__c(visit_id__c=visit,contact_id__c=contact);
        insert visitConta;
        return visitConta;
    }
    /**
    *Method Created: Visit_Management_Team_Local__c 
    **/
    public static Visit_Management_Team_Local__c CreateVisitManagement(Id visitID,Id UserKit){
        Visit_Management_Team_Local__c kit_Manage = new Visit_Management_Team_Local__c (visit_id__c=visitID,
         user_id__c=UserKit);
        insert kit_Manage;
        return kit_Manage;
    }

    public static void createAccountProfit(Id Account){
        Account_Profitability__c	accp = new Account_Profitability__c(
        Local_Client_id__c=Account,
        profitability_type__c ='03',
        profitability_category_type__c = 'Comisiones'
        );
        insert accp;
        Datetime yesterday = Datetime.now().addDays(-1);
         Test.setCreatedDate(accp.Id, yesterday);
    }
    
    //ECS
    public static void createAccountProfit_1(Id Account){
        Account_Profitability__c	accp = new Account_Profitability__c(
        Local_Client_id__c=Account,
        profitability_type__c ='03',
        profitability_category_type__c = 'Comisiones',
       	year_month_day_date__c = date.newInstance(2018, 09, 06),
        currenct_mon_amount__c=15498.0
        );
        insert accp;
        Datetime yesterday = Datetime.now().addDays(-1);
        Test.setCreatedDate(accp.Id, yesterday);
    }
    
    public static Case createCase(Id userId){
        Case casetest = new Case();
        casetest.Status = 'New';
        casetest.OwnerId = userId;
        insert casetest;
        return casetest;
    }
    
    public static void productConfiguration(Id IDProduct){
     Product_Configuration_Local__c  PC = new Product_Configuration_Local__c(
     DeveloperName__c ='gipr_Periodicidad_PC00007',	
     LoV_labels__c ='Días,Meses',		
     Map_field__c ='gipr_Periodicidad__c',
     Product__c =IDProduct,		
     Section_name__c ='Criterios de pago y liquidación',
     Visibility_control_field__c ='gipr_Tipo_garantia_PC00005', 	
     Visibility_control_value__c ='No dineraria,Dineraria' 
     ); 
     Insert PC;
    }
    
    //Eduardo Castillo S. Método creado para OpportunityPDFWrap_Test
    public static void productConfiguration_1(Id IDProduct){
     Product_Configuration_Local__c  PC = new Product_Configuration_Local__c(
     DeveloperName__c ='gipr_Tipo_garantia_PC00005',
     LoV_labels__c ='Días,Meses',	
     Map_field__c ='gipr_Periodicidad__c',
     Product__c =IDProduct,	
     Section_name__c ='Criterios de pago y liquidación',	
     Visibility_control_field__c ='gipr_Tipo_garantia_PC00005', 	
     Visibility_control_value__c ='No dineraria,Dineraria' 
     ); 
     Insert PC;
    }
    
    //Eduardo Castillo S. Método creado para OpportunityPDFWrap_Test
    public static List<dwp_cvad__Action_Audit__c> create_Action_Audit(String idopp){
        List<dwp_cvad__Action_Audit__c> action_audit_list = new List<dwp_cvad__Action_Audit__c>();
        for(integer i=0;i<2;i++){
            dwp_cvad__Action_Audit__c obj = new dwp_cvad__Action_Audit__c();
            if(i==0){
            	obj.dwp_cvad__action_audit_name__c = 'Autorizado por precios'; 
            } else {
                obj.dwp_cvad__action_audit_name__c='Autorizado por riesgos';
            }
            obj.DWP_CVAD__ACTION_AUDIT_RECORD_ID__C = idopp;
            obj.dwp_cvad__action_audit_object_api_name__c = 'Opportunity';
            obj.dwp_cvad__action_audit_style__c = 'restudy';
            obj.dwp_cvad__action_audit_type__c = 'Price Approval';
            obj.CurrencyIsoCode = 'PEN';
            action_audit_list.add(obj);
        }
        insert action_audit_list;
        return action_audit_list;
    }
    
    //Eduardo Castillo S. Método creado para OpportunityPDFWrap_Test
    public static void create_Action_Audit_Detail(String action_audit_id){
        dwp_cvad__Action_Audit_Detail__c action_audit_d_list = new dwp_cvad__Action_Audit_Detail__c();
		action_audit_d_list.dwp_cvad__action_audit_id__c = action_audit_id;	
        action_audit_d_list.dwp_cvad__action_audit_detail_content__c = 'Comentarios de prueba';
        action_audit_d_list.dwp_cvad__action_audit_detail_display_order__c = 1.0;
        action_audit_d_list.dwp_cvad__action_audit_detail_display_type__c = 'Price Approval';
        insert action_audit_d_list;
    }
    
    //Eduardo Castillo S. Método creado para OpportunityPDFWrap_Test
    public static void create_guarantee(String id){
        Commit_Inter_Garant__c obj = new Commit_Inter_Garant__c();
        obj.GBL_Opportunity_product__c = id;
        insert obj;
    }

}