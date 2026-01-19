/*
*Author: Vass
*Master global de todas las minutas
*
*/
public with sharing class MasterMinutasCnt {

	/*
	*Por peticion de sonar
	*
	*/
	private MasterMinutasCnt() {}

		Map<String, String> mResultCode;

    /*
    *Author: Vass
    *crea master de las minutas
    *
    */
    @AuraEnabled
    public static String createMinuteTable(Integer year) {
   		String result = '';

		/*
		*  Día en el que cambiaron los campos de RAR y RORC,
		*  hasta entonces se mostrarán unos y tras esta fecha los nuevos
		*  si el nbc se aprovó antes de esa fecha mostramos solo los viejos
		*/
		final Date dateChangeTemp = date.newinstance(2020, 07, 16);

		Set<String> lAccID;
		List<String> lTempID;
		List<String> lOppID;
		Map<ID, Opportunity> mOpp;
		Map<ID, OpportunityLineItem> mOli;
		Map<String, decimal> mCurrType;
		Map<String, List<String>> mClientGroup;
		Map<String, List<decimal>> mFnlTkEUR;


		lTempID = new List<String>();
		lAccID = new Set<String>();
		lOppID = new List<String>();
		mCurrType = new Map<String, decimal>();
		mClientGroup = new Map<String, List<String>>();
      	mFnlTkEUR = new Map<String, List<decimal>>();
      	System.debug('Empty-> ' +lAccID+lOppID+mCurrType+mClientGroup+mFnlTkEUR+result);


        Date firstDate;
        firstDate = System.today().addDays(-366);
		Date lastDate;
        lastDate = System.today();
		mCurrType = NBC_MinuteHandler.fillCurrencyType();

		if(year !=null ){
			firstDate = Date.newInstance(year, 1, 1);
			lastDate = Date.newInstance(year, 12, 31);
		}
		system.debug(firstDate+ 'Correcto ');
		system.debug(lastDate+ 'Correcto');
		system.debug('mCurrType' + mCurrType);
		system.debug('dateChangeTemp' + dateChangeTemp);



    	final Map<ID, NBC__c>  lnbc = new Map<ID, NBC__c>([SELECT id, Name, Committee_Start_Date__c, NBC_Region_type__c, (SELECT id FROM Opportunities__r) FROM
			NBC__c WHERE Committee_Start_Date__c > :firstDate AND Committee_Start_Date__c <= :lastDate ORDER BY Committee_Start_Date__c DESC]);

    	try {
	    	if (!lnbc.isEmpty()) {

				lOppID = createOpportunityID(lnbc.values());

				mOpp = new Map<ID, Opportunity>( [SELECT id, Name, CreatedDate, AccountId, Account.Name, x_sell_committee_type__c,  //NOSONAR
				          gtb_participant_desc__c, gf_participant_desc__c, gcc_participant_desc__c, risk_participant_desc__c,
				          CIB_Geography_participant__c,Account.DES_Country_of_Management__c,Account.DES_Group_Code__c,
							Geography_CIB_Attended_type__c, Geography_CIB_Supportive_type__c, Risk_Attended_type__c, Risk_Supportive_type__c, GF_Attended_type__c, GF_Supportive_type__c,
							GTB_Attended_type__c, GTB_Supportive_type__c, GCC_Attended_type__c, GCC_Supportive_type__c, CurrencyIsoCode,
							gf_cross_sell_committee_date__c,
				          (SELECT id, Name, Booking_type__c, Bankers_desc__c, Int_Rating_type__c, Tenor_desc__c,Product_Name__c,
				            Borrower_s_name_Fiscal_ID_desc__c, Guarantor_s_name_Fiscal_ID_desc__c, Tenor_Years4_number__c,
				            Type_of_Deal_desc__c, Product_Purpose_desc__c, Tenor_number__c,Tenor_Years3_number__c,Int_Rating_pf__c,
				            All_in_Drawn_Undrawn_desc__c, Old_All_in_Drawn1_desc__c, Tenor_Years1_number__c,
				            New_All_in_Drawn1_desc__c, New_All_in_Drawn2_desc__c, New_All_in_Drawn3_desc__c, New_All_in_Drawn4_desc__c, Floor_Clause_desc__c, Sustainable_Deal_type__c,
							BBVA_Commitment1_number__c,BBVA_Commitment2_number__c,BBVA_Commitment3_number__c,BBVA_Commitment4_number__c, opportunity_id__r.CurrencyIsoCode,
				            Qualitative_Assesment_of_X_Sell_Rev_desc__c, Average_Life1_number__c, Average_Life2_number__c,
				            Average_Life3_number__c, Average_Life4_number__c, Industry_AA_type__c, Tenor_Years2_number__c,
				            curncy_trans_year_one_type__c, curncy_trans_year_two_type__c, curncy_trans_year_three_type__c,
				            curncy_trans_year_four_type__c, Underwriting1_desc__c, Underwriting2_desc__c, Underwriting3_desc__c,
				            Underwriting4_desc__c, Expected_Final_Take1_number__c, Expected_Final_Take2_number__c, Expected_Final_Take3_number__c,
				            Expected_Final_Take4_number__c, New_Money_for_BBVA1_desc__c, New_Money_for_BBVA2_desc__c, Expected_RAR_FY_per__c ,
				            New_Money_for_BBVA3_desc__c, New_Money_for_BBVA4_desc__c, Standalone_RaR1_number__c, Standalone_RaR2_number__c,
				            Standalone_RaR3_number__c, Standalone_RaR4_number__c, Standalone_RORC1_number__c, Standalone_RORC2_number__c,
				            Standalone_RORC3_number__c, Standalone_RORC4_number__c, Calification_type__c,
				            RecordTypeID, RecordType.DeveloperName, SPPI_Test_type__c, bilateral_synd_type__c, Floor_Clause_type__c,
				            New_All_in_Undrawn1_desc__c, New_All_in_Undrawn2_desc__c, New_All_in_Undrawn3_desc__c, New_All_in_Undrawn4_desc__c,
				            Old_All_in_Drawn2_desc__c, Old_All_in_Drawn3_desc__c, Old_All_in_Drawn4_desc__c, Maturity_door_to_door1_number__c,
				            Maturity_door_to_door2_number__c, Maturity_door_to_door3_number__c, Maturity_door_to_door4_number__c,Opportunity_Product_Id__c,
				            RecordType.Name, RAR_Past_FY_per__c, RAR_YTD_per__c, Syndication_Opinion_type__c, Sectorial_Norms_type__c, CurrencyIsoCode
							,gf_ead_tranche_1_amount__c,gf_ead_tranche_2_amount__c,gf_ead_tranche_3_amount__c,gf_ead_tranche_4_amount__c
							,Expected_RAR_Avg_life_per__c,Expected_RORC_Avg_life_per__c,Past_FY_RORC_per__c,Client_RORC_Avg_life_per__c
				            FROM Templates__r),

				            (SELECT id, Name, opportunity_nbc_recm_ind_type__c,opportunity_nbc_recm_date__c,
							DES_Decision_Comments__c, DES_Product_Family__c, opportunity_nbc_comments_desc__c, solution_classification_desc__c
							FROM OpportunityLineItems
				            WHERE opportunity_nbc_recm_date__c  != null)
				          FROM Opportunity WHERE id IN: lOppID]);
				lTempID = new List <String>();

                for(Opportunity oppor : mOpp.values()) {
                    for(DES_Template__c temp : oppor.Templates__r) {
						 lTempID.add(temp.Opportunity_Product_Id__c);
                    }
				}
				mOli= new Map<ID, OpportunityLineItem>([SELECT id, Name, DES_NBC_Approval__c, opportunity_nbc_recm_ind_type__c,OpportunityId,
				           DES_Decision_Comments__c, DES_Product_Family__c, opportunity_nbc_comments_desc__c, solution_classification_desc__c,
						   opportunity_nbc_recm_date__c
				           FROM OpportunityLineItem
				            WHERE opportunity_nbc_recm_date__c  != null and  OpportunityId IN :lOppID and id  IN :lTempID]);
				if(mOpp != null && !mOpp.isEmpty()) {
					convertToEUR(mOpp, lAccID, mCurrType, mFnlTkEUR);
					mClientGroup = createMapAcc(lAccID, mOpp);
					result = createWrapper(lnbc, mClientGroup, mOpp, mFnlTkEUR,mOli,dateChangeTemp);
					System.debug('result-> ' + result);
				}
	    	}

    	} catch(Exception e) {
			throw new AuraHandledException(Label.DES_Error + e);
		}
    	return result;
    }


    private static Map<String, List<String>> createMapAcc (Set<String> lAccID, Map<ID, Opportunity> mOpp) {
    	String separator;
    	separator = '%split%';
    	Map<String, List<String>> mResult;
		List<String> resultados;

    	mResult = new Map<String, List<String>>();

    	for(DES_Subsidiary_Group_Relation__c subMat : [SELECT Id, participant_parent_id__c, participant_parent_id__r.id, participant_parent_id__r.name, participant_parent_id__r.DES_Group_Code__c, participant_child_id__c, participant_child_id__r.name FROM DES_Subsidiary_Group_Relation__c WHERE participant_child_id__c IN :lAccID  AND main_subsidiary_ind_type__c = true]) {
			resultados = new List <String>();
			resultados.add(subMat.participant_parent_id__r.name+separator+subMat.participant_parent_id__r.id);
			resultados.add(subMat.participant_parent_id__r.DES_Group_Code__c);
			mResult.put(subMat.participant_child_id__c,resultados);
		}

		for(Opportunity oppor : mOpp.values()) {
	        if(!mResult.containsKey(oppor.AccountId)) {
				resultados = new List <String>();
				resultados.add(oppor.Account.Name+separator+oppor.AccountId);
				resultados.add(oppor.Account.DES_Group_Code__c);
	        	mResult.put(oppor.AccountId, resultados);
	        }
        }

        return mResult;
    }



    private static String createWrapper (Map<ID, NBC__c> lnbc, Map<String, List<String>> mClientGroup, Map<ID, Opportunity> mOpp, Map<String, List<decimal>> mFnlTkEUR,Map<ID,OpportunityLineItem> mOli, Date dateChangeTemp) {
    	List<WrapperClass> listWrapper;
    	listWrapper = new List<WrapperClass>();

    	for(NBC__c nbc : lnbc.values()) {

    		for(Opportunity opp : nbc.Opportunities__r) {
    			opp = mOpp.get(opp.id);

    			if(!opp.Templates__r.isEmpty() && !opp.OpportunityLineItems.isEmpty()) {
                    listWrapper.addAll(createTranche1 (nbc, mClientGroup, opp.Templates__r.get(0), opp, mFnlTkEUR,mOli.get(opp.Templates__r.get(0).Opportunity_Product_Id__c),dateChangeTemp));
    				listWrapper.addAll(createTranche2 (nbc, mClientGroup, opp.Templates__r.get(0), opp, mFnlTkEUR,mOli.get(opp.Templates__r.get(0).Opportunity_Product_Id__c),dateChangeTemp));
    				listWrapper.addAll(createTranche3 (nbc, mClientGroup, opp.Templates__r.get(0), opp, mFnlTkEUR,mOli.get(opp.Templates__r.get(0).Opportunity_Product_Id__c),dateChangeTemp));
    				listWrapper.addAll(createTranche4 (nbc, mClientGroup, opp.Templates__r.get(0), opp, mFnlTkEUR,mOli.get(opp.Templates__r.get(0).Opportunity_Product_Id__c),dateChangeTemp));
    			}
    		}

    	}

        return JSON.serialize(listWrapper);

    }

    private static List<WrapperClass> createTranche1 (NBC__c nbc, Map<String, List<String>> mClientGroup, DES_Template__c tmp, Opportunity opp, Map<String, List<decimal>> mFnlTkEUR,OpportunityLineItem mOli, Date dateChangeTemp) {



			String intRating;
    		List<WrapperClass> lWrapp;
    		lWrapp = new List<WrapperClass>();
            if(tmp.RecordType.Name!=Label.DES_Template_PF){
				intRating= tmp.Calification_type__c+'/'+tmp.Int_Rating_type__c;
            }else{
                intRating= tmp.Calification_type__c+'/'+tmp.Int_Rating_pf__c;
            }
  			if (tmp.BBVA_Commitment1_number__c != null && ((tmp.RecordType.Name == Label.DES_Template_ECA && tmp.opportunity_id__r.CurrencyIsoCode != null) || tmp.curncy_trans_year_one_type__c != null)) {
				lWrapp.add(
					new WrapperClass(
						nbc,
							mClientGroup.get(opp.AccountId).get(0),
							mClientGroup.get(opp.AccountId).get(1),
						opp,
						mOli,
						intRating,
						tmp.RecordType.Name == Label.DES_Template_ECA?tmp.opportunity_id__r.CurrencyIsoCode:tmp.curncy_trans_year_one_type__c,
						tmp.Underwriting1_desc__c,
						tmp.Expected_Final_Take1_number__c,
						mFnlTkEUR.get(Opp.id).get(0),
						tmp.gf_ead_tranche_1_amount__c,
						tmp.New_Money_for_BBVA1_desc__c,
						tmp.Standalone_RaR1_number__c,
						tmp.Standalone_RORC1_number__c,
						tmp.Expected_RAR_FY_per__c,
						tmp.RAR_Past_FY_per__c,
						tmp.RAR_YTD_per__c,
						opp.OpportunityLineItems.get(0).opportunity_nbc_recm_date__c!=null && opp.OpportunityLineItems.get(0).opportunity_nbc_recm_date__c > dateChangeTemp?tmp.Expected_RAR_Avg_life_per__c:null,	//NOSONAR
						opp.OpportunityLineItems.get(0).opportunity_nbc_recm_date__c!=null && opp.OpportunityLineItems.get(0).opportunity_nbc_recm_date__c > dateChangeTemp?tmp.Expected_RORC_Avg_life_per__c:null,	//NOSONAR
						opp.OpportunityLineItems.get(0).opportunity_nbc_recm_date__c!=null && opp.OpportunityLineItems.get(0).opportunity_nbc_recm_date__c > dateChangeTemp?(tmp.RecordType.DeveloperName == Label.DES_Template_CSL || tmp.RecordType.DeveloperName == Label.DES_Template_CSL_Compass?tmp.Past_FY_RORC_per__c:(tmp.RecordType.DeveloperName == Label.DES_Template_GTB?tmp.Client_RORC_Avg_life_per__c:null)):null,	//NOSONAR
						tmp.New_All_in_Drawn1_desc__c,
						tmp.New_All_in_Undrawn1_desc__c,
						tmp.Tenor_Years1_number__c==null?tmp.Maturity_door_to_door1_number__c:tmp.Tenor_Years1_number__c,
						tmp.Average_Life1_number__c,
						'1'
						)
					);
			}

  			return lWrapp;
    }

    private static List<WrapperClass> createTranche2 (NBC__c nbc, Map<String, List<String>> mClientGroup, DES_Template__c tmp, Opportunity opp, Map<String, List<decimal>> mFnlTkEUR,OpportunityLineItem mOli, Date dateChangeTemp) {

			String intRating;
    		List<WrapperClass> lWrapp;
    		lWrapp = new List<WrapperClass>();
            if(tmp.RecordType.Name!=Label.DES_Template_PF){
				intRating= tmp.Calification_type__c+'/'+tmp.Int_Rating_type__c;
            }else{
                intRating= tmp.Calification_type__c+'/'+tmp.Int_Rating_pf__c;
            }
  			if(tmp.BBVA_Commitment2_number__c != null && ((tmp.RecordType.Name == Label.DES_Template_ECA && tmp.opportunity_id__r.CurrencyIsoCode != null) ||  tmp.curncy_trans_year_two_type__c != null)) {
  				lWrapp.add(
      				new WrapperClass(
      					nbc,
      					mClientGroup.get(opp.AccountId).get(0),
      					mClientGroup.get(opp.AccountId).get(1),
      					opp,
						mOli,
						intRating,
      					tmp.RecordType.Name == Label.DES_Template_ECA?tmp.opportunity_id__r.CurrencyIsoCode:tmp.curncy_trans_year_two_type__c,
      					tmp.Underwriting2_desc__c,
      					tmp.Expected_Final_Take2_number__c,
      					mFnlTkEUR.get(Opp.id).get(1),
						tmp.gf_ead_tranche_2_amount__c,
      					tmp.New_Money_for_BBVA2_desc__c,
      					tmp.Standalone_RaR2_number__c,
      					tmp.Standalone_RORC2_number__c,
      					tmp.Expected_RAR_FY_per__c,
      					tmp.RAR_Past_FY_per__c,
      					tmp.RAR_YTD_per__c,
						opp.OpportunityLineItems.get(0).opportunity_nbc_recm_date__c!=null && opp.OpportunityLineItems.get(0).opportunity_nbc_recm_date__c > dateChangeTemp?tmp.Expected_RAR_Avg_life_per__c:null,	//NOSONAR
						opp.OpportunityLineItems.get(0).opportunity_nbc_recm_date__c!=null && opp.OpportunityLineItems.get(0).opportunity_nbc_recm_date__c > dateChangeTemp?tmp.Expected_RORC_Avg_life_per__c:null,	//NOSONAR
						opp.OpportunityLineItems.get(0).opportunity_nbc_recm_date__c!=null && opp.OpportunityLineItems.get(0).opportunity_nbc_recm_date__c > dateChangeTemp?(tmp.RecordType.DeveloperName == Label.DES_Template_CSL || tmp.RecordType.DeveloperName == Label.DES_Template_CSL_Compass?tmp.Past_FY_RORC_per__c:(tmp.RecordType.DeveloperName == Label.DES_Template_GTB?tmp.Client_RORC_Avg_life_per__c:null)):null,	//NOSONAR
      					tmp.New_All_in_Drawn2_desc__c,
      					tmp.New_All_in_Undrawn2_desc__c,
      					tmp.Tenor_Years2_number__c==null?tmp.Maturity_door_to_door2_number__c:tmp.Tenor_Years2_number__c,
      					tmp.Average_Life2_number__c,
  						'2'
      					)
      				);
  			}

  			return lWrapp;
    }


    private static List<WrapperClass> createTranche3 (NBC__c nbc, Map<String, List<String>> mClientGroup, DES_Template__c tmp, Opportunity opp, Map<String, List<decimal>> mFnlTkEUR,OpportunityLineItem mOli, Date dateChangeTemp) {

			String intRating;
    		List<WrapperClass> lWrapp;
    		lWrapp = new List<WrapperClass>();
            if(tmp.RecordType.Name!=Label.DES_Template_PF){
				intRating= tmp.Calification_type__c+'/'+tmp.Int_Rating_type__c;
            }else{
                intRating= tmp.Calification_type__c+'/'+tmp.Int_Rating_pf__c;
            }
  			if(tmp.BBVA_Commitment3_number__c != null && ((tmp.RecordType.Name == Label.DES_Template_ECA && tmp.opportunity_id__r.CurrencyIsoCode != null) ||  tmp.curncy_trans_year_three_type__c != null)) {
  				lWrapp.add(
      				new WrapperClass(
      					nbc,
      					mClientGroup.get(opp.AccountId).get(0),
      					mClientGroup.get(opp.AccountId).get(1),
      					opp,
						mOli,
						intRating,
      					tmp.RecordType.Name == Label.DES_Template_ECA?tmp.opportunity_id__r.CurrencyIsoCode:tmp.curncy_trans_year_three_type__c,
      					tmp.Underwriting3_desc__c,
      					tmp.Expected_Final_Take3_number__c,
      					mFnlTkEUR.get(Opp.id).get(2),
						tmp.gf_ead_tranche_3_amount__c,
      					tmp.New_Money_for_BBVA3_desc__c,
      					tmp.Standalone_RaR3_number__c,
      					tmp.Standalone_RORC3_number__c,
      					tmp.Expected_RAR_FY_per__c,
      					tmp.RAR_Past_FY_per__c,
      					tmp.RAR_YTD_per__c,
						opp.OpportunityLineItems.get(0).opportunity_nbc_recm_date__c!=null && opp.OpportunityLineItems.get(0).opportunity_nbc_recm_date__c > dateChangeTemp?tmp.Expected_RAR_Avg_life_per__c:null,	//NOSONAR
						opp.OpportunityLineItems.get(0).opportunity_nbc_recm_date__c!=null && opp.OpportunityLineItems.get(0).opportunity_nbc_recm_date__c > dateChangeTemp?tmp.Expected_RORC_Avg_life_per__c:null,	//NOSONAR
						opp.OpportunityLineItems.get(0).opportunity_nbc_recm_date__c!=null && opp.OpportunityLineItems.get(0).opportunity_nbc_recm_date__c > dateChangeTemp?(tmp.RecordType.DeveloperName == Label.DES_Template_CSL || tmp.RecordType.DeveloperName == Label.DES_Template_CSL_Compass?tmp.Past_FY_RORC_per__c:(tmp.RecordType.DeveloperName == Label.DES_Template_GTB?tmp.Client_RORC_Avg_life_per__c:null)):null,	//NOSONAR
      					tmp.New_All_in_Drawn3_desc__c,
      					tmp.New_All_in_Undrawn3_desc__c,
      					tmp.Tenor_Years3_number__c==null?tmp.Maturity_door_to_door3_number__c:tmp.Tenor_Years3_number__c,
      					tmp.Average_Life3_number__c,
  						'3'
      					)
      				);
  			}

  			return lWrapp;
    }


    private static List<WrapperClass> createTranche4 (NBC__c nbc, Map<String, List<String>> mClientGroup, DES_Template__c tmp, Opportunity opp, Map<String, List<decimal>> mFnlTkEUR,OpportunityLineItem mOli, Date dateChangeTemp) {
			String intRating;
    		List<WrapperClass> lWrapp;
    		lWrapp = new List<WrapperClass>();
            if(tmp.RecordType.Name!=Label.DES_Template_PF){
				intRating= tmp.Calification_type__c+'/'+tmp.Int_Rating_type__c;
            }else{
                intRating= tmp.Calification_type__c+'/'+tmp.Int_Rating_pf__c;
            }
  			if(tmp.BBVA_Commitment4_number__c != null && ((tmp.RecordType.Name == Label.DES_Template_ECA && tmp.opportunity_id__r.CurrencyIsoCode != null) ||  tmp.curncy_trans_year_four_type__c != null)) {
  				lWrapp.add(
      				new WrapperClass(
      					nbc,
      					mClientGroup.get(opp.AccountId).get(0),
      					mClientGroup.get(opp.AccountId).get(1),
      					opp,
						mOli,
						intRating,
      					tmp.RecordType.Name == Label.DES_Template_ECA?tmp.opportunity_id__r.CurrencyIsoCode:tmp.curncy_trans_year_four_type__c,
      					tmp.Underwriting4_desc__c,
      					tmp.Expected_Final_Take4_number__c,
      					mFnlTkEUR.get(Opp.id).get(3),
						tmp.gf_ead_tranche_4_amount__c,
      					tmp.New_Money_for_BBVA4_desc__c,
      					tmp.Standalone_RaR4_number__c,
      					tmp.Standalone_RORC4_number__c,
      					tmp.Expected_RAR_FY_per__c,
      					tmp.RAR_Past_FY_per__c,
      					tmp.RAR_YTD_per__c,
						opp.OpportunityLineItems.get(0).opportunity_nbc_recm_date__c!=null && opp.OpportunityLineItems.get(0).opportunity_nbc_recm_date__c > dateChangeTemp?tmp.Expected_RAR_Avg_life_per__c:null,	//NOSONAR
						opp.OpportunityLineItems.get(0).opportunity_nbc_recm_date__c!=null && opp.OpportunityLineItems.get(0).opportunity_nbc_recm_date__c > dateChangeTemp?tmp.Expected_RORC_Avg_life_per__c:null,	//NOSONAR
						opp.OpportunityLineItems.get(0).opportunity_nbc_recm_date__c!=null && opp.OpportunityLineItems.get(0).opportunity_nbc_recm_date__c > dateChangeTemp?(tmp.RecordType.DeveloperName == Label.DES_Template_CSL || tmp.RecordType.DeveloperName == Label.DES_Template_CSL_Compass?tmp.Past_FY_RORC_per__c:(tmp.RecordType.DeveloperName == Label.DES_Template_GTB?tmp.Client_RORC_Avg_life_per__c:null)):null,	//NOSONAR
      					tmp.New_All_in_Drawn4_desc__c,
      					tmp.New_All_in_Undrawn4_desc__c,
      					tmp.Tenor_Years4_number__c==null?tmp.Maturity_door_to_door4_number__c:tmp.Tenor_Years4_number__c,
      					tmp.Average_Life4_number__c,
  						'4'
      					)
      				);
  			}

  			return lWrapp;
    }


    private static void convertToEUR (Map<ID, Opportunity> mOpp, Set<String> lAccID, Map<String, decimal> mCurrType,  Map<String, List<decimal>> mFnlTkEUR) {

      List<decimal> lMoneyTranch;
          lMoneyTranch = new List<decimal>();
          for(Opportunity oppor : mOpp.values()) {
            lMoneyTranch = new List<decimal>();

            lAccID.add(oppor.AccountId);
            convertFinalTakeMoney (oppor, lMoneyTranch, mFnlTkEUR, mCurrType);

          }
    }


    private static List<String> createOpportunityID(List<NBC__c> lnbc1) {
    	List<String> result;
    	result = new List<String>();

    	for(integer cont=0;cont<lnbc1.size();cont++) {
			for(Opportunity opp : lnbc1.get(cont).Opportunities__r) {
				result.add(opp.id);
			}
		}
		return result;
    }


    private static void convertFinalTakeMoney (Opportunity oppor, List<decimal> lMoneyTranch, Map<String, List<decimal>> mFnlTkEUR, Map<String, decimal> mCurrType) {

			String currencyECA;
            for(DES_Template__c templ : oppor.Templates__r) {
				currencyECA = NBC_MinuteHandler.isECA (templ);
				lMoneyTranch.add(NBC_MinuteHandler.convertDataCurrency(templ.Expected_Final_Take1_number__c, NBC_MinuteHandler.getTrancheCurrency(templ.curncy_trans_year_one_type__c,currencyECA), mCurrType));
				lMoneyTranch.add(NBC_MinuteHandler.convertDataCurrency(templ.Expected_Final_Take2_number__c, NBC_MinuteHandler.getTrancheCurrency(templ.curncy_trans_year_two_type__c,currencyECA), mCurrType));
				lMoneyTranch.add(NBC_MinuteHandler.convertDataCurrency(templ.Expected_Final_Take3_number__c, NBC_MinuteHandler.getTrancheCurrency(templ.curncy_trans_year_three_type__c,currencyECA), mCurrType));
				lMoneyTranch.add(NBC_MinuteHandler.convertDataCurrency(templ.Expected_Final_Take4_number__c, NBC_MinuteHandler.getTrancheCurrency(templ.curncy_trans_year_four_type__c,currencyECA), mCurrType));

				templ.New_Money_for_BBVA1_desc__c = NBC_MinuteHandler.splitTo(templ.New_Money_for_BBVA1_desc__c, NBC_MinuteHandler.getTrancheCurrency(templ.curncy_trans_year_one_type__c,currencyECA), mCurrType);
				templ.New_Money_for_BBVA2_desc__c = NBC_MinuteHandler.splitTo(templ.New_Money_for_BBVA2_desc__c, NBC_MinuteHandler.getTrancheCurrency(templ.curncy_trans_year_two_type__c,currencyECA), mCurrType);
				templ.New_Money_for_BBVA3_desc__c = NBC_MinuteHandler.splitTo(templ.New_Money_for_BBVA3_desc__c, NBC_MinuteHandler.getTrancheCurrency(templ.curncy_trans_year_three_type__c,currencyECA), mCurrType);
				templ.New_Money_for_BBVA4_desc__c = NBC_MinuteHandler.splitTo(templ.New_Money_for_BBVA4_desc__c, NBC_MinuteHandler.getTrancheCurrency(templ.curncy_trans_year_four_type__c,currencyECA), mCurrType);
            }
            mFnlTkEUR.put(oppor.id, lMoneyTranch);
    }


	/*
	*  variable wrapper usada en cliente
	*/
    public class WrapperClass { //NOSONAR USED IN CLIENT
		/*
        *  variable wrapper
		*/
		private final String nbcDate; //NOSONAR USED IN CLIENT
		/*
        *  variable wrapper
		*/
		private final String nbcRegion; //NOSONAR USED IN CLIENT
		/*
        *  variable wrapper
		*/
		private final String nbcUrl; //NOSONAR USED IN CLIENT
		/*
        *  variable wrapper
		*/
		private final String bookOff; //NOSONAR USED IN CLIENT
		/*
        *  variable wrapper
		*/
		private final String industry; //NOSONAR USED IN CLIENT
		/*
        *  variable wrapper
		*/
		private final String banker; //NOSONAR USED IN CLIENT
		/*
        *  variable wrapper
		*/
		private final String borrower; //NOSONAR USED IN CLIENT
		/*
        *  variable wrapper
		*/
		private final String nOperation; //NOSONAR USED IN CLIENT
		/*
        *  variable wrapper
		*/
		private final String guarantor; //NOSONAR USED IN CLIENT
		/*
        *  variable wrapper
		*/
		private final String groupClient; //NOSONAR USED IN CLIENT
		/*
        *  variable wrapper
		*/
		private final String groupCliURL; //NOSONAR USED IN CLIENT

		/*
        *  variable wrapper
		*/
		private final String intRating; //NOSONAR USED IN CLIENT

		/*
        *  variable wrapper
		*/
		private final String dealType; //NOSONAR USED IN CLIENT
		/*
        *  variable wrapper
		*/
		private final String bilateral; //NOSONAR USED IN CLIENT
		/*
        *  variable wrapper
		*/
		private final String productArea; //NOSONAR USED IN CLIENT
		/*
        *  variable wrapper
		*/
		private final String product; //NOSONAR USED IN CLIENT


		/*
        *  variable wrapper
		*/
		private final String currencyTranch; //NOSONAR USED IN CLIENT
		/*
        *  variable wrapper
		*/
		private final String underwritting; //NOSONAR USED IN CLIENT
		/*
        *  variable wrapper
		*/
		private final String finalTake; //NOSONAR USED IN CLIENT
		/*
        *  variable wrapper
		*/
		private final String finalTakeEUR; //NOSONAR USED IN CLIENT
		/*
        *  variable wrapper
		*/
		private final String EADs; //NOSONAR USED IN CLIENT
		/*
        *  variable wrapper
		*/
		private final String newMoneyEUR; //NOSONAR USED IN CLIENT
		/*
        *  variable wrapper
		*/
		private final String rar; //NOSONAR USED IN CLIENT //+%
		/*
        *  variable wrapper
		*/
		private final String rorc; //NOSONAR USED IN CLIENT //+%
		/*
        *  variable wrapper
		*/
		private final String expectedRar; //NOSONAR USED IN CLIENT
		/*
        *  variable wrapper
		*/
		private final String cibDeskPast; //NOSONAR USED IN CLIENT
		/*
        *  variable wrapper
		*/
		private final String cibDeskNow; //NOSONAR USED IN CLIENT
		/*
        *  variable wrapper Expected Global RORC CIB w/o X-sell
		*/
		private final String rorcCIBSell; //NOSONAR USED IN CLIENT
		/*
        *  variable wrapper Expected Global RORC CIB
		*/
		private final String rorcCIB; //NOSONAR USED IN CLIENT
		/*
        *  variable wrapper Client's Global RORC CIB
		*/
		private final String clientRorc; //NOSONAR USED IN CLIENT
		/*
        *  variable wrapper
		*/
		private final String allInDrawn; //NOSONAR USED IN CLIENT
		/*
        *  variable wrapper
		*/
		private final String allInUnDrawn; //NOSONAR USED IN CLIENT
		/*
        *  variable wrapper
		*/
		private final String tenor; //NOSONAR USED IN CLIENT
		/*
        *  variable wrapper
		*/
		private final String avgLife; //NOSONAR USED IN CLIENT
		/*
        *  variable wrapper
		*/
		private final String floorClause; //NOSONAR USED IN CLIENT
		/*
        *  variable wrapper
		*/
		private final String syndicationOp; //NOSONAR USED IN CLIENT
		/*
        *  variable wrapper
		*/
		private final String sustainableDeal; //NOSONAR USED IN CLIENT
		/*
        *  variable wrapper
		*/
		private final String xSell; //NOSONAR USED IN CLIENT
		/*
        *  variable wrapper
		*/
		private final String xSellDate; //NOSONAR USED IN CLIENT
		/*
        *  variable wrapper
		*/
		private final String sppiTest; //NOSONAR USED IN CLIENT
		/*
        *  variable wrapper
		*/
		private final String sectorialNorm; //NOSONAR USED IN CLIENT
		/*
        *  variable wrapper
		*/
		private final String comments; //NOSONAR USED IN CLIENT
		/*
        *  variable wrapper
		*/
		private final String decision; //NOSONAR USED IN CLIENT
		/*
        *  variable wrapper
		*/
		private final String gcParticipant; //NOSONAR USED IN CLIENT
		/*
        *  variable wrapper
		*/
		private final String gtbParticipant; //NOSONAR USED IN CLIENT
		/*
        *  variable wrapper
		*/
		private final String gfParticipant; //NOSONAR USED IN CLIENT
		/*
        *  variable wrapper
		*/
		private final String riskParticipant; //NOSONAR USED IN CLIENT
		/*
        *  variable wrapper
		*/
		private final String cibParticipant; //NOSONAR USED IN CLIENT
		/*
        *  variable wrapper
		*/
		private final String countryManage; //NOSONAR USED IN CLIENT
		/*
        *  variable wrapper
		*/
		private final String groupCode; //NOSONAR USED IN CLIENT

		/*
		* Constructor
		*/
		public WrapperClass(NBC__c nbc, String client, String groupCode, Opportunity opp, OpportunityLineItem mOli, String intRating, String currencyTranch, String underwritting, Decimal finalTake, Decimal finalTakeEUR, Decimal EADs, String newMoneyEUR, Decimal rar, Decimal rorc, Decimal expectedRar, Decimal cibDeskPast, Decimal cibDeskNow, Decimal rorcCIBSell, Decimal rorcCIB, Decimal clientRorc, String allInDrawn, String allInUnDrawn, String tenor, String avgLife, String operacion) {             //NOSONAR
	    	String separator;
	    	separator = '%split%';
	    	String internalRating = intRating;
			internalRating = String.valueOf(intRating).replace('null/', '').replace('null', '');
			this.nbcDate=nbc.Committee_Start_Date__c==null?'-':String.valueOf(nbc.Committee_Start_Date__c.date());
			this.countryManage=opp.Account.DES_Country_of_Management__c==null?'-':String.valueOf(opp.Account.DES_Country_of_Management__c);
			this.groupCode=groupCode==null?'-':String.valueOf(groupCode);
			this.nbcRegion=nbc.NBC_Region_type__c==null?'-':String.valueOf(nbc.NBC_Region_type__c);
			this.nbcUrl='/lightning/r/NBC__c/' + nbc.Id + '/view';
			this.bookOff=opp.Templates__r.get(0).Booking_type__c==null?'-':String.valueOf(opp.Templates__r.get(0).Booking_type__c);
			this.industry=opp.Templates__r.get(0).Industry_AA_type__c==null?'-':String.valueOf(opp.Templates__r.get(0).Industry_AA_type__c);
			this.banker=opp.Templates__r.get(0).Bankers_desc__c==null?'-':String.valueOf(opp.Templates__r.get(0).Bankers_desc__c);
			this.borrower=opp.Templates__r.get(0).Borrower_s_name_Fiscal_ID_desc__c==null?'N/A':String.valueOf(opp.Templates__r.get(0).Borrower_s_name_Fiscal_ID_desc__c);
			this.nOperation=operacion;
			this.guarantor=opp.Templates__r.get(0).Guarantor_s_name_Fiscal_ID_desc__c==null ? 'N/A' : String.valueOf(opp.Templates__r.get(0).Guarantor_s_name_Fiscal_ID_desc__c);
			this.groupClient=client==null ? '-' : String.valueOf(client).split(separator)[0];
			this.groupCliURL=client==null ? '-' : '/lightning/r/Account/' + String.valueOf(client).split(separator)[1] + '/view';
			this.intRating=internalRating!=null || internalRating.length()==0 ? internalRating : '-';
			this.dealType=opp.Templates__r.get(0).Type_of_Deal_desc__c==null ? '-' : String.valueOf(opp.Templates__r.get(0).Type_of_Deal_desc__c);
			this.bilateral=opp.Templates__r.get(0).bilateral_synd_type__c==null ? '-' : String.valueOf(opp.Templates__r.get(0).bilateral_synd_type__c);
			this.productArea=mOli.DES_Product_Family__c;
			this.product=mOli.solution_classification_desc__c;
			this.currencyTranch=currencyTranch==null ? '-' : String.valueOf(currencyTranch);
			this.underwritting=underwritting==null ? '-' : String.valueOf(underwritting) == 'Yes'?'Y':'N';
			this.finalTake=finalTake==null ? '-' : String.valueOf(finalTake);
			this.finalTakeEUR=finalTakeEUR==null ? '-' : String.valueOf(finalTakeEUR);
			this.EADs = EADs==null ? '-' : EADs+'';
			this.newMoneyEUR=newMoneyEUR==null ? '-' : String.valueOf(newMoneyEUR);
			this.rar=rar==null ? '-' : rar+'%';
			this.rorc=rorc==null ? '-' : rorc+'%';
			this.expectedRar=expectedRar==null ? '-' : expectedRar+'%';
			this.cibDeskPast=cibDeskPast==null ? '-' : cibDeskPast+'%';
			this.cibDeskNow=cibDeskNow==null ? '-' : cibDeskNow+'%';
			this.rorcCIBSell=rorcCIBSell==null ? '-' : rorcCIBSell+'%';
			this.rorcCIB=rorcCIB==null ? '-' : rorcCIB+'%';
			this.clientRorc=clientRorc==null ? '-' : clientRorc+'%';
			this.allInDrawn=allInDrawn==null ? '-' : String.valueOf(allInDrawn);
			this.allInUnDrawn=allInUnDrawn==null ? '-' : String.valueOf(allInUnDrawn);
			this.tenor=tenor==null ? '-' : String.valueOf(tenor);
			this.avgLife=avgLife==null ? '-' : String.valueOf(avgLife);
			this.floorClause=opp.Templates__r.get(0).Floor_Clause_type__c==null ? '-' : String.valueOf(opp.Templates__r.get(0).Floor_Clause_type__c) == 'Yes' ? 'Y' : 'N';
			this.syndicationOp=opp.Templates__r.get(0).Syndication_Opinion_type__c ? 'Y' : 'N';
			this.sustainableDeal=opp.Templates__r.get(0).Sustainable_Deal_type__c==null ? '-' : String.valueOf(opp.Templates__r.get(0).Sustainable_Deal_type__c) == 'Yes'?'Y':'N';
			this.xSell=opp.x_sell_committee_type__c ? 'Y' : 'N';
			this.xSellDate=opp.gf_cross_sell_committee_date__c==null?'-':String.valueOf(opp.gf_cross_sell_committee_date__c);
			this.sppiTest=opp.Templates__r.get(0).SPPI_Test_type__c==null ? '-' : String.valueOf(opp.Templates__r.get(0).SPPI_Test_type__c);
      		this.sectorialNorm=opp.Templates__r.get(0).Sectorial_Norms_type__c==null ? '-' : String.valueOf(opp.Templates__r.get(0).Sectorial_Norms_type__c);
			this.comments=opp.OpportunityLineItems.get(0).opportunity_nbc_comments_desc__c==null ? '-' : opp.OpportunityLineItems.get(0).opportunity_nbc_comments_desc__c;
			this.decision=opp.OpportunityLineItems.get(0).opportunity_nbc_recm_ind_type__c==null ? '-' : (String.valueOf(opp.OpportunityLineItems.get(0).opportunity_nbc_recm_ind_type__c) == 'Yes' ? 'Y' : (String.valueOf(opp.OpportunityLineItems.get(0).opportunity_nbc_recm_ind_type__c) == 'No'?'N': String.valueOf(opp.OpportunityLineItems.get(0).opportunity_nbc_recm_ind_type__c))); //NOSONAR
			this.gcParticipant=opp.gcc_participant_desc__c==null ? '-' : String.valueOf(opp.gcc_participant_desc__c);
			this.gtbParticipant=opp.gtb_participant_desc__c==null ? '-' : String.valueOf(opp.gtb_participant_desc__c);
			this.gfParticipant=opp.gf_participant_desc__c==null ? '-' : String.valueOf(opp.gf_participant_desc__c);
			this.riskParticipant=opp.risk_participant_desc__c==null ? '-' : String.valueOf(opp.risk_participant_desc__c);
			this.cibParticipant=opp.CIB_Geography_participant__c==null ? '-' : String.valueOf(opp.CIB_Geography_participant__c);
		}
    }
}