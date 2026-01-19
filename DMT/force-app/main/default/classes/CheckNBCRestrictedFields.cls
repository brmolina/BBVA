/*
* Author: SunnyTrail
* Comprueba campos obligatorios
*/
public with sharing class CheckNBCRestrictedFields {   //NOSONAR

    /*
    *Author: SunnyTrail
    *con patron sigleton
    *
    */
    private CheckNBCRestrictedFields() {
    }

    /*
    * Checkea que tenga los campos obligatorios antes de ready for NBC
    */
    @InvocableMethod(label='Check Restricted Fields' description='Check Restricted Fields')
    public static List<String> checkRestrictedFields (List<String> lIDTempl) {   //NOSONAR
        final List<String> lReturn = new List<String>();
        List<String> missingFlieds = new List<String>();
        string newAllD;
        newAllD = 'new_all_in_drawn%num%_desc__c';
        string newAllU;
        newAllU = 'new_all_in_undrawn%num%_desc__c';
        string stanRORC;
        stanRORC = 'standalone_rorc%num%_number__c';
        string stanRAR;
        stanRAR = 'standalone_rar%num%_number__c';
        string newMoney;
        newMoney = 'new_money_for_bbva%num%_desc__c';
        string expFinal;
        expFinal = 'expected_final_take%num%_number__c';

        TemplateTableHandler.updateTemplate(lIDTempl.get(0), false);

        final Map<String, Schema.SObjectField> tempFieldMap = Schema.getGlobalDescribe().get('DES_Template__c').getDescribe().fields.getMap();

        final List<String> allTemplate = new List<String>{'Floor_Clause_type__c',/*'Sustainable_Deal_type__c',*/'Type_of_Deal_desc__c','bilateral_synd_type__c',
												'Industry_AA_type__c','Bankers_desc__c','Borrower_s_name_Fiscal_ID_desc__c'};


        final List<String> cslTemplate = new List<String>{'Guarantor_s_name_Fiscal_ID_desc__c','Int_Rating_type__c','Expected_RAR_Avg_life_per__c','Expected_RORC_Avg_life_per__c','Past_FY_RORC_per__c',
												'YTD_RORC_per__c','SPPI_Test_type__c','YTD_RORC_per_CDD__c','Tier_desc__c','Tiering_Action_type__c',
                'Past_FY_RORC_per_CDD__c', 'Standalone_CDD_RaR_number__c', 'Standalone_CDD_RORC_number__c','Sector_Head__c'};

        final List<String> facilityCSL = new List<String>{'Underwriting%num%_desc__c',expFinal,
												newMoney,stanRAR,stanRORC,
												newAllD,newAllU,
												'Tenor_Years%num%_number__c','Average_Life%num%_number__c'};


        final List<String> ecaTemplate = new List<String>{'Standalone_CDD_RaR_number__c', 'Standalone_CDD_RORC_number__c','Sector_Head__c','Tier_desc__c','Tiering_Action_type__c'};

        final List<String> facilityECA = new List<String>{'Underwriting%num%_desc__c',expFinal,
												newMoney,stanRAR,stanRORC,
												newAllD,newAllU,
												'Tenor_Years%num%_number__c','Average_Life%num%_number__c'};


        final List<String> gtbTemplate = new List<String>{'Guarantor_s_name_Fiscal_ID_desc__c','Int_Rating_type__c','Client_RORC_Avg_life_per__c','YTD_RORC_per_CDD__c',
        'Past_FY_RORC_per_CDD__c', 'Standalone_CDD_RaR_number__c', 'Standalone_CDD_RORC_number__c','Sector_Head__c','Tier_desc__c','Tiering_Action_type__c'};

        final List<String> facilityGTB = new List<String>{expFinal,
												newMoney,stanRAR,stanRORC,
												newAllD,newAllU,
												'Tenor_Years%num%_number__c'};


        final List<String> pfTemplate = new List<String>{'Guarantor_s_name_Fiscal_ID_desc__c','Int_Rating_pf__c','SPPI_Test_type__c','Calification_type__c','Standalone_CDD_RaR_number__c', 'Standalone_CDD_RORC_number__c',
                                            'Sector_Head__c','Floor_Clause_desc__c'};

        final List<String> facilityPF = new List<String>{'Underwriting%num%_desc__c',expFinal,
												newMoney,stanRAR,stanRORC,
												newAllD,newAllU,'Maturity_door_to_door%num%_number__c',
												'Average_Life%num%_number__c'};



        DES_Template__c templ;
        templ = [SELECT id, Industry_AA_type__c, Bankers_desc__c, Borrower_s_name_Fiscal_ID_desc__c,
                Guarantor_s_name_Fiscal_ID_desc__c, Calification_type__c, Int_Rating_type__c,Int_Rating_pf__c, Type_of_Deal_desc__c,
                bilateral_synd_type__c, YTD_RORC_per_CDD__c, Past_FY_RORC_per_CDD__c, Standalone_CDD_RaR_number__c, Standalone_CDD_RORC_number__c,
                curncy_trans_year_one_type__c, curncy_trans_year_two_type__c, curncy_trans_year_three_type__c, curncy_trans_year_four_type__c,
                Underwriting1_desc__c, Underwriting2_desc__c, Underwriting3_desc__c, Underwriting4_desc__c, Tier_desc__c, Tiering_Action_type__c,
                Expected_Final_Take1_number__c, Expected_Final_Take2_number__c, Expected_Final_Take3_number__c, Expected_Final_Take4_number__c,
                New_Money_for_BBVA1_desc__c, New_Money_for_BBVA2_desc__c, New_Money_for_BBVA3_desc__c, New_Money_for_BBVA4_desc__c,
                Standalone_RaR1_number__c, Standalone_RaR2_number__c, Standalone_RaR3_number__c, Standalone_RaR4_number__c,
                Standalone_RORC1_number__c, Standalone_RORC2_number__c, Standalone_RORC3_number__c, Standalone_RORC4_number__c,
                Expected_RAR_FY_per__c, RAR_Past_FY_per__c, RAR_YTD_per__c, Sector_Head__c,Floor_Clause_desc__c,
                New_All_in_Drawn1_desc__c, New_All_in_Drawn2_desc__c, New_All_in_Drawn3_desc__c, New_All_in_Drawn4_desc__c,
                New_All_in_Undrawn1_desc__c, New_All_in_Undrawn2_desc__c, New_All_in_Undrawn3_desc__c, New_All_in_Undrawn4_desc__c,
                Maturity_door_to_door1_number__c, Maturity_door_to_door2_number__c, Maturity_door_to_door3_number__c, Maturity_door_to_door4_number__c,
                Tenor_Years1_number__c, Tenor_Years2_number__c, Tenor_Years3_number__c, Tenor_Years4_number__c,
                Average_Life1_number__c, Average_Life2_number__c, Average_Life3_number__c, Average_Life4_number__c,
                Floor_Clause_type__c, Sustainable_Deal_type__c, SPPI_Test_type__c, RecordType.Name,
                Transaction_Deal_Amount1_number__c, Transaction_Deal_Amount2_number__c, Transaction_Deal_Amount3_number__c, Transaction_Deal_Amount4_number__c
                ,Expected_RORC_Avg_life_per__c, Expected_RAR_Avg_life_per__c, Past_FY_RORC_per__c, Client_RORC_Avg_life_per__c,YTD_RORC_per__c
                FROM DES_Template__c
                WHERE id = :lIDTempl.get(0)];

        missingFlieds = getRestrictedTemplateFields(templ, missingFlieds, allTemplate, tempFieldMap);
        missingFlieds = getRestrictedTemplateFields(templ, missingFlieds, (templ.RecordType.Name == Label.DES_Template_GTB?gtbTemplate:(templ.RecordType.Name == Label.DES_Template_CSL || templ.RecordType.Name == Label.DES_Template_CSL_Compass?cslTemplate:(templ.RecordType.Name == Label.DES_Template_ECA?ecaTemplate:(templ.RecordType.Name == Label.DES_Template_PF?pfTemplate:new List<String>())))), tempFieldMap);   //NOSONAR

        for(integer cont = 0; cont < 4; cont++) {
            missingFlieds = getRestrictedFacilityFields(cont, templ, missingFlieds, (templ.RecordType.Name == Label.DES_Template_GTB?facilityGTB:(templ.RecordType.Name == Label.DES_Template_CSL || templ.RecordType.Name == Label.DES_Template_CSL_Compass?facilityCSL:(templ.RecordType.Name == Label.DES_Template_ECA?facilityECA:(templ.RecordType.Name == Label.DES_Template_PF?facilityPF:new List<String>())))), tempFieldMap);   //NOSONAR
        }

        List<DES_Template_Table__c> lTempTable;
        lTempTable = [SELECT id, Sustainable_Deal_type__c FROM DES_Template_Table__c WHERE Parent_Template__c = :lIDTempl.get(0)];
        if(lTempTable != null && !lTempTable.isEmpty() && lTempTable.get(0).Sustainable_Deal_type__c == null) {
            missingFlieds.add(tempFieldMap.get('Sustainable_Deal_type__c').getDescribe().getLabel());
        }

        lReturn.add(missingFlieds.isEmpty()?Label.NoRelatedVisits:String.join(missingFlieds, '\n'));
        return lReturn;
    }

    private static List<String> getRestrictedTemplateFields(DES_Template__c template, List<String> lErrors, List<String> lFields, Map<String, Schema.SObjectField> tempFieldMap) {   //NOSONAR
        Set<String> sResult;
        sResult = new Set<String>(lErrors);
        String newFieldLabel;

        for(String field : lFields) {
            newFieldLabel = tempFieldMap.get(field).getDescribe().getLabel();
            if((template.get(field) == null || template.get(field) == '') && (sResult.isEmpty() || !sResult.contains(newFieldLabel))) {
                sResult.add(newFieldLabel);
            }
        }
        return new List<String>(sResult);
    }

    private static List<String> getRestrictedFacilityFields(Integer num, DES_Template__c template, List<String> lErrors, List<String> lFields, Map<String, Schema.SObjectField> tempFieldMap) {   //NOSONAR
        Set<String> sResult;
        sResult = new Set<String>(lErrors);
        List<String> lThisFields;
        lThisFields = lFields;
        final Integer facilityNum = num + 1;
        final String curFieldLabel = tempFieldMap.get('curncy_trans_year_'+(facilityNum==1?'one':(facilityNum==2?'two':(facilityNum==3?'three':(facilityNum==4?'four':''))))+'_type__c').getDescribe().getLabel();   //NOSONAR
        final String curFieldAPI = 'curncy_trans_year_'+(facilityNum==1?'one':(facilityNum==2?'two':(facilityNum==3?'three':(facilityNum==4?'four':''))))+'_type__c';   //NOSONAR
        final String curFieldLabelECA = 'Transaction_Deal_Amount' + facilityNum + '_number__c';

        String newField;

        if(facilityNum == 1 && template.RecordType.Name != Label.DES_Template_ECA) {
            lThisFields.add(curFieldAPI);
        }

        for(String field : lThisFields) {
            newField = tempFieldMap.get(field.replace('%num%', facilityNum+'')).getDescribe().getLabel();

            if((facilityNum == 1 || (template.get(curFieldAPI) != null && template.RecordType.Name != Label.DES_Template_ECA) || (template.get(curFieldLabelECA) != null &&  template.RecordType.Name == Label.DES_Template_ECA)) && (template.get(field.replace('%num%', facilityNum+'')) == null || template.get(field.replace('%num%', facilityNum+'')) == '') && (sResult.isEmpty() || !sResult.contains(newField))) {
                sResult.add(newField.replace(facilityNum+'', '') + ' (Facility ' + facilityNum + ')');
            }
        }
        return new List<String>(sResult);
    }
}