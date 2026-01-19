/**
* ------------------------------------------------------------------------------------------------
* @Name     PRW_AddProductTest
* @Author   Global Hub
* @Date     Created: 2021-08-10
* ------------------------------------------------------------------------------------------------
* @Description Test class for PRW_RecordCompactCtrl and PRW_Notebook_Service
* ------------------------------------------------------------------------------------------------
* @Changes
*
* |2021-08-29 david.rodriguez.lucena.contractor@bbva.com
*             Class Creation
* -----------------------------------------------------------------------------------------------
*/
@isTest
public with sharing class PRW_RecordCompactCtrlTest {
  /**
  * @description
  * @author Global Hub | 2021-08-29
  **/
  @isTest
  static void calculatePriceTest() {
    final PRW_RecordCompactCtrl instance = PRW_RecordCompactCtrl.gtInstance();
    system.debug(instance);
    final DES_UtilTestClass util = new DES_UtilTestClass();
    final Account acc = util.createClient();
    acc.SER_CClient__c = '008789761';
    insert acc;
    final String data = '[{"id":1,"product":"Electrónico emitido","id_prod":"dypri.electronic.issued","simulatedP":3},{"id":2,"product":"Oficina emitida","id_prod":"dypri.bank.office.issued","simulatedP":3}]';
    final Map<String, Object> respuesta = PRW_RecordCompactCtrl.calculatePrice(acc.SER_CClient__c, data, null, false);
    system.debug(respuesta.get('products'));
    final String wrResponse = (String)respuesta.get('products');
    system.debug(wrResponse);
    final List<PRW_Notebook_Service.Product> lista = (List<PRW_Notebook_Service.Product>)JSON.deserialize(wrResponse, List<PRW_Notebook_Service.Product>.class);
    system.assert(!lista.isEmpty(), 'no hay productos');
  }

  /**
  * @description
  * @author Global Hub | 2021-08-29
  **/
  @isTest
  static void notebookPricingTest() {
    final PRW_Notebook_Service.petitionBy petitionBy = new PRW_Notebook_Service.petitionBy('BUSINESS','3333');

    final PRW_Notebook_Service.IndicatorsDetails details1 = new PRW_Notebook_Service.IndicatorsDetails('STRATEGY', 'recomendacion' , null, null, null, null);
    final PRW_Notebook_Service.IndicatorsProd indicatorsProd1 = new PRW_Notebook_Service.IndicatorsProd(details1);
    final PRW_Notebook_Service.Elasticity elasticity = new PRW_Notebook_Service.Elasticity('VERY_LOW','test');
    final PRW_Notebook_Service.IndicatorsDetails details2 = new PRW_Notebook_Service.IndicatorsDetails('ELASTICITY', null , elasticity, null, null, null);
    final PRW_Notebook_Service.IndicatorsProd indicatorsProd2 = new PRW_Notebook_Service.IndicatorsProd(details2);
    final PRW_Notebook_Service.Variation variation = new PRW_Notebook_Service.Variation('QUARTER_PRICE', '500');
    final List<PRW_Notebook_Service.Variation> listVariation = new List<PRW_Notebook_Service.Variation>();
    listVariation.add(variation);
    final PRW_Notebook_Service.IndicatorsDetails details3 = new PRW_Notebook_Service.IndicatorsDetails('VOLUME', null , null, listVariation, null, null);
    final PRW_Notebook_Service.IndicatorsProd indicatorsProd3 = new PRW_Notebook_Service.IndicatorsProd(details3);
    final PRW_Notebook_Service.CurrentValue current = new PRW_Notebook_Service.CurrentValue('200','200');
    final PRW_Notebook_Service.CurrentValue value1 = new PRW_Notebook_Service.CurrentValue('300','300');
    final List<PRW_Notebook_Service.CurrentValue> values = new List<PRW_Notebook_Service.CurrentValue>();
    values.add(value1);
    final PRW_Notebook_Service.IndicatorsDetails details4 = new PRW_Notebook_Service.IndicatorsDetails('CURVE', null , null, null, current, values);
    final PRW_Notebook_Service.IndicatorsProd indicatorsProd4 = new PRW_Notebook_Service.IndicatorsProd(details4);
    final List<PRW_Notebook_Service.IndicatorsProd> indicators = new List<PRW_Notebook_Service.IndicatorsProd>();
    indicators.add(indicatorsProd1);
    indicators.add(indicatorsProd2);
    indicators.add(indicatorsProd3);
    indicators.add(indicatorsProd4);

    final List<PRW_Notebook_Service.Product> products = new List<PRW_Notebook_Service.Product>();
    final PRW_Notebook_Service.Product product = new PRW_Notebook_Service.Product('CASH_MANAGEMENT','electronic.issued','3','0','100','3', indicators, null);
    products.add(product);
    final PRW_Notebook_Service.Details details = new PRW_Notebook_Service.Details('SIMPLE',null);
    final PRW_Notebook_Service.Pricing pricing = new PRW_Notebook_Service.Pricing(details, products);
    final List<PRW_Notebook_Service.Pricing> pricings = new List<PRW_Notebook_Service.Pricing>();
    pricings.add(pricing);

    final PRW_Notebook_Service.Tier tier = new PRW_Notebook_Service.Tier('GROWTH');

    final List<PRW_Notebook_Service.IndicatorsPricing> indicatorsPric = new List<PRW_Notebook_Service.IndicatorsPricing>();
    final PRW_Notebook_Service.IndicatorsPricing indicatorPric = new PRW_Notebook_Service.IndicatorsPricing('CIRBE', '10');
    indicatorsPric.add(indicatorPric);

    PRW_Notebook_Service service = new PRW_Notebook_Service(petitionBy,pricings,tier,indicatorsPric);
    system.assertEquals(service.petitionBy.id_y, '3333', 'id petitionBy');
  }
}