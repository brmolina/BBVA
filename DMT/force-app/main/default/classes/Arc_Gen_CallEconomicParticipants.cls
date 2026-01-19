/**
* @File Name          : Arc_Gen_CallEconomicParticipants.cls
* @Description        : Contain logic to process Groups ASO WS (getEconomicParticipations)
* @Author             : Luis Arturo Parra Rosas / luisarturo.parra.contractor@bbva.com
* @Group              : ARCE Team
* @Data Class         : Arc_Gen_Groups_data
* @Main ctr Class     : Arc_Gen_Groups_Service
* @Test Class         : Arc_Gen_Groups_controller_test
* @Last Modified By   : luisarturo.parra.contractor@bbva.com
* @Last Modified On   : 30/08/2019
* @Modification Log   :
*=================================================================================================
* Ver         Date                     Author                                        Modification
*=================================================================================================
* 1.0         30/08/2019                luisarturo.parra.contractor@bbva.com            Initial Version
* 1.0         08/02/2019                ricardo.almanza.contractor@bbva.com             added config for 204 for orphan test
* 1.1         17/04/2020                joseluis.garcia4.contractor@bbva.com            add customer number encryption
* 1.2         23/09/2020                saimassimilianno.jordana.contractor@bbva.com    Added arce. namespace to
                                                        all classes that are now in the arce-dependencies package
* 1.3         30/04/2021                otiliaramona.veres.contractor@bbva.com          Added an empty constructor method.
* 1.4         04/05/2021                otiliaramona.veres.contractor@bbva.com          Added annotation to the empty constructor method.
* 1.5         21/05/2021                otiliaramona.veres.contractor@bbva.com          Deleted some unused local variables.
*                                                                                       Added header comments.
*                                                                                       Added single whitespace before brackets.
*                                                                                       Reduced variable names length.
* 1.6         24/05/2021                otiliaramona.veres.contractor@bbva.com          Declared final some local variable.
*                                                                                       Added header comments.
*                                                                                       Added single whitespace before opening braces.
*                                                                                       Reduced variable names length.
****************************************************************************************************************/
@SuppressWarnings('PMD.ExcessivePublicCount')
public without sharing class Arc_Gen_CallEconomicParticipants {
    /**
    *-------------------------------------------------------------------------------
    * @Description Empty constructor method
    *-------------------------------------------------------------------------------
    * @author otiliaramona.veres.contractor@bbva.com
    * @date 30/04/2021
    */
    @TestVisible
    private Arc_Gen_CallEconomicParticipants() { }
    /**
    *-------------------------------------------------------------------------------
    * @Description wrapper for Business data object
    *-------------------------------------------------------------------------------
    * @Date 03/12/2019
    * @Author luisarturo.parra.contractor@bbva.com
    * @example Businessdataobj businessDataObj = new Businessdataobj();
    *-------------------------------------------------------------------------------
    */
    public class Businessdataobj {
        /**
        * @Description: Business Document Number
        */
        public String businessDocNum {get; set;}
        /**
        * @Description: Business Document Type Id
        */
        public String businessDocTypeId {get; set;}
        /**
        * @Description: Business Document Type Name
        */
        public String bsnssDocTypeName {get; set;}
    }
    /**
    *-------------------------------------------------------------------------------
    * @Description wrapper for Group Data
    *-------------------------------------------------------------------------------
    * @Date 03/12/2019
    * @Author luisarturo.parra.contractor@bbva.com
    * @example Groupdata groupData = new Groupdata();
    *-------------------------------------------------------------------------------
    */
    public class Groupdata {
        /**
        * @Description: Group Name
        */
        public String groupname {get; set;}
        /**
        * @Description: Group Id
        */
        public String groupid {get; set;}
        /**
        * @Description: Decrypted Group Id
        */
        public String decryptedgroupid {get; set;}
    }
    /**
    *-------------------------------------------------------------------------------
    * @Description wrapper for Business Data Container
    *-------------------------------------------------------------------------------
    * @Date 03/12/2019
    * @Author luisarturo.parra.contractor@bbva.com
    * @example Businessdatacontainer businessDataContainer = new Businessdatacontainer();
    *-------------------------------------------------------------------------------
    */
    public class Businessdatacontainer {
        /**
        * @Description: Business Id
        */
        public String businessId {get; set;}
        /**
        * @Description: Business Legal Name
        */
        public String businessLegalName {get; set;}
        /**
        * @Description: Business List Documents
        */
        public List<Businessdataobj> bussineslistdocs {get; set;}
    }

    /**
    *-------------------------------------------------------------------------------
    * @Description wrapper for Inner to return
    *-------------------------------------------------------------------------------
    * @Date 03/12/2019
    * @Author luisarturo.parra.contractor@bbva.com
    * @example Innertoreturn innertoreturn = new Innertoreturn();
    *-------------------------------------------------------------------------------
    */
    public class Innertoreturn {
        /**
        * @Description: Error 204 Message
        */
        public String error204message {get; set;}

        /**
        * @Description: Error Message
        */
        public String errormessage {get; set;}

        /**
        * @Description: Service Call Error
        */
        public String servicecallerror {get; set;}

        /**
        * @Description: Business
        */
        public Businessdatacontainer business {get; set;}

        /**
        * @Description: Group Info
        */
        public Groupdata groupinfo {get; set;}

        /**
        * @Description: Is Orphan
        */
        public Boolean isorphan {get; set;}
    }
    /**
    *-------------------------------------------------------------------------------
    * @description calls getAnalysis and return data needed to visualizate current stage:
    * serviceStatus - OK/KO
    * message - empty / message to be displayed
    * retToPreparing - OK/KO
    *--------------------------------------------------------------------------------
    * @date     20/06/2019
    * @author   diego.miguel.contractor@bbva.com
    * @param    recordId - account_has_analysis Id
    * @return   Arc_Gen_RefreshClass_service.refreshMessagesResponse
    * @example  public static Arc_Gen_CallListParticipant.Innertoreturnlistp callListParticipants(String encryptedGroup) {
    */
    public static Arc_Gen_CallEconomicParticipants.Innertoreturn callEconomicParticipations(String encryptedClient) {
        final String customerNumber = arce.Arc_Gen_CallEncryptService.getEncryptedClient(encryptedClient);
        final Innertoreturn returndata = new Innertoreturn();
        final arce.Arc_Gen_CustomServiceMessages serviceMessages = new arce.Arc_Gen_CustomServiceMessages();
        String respWarDesc204;
        final String params = '{"customerId":"'+customerNumber+'"}';// params to economic participant service
        final String[] businessdata, groupdata, s204, ecodes;
        final Boolean getOrphAnsStrct = arce.Arc_Gen_GenericUtilities.getOrphanAnsStructure();
        arce.Arc_Gen_getIASOResponse.serviceResponse sResponse = new arce.Arc_Gen_getIASOResponse.serviceResponse();
        try {
            sResponse = callEconomicParticipation(params);//iaso call
            system.debug('sResponse economicp'+sResponse);
            if(getOrphAnsStrct) {
                sResponse.serviceMessage = serviceMessages.SUCCESSFUL_204;
            }
        } catch (Exception e) {
            returndata.servicecallerror =  System.Label.Cls_arce_GRP_servError + '. ' + e.getMessage();
        }
        if(sResponse.serviceMessage == serviceMessages.SUCCESSFUL_200) {
            final Map<String, Object> data = getMapFromJson(sResponse.serviceResponse, 'data');
            final Map<String, Object> business = getMapFromJson(data, 'business');
            returndata.business = getbusinnessdatafromListPart(business);
            final List<Map<String, Object>> groupsList = getListFromJson(data, 'groups');
            returndata.groupinfo = getgroupIDandNamefromListPart(groupsList);
            returndata.isorphan = false;
        } else if(sResponse.serviceMessage == serviceMessages.SUCCESSFUL_204) {
            respWarDesc204 = sResponse.serviceHeaders.get('responsewarningdescription');
            returndata.error204message = respWarDesc204;
            final Groupdata groupinformation = NEW Groupdata();
            groupinformation.groupid = encryptedClient;
            returndata.groupinfo = groupinformation;
            returndata.isorphan = true;
            // We cannot pass through this lines on test because Mock always return 200 code.
        } else {
            // Devolver mensaje de ERROR HTTP
            // We cannot pass through this lines on test because Mock always return 200 code.
            returndata.errormessage =  System.Label.Cls_arce_GRP_servError + ': ' + sResponse.serviceCode + ' ' + sResponse.serviceMessage;
        }
        return returndata;
    }
    /**
    *-------------------------------------------------------------------------------
    * @description calls getAnalysis and return data needed to visualizate current stage:
    * serviceStatus - OK/KO
    * message - empty / message to be displayed
    * retToPreparing - OK/KO
    *--------------------------------------------------------------------------------
    * @date     20/06/2019
    * @author   diego.miguel.contractor@bbva.com
    * @param    recordId - account_has_analysis Id
    * @return   Arc_Gen_RefreshClass_service.refreshMessagesResponse
    * @example  public static Arc_Gen_CallListParticipant.Innertoreturnlistp callListParticipants(String encryptedGroup) {
    */
    private static Businessdatacontainer getbusinnessdatafromListPart (Map<String, Object> business) {
        final Businessdatacontainer businessreturn =  new Businessdatacontainer() ;
        businessreturn.businessId = (String)business.get('id');
        businessreturn.businessLegalName = (String)business.get('legalName');
        final List<Map<String, Object>> bsnssDocsList = getListFromJson(business, 'businessDocuments');
        businessreturn.bussineslistdocs = new List<Businessdataobj>();
        for (Map<String, Object> businessDoc : bsnssDocsList) {
            final Businessdataobj docs = new Businessdataobj();
            docs.businessDocNum = (String)businessDoc.get('documentNumber');
            docs.businessDocTypeId = (String)businessDoc.get('id');
            docs.bsnssDocTypeName = (String)businessDoc.get('name');
            businessreturn.bussineslistdocs.add(docs);
        }
        return businessreturn;
    }
    /**
    *-------------------------------------------------------------------------------
    * @description calls getAnalysis and return data needed to visualizate current stage:
    * serviceStatus - OK/KO
    * message - empty / message to be displayed
    * retToPreparing - OK/KO
    *--------------------------------------------------------------------------------
    * @date     20/06/2019
    * @author   diego.miguel.contractor@bbva.com
    * @param    recordId - account_has_analysis Id
    * @return   Arc_Gen_RefreshClass_service.refreshMessagesResponse
    * @example  public static Arc_Gen_CallListParticipant.Innertoreturnlistp callListParticipants(String encryptedGroup) {
    */
    private static Groupdata getgroupIDandNamefromListPart (List<Map<String, Object>> groupsList) {
        final Groupdata groupinformation = NEW Groupdata();
        groupinformation.groupid = (String)groupsList[0].get('id');
        groupinformation.groupname = (String)groupsList[0].get('name'); // NAME OF THE GROUP RETRIEVED BY ECONOMIC PARTICIPANTS "GROUP TO WHICH IT BELONGS"
        return groupinformation;
    }
    /**
    *-------------------------------------------------------------------------------
    * @description calls getAnalysis and return data needed to visualizate current stage:
    * serviceStatus - OK/KO
    * message - empty / message to be displayed
    * retToPreparing - OK/KO
    *--------------------------------------------------------------------------------
    * @date     20/06/2019
    * @author   diego.miguel.contractor@bbva.com
    * @param    recordId - account_has_analysis Id
    * @return   Arc_Gen_RefreshClass_service.refreshMessagesResponse
    * @example  public static Arc_Gen_CallListParticipant.Innertoreturnlistp callListParticipants(String encryptedGroup) {
    */
    private static Map<String, Object> getMapFromJson(Map<String, Object> prevMap, String keyToRetrieve) {
        Map<String, Object> data = (Map<String, Object>)JSON.deserializeUntyped(JSON.serialize(prevMap.get(keyToRetrieve)));
        if (data == null) {
            data = new Map<String, Object>();
        }
        return data;
    }
    /**
    *-------------------------------------------------------------------------------
    * @description calls getAnalysis and return data needed to visualizate current stage:
    * serviceStatus - OK/KO
    * message - empty / message to be displayed
    * retToPreparing - OK/KO
    *--------------------------------------------------------------------------------
    * @date     20/06/2019
    * @author   diego.miguel.contractor@bbva.com
    * @param    recordId - account_has_analysis Id
    * @return   Arc_Gen_RefreshClass_service.refreshMessagesResponse
    * @example  public static Arc_Gen_CallListParticipant.Innertoreturnlistp callListParticipants(String encryptedGroup) {
    */
    private static List<Map<String, Object>> getListFromJson(Map<String, Object> prevMap, String keyToRetrieve) {
        final List<Map<String, Object>> listOfMap = new List<Map<String, Object>>();
        final List<Object> objectList = (List<Object>)prevMap.get(keyToRetrieve);
        for(Object element : objectList) {
            listOfMap.add((Map<String, Object>)element);
        }
        return listOfMap;
    }
    /**
    *-------------------------------------------------------------------------------
    * @description calls getAnalysis and return data needed to visualizate current stage:
    * serviceStatus - OK/KO
    * message - empty / message to be displayed
    * retToPreparing - OK/KO
    *--------------------------------------------------------------------------------
    * @date     20/06/2019
    * @author   diego.miguel.contractor@bbva.com
    * @param    recordId - account_has_analysis Id
    * @return   Arc_Gen_RefreshClass_service.refreshMessagesResponse
    * @example  public static Arc_Gen_CallListParticipant.Innertoreturnlistp callListParticipants(String encryptedGroup) {
    */
    private static arce.Arc_Gen_getIASOResponse.serviceResponse callEconomicParticipation(String params) {
        // ratios service name (CMT). Mock must be set to 'retrieve mock = true' in order to pass test clases
        final String serviceName = 'economicParticipations';
        return callEngine(serviceName, params);
    }
    /**
    *-------------------------------------------------------------------------------
    * @description calls getAnalysis and return data needed to visualizate current stage:
    * serviceStatus - OK/KO
    * message - empty / message to be displayed
    * retToPreparing - OK/KO
    *--------------------------------------------------------------------------------
    * @date     20/06/2019
    * @author   diego.miguel.contractor@bbva.com
    * @param    recordId - account_has_analysis Id
    * @return   Arc_Gen_RefreshClass_service.refreshMessagesResponse
    * @example  public static Arc_Gen_CallListParticipant.Innertoreturnlistp callListParticipants(String encryptedGroup) {
    */
    private static arce.Arc_Gen_getIASOResponse.serviceResponse callEngine(String serviceName, String params) {
        return arce.Arc_Gen_getIASOResponse.calloutIASO(serviceName,params);
    }
}