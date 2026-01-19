/*-------------------------------------------------------------------------
 * Name: OpportunityTraceability_cls
 * Description : Class to audit Sanction risk ,sanction price and Formalization
 * Created date : June 11 2018
 * Developer name: Isaías Velázquez Cortés Indra(México)
--------------------------------------------------------------------------*/
public without sharing class OpportunityTraceability_cls {


	public void addOpportunityTraceability(String AudtiName,String Comments,String ObjectAPIName,String IdObject,String AuditStyleType,String AuditTypeIdCMP,String IdUser,string DisplayType,Integer Order,Boolean Detail) {
		
		dwp_cvad__Action_Audit__c row =new dwp_cvad__Action_Audit__c();

		row.dwp_cvad__action_audit_name__c=AudtiName;
		
        if(!String.isEmpty(Comments) && Comments.length()>35){
            string valu =Comments.substring(0,35)+ '...';
            row.dwp_cvad__audit_audit_comments__c=valu.stripHtmlTags();
        }
		else
			row.dwp_cvad__audit_audit_comments__c=Comments.stripHtmlTags();

		row.dwp_cvad__action_audit_object_api_name__c=ObjectAPIName;
		row.dwp_cvad__action_audit_record_id__c=IdObject;
		row.dwp_cvad__action_audit_style__c=AuditStyleType;
		row.dwp_cvad__action_audit_date__c=DateTime.now();
		row.dwp_cvad__action_audit_type__c=AuditTypeIdCMP;
		row.dwp_cvad__action_audit_user_id__c=IdUser;

		insert row;
		if(Detail)
			addOpportunityTraceabilityDetail(row.Id,Comments,'HTML',Order,AudtiName,DisplayType);
	}

	private void addOpportunityTraceabilityDetail(String AudtiId,String Content,String ContentFormat,Integer Order,String AuditTitle,String DisplayType) {
		dwp_cvad__Action_Audit_Detail__c row= new dwp_cvad__Action_Audit_Detail__c();

		row.dwp_cvad__action_audit_id__c=AudtiId;
		row.dwp_cvad__action_audit_detail_content__c=Content;
		row.dwp_cvad__action_audit_detail_display_order__c=Order;
		row.dwp_cvad__action_audit_detail_display_title__c=AuditTitle;
		row.dwp_cvad__action_audit_detail_display_type__c=DisplayType;
		insert row;
	}

}