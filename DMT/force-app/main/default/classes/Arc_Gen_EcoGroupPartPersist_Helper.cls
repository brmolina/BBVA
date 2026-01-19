/**
* ------------------------------------------------------------------------------------------------
* @Name     Arc_Gen_EcoGroupPartPersist_Helper
* @Author   Mario Humberto Ramirez Lio mariohumberto.ramirez.contractor@bbva.com
* @Date     Created: 24/04/2020
* @Group    ARCE
* -----------------------------------------------------------------------------------------------
* @Description Helper class for economic group participant persistance service
* -----------------------------------------------------------------------------------------------
* @Changes
*
* |2020-04-24 mariohumberto.ramirez.contractor@bbva.com
*             Class creation.
* |2020-04-24 mariohumberto.ramirez.contractor@bbva.com
*             Change the attribute businessDocument as optional in buildJson method
* |2020-09-23 saimassimilianno.jordana.contractor@bbva.com
*             Added arce. namespace to all classes that are now in the arce-dependencies package
* |2020-09-29 joseluis.garcia4.contractor@bbva.com
*             Temporary solution, provide only one char to relation.level param.
* |2021-06-14 juanignacio.hita.contractor@bbva.com
*             Add EcoGroupPartWrapper and save data fields of Account object.
* |2021-09-01 juanignacio.hita.contractor@bbva.com
*             Excludes the data saving when tests are running on saveDataAcc method
* -----------------------------------------------------------------------------------------------
*/
public without sharing class Arc_Gen_EcoGroupPartPersist_Helper {
    /**
        * @Description: Parse constants participant type
    */
    public static final Map<String, String> PARSE_PARTIC_TYPE = new Map<String, String> {
        'SUPRAGROUP' => '1',
        'GROUP' => '2',
        'SUBGROUP' => '3',
        'SUBSIDIARY' => '4'
    };
    /**
        * @Description: Vision constant type
    */
    public static final Map<String, String> VISION_TYPE = new Map<String, String> {
        'RISK' => '1',
        'BUSINESS' => '2',
        'BOTH' => '3'
    };
    /**
    * @Class: RatingParameters
    * @Description: Wrapper that contain all the rating service parameters
    * @author BBVA
    */
    public class EcoGroupPartWrapper {
        /**
        * @Description: direct stake percent
        */
        public Double directStakePer {get;set;}
        /**
        * @Description: indirect stake percent
        */
        public Double indirectStakePer {get;set;}
        /**
        * @Description: fiscal identifier type
        */
        public String fiscalIdType {get;set;}
        /**
        * @Description: level group type
        */
        public String levelGroupType {get;set;}
        /**
        * @Description: participant type
        */
        public String participantType {get;set;}
        /**
        * @Description: relation risk vision
        */
        public String relRiskVision {get;set;}
        /**
        * @Description: risk computable percent
        */
        public Double riskComputablePer {get;set;}
        /**
        * @Description: cnsld financial statement type
        */
        public Boolean cnsldFffssType {get;set;}
    }

    /**
        * @Description: void constrctor
    */
    private Arc_Gen_EcoGroupPartPersist_Helper() {

    }
    /**
    *------------------------------------------------------------------------------------------------------------
    * @description Method that build the json input template needed to call the economic group participant service
    *------------------------------------------------------------------------------------------------------------
    * @Author mariohumberto.ramirez.contractor@bbva.com
    * @Date 24/04/2020
    * @param Arc_Gen_CallListParticipant.innertoreturnlistp listparticipant - list participant wrapper
    * @param List<arce.Arc_Gen_Account_Wrapper> accPartWrapLts - account wrapper info
    * @return a JSON input template for economic group participant service
    * @example buildJson(listparticipant, accPartWrapLts)
    * -----------------------------------------------------------------------------------------------------------
    */
    public static String buildJson (Arc_Gen_CallListParticipant.innertoreturnlistp listparticipants, List<arce.Arc_Gen_Account_Wrapper> accPartWrapLts) {
        final List<String> accNumberLts = new List<String>();
        String dynJson = '';
        for (arce.Arc_Gen_Account_Wrapper accWrapp: accPartWrapLts) {
            accNumberLts.add(accWrapp.accNumber);
        }
        final List<Arc_Gen_CallListParticipant.participantobj> participants = listparticipants.customersdata;
        for(Arc_Gen_CallListParticipant.participantobj participant : participants) {
            String businessDocument = '';
            if (participant.documentTypeId != null && participant.documentNumber != null) {
                businessDocument ='"businessDocument":{' +
                                            '"businessDocumentType":{' +
                                            '"id":' + '"' + participant.documentTypeId + '",' +
                                            '"name":' + '"' + participant.documentTypeName +'"' +
                                            '},' +
                                            '"country":{' +
                                                '"id":' + '"' + participant.participantId.left(2) +'"' +
                                            '},' +
                                            '"documentNumber":' + '"' + participant.documentNumber + '"' +
                                        '},';

            }
            if (accNumberLts.contains(participant.participantId)) {
                dynJson +='{"id":' + '"' + participant.participantId +'",' +
                            '"legalName":' + '"' + participant.legalName + '",' +
                            businessDocument +
                            '"relation":{' +
                                '"level":' + '"' + participant.pRelLevel.right(1) + '",' +   // TODO: Revisar con equipo de servicios.
                                '"relationType":{' +
                                    '"id":' + '"' + participant.relationTypeId + '",' +
                                    '"name":' + '"' + participant.relationTypeName + '"' +
                                '},' +
                                '"startDate":' + '"' + participant.relationStartDate + '",' +
                                '"parentEconomicGroup":{' +
                                    '"id":' + '"' + participant.parentEconomicGroupId + '"' +
                                '}' +
                            '},' +
                            '"isHolding":' + String.valueOf(participant.isHolding) + ',' +
                            '"participantType":{' +
                                '"id":' + '"' + participant.participantTypeId + '"' +
                            '},' +
                            '"vision":' + '"' + participant.vision + '",' +
                            '"participation":{' +
                                '"directPercentage":' + String.valueOf(participant.directPercentage) + ',' +
                                '"indirectPercentage":' + String.valueOf(participant.indirectPercentage) + ',' +
                                '"computableRisk":' + String.valueOf(participant.computableRisk) + ',' +
                                '"totalPercentage":' + String.valueOf(participant.totalPercentage) +
                            '},' +
                            '"isConsolidated":' + String.ValueOf(participant.isConsolidated) +
                        '},';
            }
        }
        dynJson = dynJson.removeEnd(',');
        return '[' + dynJson + ']';
    }
    /**
    *------------------------------------------------------------------------------------------------------------
    * @description Fill wrapper data from services
    *------------------------------------------------------------------------------------------------------------
    * @Author  juanignacio.hita.contractor@bbva.com
    * @Date    09/06/2021
    * @param   Arc_Gen_CallListParticipant.innertoreturnlistp listparticipant - list participant wrapper
    * @param   List<arce.Arc_Gen_Account_Wrapper> accPartWrapLts - account wrapper info
    * @return  Map<String, EcoGroupPartWrapper>
    * @example Map<String, EcoGroupPartWrapper> mapWrap = fillWrapperServices(listparticipant, accPartWrapLts);
    * -----------------------------------------------------------------------------------------------------------
    */
    public static Map<String, EcoGroupPartWrapper> fillWrapperServices(Arc_Gen_CallListParticipant.innertoreturnlistp listparticipants, List<arce.Arc_Gen_Account_Wrapper> accPartWrapLts) {
        final Map<String, EcoGroupPartWrapper> ecoGroupWrap = new Map<String, EcoGroupPartWrapper>();
        final List<String> accNumberLts = new List<String>();
        final Map<String, arce.Arc_Gen_Account_Wrapper> mapAccWrapper = new Map<String, arce.Arc_Gen_Account_Wrapper>();
        for (arce.Arc_Gen_Account_Wrapper accWrapp: accPartWrapLts) {
            accNumberLts.add(accWrapp.accNumber);
            mapAccWrapper.put(accWrapp.accNumber, accWrapp);
        }
        for(Arc_Gen_CallListParticipant.participantobj participant : listparticipants.customersdata) {
            final EcoGroupPartWrapper ecoGroupWrapper = new EcoGroupPartWrapper();
            if (accNumberLts.contains(participant.participantId)) {
                if (participant.documentTypeId != null && participant.documentNumber != null) {
                    ecoGroupWrapper.fiscalIdType = participant.documentTypeId;
                }
                ecoGroupWrapper.directStakePer = participant.directPercentage;
                ecoGroupWrapper.indirectStakePer = participant.indirectPercentage;
                ecoGroupWrapper.levelGroupType = participant.pRelLevel.right(1);
                ecoGroupWrapper.participantType = participant.participantTypeId;
                ecoGroupWrapper.relRiskVision = participant.vision;
                ecoGroupWrapper.riskComputablePer = participant.computableRisk;
                ecoGroupWrapper.cnsldFffssType = participant.isConsolidated;
                ecoGroupWrap.put(mapAccWrapper.get(participant.participantId).accId, ecoGroupWrapper);
            }
        }
        return ecoGroupWrap;
    }
    /**
    *------------------------------------------------------------------------------------------------------------
    * @description Save account data from economic group response service
    *------------------------------------------------------------------------------------------------------------
    * @Author  juanignacio.hita.contractor@bbva.com
    * @Date    09/06/2021
    * @param   Map<String, EcoGroupPartWrapper> ecoGroupWrap
    * @return  arce.Arc_Gen_ServiceAndSaveResponse
    * @example arce.Arc_Gen_ServiceAndSaveResponse service = saveDataAcc(ecoGroupWrap);
    * -----------------------------------------------------------------------------------------------------------
    */
    public static arce.Arc_Gen_ServiceAndSaveResponse saveDataAcc(Map<String, EcoGroupPartWrapper> ecoGroupWrap) {
        final Map<Id, Map<String, Object>> lstAccUp = new Map<Id, Map<String, Object>>();
        for (String idKey : ecoGroupWrap.keySet()) {
            final Map<String, Object> mapObject = new Map<String, Object>();
            mapObject.put('direct_stake_per__c', ecoGroupWrap.get(idKey).directStakePer);
            mapObject.put('indirect_stake_per__c', ecoGroupWrap.get(idKey).indirectStakePer);
            mapObject.put('level_group_type__c', ecoGroupWrap.get(idKey).levelGroupType);
            mapObject.put('participant_type__c', PARSE_PARTIC_TYPE.get(ecoGroupWrap.get(idKey).participantType));
            mapObject.put('relation_risk_vision_type__c', VISION_TYPE.get(ecoGroupWrap.get(idKey).relRiskVision));
            mapObject.put('risk_computable_per__c', ecoGroupWrap.get(idKey).riskComputablePer);
            mapObject.put('sbsid_req_cnsld_ffss_type__c', ecoGroupWrap.get(idKey).cnsldFffssType == true ? '1' : '2');
            mapObject.put('fiscal_identifier_type__c', ecoGroupWrap.get(idKey).fiscalIdType);
            lstAccUp.put((Id) idKey, mapObject);
        }
        arce.Arc_Gen_ServiceAndSaveResponse serviceAndResp = new arce.Arc_Gen_ServiceAndSaveResponse();
        // Save data in Salesforce
        if (!Test.isRunningTest()) {
            serviceAndResp = arce.Arc_Gen_Account_Locator.accountUpdate(lstAccUp);
        }
        return serviceAndResp;
    }

}