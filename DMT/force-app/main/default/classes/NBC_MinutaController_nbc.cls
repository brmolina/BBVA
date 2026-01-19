/*
*Author: Alejandro del Rio
*Crea y envía la minuta de NBC
*
*/
public with sharing class NBC_MinutaController_nbc {//NOSONAR
    /*
    *Author: Alejandro del Rio
    *maximo tamaño del documentos
    *
    */
    private final Integer maxOpp;
    /*
    *Author: Alejandro del Rio
    *uñltima pagina del documento
    *
    */
    public String finalPage {get; set;}
    /*
    *Author: Alejandro del Rio
    *uñltima pagina del documento
    *
    */
    public String nameDate {get; set;}
    /*
    *Author: Alejandro del Rio
    *idOportuinidad -> oportunidad
    *
    */
    public Map<ID, Opportunity> mOpp {get; set;}
    /*
    *Author: Alejandro del Rio
    *idOportunidad -> cliente
    *
    */
    public Map<String, String> mClientGroup {get; set;}
    /*
    *Author: Alejandro del Rio
    *idOportunidad -> final take en millones
    *
    */
    public Map<String, List<decimal>> mFnlTkEUR {get; set;}
    /*
    *Author: Alejandro del Rio
    *Oportunidades por pagina
    *
    */
    public Map<String, List<Opportunity>> mPagelOpp {get; set;}
    /*
    *Author: Alejandro del Rio
    *objeto visita sobre el que creqar el template
    *
    */
    public NBC__c nbcObj {get;set;}
    /*
    *Author: Alejandro del Rio
    *id de la visita
    *
    */
    public Id idNbc {get;set;}
    /*
    *Author: Alejandro del Rio
    *marca si se puede enviar
    *
    */
    public boolean enviar {get;set;}
    /*
    *Author: Alejandro del Rio
    *marca si el correo se envia para refrescar la pagina
    *
    */
    public boolean correoEnviado {get;set;}

    /**
     * download action
     */
    private final static String DOWNLOAD = 'download';

    /*
    *Author: Alejandro del Rio
    *Crea y envía la minuta de NBC
    *
    */
  public NBC_MinutaController_nbc(ApexPages.StandardController stdController) {
    String idOppors ='';

    System.debug(stdController);
    maxOpp = Integer.valueOf(Label.NBC_minute_max_opportunity);

    idNbc   = ApexPages.currentPage().getParameters().get('Id');

    //CAMBIO William Dorado:captura las opportunidades
    idOppors  = ApexPages.currentPage().getParameters().get('Opps');
    final Set<String> setOppIds=new Set<String>(); //NOSONAR

    if(idOppors!=null) {
          setOppIds.addAll(idOppors.Split(':'));
    }


    //FIN CAMBIO

    final List<NBC__c> lNbc = new List<NBC__c>([select id, Committee_End_Date__c, Name, Committee_Start_Date__c, NBC_Region_type__c
                                                                          from NBC__c
                                                                          where Id = :idNbc]);

    mClientGroup = new Map<String, String>();

    if( !lNbc.isEmpty()) {

      nbcObj = lNbc[0];

      final List <String> nameSplit = lNbc.get(0).Name.split(' ');
      if(nameSplit.size() == 3 && nameSplit.get(2).split('-').size() == 3) {
        final List <String> dateSplit = nameSplit[2].split('-');
        nameDate = nameSplit.get(0) + ' ' + nameSplit.get(1) + ' ' + dateSplit.get(2) + '-' + dateSplit.get(1) + '-'+ dateSplit.get(0);
      } else {
        nameDate = lNbc.get(0).Name;
      }



      final Map<String, decimal> mCurrType = NBC_MinuteHandler.fillCurrencyType();

      mOpp = new Map<ID, Opportunity>([

          SELECT id, Name, CreatedDate, AccountId, Account.Name, x_sell_committee_type__c,  //NOSONAR
              gtb_participant_desc__c, gf_participant_desc__c, gcc_participant_desc__c, risk_participant_desc__c, CIB_Geography_participant__c,
              Geography_CIB_Attended_type__c, Geography_CIB_Supportive_type__c, Risk_Attended_type__c, Risk_Supportive_type__c, GF_Attended_type__c, GF_Supportive_type__c,
              GTB_Attended_type__c, GTB_Supportive_type__c, GCC_Attended_type__c, GCC_Supportive_type__c,
              gf_cross_sell_committee_date__c,
              ( SELECT id, Name, Booking_type__c, Bankers_desc__c, Int_Rating_type__c,Int_Rating_pf__c, Tenor_desc__c,
                  Borrower_s_name_Fiscal_ID_desc__c, Guarantor_s_name_Fiscal_ID_desc__c, Tenor_Years4_number__c,
                  Type_of_Deal_desc__c, Product_Purpose_desc__c, Tenor_number__c,Tenor_Years3_number__c,
                  All_in_Drawn_Undrawn_desc__c, Old_All_in_Drawn1_desc__c, Tenor_Years1_number__c,
                  New_All_in_Drawn1_desc__c, New_All_in_Drawn2_desc__c, New_All_in_Drawn3_desc__c, New_All_in_Drawn4_desc__c,
                  Floor_Clause_desc__c, Sustainable_Deal_type__c,
                  Qualitative_Assesment_of_X_Sell_Rev_desc__c, Average_Life1_number__c, Average_Life2_number__c,
                  Average_Life3_number__c, Average_Life4_number__c, Industry_AA_type__c, Tenor_Years2_number__c,
                  curncy_trans_year_one_type__c, curncy_trans_year_two_type__c, curncy_trans_year_three_type__c,
                  curncy_trans_year_four_type__c, Underwriting1_desc__c, Underwriting2_desc__c, Underwriting3_desc__c,
                  Underwriting4_desc__c, Expected_Final_Take1_number__c, Expected_Final_Take2_number__c, Expected_Final_Take3_number__c,
                  Expected_Final_Take4_number__c, New_Money_for_BBVA1_desc__c, New_Money_for_BBVA2_desc__c, Expected_RAR_FY_per__c,
                  New_Money_for_BBVA3_desc__c, New_Money_for_BBVA4_desc__c, Standalone_RaR1_number__c, Standalone_RaR2_number__c,
                  Standalone_RaR3_number__c, Standalone_RaR4_number__c, Standalone_RORC1_number__c, Standalone_RORC2_number__c,
                  Standalone_RORC3_number__c, Standalone_RORC4_number__c, Calification_type__c,
                  RecordTypeID, RecordType.DeveloperName, SPPI_Test_type__c, bilateral_synd_type__c, Floor_Clause_type__c,
                  New_All_in_Undrawn1_desc__c, New_All_in_Undrawn2_desc__c, New_All_in_Undrawn3_desc__c, New_All_in_Undrawn4_desc__c,
                  Old_All_in_Drawn2_desc__c, Old_All_in_Drawn3_desc__c, Old_All_in_Drawn4_desc__c, Maturity_door_to_door1_number__c,
                  Maturity_door_to_door2_number__c, Maturity_door_to_door3_number__c, Maturity_door_to_door4_number__c,
                  RecordType.Name, RAR_Past_FY_per__c, RAR_YTD_per__c, Product_Name__c, Booking_label__c
                  ,Expected_RORC_Avg_life_per__c, Expected_RAR_Avg_life_per__c, Past_FY_RORC_per__c, Client_RORC_Avg_life_per__c, YTD_RORC_per__c
                  ,gf_ead_tranche_1_amount__c,gf_ead_tranche_2_amount__c,gf_ead_tranche_3_amount__c,gf_ead_tranche_4_amount__c
              FROM Templates__r
          ),

          (
              SELECT id, opportunity_nbc_recm_ind_type__c,
                  DES_Decision_Comments__c, DES_Product_Family__c, opportunity_nbc_comments_desc__c, nbc_discussion_topic_desc__c
              FROM OpportunityLineItems
              WHERE opportunity_nbc_recm_date__c != null
          )
          FROM Opportunity
          WHERE Committee_id__c = :nbcObj.Id and id in:setOppIds
      ]);

      final List<String> lAccID = new List<String>();
      convertToEUR(mOpp, lAccID, mCurrType);//NOSONAR


      for (DES_Subsidiary_Group_Relation__c subMat : [SELECT Id, participant_parent_id__c, participant_parent_id__r.name, participant_child_id__c, participant_child_id__r.name FROM DES_Subsidiary_Group_Relation__c WHERE participant_child_id__c IN :lAccID AND main_subsidiary_ind_type__c = true]) {
        mClientGroup.put(subMat.participant_child_id__c, subMat.participant_parent_id__r.name);
      }
      dividirPorPagina (mClientGroup, mOpp);//NOSONAR


      final String action = ApexPages.currentPage().getParameters().get('action');

      if (action == DOWNLOAD) {
        final String fileName = ApexPages.currentPage().getParameters().get('fileName');
        Apexpages.currentPage().getHeaders().put('content-disposition', 'attachment; filename=' + fileName.unescapeHtml3());
      }

    }

  }


    private void dividirPorPagina (Map<String, String> mClientGroup, Map<ID, Opportunity> mOpp) {
      Integer pagina;
      Integer contador;
      Integer newDimension;
      List<Opportunity> lOppPage;
      lOppPage = new List<Opportunity>();
      mPagelOpp = new Map<String, List<Opportunity>>();

      finalPage = '';
      contador = 0;
      pagina = 1;

      for(Opportunity oppor : mOpp.values()) {
        if(!mClientGroup.containsKey(oppor.AccountId)) {
          mClientGroup.put(oppor.AccountId, oppor.Account.Name);
        }

        newDimension = calculateDimension (oppor);

        if(maxOpp >= (newDimension + contador)) {

          contador += newDimension;
          if(mPagelOpp.containsKey(String.valueOf(pagina)) && mPagelOpp.get(String.valueOf(pagina)).size() > 0) {
            lOppPage = mPagelOpp.get(String.valueOf(pagina));
            lOppPage.add(oppor);
            mPagelOpp.put(String.valueOf(pagina), lOppPage);
          } else {
            lOppPage = new List<Opportunity>();
            lOppPage.add(oppor);
            mPagelOpp.put(String.valueOf(pagina), lOppPage);
          }
        } else {
          pagina ++;
          contador = newDimension;
          lOppPage = new List<Opportunity>();
          lOppPage.add(oppor);
          mPagelOpp.put(String.valueOf(pagina), lOppPage);
        }
      }
      System.debug(contador);
      finalPage = String.valueOf(pagina);
    }


    private Integer calculateDimension (Opportunity oppor) {
      Integer newDimension = 4;
      if(oppor.Templates__r.size()>0 && oppor.Templates__r[0].Expected_Final_Take2_number__c!=null) {
        newDimension += 1;
      }
      if(oppor.Templates__r.size()>0 && oppor.Templates__r[0].Expected_Final_Take3_number__c!=null) {
        newDimension += 1;
      }
      if(oppor.Templates__r.size()>0 && oppor.Templates__r[0].Expected_Final_Take4_number__c!=null) {
        newDimension += 1;
      }
      return newDimension;
    }



    private void convertToEUR (Map<ID, Opportunity> mOpp, List<String> lAccID, Map<String, decimal> mCurrType) {

      List<decimal> lMoneyTranch;
      mFnlTkEUR = new Map<String, List<decimal>>();
          lMoneyTranch = new List<decimal>();
          for(Opportunity oppor : mOpp.values()) {
            lMoneyTranch = new List<decimal>();

            lAccID.add(oppor.AccountId);
            convertFinalTakeMoney (oppor, lMoneyTranch, mFnlTkEUR, mCurrType);

          }
    }



    private void convertFinalTakeMoney (Opportunity oppor, List<decimal> lMoneyTranch, Map<String, List<decimal>> mFnlTkEUR, Map<String, decimal> mCurrType) {
            String currencyECA;
            for(DES_Template__c templ : oppor.Templates__r) {
              currencyECA = isECA (templ);
              lMoneyTranch.add(NBC_MinuteHandler.convertDataCurrency(templ.Expected_Final_Take1_number__c, getTrancheCurrency(templ.curncy_trans_year_one_type__c,currencyECA), mCurrType));
              lMoneyTranch.add(NBC_MinuteHandler.convertDataCurrency(templ.Expected_Final_Take2_number__c, getTrancheCurrency(templ.curncy_trans_year_two_type__c,currencyECA), mCurrType));
              lMoneyTranch.add(NBC_MinuteHandler.convertDataCurrency(templ.Expected_Final_Take3_number__c, getTrancheCurrency(templ.curncy_trans_year_three_type__c,currencyECA), mCurrType));
              lMoneyTranch.add(NBC_MinuteHandler.convertDataCurrency(templ.Expected_Final_Take4_number__c, getTrancheCurrency(templ.curncy_trans_year_four_type__c,currencyECA), mCurrType));

              templ.New_Money_for_BBVA1_desc__c = NBC_MinuteHandler.splitTo(templ.New_Money_for_BBVA1_desc__c, getTrancheCurrency(templ.curncy_trans_year_one_type__c,currencyECA), mCurrType);
              templ.New_Money_for_BBVA2_desc__c = NBC_MinuteHandler.splitTo(templ.New_Money_for_BBVA2_desc__c, getTrancheCurrency(templ.curncy_trans_year_two_type__c,currencyECA), mCurrType);
              templ.New_Money_for_BBVA3_desc__c = NBC_MinuteHandler.splitTo(templ.New_Money_for_BBVA3_desc__c, getTrancheCurrency(templ.curncy_trans_year_three_type__c,currencyECA), mCurrType);
              templ.New_Money_for_BBVA4_desc__c = NBC_MinuteHandler.splitTo(templ.New_Money_for_BBVA4_desc__c, getTrancheCurrency(templ.curncy_trans_year_four_type__c,currencyECA), mCurrType);
            }
            mFnlTkEUR.put(oppor.id, lMoneyTranch);
    }

    private String isECA (DES_Template__c templ) {
            String currencyECA;
            String stringECA;
            stringECA = 'ECA';
            String stringNULL;
            stringNULL = 'NULL';
            currencyECA = stringNULL;
            if(templ.RecordType.DeveloperName == stringECA ) {
              currencyECA = templ.CurrencyIsoCode;
            }

            return currencyECA;

    }

    private String getTrancheCurrency (String currTranche, String currencyECA) {
            String stringNULL;
            stringNULL = 'NULL';
            String currencyResult;
            currencyResult = currencyECA;

            if(currencyECA==stringNULL) {
              currencyResult = currTranche;
            }

            return currencyResult;
    }

}