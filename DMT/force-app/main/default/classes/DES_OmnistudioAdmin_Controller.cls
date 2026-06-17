/**
 * @description       : Class to control the creation of Lightning Web Component for flexcards. Is the controller for the LWC des_omnistudioadmin
 * @author            : Aníbal Cortés
 * @group             : 
 * @last modified on  : 07-10-2025
 * @last modified by  : Aníbal Cortés
**/
public without sharing class DES_OmnistudioAdmin_Controller {

    /**
    * @description Method that refreshes all flexcards from ORG, it is primarily used on deployments
    * @author Aníbal Cortés | 07-10-2025 
    * @return String 
    **/
    @AuraEnabled
    public static String refreshAllFlexcardsLatestVersion() {
        List<OmniUiCard> omniUiCardListDesactive = [select Id,IsActive  from OmniUiCard where isActive  = true];

        for (OmniUiCard flexcard : omniUiCardListDesactive) {    
            flexcard.isActive = false;
        }

        update omniUiCardListDesactive;

        AggregateResult[] groupedResults = [SELECT Name n, MAX(VersionNumber) n3 FROM OmniUiCard GROUP BY Name];

        String queryFlexcards = 'SELECT Id, isActive FROM OmniUiCard WHERE ';

        for (AggregateResult ar : groupedResults) {
            queryFlexcards += '(Name = \'' + (String) ar.get('n') + '\' AND VersionNumber = ' + (Decimal) ar.get('n3') + ') OR ';
        }

        queryFlexcards = queryFlexcards.removeEndIgnoreCase('OR ');

        List<OmniUiCard> flexCardsToActivate = Database.query(String.escapeSingleQuotes(queryFlexcards).replaceAll('\\\\', ''));

        List<OmniUiCard> flexCardsToUpdate = new List<OmniUiCard>();

        for (OmniUiCard flexcard : flexCardsToActivate)  {
            flexcard.IsActive = true;
            flexCardsToUpdate.add(flexcard);
        }

        Boolean success = false;
        Integer contadorIntentos = 10;
        List<Database.SaveResult> updatedFlexcardsResult = makeUpdateOfFlexcards(flexCardsToUpdate);
        while (!success && contadorIntentos > 0) {
            List<OmniUiCard> flexCardsToRelaunch = new List<OmniUiCard>();
            success = true;
            for (Database.SaveResult saveResult : updatedFlexcardsResult) {
                if (!saveResult.isSuccess()) {
                success = false;
                OmniUiCard flexcard = new OmniUiCard();
                flexcard.Id = saveResult.getId();
                flexcard.IsActive = true;
                flexCardsToRelaunch.add(flexcard);
                }
            }
            if (flexCardsToRelaunch.size() > 0) {
                updatedFlexcardsResult =  makeUpdateOfFlexcards(flexCardsToRelaunch);
            }
            contadorIntentos--;
        }

        String baseUrl = URL.getOrgDomainUrl().toExternalForm();  String finalUrl;
        if (baseUrl.contains('sandbox')) {
            finalUrl = baseUrl;  finalUrl += '/apex/omnistudio__FlexCardCompilePage?id=';
        } else {
            finalUrl = baseUrl;    finalUrl += '/apex/omnistudio__FlexCardCompilePage?id=';
        }
        for (OmniUiCard flexcard : flexCardsToUpdate) {    
            finalUrl = finalUrl + flexcard.Id + '%2C';
        }
        finalUrl = finalUrl.removeEndIgnoreCase(',');

        return finalUrl;
    }

    @AuraEnabled
    public static String refreshSpecificIntegrationProcedure(String integrationProcedureId, String ipName) {
        List<OmniProcess> ipActive = [SELECT Id, Name, VersionNumber, IsActive FROM OmniProcess where IsIntegrationProcedure = true AND Name = :ipName and IsActive = true ORDER BY Name ASC];
        OmniProcess integrationObject = new OmniProcess();
        integrationObject.Id = integrationProcedureId;
        if (ipActive.size() > 0) {
            ipActive.get(0).isActive = false;
            update ipActive;
        }

        integrationObject.isActive = true;

        update integrationObject;

        String baseUrl = URL.getOrgDomainUrl().toExternalForm();
        String finalUrl;
        finalUrl = baseUrl + '/apex/omnistudio__OmniLwcCompile?id=' + integrationProcedureId +'&activate=true';

        return finalUrl;
    }

    @AuraEnabled
    public static String refreshSpecificFlexcard(String flexcardId, String flexcardName) {
        List<OmniUiCard> flexcardActive = [select Id,IsActive  from OmniUiCard where Name = :flexcardName AND isActive  = true];
        OmniUiCard flexcardObject = [SELECT Id, IsActive FROM OmniUiCard WHERE Id = :flexcardId];

        if (flexcardActive.size() > 0) {
            flexcardActive.get(0).isActive = false;
            update flexcardActive; // Ahora el update solo cambia IsActive
        }

        flexcardObject.isActive = true;
        update flexcardObject;

        String baseUrl = URL.getOrgDomainUrl().toExternalForm();
        String finalUrl = baseUrl + '/apex/omnistudio__FlexCardCompilePage?id=' + flexcardId;

        return finalUrl;
    }

    @AuraEnabled
    public static List<WRAPPER_OmnistudioComponents> returnAllIntegrationProcedureWithVersions() {
        List<WRAPPER_OmnistudioComponents> listIPs = new List<WRAPPER_OmnistudioComponents>();
        List<OmniProcess> allIntegrationProcedures = [SELECT Id, Name, VersionNumber, IsActive FROM OmniProcess where IsIntegrationProcedure = true ORDER BY Name ASC];

        for (OmniProcess ip : allIntegrationProcedures) {
            WRAPPER_OmnistudioComponents wrapIP = new WRAPPER_OmnistudioComponents();
            wrapIP.omniId = ip.Id;
            wrapIP.omniName = ip.Name;
            wrapIP.omniVersionNumber = ip.VersionNumber;

            listIPs.add(wrapIP);
        }
        return listIPs;
    }

    @AuraEnabled
    public static List<WRAPPER_OmnistudioComponents> returnAllFlexcardsWithVersions() {
        List<WRAPPER_OmnistudioComponents> listFlexcards = new List<WRAPPER_OmnistudioComponents>();
        List<OmniUiCard> allFlexcards = [SELECT Id, Name, VersionNumber, IsActive FROM OmniUiCard ORDER BY Name ASC];

        for (OmniUiCard flexcard : allFlexcards) {
            WRAPPER_OmnistudioComponents wrapFlexcard = new WRAPPER_OmnistudioComponents();
            wrapFlexcard.omniId = flexcard.Id;
            wrapFlexcard.omniName = flexcard.Name;
            wrapFlexcard.omniVersionNumber = flexcard.VersionNumber;

            listFlexcards.add(wrapFlexcard);
        }
        return listFlexcards;
    }

    private static List<Database.SaveResult> makeUpdateOfFlexcards(List<OmniUiCard> flexCardsToUpdate) {
        return Database.update(flexCardsToUpdate, false);
    }


    /**
     * @description Class Wrapper to LWC component
     */
    public class WRAPPER_OmnistudioComponents {
        @AuraEnabled
        public String omniId;
        @AuraEnabled
        public String omniName;
        @AuraEnabled
        public Decimal omniVersionNumber;
    }

}