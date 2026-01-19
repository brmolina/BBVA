/***************************************************************************************
Name:           GroupGeographyCnt class
Description:    Controlador para devolver lista de localizaciones para mostrar en el mapa GroupGeography cmp
Apex Tests:     GroupGeographyCntTest

Version        Date            Author                       Summary of changes
-----------------------------------------------------------------------------------------
0.1            22/11/2018       GlobalDesktop - APC         Initial Version
0.2            12/12/2018       GlobalDesktop - APC         Description with other info - Transactional Banker and Revenues
0.3            24/05/2019       GlobalDesktop - APC         Description of flags changed: only display the SUM of affiliates
***************************************************************************************/
public with sharing class GroupGeographyCnt {


    /*
    * @author Global Desktop
    * @Description obtiene las cuentas
    */
    @AuraEnabled
    public static List<Location> getAccount(String clientId) {

        System.debug(':::::::GroupGeographyCnt.getAccount init ');
        final List<Location> listLoc = new List<Location>();
        final List<DES_Subsidiary_Group_Relation__c> lstAcc =  [SELECT Id, participant_child_id__c, participant_child_id__r.Name, participant_child_id__r.DES_Country_Client__c,
                                                            participant_parent_id__c, participant_parent_id__r.Name, participant_parent_id__r.DES_Country_Client__c,
                                                            participant_parent_id__r.DES_Global_banker__c,   participant_parent_id__r.DES_Global_banker__r.LastName, participant_parent_id__r.DES_Global_banker__r.FirstName
                                                        FROM DES_Subsidiary_Group_Relation__c
                                                        WHERE participant_parent_id__c = :clientId
                                                            AND participant_child_id__r.DES_Country_Client__c != ''
                                                            AND main_subsidiary_ind_type__c = true];

        System.debug('::lstAcc - ' + lstAcc);

        if(!lstAcc.isEmpty()) {
            final Map<String,List<Info>> mapResultGrouped = new Map<String,List<Info>>();
            final List<Opp_Countries__mdt> lstCountryCodes = mapCountryCodesSelector();
            final Map<String,Integer> mapDescripPerCountry = new Map<String,Integer>();
            final Map<String,String> mapRegionPerCountry = new Map<String,String>();
            final Map<String,String> mapBankerPerCountry = new Map<String,String>();
            final Map<String,String> mapBankerIDPerCountry = new Map<String,String>();
            final Map<String,String> mapParseCountry = helperCreateMapCountryCodes('DEVNAME', lstCountryCodes);
            final Map<String,String> mapCountryRegion = helperCreateMapCountryCodes('OPPREGION', lstCountryCodes);
            final Map<String,String> mapContryLabel= helperCreateMapCountryCodes('LABEL', lstCountryCodes);
            final Map<String,String> mapBankerByCountry = getMapBankerByCountry(clientId, Label.DES_Role_Transactional_Banker , lstCountryCodes);
            final Map<String,Info> mapCountryInfo = new Map<String,Info>();
            System.debug(':::::::mapParseCountry: ' + JSON.serialize(mapParseCountry));
            List<Info> lstAuxInfo = new List<Info>();

            for(DES_Subsidiary_Group_Relation__c account : lstAcc) {
                final String pais = mapParseCountry.get(account.participant_child_id__r.DES_Country_Client__c);
                final String region = mapCountryRegion.get(account.participant_child_id__r.DES_Country_Client__c);
                System.debug(':::::::pais / region: ' + pais + ' / ' + region);
                System.debug(':::::::mapContryLabel.get(pais): ' + mapContryLabel.get(pais));
                System.debug(':::::::mapBankerByCountry.get(mapContryLabel.get(pais) ' + mapBankerByCountry.get(mapContryLabel.get(pais)));
                String bankerName;
                String bankerID;
                if (mapBankerByCountry.get(mapContryLabel.get(pais)) != null) {
                    final List<String> lstBanker = mapBankerByCountry.get(mapContryLabel.get(pais)).split('@@'); //mx a mexico
                    if(lstBanker != null) {
                        bankerName = lstBanker[1];
                        bankerID = '\'' + lstBanker[0] + '\'';
                    }
                }


                Integer contador;

                //info para trasladar a otros componentes
                final Info info = new Info();
                info.region = region;
                info.bankerName = bankerName;
                info.bankerId = bankerID;

                mapCountryInfo.put(pais, info);

                if(mapResultGrouped.containsKey(pais)) {
                    lstAuxInfo = mapResultGrouped.get(pais);
                    contador = mapDescripPerCountry.get(pais) + 1;
                } else {
                    lstAuxInfo = new List<Info>();
                    contador = 1;
                }
                lstAuxInfo.add(info);

                mapDescripPerCountry.put(pais, contador);
                mapRegionPerCountry.put(pais, region);
                mapBankerIDPerCountry.put(pais, account.participant_parent_id__r.DES_Global_banker__c);
                mapBankerPerCountry.put(pais, bankerName);
                mapResultGrouped.put(pais, lstAuxInfo);
            }

            Account acc;
            for(String country : mapResultGrouped.keySet()) {
                acc = new Account();
                    acc.Name = country;
                System.debug('::country - ' + country);
                final List<Info> lstInfo = mapResultGrouped.get(country);
                final String region = lstInfo[0].region;
                String bankerUser;
                String bankerId;
                bankerUser = lstInfo[0].bankerName;
                bankerId = lstInfo[0].bankerId;

                final Location loc = createInfoLocation(acc, country, mapDescripPerCountry.get(country), region, bankerUser, bankerId);
                listLoc.add(loc);
            }
            System.debug(':::::::listLoc: ' + JSON.serialize(listLoc));
        }
        return listLoc;
    }
/******************************************************************************************************************
Name:           helperCreateMapCountryCodes method
Description:    Helper que crea mapa de paises - map< codigoPais , stringPais > segun el metadata Opp_Countries__mdt

Input - String (Enum => (DevName || Label))
Output - Map(String country.DeveloperName, String country.Label)

Version             Date        Author                          Summary of changes
--------------------------------------------------------------------------------------------------------------------
0.1             22/11/2018      GlobalDesktop - APC          Initial Version
0.2             05/02/2019      GlobalDesktop - APC          Modes OPPREGION and NBCREGION added
*********************************************************************************************************************/
    public static Map<String,String> helperCreateMapCountryCodes(String mode, List<Opp_Countries__mdt> lstCountriesMTD) {
        System.debug(':::::::mapCountries init');
        final Map<String,String> mapCountryCodes = new Map<String,String>(); //code + string

        for(Opp_Countries__mdt country : lstCountriesMTD) {
            if(mode == 'DEVNAME') {
                mapCountryCodes.put(country.DeveloperName, country.Label);
            } else if(mode == 'LABEL') {
                mapCountryCodes.put(country.Label, country.DeveloperName);
            } else if(mode == 'OPPREGION') {
                mapCountryCodes.put(country.DeveloperName, country.Opp_Region__c);
            } else if(mode == 'NBCREGION') {
                mapCountryCodes.put(country.DeveloperName, country.NBC_Region__c);
            } else if(mode == 'USERCOUNTRY') {
                mapCountryCodes.put(country.Country_User__c, country.DeveloperName);
            } else if(mode == 'BOOKCOUNTRY') {
                mapCountryCodes.put(country.Label, country.Booking_country__c);
            }
        }
        System.debug(':::::::mapCountries: ' + mapCountryCodes);
        return mapCountryCodes;
    }

    /*
    * @author Global Desktop
    * @Description crea un mapa con los codigos de los paises
    */
    public static Map<String,String> helperCreateMapCountryCodes(String mode) {
        System.debug(':::::::mapCountries init');
        final Map<String,String> mapCountryCodes = new Map<String,String>();
        List<Opp_Countries__mdt> lstCountriesMTD = [SELECT Id, Label, MasterLabel, DeveloperName, Opp_Region__c, NBC_Region__c,
                                                           Country_User__c, Booking_country__c
                                                      FROM Opp_Countries__mdt LIMIT 5000];

        for(Opp_Countries__mdt country : lstCountriesMTD) {
            if(mode == 'DEVNAME') {
                mapCountryCodes.put(country.DeveloperName, country.Label);
            }else if(mode == 'LABEL') {
                mapCountryCodes.put(country.Label, country.DeveloperName);
            }else if(mode == 'OPPREGION') {
                mapCountryCodes.put(country.DeveloperName, country.Opp_Region__c);
            }else if(mode == 'NBCREGION') {
                mapCountryCodes.put(country.DeveloperName, country.NBC_Region__c);
            }else if(mode == 'USERCOUNTRY') {
                mapCountryCodes.put(country.Country_User__c, country.DeveloperName);
            } else if(mode == 'BOOKCOUNTRY') {
                mapCountryCodes.put(country.Label, country.Booking_country__c);
            }
        }
        System.debug(':::::::mapCountries: ' + mapCountryCodes);
        return mapCountryCodes;
    }
/*************************************************************************************************************
*   @author: GlobalDesktop - APC
*   @Method: mapCountryCodesSelector
*   @Description:

*   @Returns: List<Opp_Countries__mdt>

*   @Versions:
        v1 - 2019/01/28 - Initial version
***************************************************************************************************************/
    public static List<Opp_Countries__mdt> mapCountryCodesSelector() {
        System.debug(':::::::mapCountries init');
        List<Opp_Countries__mdt> lstCountriesMTD;
        lstCountriesMTD = [SELECT Id, Label, MasterLabel, DeveloperName, Opp_Region__c, NBC_Region__c,
                                  Country_User__c, Booking_country__c
                             FROM Opp_Countries__mdt LIMIT 5000];
        if(lstCountriesMTD.isEmpty()) {
            lstCountriesMTD = new List<Opp_Countries__mdt>();
        }
        return lstCountriesMTD;
    }
/****************************************************************************************************
*   @author: GlobalDesktop - APC
*   @Method: getMapBankerByCountry
*   @Description: Batch to update previous data related to scope field of contacts - related to ContactScopeManagement.class
*   @Param: String client Id
*   @Param: String BankerType
*   @Returns: Map<String,String> getMapBankerByCountry:
                Key: country
                Value: UserID@@FirstName Lastname

*   @Versions:
        v1 - 2019/01/28 - Initial version
******************************************************************************************************/
    public static Map<String,String> getMapBankerByCountry(String clientId, String bankerType, List<Opp_Countries__mdt> lstCountryCodes) {

        final Map<String,String> mapBankerByCountry = new Map<String,String>();
        final List<DES_BBVA_Management_team__c> lstBanker = [SELECT Id, DES_Client__r.Name, DES_Client__r.DES_Client_Type__c,  DES_Member_Role__c,
                                                            DES_Client__c, DES_User__c, DES_User__r.FirstName,  DES_User__r.LastName, DES_Client__r.DES_Country_Client__c,
                                                            DES_User_Country__c
                                                            FROM DES_BBVA_Management_team__c
                                                            WHERE DES_Member_Role__c = :bankerType//'Transactional Banker'
                                                            AND DES_Client__c = :clientId];
        if(!lstBanker.isEmpty()) {
            for(DES_BBVA_Management_team__c row : lstBanker) {
                Map<String,String> mapCountryParsed = helperCreateMapCountryCodes('USERCOUNTRY', lstCountryCodes);
                // mapBankerByCountry.put(row.DES_User_Country__c, row.DES_User__c + '@@' + row.DES_User__r.FirstName + ' ' + row.DES_User__r.LastName);
                mapBankerByCountry.put(mapCountryParsed.get(row.DES_User_Country__c), row.DES_User__c + '@@' + row.DES_User__r.FirstName + ' ' + row.DES_User__r.LastName);
            }
        }
        System.System.debug(':::::mapBankerByCountry: ' + JSON.serialize(mapBankerByCountry));
        return mapBankerByCountry;
    }
/**************************************************************************************************
Name:           locations methods
Description:    Constructor y wrappers de location y geolocation

                location puede ir con geoInfo o con Latitude + Longitude (si existe Lat+Long prevalece con respecto geoInfo)


Version             Date                 Author                 Summary of changes
---------------------------------------------------------------------------------------------------
0.1             22/11/2018       GlobalDesktop - APC         Initial Version
0.2             05/02/2019       GlobalDesktop - APC         Info wrapper added to pass additional info to client side
****************************************************************************************************/
    public static Location createInfoLocation(Account acc, String country, Integer descrip, String region, String bankerUser, String bankerID) {
        GeoLocation geoInfo = new GeoLocation();
            geoInfo.Country = country;
        Info infoExtra = new Info();
            infoExtra.region = region;
            infoExtra.bankerName = bankerUser;
            infoExtra.bankerId = bankerID;
        Location locDetail = new Location();
            locDetail.icon = 'action:map';
            locDetail.title = acc.Name;
            locDetail.description = '<div id="wrDescription"> Nº Affiliates: ' + descrip + '</div>';
            locDetail.location = geoInfo;

            locDetail.info = infoExtra;
        return locDetail;
    }

    /**
    * @author Global Desktop
    * @description Clase que construye la localizacion
    */
    public class Location{
        /* icon */
        @AuraEnabled
        public String icon{get;set;}
        /* title */
        @AuraEnabled
        public String title{get;set;}
        /* description */
        @AuraEnabled
        public String description{get;set;}
        /* location */
        @AuraEnabled
        public GeoLocation location{get;set;}
        /* info */
        @AuraEnabled
        public Info info{get;set;}
    }
    /**
    * @author Global Desktop
    * @description Clase que construye la geolocalizacion
    */
    public class GeoLocation{
        /* Country with UpperCase !important */
        @AuraEnabled
        public String Country{get;set;}
    }
    /**
    * @author Global Desktop
    * @description Clase que construye la lista con informacion relacionada
    */
    public class Info{
        /* region */
        @AuraEnabled
        public String region{get;set;} 
        /* bankerName */
        @AuraEnabled
        public String bankerName{get;set;}
        /* bankerId */
        @AuraEnabled
        public String bankerId{get;set;}
    }
}