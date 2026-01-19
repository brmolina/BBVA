/**
* ------------------------------------------------------------------------------------------------
* @Name     Arc_Gen_NewGroups_Service_Helper
* @Author   Mario Humberto Ramirez Lio  mariohumberto.ramirez.contractor@bbva.com
* @Date     Created: 2020-13-01
* @Group    ARCE
* ------------------------------------------------------------------------------------------------
* @Description Helper class for Arc_Gen_NewGroups_service.
* ------------------------------------------------------------------------------------------------
* @Changes
*
* |2020-13-01 mariohumberto.ramirez.contractor@bbva.com
*             Class creation.
* |2020-06-24 juanignacio.hita.contractor@bbva.com
*             Changed return type value of getStructureFinal method and added isHolding parameter to structure
* |2020-09-23 saimassimilianno.jordana.contractor@bbva.com
*             Added arce. namespace to all classes that are now in the arce-dependencies package
* ------------------------------------------------------------------------------------------------
*/
public with sharing class Arc_Gen_NewGroups_Service_Helper {
    /**
    * ----------------------------------------------------------------------------------------------------
    * @Description Void Constructor to avoid warning in sonar qube
    * ----------------------------------------------------------------------------------------------------
    * @Author   Mario Humberto Ramirez Lio  mariohumberto.ramirez.contractor@bbva.com
    * @Date     Created: 2020-13-01
    * @param void
    * @return void
    * @example Arc_Gen_NewGroups_Service_Helper helper = new Arc_Gen_NewGroups_Service_Helper()
    * ----------------------------------------------------------------------------------------------------
    **/
    @TestVisible
    private Arc_Gen_NewGroups_Service_Helper() {

    }
    /**
    *-------------------------------------------------------------------------------
    * @Description get a list of decrypted clients
    *-------------------------------------------------------------------------------
    * @Author   Mario Humberto Ramirez Lio  mariohumberto.ramirez.contractor@bbva.com
    * @Date     Created: 2020-13-01
    * @param listparticipants - list participant data
    * @return Map with account number of decripted clients and is holding value
    * @example getdecrytedClientsId(listparticipants)
    * -----------------------------------------------------------------------------
    */
    public static Map<String, Boolean> getdecrytedClientsId(Arc_Gen_CallListParticipant.Innertoreturnlistp listparticipants) {
        final Map<String, Boolean> decryptedClients =  new Map<String, Boolean>();
        final List<Arc_Gen_CallListParticipant.participantobj> participants = listparticipants.customersdata;/**get encrypted data of customers from service response**/
        for(Arc_Gen_CallListParticipant.participantobj participant : participants) {
            decryptedClients.put(participant.participantId, participant.isHolding);
        }
        return decryptedClients;
    }
    /**
    *-------------------------------------------------------------------------------
    * @Description - Method to create group accounts
    *-------------------------------------------------------------------------------
    * @Author   Mario Humberto Ramirez Lio  mariohumberto.ramirez.contractor@bbva.com
    * @Date     Created: 2020-13-01
    * @param economicparticipants - economic participant data
    * @return Map<String,arce.Arc_Gen_Account_Wrapper> - map with group info
    * @example getdecrytedClientsId(economicparticipants)
    * -----------------------------------------------------------------------------
    */
    public static Map<String,arce.Arc_Gen_Account_Wrapper> createGroupAcc(Arc_Gen_CallEconomicParticipants.Innertoreturn economicparticipants) {
        final Map<String,arce.Arc_Gen_Account_Wrapper> groupWrap = new Map<String,arce.Arc_Gen_Account_Wrapper>();
        final arce.Arc_Gen_Account_Wrapper accWrap = new arce.Arc_Gen_Account_Wrapper();
        arce.Arc_Gen_ServiceAndSaveResponse createGrp = new arce.Arc_Gen_ServiceAndSaveResponse();
        Map<String, String> grpAcc = new Map<String, String>();/**if group is not finded the group is created**/
        grpAcc.put('Name', economicparticipants.groupinfo.groupname);
        grpAcc.put('AccountNumber', economicparticipants.groupinfo.groupid);
        createGrp = arce.Arc_Gen_Account_Locator.createGroup(grpAcc);/**the group is inserted**/
        accWrap.accId = createGrp.createdRsr[0];
        accWrap.name = economicparticipants.groupinfo.groupname;
        accWrap.participantType = 'Group';
        groupWrap.put(economicparticipants.groupinfo.groupid, accWrap);
        return groupWrap;
    }
    /**
    *-------------------------------------------------------------------------------
    * @Description - Method to create group accounts
    *-------------------------------------------------------------------------------
    * @Author   Mario Humberto Ramirez Lio  mariohumberto.ramirez.contractor@bbva.com
    * @Date     Created: 2020-13-01
    * @param mapAccWrapByAccNum - map with accounts info
    * @param groupInSF - map with group info
    * @return Map<String,arce.Arc_Gen_Account_Wrapper> - map with accounts info updated
    * @example updateAccounts(mapAccWrapByAccNum, groupInSF)
    * -----------------------------------------------------------------------------
    */
    public static Map<String,arce.Arc_Gen_Account_Wrapper> updateAccounts(Map<String,arce.Arc_Gen_Account_Wrapper> mapAccWrapByAccNum,arce.Arc_Gen_Account_Wrapper groupInSF) {
        final Map<String,arce.Arc_Gen_Account_Wrapper> accWrapByAccNum = mapAccWrapByAccNum;
        Map<Id, Map<String,String>>  mapAccsToUp = new Map<Id, Map<String,String>> ();
        for (String accNumber: mapAccWrapByAccNum.keySet()) {
            Map<String, String> accAttribute = new Map<String, String>();
            arce.Arc_Gen_Account_Wrapper accWrap = new arce.Arc_Gen_Account_Wrapper();
            accAttribute.put('ParentId', groupInSF.accId);
            mapAccsToUp.put(mapAccWrapByAccNum.get(accNumber).accId,accAttribute);
            accWrap = mapAccWrapByAccNum.get(accNumber);
            accWrap.accParentId = groupInSF.accId;
            accWrap.participantType = 'Client';
            accWrapByAccNum.put(accNumber, accWrap);
        }
        arce.Arc_Gen_Account_Locator.accountUpdate(mapAccsToUp);
        return accWrapByAccNum;
    }
    /**
    *-------------------------------------------------------------------------------
    * @Description - Method to create group accounts
    *-------------------------------------------------------------------------------
    * @Author   Mario Humberto Ramirez Lio  mariohumberto.ramirez.contractor@bbva.com
    * @Date     Created: 2020-13-01
    * @param decryptedClients - map with decrypted client id as key and value is holding
    * @param economicPartId - decrypted group
    * @param accountNumber - account number
    * @param groupInSF - map with group info
    * @return Arc_Gen_NewGroups_service.Returnstructure wrapper
    * @example getStructureFinal(decryptedClients, economicPartId, accountNumber, groupInSF)
    * -----------------------------------------------------------------------------
    */
    public static Arc_Gen_NewGroups_service.Returnstructure getStructureFinal(Map<String, Boolean> decryptedClients, String economicPartId, String accountNumber, Map<String,arce.Arc_Gen_Account_Wrapper> groupInSF) {
        final Arc_Gen_NewGroups_service.Returnstructure structure = new Arc_Gen_NewGroups_service.Returnstructure();
        final List<arce.Arc_Gen_Account_Wrapper> lstParticipantsWrap = new List<arce.Arc_Gen_Account_Wrapper>();
        final List<Account> accountsInSF = new List<Account>();
        final Boolean updateStructure = arce.Arc_Gen_GenericUtilities.getUpdateStructure();
        final List<String> decryptedClientsId = new List<String>(decryptedClients.keySet());
        Map<String,arce.Arc_Gen_Account_Wrapper> mapAccWrapByAccNum = arce.Arc_Gen_Account_Locator.getAccountByAccNumber(decryptedClientsId);

        if (updateStructure) {
            mapAccWrapByAccNum = updateAccounts(mapAccWrapByAccNum, groupInSF.get(economicPartId));
        }
        for (String accNumber : mapAccWrapByAccNum.keySet()) {
            arce.Arc_Gen_Account_Wrapper accWrapParticipant = new arce.Arc_Gen_Account_Wrapper();
            Account accParticipant = new Account();
            accWrapParticipant = mapAccWrapByAccNum.get(accNumber);
            accParticipant.Id = accWrapParticipant.accId;
            accParticipant.Name = accWrapParticipant.name;
            accParticipant.AccountNumber = accWrapParticipant.accNumber;
            accParticipant.ParentId = groupInSF.get(economicPartId).accId;
            accountsInSF.add(accParticipant);
            lstParticipantsWrap.add(accWrapParticipant);
        }
        lstParticipantsWrap.add(groupInSF.get(economicPartId));
        structure.participantsinSF = accountsInSF;
        structure.participantsOnline = lstParticipantsWrap;
        structure.groupID = groupInSF.get(economicPartId) == null ? accountNumber :groupInSF.get(economicPartId).accId;
        structure.noGroupsInSf = false;
        structure.isHolding = decryptedClients;
        return structure;
    }
}