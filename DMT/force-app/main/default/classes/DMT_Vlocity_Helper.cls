public with sharing class DMT_Vlocity_Helper {

    public static Boolean isEmpty(String str) {

        if (str == null || str == '') {
            return true;
        }

        return str.contains('{') && str.contains('}') ? true : false;
    }

    public static Boolean isNotEmpty(String str) {
        return !DMT_Vlocity_Helper.isEmpty(str);
    }
}