/**
* @File Name          : Arc_Gen_RatingStudiesTabSet_controller.cls
* @Description        : Business logic of the rating studies dynamic form component
* @Author             : eduardoefrain.hernandez.contractor@bbva.com
* @Group              : ARCE Team
* @Last Modified By   : juanignacio.hita.contractor@bbva.com
* @Last Modified On   : 27/07/2020 13:00:00
* @Changes   :
* Ver       Date            Author      		    Modification
* -----------------------------------------------------------------------------------------------
* 1.0    17/10/2019   eduardoefrain.hernandez.contractor@bbva.com     Initial Version
* 1.1    27/07/2020   juanignacio.hita.contractor@bbva.com            Add methods for build dynamic table
* 1.1    23/09/2020   saimassimilianno.jordana.contractor@bbva.com    Added arce. namespace to all classes that are now in the arce-dependencies package
* 1.2    21/10/2020   joseluis.garcia4.contractor@bbva.com            Change field "Auditor opinion" to "Auditor qualification"
* 1.3    03/03/2022   francisco.munoz.torres.contractor@bbva.com      Shows only the previous sanctioned ratings
* 1.4    25/03/2022   francisco.munoz.torres.contractor@bbva.com      Manage discarded AHA in getInitData
* 1.5    07/06/2022   francisco.munoz.torres.contractor@bbva.com      In rating studies, hide sanction and discarded analysis
**/
public class Arc_Gen_RatingStudiesTabSet_service {
    /**
    * @description: Instance of the data access class
    **/
    private static Arc_Gen_Balance_Tables_data dataAccess = new Arc_Gen_Balance_Tables_data();
    /**
    * @description: Vale short rating scale type
    **/
    static final String SHORT_SCALE = '1';
    /**
    * @description: Template for short rating scale
    **/
    static final String SHORT_TEMPLATE = 'r-01-100';
    /**
    * @description: Template for long rating scale
    **/
    static final String LONG_TEMPLATE = 'r-02-100';
    /**
    * @description: Rating type code id map field
    **/
    static final String MODELRATING = 'RatingStudies';
    /**
    * @description: Empty constructor
    **/
    @TestVisible
    private Arc_Gen_RatingStudiesTabSet_service() {

    }
    /**
    *-------------------------------------------------------------------------------
    * @description Method that calls the business logic in the service class
    --------------------------------------------------------------------------------
    * @author eduardoefrain.hernandez.contractor@bbva.com
    * @date 17/10/2019
    * @param String ffssId - Standard Id of the selected Financial statement
    * @return List<String> - list of paramaters (rating id and template name)
    * @example List<String> strParams = getAnalyzedClientId(ffssId);
    **/
    public static List<String> getAnalyzedClientId(String ffssId) {
        final List<arce__Financial_Statements__c> ffssList = dataAccess.getFinancialStatements(new List<String>{ffssId});
        final List<arce__Account_has_Analysis__c> analyzedClient = arce.Arc_Gen_AccHasAnalysis_Data.getAccHasAnalysis(new List<String>{ffssList.get(0).arce__account_has_analysis_id__c});
        final String ratingId = ffssList.get(0).arce__rating_id__c;
        final String template = analyzedClient.get(0).arce__rating_scale_type__c == SHORT_SCALE ? SHORT_TEMPLATE : LONG_TEMPLATE;
        return new List<String>{ratingId, template};
    }
    /**
    *-------------------------------------------------------------------------------
    * @description Method that get the financial statement rating valid from aha id
    --------------------------------------------------------------------------------
    * @author juanignacio.hita.contractor@bbva.com
    * @date   31/07/2020
    * @param  String recordId - Standard id of account has analysis
    * @return Returns a list of strings with the param ffssRatingId and template to initialize the component
    * @example List<String> lstStr = getInitData(recordId);
    **/
    public static List<String> getInitData(String recordId) {
      final List<arce__Account_has_Analysis__c> lstAccHasAnlsys = arce.Arc_Gen_AccHasAnalysis_Data.getAccHasAnalysis(new List<String> {recordId});
      final List<Id> lstIDs = new List<Id>();
      List<String> listRatingId = new List<String>();
      final arce__Account_has_Analysis__c currentAha = lstAccHasAnlsys.get(0);
      for (arce__Account_has_Analysis__c aha : arce.Arc_Gen_AccHasAnalysis_Data.getAccForResume(new Set<Id> {currentAha.arce__Customer__c})) {
          lstIDs.add(aha.Id);
      }

      final List<arce__Account_has_Analysis__c> ahaList = arce.Arc_Gen_AccHasAnalysis_Data.getAccHasAnalysis(lstIDs);
      if(currentAha.arce__Analysis__r.arce__anlys_wkfl_discard_reason_id__c == null) {
        listRatingId = getInitDataARCENotDiscarded(ahaList, currentAha);
      } else {
        listRatingId = getInitDataARCEDiscarded(ahaList, currentAha);
      }
      return listRatingId;
    }

