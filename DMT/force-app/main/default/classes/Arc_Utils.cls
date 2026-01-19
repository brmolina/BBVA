/**
* ____________________________________________________________________________
* class for generic methods or selects
* ____________________________________________________________________________
* @author      David Otero <david.otero.carcia.contractor@bbva.com>
* @modifiedBy
* @version     1.0
* @created     2024-10-10
* @modified
* @systemLayer Sample
* ____________________________________________________________________________
* @changes
*
* ____________________________________________________________________________
*/
public with sharing class Arc_Utils {

    /**
    * @description Private constructor to avoid sonar err
    */
    public Arc_Utils() {

    }

    /**
    *-------------------------------------------------------------------------------
    * @description  Method "getAcctAndLocalClientInfo" queries Local_Client__c to retrieve Local Client info by the Cib_Client__c(Account) Id 
    *-------------------------------------------------------------------------------
    * @author santiago.vidal.contractor@bbva.com
    * @date 16-07-2025
    * @param string accountId
    * @return List<Local_Client__c>
    **/
    public static List<Local_Client__c> getAcctAndLocalClientInfo (String accountId){
        List<Local_Client__c> lstLClient = new List<Local_Client__c>();
        try{
            lstLClient = [SELECT Id, Alpha_code__c, Cib_Client__c, Cib_Client__r.Name, Cib_Client__r.DES_Structure_Type__c, Cib_Client__r.DES_Activity__c, Cib_Client__r.DES_Country_Client__c, Cib_Client__r.DES_ID_Fiscal__c, g_residence_country_id__c, local_customer_id__c    
                            FROM Local_Client__c 
                            WHERE Cib_Client__r.DES_Client_Type__c = 'subsidiary'  AND Cib_Client__c = :accountId
            ];
        }catch(Exception e){
            System.debug('Error--'+e.getMessage());
        }                       
        return lstLClient;
    }

    /**
    *-------------------------------------------------------------------------------
    * @description  Method "getRelatedClients" queries Local_Client__c to retrieve related Clients with the same local_customer_id__c
    *-------------------------------------------------------------------------------
    * @author santiago.vidal.contractor@bbva.com
    * @date 16-07-2025
    * @param string localCustomerId
    * @return Set<String>
    **/
    public static Set<String> getRelatedClients (String localCustomerId ){
        Set<String> setClients = new Set<String>();
        List<Local_Client__c> lstLocalClients = new List<Local_Client__c>();
        try{
            lstLocalClients = [SELECT Id, Cib_Client__c    
                            FROM Local_Client__c 
                            WHERE Cib_Client__r.DES_Client_Type__c = 'subsidiary'  AND local_customer_id__c = :localCustomerId
            ];
            if(!lstLocalClients.isEmpty()){
                for(Local_Client__c lClient : lstLocalClients){
                    setClients.add(lClient.Cib_Client__c);
                }
            }
        }catch(Exception e){
            System.debug('Error--'+e.getMessage());
        }                       
        return setClients;
    }

    /**
    *-------------------------------------------------------------------------------
    * @description  Method "getSbAndScraInfo" queries arce_Shadow_Banking__c to retrieve SB and SCRA info by the ClientLKP__c(Account) Id 
    *-------------------------------------------------------------------------------
    * @author santiago.vidal.contractor@bbva.com
    * @date 18-08-2025
    * @param string accountId
    * @return List<arce_Shadow_Banking__c>
    **/
    public static List<arce_Shadow_Banking__c> getSbAndScraInfo (String accountId){
        List<arce_Shadow_Banking__c> lstSB = new List<arce_Shadow_Banking__c>();
        try{
            lstSB = [SELECT Id, SB__c, SCRA__c, Country__c, FICCode__c, MarkScra__c, groupName__c, ClientLKP__c, ComentSB__c, CommentSCRA__c, Fecha_SCRA__c, 
                            Fecha_Shadow_Banking__c, Option_banking_activities_GDT__c, Option_consolidates_within_bank_GDT__c, Option_EU_bank_corpo_GDT__c, 
                            Option_insurance_corpo_GDT__c, Option_EU_insurance_corpo_GDT__c, Option_MMF_or_AIFs_GDT__c, Option_regulated_funds_GDT__c, 
                            Option_institutions_GDT__c, Option_insurance_GDT__c, Selected_Flow_GDT__c
                            FROM arce_Shadow_Banking__c
                            WHERE ClientLKP__c = :accountId 
                            ORDER BY CreatedDate DESC LIMIT 1
            ];
        }catch(Exception e){
            System.debug('Error--'+e.getMessage());
        }                       
        return lstSB;
    }

    /**
    *-------------------------------------------------------------------------------
    * @description  Method "getClientTypeFromActivitySector" that retrieves arce__IFIS_ClientType__c from arce__IFIS_Activity_relationship__mdt
    *-------------------------------------------------------------------------------
    * @author santiago.vidal.contractor@bbva.com
    * @date 16-07-2025
    * @param string actSector
    * @return String
    **/
    /* public static String getClientTypeFromActivitySector(String actSector) {
        String clientType = '';
        
        List<arce__IFIS_Activity_relationship__mdt> arMDT = [SELECT arce__IFIS_ClientType__c FROM arce__IFIS_Activity_relationship__mdt WHERE arce__IFIS_ActivitySector__c = :actSector LIMIT 1];
        
        if(!arMDT.isEmpty()){
        clientType = arMDT[0].arce__IFIS_ClientType__c;
        }
        return clientType;
    } */

    
    /**
    * @description Get data from services
    * @param 
    * @return retMap account 
    */
    /* public static List<Account> accountList (){
        List<Account> accLst = [SELECT Id, Name, DES_Structure_Type__c, account_group__c, DES_Group_Code__c, DES_Country_Client__c 
            FROM Account
            WHERE DES_Structure_Type__c != 'Subsidiary' AND DES_Structure_Type__c != 'Subgroup' AND DES_Structure_Type__c != 'Shared Management Group' AND DES_Structure_Type__c != '' AND account_group__c != '' AND DES_Group_Code__c != '' LIMIT 25
            ];

        return accLst;
    } */

    /**
    * @description Get data from services
    * @param 
    * @return retMap arce__Account_has_Analysis__c 
    */
    /* public static List<Account> accountSoslList (String soslFindClause){
        List<List<Account>> searchList = [FIND :soslFindClause IN ALL FIELDS
        RETURNING Account (Id, name, DES_Structure_Type__c, account_group__c, DES_Group_Code__c, DES_Country_Client__c WHERE DES_Structure_Type__c != 'Subsidiary' AND DES_Structure_Type__c != 'Subgroup' AND DES_Structure_Type__c != 'Shared Management Group' AND DES_Structure_Type__c != '' AND account_group__c != '' AND DES_Group_Code__c != '') LIMIT 25];

        return searchList.get(0);
    } */

    /**
    * @description Get data from services
    * @param 
    * @return retMap arce__Account_has_Analysis__c 
    */
    /* public static List<Account> accountCountrySoslList (String soslFindClause){
        String str = addPercentForFilter(soslFindClause);
        List<List<Account>> searchList = [FIND :soslFindClause IN ALL FIELDS
        RETURNING Account (Id, name, DES_Structure_Type__c, account_group__c, DES_Group_Code__c, DES_Country_Client__c WHERE DES_Structure_Type__c != 'Subsidiary' AND DES_Country_Client__c = :soslFindClause AND DES_Structure_Type__c != 'Subgroup' AND DES_Structure_Type__c != 'Shared Management Group' AND DES_Structure_Type__c != '' AND account_group__c != '' AND DES_Group_Code__c != '') LIMIT 25];

        return searchList.get(0);
    } */

    /**
    * @description Get data from services
    * @param 
    * @return retMap arce__Account_has_Analysis__c 
    */
    /* public static List<Account> accountGroupSoslList (String soslFindClause){
        List<List<Account>> searchList = [FIND :soslFindClause IN ALL FIELDS
        RETURNING Account (Id, name, DES_Structure_Type__c, account_group__c, DES_Group_Code__c, DES_Country_Client__c WHERE DES_Structure_Type__c != 'Subsidiary' AND DES_Structure_Type__c != 'Subgroup' AND DES_Structure_Type__c != 'Shared Management Group' AND DES_Structure_Type__c != '' AND account_group__c != '' AND DES_Group_Code__c != '') LIMIT 25];

        return searchList.get(0);
    } */

    /**
    * @description Get data from services
    * @param 
    * @return retMap arce__Account_has_Analysis__c 
    */
    /* public static List<Account> accountGroupCodeSoslList (String soslFindClause){
        List<List<Account>> searchList = [FIND :soslFindClause IN ALL FIELDS
        RETURNING Account (Id, name, DES_Structure_Type__c, account_group__c, DES_Group_Code__c, DES_Country_Client__c WHERE DES_Structure_Type__c != 'Subsidiary' AND DES_Structure_Type__c != 'Subgroup' AND DES_Structure_Type__c != 'Shared Management Group' AND DES_Structure_Type__c != '' AND account_group__c != '' AND DES_Group_Code__c != '') LIMIT 25];

        return searchList.get(0);
    } */

    /**
    * @description Get data from services
    * @param 
    * @return retMap arce__Account_has_Analysis__c 
    */
    /* public static List<arce__Account_has_Analysis__c > RepresentativeIfisList (string representativeAccountId){
        List<arce__Account_has_Analysis__c > ahaLst = [SELECT Name, 
                arce__Analysis__r.Name, DES_Local_Client__r.Alpha_code__c, 
                DES_Local_Client__r.Name, DES_Local_Client__r.Cib_Client__r.Name,
                DES_Local_Client__c, DES_Local_Client__r.Cib_Client__c, 
                DES_Local_Client__r.g_residence_country_id__c, 
                DES_Local_Client__r.Cib_Client__r.DES_ID_Fiscal__c, 
                arce__AHA_Extension__r.arce__IFIS_ClientType__c,
                arce__AHA_Extension__r.arce__IFIS_Path__c
            FROM arce__Account_has_Analysis__c 
            WHERE DES_Local_Client__r.Cib_Client__r.DES_Main_Parent__c =: representativeAccountId 
            AND arce__Analysis__r.arce__wf_status_id__c = '13' 
            AND arce__Analysis__r.arce__Stage__c = '3' 
            AND arce__g_rtg_tool_typ_id__c = 'Representative' 
            AND arce__Analysis__r.arce__rating_prerating_type__c = 'Rating'           
            ORDER BY DES_Local_Client__r.Alpha_code__c, name DESC
            LIMIT 20
        ];
        return ahaLst;
    } */

    /**
    * @description Get data from services
    * @param 
    * @return retMap arce__Account_has_Analysis__c 
    */
    /* public static List<arce__Account_has_Analysis__c > RepresentativeIfisListByFICCode (string representativeAccountId, string ficCode){
        ficCode = addPercentForFilter(ficCode);
        List<arce__Account_has_Analysis__c > ahaLst = [SELECT Name, 
                arce__Analysis__r.Name, DES_Local_Client__r.Alpha_code__c, 
                DES_Local_Client__r.Name, DES_Local_Client__r.Cib_Client__r.Name,
                DES_Local_Client__c, DES_Local_Client__r.Cib_Client__c, 
                DES_Local_Client__r.g_residence_country_id__c, 
                DES_Local_Client__r.Cib_Client__r.DES_ID_Fiscal__c, 
                arce__AHA_Extension__r.arce__IFIS_ClientType__c,
                arce__AHA_Extension__r.arce__IFIS_Path__c
            FROM arce__Account_has_Analysis__c 
                WHERE DES_Local_Client__r.Cib_Client__r.DES_Main_Parent__c =: representativeAccountId 
                AND arce__Analysis__r.arce__wf_status_id__c = '13' 
                AND arce__Analysis__r.arce__Stage__c = '3' 
                AND arce__g_rtg_tool_typ_id__c = 'Representative' 
                AND arce__Analysis__r.arce__rating_prerating_type__c = 'Rating'           
                AND DES_Local_Client__r.Cib_Client__r.DES_ID_Fiscal__c LIKE: ficCode
                ORDER BY DES_Local_Client__r.Alpha_code__c, name DESC
                LIMIT 20
            ];
        return ahaLst;
    } */

    /**
    * @description Get data from services
    * @param 
    * @return retMap arce__Account_has_Analysis__c 
    */
    /* public static List<arce__Account_has_Analysis__c > RepresentativeIfisListByAccName (string representativeAccountId, string nameAcc){
        string name = addPercentForFilter(nameAcc);
        List<arce__Account_has_Analysis__c > ahaLst = [SELECT Name, 
                    arce__Analysis__r.Name, DES_Local_Client__r.Alpha_code__c, 
                    DES_Local_Client__r.Name, DES_Local_Client__r.Cib_Client__r.Name,
                    DES_Local_Client__c, DES_Local_Client__r.Cib_Client__c, 
                    DES_Local_Client__r.g_residence_country_id__c, 
                    DES_Local_Client__r.Cib_Client__r.DES_ID_Fiscal__c, 
                    arce__AHA_Extension__r.arce__IFIS_ClientType__c,
                    arce__AHA_Extension__r.arce__IFIS_Path__c
                FROM arce__Account_has_Analysis__c 
                WHERE DES_Local_Client__r.Cib_Client__r.DES_Main_Parent__c =: representativeAccountId 
                AND arce__Analysis__r.arce__wf_status_id__c = '13' 
                AND arce__Analysis__r.arce__Stage__c = '3' 
                AND arce__g_rtg_tool_typ_id__c = 'Representative' 
                AND arce__Analysis__r.arce__rating_prerating_type__c = 'Rating'           
                AND DES_Local_Client__r.Name LIKE: name
                ORDER BY DES_Local_Client__r.Alpha_code__c, name DESC
                LIMIT 20
        ];
        return ahaLst;
    } */

    /**
    * @description Get data from services
    * @param 
    * @return retMap arce__Account_has_Analysis__c 
    */
    /* public static List<arce__Account_has_Analysis__c > RepresentativeIfisListByType (string representativeAccountId, string typeAcc){
        string type = addPercentForFilter(typeAcc);
        List<arce__Account_has_Analysis__c > ahaLst = [SELECT Name, 
                    arce__Analysis__r.Name, DES_Local_Client__r.Alpha_code__c, 
                    DES_Local_Client__r.Name, DES_Local_Client__r.Cib_Client__r.Name,
                    DES_Local_Client__c, DES_Local_Client__r.Cib_Client__c, 
                    DES_Local_Client__r.g_residence_country_id__c, 
                    DES_Local_Client__r.Cib_Client__r.DES_ID_Fiscal__c, 
                    arce__AHA_Extension__r.arce__IFIS_ClientType__c,
                    arce__AHA_Extension__r.arce__IFIS_Path__c
                FROM arce__Account_has_Analysis__c 
                WHERE DES_Local_Client__r.Cib_Client__r.DES_Main_Parent__c =: representativeAccountId 
                AND arce__Analysis__r.arce__wf_status_id__c = '13' 
                AND arce__Analysis__r.arce__Stage__c = '3' 
                AND arce__g_rtg_tool_typ_id__c = 'Representative'
                AND arce__Analysis__r.arce__rating_prerating_type__c = 'Rating' 
                ORDER BY DES_Local_Client__r.Alpha_code__c, name DESC
                LIMIT 20
        ];
        return ahaLst;
    } */

    /**
    * @description Get data from services
    * @param 
    * @return retMap arce__Account_has_Analysis__c 
    */
    /* public static List<arce__Account_has_Analysis__c > RepresentativeIfisListByCtry (string representativeAccountName, string country){
        string reprAccountName = addPercentForFilter(representativeAccountName);
        string ctry = addPercentForFilter(country);
        List<arce__Account_has_Analysis__c > ahaLst = [SELECT arce__Analysis__r.arce__participant_name__c, arce__AHA_Extension__r.arce__Financial_Type__c, arce__CustomAccountID__c, arce__AHA_Extension__r.arce__IFIS_Path__c, arce__RAR_rating_tool_id__c, arce__g_rtg_tool_typ_id__c, arce__Analysis__r.arce__Group__r.name, arce__Analysis__r.arce__Group__r.DES_Subsidiary_Group_Code__c, arce__Analysis__r.arce__Group__r.DES_Country__c,arce__AHA_Extension__r.arce__IFIS_ClientType__c
                                    FROM arce__Account_has_Analysis__c 
                                    WHERE arce__RAR_rating_tool_id__c LIKE '%age%' 
                                    AND arce__g_rtg_tool_typ_id__c LIKE 'Representative'
                                    AND arce__Analysis__r.arce__participant_name__c LIKE: reprAccountName
                                    AND arce__Analysis__r.arce__Group__r.DES_Country__c LIKE: ctry
                                    LIMIT 20
                                    ];
        return ahaLst;
    } */

    /**
    * @description Get data from services
    * @param 
    * @return retMap arce__Account_has_Analysis__c 
    */
    /* public static List<arce__Account_has_Analysis__c > RepresentativeIfisListByFIC (string representativeAccountName, string fic){
        string reprAccountName = addPercentForFilter(representativeAccountName);
        string ficNm = addPercentForFilter(fic);
        List<arce__Account_has_Analysis__c > ahaLst = [SELECT arce__Analysis__r.arce__participant_name__c, arce__AHA_Extension__r.arce__Financial_Type__c, arce__CustomAccountID__c, arce__AHA_Extension__r.arce__IFIS_Path__c, arce__RAR_rating_tool_id__c, arce__g_rtg_tool_typ_id__c, arce__Analysis__r.arce__Group__r.name, arce__Analysis__r.arce__Group__r.DES_Subsidiary_Group_Code__c, arce__Analysis__r.arce__Group__r.DES_Country__c,arce__AHA_Extension__r.arce__IFIS_ClientType__c
                                    FROM arce__Account_has_Analysis__c 
                                    WHERE arce__RAR_rating_tool_id__c LIKE '%age%' 
                                    AND arce__g_rtg_tool_typ_id__c LIKE 'Representative'
                                    AND arce__Analysis__r.arce__participant_name__c LIKE: reprAccountName
                                    AND arce__Analysis__r.arce__Group__r.DES_Subsidiary_Group_Code__c LIKE: ficNm
                                    LIMIT 20
                                    ];
        return ahaLst;
    } */

    /**
    * @description Get data from services
    * @param 
    * @return retMap arce__Account_has_Analysis__c 
    */
    /* public static List<arce__Account_has_Analysis__c > noRepresentativeIfisListByGroup (string representativeAccountName){
        string reprAccountName = addPercentForFilter(representativeAccountName);
        List<arce__Account_has_Analysis__c > ahaLst = [SELECT arce__Analysis__r.arce__participant_name__c, arce__AHA_Extension__r.arce__Financial_Type__c, arce__CustomAccountID__c, arce__AHA_Extension__r.arce__IFIS_Path__c, arce__RAR_rating_tool_id__c, arce__g_rtg_tool_typ_id__c, arce__Analysis__r.arce__Group__r.name, arce__Analysis__r.arce__Group__r.DES_Subsidiary_Group_Code__c, arce__Analysis__r.arce__Group__r.DES_Country__c,arce__AHA_Extension__r.arce__IFIS_ClientType__c
                                    FROM arce__Account_has_Analysis__c 
                                    WHERE arce__RAR_rating_tool_id__c LIKE '%age%' 
                                    AND arce__g_rtg_tool_typ_id__c != 'Representative'
                                    AND arce__Analysis__r.arce__participant_name__c LIKE: reprAccountName
                                    LIMIT 20
                                    ];
        return ahaLst;
    } */

    /**
    * @description Get data from services
    * @param 
    * @return retMap arce__Account_has_Analysis__c 
    */
    /* public static List<arce__Account_has_Analysis__c > noRepresentativeIfisListByGroupCode (string groupCode){
        string grpCode = addPercentForFilter(groupCode);
        List<arce__Account_has_Analysis__c > ahaLst = [SELECT arce__Analysis__r.arce__participant_name__c, arce__AHA_Extension__r.arce__Financial_Type__c, arce__CustomAccountID__c, arce__AHA_Extension__r.arce__IFIS_Path__c, arce__RAR_rating_tool_id__c, arce__g_rtg_tool_typ_id__c, arce__Analysis__r.arce__Group__r.name, arce__Analysis__r.arce__Group__r.DES_Subsidiary_Group_Code__c, arce__Analysis__r.arce__Group__r.DES_Country__c,arce__AHA_Extension__r.arce__IFIS_ClientType__c
                                    FROM arce__Account_has_Analysis__c 
                                    WHERE arce__RAR_rating_tool_id__c LIKE '%age%' 
                                    AND arce__g_rtg_tool_typ_id__c != 'Representative'
                                    AND arce__Analysis__r.arce__Group__r.DES_Subsidiary_Group_Code__c LIKE: grpCode
                                    LIMIT 20
                                    ];
        return ahaLst;
    } */

    /**
    * @description Get data from services
    * @param 
    * @return retMap arce__Account_has_Analysis__c 
    */
    /* public static List<arce__Account_has_Analysis__c > noRepresentativeIfisListByCountry (string country){
        string ctry = addPercentForFilter(country);
        List<arce__Account_has_Analysis__c > ahaLst = [SELECT arce__Analysis__r.arce__participant_name__c, arce__AHA_Extension__r.arce__Financial_Type__c, arce__CustomAccountID__c, arce__AHA_Extension__r.arce__IFIS_Path__c, arce__RAR_rating_tool_id__c, arce__g_rtg_tool_typ_id__c, arce__Analysis__r.arce__Group__r.name, arce__Analysis__r.arce__Group__r.DES_Subsidiary_Group_Code__c, arce__Analysis__r.arce__Group__r.DES_Country__c,arce__AHA_Extension__r.arce__IFIS_ClientType__c
                                    FROM arce__Account_has_Analysis__c 
                                    WHERE arce__RAR_rating_tool_id__c LIKE '%age%' 
                                    AND arce__g_rtg_tool_typ_id__c != 'Representative'
                                    AND arce__Analysis__r.arce__Group__r.DES_Country__c LIKE: ctry
                                    LIMIT 20
                                    ];
        return ahaLst;
    } */

    /**
    * @description Get data from services
    * @param 
    * @return retMap arce__Account_has_Analysis__c 
    */
    /* public static List<arce__Account_has_Analysis__c > noRepresentativeIfisListByCtry (string representativeAccountName, string country){
        string reprAccountName = addPercentForFilter(representativeAccountName);
        string ctry = addPercentForFilter(country);
        List<arce__Account_has_Analysis__c > ahaLst = [SELECT arce__Analysis__r.arce__participant_name__c, arce__AHA_Extension__r.arce__Financial_Type__c, arce__CustomAccountID__c, arce__AHA_Extension__r.arce__IFIS_Path__c, arce__RAR_rating_tool_id__c, arce__g_rtg_tool_typ_id__c, arce__Analysis__r.arce__Group__r.name, arce__Analysis__r.arce__Group__r.DES_Subsidiary_Group_Code__c, arce__Analysis__r.arce__Group__r.DES_Country__c,arce__AHA_Extension__r.arce__IFIS_ClientType__c
                                    FROM arce__Account_has_Analysis__c 
                                    WHERE arce__RAR_rating_tool_id__c LIKE '%age%' 
                                    AND arce__g_rtg_tool_typ_id__c != 'Representative'
                                    AND arce__Analysis__r.arce__participant_name__c LIKE: reprAccountName
                                    AND arce__Analysis__r.arce__Group__r.DES_Country__c LIKE: ctry
                                    LIMIT 20
                                    ];
        return ahaLst;
    } */

    /**
    * @description Get data from services
    * @param 
    * @return retMap arce__Account_has_Analysis__c 
    */
    /* public static List<arce__Account_has_Analysis__c > noRepresentativeIfisListByFIC (string representativeAccountName, string fic){
        string reprAccountName = addPercentForFilter(representativeAccountName);
        string ficNm = addPercentForFilter(fic);
        List<arce__Account_has_Analysis__c > ahaLst = [SELECT arce__Analysis__r.arce__participant_name__c, arce__AHA_Extension__r.arce__Financial_Type__c, arce__CustomAccountID__c, arce__AHA_Extension__r.arce__IFIS_Path__c, arce__RAR_rating_tool_id__c, arce__g_rtg_tool_typ_id__c, arce__Analysis__r.arce__Group__r.name, arce__Analysis__r.arce__Group__r.DES_Subsidiary_Group_Code__c, arce__Analysis__r.arce__Group__r.DES_Country__c,arce__AHA_Extension__r.arce__IFIS_ClientType__c
                                    FROM arce__Account_has_Analysis__c 
                                    WHERE arce__RAR_rating_tool_id__c LIKE '%age%' 
                                    AND arce__g_rtg_tool_typ_id__c != 'Representative'
                                    AND arce__Analysis__r.arce__participant_name__c LIKE: reprAccountName
                                    AND arce__Analysis__r.arce__Group__r.DES_Subsidiary_Group_Code__c LIKE: ficNm
                                    LIMIT 20
                                    ];
        return ahaLst;
    } */

    /**
    * @description Get data from services
    * @param 
    * @return retMap string
    */
    /* public static string addPercentForFilter (string name){
        string str = '%'+name+'%';
        return str;
    } */

    /**
    * @description Get data from services
    * @param 
    * @return retMap arce__Account_has_Analysis__c 
    */
    /* public static arce__Account_has_Analysis__c ahaSelector (string ahaId){
        arce__Account_has_Analysis__c aha = [SELECT arce__Analysis__r.arce__participant_name__c, 
                                        arce__AHA_Extension__r.arce__Financial_Type__c, 
                                        arce__CustomAccountID__c, 
                                        arce__AHA_Extension__r.arce__IFIS_Path__c, 
                                        arce__RAR_rating_tool_id__c, 
                                        arce__g_rtg_tool_typ_id__c, 
                                        arce__Analysis__r.arce__Group__r.name, 
                                        arce__Analysis__r.arce__Group__r.DES_Subsidiary_Group_Code__c, 
                                        arce__Analysis__r.arce__Group__r.DES_Country__c,
                                        arce__AHA_Extension__r.arce__IFIS_ClientType__c,
                                        Name, 
                                        arce__Analysis__r.Name, DES_Local_Client__r.Alpha_code__c, 
                                        DES_Local_Client__r.Name, DES_Local_Client__r.Cib_Client__r.Name,
                                        DES_Local_Client__c, DES_Local_Client__r.Cib_Client__c, 
                                        DES_Local_Client__r.g_residence_country_id__c, 
                                        DES_Local_Client__r.Cib_Client__r.DES_ID_Fiscal__c
                                    FROM arce__Account_has_Analysis__c 
                                    WHERE id =: ahaId
                                    ];
        return aha;
    } */

    /**
    * @description Get data from services
    * @param clientIds set of client (Account) Ids
    * @return retMap arce_Shadow_Banking__c 
    */
    public static Map<String, arce_Shadow_Banking__c> sBSelector (Set<String> clientIds){
        Map<String, arce_Shadow_Banking__c> mapClientSB = new Map<String, arce_Shadow_Banking__c>();
        List<arce_Shadow_Banking__c> listSb = new List<arce_Shadow_Banking__c>();
        try{
            listSb = [SELECT id, ClientLKP__c
                        FROM arce_Shadow_Banking__c 
                        WHERE ClientLKP__c  IN :clientIds
                        ];
            for(arce_Shadow_Banking__c sb : listSb){
                if(!mapClientSB.containsKey(sb.ClientLKP__c)){
                    mapClientSB.put(sb.ClientLKP__c, sb);
                }
            }
        }catch(Exception e){
            System.debug('Error--'+e.getMessage());
        }                          
        return mapClientSB;
    }

    /**
    * @description Get data from services
    * @param 
    * @return retMap arce_Shadow_Banking__c 
    */
    /* public static List<arce_Shadow_Banking__c> SBSelectorLst (Set<Id> agaIds){
        List<arce_Shadow_Banking__c> sb = new List<arce_Shadow_Banking__c>();
        try{
            sb = [SELECT id, Account_has_Analysis__c, SB__c, SCRA__c, Fecha_SCRA__c, Fecha_Shadow_Banking__c, ClientLKP__c, ComentSB__c, CommentSCRA__c
                                    FROM arce_Shadow_Banking__c 
                                    WHERE Account_has_Analysis__c IN: agaIds
                                    ];
        }catch(Exception e){
            System.debug('Error--'+e.getMessage());
        }                          
        return sb;
    } */

    /**
    * @description Get data from services
    * @param 
    * @return Map<String,String>
    */
    /* public static Map<String,String> bankCountriesEUSBList(){
        Map<String,String> bankCountriesSBList = new Map<String,String>();

        bankCountriesSBList.put('AT','Austria');
        bankCountriesSBList.put('BE','Belgium');
        bankCountriesSBList.put('HR','Croatia');
        bankCountriesSBList.put('CY','Republic of Cyprus');
        bankCountriesSBList.put('DK','Denmark');
        bankCountriesSBList.put('EE','Estonia');
        bankCountriesSBList.put('FI','Finland');
        bankCountriesSBList.put('FR','France');
        bankCountriesSBList.put('DE','Germany');
        bankCountriesSBList.put('GR','Greece');
        bankCountriesSBList.put('HU','Hungary');
        bankCountriesSBList.put('IE','Ireland');
        bankCountriesSBList.put('IT','Italy');
        bankCountriesSBList.put('LV','Latvia');
        bankCountriesSBList.put('LT','Lithuania');
        bankCountriesSBList.put('LU','Luxembourg');
        bankCountriesSBList.put('MT','Malta');
        bankCountriesSBList.put('NL','Netherlands');
        bankCountriesSBList.put('PL','Poland');
        bankCountriesSBList.put('PT','Portugal');
        bankCountriesSBList.put('RO','Romania');
        bankCountriesSBList.put('SK','Slovakia');
        bankCountriesSBList.put('SI','Slovenia');
        bankCountriesSBList.put('ES','Spain');
        bankCountriesSBList.put('SE','Sweden');
        bankCountriesSBList.put('UK','Reino Unido');

        return bankCountriesSBList;
    } */

    /**
    * @description Get data from services
    * @param 
    * @return Map<String,String>
    */
    public static Map<String,String> bankCountriesSBList(){
        Map<String,String> bankCountriesSBList = new Map<String,String>();

        bankCountriesSBList.put('AT','Austria');
        bankCountriesSBList.put('BE','Belgium');
        bankCountriesSBList.put('BG','Bulgaria');
        bankCountriesSBList.put('HR','Croatia');
        bankCountriesSBList.put('CY','Republic of Cyprus');
        bankCountriesSBList.put('CZ','Czech Republic');
        bankCountriesSBList.put('DK','Denmark');
        bankCountriesSBList.put('EE','Estonia');
        bankCountriesSBList.put('FI','Finland');
        bankCountriesSBList.put('FR','France');
        bankCountriesSBList.put('DE','Germany');
        bankCountriesSBList.put('GR','Greece');
        bankCountriesSBList.put('HU','Hungary');
        bankCountriesSBList.put('IE','Ireland');
        bankCountriesSBList.put('IT','Italy');
        bankCountriesSBList.put('LV','Latvia');
        bankCountriesSBList.put('LT','Lithuania');
        bankCountriesSBList.put('LU','Luxembourg');
        bankCountriesSBList.put('MT','Malta');
        bankCountriesSBList.put('NL','Netherlands');
        bankCountriesSBList.put('PL','Poland');
        bankCountriesSBList.put('PT','Portugal');
        bankCountriesSBList.put('RO','Romania');
        bankCountriesSBList.put('SK','Slovakia');
        bankCountriesSBList.put('SI','Slovenia');
        bankCountriesSBList.put('ES','Spain');
        bankCountriesSBList.put('SE','Sweden');
        bankCountriesSBList.put('AR','Argentina');
        bankCountriesSBList.put('AU','Australia');
        bankCountriesSBList.put('BA','Bosnia');
        bankCountriesSBList.put('BR','Brasil');
        bankCountriesSBList.put('CA','Canadá');
        bankCountriesSBList.put('CN','China');
        bankCountriesSBList.put('HK','Hong Kong');
        bankCountriesSBList.put('IN','India');
        bankCountriesSBList.put('JP','Japón');
        bankCountriesSBList.put('JE','Jersey');
        bankCountriesSBList.put('MX','México');
        bankCountriesSBList.put('MC','Mónaco');
        bankCountriesSBList.put('NZ','New Zealand');
        bankCountriesSBList.put('SA','Arabia Saudi');
        bankCountriesSBList.put('CS','Serbia');
        bankCountriesSBList.put('SG','Singapore');
        bankCountriesSBList.put('ZA','South Africa');
        bankCountriesSBList.put('KR','South Korea');
        bankCountriesSBList.put('US','USA');
        bankCountriesSBList.put('CH','Suiza');
        bankCountriesSBList.put('TR','Turquía');
        bankCountriesSBList.put('MK','Macedonia del Norte');
        bankCountriesSBList.put('FRO','Faroe Islands');
        bankCountriesSBList.put('CO','Colombia');
        bankCountriesSBList.put('GB','UK');
        bankCountriesSBList.put('TH','Thailand');
        bankCountriesSBList.put('IL','Israel');
        bankCountriesSBList.put('PH','Filipinas');
        bankCountriesSBList.put('PE','Perú');
        bankCountriesSBList.put('CL','Chile');
        bankCountriesSBList.put('QA','Qatar');
        bankCountriesSBList.put('AE','UAE');
        bankCountriesSBList.put('ID','Indonesia');
        bankCountriesSBList.put('MY','Malaysia');
        bankCountriesSBList.put('TW','Taiwan');
        bankCountriesSBList.put('VN','Vietnam');

        return bankCountriesSBList;
    }

    /**
    * @description Get data from services
    * @param 
    * @return Map<String,String>
    */
    public static Map<String,String> insurerCountriesSBList(){
        Map<String,String> insurerCountriesSBList = new Map<String,String>();

        insurerCountriesSBList.put('AT','Austria');
        insurerCountriesSBList.put('BE','Belgium');
        insurerCountriesSBList.put('BG','Bulgaria');
        insurerCountriesSBList.put('HR','Croatia');
        insurerCountriesSBList.put('CY','Republic of Cyprus');
        insurerCountriesSBList.put('CZ','Czech Republic');
        insurerCountriesSBList.put('DK','Denmark');
        insurerCountriesSBList.put('EE','Estonia');
        insurerCountriesSBList.put('FI','Finland');
        insurerCountriesSBList.put('FR','France');
        insurerCountriesSBList.put('DE','Germany');
        insurerCountriesSBList.put('GR','Greece');
        insurerCountriesSBList.put('HU','Hungary');
        insurerCountriesSBList.put('IE','Ireland');
        insurerCountriesSBList.put('IT','Italy');
        insurerCountriesSBList.put('LV','Latvia');
        insurerCountriesSBList.put('LT','Lithuania');
        insurerCountriesSBList.put('LU','Luxembourg');
        insurerCountriesSBList.put('MT','Malta');
        insurerCountriesSBList.put('NL','Netherlands');
        insurerCountriesSBList.put('PL','Poland');
        insurerCountriesSBList.put('PT','Portugal');
        insurerCountriesSBList.put('RO','Romania');
        insurerCountriesSBList.put('SK','Slovakia');
        insurerCountriesSBList.put('SI','Slovenia');
        insurerCountriesSBList.put('ES','Spain');
        insurerCountriesSBList.put('SE','Sweden');
        insurerCountriesSBList.put('BM','Bermudas');
        insurerCountriesSBList.put('CH','Suiza');
        insurerCountriesSBList.put('AU','Australia');
        insurerCountriesSBList.put('BR','Brasil');
        insurerCountriesSBList.put('CA','Canadá');
        insurerCountriesSBList.put('MX','México');
        insurerCountriesSBList.put('US','USA');
        insurerCountriesSBList.put('GB','UK');

        return insurerCountriesSBList;
    
    }
}