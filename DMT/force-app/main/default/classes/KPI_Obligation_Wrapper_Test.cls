/**
------------------------------------------------------------------------------------------------
@Name     KPI_Obligation_Wrapper_Test
@Author   Global Hub
@Date     Created: 2023-09-11
------------------------------------------------------------------------------------------------
@Description Test class for KPI_Obligation_Wrapper_Test
------------------------------------------------------------------------------------------------
@Changes
| 2023-09-11 ivan.garces.contractor@bbva.com
            Class Creation
-----------------------------------------------------------------------------------------------
*/
@isTest
public with sharing class KPI_Obligation_Wrapper_Test {
    /**
    @description
    @author Global Hub | 2023-09-07
    **/
    @isTest
    static void getKPICatalogTest() {
        Test.startTest();
        final Date dateMock = Date.newInstance(2023, 9, 11);
        KPI_Obligation_Wrapper wrap = new KPI_Obligation_Wrapper();
        wrap.data = new List<KPI_Obligation_Wrapper.Data>();
        wrap.success = true;
        wrap.message = 'test';

        KPI_Obligation_Wrapper.Data data = new KPI_Obligation_Wrapper.Data();
        data.id = 'Test';
        data.description = 'Test';
        data.contract = new KPI_Obligation_Wrapper.Contract();
        data.sustainableSubcategory = new KPI_Obligation_Wrapper.SustainableSubcategory();
        data.sustainableAgent = new KPI_Obligation_Wrapper.SustainableAgent();
        data.sustainableCoordinator = true;
        data.feeSustainableCoordinator = 100;
        data.extendedDescription = 'Test';
        data.actions = new List<KPI_Obligation_Wrapper.Actions>();
        data.obligationType = new KPI_Obligation_Wrapper.ObligationType();

        KPI_Obligation_Wrapper.Scale scale = new KPI_Obligation_Wrapper.Scale();
        scale.id = 'Test';
        scale.effectiveStartDate = dateMock;
        scale.effectiveEndDate = dateMock;
        scale.criteriaIdMaximum = 'Test';
        scale.criteriaValueMaximum = 10;
        scale.criteriaIdMinimum = 'Test';
        scale.criteriaValueMinimum = 10;
        scale.rate = 'Test';
        scale.sortOrder = 10;
        scale.rating = new KPI_Obligation_Wrapper.Rating();

        KPI_Obligation_Wrapper.Rating mockRating = new KPI_Obligation_Wrapper.Rating();
        mockRating.id = 'Test';
        mockRating.name = 'Test';
        mockRating.ratingIdMaximum = 'Test';
        mockRating.ratingNameMaximum = 'Test';
        mockRating.ratingValueMaximum = 10;
        mockRating.ratingIdMinimum = 'Test';
        mockRating.ratingNameMinimum = 'Test';
        mockRating.ratingValueMinimum = 10;

        KPI_Obligation_Wrapper.Review mockReview = new KPI_Obligation_Wrapper.Review();
        mockReview.id = 'Test';
        mockReview.obligationReview = new KPI_Obligation_Wrapper.ObligationReview();
        mockReview.idCriteria = 'Test';
        mockReview.alertClasificationDescription = 'Test';
        mockReview.alertMinimumTrigger = 10;
        mockReview.idAction = 'Test';
        mockReview.alertTriggerObligation = 'Test';
        mockReview.alertTriggerOutputFormatDescription = 'Test';
        mockReview.alertTriggerOutputFormatNumber = 10;
        mockReview.alertObligationDate = dateMock;
        mockReview.alertCovenant = new KPI_Obligation_Wrapper.AlertCovenant();

        KPI_Obligation_Wrapper.ObligationReview mockObReview = new KPI_Obligation_Wrapper.ObligationReview();
        mockObReview.name = 'Test';
        mockObReview.obligationDate = dateMock;
        mockObReview.classificationDescription = 'Test';
        mockObReview.workflowId = 'Test';
        mockObReview.receptionStatusDescription = 'Test';
        mockObReview.complianceStatusDescription = 'Test';
        mockObReview.covenant = new KPI_Obligation_Wrapper.Covenant();

        KPI_Obligation_Wrapper.ObligationType ob = new KPI_Obligation_Wrapper.ObligationType();
        ob.id = 'test';

        KPI_Obligation_Wrapper.Contract con = new KPI_Obligation_Wrapper.Contract();
        con.id = 'test';

        KPI_Obligation_Wrapper.SustainableSubcategory sust = new KPI_Obligation_Wrapper.SustainableSubcategory();
        sust.id = 'test';

        KPI_Obligation_Wrapper.SustainableAgent ag = new KPI_Obligation_Wrapper.SustainableAgent();
        ag.id = 'test';

        KPI_Obligation_Wrapper.Triggers tri = new KPI_Obligation_Wrapper.Triggers();
        tri.id = 'test';
        tri.name = 'test';
        tri.obligationReviewWorkflowId = 'test';
        tri.scale = new KPI_Obligation_Wrapper.Scale();
        tri.reviews = new List<KPI_Obligation_Wrapper.Review>();

        Test.stopTest();

        Assert.areEqual('test', wrap.message, '');
    }
}