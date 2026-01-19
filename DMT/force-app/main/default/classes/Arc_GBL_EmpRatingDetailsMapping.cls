/**
* ------------------------------------------------------------------------------------------------
* @Name     Arc_GBL_RatingDetailsMapping
* @Author   jose.hijar.contractor@bbva.com
* @Date     Created: 2020-03-11
* @Group    ARCE
* ------------------------------------------------------------------------------------------------
* @Description: Global class for customization of geography field mapping of arce__rating_variables_detail__c objects created on rating response
* ------------------------------------------------------------------------------------------------
* @Changes
*
* |2020-10-28 jose.hijar.contractor@bbva.com
*               class creation
* |2020-11-25 jose.hijar.contractor@bbva.com
*               method setRatingVariable copied from arce core adapted to SP business logic
*               method setRatingModifier copied from arce core adapted to SP business logic
*               refactorization of setRatingModifier. Methods setValuesFromModifiers and setValuesFromAdjustments
* |2021-04-07 joseluis.garcia4.contractor@bbva.com
*               Adapt class for enterprises.
* |2021-05-26 amunguia.contractor@bbva.com the mapping is based on the type of field.
* ------------------------------------------------------------------------------------------------
*/
@SuppressWarnings('sf:TooManyMethods')
global class Arc_GBL_EmpRatingDetailsMapping implements arce.Arc_GBL_RatingDetailsMapping_Interface {
    /**
    * @Description: Instance of the data access class
    */
    private final Map<String,arce__overlay_custom_mapping__mdt> modifierOverlayMapping;

    /**
    *-------------------------------------------------------------------------------
    * @description Constructor
    --------------------------------------------------------------------------------
    * @author jose.hijar.contractor@bbva.com
    * @date 4/03/2021
    * @return an instance of Arc_GBL_RatingDetailsMapping
    * @example Arc_GBL_RatingDetailsMapping
    **/
    global Arc_GBL_EmpRatingDetailsMapping() {
      this.modifierOverlayMapping = arce.Arc_Gen_RatingGlobal_data.getModifierOverlayMapping();
    }

    /**
    *-------------------------------------------------------------------------------
    * @description Method that sets a rating variable with the obtained data
    --------------------------------------------------------------------------------
    * @author eduardoefrain.hernandez.contractor@bbva.com
    * @date 30/4/2019
    * @param Map<String, Object> ratingAdjustmentsMap adjustments for rating
    * @param String aHaId id for the current account has analisis
    * @param arce__rating__c rating current rating in process
    * @return arce__rating_variables_detail__c an instance for the  auxiliary rating variables
    * @example global static arce__rating_variables_detail__c setRatingVariable(Map<String, Object> ratingAdjustmentsMap,String aHaId,arce__rating__c rating)
    **/
    global arce__rating_variables_detail__c setRatingVariable(Map<String, Object> ratingVariablesMap,String aHaId,arce__rating__c rating) {
      final arce__rating_variables_detail__c rvdVariable = new arce__rating_variables_detail__c();
      final Object variablesScore = (Object)ratingVariablesMap.get(arce.Arc_Gen_RatingGlobal_Constants.SCORE);
      final Map<String, Object> variablesScoreMap = (Map<String, Object>)variablesScore;
      rvdVariable.arce__rating_id__c = rating.Id;
      rvdVariable.arce__account_has_analysis_id__c = aHaId;
      rvdVariable.arce__rating_variable_level_id__c = arce.Arc_Gen_RatingGlobal_helper.supressStringNull((String)ratingVariablesMap.get(arce.Arc_Gen_RatingGlobal_Constants.LEVEL));
      rvdVariable.arce__rating_variable_data_type__c = (String)ratingVariablesMap.get(arce.Arc_Gen_RatingGlobal_Constants.VARIABLE_TYPE);
      rvdVariable.arce__rating_variable_large_id__c = (String)ratingVariablesMap.get(arce.Arc_Gen_RatingGlobal_Constants.ID_TEXT);
      rvdVariable.arce__rating_variable_id__c = Integer.valueOf(arce.Arc_Gen_RatingGlobal_helper.supressDecimalNull((String)ratingVariablesMap.get(arce.Arc_Gen_RatingGlobal_Constants.CODE_TEXT)));
      rvdVariable.arce__rating_var_parent_level_id__c = arce.Arc_Gen_RatingGlobal_helper.supressStringNull((String)ratingVariablesMap.get(arce.Arc_Gen_RatingGlobal_Constants.PARENT_LEVEL));
      rvdVariable.arce__parent_code_number__c = arce.Arc_Gen_RatingGlobal_helper.supressStringNull((String)ratingVariablesMap.get(arce.Arc_Gen_RatingGlobal_Constants.PARENT_CODE));
      rvdVariable.arce__rating_variable_name__c = arce.Arc_Gen_RatingGlobal_helper.supressStringNull((String)ratingVariablesMap.get(arce.Arc_Gen_RatingGlobal_Constants.BLOCK_TYPE));
      rvdVariable.arce__rating_var_adj_value_amount__c = arce.Arc_Gen_RatingGlobal_helper.supressDecimalNull((String)ratingVariablesMap.get(arce.Arc_Gen_RatingGlobal_Constants.ADJUSTED_VALUE));
      if (rvdVariable.arce__parent_code_number__c == arce.Arc_Gen_RatingGlobal_Constants.QUALITATIVE_VAR_CODE) {
        // If qualitative and value is null, keep value as null.
        rvdVariable.arce__rating_var_value_amount__c = ratingVariablesMap.get(arce.Arc_Gen_RatingGlobal_Constants.VALUE_TEXT) == null ? null : arce.Arc_Gen_RatingGlobal_helper.supressDecimalNull((String)ratingVariablesMap.get(arce.Arc_Gen_RatingGlobal_Constants.VALUE_TEXT));
        rvdVariable.arce__rating_var_score_number__c = rvdVariable.arce__rating_variable_level_id__c == '1' ? Decimal.valueOf((String)variablesScoreMap.get(arce.Arc_Gen_RatingGlobal_Constants.VALUE_TEXT)) : null;
      } else {
        rvdVariable.arce__rating_var_value_amount__c = arce.Arc_Gen_RatingGlobal_helper.supressDecimalNull((String)ratingVariablesMap.get(arce.Arc_Gen_RatingGlobal_Constants.VALUE_TEXT));
        rvdVariable.arce__rating_var_score_number__c = Decimal.valueOf((String)variablesScoreMap.get(arce.Arc_Gen_RatingGlobal_Constants.VALUE_TEXT));
        rvdVariable.arce__rating_var_adj_score_number__c = (Decimal)variablesScoreMap.get(arce.Arc_Gen_RatingGlobal_Constants.ADJUSTED_SCORE);
        rvdVariable.arce__rating_var_max_score_number__c = arce.Arc_Gen_RatingGlobal_helper.supressDecimalNull(String.valueOf((Decimal)variablesScoreMap.get(arce.Arc_Gen_RatingGlobal_Constants.MAXIMUM_SCORE)));
        rvdVariable.arce__rating_var_min_score_number__c = arce.Arc_Gen_RatingGlobal_helper.supressDecimalNull(String.valueOf((Decimal)variablesScoreMap.get(arce.Arc_Gen_RatingGlobal_Constants.MINIMUM_SCORE)));
      }
      return rvdVariable;
    }

    /**
    *-------------------------------------------------------------------------------
    * @description Method that sets a rating modifier with the obtained data
    --------------------------------------------------------------------------------
    * @author eduardoefrain.hernandez.contractor@bbva.com
    * @date 30/4/2019
    * @param Map<String, Object> ratingAdjustmentsMap map for adjustments for rating
    * @param String aHaId current analisis for rating
    * @param arce__rating__c rating current rating for analisis
    * @return arce__rating_variables_detail__cm an instance for the  auxiliary variables for rating
    * @example setRatingModifier(Map<String, Object> ratingAdjustmentsMap,String aHaId,arce__rating__c rating)
    **/
    global arce__rating_variables_detail__c setRatingModifier(Map<String, Object> ratingAdjustmentsMap,String aHaId,arce__rating__c rating) {
      final arce__rating_variables_detail__c rvdAdjustment = new arce__rating_variables_detail__c();
      final Map<String, Object> modifierMap = (Map<String, Object>)ratingAdjustmentsMap.get(arce.Arc_Gen_RatingGlobal_Constants.MODIFIER);
      final String adjShortRating = (String)ratingAdjustmentsMap.get(arce.Arc_Gen_RatingGlobal_Constants.SHORT_VALUE);
      final String adjLongRating = (String)ratingAdjustmentsMap.get(arce.Arc_Gen_RatingGlobal_Constants.LONG_VALUE);
      final String adjustmentType = setValuesFromAdjustments(ratingAdjustmentsMap, rvdAdjustment);

      setValuesFromModifiers(modifierMap, rvdAdjustment, adjustmentType);
      rvdAdjustment.arce__rating_Id__c = rating.Id;
      rvdAdjustment.arce__account_has_analysis_id__c = aHaId;
      rvdAdjustment.arce__adj_long_rating_value_type__c = adjLongRating == arce.Arc_Gen_RatingGlobal_Constants.NOT_APPLY ? NULL : adjLongRating;
      rvdAdjustment.arce__adj_short_rating_value_type__c = adjShortRating == arce.Arc_Gen_RatingGlobal_Constants.NOT_APPLY ? NULL : adjShortRating;

      return rvdAdjustment;
    }

    /**
    *-------------------------------------------------------------------------------
    * @description Method that sets fields of rating_variable_detail object from obtained data.
    --------------------------------------------------------------------------------
    * @author jose.hijar.contractor@bbva.com
    * @date 19/11/2020
    * @param Map<String, Object> modifierMap
    * @param arce__rating_variables_detail__c variable
    * @return void
    * @example setValuesFromModifiers(Map<String, Object> modifierMap, arce__rating_variables_detail__c variable)
    **/
    private void setValuesFromModifiers(Map<String, Object> modifierMap, arce__rating_variables_detail__c rvdAdj, String adjustmentType) {
      rvdAdj.arce__rating_override_reason_desc__c = adjustmentType == arce.Arc_Gen_RatingGlobal_Constants.METHOD_OVERRIDE ? (String)modifierMap.get(arce.Arc_Gen_RatingGlobal_Constants.DESCRIPTION) : '';
      if (modifierMap != null) {
        rvdAdj.arce__rating_modifier_id__c = (String)modifierMap.get(arce.Arc_Gen_RatingGlobal_Constants.ID_TEXT);
        rvdAdj.arce__rating_modifier_desc__c = (String)modifierMap.get(arce.Arc_Gen_RatingGlobal_Constants.DESCRIPTION);
        rvdAdj.arce__rating_variable_name__c = (String)modifierMap.get(arce.Arc_Gen_RatingGlobal_Constants.DESCRIPTION);
        if (adjustmentType == arce.Arc_Gen_RatingGlobal_Constants.METHOD_OVERLAY) {
          rvdAdj.arce__overlay_type__c = (String)modifierMap.get(arce.Arc_Gen_RatingGlobal_Constants.ID_TEXT);
        } else if(adjustmentType == arce.Arc_Gen_RatingGlobal_Constants.MODIFIER) {
          rvdAdj.arce__modifier_valuation__c = (String)modifierMap.get(arce.Arc_Gen_RatingGlobal_Constants.VALUE_TEXT);
        }
      }
    }

    /**
    *-------------------------------------------------------------------------------
    * @description Method that sets fields of rating_variable_detail object from obtained data.
    --------------------------------------------------------------------------------
    * @author jose.hijar.contractor@bbva.com
    * @date 19/11/2020
    * @param Map<String, Object> ratingAdjustmentsMap
    * @param arce__rating_variables_detail__c variable
    * @return String
    * @example setValuesFromAdjustments(Map<String, Object> ratingAdjustmentsMap, arce__rating_variables_detail__c variable)
    **/
    private String setValuesFromAdjustments(Map<String, Object> ratingAdjustmentsMap, arce__rating_variables_detail__c rvdAdj) {
      //String adjustmentType = (String)((Map<String,Object>)ratingAdjustmentsMap.get(System.Label.Cls_arce_RatingRespAdjType)).get(System.Label.Cls_arce_RatingId);
      final String adjustmentType = (String)((Map<String,Object>)ratingAdjustmentsMap.get(arce.Arc_Gen_RatingGlobal_Constants.ADJUSTMENT_TYPE)).get(arce.Arc_Gen_RatingGlobal_Constants.ID_TEXT);
      final Decimal score = (Decimal)ratingAdjustmentsMap.get(arce.Arc_Gen_RatingGlobal_Constants.SCORE);
      rvdAdj.arce__rating_variable_level_id__c = (String)ratingAdjustmentsMap.get(arce.Arc_Gen_RatingGlobal_Constants.LEVEL);
      rvdAdj.arce__rating_var_score_number__c = score;
      rvdAdj.arce__adj_total_rating_score_number__c = score;
      rvdAdj.arce__PD_per__c = (Decimal)ratingAdjustmentsMap.get(arce.Arc_Gen_RatingGlobal_Constants.DEFAULT_PROBABILITY);
      //rvdAdj.arce__modifier_type__c = adjustmentType;
      rvdAdj.arce__rating_modifier_adj_type__c = adjustmentType;
      return adjustmentType;
    }

    /**
    *-------------------------------------------------------------------------------
    * @description Updates overlay object with data from service(ratingEngine) response
    --------------------------------------------------------------------------------
    * @author jose.hijar.contractor@bbva.com
    * @date 19/11/2020
    * @param Map<String, Object> ratingAdjustmentsMap
    * @param String modifierId
    * @param arce__Overlay__c overlay
    * @example updateOverlayObj(Map<String, Object> ratingAdjustmentsMap, String modifierId, arce__Overlay__c overlay)
    **/
    global void updateOverlayObj(Map<String, Object> ratingAdjustmentsMap, String modifierId, arce__Overlay__c overlay) {
      arce__overlay_custom_mapping__mdt overlayMappingConfig;
      final Map<String,Object> modifierMap = (Map<String, Object>)ratingAdjustmentsMap.get(arce.Arc_Gen_RatingGlobal_Constants.MODIFIER);

      String modifierValue;

      if(modifierOverlayMapping != null){ //populated on static block
        overlayMappingConfig = modifierOverlayMapping.get(modifierId);

        if(overlayMappingConfig!=null){
          modifierValue = (String)modifierMap.get(arce.Arc_Gen_RatingGlobal_Constants.VALUE_TEXT);
          String defProb = String.valueOf(ratingAdjustmentsMap.get(arce.Arc_Gen_RatingGlobal_Constants.DEFAULT_PROBABILITY));
          String longScale = (String)ratingAdjustmentsMap.get(arce.Arc_Gen_RatingGlobal_Constants.LONG_VALUE);
          String score = String.valueOf(ratingAdjustmentsMap.get(arce.Arc_Gen_RatingGlobal_Constants.SCORE_TEXT));
          String shortScale = (String)ratingAdjustmentsMap.get(arce.Arc_Gen_RatingGlobal_Constants.SHORT_VALUE);
          //cabría la posibilidad de que hubiera que comprobar mediante el schema qué tipo de campo es al que se le va a asignar para castearlo a un tipo de dato adecuado
          assignFieldValue(overlay, overlayMappingConfig.arce__defProb_fieldMap__c, defProb);
          assignFieldValue(overlay, overlayMappingConfig.arce__longScale_fieldMap__c, longScale);
          assignFieldValue(overlay, overlayMappingConfig.arce__score_fieldMap__c, score);
          assignFieldValue(overlay, overlayMappingConfig.arce__shortScale_fieldMap__c, shortScale);
          assignFieldValue(overlay, overlayMappingConfig.arce__modifierValue_fieldMap__c, modifierValue);
        }
      }
    }

    /**
    *-------------------------------------------------------------------------------
    * @description assigns overlay fields value dinamically
    --------------------------------------------------------------------------------
    * @author jose.hijar.contractor@bbva.com
    * @date 19/11/2020
    * @param arce__Overlay__c overlay
    * @param String mappingField
    * @param String fValue
    * @example assignFieldValue(arce__Overlay__c overlay, String mappingField, String fValue)
    **/
    private void assignFieldValue(arce__Overlay__c overlay, String mappingField, String fValue){
      if(!String.isBlank(mappingField)) {
        final Schema.sObjectType objectDef = Schema.getGlobalDescribe().get('arce__Overlay__c').getDescribe().getSObjectType();
        final Map<String, Schema.SobjectField> objectFieldsMap = objectDef.getDescribe().fields.getMap();
        final String fieldType = objectFieldsMap.get(mappingField).getDescribe().getType().name();
        if(TYPE.BOOLEAN_X.name().contains(fieldType)) {
            overlay.put(mappingField, Boolean.valueOf(fValue));
        } else if(TYPE.DATETIME_X.name().contains(fieldType)) {
            overlay.put(mappingField, Date.valueOf(fValue));
        } else if(TYPE.DOUBLE_X.name().contains(fieldType) || TYPE.CURRENCY_X.name().contains(fieldType)) {
            overlay.put(mappingField, Double.valueOf(fValue));
        } else {
            overlay.put(mappingField, fValue);
        }
    }
    }

    /**
    *-------------------------------------------------------------------------------
    * @description Sets rating fields value depending on the type of rating being processed
    --------------------------------------------------------------------------------
    *  @author aleksandar.dinkov.contractor@bbva.com
    * @param Map<String, Object> ratingMap
    * @param String ratingType
    * @param arce__Account_has_Analysis__c accHasAnalysis
    * @param arce__rating__c rating
    * @param String projectionId
    * @example setRating(Map<String, Object> ratingMap, String ratingType, arce__Account_has_Analysis__c accHasAnalysis, arce__rating__c rating)
    **/
    global void setRating(Map<String, Object> ratingMap, String ratingType, arce__Account_has_Analysis__c accHasAnalysis, arce__rating__c rating) {
      setRating(ratingMap, ratingType, accHasAnalysis, rating, null);
    }

    /**
    *-------------------------------------------------------------------------------
    * @description Sets rating fields value depending on the type of rating being processed
    --------------------------------------------------------------------------------
    * @author jose.hijar.contractor@bbva.com
    * @date 19/11/2020
    * @param Map<String, Object> ratingMap
    * @param String ratingType
    * @param arce__Account_has_Analysis__c accHasAnalysis
    * @param arce__rating__c rating
    * @example setRating(Map<String, Object> ratingMap, String ratingType, arce__Account_has_Analysis__c accHasAnalysis,
    * arce__rating__c rating, String projectionId)
    **/
    @SuppressWarnings('PMD.ExcessiveParameterList')
    global void setRating(Map<String, Object> ratingMap, String ratingType, arce__Account_has_Analysis__c accHasAnalysis, arce__rating__c rating, String projectionId) {
      if (ratingType == arce.Arc_Gen_RatingGlobal_Constants.STANDALONE_RATING) {
        rating.arce__short_rating_value_type__c = (String)ratingMap.get(arce.Arc_Gen_RatingGlobal_Constants.SHORT_VALUE);
        rating.arce__long_rating_value_type__c = (String)ratingMap.get(arce.Arc_Gen_RatingGlobal_Constants.LONG_VALUE);
        accHasAnalysis.arce__long_rating_value_type__c = (String)ratingMap.get(arce.Arc_Gen_RatingGlobal_Constants.LONG_VALUE);
        accHasAnalysis.arce__short_rating_value_type__c = (String)ratingMap.get(arce.Arc_Gen_RatingGlobal_Constants.SHORT_VALUE);
        accHasAnalysis.arce__total_rating_score_number__c = Decimal.valueOf(String.valueOf(ratingMap.get(arce.Arc_Gen_RatingGlobal_Constants.SCORE)));
        accHasAnalysis.arce__recalculate_rating__c = String.valueOf(4);
      } else if(ratingType == arce.Arc_Gen_RatingGlobal_Constants.FINAL_RATING) {
        rating.arce__total_rating_score_number__c = Decimal.valueOf(String.valueOf(ratingMap.get(arce.Arc_Gen_RatingGlobal_Constants.SCORE_TEXT)));
        rating.arce__rating_short_value_type__c = (String)ratingMap.get(arce.Arc_Gen_RatingGlobal_Constants.SHORT_VALUE);
        rating.arce__rating_long_value_type__c = (String)ratingMap.get(arce.Arc_Gen_RatingGlobal_Constants.LONG_VALUE);
        rating.arce__pd_per__c = (Decimal)ratingMap.get(arce.Arc_Gen_RatingGlobal_Constants.DEFAULT_PROBABILITY);
        // Extract rating model id and type.
        final Map<String, Object> toolMap = (Map<String, Object>) ratingMap.get(arce.Arc_Gen_RatingGlobal_Constants.TOOL_TEXT);
        if (toolMap != null && toolMap.containsKey(arce.Arc_Gen_RatingGlobal_Constants.ID_TEXT)) {
          final String ratingModelId = String.valueOf(toolMap.get(arce.Arc_Gen_RatingGlobal_Constants.ID_TEXT));
          rating.arce__rar_rating_tool_id__c = ratingModelId;
          rating.arce__rating_type_code_id__c = ratingModelId.length() > 12 ? ratingModelId.substring(8, 12) : '';
        }
        accHasAnalysis.arce__long_rating_value_id__c = (String)ratingMap.get(arce.Arc_Gen_RatingGlobal_Constants.LONG_VALUE);
      } else if(ratingType == arce.Arc_Gen_RatingGlobal_Constants.ANCHOR_RATING) {
        rating.arce__anchor_short_scale__c = (String)ratingMap.get(arce.Arc_Gen_RatingGlobal_Constants.SHORT_VALUE);
        rating.arce__anchor_long_scale__c = (String)ratingMap.get(arce.Arc_Gen_RatingGlobal_Constants.LONG_VALUE);
        rating.arce__anchor_score__c = Decimal.valueOf(String.valueOf(ratingMap.get(arce.Arc_Gen_RatingGlobal_Constants.SCORE_TEXT)));
      } else if(ratingType == arce.Arc_Gen_RatingGlobal_Constants.METHOD_OVERLAY) {
        rating.arce__overlay_score_number__c = Decimal.valueOf(String.valueOf(ratingMap.get(arce.Arc_Gen_RatingGlobal_Constants.SCORE_TEXT)));
        rating.arce__overlay_short_value__c = (String)ratingMap.get(arce.Arc_Gen_RatingGlobal_Constants.SHORT_VALUE);
        rating.arce__overlay_long_value__c = (String)ratingMap.get(arce.Arc_Gen_RatingGlobal_Constants.LONG_VALUE);
        rating.arce__overlay_pd_per__c = (Decimal)ratingMap.get(arce.Arc_Gen_RatingGlobal_Constants.DEFAULT_PROBABILITY);
      } else if(ratingType == arce.Arc_Gen_RatingGlobal_Constants.PROJECTION_STANDALONE) {
        final arce__Projection__c projection = arce.Arc_Gen_RatingGlobal_data.getProjectionById(projectionId);
        projection.arce__Simulation_Long_Scale_Value__c = (String)ratingMap.get(arce.Arc_Gen_RatingGlobal_Constants.LONG_VALUE);
        projection.arce__Simulation_Short_Scale_Value__c = (String)ratingMap.get(arce.Arc_Gen_RatingGlobal_Constants.SHORT_VALUE);
        projection.arce__Simulation_Score__c = Decimal.valueOf(String.valueOf(ratingMap.get(arce.Arc_Gen_RatingGlobal_Constants.SCORE_TEXT)));
        projection.arce__Simulation_Calculated__c = true;
        arce.Arc_Gen_GenericUtilities.updateRecords(new List<arce__Projection__c>{projection});
      }
    }

    /**
    *-------------------------------------------------------------------------------
    * @description Processes and map every entry contained on combinedRating section of service(ratingEngine) response
    --------------------------------------------------------------------------------
    * @author jose.hijar.contractor@bbva.com
    * @date 19/11/2020
    * @param Map<String, Object> combinedRatingMap
    * @param String templateId
    * @param Decimal wheight
    * @param String analysisId
    * @param String ratingId
    * @example setRatingCombinedRating(Map<String, Object> combinedRatingMap, String templateId, Decimal wheight, String analysisId, String ratingId)
    **/
    @SuppressWarnings('PMD.ExcessiveParameterList')
    global arce__rating_variables_detail__c setRatingCombinedRating(Map<String, Object> combinedRatingMap, String templateId, Decimal wheight, String analysisId, String ratingId) {
      final arce__rating_variables_detail__c rvdCombinedRating = new arce__rating_variables_detail__c();

      rvdCombinedRating.arce__rating_id__c = ratingId;
      rvdCombinedRating.arce__account_has_analysis_id__c = analysisId;
      rvdCombinedRating.arce__adj_long_rating_value_type__c = (String)combinedRatingMap.get(arce.Arc_Gen_RatingGlobal_Constants.LARGE_VALUE);
      rvdCombinedRating.arce__rating_var_score_number__c = (Decimal)combinedRatingMap.get(arce.Arc_Gen_RatingGlobal_Constants.SCORE);
      rvdCombinedRating.arce__adj_short_rating_value_type__c = (String)combinedRatingMap.get(arce.Arc_Gen_RatingGlobal_Constants.SHORT_VALUE);
      rvdCombinedRating.arce__rating_modifier_adj_type__c = arce.Arc_Gen_RatingGlobal_Constants.ACTIVITY_TEMPLATE;

      return rvdCombinedRating;
    }
      /**
    * --------------------------------------------------------------------------------------
    * @description Returns a an AggregateResult containing the total weight per template for a given Account_has_analysis__c
    * @param parentId Account_has_analysis id to filter for
    * @param templates Set of activity templates id to get theirs weight
    * @return Returns all the activities related.
    **/
    global List<AggregateResult> getActivitiesWeightByTemplate(String parentId, Set<String> templates) {
      return new List<AggregateResult>();
    }

    /**
    * --------------------------------------------------------------------------------------
    * @description REturns the non-absolute sum of the weights of the activities
    * @param parentIdSet Account_has_analysis id to filter for
    * @return Returns an AggregateResult object containing the sum of all weights of activities
    **/
    global AggregateResult getRelativeWeightSum(String parentId) {
      return null;
    }
    /** @Description: ENUM TYPE */
    public enum TYPE {DATETIME_X, BOOLEAN_X, DOUBLE_X, CURRENCY_X}
}