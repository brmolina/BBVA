public with sharing class ONB_PathConditionEvaluator {

    public static Boolean evaluate(String condition, Map<String, Object> ctx) {
        if (String.isBlank(condition)) return true;
        if (ctx == null) ctx = new Map<String, Object>();

        for (String andGroup : condition.split('&')) {
            andGroup = andGroup != null ? andGroup.trim() : '';
            if (andGroup == '') continue;

            Boolean groupPass = false;

            for (String clause : andGroup.split('\\|')) {
                clause = clause != null ? clause.trim() : '';
                if (clause == '') continue;

                if (evaluateClause(clause, ctx)) {
                    groupPass = true;
                    break;
                }
            }

            if (!groupPass) return false;
        }

        return true;
    }

    private static Boolean evaluateClause(String clause, Map<String, Object> ctx) {
        String op;
        Integer opIdx;

        if (clause.contains('!=')) {
            op = '!=';
            opIdx = clause.indexOf('!=');
        } else {
            op = '=';
            opIdx = clause.indexOf('=');
        }

        if (opIdx == null || opIdx <= 0) return false;
        if (clause.indexOf(op, opIdx + op.length()) >= 0) return false;

        String left = clause.substring(0, opIdx) != null ? clause.substring(0, opIdx).trim() : '';
        String right = clause.substring(opIdx + op.length()) != null ? clause.substring(opIdx + op.length()).trim() : '';
        if (left == '' || right == '') return false;

        Object leftVal = resolveLeftValue(left, ctx);
        if (leftVal == null) return false;

        Boolean isEqual;

        if (leftVal instanceof Boolean) {
            isEqual = String.valueOf((Boolean) leftVal).toLowerCase() == right.toLowerCase();
        } else if (leftVal instanceof Integer || leftVal instanceof Long || leftVal instanceof Decimal) {
            try {
                Decimal dl = Decimal.valueOf(String.valueOf(leftVal));
                Decimal dr = Decimal.valueOf(right);
                isEqual = (dl == dr);
            } catch (Exception e) {
                isEqual = (String.valueOf(leftVal) == right);
            }
        } else {
            isEqual = (String.valueOf(leftVal) == right);
        }

        return op == '=' ? isEqual : !isEqual;
    }

    private static Object resolveLeftValue(String left, Map<String, Object> ctx) {
        Integer dot = left.indexOf('.');
        if (dot > 0) {
            String objApi = left.substring(0, dot).trim();
            String fieldApi = left.substring(dot + 1).trim();

            Object obj = ctx.get(objApi);
            if (obj == null || !(obj instanceof SObject)) return null;

            return ((SObject) obj).get(fieldApi);
        }

        return ctx.get(left);
    }
}