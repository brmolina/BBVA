/**
* ------------------------------------------------------------------------------------------------
* @Name     Arc_Gen_ShareholderTable_Helper
* @Author   Mario Humberto Ramirez Lio  mariohumberto.ramirez.contractor@bbva.com
* @Date     Created: 2020-05-06
* @Group    ARCE
* ------------------------------------------------------------------------------------------------
* @Description helper class for Arc_Gen_ShareholderTable_Service
* ------------------------------------------------------------------------------------------------
* @Changes
*
* |2020-05-06 mariohumberto.ramirez.contractor@bbva.com
*             Class creation.
* |2020-05-15 mariohumberto.ramirez.contractor@bbva.com
*             Sorting by shareholder name added.
* |2020-03-12 juanpedro.benito.contractor@bbva.com
*             Change arce__third_participant_per__c for arce__third_prtcpt_intervention_per__c
* |2021-06-17 juanignacio.hita.contractor@bbva.com
*             Rollback last commit  (PR: 1231)
* -----------------------------------------------------------------------------------------------
*/
public without sharing class Arc_Gen_ShareholderTable_Helper {
    /*
        @Description code for TOTAL
    */
    static final String TOTAL_COLUMN = 'TOTAL';
    /**
    * ----------------------------------------------------------------------------------------------------
    * @Description Void Constructor to avoid warning in sonar qube
    * ----------------------------------------------------------------------------------------------------
    * @Author   mariohumberto.ramirez.contractor@bbva.com
    * @Date     2020-05-06
    * @param void
    * @return void
    * @example Arc_Gen_ShareholderTable_Helper helper = new Arc_Gen_ShareholderTable_Helper()
    * ----------------------------------------------------------------------------------------------------
    **/
    @TestVisible
    private Arc_Gen_ShareholderTable_Helper() {}
    /**
    *---------------------------------------------------------------------------------------------------
    * @Description create the shareholder group table structure
    *---------------------------------------------------------------------------------------------------
    * @Author  mariohumberto.ramirez.contractor@bbva.com
    * @Date    2020-05-06
    * @param   accHasIdLts - ids of the account has analysis
    * @param   columns2Show - names of the columns to show
    * @return  Arc_Gen_ShareholderTable_Ctr.ShareHoldTableWp wrapper with the structure needed to build
    *          the table
    * @example buildTableStructure(accHasIdLts, columns2Show)
    * --------------------------------------------------------------------------------------------------
    **/
    public static Arc_Gen_ShareholderTable_Ctr.ShareHoldTableWp buildTableStructure(List<String> accHasIdLts, List<String> columns2Show) {
        final Arc_Gen_ShareholderTable_Ctr.ShareHoldTableWp shareHoldWrapper = new Arc_Gen_ShareholderTable_Ctr.ShareHoldTableWp();
        Map<String,Map<String,String>> shareHoldInfo = new Map<String,Map<String,String>>();
        Set<String> shareHoldNameLts = new Set<String>();
        Set<String> subsidiaryNameLts = new Set<String>();
        Map<String,String> mapAux = new Map<String,String>();
        Integer total = 0;
        final List<arce__third_participant_details__c> thirdPartInfoLts = Arc_Gen_ThirdParticipantDetails_Data.getInfoForShareHoldGpTable(accHasIdLts);
        if (thirdPartInfoLts.isEmpty()) {
            shareHoldWrapper.hasInfo = false;
        } else {
            String currentPartName = thirdPartInfoLts[0].arce__account_has_analysis_id__r.arce__participant_name__c;
            for (arce__third_participant_details__c thirdInfo: thirdPartInfoLts) {
                if (columns2Show.contains(thirdInfo.arce__account_has_analysis_id__r.arce__participant_name__c) || columns2Show.isEmpty()) {
                    subsidiaryNameLts.add(thirdInfo.arce__account_has_analysis_id__r.arce__participant_name__c);
                    shareHoldNameLts.add(thirdInfo.arce__Third_Participant_id__r.Name);
                    if (currentPartName == thirdInfo.arce__account_has_analysis_id__r.arce__participant_name__c) {
                        total += integer.valueOf(thirdInfo.arce__third_participant_per__c);
                        mapAux.put(thirdInfo.arce__Third_Participant_id__r.Name, String.valueOf(thirdInfo.arce__third_participant_per__c) + '%');
                        mapAux.put(TOTAL_COLUMN, String.valueOf(total) + '%');
                        shareHoldInfo.put(thirdInfo.arce__account_has_analysis_id__r.arce__participant_name__c, mapAux);
                    } else {
                        total = 0;
                        total += Integer.valueOf(thirdInfo.arce__third_participant_per__c);
                        mapAux = new Map<String,String>();
                        currentPartName = thirdInfo.arce__account_has_analysis_id__r.arce__participant_name__c;
                        mapAux.put(thirdInfo.arce__Third_Participant_id__r.Name, String.valueOf(thirdInfo.arce__third_participant_per__c) + '%');
                        mapAux.put(TOTAL_COLUMN, String.valueOf(total) + '%');
                        shareHoldInfo.put(thirdInfo.arce__account_has_analysis_id__r.arce__participant_name__c, mapAux);
                    }
                }
            }
            List<String> shareHoldNameSort = new List<String>();
            shareHoldNameSort.addAll(shareHoldNameLts);
            shareHoldNameSort.sort();
            shareHoldNameSort.add(TOTAL_COLUMN);
            Set<String> columsInfo = new Set<String>{Label.Arc_Gen_Shareholder};
            columsInfo.addAll(subsidiaryNameLts);
            shareHoldWrapper.rowInfo = getRowStructure(shareHoldNameSort, subsidiaryNameLts, shareHoldInfo);//rowInfoLts;
            shareHoldWrapper.columnsInfo = columsInfo;
            shareHoldWrapper.hasInfo = true;
        }
        return shareHoldWrapper;
    }
    /**
    *---------------------------------------------------------------------------------------------------
    * @Description create the shareholder group table row information
    *---------------------------------------------------------------------------------------------------
    * @Author  mariohumberto.ramirez.contractor@bbva.com
    * @Date    2020-05-06
    * @param   shareHoldNameLts - names of the shareholders
    * @param   subsidiaryNameLts - names of the subsidiaries
    * @param   shareHoldInfo - shareholder information
    * @return  List<Map<String,String>> List with the row structure
    * @example getRowStructure(shareHoldNameLts, subsidiaryNameLts, shareHoldInfo)
    * --------------------------------------------------------------------------------------------------
    **/
    public static List<Map<String,String>> getRowStructure(List<String> shareHoldNameLts, Set<String> subsidiaryNameLts, Map<String,Map<String,String>> shareHoldInfo) {
        Map<String,String> rowInfoMap = new Map<String,String>();
        List<Map<String,String>> rowInfoLts = new List<Map<String,String>>();
        for (String shareHolderName: shareHoldNameLts) {
            for (String subsidiaryName: subsidiaryNameLts) {
                if(shareHoldInfo.get(subsidiaryName).containsKey(shareHolderName)) {
                    rowInfoMap.put(Label.Arc_Gen_Shareholder, shareHolderName);
                    rowInfoMap.put(subsidiaryName, shareHoldInfo.get(subsidiaryName).get(shareHolderName));
                }
                else {
                    rowInfoMap.put(subsidiaryName, '-');
                }
            }
            rowInfoLts.add(rowInfoMap);
            rowInfoMap = new Map<String,String>();
        }
        return rowInfoLts;
    }
    /**
    *---------------------------------------------------------------------------------------------------
    * @Description create the row structure for the shareholder group table
    *---------------------------------------------------------------------------------------------------
    * @Author  mariohumberto.ramirez.contractor@bbva.com
    * @Date    2020-05-06
    * @param   Arc_Gen_ShareholderTable_Ctr.ShareHoldTableWp wrapper with the structure needed to build
    *          the table
    * @return  List<List<String>> - with the row information to build the shareholder group table
    * @example getRowInfo(shareHoldWrapper)
    * --------------------------------------------------------------------------------------------------
    **/
    public static List<List<String>> getRowInfo(Arc_Gen_ShareholderTable_Ctr.ShareHoldTableWp shareHoldWrapper) {
        List<List<String>> rowLts = new List<List<String>>();
        Set<String> columns = shareHoldWrapper.columnsInfo;
        List<Map<String,String>> rows = shareHoldWrapper.rowInfo;
        for (Map<String,String> row: rows) {
            List<String> tempList = new List<String>();
            for (String column: columns) {
                tempList.add(row.get(column));
            }
            rowLts.add(tempList);
        }
        return rowLts;
    }
}