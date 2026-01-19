/*---------------------------------------------------------------------------------------------
    Company:       BBVA
    Description:   This class contains methods related to GTB Cases.

    History:
    <Date>          <Author>                <Description>
    22/03/2019      Javier Touchard         Initial Version.
----------------------------------------------------------------------------------------------*/
public with sharing class SER_CaseMethodsGTB {
    /*Constante '*'*/
    public static final String ASTERISCO = '*';
    /*Constante 'SIN FECHA'*/
    public static final String SINFECHA = 'SIN FECHA';
    /**Record Type'GTB User'*/
    public final static Id RT_GTB;
    /**Record Type 'Closed Case GTB User'*/
    public final static Id RT_CLOSE_GTB;
    static {
        RT_GTB = [SELECT Id FROM RecordType WHERE DeveloperName = 'SER_GTB_User'].Id;
        RT_CLOSE_GTB = [SELECT Id FROM RecordType WHERE DeveloperName = 'SER_Closed_Case_GTB_User'].Id;
    }

    /*---------------------------------------------------------------------------------------
        Company:       BBVA
        Description:   private constructor.
    ---------------------------------------------------------------------------------------*/
    private SER_CaseMethodsGTB() {}


    /*-------------------------------------------------------------------------------------------
        Company:       BBVA
        Description:   The method return true if one of the cases have GTB record type.

        IN:            List<Case> newList.
        OUT:           Boolean

        History:
        <Date>                  <Author>                <Change Description>
        15/03/2019              Javier Touchard         Initial Version
    ---------------------------------------------------------------------------------------------*/
    public static Boolean isGTB(List<Case> newList) {
        Boolean response;
        response = false;
        for(Case caso : newList) {
            if(caso.RecordTypeId == RT_GTB || caso.RecordTypeId == RT_CLOSE_GTB ) {
                response = true;
            }
        }
        return response;
    }

    /*-------------------------------------------------------------------------------------------
        Company:       BBVA
        Description:   Method that assign GTB Case Approvers.

        IN:            Map<Id,Case> newMap
        OUT:           void

        History:
        <Date>                  <Author>                <Change Description>
        15/03/2019              Javier Touchard         Initial Version
    ---------------------------------------------------------------------------------------------*/
    public static void assigGTBApprovers(List<Case> newList) {
        try {
            List<SER_Assignment_GTB_Approvers__c> csList;
            csList = SER_Assignment_GTB_Approvers__c.getAll().values();
            Map<String, Id> claimsMap;
            claimsMap = New Map<String, Id>();
            for(SER_Claim_Approver__c claim : [SELECT claim_approval_user_id__c,claim_aprvl_user_hier_auth_type__c,branch_id__c FROM SER_Claim_Approver__c WHERE claim_approval_user_ind_type__c = true]) {
                claimsMap.put(claim.claim_aprvl_user_hier_auth_type__c + ' ' + claim.branch_id__c,claim.claim_approval_user_id__c);
            }
            for(Case caso : newList) {
                treatCase(caso,claimsMap,csList);
            }
        } catch(Exception e) {
            System.debug('---->>>>assigGTBApprovers EXCEPTION: ' + e.getMessage());
        }
    }

    /*-------------------------------------------------------------------------------------------
        Company:       BBVA
        Description:   Method that set the case seniority.

        IN:            Case caso.
        OUT:           Integer.

        History:
        <Date>                  <Author>                <Change Description>
        27/03/2019              Javier Touchard         Initial Version
    ---------------------------------------------------------------------------------------------*/
    private static Integer setSeniority(Case caso) {
        Integer response;
        response = 0;
        if(caso.SER_Close__c) {
            response = caso.data_incidence_date__c.daysBetween(Date.valueOf(caso.ClosedDate));
        } else {
            response = caso.data_incidence_date__c.daysBetween(Date.valueOf(Date.today()));
        }
        return response;
    }

    /*-------------------------------------------------------------------------------------------
        Company:       BBVA
        Description:   Method to treat the cases.

        IN:            Case caso.
        IN:            Map<String, Id> claimsMap.
        IN:            List<SER_Assignment_GTB_Approvers__c> csList.
        OUT:           Void.

        History:
        <Date>                  <Author>                <Change Description>
        27/03/2019              Javier Touchard         Initial Version
    ---------------------------------------------------------------------------------------------*/
    private static void treatCase(Case caso,Map<String, Id> claimsMap,List<SER_Assignment_GTB_Approvers__c> csList) {
        Boolean isGTB;
        isGTB = caso.RecordTypeId == RT_GTB || caso.RecordTypeId == RT_CLOSE_GTB;
        if(isGTB) {
            for(SER_Assignment_GTB_Approvers__c gtbCS : csList) {
                if(assignApprovers(gtbCS, caso)) {
                    caso.SER_Authorizer_1__c = claimsMap.get(gtbCS.SER_Delegation_Level__c + ' ' + caso.SER_Office__c);
                }
            }
        }
    }

    /*-------------------------------------------------------------------------------------------
        Company:       BBVA
        Description:   Method that determines the cases in which an approver must be assigned.

        IN:            SER_Assignment_GTB_Approvers__c gtbCS
        IN:            Case caso
        OUT:           Boolean

        History:
        <Date>                  <Author>                <Change Description>
        15/03/2019              Javier Touchard         Initial Version
    ---------------------------------------------------------------------------------------------*/
    public static Boolean assignApprovers(SER_Assignment_GTB_Approvers__c gtbCS, Case caso) {
        Boolean caseType;
        caseType = gtbCS.SER_Type__c.equalsIgnoreCase(caso.Type);
        Boolean amount;
        amount = false;
        Boolean days;
        days = false;
        if(caseType) {
            Boolean rango;
            rango = gtbCS.SER_Amount_Operator__c == ASTERISCO && caso.return_euro_amount__c >= gtbCS.SER_Amount_to_be_repaid_2__c && caso.return_euro_amount__c <= gtbCS.SER_Amount_to_be_repaid__c;
            Boolean amountNotRange;
            amountNotRange = gtbCS.SER_Amount_Operator__c != ASTERISCO;
            if(rango) {
                amount = true;
            } else if(amountNotRange) {
                amount = gtbCS.SER_Amount_Operator__c == '<=' ? caso.return_euro_amount__c <= gtbCS.SER_Amount_to_be_repaid__c : caso.return_euro_amount__c > gtbCS.SER_Amount_to_be_repaid__c;
            }
            Integer antiguedad;
            antiguedad = setSeniority(caso);
            Boolean rangoDias;
            rangoDias = gtbCS.SER_Days_Operator__c == ASTERISCO && antiguedad >= gtbCS.Days_2__c && antiguedad <= gtbCS.SER_Days__c;
            Boolean specialCases;
            specialCases = rangoDias || gtbCS.SER_Days_Operator__c == SINFECHA;
            Boolean daysNotRange;
            daysNotRange = gtbCS.SER_Days_Operator__c != ASTERISCO;
            if(specialCases) {
                days = true;
            } else if(daysNotRange) {
                days = gtbCS.SER_Days_Operator__c == '<=' ? antiguedad <= gtbCS.SER_Days__c : antiguedad > gtbCS.SER_Days__c;
            }
        }
        return amount && days && caseType;
    }

    /*-------------------------------------------------------------------------------------------
        Company:       BBVA
        Description:   Method that assign GTB Case Owners.

        IN:            Case casoInfo
        IN:            Case caso
        IN:            Id queueId
        OUT:           void

        History:
              <Date>                   <Author>            <Change Description>
            15/03/2019              Javier Touchard         Initial Version
    ---------------------------------------------------------------------------------------------*/
    public static void assigGtbOwners(Case casoInfo,Case caso,Id queueId,Map<Id,String> mapCaseFromEmail) {
        List<String> userCodeList;
        userCodeList = new List<String>();
        for(Assignment_GTB_owners__c csGTB : Assignment_GTB_owners__c.getAll().values()) {
            userCodeList.add(csGTB.SER_ID_User__c);
        }
        Map<String,Id> userCodeIdMap;
        userCodeIdMap = new Map<String,Id>();
        for(User user : [SELECT Id,ID_User__c FROM User WHERE ID_User__c IN :userCodeList AND IsActive = true]) {
            userCodeIdMap.put(user.ID_User__c,user.Id);
        }
        Map<String,Id> csGTBOwners;
        csGTBOwners = new Map<String,Id>();
        for(Assignment_GTB_owners__c csGTB : Assignment_GTB_owners__c.getAll().values()) {
            csGTBOwners.put(csGTB.fromEmail__c,userCodeIdMap.get(csGTB.SER_ID_User__c));
        }
        Boolean isGTBE2C;
        isGTBE2C = String.isNotBlank(casoInfo.SER_EmailToCaseCode__c) && mapCaseFromEmail.get(casoInfo.Id) != null
                                        && casoInfo.Origin == 'Email GTB' && csGTBOwners.get(mapCaseFromEmail.get(casoInfo.Id)) != null
                                        && (casoInfo.Recordtype.DeveloperName == 'SER_GTB_User' || casoInfo.Recordtype.DeveloperName == 'SER_Closed_Case_GTB_User');
        if(isGTBE2C) {
            caso.OwnerId = csGTBOwners.get(mapCaseFromEmail.get(casoInfo.Id));
        } else {
            caso.OwnerId = queueId;
        }
    }
}