/**
 * @description       : Class to control the creation of Lightning Web Component for flexcards. Is the controller for the LWC des_omnistudioadmin
 * @author            : Aníbal Cortés
 * @group             :
 * @last modified on  : 07-10-2025
 * @last modified by  : Aníbal Cortés
**/
public without sharing class DES_OmnistudioAdmin_Controller {

    private static final String STAGING_PREFIX = 'STAGING-';
    private static final String TEMP_SUFFIX = '_SWAP_TEMP';

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


    /**
    * @description Method used to refresh (meaning, deactiviting and activiting) one specific Integration Procedure
    * @author Aníbal Cortés | 10/07/2025
    * @param integrationProcedureId
    * @param ipName
    * @return String
    **/
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

    /**
    * @description Method used to swap Data Mapper Versions between staging and normal ones
    * @author Aníbal Cortés | 18/11/2025
    **/
    @AuraEnabled
    public static void swapDataMapperVersions() {

        // Creating maps for normal name Data Mappers and Staging ones
        Map<String, OmniDataTransform> normalMappers = new Map<String, OmniDataTransform>();
        Map<String, OmniDataTransform> stagingMappers = new Map<String, OmniDataTransform>();

        // Construir la consulta dinámicamente
        List<OmniDataTransform> allDataMappersFromOrg = [SELECT Id, Name, UniqueName FROM OmniDataTransform] ;

        for (OmniDataTransform dm : allDataMappersFromOrg) {
            String currentName = dm.Name;

            if (currentName != null && currentName.startsWith(STAGING_PREFIX)) {
                // It is a STAGING record
                String baseName = currentName.removeStart(STAGING_PREFIX);
                stagingMappers.put(baseName, dm);
            } else if (currentName != null) {
                // It is a normal record
                normalMappers.put(currentName, dm);
            }
        }

        // The update will be in two phases, so we create two lists.
        List<SObject> firstPassUpdate = new List<SObject>(); // First phase
        List<SObject> tempRecordsForSecondPass = new List<SObject>(); // Second phase

        // We iterate over normal data mappers to find pairs
        for (String baseName : normalMappers.keySet()) {

            // Check if it has STAGING counterpart
            if (stagingMappers.containsKey(baseName)) {

                // We found a pair so we store it
                OmniDataTransform normalMapper = normalMappers.get(baseName);
                OmniDataTransform stagingMapper = stagingMappers.get(baseName);

                // Guardar valores originales para el intercambio
                String originalProdName = normalMapper.Name;
                String originalProdUnique = normalMapper.UniqueName;
                String originalStagingName = stagingMapper.Name;
                String originalStagingUnique = stagingMapper.UniqueName;

                // --- PASE 1 ---

                // A. Rename Normal (the one that is going to be STAGING) to a temp value
                // (Example: 'MiMapper' -> 'STAGING-MiMapper_SWAP_TEMP')
                SObject prodToTemp = OmniDataTransform.getSObjectType().newSObject(normalMapper.Id);
                prodToTemp.put('Name', originalStagingName + TEMP_SUFFIX);
                prodToTemp.put('UniqueName', originalStagingUnique + TEMP_SUFFIX);

                firstPassUpdate.add(prodToTemp);
                tempRecordsForSecondPass.add(prodToTemp); // Store reference for Phase 2

                // B. Rename STAGING (the one that is going to be the normal) to its final value
                // (Ej: 'STAGING-MiMapper' -> 'MiMapper')
                SObject stagingToProd = OmniDataTransform.getSObjectType().newSObject(stagingMapper.Id);
                stagingToProd.put('Name', originalProdName);
                stagingToProd.put('UniqueName', originalProdUnique);

                firstPassUpdate.add(stagingToProd);
            }
        }

        // 4. Execute phase 1 update
        if (firstPassUpdate.isEmpty()) {
            System.debug('DataMapperVersionSwitcher: No se encontraron pares para intercambiar.');
            return;
        }

        // We use allOrNone to false
        List<Database.SaveResult> firstResults = Database.update(firstPassUpdate, false);

        // 5. Prepare phase 2 only for the records that passed to TEMP successfully
        List<SObject> secondPassUpdate = new List<SObject>();
        Set<Id> successfulTempIds = new Set<Id>();
        Map<Id, SObject> tempRecordMap = new Map<Id, SObject>(tempRecordsForSecondPass);

        // Identify which ones were correctly passed into TEMP
        for (Database.SaveResult sr : firstResults) {
            if (sr.isSuccess() && tempRecordMap.containsKey(sr.getId())) {
                successfulTempIds.add(sr.getId());
            } else if (!sr.isSuccess()) {
                 System.debug('DataMapperVersionSwitcher: Error en Pase 1 para ' + sr.getId() + ': ' + sr.getErrors()[0].getMessage());
            }
        }

        // Create records for Phase 2
        for (Id tempId : successfulTempIds) {
            SObject tempRecord = tempRecordMap.get(tempId);
            String tempName = (String)tempRecord.get('Name');
            String tempUniqueName = (String)tempRecord.get('UniqueName');

            // Rename TEMP to STAGING (final)
            // (Ej: 'STAGING-MiMapper_SWAP_TEMP' -> 'STAGING-MiMapper')
            SObject tempToStaging = OmniDataTransform.getSObjectType().newSObject(tempId);
            tempToStaging.put('Name', tempName.removeEnd(TEMP_SUFFIX));
            tempToStaging.put('UniqueName', tempUniqueName.removeEnd(TEMP_SUFFIX));
            secondPassUpdate.add(tempToStaging);
        }

        // 6. Execute Phase 2
        if (!secondPassUpdate.isEmpty()) {
            List<Database.SaveResult> secondResults = Database.update(secondPassUpdate, false);

            // Register final errors
            for(Database.SaveResult sr : secondResults) {
                 if (!sr.isSuccess()) {
                     System.debug('DataMapperVersionSwitcher: Error en Pase 2 para ' + sr.getId() + ': ' + sr.getErrors()[0].getMessage());
                 }
            }
        }
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