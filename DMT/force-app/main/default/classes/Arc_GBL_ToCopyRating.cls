/**
* --------------------------------------------------------------------------------------------------------
* @Name     Arc_GBL_ToCopyRating
* @Author   Antonio Muñoz Pérez  antonio.munoz.perez.contractor@bbva.com
* @Date     Created: 2020-12-16
* @Group    ARCE
* --------------------------------------------------------------------------------------------------------
* @Description  GBL class that implements Arc_Gen_ToCopyRating_Interface
* --------------------------------------------------------------------------------------------------------
* @Changes
*
* |2020-12-16 antonio.munoz.perez.contractor@bbva.com
*             Class creation.
* |2022-03-23 francisco.munoz.torres.contractor@bbva.com
*             Filter the template names in updateRating
* |2022-03-29 francisco.munoz.torres.contractor@bbva.com
*             Changes the way to get the template names
* --------------------------------------------------------------------------------------------------------
*/
public With Sharing class Arc_GBL_ToCopyRating implements Arc_Gen_ToCopyRating_Interface {
    /**
    * ----------------------------------------------------------------------------------------------------
    * @Description Method that returns the arce__Account_has_Analysis__c you want to update
    * ----------------------------------------------------------------------------------------------------
    * @Author   antonio.munoz.perez.contractor@bbva.com
    * @Date     2020-12-16
    * @param ahaLst - List<Arc_Gen_Account_Has_Analysis_Wrapper> all aha of the analysis
    * @param idRecord - current aha.ID
    * @example getMatrix (ahaLst, idRecord)
    * ----------------------------------------------------------------------------------------------------
    **/
    public arce__Account_has_Analysis__c getMatrix (List<arce.Arc_Gen_Account_Has_Analysis_Wrapper> ahaLst, ID idRecord) {
        arce__Account_has_Analysis__c matrix = new arce__Account_has_Analysis__c();
        for (arce.Arc_Gen_Account_Has_Analysis_Wrapper aha : ahaLst) {
            if (aha.ahaObj.arce__main_subsidiary_ind_type__c
                && aha.ahaObj.Id == idRecord
                && aha.ahaObj.arce__InReview__c == false
                && aha.ahaObj.arce__anlys_wkfl_cnsld_ffss_type__c == '2') {
                    matrix = aha.ahaObj;
                }
        }
        return matrix;
    }
    /**
    * ----------------------------------------------------------------------------------------------------
    * @Description Method that returns the arce__Account_has_Analysis__c which qualitative questions you want to copy
    * ----------------------------------------------------------------------------------------------------
    * @Author   antonio.munoz.perez.contractor@bbva.com
    * @Date     2020-12-16
    * @param ahaLst - List<arce.Arc_Gen_Account_Has_Analysis_Wrapper> all aha of the analysis
    * @param idRecord - current aha.ID
    * @example getHeader (ahaLst, idRecord)
    * ----------------------------------------------------------------------------------------------------
    **/
    public arce__Account_has_Analysis__c getHeader (List<arce.Arc_Gen_Account_Has_Analysis_Wrapper> ahaLst, ID idRecord) {
        arce__Account_has_Analysis__c header = new arce__Account_has_Analysis__c();
        for (arce.Arc_Gen_Account_Has_Analysis_Wrapper aha : ahaLst) {
            if (aha.ahaObj.arce__group_asset_header_type__c == '1') {
                header = aha.ahaObj;
            }
        }
        return header;
    }
    /**
    * ----------------------------------------------------------------------------------------------------
    * @Description Method to validate the analysis data to copy.
    * ----------------------------------------------------------------------------------------------------
    * @Author   antonio.munoz.perez.contractor@bbva.com
    * @Date     2020-12-16
    * @param matrix - Account has analysis object
    * @param header - Account has analysis object
    * @example doCopy(matrix, header)
    * ----------------------------------------------------------------------------------------------------
    **/
    public Boolean doCopy (arce__Account_has_Analysis__c matrix, arce__Account_has_Analysis__c header) {
        Boolean response = false;
        final List<arce__Account_has_Analysis__c> rtData = arce.Arc_Gen_AccHasAnalysis_Data.getRatingStatus(new List<ID>{header.ID});
        if (matrix != null
            && rtData[0] != null
            && (rtData[0].arce__ffss_for_rating_id__r.arce__rating_id__r.arce__status_type__c == '2'
                || rtData[0].arce__ffss_for_rating_id__r.arce__rating_id__r.arce__status_type__c == '3')) {
                    response = true;
                }
        return response;
    }
    /**
    * ----------------------------------------------------------------------------------------------------
    * @Description Method to update de matrix qualitative questions with the values of the header
    * ----------------------------------------------------------------------------------------------------
    * @Author   antonio.munoz.perez.contractor@bbva.com
    * @Date     2020-12-16
    * @param matrix - Account has analysis object
    * @param header - Account has analysis object
    * @example updateRating(matrix, header)
    * ----------------------------------------------------------------------------------------------------
    **/
    public static arce.Arc_Gen_ServiceAndSaveResponse updateRating(arce__Account_has_Analysis__c matrix, arce__Account_has_Analysis__c header) {
        final arce.Arc_Gen_ServiceAndSaveResponse servSaveResp = new arce.Arc_Gen_ServiceAndSaveResponse();
        servSaveResp.updatefields = new Map<String,Object>();
        final Set <String> qualQues = new Set <String> ();

        final List<String> templateNames = getTemplateNames(header.id);

        for (dyfr__Field_Config__c fCng :[select dyfr__Map_field__c from dyfr__Field_Config__c where Arc_Gen_QualitativeQuestions__c = true and dyfr__Tab__r.dyfr__Template__r.name in :templateNames]) {
          if (!String.isBlank(fCng.dyfr__Map_field__c) && !fCng.dyfr__Map_field__c.contains('__r.')) {
              qualQues.add(fCng.dyfr__Map_field__c);
          }
        }

        if (!qualQues.isEmpty()) {
          final Map<ID, sObject> groupRTData = new Map<ID, sObject>(new List<arce__Account_has_Analysis__c> {arce.Arc_Gen_AccHasAnalysis_Data.getAccHasAnalysisFields(header.Id, new List<String>(qualQues))});
          for (String qualQ : qualQues) {
            if (groupRTData.get(header.ID).get(qualQ) == null) {
                servSaveResp.updatefields.clear();
                arce.Arc_Gen_GenericUtilities.throwAuraExcept(System.Label.Arc_Gen_TD_add_Matrix_error);
                break;
            } else {
                servSaveResp.updatefields.put(qualQ, groupRTData.get(header.ID).get(qualQ));
            }
          }
      }
      return servSaveResp;
    }

    /**
    * ----------------------------------------------------------------------------------------------------
    * @Description Get the template names given an ahaId
    * ----------------------------------------------------------------------------------------------------
    * @Author   francisco.munoz.torres.contractor@bbva.com
    * @Date     2022-03-29
    * @param ahaId - Account has analysis id
    * @example getTemplateNames(aha)
    * ----------------------------------------------------------------------------------------------------
    **/
    private static List<String> getTemplateNames(String ahaId) {
      final List<String> templateNames = new List<String>();
      final arce__Account_has_Analysis__c aha = arce.Arc_Gen_AccHasAnalysis_Data.getAccHasAnalysis(new List<Id>{ahaId})[0];
      final String analysisType = aha.arce__Analysis__r.arce__anlys_wkfl_sub_process_type__c;
      final arce__Sector__c sector = Arc_Gen_Sector_Data.getSectorAccHasAn(aha, analysisType);

      for( Arc_Gen_Sector_Data.SectorWrapper s : Arc_Gen_Sector_Data.getSectionsFromSector(sector)) {
        templateNames.add(s.templateDevName);
      }

      return templateNames;
    }
}