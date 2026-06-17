public with sharing class DMT_RendererFactory {
    private static Map<String, Type> rendererMap = new Map<String, Type>{
        'Line Info' => DMT_InfoRenderer.class,
        'Opportunity Info' => DMT_InfoRenderer.class,
        'Client' => DMT_ClientRenderer.class,
        'Approval Modifications' => DMT_ApprovalModificationsRenderer.class,
        'Approval Process Data' => DMT_ApprovalProcessDataRenderer.class,
        'Commercial Process Data' => DMT_CommercialProcessDataRenderer.class,
        'Participants' => DMT_ParticipantRenderer.class,
        'Products' => DMT_ProductsRenderer.class,
        'Sustainability' => DMT_SustainabilityRenderer.class,
        'Passport' => DMT_PassportRenderer.class,
        'Limit' => DMT_LimitRenderer.class,
        'Limit Visual' => DMT_LimitVisualRenderer.class,
        'Profitability' => DMT_ProfitabilityRenderer.class,
        'Transaction Overview' => DMT_TransactionOverviewRenderer.class,
        'Economics' => DMT_EconomicsRenderer.class,
        'Approval Process' => DMT_ApprovalProcessFlowRenderer.class,
        'Validation Process' => DMT_PassportProcessFlowRenderer.class,
        'Basic Financials' => DMT_BasicFinancialsRenderer.class,
        'Client Information' => DMT_ClientInformationRenderer.class,
        'Business Plan Data' => DMT_BusinessPlanDataRenderer.class,
        'Client Tier' => DMT_ClientTierRenderer.class,
        'Sustainable Finance' => DMT_SustainableFinanceRenderer.class,
        'Main Characteristics of the Deal' => DMT_MainCharacteristicsOfTheDealRenderer.class,
        'Other Aspect' => DMT_OtherAspectRenderer.class,
        'Risks' => DMT_RisksRenderer.class,
        'Basic Requirement' => DMT_BasicRequirementRenderer.class,
        'Intro Opportunity Deal' => DMT_IntroOpportunityDealRenderer.class,
        'Active Related Lines'=>DMT_ActiveRelatedLinesRenderer.class,
        'Sanction Approval Info' => DMT_SanctionApprovalInfoRenderer.class,
        'Approval Info' => DMT_InfoRenderer.class,
        'Sanction Client' => DMT_SanctionClientRenderer.class,
        'Sanction Products' => DMT_SanctionProductsRenderer.class,
        'Sanction Participants' => DMT_SanctionParticipantsRenderer.class,
        'Sanction Approval Process Data' => DMT_SanctionApprovalProcessDataRenderer.class,
        'Sanction Passport' => DMT_SanctionPassportRenderer.class,
        'Sanction Limit' => DMT_SanctionLimitRenderer.class,
        'Sanction Limit Visual' => DMT_SanctionLimitVisualRenderer.class,
        'Product Simple' => DMT_ProductSimpleRenderer.class,
        'Opportunity Info NBC' => DMT_InfoNBCRenderer.class,
        'Client NBC' => DMT_ClientNBCRenderer.class,
        'Profitability Summaries' => DMT_ProfitabilitySummariesRenderer.class,
        'Profitability Visual' => DMT_ProfitabilityVisualRenderer.class,
        'Status' => DMT_StatusOnlyRenderer.class

        // Add other components here
    };

    public static DMT_ViewRenderer getRenderer(String componentType) {
        Type rendererType = rendererMap.get(componentType);
        if (rendererType == null) throw new IllegalArgumentException('No renderer found for component: ' + componentType);
        return (DMT_ViewRenderer) rendererType.newInstance();
    }

    public static Boolean hasRenderer(String componentType) {
        return rendererMap.containsKey(componentType);
    }
}