    /**
    *-------------------------------------------------------------------------------
    * @description Method that get the financial statement rating valid from aha id when ARCE is discarded
    --------------------------------------------------------------------------------
    * @author francisco.munoz.torres.contractor@bbva.com
    * @date   28/03/2022
    * @param  List<arce__Account_has_Analysis__c> ahaList - List of aha Id's
    * @param arce__Account_has_Analysis__c currentAha - Current aha
    * @return Returns a list of strings with the param ffssRatingId and template to initialize the component
    * @example List<String> lstStr = getInitDataARCEDiscarded(ahaList);
    **/
    private static List<String> getInitDataARCEDiscarded(List<arce__Account_has_Analysis__c> ahaList, arce__Account_has_Analysis__c currentAha) {
      final List<String> lstRatingId = new List<String>();
      // Shows only non discarded aha and number less or equal than the current
      for (arce__Account_has_Analysis__c aha : ahaList) {
        if(aha.arce__Analysis__r.arce__anlys_wkfl_discard_reason_id__c == null && aha.name <= currentAha.name) {
          lstRatingId.add(aha.arce__ffss_for_rating_id__c);
        }
      }
      return lstRatingId;
    }

    /**
    *-------------------------------------------------------------------------------
    * @description Method that get the financial statement rating valid from aha id when ARCE is not discarded
    --------------------------------------------------------------------------------
    * @author francisco.munoz.torres.contractor@bbva.com
    * @date   28/03/2022
    * @param  List<arce__Account_has_Analysis__c> ahaList - List of aha Id's
    * @param arce__Account_has_Analysis__c currentAha - Current aha
    * @return Returns a list of strings with the param ffssRatingId and template to initialize the component
    * @example List<String> lstStr = getInitDataARCENotDiscarded(ahaList, currentAha);
    **/
    private static List<String> getInitDataARCENotDiscarded(List<arce__Account_has_Analysis__c> ahaList, arce__Account_has_Analysis__c currentAha) {
      final List<String> arceIds = new List<String>();
      for(arce__Account_has_Analysis__c aha: ahaList) {
        arceids.add(aha.arce__Analysis__c);
      }
      final Map<String, arce__analysis__c> arceData = new Map<String, arce__analysis__c>(arce.Arc_Gen_ArceAnalysis_Data.getArceAnalysisData(arceIds));

      final List<String> lstRatingId = new List<String>();
      for (arce__Account_has_Analysis__c aha : ahaList) {
        final arce__analysis__c analysis = arceData.get(aha.arce__analysis__c);

        // If is sanctioned and the reason is Discard, hide
        if(aha.arce__Analysis__r.arce__analysis_risk_sanction_date__c != null && analysis.arce__anlys_wkfl_sanction_rslt_type__c == '3') {
          continue;
        }

        // If the discard reason is filled, hide
        if(aha.arce__Analysis__r.arce__anlys_wkfl_discard_reason_id__c != null) {
          continue;
        }

        // If the aha have a sanction date, shows aha with sanction date less or equal than the current sanction date
        //    and name less or equal than the current name (Cover aha sanctioned on the same day)
        if(currentAha.arce__Analysis__r.arce__analysis_risk_sanction_date__c == null ||
          (aha.arce__Analysis__r.arce__analysis_risk_sanction_date__c <= currentAha.arce__Analysis__r.arce__analysis_risk_sanction_date__c &&
          aha.name <= currentAha.name)) {
          lstRatingId.add(aha.arce__ffss_for_rating_id__c);
        }
      }
      return lstRatingId;
    }

