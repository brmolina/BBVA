/**
* ------------------------------------------------------------------------------------------------
* @Name     Arc_Gen_CorpRenewal_Controller
* @Author   amunguia@bbva.com
* @Date     Created: 2022-02-24
* @Group    ARCE
* ------------------------------------------------------------------------------------------------
* @Description: Arc_Gen_CorpRenewal_Controller
* ------------------------------------------------------------------------------------------------
* @Changes
*
* |2022-02-24 amunguia@bbva.com.
*              Class creation.
* ------------------------------------------------------------------------------------------------
*/
public with sharing class Arc_Gen_CorpRenewal_Controller {
    /**
    * @Description: 'text' literal
    */
    static final string TEXT_LIT = 'text';
    /**
    * @Description: 'type' literal
    */
    static final string TYPE_LIT = 'type';
    /**
    * @Description: 'fieldname' literal
    */
    static final string FIELDNAME_LIT = 'fieldName';
    /**
    * @Description: 'label' literal
    */
    static final string LABEL_LIT = 'label';
    /**
    *-------------------------------------------------------------------------------
    * @description empty constructor to sonar validations
    *--------------------------------------------------------------------------------
    * @date		21/03/2022
    * @author	amunguia.contractor@bbva.com
    */
    @TestVisible
    private Arc_Gen_CorpRenewal_Controller() {

    }
    /**
    * @description fetchAccounts
    * @author amunguia.contractor@bbva.com | 03-21-2022
    * @param String recordId
    * @return List<ClientData>
    **/
    @AuraEnabled
    public static List <ClientData> fetchAccounts(String recordId) {
        final List <ClientData> result = new List <ClientData>();
        final List<arce.Arc_Gen_Account_Has_Analysis_Wrapper> arceCom = arce.Arc_Gen_AccHasAnalysis_Data.getARCEClientData(new Set<String>{recordId});

        if(!arceCom.isEmpty()) {
            for(arce.Arc_Gen_Account_Has_Analysis_Wrapper aux : arceCom) {
                result.add(parseDatas(aux));
            }
        }
        return result;
    }

    /**
    * @description parseDatas
    * @author amunguia.contractor@bbva.com | 03-21-2022
    * @param arce.Arc_Gen_Account_Has_Analysis_Wrapper curr
    * @return ClientData
    **/
    public static ClientData parseDatas(arce.Arc_Gen_Account_Has_Analysis_Wrapper curr) {
        final ClientData result = new ClientData();
        result.ident = curr.ahaObj.Id;
        result.name = curr.ahaObj.arce__Analysis__r.Name;
        result.nameURL = '/lightning/r/arce__Analysis__c/' + curr.ahaObj.arce__Analysis__c +'/view';
        result.participantType = curr.ahaObj.arce__Analysis__r.arce__rating_prerating_type__c;
        result.finalizedBy = curr.ahaObj.arce__Analysis__r.LastModifiedBy.Name;
        result.finishDate = Arc_Gen_CorpRenewAnalysis.getValidtdDate(curr.ahaObj);
        result.rating = curr.ahaObj.arce__long_rating_value_type__c;
        result.dateEEFF = curr.ahaObj.arce__ffss_for_rating_id__r.arce__financial_statement_end_date__c;
        return result;

    }

    /**
    *----------------------------------------------------------------------------------------------------------------------------------------
    * @Description get Dynamic Columns
    *----------------------------------------------------------------------------------------------------------------------------------------
    * @Author   amunguia.contractor@bbva.com
    * @Date     Created: 2022-01-05
    * @param isRaip - Boolean
    * @return String - wrapper with the result of the operation
    * @example getDynamicColumns(isRaip) {
    * ---------------------------------------------------------------------------------------------------------------------------------------
    **/
    @AuraEnabled
    public static String buildDynamicColumns() {
        final JSONGenerator gen = JSON.createGenerator(false);
        gen.writeStartArray();

        gen.writeStartObject();
        gen.writeStringField(LABEL_LIT, 'Name');
        gen.writeStringField(FIELDNAME_LIT, 'nameURL');
        gen.writeBooleanField('wrapText', true);
        gen.writeStringField('iconName','utility:rating');
        gen.writeStringField(TYPE_LIT, 'url');
        gen.writeObjectField('typeAttributes', buildTypeAttributes('name'));
        gen.writeEndObject();

        gen.writeStartObject();
        gen.writeStringField(LABEL_LIT, 'Type');
        gen.writeStringField(FIELDNAME_LIT, 'participantType');
        gen.writeStringField(TYPE_LIT, TEXT_LIT);
        gen.writeEndObject();

        gen.writeStartObject();
        gen.writeStringField(LABEL_LIT, 'Rating');
        gen.writeStringField(FIELDNAME_LIT, 'rating');
        gen.writeStringField(TYPE_LIT, TEXT_LIT);
        gen.writeEndObject();

        gen.writeStartObject();
        gen.writeStringField(LABEL_LIT, 'Finalized By');
        gen.writeStringField(FIELDNAME_LIT, 'finalizedBy');
        gen.writeStringField(TYPE_LIT, TEXT_LIT);
        gen.writeEndObject();

        gen.writeStartObject();
        gen.writeStringField(LABEL_LIT, 'End Date');
        gen.writeStringField(FIELDNAME_LIT, 'finishDate');
        gen.writeStringField(TYPE_LIT, 'Date');
        gen.writeEndObject();

        gen.writeEndArray();
        return gen.getAsString();
    }
    /**
    * @Description: ClientData wrapper
    */
    public class ClientData {
        /**
        * @Description: Indicates name of the customer
        */
        @AuraEnabled public String ident {get;set;}
        /**
        * @Description: Indicates if the numeber of the customer
        */
        @AuraEnabled public String name {get;set;}
        /**
        * @Description: Indicates if the accNumber of the customer
        */
        @AuraEnabled public String finalizedBy {get;set;}
        /**
        * @Description: Indicates if the participantType of the customer
        */
        @AuraEnabled public String participantType {get;set;}
        /**
        * @Description: Indicates if the rating of the customer
        */
        @AuraEnabled public String rating {get;set;}
        /**
        * @Description: Indicates if the dateEEFF of the customer
        */
        @AuraEnabled public Date dateEEFF {get;set;}
        /**
        * @Description: Indicates if the state of the customer
        */
        @AuraEnabled public Date finishDate {get;set;}
        /**
        * @Description: Indicates if the nameURL of the customer
        */
        @AuraEnabled public String nameURL {get;set;}
    }
    /**
    * @Description: TypeAttribute wrapper
    */
    private class TypeAttribute {
        /**
        * @Description: Indicates name of the customer
        */
        private Map<String, String> label {get;set;}
        /**
        * @Description: Indicates if the numeber of the customer
        */
        private String target {get;set;}
    }
    /**
    * @description buildTypeAttributes
    * @author amunguia.contractor@bbva.com | 04-21-2022
    * @param String fieldName
    * @return TypeAttribute
    **/
    private static TypeAttribute buildTypeAttributes(String fieldName) {
        final TypeAttribute result = new TypeAttribute();
        result.label = new Map<String, String>{'fieldName'=> fieldName};
        result.target = '_blank';
        return result;
    }
}