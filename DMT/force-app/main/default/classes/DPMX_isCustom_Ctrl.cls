public class DPMX_isCustom_Ctrl {

    /**
    * @description Private constructor to avoid sonar err
    */
    public DPMX_isCustom_Ctrl() {

    }

    /**
    * @description ??????????????????????
    * @param dynamicPricingUpsert : DPMX_Dynamic_Pricing__c record with Simulator info
    * @return retMap ??????
    */
    @AuraEnabled
    public static Map<String,Object> saveData(DPMX_Dynamic_Pricing__c dynamicPricingUpsert) {
        Map<String, Object> retMap = new Map<String, Object>();
        update dynamicPricingUpsert;
        retMap.put('dynamicPricingUpsert', dynamicPricingUpsert);
        return retMap;
    }

}