    /**
    *-------------------------------------------------------------------------------
    * @description Method that creates a DwpTable wrapper for build the table with the financial statement valid for call rating engine.
    --------------------------------------------------------------------------------
    * @author juanignacio.hita.contractor@bbva.com
    * @date   27/07/2020
    * @param  List<arce__Financial_Statements__c> lstEeffValid - list of valid financial statements
    * @return returns a Dwp TableWrapper object with valid financial statement data and headers
    * @example Arc_Gen_DwpTableWrapper wrapper = getJsonTable(lstEEFF);
    **/
    public static Arc_Gen_DwpTableWrapper getJsonTable(List<arce__Financial_Statements__c> lstEeffValid) {
        // Generate table Json.
        final Map<String, Object> mapHeader = new Map<String, Object> {
            'selection' => '',
            'endDate' => System.Label.Arc_Gen_RatingStudies_EndDate,
            'periodNumber' => System.Label.Arc_Gen_RatingStudies_PeriodNumber,
            'ratingStatus' => System.Label.Arc_Gen_RatingStudies_RatingStatus,
            'certification' => System.Label.Arc_Gen_RatingStudies_Certification,
            'auditOpinion' => System.Label.Arc_Gen_RatingStudies_AuditQualification,
            'adjustType' => System.Label.Arc_Gen_RatingStudies_AdjustedType,
            'submitType' => System.Label.Arc_Gen_RatingStudies_SubmitType,
            'ratingFinal' => System.Label.Arc_Gen_RatingStudies_ShortRating,
            'ratingLongValue' => System.Label.Arc_Gen_RatingStudies_LongRating,
            'ratingTypeCodeId' => System.Label.Arc_Gen_RatingStudies_RatingModel,
            'ratingUserId' => System.Label.Arc_Gen_RatingStudies_UserId
        };
        final Arc_Gen_DwpTableWrapper tableWrapper = new Arc_Gen_DwpTableWrapper();
        tableWrapper.table = new Arc_Gen_DwpTableWrapper.Dynamic_Table_Wrapper();
        tableWrapper.table.lstHeaders = Arc_Gen_DwpTableWrapper_Controller.getHeadersTable(mapHeader);
        tableWrapper.table.lstRows = createRowTable(lstEeffValid);
        return tableWrapper;
    }
    /**
    *-------------------------------------------------------------------------------
    * @description Method that fills the table rows with data of financial statements
    --------------------------------------------------------------------------------
    * @author juanignacio.hita.contractor@bbva.com
    * @date   27/07/2020
    * @param  List<arce__Financial_Statements__c> lstEeffValid - list of valid financial statements
    * @return List<Arc_Gen_DwpTableWrapper.Row_Wrapper> - Returns a list of row wrapper
    * @example List<Arc_Gen_DwpTableWrapper.Row_Wrapper> lstRows = createRowTable(lstEeffValid);
    **/
    private static List<Arc_Gen_DwpTableWrapper.Row_Wrapper> createRowTable(List<arce__Financial_Statements__c> lstEeffValid) {
        final List<Arc_Gen_DwpTableWrapper.Row_Wrapper> rowsList = new List<Arc_Gen_DwpTableWrapper.Row_Wrapper>();
        final Map<String, String> mapRatingModel = Arc_Gen_FieldConfig_Data.getDependValByQualitativeCode(MODELRATING);

        for (arce__Financial_Statements__c ffss : lstEeffValid) {
            final Map<String, Object> mapRows = new Map<String, Object> {
                'endDate' => ffss.arce__financial_statement_end_date__c,
                'economicMonth' => ffss.arce__economic_month_info_number__c,
                'status' => ffss.arce__rating_status__c,
                'certificationType' => ffss.arce__ffss_certification_type__c,
                'auditOpinion' => arce.Arc_Gen_GenericUtilities.getLabelFromValue('arce__Financial_Statements__c', 'arce__ffss_auditor_qlfn_type__c', ffss.arce__ffss_auditor_qlfn_type__c),
                'adjustType' => arce.Arc_Gen_GenericUtilities.getLabelFromValue('arce__Financial_Statements__c', 'arce__ffss_adjusted_type__c', ffss.arce__ffss_adjusted_type__c),
                'submitType' => arce.Arc_Gen_GenericUtilities.getLabelFromValue('arce__Financial_Statements__c', 'arce__ffss_submitted_type__c', ffss.arce__ffss_submitted_type__c),
                'ratingFinal' => ffss.arce__rating_final__c,
                'ratingLongValue' => ffss.arce__rating_long_value_type__c,
                'ratingTypeCodeId' => getRatingModel(mapRatingModel, ffss.arce__rating_type_code_id__c),
                'ratingUserId' => ffss.arce__rating_user_id__c
            };
            rowsList.add(Arc_Gen_DwpTableWrapper_Controller.fillRow(ffss.Id, mapRows, true));
        }
        return rowsList;
    }
    /**
    *-------------------------------------------------------------------------------
    * @description Method that get of the map rating model catalog the label of the ratingTypeCodeId.
    * If not exist returns the rating type code id value
    --------------------------------------------------------------------------------
    * @author juanignacio.hita.contractor@bbva.com
    * @date   27/07/2020
    * @param  Map<String, String> mapRatingModel - map with the value and label of model rating
    * @param  String ratingTypeCodeId            - rating type code id
    * @return Returns the label of the rating type code id
    * @example Arc_Gen_DwpTableWrapper.Row_Wrapper row = getRatingModel(mapRatingModel, ratingTypeCodeId);
    **/
    private static String getRatingModel(Map<String, String> mapRatingModel, String ratingTypeCodeId) {
        String labelModel = '';
        if (!mapRatingModel.isEmpty()) {
            labelModel = mapRatingModel.get(ratingTypeCodeId);
        }
        return labelModel == '' || labelModel == null ? ratingTypeCodeId : labelModel;
    }
}