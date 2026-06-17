public class ONB_PathContextBuilder {
	public class BuildResult {
        public Map<String, Object> ctx;
        public ONB_Onboarding__c onboarding;
        public BuildResult(Map<String, Object> c, ONB_Onboarding__c o) { ctx = c; onboarding = o; }
    }

    public static BuildResult buildForOnboarding(Id onboardingId) {
        ONB_Onboarding__c onb = [
            SELECT Id,
                   Step__c,
                   Any_Master_Agreement__c,
                   ONB_Onboarding_Client_Type__c,
                   Legal_Entity_Type__c,
                   Request_Type__c
            FROM ONB_Onboarding__c
            WHERE Id = :onboardingId
            LIMIT 1
        ];

        Map<String, Object> ctx = new Map<String, Object>();
        ctx.put('ONB_Onboarding__c', onb);
        return new BuildResult(ctx, onb);
    }
}