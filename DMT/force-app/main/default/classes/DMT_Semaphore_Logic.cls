public with sharing class DMT_Semaphore_Logic {

    public class SemaphoreRule {
        public String requiredStatus;
        public String requiredColorCapability;
        public String requiredColorWorkflow;
        public String colorLogicalOperatorType;
    }

    public static Boolean evaluate(SemaphoreRule rule, String currentCapabilityColor, String currentWorkflowColor) {
        Boolean capabilityOk = isColorAllowed(currentCapabilityColor, rule.requiredColorCapability);
        Boolean workflowOk = isColorAllowed(currentWorkflowColor, rule.requiredColorWorkflow);

        if (rule.colorLogicalOperatorType == 'AND') return capabilityOk && workflowOk;
        if (rule.colorLogicalOperatorType == 'OR') return capabilityOk || workflowOk;

        // No operator
        Boolean hasCapability = String.isNotBlank(rule.requiredColorCapability);
        Boolean hasWorkflow   = String.isNotBlank(rule.requiredColorWorkflow);
        if (hasCapability && hasWorkflow) return capabilityOk || workflowOk;
        if (hasCapability) return capabilityOk;
        if (hasWorkflow)   return workflowOk;
        return false;
    }

    private static Boolean isColorAllowed(String currentColor, String allowedColorsRaw) {
        if (String.isBlank(allowedColorsRaw) || String.isBlank(currentColor)) return false;
        Set<String> allowedColors = new Set<String>(allowedColorsRaw.split(';'));
        return allowedColors.contains(currentColor.trim().toUpperCase());
    }

    public static Boolean isRuleApplicable(SemaphoreRule rule, String currentFunctionalStatus) {
        return rule.requiredStatus != null && rule.requiredStatus.equalsIgnoreCase(currentFunctionalStatus);
    }

    public static String normalizeToShortColor(String rawColor) {
        if (String.isBlank(rawColor)) {
            return null;
        }
        String upper = rawColor.trim().toUpperCase();
        if (upper == 'GREEN' || upper == 'GRE') return 'GRE';
        if (upper == 'YELLOW' || upper == 'YEL') return 'YEL';
        if (upper == 'RED') return 'RED';
        if (upper == 'WHITE' || upper == 'WHI') return 'WHI';
        if (upper == 'GRAY' || upper == 'GRA') return 'GRA';
        return null;
    }
}