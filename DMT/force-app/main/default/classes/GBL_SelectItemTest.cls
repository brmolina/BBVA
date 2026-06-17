@isTest
public class GBL_SelectItemTest {
  @isTest static void constructor1 () {
    GBL_SelectItem mySelectItem = new GBL_SelectItem('value','label',true);

    System.assertEquals(mySelectItem.value,'value');
    System.assertEquals(mySelectItem.label,'label');
    System.assertEquals(mySelectItem.selected,true);
  }

  @isTest static void constructor2 () {
    GBL_SelectItem mySelectItem = new GBL_SelectItem('value','label');

    System.assertEquals(mySelectItem.value,'value');
    System.assertEquals(mySelectItem.label,'label');
    System.assertEquals(mySelectItem.selected, false);
  }

}