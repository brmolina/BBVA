/**
* ------------------------------------------------------------------------------------------------
* @Name     GDT_Arc_Gen_Hierarchy_Controller
* @Author   amunguia@bbva.com
* @Date     Created: 2022-02-24
* @Group    ARCE
* ------------------------------------------------------------------------------------------------
* @Description: GDT_Arc_Gen_Hierarchy_Controller
* ------------------------------------------------------------------------------------------------
* @Changes
*
* |2022-02-24 amunguia@bbva.com.
*              Class creation.
* |2023-03-29 nerea.ortiz.penalosa.contractor@bbva.com.
*              Removal of Booking Country Code column in buildDynamicColumns method.
*              Only most recent rating per Account is retrieved in fetchAccounts method.
*              ClientData dateEEFF population logic changed in methods parseDatas and getClientDataDate
* ------------------------------------------------------------------------------------------------
*/
@SuppressWarnings('PMD.AvoidGlobalModifier')
global with sharing class GDT_Arc_Gen_Hierarchy_Controller {
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
    * @Description: 'label' sortable
    */
    static final string SORTABLE_LIT = 'sortable';
    /**
    * @Description: Object name of the 'accounts' nodes
    */
    static string objName;
    /**
    * @Description: Object name of the 'accounts' nodes
    */
    static final Boolean FULL_MODE_ON = Boolean.valueOf(arce.Arc_Gen_Arceconfigs_locator.getConfigurationInfo('ArceOverviewFullMode')[0].arce__Value1__c);
    /**
    * @Description: Object name of the 'accounts' nodes
    */
    static final Map<String, String> ARCE_STAGES = arce.Arc_Gen_GenericUtilities.getPicklistLabels('arce__Analysis__c','arce__Stage__c');
    /**
    *-------------------------------------------------------------------------------
    * @description empty constructor to sonar validations
    *--------------------------------------------------------------------------------
    * @date		21/03/2022
    * @author	amunguia.contractor@bbva.com
    */
    @SuppressWarnings('PMD.EmptyStatementBlock')
    @TestVisible
    private GDT_Arc_Gen_Hierarchy_Controller() {

    }
    /**
    * @description fetchAccounts
    * @author amunguia.contractor@bbva.com | 03-21-2022
    * @param String recordId
    * @return List<ClientData>
    **/
    @AuraEnabled
    global static List <ClientData> fetchAccounts(String recordId) {
        final Map<String, ClientData> result = new Map<String, ClientData>();
        final arce.Arc_Gen_Account_Has_Analysis_Wrapper arceCom = arce.Arc_Gen_AccHasAnalysis_Data.getARCEClientData(new Set<String>{recordId})[0];
        final arce.Arc_Gen_Group_Structure_Wrapper hierarMap = arce.Arc_Gen_Account_Locator.getArceOverviewStrc(recordId);

        final String idToUrl = getIdToOverview(arceCom.accWrapperObj);

        final Set<Id> accHierarchy = !FULL_MODE_ON || Test.isRunningTest() ?  recursiveParents(idToUrl, hierarMap.accountMapW, hierarMap.treeMapW) : rcrsveFullStr(hierarMap.treeMapW);
        accHierarchy.remove(null);
        final Id firstelement = (new list<Id>(accHierarchy))[0];
        objName = firstelement.getSObjectType().getDescribe().getName();

        /*final List<arce.Arc_Gen_Account_Has_Analysis_Wrapper> arces = arce.Arc_Gen_AccHasAnalysis_Data.getArcesToOvrvw(accHierarchy);
        if(!arces.isEmpty()) {
            for(arce.Arc_Gen_Account_Has_Analysis_Wrapper aux : arces) {
                final String clientId = arce.Arc_Gen_AccHasAnalysis_Data.getCorrectIdWAhas(aux.ahaObj);
                if(!result.containsKey(clientId) || aux.ahaObj.CreatedDate > result.get(clientId).CreatedDate) {
                    result.put(clientId, parseDatas(aux));
                }
            }
        }*/
        // Add comparison RTC arce data
        final List<arce.Arc_Gen_Account_Has_Analysis_Wrapper> arcesRTC = arce.Arc_Gen_AccHasAnalysis_Data.getRtcArcesToOvrvw(accHierarchy);
        if (!arcesRTC.isEmpty()) {
            for (arce.Arc_Gen_Account_Has_Analysis_Wrapper auxRTC : arcesRTC) {
                addRtcData(result, auxRTC);
            }
        }
        return result.values();
    } 

    /**
    * @description parseDatas
    * @author amunguia.contractor@bbva.com | 03-21-2022
    * @param arce.Arc_Gen_Account_Has_Analysis_Wrapper curr
    * @return ClientData
    **/
    global static ClientData parseDatas(arce.Arc_Gen_Account_Has_Analysis_Wrapper curr) {
        final String typeOfClient = curr.accWrapperObj.parentSubsidiary == 'GROUP' ? 'PARENT - GROUP' : curr.accWrapperObj.parentSubsidiary == 'SUBGROUP' ? 'PARENT - SUBGROUP' : 'SUBSIDIARY';
        final ClientData result = new ClientData();
        final String idToUrl = getIdToOverview(curr.accWrapperObj);
        result.ident = curr.ahaObj.Id;
        result.name = curr.accWrapperObj.Name;
        result.arceURL = '/lightning/r/arce__Analysis__c/' + curr.ahaObj.arce__Analysis__c + '/view';
        result.nameURL = '/lightning/r/' + objName +'/' + idToUrl +'/view';
        result.accNumber = curr.accWrapperObj.accNumber;
        result.participantType = typeOfClient;
        result.country = curr.accWrapperObj.country;
        result.rating = curr.ahaObj.arce__ffss_for_rating_id__r.arce__rating_id__r.arce__rating_long_value_type__c;
        result.createdDate = curr.ahaObj.CreatedDate;
        result.dateEEFF = getClientDataDate(curr.ahaObj);
        result.state = ARCE_STAGES.get(curr.ahaObj.arce__Analysis__r.arce__Stage__c);
        return result;
    }

    /**
    * @description parseDatas
    * @author amunguia.contractor@bbva.com | 03-21-2022
    * @param arce.Arc_Gen_Account_Has_Analysis_Wrapper curr
    * @return ClientData
    **/
    global static void addRtcData(Map<String, ClientData> result, arce.Arc_Gen_Account_Has_Analysis_Wrapper wrapper) {
        final String clientId = arce.Arc_Gen_AccHasAnalysis_Data.getCorrectIdWAhas(wrapper.ahaObj);
        if (result.containsKey(clientId)) {
            result.get(clientId).ratingRTC = wrapper.ahaObj.arce__ffss_for_rating_id__r.arce__rating_id__r.arce__rating_long_value_type__c;
            result.get(clientId).dateEeffRTC = getClientDataDate(wrapper.ahaObj);
            result.get(clientId).stateRTC = ARCE_STAGES.get(wrapper.ahaObj.arce__Analysis__r.arce__Stage__c);
            result.get(clientId).arceUrlRTC = '/lightning/r/arce__Analysis__c/' + wrapper.ahaObj.arce__Analysis__c + '/view';
        }
    }

    /**
    * @description recursiveParents
    * @author amunguia.contractor@bbva.com | 03-21-2022
    * @param String child
    * @param Map<Id Id> parents
    * @param Map<Id List<Id>> tree
    * @return Set<Id>
    **/
    private static Set<Id> recursiveParents (String child, Map<Id,Id> parents, Map<Id, List<Id>> tree) {
        final Set<Id> result = new Set<Id>{child, parents.get(child)};
        result.addAll(tree.get(parents.get(child)));
        if(String.isNotBlank(child) && parents.containsKey(child)) {
            result.addAll(recursiveParents(parents.get(child), parents, tree));
        }
        return result;
    }

    /**
    * @description recursiveParents
    * @author ARCE
    * @param Arc_Gen_Account_Wrapper accWrapper
    * @return String
    **/
    private static String getIdToOverview (arce.Arc_Gen_Account_Wrapper accWrapper) {
        final String customUrlId = accWrapper?.customAccount;
        return String.isBlank(customUrlId) ? accWrapper.accId : customUrlId;
    }

    /**
    * @description rcrsveFullStr
    * @author ARCE | 03-2023
    * @param Map<Id List<Id>> tree
    * @return Set<Id>
    **/
    private static Set<Id> rcrsveFullStr (Map<Id, List<Id>> tree) {
        Set<Id> allHierarchy = new Set<Id>();

        for(Id currnt : tree.keySet()) {
            allHierarchy.add(currnt);
            allHierarchy.addAll(tree.get(currnt));
        }

        return allHierarchy;
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
    @SuppressWarnings('PMD.NcssMethodCount')
    @AuraEnabled
    global static String buildDynamicColumns() {
        final JSONGenerator gen = JSON.createGenerator(false);
        gen.writeStartArray();

        gen.writeStartObject();
        gen.writeStringField(LABEL_LIT, 'Alphacode');
        gen.writeStringField(FIELDNAME_LIT, 'accNumber');
        gen.writeStringField(TYPE_LIT, TEXT_LIT);
        gen.writeEndObject();

        gen.writeStartObject();
        gen.writeStringField(LABEL_LIT, 'Name (Local client)');
        gen.writeBooleanField(SORTABLE_LIT, true);
        gen.writeStringField(FIELDNAME_LIT, 'nameURL');
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
        gen.writeStringField(LABEL_LIT, 'Date');
        gen.writeStringField(FIELDNAME_LIT, 'dateEEFF');
        gen.writeBooleanField(SORTABLE_LIT, true);
        gen.writeStringField(TYPE_LIT, 'Date');
        gen.writeEndObject();

        gen.writeStartObject();
        gen.writeStringField(LABEL_LIT, 'State');
        gen.writeStringField(FIELDNAME_LIT, 'arceURL');
        gen.writeBooleanField(SORTABLE_LIT, true);
        gen.writeStringField(TYPE_LIT, 'url');
        gen.writeObjectField('typeAttributes', buildTypeAttributes('state'));
        gen.writeEndObject();

        gen.writeStartObject();
        gen.writeStringField(LABEL_LIT, 'Rating RTC');
        gen.writeStringField(FIELDNAME_LIT, 'ratingRTC');
        gen.writeStringField(TYPE_LIT, TEXT_LIT);
        gen.writeEndObject();

        gen.writeStartObject();
        gen.writeStringField(LABEL_LIT, 'Date RTC');
        gen.writeStringField(FIELDNAME_LIT, 'dateEeffRTC');
        gen.writeBooleanField(SORTABLE_LIT, true);
        gen.writeStringField(TYPE_LIT, 'Date');
        gen.writeEndObject();

        gen.writeStartObject();
        gen.writeStringField(LABEL_LIT, 'State RTC');
        gen.writeStringField(FIELDNAME_LIT, 'arceUrlRTC');
        gen.writeBooleanField(SORTABLE_LIT, true);
        gen.writeStringField(TYPE_LIT, 'url');
        gen.writeObjectField('typeAttributes', buildTypeAttributes('stateRTC'));
        gen.writeEndObject();
        gen.writeEndArray();
        return gen.getAsString();
    }
    /**
    * @Description: ClientData wrapper
    */
    global class ClientData {
        /**
        * @Description: Indicates name of the customer
        */
        @AuraEnabled global String ident {get;set;}
        /**
        * @Description: Indicates if the numeber of the customer
        */
        @AuraEnabled global String name {get;set;}
        /**
        * @Description: Indicates if the accNumber of the customer
        */
        @AuraEnabled global String accNumber {get;set;}
        /**
        * @Description: Indicates if the participantType of the customer
        */
        @AuraEnabled global String participantType {get;set;}
        /**
        * @Description: Indicates if the country of the customer
        */
        @AuraEnabled global String country {get;set;}
        /**
        * @Description: Indicates if the rating of the customer
        */
        @AuraEnabled global String rating {get;set;}
        /**
        * @Description: Indicates if the ratingRTC of the customer
        */
        @AuraEnabled global String ratingRTC {get;set;}
        /**
        * @Description: Indicates if the dateEEFF of the customer
        */
        @AuraEnabled global Date dateEEFF {get;set;}
        /**
        * @Description: Indicates if the dateEeffRTC of the customer
        */
        @AuraEnabled global Date dateEeffRTC {get;set;}
        /**
        * @Description: Indicates if the created date of the customer
        */
        @AuraEnabled global Datetime createdDate {get;set;}
        /**
        * @Description: Indicates if the state of the customer
        */
        @AuraEnabled global String state {get;set;}
        /**
        * @Description: Indicates if the stateRTC of the customer
        */
        @AuraEnabled global String stateRTC {get;set;}
        /**
        * @Description: Indicates if the nameURL of the customer
        */
        @AuraEnabled global String nameURL {get;set;}
        /**
        * @Description: Indicates if the arceURL of the customer
        */
        @AuraEnabled global String arceURL {get;set;}
        /**
        * @Description: Indicates if the arceUrlRTC of the customer
        */
        @AuraEnabled global String arceUrlRTC {get;set;}
    }
    /**
    * @description getClientDataDate
    * @author nerea.ortiz.penalosa.contractor@bbva.com | 29-03-2029
    * @param arce__Account_has_Analysis__c aha
    * @return Date
    **/
    private static Date getClientDataDate(arce__Account_has_Analysis__c aha) {
        Date clientDataDate = null;
        if(aha.arce__Analysis__r.arce__wf_status_id__c == '13') {
            clientDataDate = aha.arce__Analysis__r.arce__end_date__c;
        } else {
            clientDataDate = Date.newInstance(aha.CreatedDate.year(), aha.CreatedDate.month(), aha.CreatedDate.day());
        }
        return clientDataDate;
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
    * @author amunguia.contractor@bbva.com | 03-25-2022
    * @param String fieldName
    * @return Map<String, Map<String, String>>
    **/
    private static TypeAttribute buildTypeAttributes(String fieldName) {
        final TypeAttribute result = new TypeAttribute();
        result.label = new Map<String, String>{'fieldName'=> fieldName};
        result.target = '_blank';
        return result;
    }
}