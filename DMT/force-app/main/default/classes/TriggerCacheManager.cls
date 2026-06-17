/**
 * @description Clase centralizada para cachear datos frecuentemente consultados en triggers.
 *              Evita queries SOQL redundantes dentro de una misma transacción.
 * @author Optimización de triggers - BBVA
 * @date 2024
 */
public without sharing class TriggerCacheManager {
    
    // ============================================================================
    // SINGLETON PATTERN - Una sola instancia por transacción
    // ============================================================================
    private static TriggerCacheManager instance;
    
    public static TriggerCacheManager getInstance() {
        if (instance == null) {
            instance = new TriggerCacheManager();
        }
        return instance;
    }
    
    private TriggerCacheManager() {
        // Constructor privado para singleton
    }
    
    // ============================================================================
    // CACHE DE PROFILE DEL USUARIO ACTUAL
    // ============================================================================
    private String currentUserProfileName;
    
    public String getCurrentUserProfileName() {
        if (currentUserProfileName == null) {
            currentUserProfileName = [
                SELECT Name 
                FROM Profile 
                WHERE Id = :UserInfo.getProfileId() 
                LIMIT 1
            ].Name;
        }
        return currentUserProfileName;
    }

    // ============================================================================
    // CACHE DE USER ACTUAL (completo)
    // ============================================================================
    private User currentUser;

    public User getCurrentUser() {
        if (currentUser == null) {
            currentUser = [
                SELECT Id, Name, ProfileId, Profile.Name, ID_User__c 
                FROM User 
                WHERE Id = :UserInfo.getUserId() 
                LIMIT 1
            ];
        }
        return currentUser;
    }

    public String getCurrentUserName() {
        return getCurrentUser().Name;
    }

    // ============================================================================
    // CACHE DE ACCOUNT "CLIENT NBC" (para fillClientNBCVisit)
    // ============================================================================
    private Id clientNbcAccountId;
    private Boolean clientNbcAccountQueried = false;

    public Id getClientNbcAccountId() {
        if (!clientNbcAccountQueried) {
            Id rtypeId = Schema.SObjectType.Account.getRecordTypeInfosByName()
                .get(Label.DES_RT_CLIENT_NBC).getRecordTypeId();
            
            List<Account> accounts = [
                SELECT Id 
                FROM Account 
                WHERE RecordTypeId = :rtypeId 
                LIMIT 1
            ];
            
            clientNbcAccountId = accounts.isEmpty() ? null : accounts[0].Id;
            clientNbcAccountQueried = true;
        }
        return clientNbcAccountId;
    }


    // ============================================================================
    // CACHE DE NBC_MEMBERS POR REGIÓN (para futureFillMembers)
    // ============================================================================
    private Map<String, List<NBC_Member__c>> nbcMembersByRegion;

    public Map<String, List<NBC_Member__c>> getNbcMembersByRegion() {
        if (nbcMembersByRegion == null) {
            nbcMembersByRegion = new Map<String, List<NBC_Member__c>>{
                'NBC_REGION_EMEA' => new List<NBC_Member__c>(),
                'NBC_REGION_LATAM' => new List<NBC_Member__c>(),
                'NBC_REGION_USA' => new List<NBC_Member__c>()
            };
            
            // UNA SOLA QUERY en lugar de 3
            for (NBC_Member__c member : [
                SELECT Id, BBVA_participant__c, Other_BBVA_participant__c, 
                    region_emea__c, region_latam__c, region_usa__c 
                FROM NBC_Member__c 
                WHERE region_emea__c = true 
                OR region_latam__c = true 
                OR region_usa__c = true
            ]) {
                if (member.region_emea__c) {
                    nbcMembersByRegion.get('NBC_REGION_EMEA').add(member);
                }
                if (member.region_latam__c) {
                    nbcMembersByRegion.get('NBC_REGION_LATAM').add(member);
                }
                if (member.region_usa__c) {
                    nbcMembersByRegion.get('NBC_REGION_USA').add(member);
                }
            }
        }
        return nbcMembersByRegion;
    }

    public List<NBC_Member__c> getNbcMembersEMEA() {
        return getNbcMembersByRegion().get('NBC_REGION_EMEA');
    }

    public List<NBC_Member__c> getNbcMembersLATAM() {
        return getNbcMembersByRegion().get('NBC_REGION_LATAM');
    }

    public List<NBC_Member__c> getNbcMembersUSA() {
        return getNbcMembersByRegion().get('NBC_REGION_USA');
    }
        
    // ============================================================================
    // CACHE DE CUSTOM METADATA - WVL_ActivateConfigPdfTemplate__mdt
    // ============================================================================
    private List<WVL_ActivateConfigPdfTemplate__mdt> activateConfigPdfTemplate;
    
    public List<WVL_ActivateConfigPdfTemplate__mdt> getActivateConfigPdfTemplate() {
        if (activateConfigPdfTemplate == null) {
            activateConfigPdfTemplate = [
                SELECT DeveloperName, ActivateDate__c 
                FROM WVL_ActivateConfigPdfTemplate__mdt 
                LIMIT 1
            ];
        }
        return activateConfigPdfTemplate;
    }
    
    // ============================================================================
    // CACHE DE CUSTOM METADATA - WVL_ConfigPdfTemplate__mdt
    // ============================================================================
    private List<WVL_ConfigPdfTemplate__mdt> configPdfTemplate;
    
    public List<WVL_ConfigPdfTemplate__mdt> getConfigPdfTemplate() {
        if (configPdfTemplate == null) {
            configPdfTemplate = [
                SELECT DeveloperName, WVL_fld_NombreCampo__c, WVL_fld_NumMaxCaracteresLinea__c,
                       WVL_fld_NumMaximoLineas__c, CSL__c, CSL_Compass__c, ECA__c, GTB__c, PF__c 
                FROM WVL_ConfigPdfTemplate__mdt 
                LIMIT 1000
            ];
        }
        return configPdfTemplate;
    }
    
    // ============================================================================
    // CACHE DE CUSTOM METADATA - WVL_ConfigTextLimitTemplate__mdt
    // ============================================================================
    private List<WVL_ConfigTextLimitTemplate__mdt> configTextLimitTemplate;
    
    public List<WVL_ConfigTextLimitTemplate__mdt> getConfigTextLimitTemplate() {
        if (configTextLimitTemplate == null) {
            configTextLimitTemplate = [
                SELECT DeveloperName, WVL_fld_NombreCampo__c, CSL__c, CSL_Compass__c, ECA__c, GTB__c, PF__c 
                FROM WVL_ConfigTextLimitTemplate__mdt 
                LIMIT 1000
            ];
        }
        return configTextLimitTemplate;
    }
    
    // ============================================================================
    // CACHE DE CUSTOM METADATA - Opp_Countries__mdt
    // ============================================================================
    private List<Opp_Countries__mdt> oppCountries;
    private Map<String, String> countryToRegionMap;
    
    public List<Opp_Countries__mdt> getOppCountries() {
        if (oppCountries == null) {
            oppCountries = [
                SELECT Label, DeveloperName, Opp_Region__c 
                FROM Opp_Countries__mdt 
                LIMIT 300
            ];
        }
        return oppCountries;
    }
    
    public Map<String, String> getCountryToRegionMap() {
        if (countryToRegionMap == null) {
            countryToRegionMap = new Map<String, String>();
            for (Opp_Countries__mdt country : getOppCountries()) {
                countryToRegionMap.put(country.DeveloperName, country.Opp_Region__c);
            }
        }
        return countryToRegionMap;
    }
    
    // ============================================================================
    // CACHE DE CUSTOM METADATA - DES_XB_Country__mdt (Cross Border)
    // ============================================================================
    private List<DES_XB_Country__mdt> xbCountries;
    private Set<String> europeCountries;
    private Set<String> asiaCountries;
    private Set<String> specialCountries;
    
    public List<DES_XB_Country__mdt> getXBCountries() {
        if (xbCountries == null) {
            xbCountries = [
                SELECT Id, DeveloperName, Label, DES_XB_Region__c 
                FROM DES_XB_Country__mdt 
                LIMIT 20000
            ];
            // Inicializar los sets de regiones
            europeCountries = new Set<String>();
            asiaCountries = new Set<String>();
            specialCountries = new Set<String>();
            
            for (DES_XB_Country__mdt country : xbCountries) {
                if (country.DES_XB_Region__c == 'Europe') {
                    europeCountries.add(country.DeveloperName);
                } else if (country.DES_XB_Region__c == 'Asia') {
                    asiaCountries.add(country.DeveloperName);
                } else if (country.DES_XB_Region__c == 'Special Country') {
                    specialCountries.add(country.DeveloperName);
                }
            }
        }
        return xbCountries;
    }
    
    public Set<String> getEuropeCountries() {
        if (europeCountries == null) {
            getXBCountries(); // Esto inicializa todos los sets
        }
        return europeCountries;
    }
    
    public Set<String> getAsiaCountries() {
        if (asiaCountries == null) {
            getXBCountries();
        }
        return asiaCountries;
    }
    
    public Set<String> getSpecialCountries() {
        if (specialCountries == null) {
            getXBCountries();
        }
        return specialCountries;
    }
    
    // ============================================================================
    // CACHE DE CUSTOM METADATA - Opportunity_Expected_Probability__mdt
    // ============================================================================
    private Map<String, Decimal> stageToExpectedProbabilityMap;
    
    public Map<String, Decimal> getStageToExpectedProbabilityMap() {
        if (stageToExpectedProbabilityMap == null) {
            stageToExpectedProbabilityMap = new Map<String, Decimal>();
            for (Opportunity_Expected_Probability__mdt oppExpProb : [
                SELECT Opportunity_Stage_Name__c, Expected_Probability__c
                FROM Opportunity_Expected_Probability__mdt 
                LIMIT 5000
            ]) {
                stageToExpectedProbabilityMap.put(
                    oppExpProb.Opportunity_Stage_Name__c.toUpperCase(), 
                    oppExpProb.Expected_Probability__c
                );
            }
        }
        return stageToExpectedProbabilityMap;
    }
    
    // ============================================================================
    // CACHE DE USUARIOS S&P (para checkIndustryEdit)
    // ============================================================================
    private Set<Id> spUserIds;
    
    public Set<Id> getSPUserIds() {
        if (spUserIds == null) {
            spUserIds = new Set<Id>();
            for (User u : [
                SELECT Id 
                FROM User 
                WHERE Profile.Name = :Label.DES_SP_PROFILE
            ]) {
                spUserIds.add(u.Id);
            }
        }
        return spUserIds;
    }
    
    // ============================================================================
    // CACHE DE RECORD TYPES
    // ============================================================================
    private Map<Id, String> recordTypeIdToDevName;
    
    public Map<Id, String> getRecordTypeIdToDevName(String sObjectName) {
        if (recordTypeIdToDevName == null) {
            recordTypeIdToDevName = new Map<Id, String>();
        }
        
        // Si no tenemos datos para este objeto, los cargamos
        Schema.SObjectType sObjectType = Schema.getGlobalDescribe().get(sObjectName);
        if (sObjectType != null) {
            Map<Id, Schema.RecordTypeInfo> rtMap = sObjectType.getDescribe().getRecordTypeInfosById();
            for (Id rtId : rtMap.keySet()) {
                if (!recordTypeIdToDevName.containsKey(rtId)) {
                    recordTypeIdToDevName.put(rtId, rtMap.get(rtId).getDeveloperName());
                }
            }
        }
        
        return recordTypeIdToDevName;
    }
    
    public String getRecordTypeDevName(String sObjectName, Id recordTypeId) {
        if (recordTypeId == null) {
            return 'CSL'; // Default
        }
        Map<Id, String> rtMap = getRecordTypeIdToDevName(sObjectName);
        return rtMap.containsKey(recordTypeId) ? rtMap.get(recordTypeId) : 'CSL';
    }
    
    // ============================================================================
    // CACHE DE GLOBAL SETTINGS
    // ============================================================================
    private Global_Desktop_Settings__c globalDesktopSettings;
    
    public Global_Desktop_Settings__c getGlobalDesktopSettings() {
        if (globalDesktopSettings == null) {
            globalDesktopSettings = Global_Desktop_Settings__c.getInstance();
        }
        return globalDesktopSettings;
    }
    
    public Boolean isAutoExpectedProbabilityEnabled() {
        return getGlobalDesktopSettings().Opportunity_Auto_Expected_Probability__c;
    }
    
    // ============================================================================
    // MÉTODO PARA LIMPIAR CACHÉ (útil para tests)
    // ============================================================================
    @TestVisible
    private static void clearCache() {
        instance = null;
    }
}