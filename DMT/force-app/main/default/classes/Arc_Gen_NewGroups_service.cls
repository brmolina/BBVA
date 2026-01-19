/**
  * ------------------------------------------------------------------------------------------------
  * @Name     Arc_Gen_NewGroups_service
  * @Author   luisarturo.parra.contractor@bbva.com
  * @Date     Created: 2019-04-30
  * @Group    ARCE
  *=======================================================================================================================
  * Ver                  Date                         Author                       Modification
  * 1.0              12/09/2019    luisarturo.parra.contractor@bbva.com         Initial version
  * 1.1              05/12/2019    manuelhugo.castillo.contractor@bbva.com      Modify method 'handlecall','accountstoremove' replace Account to AccountWrapper
  * 1.2              13/01/2020    mariohumberto.ramirez.contractor@bbva.com    Added new methods handleGroupStructureOnline
  * 1.3              17/01/2020    javier.soto.carrascosa@bbva.com              Add support for new account interfaces
  * 1.4              22/01/2020    juanmanuel.perez.ortiz.contractor@bbva.com   Add line to return orphan structure
  * 1.5              08/02/2020    ricardo.almanza.contractor@bbva.com          Removed class orphan and and sent as parameter
  * 1.6              24/06/2020    juanignacio.hita.contractor@bbva.com         Changed handle group structure online for get isHolding parameter
  * 1.7              23/09/2020    saimassimilianno.jordana.contractor@bbva.com Added arce. namespace to all classes that
  *                                                                             are now in the arce-dependencies package
  * 1.8              01/09/2021    juanignacio.hita.contractor@bbva.com         Excludes the data saving when tests are running on updateGroupName method
  * 1.9              31/03/2022    juanignacio.hita.contractor@bbva.com         Created comparePrevStructOnline method
  *=======================================================================================================================
  * -----------------------------------------------------------------------------------------------
  */
