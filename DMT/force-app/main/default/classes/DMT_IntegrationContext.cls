public with sharing class DMT_IntegrationContext {
    private static Boolean inbound = false;
    public static Boolean isInbound() { return inbound; }
    public static void setInbound(Boolean v) { inbound = v; }
}