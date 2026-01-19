/**
* @File Name          : Arc_Gen_RatingStudiesTabSet_data.cls
* @Description        :
* @Author             : juanignacio.hita.contractor@bbva.com
* @Group              : ARCE Team
* @Last Modified By   : juanignacio.hita.contractor@bbva.com
* @Last Modified On   : 16/09/2020
* @Changes   :
* Ver       Date            Author      		    Modification
* 1.0    27/07/2020   juanignacio.hita.contractor@bbva.com     Initial Version
* 1.1    16/09/2020   juanignacio.hita.contractor@bbva.com     Change rating_status field to status_type in getListEEFF
* 1.2    21/10/2020   joseluis.garcia4.contractor@bbva.com     Add arce__ffss_auditor_qlfn_type__c field to query.
* 1.3    27/04/2021   javier.soto.carrascosa@bbva.com     Add validate status to query
**/
public with sharing class Arc_Gen_RatingStudiesTabSet_data {

    /**
    * @description: Empty constructor
    **/
    @TestVisible
    private Arc_Gen_RatingStudiesTabSet_data() {

    }
    /**
    *-------------------------------------------------------------------------------
    * @description Method that get a financial statement
    --------------------------------------------------------------------------------
    * @author juanignacio.hita.contractor@bbva.com
    * @date   31/07/2020
    * @param  List<String> ffssId : a list with id of the financial statements
    * @return List<arce__Financial_Statements__c> : returns a list of financial statement
    * @example List<arce__Financial_Statements__c> ffss = getListEEFF(ids);
    **/
    public static List<arce__Financial_Statements__c> getListEEFF(List<String> ffssIds) {
        return [SELECT arce__economic_month_info_number__c, arce__rating_type_code_id__c, arce__rating_user_id__c, arce__ffss_auditor_opinion_type__c,
        arce__financial_statement_end_date__c, arce__ffss_certification_type__c, arce__rating_final__c, arce__rating_long_value_type__c, arce__ffss_adjusted_type__c,
        arce__ffss_submitted_type__c, arce__rating_status__c,arce__financial_statement_id__c,arce__ffss_auditor_qlfn_type__c
        FROM arce__Financial_Statements__c
        WHERE Id IN :ffssIds AND arce__rating_id__r.arce__status_type__c in ('2', '3')
        ORDER BY arce__financial_statement_end_date__c ASC];
    }
}