@SuppressWarnings('sf:TooManyMethods, PMD.ExcessivePublicCount')
public virtual class Arc_Gen_NewGroups_service extends Arc_Gen_NewGroups_Data{
    /**
    *-------------------------------------------------------------------------------
    * @description method that sets rating
    *-------------------------------------------------------------------------------
    * @date 12/09/2019
    * @author luisarturo.parra.contractor@bbva.com
    * @param List<arce__Account_has_Analysis__c> analyzedClientList
    * @return none
    * @example  private void setRatingVariables(List<arce__Account_has_Analysis__c> analyzedClientList)
    */
    public class Returnstructure {
        /**
            * @Description: String participantsinSF
        */
        public  List<Account> participantsinSF {get; set;}
        /**
            * @Description: String participantsnotinSF
        */
        public  List<String> participantsnotinSF {get; set;}
        /**
            * @Description: String participantsremoved
        */
        public  List<Account> participantsremoved {get; set;}
        /**
            * @Description: String groupID
        */
        public  String groupID {get; set;}
        /**
            * @Description: String isorphan
        */
        public  Boolean isorphan {get; set;}
        /**
            * @Description: String orphanNumber
        */
        public  String orphanNumber {get; set;}
        /**
            * @Description: String orphanId
        */
        public  String orphanId {get; set;}
        /**
            * @Description: String participantsOnline
        */
        public  List<arce.Arc_Gen_Account_Wrapper> participantsOnline {get; set;}
        /**
            * @Description: String noGroupsInSf
        */
        public  Boolean noGroupsInSf {get; set;}
        /**
            * @Description: String updateStructure
        */
        public  Boolean updateStructure {get; set;}
        /**
            * @Description : Map with record id and value isHolding that indicates whether the participant is a matrix or not.
        */
        @AuraEnabled public Map<String, Boolean> isHolding {get;set;}
    }
    /**
    *-------------------------------------------------------------------------------
    * @Description method that handle groups structure Online
    *-------------------------------------------------------------------------------
    * @Author   Mario Humberto Ramirez Lio  mariohumberto.ramirez.contractor@bbva.com
    * @Date     Created: 2020-13-01
    * @param List<arce__Account_has_Analysis__c> analyzedClientList
    * @return Returnstructure - wrapper with the group structure data
    * @example handleGroupStructureOnline(economicparticipants,listparticipants,accountNumber)
    * -----------------------------------------------------------------------------
    */
    public virtual Arc_Gen_NewGroups_service.Returnstructure handleGroupStructureOnline(Arc_Gen_CallEconomicParticipants.Innertoreturn economicparticipants, Arc_Gen_CallListParticipant.Innertoreturnlistp listparticipants, String accountNumber, Boolean isOrphan ) {
        Arc_Gen_NewGroups_service.Returnstructure structure = new Arc_Gen_NewGroups_service.Returnstructure();
        final List<arce.Arc_Gen_Account_Wrapper> lstParticipantsWrap = new List<arce.Arc_Gen_Account_Wrapper>();
        final Boolean updateStructure = arce.Arc_Gen_GenericUtilities.getUpdateStructure();
        structure.noGroupsInSf = false;

        Map<String,arce.Arc_Gen_Account_Wrapper> groupInSF = arce.Arc_Gen_Account_Locator.getAccountByAccNumber(new List<String>{economicparticipants.groupinfo.groupid, accountNumber});
        if ((groupInSF.get(economicparticipants.groupinfo.groupid) == null || groupInSF.get(accountNumber) == null) && isOrphan == false) {
            if (updateStructure) {
                groupInSF = Arc_Gen_NewGroups_Service_Helper.createGroupAcc(economicparticipants);
            } else {
                structure.noGroupsInSf = true;
            }
        }
        if (isOrphan && structure.noGroupsInSf == false) {
            final Map<String,arce.Arc_Gen_Account_Wrapper> mapAccWrapByAccNum = arce.Arc_Gen_Account_Locator.getAccountByAccNumber(new List<String>{accountNumber});
            lstParticipantsWrap.add(mapAccWrapByAccNum.get(accountNumber));
            structure.isorphan = true;
            structure.orphanId = mapAccWrapByAccNum.get(accountNumber).accId;
            structure.orphanNumber = accountNumber;
            structure.participantsOnline = lstParticipantsWrap;
            structure.noGroupsInSf = false;
            structure.groupID = mapAccWrapByAccNum.get(accountNumber).accId;
        } else if (structure.noGroupsInSf == false) {
            final Map<String, Boolean> decryptedClients = isOrphan ? new Map<String, Boolean>() : Arc_Gen_NewGroups_Service_Helper.getdecrytedClientsId(listparticipants);
            structure = Arc_Gen_NewGroups_Service_Helper.getStructureFinal(decryptedClients, economicparticipants.groupinfo.groupid, accountNumber, groupInSF);
        }
        structure.updateStructure = updateStructure;
        return structure;
    }
    /**
    *-------------------------------------------------------------------------------
    * @Description Update the name of the Group
    *-------------------------------------------------------------------------------
    * @Author   Mario Humberto Ramirez Lio  mariohumberto.ramirez.contractor@bbva.com
    * @Date     Created: 2020-13-01
    * @param    updateStructure - Boolean to know if the group structure is active
    * @param    economicGroupName - Name of the group
    * @param    economicGroupAccNum - Account number of the group
    * @param    groupInSF - arce.Arc_Gen_Account_Wrapper with the group info
    * @return   void
    * @example  updateGroupName(updateStructure,economicGroupName,economicGroupAccNum,groupInSF)
    * -----------------------------------------------------------------------------
    */
    public void updateGroupName(Boolean updateStructure, String economicGroupName, String economicGroupAccNum, Map<String,arce.Arc_Gen_Account_Wrapper> groupInSF) {
        if (updateStructure) {
            Map<String, String> accAttr = new Map<String, String>();
            Map<Id, Map<String,String>>  mapAccsToUp = new Map<Id, Map<String,String>> ();
            accAttr.put('Name', economicGroupName);
            mapAccsToUp.put(groupInSF.get(economicGroupAccNum).accId,accAttr);
            if (!Test.isRunningTest()) {
                arce.Arc_Gen_Account_Locator.accountUpdate(mapAccsToUp);
            }
        }
    }
    /**
    *-------------------------------------------------------------------------------
    * @Description Compare the previous arch data structure against the list of participants retrieved from service
    *-------------------------------------------------------------------------------
    * @Author   juanignacio.hita.contractor@bbva.com
    * @Date     Created: 2022-03-31
    * @param    Arc_Gen_NewAnalysis_Service_Helper.PreviousARCEData prevArce
    * @param    Returnstructure structure
    * @return   void
    * @example  comparePrevStructOnline(prevArce, structure);
    * -----------------------------------------------------------------------------
    */
    public Boolean comparePrevStructOnline(Arc_Gen_NewAnalysis_Service_Helper.PreviousARCEData prevArce, Returnstructure structure) {
        Boolean changeStructure = false;
        final List<arce.Arc_Gen_Account_Has_Analysis_Wrapper> accHasLst = arce.Arc_Gen_AccHasAnalysis_Data.getARCEClientData(new Set<String>{prevArce.idARCE});
        if (accHasLst.size() == structure.participantsOnline.size()) {
            final Map<String, arce__Account_has_Analysis__c> accNumberLst = new Map<String, arce__Account_has_Analysis__c>();
            for (arce.Arc_Gen_Account_Has_Analysis_Wrapper ahaWrapper : accHasLst) {
                accNumberLst.put(ahaWrapper.accWrapperObj.accNumber, ahaWrapper.ahaObj);
            }
            for (arce.Arc_Gen_Account_Wrapper customer : structure.participantsOnline) {
                if (!accNumberLst.containsKey(customer.accNumber) && !changeStructure) {
                    changeStructure = true;
                }
            }
        } else {
            changeStructure = true;
        }
        return changeStructure;
    }
}