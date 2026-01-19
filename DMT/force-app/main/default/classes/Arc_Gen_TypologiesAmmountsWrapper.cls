/**
* @File Name          : Arc_Gen_TypologiesAmmountsWrapper.cls
* @Description        : wraper lass for typologies
* @Author             :luisarturo.parra.contractor@bbva.com
* @Group              : ARCE
* @Last Modified By   : luisarturo.parra.contractor@bbva.com
* @Last Modified On   : 24/12/2019 05:17
* @Modification Log   :
*==============================================================================
* Ver         Date                     Author                 Modification
*==============================================================================
* 1.0    24/12/2019           luisarturo.parra.contractor@bbva.com     Initial Version
**/
public class Arc_Gen_TypologiesAmmountsWrapper {
    /** variable for typologies names**/
    public String typologyname { get;set;}
    /** variable for typologyammount names**/
    public Decimal typologyammount { get;set;}
    /** variable for typologykey names**/
    public String typologykey { get;set;}
    public Arc_Gen_TypologiesAmmountsWrapper(){
      typologyname = '';
      typologyammount = 0;
      typologykey = '';
    }
}