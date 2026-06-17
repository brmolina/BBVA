public with sharing class ONB_PathConfigService {

    public class StepDTO {
        @AuraEnabled public String key;
        @AuraEnabled public String label;
        @AuraEnabled public Integer order;
        @AuraEnabled public String status;     // 'complete' | 'current' | 'incomplete'
        @AuraEnabled public Boolean clickable; // UI rule
    }

    public class PathModelDTO {
        @AuraEnabled public List<StepDTO> steps;
        @AuraEnabled public Boolean allComplete;
        @AuraEnabled public String currentStep;
    }

    @AuraEnabled(cacheable=true)
    public static PathModelDTO getPathModel(Id onboardingId, String contextKey) {

        ONB_PathContextBuilder.BuildResult build = ONB_PathContextBuilder.buildForOnboarding(onboardingId);
        ONB_Onboarding__c onb = build.onboarding;
        Map<String, Object> ctx = build.ctx;

        // Steps visibles por CMDT
        String pathKey = resolvePathKey(contextKey);

        List<ONB_PathState__mdt> stepsMdt = [
            SELECT StepKey__c, Label, Order__c, VisibleCondition__c, PathKey__c
            FROM ONB_PathState__mdt
            WHERE PathKey__c = :pathKey
            ORDER BY Order__c ASC
        ];

        List<StepDTO> visibleSteps = new List<StepDTO>();
        for (ONB_PathState__mdt rec : stepsMdt) {
            if (ONB_PathConditionEvaluator.evaluate(rec.VisibleCondition__c, ctx)) {
                StepDTO dto = new StepDTO();
                dto.key = rec.StepKey__c;
                dto.label = rec.Label;
                dto.order = rec.Order__c == null ? null : Integer.valueOf(rec.Order__c);
                visibleSteps.add(dto);
            }
        }

        // Determinar currentStep (desde Step__c)
        String current = onb != null ? onb.Step__c : null;

        // Si current no está en visibles, lo ponemos al primero visible
        Integer currentIdx = indexOf(visibleSteps, current);
        if (currentIdx < 0 && !visibleSteps.isEmpty()) {
            current = visibleSteps[0].key;
            currentIdx = 0;
        }

        // allComplete (MVP: current es el último)
        Boolean allComplete = (!visibleSteps.isEmpty() && currentIdx == visibleSteps.size() - 1);

        // status + clickable
        for (Integer i = 0; i < visibleSteps.size(); i++) {
            StepDTO s = visibleSteps[i];

            if (i < currentIdx) s.status = 'complete';
            else if (i == currentIdx) s.status = 'current';
            else s.status = 'incomplete';

            // reglas click:
            if (allComplete) {
                s.clickable = true;
            } else {
                // permitir current, prev, next
                s.clickable = (i == currentIdx || i == currentIdx - 1 || i == currentIdx + 1);
            }
        }

        PathModelDTO model = new PathModelDTO();
        model.steps = visibleSteps;
        model.allComplete = allComplete;
        model.currentStep = current;
        return model;
    }

    private static Integer indexOf(List<StepDTO> steps, String key) {
        if (String.isBlank(key) || steps == null) return -1;
        for (Integer i = 0; i < steps.size(); i++) {
            if (steps[i].key == key) return i;
        }
        return -1;
    }

    private static String resolvePathKey(String contextKey) {
        if (String.isBlank(contextKey)) contextKey = 'DEFAULT';

        List<ONB_PathVariant__mdt> variants = [
            SELECT PathKey__c, Priority__c, IsActive__c, ContextKey__c
            FROM ONB_PathVariant__mdt
            WHERE IsActive__c = true AND ContextKey__c = :contextKey
            ORDER BY Priority__c DESC
            LIMIT 1
        ];

        if (variants.isEmpty() || String.isBlank(variants[0].PathKey__c)) {
            return 'ONB_NEWCLIENT_V1';
        }
        return variants[0].PathKey__c;
    }
}