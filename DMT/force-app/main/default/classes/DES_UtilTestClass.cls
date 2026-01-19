/*----------------------------------------------------------------------------------------------
    Description:    Creacion de datos dummy para los Tests de los desarrollos de Desktop.

    History:
    <Date>          <Author>                <Description>
    01/08/2018
-----------------------------------------------------------------------------------------------*/
public with sharing class DES_UtilTestClass {
    /**
    public Id getRecordTypeId ( String recordTypeLabel ) {
        return Schema.SObjectType.Account_Campaign__c.getRecordTypeInfosByName().get( recordTypeLabel ).getRecordTypeId();
    }
    */

    /* Nuevo cliente */
    public Account createClient() {
        Account acc = new Account();
        acc.Name = 'Test Client';
        acc.Phone = '646171717';
        acc.DES_Revenue_Update_Engloba__c = '20180912';
		acc.DES_Country_Client__c = 'ES';
        acc.account_client__c = 'N';
        return acc;
    }

    public Account createClient( String name, String idFiscal, Map<String, User> usersByTeamMemberRole) {

        Account cliente = new Account(

                Name = name,
                Phone = '987678654',
                DES_Revenue_Update_Engloba__c = '20190912',
                DES_BBVA_Segmentation__c = 'B',
                DES_ID_Fiscal__c = idFiscal,
				DES_Country_Client__c = 'ES'
                //salesforce_unified_external_id__c = idFiscal

        );

        if ( usersByTeamMemberRole != null && usersByTeamMemberRole.get(Label.DES_ROLE_GLOBAL_BANKER) != null ) {
            cliente.DES_Global_banker__c = usersByTeamMemberRole.get(Label.DES_ROLE_GLOBAL_BANKER).Id;
        }

        insert cliente;

        if ( usersByTeamMemberRole != null ) {
            // Adjuntar miembros de la cuenta
            final List<DES_BBVA_Management_team__c> teamMembers = new List<DES_BBVA_Management_team__c>();
            DES_BBVA_Management_team__c teamMember;

            for ( String roleUser: usersByTeamMemberRole.keySet() ) {

                teamMember = createBBVAManagementTeamMember( usersByTeamMemberRole.get( roleUser ), cliente );
                teamMember.DES_Member_Role__c = roleUser;
                teamMembers.add(teamMember);

            }

            insert teamMembers;
        }

        return cliente;

    }



    /**
     * Crea una cuenta de grupo y la relaciona con las cuentas y globalbenker pasados por parámetro
     *
     * @param groupAccountName : nombre de la cuenta de grupo
     * @param relatedAccountIds : null o cuentas que se relacionan con la cuenta de grupo
     * @param globalBankerUserId : userId del globalbanker que se asociará a la cuenta de grupo.
     *
     * @return : cuenta de grupo creada
     */
    public Account createGroupClient( String groupAccountName, Set<Id> relatedAccountIds, Id globalBankerUserId ) {

        Account groupAccount = new Account (
                Name = groupAccountName,
                DES_Structure_Type__c = 'Group',
                DES_BBVA_Segmentation__c = 'C'
        );
        insert groupAccount;

        DES_BBVA_Management_team__c globalBankerMember;
        if ( globalBankerUserId != null ) {

            globalBankerMember = new DES_BBVA_Management_team__c(
                    DES_User__c = globalBankerUserId,
                    DES_Client__c = groupAccount.Id,
                    DES_Member_Role__c = Label.DES_ROLE_GLOBAL_BANKER,
                    Name = 'globalBanker - ' + groupAccountName
            );
            insert globalBankerMember;

            groupAccount.DES_Global_Banker_Ref__c = globalBankerMember.Id;
            groupAccount.DES_Global_banker__c = globalBankerUserId;

            update groupAccount;

        }

        if ( relatedAccountIds != null ) {

            final List<DES_Subsidiary_Group_Relation__c> matrixList = new List<DES_Subsidiary_Group_Relation__c>();
            DES_Subsidiary_Group_Relation__c matrix;

            for ( Id accountId : relatedAccountIds) {
                matrix = new DES_Subsidiary_Group_Relation__c();
                matrix.participant_child_id__c = accountId;
                matrix.main_subsidiary_ind_type__c = true;
                matrix.participant_parent_id__c = groupAccount.Id;
                matrixList.add( matrix );
            }
            insert matrixList;

        }

        return groupAccount;

    }

    /**
     * Realiza el borrado de las cuentas de grupo, y de todos sus registros
     * en la group_Subsidiary_Matrix
     *
     * @param groupClientNames : Lista de nombres del clientes de grupo (exactos y únicos).
     *
     * @return : true si la operación se realiza con éxito, false en caso contrario
     */
    public Boolean deleteGroupClient ( Set<String> groupClientNames) {

        Boolean success = true;
        try {

            final Map<Id, Account> groupClientById = new Map<Id, Account> ([SELECT Id FROM Account WHERE name IN :groupClientNames]);

            // Borrar relaciones de la matriz
            final List<DES_Subsidiary_Group_Relation__c> matrixToDelete = [SELECT Id FROM DES_Subsidiary_Group_Relation__c WHERE participant_parent_id__c IN :groupClientById.keySet() AND main_subsidiary_ind_type__c = true];

            if ( !matrixToDelete.isEmpty() ) {
                delete matrixToDelete;
            }

            delete groupClientById.values();

        } catch (Exception e) {
            System.debug('@@> el borrado del clientes de grupo no pudo completarse con éxito :(');
            success = false;
        }
        return success;

    }

    public dwp_kitv__Visit_Management_Team__c createVisitTM(User user, dwp_kitv__Visit__c visit) {
        dwp_kitv__Visit_Management_Team__c visitTeamMember = new dwp_kitv__Visit_Management_Team__c();
        visitTeamMember.DES_Member_Role__c = Label.DES_Role_Risk_Analyst;
        visitTeamMember.dwp_kitv__user_id__c = user.Id;
        visitTeamMember.dwp_kitv__visit_id__c = visit.Id;
        return visitTeamMember;
    }

    /**
     * Global Desktop
     */
    public dwp_acmh__GBL_Account_Relationship__c createAccRelationship(Account accParent, Account accChild) {
        dwp_acmh__GBL_Account_Relationship__c rel = new dwp_acmh__GBL_Account_Relationship__c();
        rel.dwp_acmh__Child_Account__c = accChild.Id;
        rel.dwp_acmh__Parent_Account__c = accParent.Id;
        rel.DES_Participacion__c = 80;
        rel.CurrencyIsoCode = 'EUR';
        rel.DES_Main_Parent__c = 'S';
        rel.dwp_acmh__Type__c = '03 - Filial';
        rel.dwp_acmh__Vision__c = 'Negocio';
        return rel;
    }

    /**
     * Global Desktop
     */
    public DES_Denorm_AccountVisits__c createDenVisit(Account acc, dwp_kitv__Visit__c vis) {
        DES_Denorm_AccountVisits__c denVis = new DES_Denorm_AccountVisits__c();
        denVis.DES_Client__c = acc.Id;
        denVis.DES_Visit_new__c = vis.Id;
        return denVis;
    }

    /**
     * Global Desktop
     */
    public dwp_kitv__Visit_Contact__c visitContact(Contact contact, dwp_kitv__visit__c visit) {
        dwp_kitv__Visit_Contact__c visCon = new dwp_kitv__Visit_Contact__c();
        visCon.dwp_kitv__contact_id__c = contact.Id;
        visCon.dwp_kitv__visit_id__c = visit.Id;
        return visCon;
    }

    /**
     * Global Desktop
	 *
	 *   2019/09/18 [JJS]  DES_Scope__c = DES_Country_Client__c
     */
    public Contact createContact(Account acc) {
        Contact con = new Contact();
        con.AccountId = acc.Id;
        con.Phone = '666000011';
        con.Email = 'example@none.es';
        con.FirstName = 'FirstName';
        con.LastName = 'LastName';
    	//con.DES_Scope__c = acc.DES_Country_Client__c ;

        return con;
    }

    /**
     * Global Desktop
     */
    public dwp_kitv__Visit_Management_Team__c createVisitManagementTeam(dwp_kitv__Visit__c visit, User user) {
        dwp_kitv__Visit_Management_Team__c visitMMT = new dwp_kitv__Visit_Management_Team__c();
        visitMMT.dwp_kitv__visit_id__c = visit.Id;
        //visitMMT.dwp_kitv__user_id__c = user.Id;
        return visitMMT;
    }

    /**
     * Global Desktop
     */
    //Nueva oportunidad
    public Opportunity createOpportunity(Account acc) {
        Opportunity opp = new Opportunity();
        opp.Name = 'Test Opportunity';
        opp.DES_Description_rich__c = 'Oportunidad para clase de test';
        opp.DES_Countries__c = 'AR';
        opp.AccountId = acc.Id;
        opp.CloseDate = Date.today();
        opp.StageName = Label.DES_Draft;
        opp.Probability = 5;
        opp.Amount = 5;
        opp.CurrencyIsoCode = 'EUR';
        opp.DES_Cross_border__c = true;
        //opp.pre_oppy_revenue_next_12m_amount__c = 5;
        opp.DES_Expected_Probability__c = 5;
        opp.DES_Amount__c = 5;
        opp.DES_Booking_Geography__c = 'AR';

        opp.Pricebook2Id = Test.getStandardPricebookId();
        return opp;
    }

    /**
     * Global Desktop
     */
    //Nuevo producto
    public Product2 createProduct(String productName) {
        Product2 prod = new Product2();
        prod.Name = productName;
        prod.isActive = true;
        prod.Family = 'GTB';
        return prod;
    }

    /**
     * Global Desktop
     */
    public fprd__GBL_Product_version__c createVersionProduct(Product2 prod) {
        fprd__GBL_Product_version__c prodv = new fprd__GBL_Product_version__c();
        prodv.fprd__Product__c = prod.id;
        prodv.fprd__Active__c = true;
        prodv.fprd__Version_number__c = 1;
        return prodv;
    }

    /**
     * Global Desktop
     */
    //Nuevo Opportunity Product
    public OpportunityLineItem createOppLineItem(Opportunity opp, Product2 prod, PricebookEntry pbookEntry) {
        OpportunityLineItem oppLineIt = new OpportunityLineItem();
        oppLineIt.OpportunityId = opp.Id;
        oppLineIt.Product2Id = prod.Id;
        oppLineIt.PricebookEntryId = pbookEntry.Id;
        oppLineIt.TotalPrice = 1;
        oppLineIt.Quantity = 1;
        return oppLineIt;
    }

    /**
     * Global Desktop
     */
    //Completar los datos de Opportunity Product
    public OpportunityLineItem updateOppLineItem (OpportunityLineItem oppLineItemTest, User userTest) {

        oppLineItemTest.DES_All_In__c = 5;
        oppLineItemTest.pre_gross_margin_next_12m_per__c = 5;
        oppLineItemTest.country_name__c = 'Asia';
        oppLineItemTest.oppy_asset_level_1_name__c = 'Energy';
        oppLineItemTest.oppy_asset_level_2_name__c = 'Power&Oil';
        oppLineItemTest.bbva_prtcp_tranche_amount__c = 5;
        oppLineItemTest.syndicated_loan_drawn_amount__c = 5;
        oppLineItemTest.entity_role_type__c = 'Agent';
        oppLineItemTest.classification_cib_banker_type__c = 'BIBEC Banker';
        oppLineItemTest.opportunity_name__c = 'Line';
        oppLineItemTest.DES_Booking_ID__c = 'Booking ID';
        oppLineItemTest.DES_Booking_System__c = 'Booking System';
        oppLineItemTest.participant_name__c = 'Test Text';
        oppLineItemTest.customer_cib_ind_type__c = 'No';
        oppLineItemTest.participant_role_desc__c = 'Exporter';
        oppLineItemTest.customer_type__c = 'CIB';
        oppLineItemTest.DES_Contract_Signed__c = true;
        oppLineItemTest.counterparty_name__c = 'Counterpart Name';
        oppLineItemTest.counterparty_country_id__c = 'AB';
        oppLineItemTest.counterparty_rol_name__c = 'Exporter';
        oppLineItemTest.loan_export_cr_agncy_cntrb_per__c = 5;
        oppLineItemTest.export_credit_agency_name__c = 'Cesce';
        oppLineItemTest.deal_total_amount__c = 5;
        oppLineItemTest.DES_Gross_Spread__c = 5;
        oppLineItemTest.oppy_substage_mandate_date__c = Date.Today();
        oppLineItemTest.DES_Mandate_Signed__c = true;
        oppLineItemTest.opportunity_nbc_recm_date__c = Date.Today();
        oppLineItemTest.opportunity_nbc_recm_ind_type__c = 'Yes';
        oppLineItemTest.opportunity_nbc_recm_ind_type__c = 'Yes';
        oppLineItemTest.product_scope_type__c = 'CIB';
        oppLineItemTest.opportunity_nbc_recm_date__c = Date.Today();
        oppLineItemTest.origin_country_name__c = 'China';
        oppLineItemTest.DES_Origination_Geography__c = 'Asia';
        //oppLineItemTest.DES_Product_Specialist__c  = userTest.Id;
        oppLineItemTest.pre_oppy_revenue_next_12m_amount__c = 5;
        oppLineItemTest.oppy_pricing_cmtee_aprvl_date__c = Date.Today();
        oppLineItemTest.oppy_pricing_cmtee_rspse_type__c = 'N.A.';
        oppLineItemTest.subproduct_name__c = 'Product';
        oppLineItemTest.DES_Proposal_Status__c = 'Mandated';
        oppLineItemTest.DES_RaR_Expected_Before_Cost_Funding__c = 5;
        oppLineItemTest.DES_RaR_Expected_Post_Cost_of_Funding__c = 5;
        oppLineItemTest.regional_area_name__c = 'BEC Norte';
        oppLineItemTest.risk_committee_aprvl_ind_type__c = Label.DES_YES;
        oppLineItemTest.risk_committee_approval_date__c = Date.Today();
        oppLineItemTest.gf_oppy_counterparty_risk_per__c = 50;
        oppLineItemTest.proposal_requested_ind_type__c = 'Yes';
        oppLineItemTest.oppy_product_ctrct_comt_date__c = Date.Today();
        oppLineItemTest.signing_date__c = Date.Today();
        oppLineItemTest.solution_name_path_desc__c = 'SCF - Reverse factoring';
        oppLineItemTest.fee_next_12m_amount__c = 5;
        oppLineItemTest.loan_tenor_month_desc__c = 5;
        oppLineItemTest.opportunity_tenor_years_number__c = 5;
        oppLineItemTest.DES_Type_of_Project__c = 'Acquisition';
        oppLineItemTest.underwriting_agreement_type__c = Label.DES_No;
        oppLineItemTest.oppy_undwr_cmtee_approval_date__c = Date.Today();
        oppLineItemTest.oppy_undwr_cmtee_rspse_type__c = 'N.A.';
        oppLineItemTest.opening_fee_per__c = 5;
        return oppLineItemTest;
    }

    /**
     * Global Desktop
     */
    //Nuevo Price book
    public Pricebook2 createPricebook() {
        Pricebook2 pricebookTest = new Pricebook2();
        pricebookTest.Name = 'Test Pricebook';
        pricebookTest.IsActive = true;
        return pricebookTest;
    }
    /**

     * Global Desktop
     */
    //Nuevo pricebookEntry
    public PricebookEntry createPricebookEntry(Product2 prod) {
        Id pricebookId = Test.getStandardPricebookId();
        PricebookEntry pricebookentryTest = new PricebookEntry();
        pricebookentryTest.isActive = true;
        pricebookentryTest.Pricebook2Id = Test.getStandardPricebookId();
        pricebookentryTest.Product2Id = prod.Id;
        pricebookentryTest.UnitPrice = 1;
        return pricebookentryTest;
    }

    /**
     * Global Desktop
     */
    //Nuevo Opportunity Team Member
    public OpportunityTeamMember oppTeamMember(Opportunity oppTest, User userTest) {
        OpportunityTeamMember oppTeamMemberTest = new OpportunityTeamMember();
        oppTeamMemberTest.OpportunityId = oppTest.Id;
        oppTeamMemberTest.TeamMemberRole = 'Local Banker';
        oppTeamMemberTest.UserId = userTest.Id;
        return oppTeamMemberTest;
    }

    /**
     * Global Desktop
     */
    //Nuevo perfil
     public String createProfile() {
        String profileTest = userinfo.getProfileId();
        return profileTest;
    }

    /**
     * Global Desktop
     */
    //Nuevo usuario
    public User createUser(String profileTest){
        final Desktop_Utils util = Desktop_Utils.getInstance();
        User userTest = new User();
        userTest.ProfileId = profileTest;
        userTest.FirstName = 'User Name Test';
        userTest.LastName = 'User Last Name Test';
        userTest.Alias = 'ATest';
        userTest.Email = 'useremail@test.comm';
        userTest.ID_User__c = string.valueOf(system.now() - Math.abs(Math.random()*10));
        userTest.FederationIdentifier = userTest.ID_User__c;
        userTest.username = String.valueof(Math.random()*10) + String.valueof(DateTime.now().getTime()) + '@test.comm';
        userTest.CommunityNickname = String.valueof(datetime.now().getTime());
        userTest.EmailEncodingKey = 'UTF-8';
        userTest.Timezonesidkey='Europe/London';
        userTest.Localesidkey ='en_US';
        userTest.languagelocalekey='en_US';
        return userTest;
    }

    /**
     * Global Desktop
     */
    public User createUser(String profileTest, String username) {
        User userTest = new User();
        userTest.ProfileId = profileTest;
        userTest.FirstName = 'User Name Test';
        userTest.LastName = 'User Last Name Test';
        userTest.Alias = 'ATest';
        userTest.Email = 'useremail@test.comm';
        userTest.ID_User__c = string.valueOf(system.now() - Math.abs(Math.random()*10));
        userTest.FederationIdentifier = userTest.ID_User__c;
        userTest.username= String.valueof(DateTime.now().getTime()) + username;
        userTest.CommunityNickname = username;
        userTest.EmailEncodingKey = 'UTF-8';
        userTest.Timezonesidkey='Europe/London';
        userTest.Localesidkey ='en_US';
        userTest.languagelocalekey='en_US';
        return userTest;
    }

    /**
     * Global Desktop
     */
    public User createUserWithProfileName(String profileNameTest, String username) {
        User userTest = new User();
        userTest.Dataloader_Profile_Name__c = profileNameTest;
        userTest.FirstName = 'User Name Test';
        userTest.LastName = 'User Last Name Test';
        userTest.Alias = 'ATest';
        userTest.Email = 'useremail@test.comm';
        userTest.ID_User__c = string.valueOf(system.now() - Math.abs(Math.random()*10));
        userTest.username= username;
        userTest.CommunityNickname = username;
        userTest.EmailEncodingKey = 'UTF-8';
        userTest.Timezonesidkey='Europe/London';
        userTest.Localesidkey ='en_US';
        userTest.languagelocalekey='en_US';
        return userTest;
    }

    /**
     * Global Desktop
     */
    //Nuevo Opportunity Management Member
    public DES_Opportunity_Management_member__c createOppManagementMember(User userTest, Opportunity oppTest) {
        DES_Opportunity_Management_member__c oppManagementMemberTest = new DES_Opportunity_Management_member__c();
        oppManagementMemberTest.Name = 'User Test';
        oppManagementMemberTest.DES_User__c = userTest.Id;
        oppManagementMemberTest.DES_Opportunity__c = oppTest.Id;
        return oppManagementMemberTest;
    }

    /**
     * Global Desktop
     */
    //Nuevo BBVA Management Team Member
    public DES_BBVA_Management_team__c createBBVAManagementTeamMember(User userTest, Account acc) {
        DES_BBVA_Management_team__c bbvaManagementTeamMember = new DES_BBVA_Management_team__c();
        bbvaManagementTeamMember.Name = 'User Test';
        bbvaManagementTeamMember.DES_User__c = userTest.Id;
        bbvaManagementTeamMember.DES_Client__c = acc.Id;
        return bbvaManagementTeamMember;
    }

    /**
     * Global Desktop
     */
    //Nueva User Custom Setting
    public CIB_User_Org__c createCustomSetting() {
        CIB_User_Org__c userSettings = new CIB_User_Org__c();
        userSettings.CIB_Is_Desktop__c = true;
        return userSettings;
    }

    /**
     * Global Desktop
     */
    //Nueva Visita
    public dwp_kitv__Visit__c createVisit(Account acc, Opportunity opp) {
        dwp_kitv__Visit__c vis = new dwp_kitv__Visit__c();
        vis.dwp_kitv__account_id__c= acc.Id;
        //vis.DES_Opportunity__c = opp.Id;
        vis.Name = 'VISIT TEST';
        vis.dwp_kitv__visit_duration_number__c = '15';
        vis.dwp_kitv__visit_start_date__c = Date.today();
        return vis;
    }

    /**
     * Global Desktop
     */
    //Nuevo VisitTopic
    public dwp_kitv__Visit_Topic__c createVisitTopic(dwp_kitv__Visit__c vis, Opportunity opp) {
        dwp_kitv__Visit_Topic__c visTopic = new dwp_kitv__Visit_Topic__c();
        visTopic.dwp_kitv__visit_id__c = vis.Id;
        visTopic.dwp_kitv__opportunity_id__c = opp.id;
        visTopic.dwp_kitv__topic_desc__c = 'VISIT TOPIC TEST';
        return visTopic;
    }

    /**
     * Global Desktop
     */
    //CREATE NUEVO BOOKING
    public DES_Booking__c createBooking(Account acc, String country, String region, Decimal revenues, String type, String year) {

        DES_Booking__c boo = new DES_Booking__c();
        boo.DES_Client__c = acc.Id;
        boo.DES_Country__c = country;
        boo.DES_Region__c = region;
        boo.DES_Revenues__c = revenues;
        boo.DES_Type__c = type;
        boo.DES_Year__c = year;
        return boo;

    }

    /**
     * Global Desktop
     */
    // nueva Alerta Comercial
    public almd__Commercial_Alert__c createAlert(User user1, User user2, Account acc, Integer i, String rt) {
        almd__Commercial_Alert__c comAl1 = new almd__Commercial_Alert__c(); //NOSONAR
        comAl1.Name = 'Prueba Alerta'+i;
        comAl1.almd__owner_access_alert_id__c = user1.ID_User__c;
        comAl1.almd__User_id__c = user2.Id;
        comAl1.almd__commercial_alert_id__c = 'Id'+i;
        comAl1.almd__participant_id__c = acc.id;
        comAl1.almd__commercial_alert_start_date__c = system.today();
        comAl1.almd__commercial_alert_end_date__c = system.today();
        comAl1.almd__commercial_alert_record_type__c = rt;
        comAl1.almd__commercial_alert_desc__c = 'Prueba1';
        comAl1.almd__priority_alert_type__c = 'High';
        comAl1.almd__data_source_name__c = 'Test';
        comAl1.almd__commercial_alert_task_type__c = 'backup';
        return comAl1;
    }

    /*
    * Global Desktop
    */
    public altm__Commercial_Alert__c createNewAlert(User user1, User user2, Account acc, Integer iaux, String rtype) {
        altm__Commercial_Alert__c comAl1 = new altm__Commercial_Alert__c();
        comAl1.Name = 'Prueba Alerta'+iaux;
        comAl1.altm__owner_access_alert_id__c = user1.ID_User__c;
        comAl1.altm__User_id__c = user2.Id;
        comAl1.altm__commercial_alert_id__c = 'Id'+iaux;
        comAl1.altm__participant_id__c = acc.id;
        comAl1.altm__commercial_alert_start_date__c = system.today();
        comAl1.altm__commercial_alert_end_date__c = system.today();
        comAl1.altm__commercial_alert_record_type__c = rtype;
        comAl1.altm__commercial_alert_desc__c = 'Prueba';
        comAl1.altm__priority_alert_type__c = 'High';
        comAl1.altm__data_source_name__c = 'Test';
        comAl1.altm__commercial_alert_task_type__c = 'backup';
        return comAl1;
    }

    /**
     * Global Desktop
     */
    // nuevo Matriz de Global banker
    public DES_Subsidiary_Group_Relation__c createMatrix(Account acc) {
        DES_Subsidiary_Group_Relation__c matrix = new DES_Subsidiary_Group_Relation__c();
        matrix.participant_child_id__c = acc.Id;
        matrix.main_subsidiary_ind_type__c = true;
        return matrix;
    }

    /**
     * Global Desktop ----Campañas

    //Nueva account campaign
	public Account_Campaign__c createAccountCampaign() {
		Account_Campaign__c accountCampaign = new Account_Campaign__c();
		accountCampaign.Name = 'AC1';
		accountCampaign.campaign_load_id__c = 'campaign id load 1';
		accountCampaign.participant_load_id__c = 'client id load 1';
		accountCampaign.taxpayer_id__c = 'id fiscal 1';
		accountCampaign.participant_name__c = 'client name 1';
		accountCampaign.campaign_name__c = 'campaign name 1';
		accountCampaign.priority_campaign_type__c = 'High';
        accountCampaign.solution_category_name__c = 'pdto1,pdt2,pdto3';
        accountCampaign.solution_category_type__c = 'FAMtest';
        accountCampaign.data_source_name__c = 'Test data source';
        accountCampaign.campaign_desc__c = 'Test campaign description';
        accountCampaign.DES_Country_Client__c = 'ES';
		return accountCampaign;
	}
     */

    /**
     * Global Desktop
     */
    public DES_Template__c createTemplate(Opportunity opp, OpportunityLineItem oppLineItem) {
    	DES_Template__c template = new DES_Template__c();
        template.opportunity_id__c = opp.id;
        template.Name = 'Prueba';
        template.Opportunity_Product_Id__c = oppLineItem.id;
        template.Transaction_Deal_Amount1_number__c = 5;
        template.Transaction_Deal_Amount2_number__c = 5;
        template.Transaction_Deal_Amount3_number__c = 5;
        template.Transaction_Deal_Amount4_number__c = 5;
        template.BBVA_Commitment1_number__c = 5;
        template.BBVA_Commitment2_number__c = 5;
        template.BBVA_Commitment3_number__c = 5;
        template.BBVA_Commitment4_number__c = 5;
        template.Expected_Final_Take1_number__c = 5;
        template.Expected_Final_Take2_number__c = 5;
        template.Expected_Final_Take3_number__c = 5;
        template.Expected_Final_Take4_number__c = 5;
        template.Sub_limit_if_any1_number__c = 5;
        template.Sub_limit_if_any2_number__c = 5;
        template.Sub_limit_if_any3_number__c = 5;
        template.Sub_limit_if_any4_number__c = 5;
        template.New_Money_for_BBVA1_desc__c = '5';
        template.New_Money_for_BBVA2_desc__c = '5';
        template.New_Money_for_BBVA3_desc__c = '5';
        template.New_Money_for_BBVA4_desc__c = '5';
        template.Old_Money_for_BBVA1_desc__c = '5';
        template.Old_Money_for_BBVA2_desc__c = '5';
        template.Old_Money_for_BBVA3_desc__c = '5';
        template.Old_Money_for_BBVA4_desc__c = '5';
        template.New_Up_Front_Fee1_desc__c = '5';
        template.New_Up_Front_Fee2_desc__c = '5';
        template.New_Up_Front_Fee3_desc__c = '5';
        template.New_Up_Front_Fee4_desc__c = '5';
        template.New_Applicable_Margin1_desc__c = '5';
        template.New_Applicable_Margin2_desc__c = '5';
        template.New_Applicable_Margin3_desc__c = '5';
        template.New_Applicable_Margin4_desc__c = '5';
        template.New_Commitment_Fee1_desc__c = '5';
        template.New_Commitment_Fee2_desc__c = '5';
        template.New_Commitment_Fee3_desc__c = '5';
        template.New_Commitment_Fee4_desc__c = '5';
        template.Debt_Funds_Num_1_number__c = 5;
        template.Debt_Funds_Num_2_number__c = 5;
        template.Debt_Funds_Num_3_number__c = 5;
        template.Debt_Funds_Num_4_number__c = 5;
        template.Debt_Funds_Num_5_number__c = 5;
        template.Uses_num_1_number__c = 5;
        template.Uses_num_2_number__c = 5;
        template.Uses_num_3_number__c = 5;
        template.Uses_num_4_number__c = 5;
        template.Uses_num_5_number__c = 5;
        template.Uses_num_6_number__c = 5;
        template.Uses_num_7_number__c = 5;
        template.Uses_num_8_number__c = 5;
        template.Uses_num_9_number__c = 5;
        template.Uses_num_10_number__c = 5;
        template.Uses_num_11_number__c = 5;
        template.Equity_Funds_num_1_number__c = 5;
        template.Equity_Funds_num_2_number__c = 5;
        template.Equity_Funds_num_3_number__c = 5;
        template.Equity_Funds_num_4_number__c = 5;
        template.Revenues_Last_Year_number__c = 5;
        template.Revenues_Current_Year_number__c = 5;
        template.Revenues_Next_Year_number__c = 5;
        template.Revenues_Next_Year_1_number__c = 5;
        template.Revenues_Next_Year_2_number__c = 5;
        template.EBITDA_Last_Year_number__c = 5;
        template.EBITDA_Current_Year_number__c = 5;
        template.EBITDA_Next_Year_number__c = 5;
        template.EBITDA_Next_Year_1_number__c = 5;
        template.EBITDA_Next_Year_2_number__c = 5;
        template.EBIT_Last_Year_number__c = 5;
        template.EBIT_Current_Year_number__c = 5;
        template.EBIT_Next_Year_number__c = 5;
        template.EBIT_Next_Year_1_number__c = 5;
        template.EBIT_Next_Year_2_number__c = 5;
        template.Net_Income_Last_Year_number__c = 5;
        template.Net_Income_Current_Year_number__c = 5;
        template.Net_Income_Next_Year_number__c = 5;
        template.Net_Income_Next_Year_1_number__c = 5;
        template.Net_Income_Next_Year_2_number__c = 5;
        template.Free_Cash_Flow_Last_Year_number__c = 5;
        template.Free_Cash_Flow_Current_Year_number__c = 5;
        template.Free_Cash_Flow_Next_Year_number__c = 5;
        template.Free_Cash_Flow_Next_Year_1_number__c = 5;
        template.Free_Cash_Flow_Next_Year_2_number__c = 5;
        return template;
    }

    /**
     * Global Desktop
     */
    public NBC__c createNBC() {
    	NBC__c nbc = new NBC__c();
    	nbc.Name = 'Prueba';
    	return nbc;
    }

    /**
     * Global Desktop
     */
    public NBC_Member__c createNBCMember(User user, Contact contact) {
    	NBC_Member__c member = new NBC_Member__c();
    	if(user != null) {
    		member.BBVA_participant__c = user.id;
    	}
    	if(contact != null) {
    		member.Other_BBVA_participant__c = contact.id;
    	}
    	member.region_emea__c = true;
    	member.region_latam__c = true;
    	member.region_usa__c = true;

    	return member;
    }

    /**
     * Global Desktop
     */
    public ContentDocumentLink createContentDocumentLink(DES_Template__c template, ContentDocument document) {
    	ContentDocumentLink contentlink=new ContentDocumentLink();
		contentlink.LinkedEntityId=template.id;
		contentlink.ShareType= 'V';
		contentlink.LinkedEntityId = template.Id;
		contentlink.ContentDocumentId=document.Id;
		contentlink.Visibility = 'AllUsers';
		return contentlink;
    }

    /**
     * Global Desktop
     */
    public ContentVersion createContentVersion(Boolean copyToNBC) {
    	ContentVersion cv = new Contentversion();
		cv.title = 'Title1';
		cv.PathOnClient ='test.pdf';
		cv.Copy_to_NBC__c = copyToNBC;
		Blob b = Blob.valueOf('Body TEST');
		cv.versiondata = EncodingUtil.base64Decode('Body TEST');
		insert cv;
		cv.Category_Type__c = 'Client Snapshot';
		return cv;
    }

	/**
    * Global Desktop
    */
    public DES_Subsidiary_Group_Relation__c createSubsidiaryGroupRelation(Account groupAccount, Account subsidiaryAccount) {
        DES_Subsidiary_Group_Relation__c sgRelation = new DES_Subsidiary_Group_Relation__c();
        sgRelation.participant_child_id__c = subsidiaryAccount.Id;
        sgRelation.participant_parent_id__c = groupAccount.Id;
        sgRelation.main_subsidiary_ind_type__c = true;
        sgRelation.business_computable_per__c = 100.00;
        sgRelation.core_business_relation_type__c = 'Subsidiary';
        return sgRelation;
    }

    /**
     * Nuevo Chatter NBC Virtual
    */
    public Chatter_NBC_Virtual__c createChatterNBCVirtual(Id recordId, String sObjectAPIName) {//NOSONAR
        Chatter_NBC_Virtual__c cNBCV;
        cNBCV = new Chatter_NBC_Virtual__c();
        cNBCV.tipo_objeto__c = sObjectAPIName;
        cNBCV.id_objeto__c = recordId;
        return cNBCV;
    }

    /**
     * nuevo NBC Commitee Member
     */
    public NBC_Commitee_Member__c createNbcCommitee(Id recordId,Id opp) {//NOSONAR
      final List<GroupMember> Groupmembers = [SELECT Id, GroupId, UserOrGroupId from GroupMember where Group.DeveloperName ='Virtual_NBC_Commitee_Team' LIMIT 1];//NOSONAR
        final NBC_Commitee_Member__c nbcMembers = new NBC_Commitee_Member__c();
        for(GroupMember members :Groupmembers) {
                nbcMembers.opportunity_id__c =opp;
                nbcMembers.gf_oppy_virtual_cmtee_id__c = recordId;
                nbcMembers.gf_oppy_virtual_cmtee_user_id__c = members.UserOrGroupId;
        }
        return nbcMembers;
    }

	/**
     * Global Desktop
     */
    public acpl__Account_Planning__c createAccountPlanning(Account account) {
        acpl__Account_Planning__c accountPlanning = new acpl__Account_Planning__c();
        accountPlanning.Name = 'Account Planning';
        accountPlanning.acpl__gf_ap_status_type_name__c = 'Not started';
        accountPlanning.acpl__participant_id__c = account.Id;
        accountPlanning.acpl__gf_ap_priority_type_name__c = 'Wave 1';
		accountPlanning.acpl__gf_mandatory_type__c = 'Mandatory';
        accountPlanning.acpl__gf_ap_indvi_lock_edit_ind_type__c=true;
        return accountPlanning;
    }
    
    /**
     * Global Desktop
     */
    public bupl__AP_Team__c createAPTeamMember(User user, acpl__Account_Planning__c accountPlanning) {
        bupl__AP_Team__c apTeamMember = new bupl__AP_Team__c();
        apTeamMember.Name = user.Name;
        apTeamMember.bupl__gf_ap_team_user_id__c = user.Id;
        apTeamMember.acpl__gf_account_planning_id__c = accountPlanning.Id;
        return apTeamMember;
    }

    /**
     * Account Planning Question record
     */
     public acpl__AP_Question__c createAPQuestion(acpl__Account_Planning__c accountPlanning) {
        acpl__AP_Question__c apQuestion = new acpl__AP_Question__c();
        apQuestion.Name = accountPlanning.Id + '_Q' + String.valueof(DateTime.now().getTime()*Math.abs(Math.random()*10));
        apQuestion.acpl__gf_account_planning_id__c = accountPlanning.Id;
        apQuestion.acpl__gf_ap_question_form_desc__c = 'question';
        return apQuestion;
    }

    /**
     * Dynamic form template record
     */
     public dyfr__Template__c createDfTemplate() {
        dyfr__Template__c dfTemplate = new dyfr__Template__c();
        dfTemplate.dyfr__Template_Code__c = 'dfTemplate_' + String.valueof(DateTime.now().getTime()*Math.abs(Math.random()*10));
        dfTemplate.Name = dfTemplate.dyfr__Template_Code__c;
        return dfTemplate;
    }

    /**
    * Dynamic form tab record
    */
    public dyfr__Tab__c createDfTab(dyfr__Template__c dfTemplate) {
        dyfr__Tab__c dfTab = new dyfr__Tab__c();
        dfTab.dyfr__Tab_Code__c = 'dfTab_' + String.valueof(DateTime.now().getTime()*Math.abs(Math.random()*10));
        dfTab.Name = dfTab.dyfr__Tab_Code__c;
        dfTab.dyfr__Column_Number__c = 1;
        dfTab.dyfr__Template__c = dfTemplate.Id;
        return dfTab;
    }

    /**
    * Dynamic form field config record
    */
    public dyfr__Field_Config__c createDfFieldConfig(dyfr__Tab__c dfTab) {
        dyfr__Field_Config__c fieldConfig = new dyfr__Field_Config__c();
        fieldConfig.dyfr__Tab__c = dfTab.Id;
        return fieldConfig;
    }

    /**
     * Account planning period configuration record
     */
    public acpl__AP_PeriodConfiguration__c createAPConfig() {
        acpl__AP_PeriodConfiguration__c apConfig = new acpl__AP_PeriodConfiguration__c();
        apConfig.Name = 'Account Planning Period Configuration';
        apConfig.acpl__gf_ap_edit_prms_type_name__c = 'General';
        apConfig.acpl__gf_ap_genrl_lock_edit_ind_type__c = true;
        apConfig.acpl__gf_ap_edit_days_left_number__c = 4;
        return apConfig;
    }

    /**
     * Account planning configuration record
     */

    public acpl__AP_Period__c createAPPeriod() {
        acpl__AP_Period__c apPeriod = new acpl__AP_Period__c();
        apPeriod.acpl__gf_ap_notfn_next_close_date__c = Date.Today();
        apPeriod.acpl__gf_ap_next_date_msg_desc__c = 'Notification message';
        apPeriod.acpl__gf_ap_edit_start_date__c = Date.Today();
        apPeriod.acpl__gf_ap_start_date_msg_desc__c = 'Start date message';
        apPeriod.acpl__gf_ap_edit_end_date__c = Date.Today();
        apPeriod.acpl__gf_ap_close_date_msg_desc__c = 'End date message';
        apPeriod.acpl__gf_ap_priority_edit_type__c = '';
        return apPeriod;
    }

    /*
     *  Global Desktop  -   OPR - NEW Sold Order
     *
    **/
    public Sold_Order__c createSoldOrder(Id oppId, Id accId, String currISOCode) {
        final Sold_Order__c soldOrder = new Sold_Order__c();
        soldOrder.opportunity_id__c = oppId;
        soldOrder.Currency__c = currISOCode;
        soldOrder.gf_loan_br_ctpty_id__c = accId;
        soldOrder.gf_ctpty_sold_order_amount__c = 200000000;
        soldOrder.gf_sold_order_settled_ind_type__c = 'No';

        return soldOrder;
    }
	/*
     *  Global Desktop  -  Loans Repayment
     *
    **/
    public Loans_Repayment__c createLoansRepayment(Account accGroup) {
    	Loans_Repayment__c loansRepayment = new Loans_Repayment__c();
    	loansRepayment.participant_id__c = accGroup.Id;
    	loansRepayment.gf_settlement_date__c = 2020;
    	loansRepayment.synd_loan_amortization_amount__c = 900000;
    	loansRepayment.bbva_repayment_amount__c = 450000;
    	return loansRepayment;
    }

    /*
     *  Global Desktop  -  RCF Expiration
     *
    **/
    public RCF_Expiration__c createRCF(Account accGroup) {
    	RCF_Expiration__c rcfExpiration = new RCF_Expiration__c();
    	rcfExpiration.participant_id__c = accGroup.Id;
    	rcfExpiration.current_expiry_date__c = system.Today();
    	rcfExpiration.deal_total_amount__c = 620000;
    	rcfExpiration.bbva_prtcp_tranche_amount__c = 300000;
    	return rcfExpiration;
    }

    /*
     *  Global Desktop  -  RCF Evolution
     *
    **/
    public RCF_Evolution__c createRCFEvolution(Account accGroup) {
    	RCF_Evolution__c rcfEvolution = new RCF_Evolution__c();
    	rcfEvolution.participant_id__c = accGroup.Id;
    	rcfEvolution.year_month_day_date__c = system.Today();
    	rcfEvolution.credit_drawn_per__c = 620000;
    	rcfEvolution.bbva_prtcp_tranche_amount__c = 300000;
    	return rcfEvolution;
    }

	/*
     *  Global Desktop  -  Legal Agreement
     *
    **/
	public Contrato_Marco__c createLegalAgreement(Account accFilial, Account accGroup) {
    	Contrato_Marco__c legalAgreement = new Contrato_Marco__c();
    	legalAgreement.participant_id__c = accFilial.Id;
    	legalAgreement.gf_deal_signing_date__c = system.Today();
    	legalAgreement.master_agreement_type__c = 'CMOF09';
    	legalAgreement.gf_agree_annex_typo_desc__c = 'CSAENGLAW';
    	return legalAgreement;
    }

    /*
     *  Global Desktop  -  TOP WON DEALS
     *
    **/
    public DES_TopWonDeals__c createAggregatedTopWonDeals(Account accFilial, Account accGroup) {
        DES_TopWonDeals__c twdeals = new DES_TopWonDeals__c();
        //twdeals.rec_cust_group_level_ind_type__c = 'Yes';
        twdeals.participant_id__c = accFilial.Id;
        twdeals.year_month_day_date__c = system.Today();
        twdeals.franch_oper_rslt_amount__c = 5000;
        twdeals.solution_category_id__c = 'FX,RATES';
        return twdeals;
    }
}