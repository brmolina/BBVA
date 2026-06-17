public class GBL_SelectItem {

  @AuraEnabled public String  label  {get; set;}
  @AuraEnabled public String  value  {get; set;}
  @AuraEnabled public Boolean  selected  {get; set;}

  public GBL_SelectItem( String value, String label, Boolean selected) {
    this.label = label;
    this.value = value;
    this.selected = selected;
  }

  public GBL_SelectItem( String value, String label) {
    this.label = label;
    this.value = value;
    this.selected = false;
  }
}