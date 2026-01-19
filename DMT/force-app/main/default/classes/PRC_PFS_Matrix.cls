public with sharing class PRC_PFS_Matrix {
    @AuraEnabled
    public String id {get;set;}
    @AuraEnabled
    public List<axis> axis {get;set;}
    public PRC_PFS_Matrix() {
    }
    public class axis {
        @AuraEnabled
        public String id {get;set;}
        @AuraEnabled
        public Decimal numberOfEntries {get;set;}
        public axis(){}
        public axis(String id, Decimal entries) {
            this.id = id;
            this.numberOfEntries = entries;
        }
    }
}