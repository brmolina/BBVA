public with sharing class DMT_RendererFactory {
    private static Map<String, Type> rendererMap = new Map<String, Type>{
        'Line Info' => DMT_InfoRenderer.class,
        'Opportunity Info' => DMT_InfoRenderer.class,
        'Client' => DMT_ClientRenderer.class,
        'Approval Process Data' => DMT_ApprovalProcessDataRenderer.class,
        'Commercial Process Data' => DMT_CommercialProcessDataRenderer.class,
        'Participants' => DMT_ParticipantRenderer.class,
        'Products' => DMT_ProductsRenderer.class,
        'Passport' => DMT_PassportRenderer.class,
        'Limit' => DMT_LimitRenderer.class,
        'Limit Visual' => DMT_LimitVisualRenderer.class,
        'Transaction Overview' => DMT_TransactionOverviewRenderer.class,
        'Economics' => DMT_EconomicsRenderer.class,
        'Approval Process' => DMT_ApprovalProcessFlowRenderer.class,
        'Validation Process' => DMT_PassportProcessFlowRenderer.class
        // Add other components here
    };

    public static DMT_ViewRenderer getRenderer(String componentType) {
        Type rendererType = rendererMap.get(componentType);
        if (rendererType == null) throw new IllegalArgumentException('No renderer found for component: ' + componentType);
        return (DMT_ViewRenderer) rendererType.newInstance();
    }
}