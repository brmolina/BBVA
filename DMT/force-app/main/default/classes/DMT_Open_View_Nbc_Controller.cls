public class DMT_Open_View_Nbc_Controller {

    @AuraEnabled
    public static String getListViewNBC() {

    //	List<DMT_Items__c> dmtItemList = DMT_Open_View_Nbc_Controller_Selector.getItemsNBC();
        Map<DMT_ApproversView__c, List<DMT_Items__c>> mapItemsByApprover;// = DMT_Open_View_Nbc_Controller_Selector.getItemsNBC();
        Map<DMT_ApproversView__c, List<DMT_ViewController.ItemWrapper>> finalMap = new Map<DMT_ApproversView__c, List<DMT_ViewController.ItemWrapper>>();
        for(DMT_ApproversView__c approver : mapItemsByApprover.keySet()) {
                List<DMT_ViewController.ItemWrapper> itemWrappers = new List<DMT_ViewController.ItemWrapper>();
                for (DMT_Items__c item : mapItemsByApprover.get(approver)) {
                    itemWrappers.add(new DMT_ViewController.ItemWrapper(item.Type_Item__c, item.DMT_Component_Item__c, item.DMT_order_display__c, item.DMT_Text__c));
                }
                finalMap.put(approver, itemWrappers);
            }

            return JSON.serialize(finalMap);
        }
}