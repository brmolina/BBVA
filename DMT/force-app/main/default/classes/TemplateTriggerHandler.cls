public without sharing  class TemplateTriggerHandler {
    final static String profileName = [SELECT Name FROM Profile WHERE Id = :userInfo.getProfileId() LIMIT 1].Name; //NOSONAR

    public static void updateOpportunityPendApp(List <DES_Template__c> triggerNew, Map<Id, DES_Template__c> triggerOldMap) {


        Map<Id,Opportunity> opps = getOpps(triggerNew);
        List<Opportunity> oppsToUpdate = new List<Opportunity>();
        List<String> lTemplateTab;
        lTemplateTab = new List<String>();

        for(DES_Template__c templ : triggerNew) {
            if((templ.Pending_approval_type__c != triggerOldMap.get(templ.id).Pending_approval_type__c) || (templ.Template_approved_type__c != triggerOldMap.get(templ.id).Template_approved_type__c)) {
                Opportunity aux = opps.get(templ.opportunity_id__c);
                aux.Template_pending_approval_type__c = templ.Pending_approval_type__c;
                aux.Template_approved_type__c = templ.Template_approved_type__c;
                oppsToUpdate.add(aux);
                // lTemplateTab.add(templ.Id);
            }
            lTemplateTab.add(templ.Id);
        }
        if(!oppsToUpdate.isEmpty()) {
            update oppsToUpdate;
        }

        if(!lTemplateTab.isEmpty()) {
            TemplateTableHandler.updateListTemplate(lTemplateTab);
        }
    }


     /**************************************************************************************
      * @Author:      Henry William Dorado
    * @Method:      corregirTextoPdf
    * @Return:
    * @Paramerers:  triggerNew lista de templates
    * @Description: corrige el texto de los campos que se despliegan en el PDF del template
    *****************************************************************************************/

     public static void corregirTextoPdf(List <DES_Template__c> triggerNew) {

        //se valida solo para el registro actual para evitar errores de data ya cargada

        List<WVL_ActivateConfigPdfTemplate__mdt> lstActivate  =  [SELECT DeveloperName,ActivateDate__c FROM WVL_ActivateConfigPdfTemplate__mdt limit 1];//NOSONAR

        if((triggerNew.size()==1&&lstActivate.size()>0&&lstActivate[0].ActivateDate__c<=triggerNew[0].createddate)||test.isrunningtest()) {//NOSONAR



                final DES_Template__c templ                               =  triggerNew[0];
                List<Recordtype> lstRecord;
                lstRecord=[select id,DeveloperName from recordtype where id=:templ.recordtypeid];
                String strRecordtypeName='CSL';

                if(lstRecord.size()>0) {    //NOSONAR
                    strRecordtypeName=lstRecord[0].DeveloperName;
                }

                //Ajusta el texto de los campos

                //Template_CSL
                templ.Purpose_desc__c                               =  corregirTexto(templ.Purpose_desc__c);
                templ.Rating_Scenarios_desc__c                      =  corregirTexto(templ.Rating_Scenarios_desc__c);
                templ.Other_Relevant_Issues_desc__c                 =  corregirTexto(templ.Other_Relevant_Issues_desc__c);
                templ.Main_characteristics_desc__c                  =  corregirTexto(templ.Main_characteristics_desc__c);
                templ.History_of_the_deal_desc__c                   =  corregirTexto(templ.History_of_the_deal_desc__c);
                templ.Security_Package_desc__c                      =  corregirTexto(templ.Security_Package_desc__c);
                templ.Competition_For_the_Deal_desc__c              =  corregirTexto(templ.Competition_For_the_Deal_desc__c);
                templ.Other_Relevant_Ratios_desc__c                 =  corregirTexto(templ.Other_Relevant_Ratios_desc__c);
                templ.Geographical_Footprint_desc__c                =  corregirTexto(templ.Geographical_Footprint_desc__c);
                templ.Relationship_Status_desc__c                   =  corregirTexto(templ.Relationship_Status_desc__c);
                templ.Industry_Overview_desc__c                     =  corregirTexto(templ.Industry_Overview_desc__c);
                templ.Qual_Assessment_of_Estimate_Revenue_desc__c   =  corregirTexto(templ.Qual_Assessment_of_Estimate_Revenue_desc__c);

                ////Oppties_Threats_Related_To_The_Deal__c
                //Template_PF
                templ.Other_Relevant_Information_desc__c            =  corregirTexto(templ.Other_Relevant_Information_desc__c);
                templ.Qualitative_Assesment_of_X_Sell_Rev_desc__c   =  corregirTexto(templ.Qualitative_Assesment_of_X_Sell_Rev_desc__c);
                templ.Main_Performance_Indicators_desc__c           =  corregirTexto(templ.Main_Performance_Indicators_desc__c);


                validarTexto(templ,strRecordtypeName);
                validarLongitud(templ,strRecordtypeName);

        }


    }


    /******************************************************************************
    * @Author:      Henry William Dorado
    * @Method:      validarTexto
    * @Return:
    * @Paramerers:  triggerNew lista de templates
    * @Description: valida el numero maximo de lineas por cada texto
    ***********************************************************************************/

    public static void validarTexto(DES_Template__c templ,String recordtype) {

        //valida la longitud de los campos de texto

        final List<WVL_ConfigPdfTemplate__mdt> lstConfigTemplate  =  [SELECT DeveloperName,WVL_fld_NombreCampo__c,WVL_fld_NumMaxCaracteresLinea__c,WVL_fld_NumMaximoLineas__c,CSL__c,CSL_Compass__c,ECA__c,GTB__c,PF__c FROM WVL_ConfigPdfTemplate__mdt limit 1000];

        //recorre los campos

        for(Integer i=0;i<lstConfigTemplate.size();i++) {
            final Integer intMaximoLineas                             =  Integer.ValueOf(lstConfigTemplate[i].get(recordtype+'__c') );
            final Integer intMaxCarLinea                              =  Integer.ValueOf(lstConfigTemplate[i].WVL_fld_NumMaxCaracteresLinea__c);

            //VALIDA EL TEXTO
            if(templ.get(lstConfigTemplate[i].WVL_fld_NombreCampo__c)!=null) {
                //carga el texto del campo
                final String valorCampo                                =  String.ValueOf(templ.get(lstConfigTemplate[i].WVL_fld_NombreCampo__c));
                final String[] arrTest                                 =  valorCampo.split('\n');
                Integer  intNumLienasTexto                       =  0;
                //carga el numero de lineas por salto
                intNumLienasTexto                                =  arrTest.size();

                for(Integer j=0;j<arrTest.Size();j++) {
                    //saca los caracteres de cada parrafo
                    final Integer intCaracteres                        =   arrTest[j].length();
                    final Integer intLineas                            =   intCaracteres/intMaxCarLinea;
                    //suma las lineas de cada parrafo
                    intNumLienasTexto                            =   intNumLienasTexto+intLineas;
                }

                system.debug('#campo#'+lstConfigTemplate[i].WVL_fld_NombreCampo__c);
                system.debug('#campo valor#'+valorCampo);
                system.debug('#campo lineas#'+intNumLienasTexto);
                system.debug('#campo lineas Maximo#'+intMaximoLineas);

                if(intNumLienasTexto>intMaximoLineas) {

                    templ.addError(system.label.WVL_lbl_TemplateTgrError+'['+Schema.getGlobalDescribe().get('DES_Template__c').getDescribe().fields.getMap().get(lstConfigTemplate[i].WVL_fld_NombreCampo__c).getDescribe().getLabel()+']');

                }

            }

        }



    }
    /******************************************************************************
    * @Author:      Daniel Herrero
    * @Method:      validarLongitud
    * @Return:
    * @Paramerers:  triggerNew lista de templates
    * @Description: valida el numero maximo de caracteres por cada texto
    ***********************************************************************************/

    public static void validarLongitud(DES_Template__c templ, String recordtype) {

        //valida la longitud de los campos de texto

        final List<WVL_ConfigTextLimitTemplate__mdt> lstConfigTemplate  =  [SELECT DeveloperName,WVL_fld_NombreCampo__c,CSL__c,CSL_Compass__c,ECA__c,GTB__c,PF__c FROM WVL_ConfigTextLimitTemplate__mdt limit 1000];

        //recorre los campos
        for(Integer i=0;i<lstConfigTemplate.size();i++) {
            final Integer intMaxLength                             =  Integer.ValueOf(lstConfigTemplate[i].get(recordtype+'__c') );

            //VALIDA EL TEXTO
            if(templ.get(lstConfigTemplate[i].WVL_fld_NombreCampo__c)!=null && intMaxLength != 0) {
                //carga el texto del campo
                final String valorCampo                                =  String.ValueOf(templ.get(lstConfigTemplate[i].WVL_fld_NombreCampo__c));
                final Integer  intNumTexto                       =  valorCampo.length();

                if(intNumTexto>intMaxLength) {
                    templ.addError(Schema.getGlobalDescribe().get('DES_Template__c').getDescribe().fields.getMap().get(lstConfigTemplate[i].WVL_fld_NombreCampo__c).getDescribe().getLabel()+' (max ' + Integer.ValueOf(lstConfigTemplate[i].get(recordtype+'__c') ) + ' characters)'); //NOSONAR
                }

            }

        }



    }
    /*****************************************************************************
    * @Author:      Henry William Dorado
    * @Method:      corregirTextoPdf
    * @Return:      cad                  cadena a corregir
    * @Paramerers:  String               cadena corregida
    * @Description: corrige el texto
    *******************************************************************************/

    public static String corregirTexto(String campo) {

        String cad     =  '';
        cad            =  campo;

        if(cad!=null) {


            while(cad.indexOf('  ')!=-1) {
                cad      =   cad.replace('  ',' ');
            }
            cad          =   cad.replace('\r','');
            cad          =   cad.replace('.\n\n','@PARRAFSALTO@');
            cad          =   cad.replace('.\n','@PARRAF@');
            cad          =   cad.replace('. \n','@PARRAF@');
            cad          =   cad.replace('\n',' ');
            cad          =   cad.replace('@PARRAF@','.\n');
            cad          =   cad.replace('@PARRAFSALTO@','.\n\n');


        }

        return cad;



    }




    public static void oppPendingToFalse(List <DES_Template__c> triggerOld) {

        Map<Id,Opportunity> opps = getOpps(triggerOld);

        for (DES_Template__c templ : triggerOld) {
            Opportunity aux = opps.get(templ.opportunity_id__c);
            aux.Template_pending_approval_type__c = false;
            opps.put(aux.id, aux);
        }

        update opps.values();
    }

    private static Map<Id, Opportunity> getOpps(List <DES_Template__c> listTemplates) {
        Set <Id> OppsId = new Set<Id>();
        for (DES_Template__c templ : listTemplates) {
            if(templ.opportunity_id__c != null) {
                OppsId.add(templ.opportunity_id__c);
            }
        }
        Map<Id,Opportunity> opps = new Map<ID, Opportunity>([SELECT id, Template_pending_approval_type__c, Template_approved_type__c from Opportunity where id IN :OppsId]);
        return opps;
    }

    /*
    *Busca a template hijos
    */
    public static void searchTableTemplate (List<DES_Template__c> listTemplates) {
        DES_Template_Table__c tabTempl;
        List<DES_Template_Table__c> lTabTempl;
        lTabTempl = new List<DES_Template_Table__c>();

        for(DES_Template__c tmp : listTemplates) {
            tabTempl = new DES_Template_Table__c();
            tabTempl.Parent_Template__c = tmp.id;

            // 22-11-24 Torcuato - Add PAWIF fields to NBC Template
            tabTempl.PAWIF_Simulation_Id__c = tmp.PAWIF_Simulation_Id__c;
            tabTempl.PAWIF_Simulation_URL__c = tmp.PAWIF_Simulation_URL__c;

            // 27-10-22 Torcuato Tejada - Add preloaded ESG info to template table
            tabTempl.gf_paris_agreement_ind_type__c = tmp.gf_paris_agreement_ind_type__c;
            tabTempl.gf_esg_score_close_ope_name__c = tmp.gf_esg_score_close_ope_name__c;
            tabTempl.gf_co_list_tcfd_ind_type__c = tmp.gf_co_list_tcfd_ind_type__c;
            tabTempl.gf_customer_sustnbl_strg_desc__c = tmp.gf_customer_sustnbl_strg_desc__c;
            tabTempl.Reputational_Risk_type__c = tmp.Reputational_Risk_type__c;
            tabTempl.cstk_tri_engagement_plan__c = tmp.cstk_tri_engagement_plan__c;
            tabTempl.cstk_positioning__c = tmp.cstk_positioning__c;
            tabTempl.cstk_group_alignment_degree__c = tmp.cstk_group_alignment_degree__c;
            tabTempl.cstk_sector_alignment_degree__c = tmp.cstk_sector_alignment_degree__c;
            tabTempl.cstk_emissions_intensity_units__c = tmp.cstk_emissions_intensity_units__c;
            tabTempl.cstk_sust_indicators_comments__c = tmp.cstk_sust_indicators_comments__c;
            tabTempl.Sectorial_Norms_type__c = tmp.Sectorial_Norms_type__c;
            // 08-06-23 Olatz - Add thermal coal fields
            tabTempl.cstk_g_thermal_coal_exps_ind_type__c = tmp.cstk_g_thermal_coal_exps_ind_type__c;
            tabTempl.cstk_g_thermal_coal_exps_i_src_type__c = tmp.cstk_g_thermal_coal_exps_i_src_type__c;
            tabTempl.cstk_g_coal_prgrsv_red_pl_ind_type__c = tmp.cstk_g_coal_prgrsv_red_pl_ind_type__c;
            tabTempl.cstk_gf_thermal_coal_rev_wg_per__c = tmp.cstk_gf_thermal_coal_rev_wg_per__c;
            tabTempl.cstk_gf_thermal_coal_prod_wg_per__c = tmp.cstk_gf_thermal_coal_prod_wg_per__c;
            // END 08-06-23 Olatz - Add thermal coal fields
            // tabTempl.gf_pitch_oppy_l12m_ibf_desc__c = template.gf_pitch_oppy_l12m_ibf_desc__c;
            // tabTempl.gf_pitch_oppy_l12m_gm_desc__c = template.gf_pitch_oppy_l12m_gm_desc__c;
            // tabTempl.gf_pitch_oppy_l12m_gtb_desc__c = template.gf_pitch_oppy_l12m_gtb_desc__c;

            lTabTempl.add(tabTempl);
        }
        insert lTabTempl;
    }

    /***************************************************************************************************
    * @Author:      David Rodriguez
    * @Method:      completeIndustry
    * @Return:
    * @Paramerers:  triggerNew lista de templates
    * @Description: Completa el campo Industry AA con el valor del Sector del cliente de la oportunidad
    ***************************************************************************************************/
    public static void completeIndustry (List<DES_Template__c> triggerNew) {
        final Map <Id, Id> templOpp = new Map <Id, Id>();
        final Set <Id> oppsId =  new Set <Id>();
        String sectorLabel;
        for(DES_Template__c templ : triggerNew) {
            if(templ.opportunity_id__c != null) {
                oppsId.add(templ.opportunity_id__c);
                templOpp.put(templ.Id, templ.opportunity_id__c);
            }
        }
        final Map <Id, Opportunity> mapOpps = new Map <Id, Opportunity>([
            SELECT Id, AccountId, Account.DES_AGGR_Sector__c
            FROM Opportunity
            WHERE Id IN :oppsId
        ]);

        for(DES_Template__c templ : triggerNew) {
            if(templOpp.get(templ.Id) != null && mapOpps.get(templOpp.get(templ.Id)) != null) {
                sectorLabel = Util_PickList.getLabelFromAPI('Account', 'DES_AGGR_Sector__c').get(mapOpps.get(templOpp.get(templ.Id)).Account.DES_AGGR_Sector__c);
                templ.Industry_AA_type__c = sectorLabel;
            }
        }
    }


     /***************************************************************************************************
    * @Author:      Maria Martinez
    * @Method:      isProspectClient
    * @Return:
    * @Paramerers:  triggerNew lista de templates
    * @Description: Pone a true el campo ProspectClient si es prospect el cliente de la oportunidad solo cuando se crea el template
                    para permitir cambiarlo manualmente
    ***************************************************************************************************/
    public static void isProspectClient (List<DES_Template__c> triggerNew) {
        final Map <Id, Id> templOpp = new Map <Id, Id>();
        final Set <Id> oppsId =  new Set <Id>();
        for(DES_Template__c templ : triggerNew) {
            if(templ.opportunity_id__c != null) {
                oppsId.add(templ.opportunity_id__c);
                templOpp.put(templ.Id, templ.opportunity_id__c);
            }
        }
        final Map <Id, Opportunity> mapOpps = new Map <Id, Opportunity>([
            SELECT Id, AccountId, Account.gf_cust_orig_prospect_ind_type__c
            FROM Opportunity
            WHERE Id IN :oppsId
        ]);

        for(DES_Template__c templ : triggerNew) {
            if(templOpp.get(templ.Id) != null && mapOpps.get(templOpp.get(templ.Id)) != null) {
                templ.DES_Prospect_Client__c = mapOpps.get(templOpp.get(templ.Id)).Account.gf_cust_orig_prospect_ind_type__c;
            }
        }
    }

    /***************************************************************************************************
    * @Author:      David Rodriguez
    * @Method:      checkEditIndustry
    * @Return:
    * @Paramerers:  triggerNew lista de templates
    * @Description: Añade una excepción si la persona que edita el campo no es Owner de la opp, del equipo de la opp o de S&P
    ***************************************************************************************************/
    public static void checkIndustryEdit (List<DES_Template__c> triggerNew, Map<Id, DES_Template__c> triggerOldMap) {
        final Set <Id> oppsId = new Set <Id>();

        for(DES_Template__c templ : triggerNew) {
            if(!oppsId.contains(templ.opportunity_id__c) && templ.opportunity_id__c != null) {
                oppsId.add(templ.opportunity_id__c);
            }
        }

        final Map <Id, String> oppMembers = auxFillMembers(oppsId);

        system.debug('++ oppMembers Users -> ' + JSON.serialize(oppMembers));

        for(DES_Template__c templ : triggerNew) {
            if(templ.Industry_AA_type__c != triggerOldMap.get(templ.Id).Industry_AA_type__c &&oppMembers!=null &&!oppMembers.isEmpty()&&oppMembers.get(templ.opportunity_id__c)!=null&& !oppMembers.get(templ.opportunity_id__c).contains(UserInfo.getUserId())
            && profileName != Label.DES_ADMIN_PROFILE && profileName != Label.DES_INTEGRATION_PROFILE) {
                templ.addError(Label.Error_Edit_Industry);
            }
        }
    }

    /***************************************************************************************************
    * @Author:      David Rodriguez
    * @Method:      auxFillMembers
    * @Return:      Map<id,String> id opp String con ids de miembros que pueden editar el campo Industry AA
    * @Paramerers:  set<Id> oppsId
    * @Description: Method que completa un mapa con el id de la oportunidad como clave y
                    un string que contiene los usuarios de SP y los miembros y el owner de la opp
                    ***************************************************************************************************/
    private static Map <Id, String> auxFillMembers(Set <Id> oppsId) {
        final Map <Id, String> oppMembers = new Map <Id, String>();
        final List <User> spUsers = new List <User>([
            SELECT Id FROM User WHERE Profile.Name = :Label.DES_SP_PROFILE
        ]);

        for(DES_Opportunity_Management_member__c oppMemb : [SELECT Id, DES_User__c, DES_Opportunity__c, DES_Opportunity__r.OwnerId FROM DES_Opportunity_Management_member__c Where DES_Opportunity__c IN :oppsId]) {
            if(oppMembers.get(oppMemb.DES_Opportunity__c) == null) {
                oppMembers.put(oppMemb.DES_Opportunity__c,oppMemb.DES_Opportunity__r.OwnerId);
            } else {
                String cadenaUsers = oppMembers.get(oppMemb.DES_Opportunity__c);
                if(!cadenaUsers.contains(oppMemb.DES_User__c)) {
                    cadenaUsers = cadenaUsers + '//' + oppMemb.DES_User__c;
                }
                oppMembers.put(oppMemb.DES_Opportunity__c,cadenaUsers);
            }
        }

        for(Id oppId : oppMembers.keySet()) {
            String cadenaUsers = oppMembers.get(oppId);
            for(User user : spUsers) {
                cadenaUsers = cadenaUsers + '//' + user.Id;
            }
            oppMembers.put(oppId, cadenaUsers);
        }

        return oppMembers;
    }

    /***************************************************************************************************
    * @Author:      David Rodriguez
    * @Method:      auxFillMembers
    * @Return:      Map<id,String> id opp String con ids de miembros que pueden editar el campo Industry AA
    * @Paramerers:  set<Id> oppsId
    * @Description: Method que completa un mapa con el id de la oportunidad como clave y
                    un string que contiene los usuarios de SP y los miembros y el owner de la opp
    ***************************************************************************************************/
    public static void completeBooking(List<DES_Template__c> triggerNew) {

        final Set <Id> oppsIds = new Set<Id>();

        for(DES_Template__c templ : triggerNew) {
            oppsIds.add(templ.opportunity_id__c);
        }
        final Map<Id, Opportunity> mapOpps = new Map<Id, Opportunity>([SELECT Id, DES_Booking_Geography__c from Opportunity Where Id IN :oppsIds]);

        for(DES_Template__c templ : triggerNew) {
            if(mapOpps.get(templ.opportunity_id__c).DES_Booking_Geography__c != null) {
                templ.Booking_label__c = Util_PickList.getLabelFromAPI('Opportunity', 'DES_Booking_Geography__c').get(mapOpps.get(templ.opportunity_id__c).DES_Booking_Geography__c);
            }
        }
    }

    /***************************************************************************************************
    * @Author:      Aitor Martin
    * @Method:      createChatter
    * @Return:
    * @Paramerers:  List<DES_Template__c> triggerNew
    * @Description: Method que crea un objeto del tipo Chatter NBC Virtual por cada template creado.
    ***************************************************************************************************/
    public static void createChatter(List<DES_Template__c> triggerNew) {
        if(!triggerNew.isEmpty()) {
            List<Chatter_NBC_Virtual__c> lstChat = new List<Chatter_NBC_Virtual__c>();//NOSONAR
            for(DES_Template__c template : triggerNew) {
                Chatter_NBC_Virtual__c chat = new Chatter_NBC_Virtual__c(); //NOSONAR
                chat.id_objeto__c = template.Id;
                chat.tipo_objeto__c = 'DES_Template__c';
                lstChat.add(chat);
            }
            System.debug('lstChat Chatters creados----------------------------------------> '+lstChat);
            if(!lstChat.isEmpty()) {
                insert lstChat;
            }
        }
    }

    /***************************************************************************************************
    * @Author:      Aitor Martin
    * @Method:      deleteChatter
    * @Return:
    * @Paramerers:  List<DES_Template__c> triggerOld
    * @Description: Method que elimina el objeto del tipo Chatter NBC Virtual por cada template eliminado.
    ***************************************************************************************************/
    public static void deleteChatter(List<DES_Template__c> triggerOld) {
        Set <Id> templateId = new Set<Id>(); //NOSONAR
        for (DES_Template__c templ : triggerOld) {
            TemplateId.add(templ.Id);
        }
        final List<Chatter_NBC_Virtual__c> lstChatter = [SELECT id, id_objeto__c FROM Chatter_NBC_Virtual__c WHERE id_objeto__c = :TemplateId];
        delete lstChatter;
    }

}