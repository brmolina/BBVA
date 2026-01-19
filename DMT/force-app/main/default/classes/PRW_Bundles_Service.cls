public with sharing class PRW_Bundles_Service {
  /**
  * @Description : Wrapper of petition
  */
  public class Data {
    /**
    * @Description: petitionType
    */
    public List<Response> data {get;set;}


    /**
    * @Description: Empty Constructor
    **/
    public Data() {}

    /**
    * @Description: Constructor
    **/
    public Data(List<Response> data) {
      this.data = data;
    }
  }
    /**
  * @Description : Wrapper of response
  */
  public class Response {

    /**
    * @Description: id_y
    */

    public String id_y {get;set;}
    /**
    * @Description: description
    */

    public String description {get;set;}
    /**
    * @Description: price
    */
    public Price price {get;set;}

    /**
    * @Description: participant
    */
    public List<Participant> participants {get;set;}

    /**
    * @Description: products
    */
    public List<Products> products {get;set;}

    /**
    * @Description: nextBestProducts
    */
    public List<NextBestProducts> nextBestProducts {get;set;}

    /**
    * @Description: optimalProductPack
    */
    public OptimalProductPack optimalProductPack {get;set;}


    /**
    * @Description: Empty Constructor
    **/
    public Response() {}

    /**
    * @Description: Constructor
    **/
    public Response(String id_y,String description ,Price price, List<Participant> participants,  List<Products> products, List<NextBestProducts> nextBestProducts,OptimalProductPack optimalProductPack) {
      this.id_y = id_y;
      this.description = description;
      this.price = price;
      this.participants = participants;
      this.products = products;
      this.nextBestProducts = nextBestProducts;
      this.optimalProductPack = optimalProductPack;
    }
  }

  /**
  * @Description : Wrapper of Price
  */
  public class Price {
    /**
    * @Description: petitionType
    */
    public Decimal amount {get;set;}

    /**
    * @Description: currency
    */
    public String currency_y {get;set;}

    /**
    * @Description: Empty Constructor
    **/
    public Price() {}

    /**
    * @Description: Constructor
    **/
    public Price(Decimal amount, String currency_y) {
      this.amount = amount;
      this.currency_y = currency_y;
    }
  }

  /**
  * @Description : Wrapper of Participant
  */
  public class Participant {

    /**
    * @Description: id_y
    */
    public String id_y {get;set;}

    /**
    * @Description: Empty Constructor
    **/
    public Participant() {}

    /**
    * @Description: Constructor
    **/
    public Participant(String id_y) {
      this.id_y = id_y;
    }
  }

  /**
  * @Description : Wrapper of Products
  */
  public class Products {

    /**
    * @Description: optimalPrice
    */
    public OptimalPrice optimalPrice {get;set;}

    /**
    * @Description: description
    */
    public String description {get;set;}

    /**
    * @Description: optimalVolume
    */
    public Decimal optimalVolume {get;set;}

    /**
    * @Description: order
    */
    public Decimal order {get;set;}

    /**
    * @Description: Empty Constructor
    **/
    public Products() {}

    /**
    * @Description: Constructor
    **/
    public Products(OptimalPrice optimalPrice , String description , Decimal optimalVolume , Decimal order) {
      this.optimalPrice = optimalPrice;
      this.description = description;
      this.optimalVolume = optimalVolume;
      this.order= order;
    }
  }

  /**
  * @Description : Wrapper of NextBestProducts
  */
  public class NextBestProducts {

    /**
    * @Description: optimalPrice
    */
    public OptimalPrice optimalPrice {get;set;}

    /**
    * @Description: description
    */
    public String description {get;set;}

    /**
    * @Description: optimalVolume
    */
    public Decimal optimalVolume {get;set;}

    /**
    * @Description: order
    */
    public Decimal order {get;set;}

    /**
    * @Description: Empty Constructor
    **/
    public NextBestProducts() {}

    /**
    * @Description: Constructor
    **/
    public NextBestProducts(OptimalPrice optimalPrice , String description , Decimal optimalVolume , Decimal order) {
      this.optimalPrice = optimalPrice;
      this.description = description;
      this.optimalVolume = optimalVolume;
      this.order= order;
    }
  }

  /**
  * @Description : Wrapper of OptimalPrice
  */
  public class OptimalPrice {

    /**
    * @Description: amount
    */
    public Decimal amount {get;set;}

    /**
    * @Description: currency
    */
    public String currency_y {get;set;}

    /**
    * @Description: Empty Constructor
    **/
    public OptimalPrice() {}

    /**
    * @Description: Constructor
    **/
    public OptimalPrice(Decimal amount , String currency_y) {
      this.amount = amount;
      this.currency_y = currency_y;
    }
  }

  /**
  * @Description : Wrapper of OptimalProductPack
  */
  public class OptimalProductPack {

    /**
    * @Description: id_y
    */
    public String id_y {get;set;}

    /**
    * @Description: description
    */
    public String description {get;set;}

    /**
    * @Description: Empty Constructor
    **/
    public OptimalProductPack() {}

    /**
    * @Description: Constructor
    **/
    public OptimalProductPack(String id_y , String description) {
      this.id_y = id_y;
      this.description = description;
    }
  }
  /**
  * @Description : Wrapper of bundle table 
  */
  public class TableBundleProdDataWrap {
    /**
    * @Description: bundleProd
    */
    public String bundleProd {get;set;}
    /**
    * @Description: qntity
    */
    public Decimal qntity {get;set;}
    /**
    * @Description: qntity
    */
    public Decimal order {get;set;}
    /**
    * @Description: Empty Constructor
    **/
    public TableBundleProdDataWrap() {}

    /**
    * @Description: Constructor
    **/
    public TableBundleProdDataWrap(String bundleProd, Decimal qntity, Decimal order) {
      this.bundleProd=bundleProd;
      this.qntity=qntity;
      this.order=order;
    }

  }

  /**
  * @Description : Wrapper of next best product
  */
  public class TableNBPDataWrap {
    /**
    * @Description: nextBestProd
    */
    public String nextBestProd  {get;set;}

    /**
    * @Description: price
    */
    public Decimal price  {get;set;}
    /**
    * @Description: currency
    */
    public String currency_y  {get;set;}
    /**
    * @Description: qntity
    */
    public Decimal qntity {get;set;}
    /**
    * @Description: qntity
    */
    public Decimal order {get;set;}
    /**
    * @Description: Empty Constructor
    **/
    public TableNBPDataWrap() {}

    /**
    * @Description: Constructor
    **/
    public TableNBPDataWrap(String nextBestProd, Decimal price,String currency_y, Decimal qntity, Decimal order) {
      this.nextBestProd=nextBestProd;
      this.price=price;
      this.currency_y=currency_y;
      this.qntity=qntity;
      this.order=order;
    }

  }

  /**
  * @Description : Wrapper of BundleDataWrap
  */
  public class BundleDataWrap {
    /**
    * @Description: nextBestProd
    */
    public List<TableNBPDataWrap> nextBestProd  {get;set;}

    /**
    * @Description: bundleProd
    */
    public List<TableBundleProdDataWrap> bundleProd  {get;set;}

    /**
    * @Description: bundleName
    */
    public String bundleName {get;set;}

    /**
    * @Description: bundlePrice
    */
    public Decimal bundlePrice {get;set;}
    /**
    * @Description: currency
    */
    public String currency_y {get;set;}
    /**
    * @Description: isBestOption
    */
    public Boolean isBestOption{get;set;}
    /**
    * @Description: description
    */
    public String description{get;set;}
    /**
    * @Description: cifNames
    */
    public List<String> cifNames{get;set;}
    /**
    * @Description: cifs
    */
    public Integer cifs {get;set;}
    /**
    * @Description: Empty Constructor
    **/
    public BundleDataWrap() {}

    /**
    * @Description: Constructor
    **/
    public BundleDataWrap(List<TableNBPDataWrap> nextBestProd, List<TableBundleProdDataWrap> bundleProd, String bundleName ,Decimal bundlePrice ,String currency_y , Boolean isBestOption, String description ) {
      this.nextBestProd=nextBestProd;
      this.bundleProd=bundleProd;
      this.bundleName=bundleName;
      this.bundlePrice=bundlePrice;
      this.currency_y=currency_y;
      this.isBestOption=isBestOption;
      this.description = description;
    }

  }

}