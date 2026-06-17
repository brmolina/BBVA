/**
* ------------------------------------------------------------------------------------------------
* @Name     DES_Arc_Account_Hierarchy
* -----------------------------------------------------------------------------------------------
* @Description Class "DES_Arc_Account_Hierarchy"
* -----------------------------------------------------------------------------------------------
*/
@SuppressWarnings('sf:NPathComplexity, sf:CyclomaticComplexity, sf:TooManyMethods')
global with sharing class DES_Arc_Account_Hierarchy {
    
    static final string risk = 'Riesgo';
    

    /**
    * ----------------------------------------------------------------------------------------------------
    * @Description Method to get risk header from accounts
    * ----------------------------------------------------------------------------------------------------
    * @author hectorjeshua.vasquez.contractor@bbva.com
    * @date 2022-14-10
    * @param String alphaCode
    * @return Map<String,List<String>>
    * @example DES_Arc_Account_Hierarchy.riskHeader(alphaCode)
    * ----------------------------------------------------------------------------------------------------
    **/
    Public Static Map<String,List<String>> riskHeader (String alphaCode){
        Map<String, List<String>> mappingRiskHeader = new Map<String, List<String>>();
        Set<String> groupAccounts = new Set<String>();
        Set<String> subgroupAccounts = new Set<String>();
        final List<Local_Client__c> lcClient = [SELECT Id, Cib_Client__c FROM Local_Client__c WHERE Alpha_Code__c =: alphaCode LIMIT 1];
        final List<Account> lstAccount = [SELECT Id, Name, account_client__c, account_group__c FROM Account WHERE Id =: lcClient[0].Cib_Client__c LIMIT 1];
        
        //Si el cliente es directamente el padre del local cliente
        if(lstAccount[0].account_client__c == 'S'){
            final List<AMH_GBL_Account_Relationship__c> upHierarchy = [SELECT Id, AMH_Parent_Account__c, AMH_Child_Account__c, AMH_Vision__c,DES_Main_Parent__c, AMH_Parent_Account__r.account_group__c 
                                                                        FROM AMH_GBL_Account_Relationship__c WHERE AMH_Vision__c = 'Riesgos' AND AMH_Child_Account__c =: lstAccount[0].Id AND DES_Main_Parent__c = 'S' LIMIT 1];   
            if(upHierarchy[0].AMH_Parent_Account__r.account_group__c == '1A'){
                mappingRiskHeader = subgroupParent(upHierarchy, alphaCode);
            }else{
                List<String> lstAlpha = new List<String>{alphaCode};
              mappingRiskHeader.put(alphaCode, lstAlpha);
            }
        }else{
            final List<AMH_GBL_Account_Relationship__c> subHierarchy = [SELECT Id, AMH_Parent_Account__c, AMH_Child_Account__c FROM AMH_GBL_Account_Relationship__c WHERE AMH_Vision__c = 'Riesgos' AND AMH_Child_Account__c =: lstAccount[0].Id AND DES_Main_Parent__c = 'N' LIMIT 1];
            if(subHierarchy != null && !subHierarchy.isEmpty()){
                System.debug('entro');
                final List<AMH_GBL_Account_Relationship__c> subHierarchyGroup = [SELECT Id, AMH_Parent_Account__c, AMH_Child_Account__c, AMH_Parent_Account__r.account_group__c FROM AMH_GBL_Account_Relationship__c WHERE AMH_Vision__c = 'Riesgos' AND AMH_Child_Account__c =: lstAccount[0].Id AND DES_Main_Parent__c = 'S' AND AMH_Parent_Account__r.account_group__c != '1B'];
                mappingRiskHeader = subgroupParent(subHierarchyGroup, alphaCode);
                mappingRiskHeader.remove(alphaCode);
                final List<AMH_GBL_Account_Relationship__c> subHierarchySon = [SELECT Id, AMH_Parent_Account__c, AMH_Child_Account__c FROM AMH_GBL_Account_Relationship__c WHERE AMH_Vision__c = 'Riesgos' AND AMH_Parent_Account__c =: subHierarchy[0].AMH_Parent_Account__c AND AMH_Child_Account__r.account_client__c = 'S'];
                for(AMH_GBL_Account_Relationship__c searchGroup : subHierarchySon){
                  subgroupAccounts.Add(searchGroup.AMH_Child_Account__c);
                }
                final List<Local_Client__c> lcClientSon = [SELECT Alpha_Code__c FROM Local_Client__c WHERE Cib_Client__c IN :subgroupAccounts  AND gf_prtcpt_act_status_ind_type__c = true];
                for (Local_Client__c localC : lcClientSon){
                  List<String> lstAlpha = new List<String>{localC.Alpha_Code__c};
                    mappingRiskHeader.put(localC.Alpha_Code__c, lstAlpha);
                }
                
            }else{
            
          final List<AMH_GBL_Account_Relationship__c> upHierarchy = [SELECT Id, AMH_Parent_Account__c, AMH_Child_Account__c, AMH_Vision__c,DES_Main_Parent__c,  DES_Type__c, AMH_Parent_Account__r.account_group__c  
                                                                          FROM AMH_GBL_Account_Relationship__c WHERE AMH_Vision__c = 'Riesgos' AND AMH_Child_Account__c =: lstAccount[0].Id AND DES_Main_Parent__c = 'S'];
          if(upHierarchy != null){
              
                Integer i = upHierarchy.size();
                if(i > 1){
                    
                    for(AMH_GBL_Account_Relationship__c search : upHierarchy){
                        groupAccounts.add(search.AMH_Parent_Account__c);
                    }
                    List<AMH_GBL_Account_Relationship__c> LstAccountS = [SELECT Id, AMH_Parent_Account__c, AMH_Child_Account__c, AMH_Vision__c,DES_Main_Parent__c,  DES_Type__c, AMH_Child_Account__r.account_client__c, AMH_Child_Account__r.account_group__c  
                                                                              FROM AMH_GBL_Account_Relationship__c WHERE AMH_Vision__c = 'Riesgos' AND AMH_Parent_Account__c IN :groupAccounts AND AMH_Child_Account__r.account_client__c = 's'];
                    
                    List<AMH_GBL_Account_Relationship__c> LstAccountG = [SELECT Id, AMH_Parent_Account__c, AMH_Child_Account__c, AMH_Vision__c,DES_Main_Parent__c,  DES_Type__c, AMH_Child_Account__r.account_client__c, AMH_Child_Account__r.account_group__c  
                                                                              FROM AMH_GBL_Account_Relationship__c WHERE AMH_Vision__c = 'Riesgos' AND AMH_Parent_Account__c IN :groupAccounts AND AMH_Child_Account__r.account_group__c = '3' and DES_Main_Parent__c = 'S'];
                    System.debug('REVISAR ' + LstAccountG);
                    if(LstAccountG != null && !LstAccountG.isEmpty()){
                        for(AMH_GBL_Account_Relationship__c searchAccount : LstAccountG){
                            subgroupAccounts.Add(searchAccount.AMH_Child_Account__c);
                        }
                        List<AMH_GBL_Account_Relationship__c> LstSubgroups = [SELECT Id, AMH_Parent_Account__c, AMH_Child_Account__c, AMH_Vision__c,DES_Main_Parent__c,  DES_Type__c, AMH_Child_Account__r.account_client__c, AMH_Child_Account__r.account_group__c  
                                                                              FROM AMH_GBL_Account_Relationship__c WHERE AMH_Vision__c = 'Riesgos' AND AMH_Parent_Account__c IN :subgroupAccounts AND AMH_Child_Account__r.account_client__c = 's' and DES_Main_Parent__c = 'S'];
                        subgroupAccounts.Clear();
                        for(AMH_GBL_Account_Relationship__c searchGroup : LstSubgroups){
                            subgroupAccounts.Add(searchGroup.AMH_Child_Account__c);
                        }
                        final List<Local_Client__c> lcClientHierarchy = [SELECT Alpha_Code__c FROM Local_Client__c WHERE Cib_Client__c IN :subgroupAccounts  AND gf_prtcpt_act_status_ind_type__c = true];
                        for (Local_Client__c localC : lcClientHierarchy){
                                List<String> lstAlpha = new List<String>{localC.Alpha_Code__c};
                                mappingRiskHeader.put(localC.Alpha_Code__c, lstAlpha);
                        }
                    }
                    System.debug('PRIMER MAP ' + mappingRiskHeader);
                    for(AMH_GBL_Account_Relationship__c searchAccount : LstAccountS){
                        if(searchAccount.AMH_Child_Account__r.account_client__c == 'S'){
                            final List<Local_Client__c> lcClientHierarchy = [SELECT Alpha_Code__c FROM Local_Client__c WHERE Cib_Client__c =: searchAccount.AMH_Child_Account__c  AND gf_prtcpt_act_status_ind_type__c = true];
                            for (Local_Client__c localC : lcClientHierarchy){
                                List<String> lstAlpha = new List<String>{localC.Alpha_Code__c};
                                mappingRiskHeader.put(localC.Alpha_Code__c, lstAlpha);
                            }
                        }
                    }

                }else{
                    List<AMH_GBL_Account_Relationship__c> LstAccountS = [SELECT Id, AMH_Parent_Account__c, AMH_Child_Account__c, AMH_Vision__c,DES_Main_Parent__c,  DES_Type__c, AMH_Child_Account__r.account_client__c
                                                                               FROM AMH_GBL_Account_Relationship__c WHERE AMH_Vision__c = 'Riesgos' AND AMH_Parent_Account__c =: upHierarchy[0].AMH_Parent_Account__c AND AMH_Child_Account__r.account_client__c = 'S' and DES_Main_Parent__c = 'S' AND AMH_Child_Account__r.business_group_header_type__c = true];
                    for(AMH_GBL_Account_Relationship__c searchAccount : LstAccountS){
                        if(searchAccount.AMH_Child_Account__r.account_client__c == 'S'){
                            final List<Local_Client__c> lcClientHierarchy = [SELECT Alpha_Code__c FROM Local_Client__c WHERE Cib_Client__c =: searchAccount.AMH_Child_Account__c  AND gf_prtcpt_act_status_ind_type__c = true];
                            for (Local_Client__c localC : lcClientHierarchy){
                                List<String> lstAlpha = new List<String>{localC.Alpha_Code__c};
                                mappingRiskHeader.put(localC.Alpha_Code__c, lstAlpha);
                            }
                        }
                    }
                }
          
        }
            }
    }
        
        System.debug('REVISAR : ' + mappingRiskHeader);
        return mappingRiskHeader;
    }

    /**
    * ----------------------------------------------------------------------------------------------------
    * @Description New Method to get risk header from accounts fixing problems
    * ----------------------------------------------------------------------------------------------------
    * @author hectorjeshua.vasquez.contractor@bbva.com
    * @date 2024-11-04
    * @param String alphaCode
    * @return Map<String,List<String>>
    * @example DES_Arc_Account_Hierarchy.headerFinder(alphaCode)
    * ----------------------------------------------------------------------------------------------------
    **/
    Public Static Map<String,List<String>> headerFinder (String alphaCode){
        Map<String, List<String>> mappingRiskHeader = new Map<String, List<String>>();
        final List<Local_Client__c> lcClient = [SELECT Id, Cib_Client__c FROM Local_Client__c WHERE Alpha_Code__c =: alphaCode LIMIT 1];
        final List<Account> lstAcc = [SELECT Id, account_client__c, account_group__c, DES_Main_Parent__c FROM Account WHERE Id =: lcClient[0].Cib_Client__c LIMIT 1];
        final List<AMH_GBL_Account_Relationship__c> mainHierarchy = [select Id, AMH_Child_Account__c, AMH_Parent_Account__c, DES_Main_Parent__c 
                                                                           from AMH_GBL_Account_Relationship__c 
                                                                           where AMH_Child_Account__c =: lstAcc[0].Id and AMH_Vision__c = 'Riesgos' and AMH_Parent_Account__r.account_group__c = '1A' and DES_Main_Parent__c = 'S'];
        
        final List<AMH_GBL_Account_Relationship__c> subHierarchy = [select Id, AMH_Child_Account__c, AMH_Parent_Account__c, DES_Main_Parent__c 
                                                                          from AMH_GBL_Account_Relationship__c 
                                                                          where AMH_Child_Account__c =: lstAcc[0].Id and AMH_Vision__c = 'Riesgos' and AMH_Parent_Account__r.account_group__c = '3'];
        
        final List<AMH_GBL_Account_Relationship__c> shareGesHierarchy = [select Id, AMH_Child_Account__c, AMH_Parent_Account__c, DES_Main_Parent__c 
                                                                               from AMH_GBL_Account_Relationship__c 
                                                                               where AMH_Child_Account__c =: lstAcc[0].Id and AMH_Vision__c = 'Riesgos' and AMH_Parent_Account__r.account_group__c = '1B' and DES_Main_Parent__c = 'S'];
        
        if(lstAcc[0].account_client__c == 'S' && shareGesHierarchy == null || subHierarchy == null){
            final List<AMH_GBL_Account_Relationship__c> upHierarchy = [SELECT Id, AMH_Parent_Account__c, AMH_Child_Account__c, AMH_Vision__c,DES_Main_Parent__c, AMH_Parent_Account__r.account_group__c 
                                                                        FROM AMH_GBL_Account_Relationship__c WHERE AMH_Vision__c = 'Riesgos' AND AMH_Child_Account__c =: lstAcc[0].Id AND DES_Main_Parent__c = 'S' LIMIT 1];   
            if(upHierarchy[0].AMH_Parent_Account__r.account_group__c == '1A'){
                mappingRiskHeader = subgroupParent(upHierarchy, alphaCode);
            }else{
                List<String> lstAlpha = new List<String>{alphaCode};
              mappingRiskHeader.put(alphaCode, lstAlpha);
            }
        }else{
            if (shareGesHierarchy != null && !shareGesHierarchy.isEmpty()){
                final List<AMH_GBL_Account_Relationship__c> shareGesHierarchyHeader = [select Id, AMH_Child_Account__c 
                                                                                             from AMH_GBL_Account_Relationship__c 
                                                                                             where AMH_Parent_Account__c =: shareGesHierarchy[0].AMH_Parent_Account__c and AMH_Vision__c = 'Riesgos' and AMH_Child_Account__r.account_client__c  = 'S' and AMH_Child_Account__r.business_group_header_type__c = true and DES_Main_Parent__c = 'S'];
                
                final List<Local_Client__c> lcClientHierarchy = [SELECT Alpha_Code__c FROM Local_Client__c WHERE Cib_Client__c =: shareGesHierarchyHeader[0].AMH_Child_Account__c  AND gf_prtcpt_act_status_ind_type__c = true];
                for (Local_Client__c localC : lcClientHierarchy){
                    List<String> lstAlpha = new List<String>{localC.Alpha_Code__c};
                    mappingRiskHeader.put(localC.Alpha_Code__c, lstAlpha);
                }
            } 
            if(subHierarchy != null && !subHierarchy.isEmpty()){
                final List<AMH_GBL_Account_Relationship__c> subHierarchyHeader = [select Id, AMH_Child_Account__c 
                                                                                        from AMH_GBL_Account_Relationship__c 
                                                                                        where AMH_Parent_Account__c =: subHierarchy[0].AMH_Parent_Account__c and AMH_Vision__c = 'Riesgos' and AMH_Child_Account__r.account_client__c = 'S'];
                
                final List<Local_Client__c> lcClientHierarchy = [SELECT Alpha_Code__c FROM Local_Client__c WHERE Cib_Client__c =: subHierarchyHeader[0].AMH_Child_Account__c  AND gf_prtcpt_act_status_ind_type__c = true];
                for (Local_Client__c localC : lcClientHierarchy){
                    List<String> lstAlpha = new List<String>{localC.Alpha_Code__c};
                    mappingRiskHeader.put(localC.Alpha_Code__c, lstAlpha);
                }
            }
            if(mainHierarchy != null && !mainHierarchy.isEmpty()){
                final List<AMH_GBL_Account_Relationship__c> mainHierarchyHeader = [select Id, AMH_Child_Account__c,AMH_Child_Account__r.business_group_header_type__c 
                                                                                         from AMH_GBL_Account_Relationship__c 
                                                                                         where AMH_Parent_Account__c =: mainHierarchy[0].AMH_Parent_Account__c and AMH_Vision__c = 'Riesgos' and DES_Main_Parent__c = 'S' and AMH_Child_Account__r.account_client__c = 'S'];
                Integer i = mainHierarchyHeader.size();
                if(i > 1){
                    List<String> lstAlphaGlobalbusiness = new List<String>();
                    for (AMH_GBL_Account_Relationship__c businessHeader : mainHierarchyHeader){
                        if(businessHeader.AMH_Child_Account__r.business_group_header_type__c == true){
                            lstAlphaGlobalbusiness.add(businessHeader.AMH_Child_Account__c);
                        }
                  }
                    final List<Local_Client__c> lcClientHierarchyGlobal = [SELECT Alpha_Code__c FROM Local_Client__c WHERE Cib_Client__c =: lstAlphaGlobalbusiness[0] AND gf_prtcpt_act_status_ind_type__c = true];
                    for (Local_Client__c localC : lcClientHierarchyGlobal){
                        List<String> lstAlphaGlobal = new List<String>{localC.Alpha_Code__c};
                        mappingRiskHeader.put(localC.Alpha_Code__c, lstAlphaGlobal);
                    }
                }else{
                    final List<Local_Client__c> lcClientHierarchyGlobal = [SELECT Alpha_Code__c FROM Local_Client__c WHERE Cib_Client__c =: mainHierarchyHeader[0].AMH_Child_Account__c  AND gf_prtcpt_act_status_ind_type__c = true];
                    for (Local_Client__c localC : lcClientHierarchyGlobal){
                        List<String> lstAlphaGlobal = new List<String>{localC.Alpha_Code__c};
                        mappingRiskHeader.put(localC.Alpha_Code__c, lstAlphaGlobal);
                    }
                }
            }
      }
        Integer count = mappingRiskHeader.size();
        if(count > 1){
          mappingRiskHeader.remove(alphaCode);
        }
        System.debug('REVISAR : ' + mappingRiskHeader);
        return mappingRiskHeader;
    }
    
    /**
    * ----------------------------------------------------------------------------------------------------
    * @Description Method to get local client child hierarchy
    * ----------------------------------------------------------------------------------------------------
    * @author hectorjeshua.vasquez.contractor@bbva.com
    * @date 2022-14-10
    * @param String alphaCode
    * @return Map<String,List<String>>
    * @example DES_Arc_Account_Hierarchy.childHierarchy(alphaCode)
    * ----------------------------------------------------------------------------------------------------
    **/
    Public Static Map<String,List<String>> subgroupParent (List<AMH_GBL_Account_Relationship__c> upHierarchy, String alphaCode){
        Map<String, List<String>> mappingRiskHeader = new Map<String, List<String>>();
        Set<String> groupAccounts = new Set<String>();
        Set<String> subgroupAccounts = new Set<String>();
        Set<String> alphaCodes = new Set<String>();
            for(AMH_GBL_Account_Relationship__c search : upHierarchy){
              groupAccounts.add(search.AMH_Parent_Account__c);
            }
            List<AMH_GBL_Account_Relationship__c> LstAccountS = [SELECT Id, AMH_Parent_Account__c, AMH_Child_Account__c, AMH_Vision__c,DES_Main_Parent__c,  DES_Type__c, AMH_Child_Account__r.account_client__c, AMH_Child_Account__r.account_group__c  
                                                                          FROM AMH_GBL_Account_Relationship__c WHERE AMH_Vision__c = 'Riesgos' AND AMH_Parent_Account__c IN :groupAccounts AND AMH_Child_Account__r.account_client__c = 's' and DES_Main_Parent__c = 'S' AND AMH_Child_Account__r.business_group_header_type__c = true];

       
          for(AMH_GBL_Account_Relationship__c searchAccount : LstAccountS){
                    if(searchAccount.AMH_Child_Account__r.account_client__c == 'S'){
                        final List<Local_Client__c> lcClientHierarchy = [SELECT Alpha_Code__c FROM Local_Client__c WHERE Cib_Client__c =: searchAccount.AMH_Child_Account__c  AND gf_prtcpt_act_status_ind_type__c = true];
                        for (Local_Client__c localC : lcClientHierarchy){
                            List<String> lstAlpha = new List<String>{localC.Alpha_Code__c};
                            mappingRiskHeader.put(localC.Alpha_Code__c, lstAlpha);
                        }
                    }
                }
            if (mappingRiskHeader == null || mappingRiskHeader.isempty()){
                List<String> lstAlpha = new List<String>{alphaCode};
                mappingRiskHeader.put(alphaCode, lstAlpha);
            }
            return mappingRiskHeader;
    }

    /**
    * ----------------------------------------------------------------------------------------------------
    * @Description Method to get local client from client
    * ----------------------------------------------------------------------------------------------------
    * @author hectorjeshua.vasquez.contractor@bbva.com
    * @date 2022-14-10
    * @param String accountId
    * @return Set<String>
    * @example DES_Arc_Account_Hierarchy.childHierarchy(accountId)
    * ----------------------------------------------------------------------------------------------------
    **/
    Public Static Set<String> localClientFinder (Set<String> accounts){
        Set <String> lcClient = new Set<String>();
        for(Local_Client__c lcClients : [SELECT Id, Cib_Client__c FROM Local_Client__c WHERE Cib_Client__c IN :accounts AND gf_prtcpt_act_status_ind_type__c = true]){
            lcClient.add(lcClients.Id);
        }
        return lcClient;
    }
    
    /**
    * ----------------------------------------------------------------------------------------------------
    * @Description Method to get local client from client
    * ----------------------------------------------------------------------------------------------------
    * @author hectorjeshua.vasquez.contractor@bbva.com
    * @date 2022-14-10
    * @param String accountId
    * @return Set<String>
    * @example DES_Arc_Account_Hierarchy.childHierarchy(accountId)
    * ----------------------------------------------------------------------------------------------------
    **/
    Public Static String localClientFinder (String account){
        String lcClient;
        for(Local_Client__c lcClients : [SELECT Id, Cib_Client__c FROM Local_Client__c WHERE Cib_Client__c = :account AND gf_prtcpt_act_status_ind_type__c = true]){
            lcClient = lcClients.Id;
        }
        return lcClient;
    }

    /**
    * ----------------------------------------------------------------------------------------------------
    * @Description Method to get local client from client
    * ----------------------------------------------------------------------------------------------------
    * @author hectorjeshua.vasquez.contractor@bbva.com
    * @date 2023-30-11
    * @param String accountId
    * @return Set<String>
    * @example DES_Arc_Account_Hierarchy.childHierarchy(accountId)
    * ----------------------------------------------------------------------------------------------------
    **/
    Public Static String localClientAlphaFinder (String account){
        String lcClientAlphaCode;
        for(Local_Client__c lcClients : [SELECT Id, Alpha_code__c FROM Local_Client__c WHERE Cib_Client__c = :account AND gf_prtcpt_act_status_ind_type__c = true]){
            lcClientAlphaCode = lcClients.Alpha_code__c;
        }
        return lcClientAlphaCode;
    }
    
    /**
    * ----------------------------------------------------------------------------------------------------
    * @Description Method to get local client from client
    * ----------------------------------------------------------------------------------------------------
    * @author hectorjeshua.vasquez.contractor@bbva.com
    * @date 2023-30-11
    * @param String accountId
    * @return Set<String>
    * @example DES_Arc_Account_Hierarchy.childHierarchy(accountId)
    * ----------------------------------------------------------------------------------------------------
    **/
    Public Static Set<String> localClientAlphaFinder (Set<String> accounts){
        Set <String> lcClientAlphaCode = new Set<String>();
        for(Local_Client__c lcClients : [SELECT Id, Alpha_code__c FROM Local_Client__c WHERE Cib_Client__c IN :accounts AND gf_prtcpt_act_status_ind_type__c = true]){
            lcClientAlphaCode.add(lcClients.Id);
        }
        return lcClientAlphaCode;
    }

    Public Static Map<String, List<String>> alphaCodeHierarchy (String accId){
        Map<Id, Id> mappingRiskHeader = new Map<Id, Id>();
        Set <String> ftherChild = new Set<String>();
        Set <String> father = new Set<String>();
        Set<String> subgroupAccounts = new Set<String>();
        Set<String> subgroupAccountsHeader = new Set<String>();
        Set<String> subChilds = new Set<String>();
        Map<Id, Set<string>> parentToChildren = new Map<Id, Set<String>>();
        Map<Id, Id> parentToChildrenHeader = new Map<Id, Id>();
        Map<String, List<String>> mappingRiskHeader2 = new Map<String, List<String>>();
        String fatherId;
        String subParent;
        String subGroupfatherId;
        final List<AMH_GBL_Account_Relationship__c> lstFather = [SELECT Id, AMH_Parent_Account__c, AMH_Child_Account__c, AMH_Parent_Account__r.account_group__c 
                                                                      FROM  AMH_GBL_Account_Relationship__c WHERE AMH_Vision__c = 'Riesgos' AND AMH_Child_Account__c = :accId and DES_Main_Parent__c = 'S'];
        if(lstFather[0].AMH_Parent_Account__r.account_group__c == '1A'){
            List<AMH_GBL_Account_Relationship__c> LstFatherHeader = [SELECT Id, AMH_Parent_Account__c, AMH_Child_Account__c, AMH_Vision__c,DES_Main_Parent__c,  DES_Type__c, AMH_Child_Account__r.account_client__c, AMH_Child_Account__r.account_group__c  
                                                                          FROM AMH_GBL_Account_Relationship__c WHERE AMH_Vision__c = 'Riesgos' AND AMH_Parent_Account__c = :lstFather[0].AMH_Parent_Account__c AND AMH_Child_Account__r.account_client__c = 's' and DES_Main_Parent__c = 'S' AND AMH_Child_Account__r.business_group_header_type__c = true];
            
            List<AMH_GBL_Account_Relationship__c> LstFtherChilds = [SELECT Id, AMH_Parent_Account__c, AMH_Child_Account__c, AMH_Vision__c,DES_Main_Parent__c,  DES_Type__c, AMH_Child_Account__r.account_client__c, AMH_Child_Account__r.account_group__c , AMH_ChildName__c
                                                                         FROM AMH_GBL_Account_Relationship__c WHERE AMH_Vision__c = 'Riesgos' AND AMH_Parent_Account__c = :lstFather[0].AMH_Parent_Account__c  AND AMH_Child_Account__r.business_group_header_type__c = false AND AMH_Child_Account__r.account_group__c = null];
        
            List<AMH_GBL_Account_Relationship__c> LstSubgroups = [SELECT Id, AMH_Parent_Account__c, AMH_Child_Account__c, AMH_Vision__c,DES_Main_Parent__c,  DES_Type__c, AMH_Child_Account__r.account_client__c, AMH_Child_Account__r.account_group__c , AMH_ChildName__c
                                                                        FROM AMH_GBL_Account_Relationship__c WHERE AMH_Vision__c = 'Riesgos' AND AMH_Parent_Account__c = :lstFather[0].AMH_Parent_Account__c  AND AMH_Child_Account__r.business_group_header_type__c = false AND AMH_Child_Account__r.account_group__c != null AND AMH_Child_Account__r.account_group__c != '1B'];
            for(AMH_GBL_Account_Relationship__c accountSetter : LstFatherHeader){
                father.add(accountSetter.AMH_Child_Account__c);
            }

            for(AMH_GBL_Account_Relationship__c accountSetter : LstFtherChilds){
                ftherChild.add(accountSetter.AMH_Child_Account__c);
            }

            father = localClientAlphaFinder(father);
            List<String> lstFatherId = new List<String>(); 
            List<String> lstSubgroupId = new List<String>(); 
            List<String> lstFatherChldG = new List<String>(); 
            List<String> lstChldSub = new List<String>(); 
            lstFatherId.addAll(father);
            fatherId = lstFatherId[0];
            ftherChild = localClientAlphaFinder(ftherChild);
            for(String childs : ftherChild){
                lstFatherChldG.add(childs);
            }
            if(LstSubgroups != null && !LstSubgroups.isEmpty()){
                for(AMH_GBL_Account_Relationship__c searchAccount : LstSubgroups){
                    subgroupAccounts.Add(searchAccount.AMH_Child_Account__c);
                }
                List<AMH_GBL_Account_Relationship__c> LstSubgroupsHeader = [SELECT Id, AMH_Parent_Account__c, AMH_Child_Account__c, AMH_Vision__c,DES_Main_Parent__c,  DES_Type__c, AMH_Child_Account__r.account_client__c, AMH_Child_Account__r.account_group__c, AMH_ChildName__c  
                                                                              FROM AMH_GBL_Account_Relationship__c WHERE AMH_Vision__c = 'Riesgos' AND AMH_Parent_Account__c IN :subgroupAccounts AND AMH_Child_Account__r.account_client__c = 's'];

                for(AMH_GBL_Account_Relationship__c searchAccount : LstSubgroupsHeader){
                    subgroupAccountsHeader.Add(searchAccount.AMH_Child_Account__c);
                    parentToChildrenHeader.put(searchAccount.AMH_Parent_Account__c, searchAccount.AMH_Child_Account__c);
                }
                
                
                List<AMH_GBL_Account_Relationship__c> LstSubgroupsHeaderSons = [SELECT Id, AMH_Parent_Account__c, AMH_Child_Account__c, AMH_Vision__c,DES_Main_Parent__c,  DES_Type__c, AMH_Child_Account__r.account_client__c, AMH_Child_Account__r.account_group__c, AMH_ChildName__c  
                                                                              FROM AMH_GBL_Account_Relationship__c WHERE AMH_Vision__c = 'Riesgos' AND AMH_Parent_Account__c IN :subgroupAccounts AND AMH_Child_Account__r.account_client__c = 'N' ];

                for(AMH_GBL_Account_Relationship__c subgroups : LstSubgroupsHeaderSons){
                    if (!parentToChildren.containsKey(subgroups.AMH_Parent_Account__c))
                        parentToChildren.put(subgroups.AMH_Parent_Account__c, new set<String>());
                    parentToChildren.get(subgroups.AMH_Parent_Account__c).add(subgroups.AMH_Child_Account__c);
                }
                for(AMH_GBL_Account_Relationship__c searchAccount : LstSubgroups){
                    subParent = parentToChildrenHeader.get(searchAccount.AMH_Child_Account__c);
                    String subparentAcc = subParent;
                    subParent = localClientAlphaFinder(subParent);
                    if(subParent != null){
                        subChilds = parentToChildren.get(searchAccount.AMH_Child_Account__c);
                        List<arce__Account_has_Analysis__c> lstHasAnalysis = [SELECT Id, arce__Customer__r.Name from arce__Account_has_Analysis__c where DES_Local_Client__c  = :subParent LIMIT 1]; 
                        if(lstHasAnalysis != null && !lstHasAnalysis.isEmpty()){
                            subChilds = localClientAlphaFinder(subChilds);
                            if(subparentAcc == LstFatherHeader[0].AMH_Child_Account__c){
                                for(String child :  subChilds){
                                    //mappingRiskHeader.put(child,fatherId);
                                    lstFatherChldG.Add(child);
                                }
                            }
                            lstChldSub.clear();
                        }
                    }
                }                

            }
            
            mappingRiskHeader2.put(fatherId, lstFatherChldG);

        }
        return (mappingRiskHeader2);
    }

    
    /**
    * ----------------------------------------------------------------------------------------------------
    * @Description Method to get local client child hierarchy
    * ----------------------------------------------------------------------------------------------------
    * @author hectorjeshua.vasquez.contractor@bbva.com
    * @date 2022-14-10
    * @param String alphaCode
    * @return Map<String,List<String>>
    * @example DES_Arc_Account_Hierarchy.childHierarchy(alphaCode)
    * ----------------------------------------------------------------------------------------------------
    **/
    Public Static arce.Arc_Gen_Group_Structure_Wrapper childHierarchy (String analysis){
        final arce.Arc_Gen_Group_Structure_Wrapper toRtn = new arce.Arc_Gen_Group_Structure_Wrapper();
        Map<Id, Id> mappingRiskHeader = new Map<Id, Id>();
        Set <String> ftherChild = new Set<String>();
        Set <String> father = new Set<String>();
        Set<String> subgroupAccounts = new Set<String>();
        Set<String> subgroupAccountsHeader = new Set<String>();
        Set<String> subChilds = new Set<String>();
        Map<Id, Set<string>> parentToChildren = new Map<Id, Set<String>>();
        Map<Id, Id> parentToChildrenHeader = new Map<Id, Id>();
        Map<Id, List<Id>> mappingRiskHeader2 = new Map<Id, List<Id>>();
        String fatherId;
        String subParent;
        String subGroupfatherId;
        final List<arce__Analysis__c> lcAnalysis = [Select Id, Local_Client__c, arce__Group__c FROM arce__Analysis__c WHERE Id =: analysis];
        final List<AMH_GBL_Account_Relationship__c> lstFather = [SELECT Id, AMH_Parent_Account__c, AMH_Child_Account__c, AMH_Parent_Account__r.account_group__c 
                                                                      FROM  AMH_GBL_Account_Relationship__c WHERE AMH_Vision__c = 'Riesgos' AND AMH_Child_Account__c = :lcAnalysis[0].arce__Group__c and DES_Main_Parent__c = 'S'];
        if(lstFather[0].AMH_Parent_Account__r.account_group__c == '1A'){
            List<AMH_GBL_Account_Relationship__c> LstFatherHeader = [SELECT Id, AMH_Parent_Account__c, AMH_Child_Account__c, AMH_Vision__c,DES_Main_Parent__c,  DES_Type__c, AMH_Child_Account__r.account_client__c, AMH_Child_Account__r.account_group__c  
                                                                          FROM AMH_GBL_Account_Relationship__c WHERE AMH_Vision__c = 'Riesgos' AND AMH_Parent_Account__c = :lstFather[0].AMH_Parent_Account__c AND AMH_Child_Account__r.account_client__c = 's' and DES_Main_Parent__c = 'S' AND AMH_Child_Account__r.business_group_header_type__c = true];
            
            List<AMH_GBL_Account_Relationship__c> LstFtherChilds = [SELECT Id, AMH_Parent_Account__c, AMH_Child_Account__c, AMH_Vision__c,DES_Main_Parent__c,  DES_Type__c, AMH_Child_Account__r.account_client__c, AMH_Child_Account__r.account_group__c , AMH_ChildName__c
                                                                         FROM AMH_GBL_Account_Relationship__c WHERE AMH_Vision__c = 'Riesgos' AND AMH_Parent_Account__c = :lstFather[0].AMH_Parent_Account__c  AND AMH_Child_Account__r.business_group_header_type__c = false AND AMH_Child_Account__r.account_group__c = null];
    
            List<AMH_GBL_Account_Relationship__c> LstSubgroups = [SELECT Id, AMH_Parent_Account__c, AMH_Child_Account__c, AMH_Vision__c,DES_Main_Parent__c,  DES_Type__c, AMH_Child_Account__r.account_client__c, AMH_Child_Account__r.account_group__c , AMH_ChildName__c
                                                                        FROM AMH_GBL_Account_Relationship__c WHERE AMH_Vision__c = 'Riesgos' AND AMH_Parent_Account__c = :lstFather[0].AMH_Parent_Account__c  AND AMH_Child_Account__r.business_group_header_type__c = false AND AMH_Child_Account__r.account_group__c != null AND AMH_Child_Account__r.account_group__c != '1B'];
            for(AMH_GBL_Account_Relationship__c accountSetter : LstFatherHeader){
                father.add(accountSetter.AMH_Child_Account__c);
            }

            for(AMH_GBL_Account_Relationship__c accountSetter : LstFtherChilds){
                ftherChild.add(accountSetter.AMH_Child_Account__c);
            }

            father = localClientFinder(father);
            List<String> lstFatherId = new List<String>(); 
            List<String> lstSubgroupId = new List<String>(); 
            List<String> lstFatherChldG = new List<String>(); 
            List<String> lstChldSub = new List<String>(); 
            lstFatherId.addAll(father);
            fatherId = lstFatherId[0];
            ftherChild = localClientFinder(ftherChild);
            for(String childs : ftherChild){
                mappingRiskHeader.put(childs,fatherId);
                lstFatherChldG.add(childs);
            }
            mappingRiskHeader.put(fatherId,null);
            if(LstSubgroups != null && !LstSubgroups.isEmpty()){
                for(AMH_GBL_Account_Relationship__c searchAccount : LstSubgroups){
                    subgroupAccounts.Add(searchAccount.AMH_Child_Account__c);
                }
                List<AMH_GBL_Account_Relationship__c> LstSubgroupsHeader = [SELECT Id, AMH_Parent_Account__c, AMH_Child_Account__c, AMH_Vision__c,DES_Main_Parent__c,  DES_Type__c, AMH_Child_Account__r.account_client__c, AMH_Child_Account__r.account_group__c, AMH_ChildName__c  
                                                                              FROM AMH_GBL_Account_Relationship__c WHERE AMH_Vision__c = 'Riesgos' AND AMH_Parent_Account__c IN :subgroupAccounts AND AMH_Child_Account__r.account_client__c = 's'];

                for(AMH_GBL_Account_Relationship__c searchAccount : LstSubgroupsHeader){
                    subgroupAccountsHeader.Add(searchAccount.AMH_Child_Account__c);
                    parentToChildrenHeader.put(searchAccount.AMH_Parent_Account__c, searchAccount.AMH_Child_Account__c);
                }
                
                
                List<AMH_GBL_Account_Relationship__c> LstSubgroupsHeaderSons = [SELECT Id, AMH_Parent_Account__c, AMH_Child_Account__c, AMH_Vision__c,DES_Main_Parent__c,  DES_Type__c, AMH_Child_Account__r.account_client__c, AMH_Child_Account__r.account_group__c, AMH_ChildName__c  
                                                                              FROM AMH_GBL_Account_Relationship__c WHERE AMH_Vision__c = 'Riesgos' AND AMH_Parent_Account__c IN :subgroupAccounts AND AMH_Child_Account__r.account_client__c = 'N' ];

                for(AMH_GBL_Account_Relationship__c subgroups : LstSubgroupsHeaderSons){
                    if (!parentToChildren.containsKey(subgroups.AMH_Parent_Account__c))
                        parentToChildren.put(subgroups.AMH_Parent_Account__c, new set<String>());
                    parentToChildren.get(subgroups.AMH_Parent_Account__c).add(subgroups.AMH_Child_Account__c);
                }
        for(AMH_GBL_Account_Relationship__c searchAccount : LstSubgroups){
                    subParent = parentToChildrenHeader.get(searchAccount.AMH_Child_Account__c);
                    String subparentAcc = subParent;
                    subParent = localClientFinder(subParent);
                    if(subParent != null){
                        subChilds = parentToChildren.get(searchAccount.AMH_Child_Account__c);
                        List<arce__Account_has_Analysis__c> lstHasAnalysis = [SELECT Id, arce__Customer__r.Name from arce__Account_has_Analysis__c where DES_Local_Client__c  = :subParent LIMIT 1]; 
                        if(lstHasAnalysis != null && !lstHasAnalysis.isEmpty()){
                            subChilds = localClientFinder(subChilds);
                            if(subparentAcc == LstFatherHeader[0].AMH_Child_Account__c){
                                for(String child :  subChilds){
                                    mappingRiskHeader.put(child,fatherId);
                                    lstFatherChldG.Add(child);
                                }
                            }else{
                                for(String child :  subChilds){
                                    mappingRiskHeader.put(child,subParent);
                                    lstChldSub.Add(child);
                                }
                                mappingRiskHeader2.put(subParent, lstChldSub);
                            }
                            lstChldSub.clear();
                        }
                    }
                }                

            }
            
            mappingRiskHeader2.put(fatherId, lstFatherChldG);
            mappingRiskHeader2.put(null,lstFatherId);

        }
        toRtn.accountMapW = mappingRiskHeader;
        toRtn.treeMapW = mappingRiskHeader2;
        return (toRtn);
    }
    

}