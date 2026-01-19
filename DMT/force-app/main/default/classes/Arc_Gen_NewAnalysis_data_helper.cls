/**
* ------------------------------------------------------------------------------------------------
* @Name     Arc_Gen_NewAnalysis_data_helper.cls
* @Author   antonio.perez.hernandez.contractor@bbva.com
* @Date     Created: 2023-06-08
* @Group    ARCE
* ------------------------------------------------------------------------------------------------
* @Description Class that contains some methods of Arc_Gen_NewAnalysis_data
* ------------------------------------------------------------------------------------------------
* @Changes
* |08/06/2023   antonio.perez.hernandez.contractor@bbva.com
*               Remove @SuppressWarnings('sf:TooManyMethods') on Arc_Gen_NewAnalysis_data
**/
public with sharing class Arc_Gen_NewAnalysis_data_helper {
    /**
    * @Description Subprocess type of RAIP.
    * @Author antonio.perez.hernandez.contractor@bbva.com
    */
    public static final String MODIFY_TEXT = 'Modification';
    /**
    * @Description String with value of hyphen between spaces.
    * @Author antonio.perez.hernandez.contractor@bbva.com
    */
    public static final String HYPHEN_SYMB = ' - ';

    /**
    *-------------------------------------------------------------------------------
    * @Description Empty constructor method
    *-------------------------------------------------------------------------------
    * @Author antonio.perez.hernandez.contractor@bbva.com
    * @Date 08/06/2023
    */
    @TestVisible
    private Arc_Gen_NewAnalysis_data_helper() { }

    /**
    *-------------------------------------------------------------------------------
    * @Description Method get the subprocess name
    *-------------------------------------------------------------------------------
    * @Date 03/04/2023
    * @Author antonio.perez.hernandez.contractor@bbva.com
    * @param newAnalysis    - arce__Analysis__c record
    * @param isFastTrackRen - Boolean to check if the flag of fast track flow is active
    * @return subprocess name
    * @example Arc_Gen_NewAnalysis_data.getSubprocessName(newAnalysis, isFastTrackRen)
    */
    public static String getSubprocessName(arce__Analysis__c newAnalysis, Boolean isFastTrackRen) {
        return isFastTrackRen ? System.Label.Arc_Gen_FastTrack_Title : newAnalysis.arce__anlys_wkfl_sub_process_type__c;
    }

    /**
    *-------------------------------------------------------------------------------
    * @Description Method to obtain the related group name of the ARCE
    *-------------------------------------------------------------------------------
    * @Date 03/04/2023
    * @Author antonio.perez.hernandez.contractor@bbva.com
    * @param newAnalysis - arce__Analysis__c record
    * @param nameNoAcc   - String to verify if there is a custom account related
    * @return String     - Name of the related group
    * @example Arc_Gen_NewAnalysis_data.getGroupName(newAnalysis, nameNoAcc)
    */
    public static String getGroupName(arce__Analysis__c newAnalysis, String nameNoAcc) {
        return String.isBlank(nameNoAcc) ? newAnalysis.arce__Group__r.Name.abbreviate(30) : nameNoAcc;
    }

    /**
    *-------------------------------------------------------------------------------
    * @Description Method to obtain justification if the ARCE is a modification
    *-------------------------------------------------------------------------------
    * @Date 03/04/2023
    * @Author antonio.perez.hernandez.contractor@bbva.com
    * @param newAnalysis    - arce__Analysis__c record
    * @param nameSubProcess - name of the ARCE subprocess
    * @return String        - justification of the ARCE
    * @example Arc_Gen_NewAnalysis_data.getMaxSubpJust(newAnalysis, nameSubProcess)
    */
    public static String getMaxSubpJust(arce__Analysis__c newAnalysis, String nameSubProcess) {
        return nameSubProcess + HYPHEN_SYMB + newAnalysis.arce__gf_curr_anlys_mod_justn_type__c;
    }

    /**
    *-------------------------------------------------------------------------------
    * @Description Method return the name of the ARCE
    *-------------------------------------------------------------------------------
    * @Date 03/04/2023
    * @Author antonio.perez.hernandez.contractor@bbva.com
    * @param newAnalysis    - arce__Analysis__c record
    * @param maxSubpJust    - Justification if the ARCE is a modification
    * @param maxGroupName   - Name of the related group
    * @param nameSubProcess - Name of the subprocess
    * @return String        - Name of the ARCE
    * @example Arc_Gen_NewAnalysis_data.getArceName(newAnalysis, maxSubpJust, maxGroupName, nameSubProcess)
    */
    public static String getArceName(arce__Analysis__c newAnalysis, String maxSubpJust, String maxGroupName, String nameSubProcess) {
        String result = '';
        if (newAnalysis.arce__anlys_wkfl_sub_process_type__c == MODIFY_TEXT) {
            result = maxSubpJust.abbreviate(30) + HYPHEN_SYMB + maxGroupName + HYPHEN_SYMB + newAnalysis.arce__parent_analysis_id__c;
        } else {
            final String subProcessName = nameSubProcess.equalsIgnoreCase('rating') && String.isNotBlank(newAnalysis.arce__rating_prerating_type__c) && newAnalysis.arce__rating_prerating_type__c.equalsIgnoreCase('prerating') ? 'Prerating' : nameSubProcess;
            result = subProcessName + HYPHEN_SYMB + maxGroupName + HYPHEN_SYMB + newAnalysis.arce__parent_analysis_id__c;
        }
        return result;
    }
}