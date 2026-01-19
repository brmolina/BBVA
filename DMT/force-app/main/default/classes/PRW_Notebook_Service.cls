/**
* ------------------------------------------------------------------------------------------------
* @Name     PRW_Notebook_Request
* @Author   Global Hub
* @Date     Created: 2021-07-22
* ------------------------------------------------------------------------------------------------
* @Description Wrapper Class for request
* ------------------------------------------------------------------------------------------------
* @Changes
*
* |2021-08-24 david.rodriguez.lucena.contractor@bbva.com
*             Class Creation
* -----------------------------------------------------------------------------------------------
*/
@SuppressWarnings('sf:ShortVariable,sf:ShortClassName,sf:VariableNamingConventions,sf:LongVariable,sf:VariableDeclarationHidesAnothe')
public with sharing class PRW_Notebook_Service {

  /**
  * @Description: petitionBy
  */
  public PetitionBy petitionBy {get;set;}

  /**
  * @Description: pricing
  */
  public List<Pricing> pricing {get;set;}

  /**
  * @Description: pricing
  */
  public Tier tier {get;set;}

  /**
  * @Description: indicators
  */
  public List<IndicatorsPricing> indicators {get;set;}

  /**
  * @Description: Empty Constructor
  **/
  public PRW_Notebook_Service() {}

  /**
  * @Description: Constructor
  **/
  public PRW_Notebook_Service(PetitionBy petitionBy, List<Pricing> pricing, Tier tier, List<IndicatorsPricing> indicators) {
    this.petitionBy = petitionBy;
    this.pricing = pricing;
    this.tier = tier;
    this.indicators = indicators;
  }

  /**
  * @Description : Wrapper of petition
  */
  public class PetitionBy {
    /**
    * @Description: petitionType
    */
    public String petitionType {get;set;}

    /**
    * @Description: id_y
    */
    public String id_y {get;set;}

    /**
    * @Description: Empty Constructor
    **/
    public PetitionBy() {}

    /**
    * @Description: Constructor
    **/
    public PetitionBy(String petitionType, String id_y) {
      this.petitionType = petitionType;
      this.id_y = id_y;
    }
  }


  /**
  * @Description : Wrapper of Products
  */
  public class Product {
    /**
    * @Description: productConditionType
    */
    public String productConditionType {get;set;}
    /**
    * @Description: Id
    */
    public String id_y {get;set;}
    /**
    * @Description: price
    */
    public String price {get;set;}
    /**
    * @Description: volume
    */
    public String volume {get;set;}
    /**
    * @Description: optimalVolume
    */
    public String optimalVolume {get;set;}
    /**
    * @Description: optimalPrice
    */
    public String optimalPrice {get;set;}
    /**
    * @Description: indicators
    */
    public List<IndicatorsProd> indicators {get;set;}
    /**
    * @Description: description
    */
    public String description {get;set;}
    /**
    * @Description: notificationDescription
    */
    public String notificationDescription {get;set;}
    /**
    * @Description: notificationCode
    */
    public String notificationCode {get;set;}
    /**
    * @Description: notifications
    */
    public List <Notification> notifications {get;set;}

    /**
    * @Description: Empty Constructor
    **/
    public Product() {}

    /**
    * @Description: Constructor
    **/
    public Product(String productConditionType, String id_y, String price, String volume, String optimalVolume, String optimalPrice, List<IndicatorsProd> indicators, String description) { //NOSONAR
      this.productConditionType = productConditionType;
      this.id_y = id_y;
      this.price = price;
      this.volume = volume;
      this.optimalVolume = optimalVolume;
      this.optimalPrice = optimalPrice;
      this.indicators = indicators;
      this.description = description;
    }
    
    public Product(String productConditionType, String id_y, String price, String volume, String optimalVolume, String optimalPrice, List<IndicatorsProd> indicators, String description, List<Notification> notifications) { //NOSONAR
      this.productConditionType = productConditionType;
      this.id_y = id_y;
      this.price = price;
      this.volume = volume;
      this.optimalVolume = optimalVolume;
      this.optimalPrice = optimalPrice;
      this.indicators = indicators;
      this.description = description;
      this.notifications = notifications;
    }
  }

  /**
  * @Description : Wrapper of details
  */
  public class Details {
    /**
    * @Description: pricingType
    */
    public String pricingType {get;set;}

    /**
    * @Description: optimalPrice
    */
    public String optimalPrice {get;set;}

    /**
    * @Description: Constructor
    **/
    public Details(String pricingType, String optimalPrice) {
      this.pricingType = pricingType;
      this.optimalPrice = optimalPrice;
    }
  }

  /**
  * @Description : Wrapper of Pricing
  */
  public class Pricing {
    /**
    * @Description: details
    */
    public Details details {get;set;}

    /**
    * @Description: details
    */
    public List<Product> products {get;set;}

    /**
    * @Description: EmptyConstructor
    **/
    public Pricing() {}

    /**
    * @Description: Constructor
    **/
    public Pricing(Details details, List<Product> products) {
      this.details = details;
      this.products = products;
    }
  }

  /**
  * @Description : Wrapper of Elasticity
  */
  public class Elasticity {
    /**
    * @Description: id
    */
    public String id_y {get;set;}

    /**
    * @Description: description
    */
    public String description {get;set;}

    /**
    * @Description: Constructor
    **/
    public Elasticity(String id_y, String description) {
      this.id_y = id_y;
      this.description = description;
    }
  }

  /**
  * @Description : Wrapper of Variation
  */
  public class Variation {
    /**
    * @Description: id
    */
    public String id_y {get;set;}

    /**
    * @Description: value
    */
    public String value {get;set;}

    /**
    * @Description: Constructor
    **/
    public Variation(String id_y, String value) {
      this.id_y = id_y;
      this.value = value;
    }
  }

  /**
  * @Description : Wrapper of CurrentValue
  */
  public class CurrentValue {
    /**
    * @Description: price
    */
    public String price {get;set;}

    /**
    * @Description: volume
    */
    public String volume {get;set;}

    /**
    * @Description: Constructor
    **/
    public CurrentValue(String price, String volume) {
      this.price = price;
      this.volume = volume;
    }
  }

  /**
  * @Description : Wrapper of IndicatorsDetails
  */
  public class IndicatorsDetails {
    /**
    * @Description: indicatorType
    */
    public String indicatorType {get;set;}

    /**
    * @Description: strategy
    */
    public String strategy {get;set;}

    /**
    * @Description: volume
    */
    public Elasticity elasticity {get;set;}

    /**
    * @Description: variations
    */
    public List<Variation> variations {get;set;}

    /**
    * @Description: current
    */
    public CurrentValue current {get;set;}

    /**
    * @Description: values
    */
    public List<CurrentValue> values {get;set;}

    /**
    * @Description: Constructor
    **/
    public IndicatorsDetails(String indicatorType, String strategy, Elasticity elasticity, List<Variation> variations, CurrentValue current, List<CurrentValue> values) { //NOSONAR
      this.indicatorType = indicatorType;
      this.strategy = strategy;
      this.elasticity = elasticity;
      this.variations = variations;
      this.current = current;
      this.values = values;
    }
  }

  /**
  * @Description : Wrapper of Notification
  */
  public class Notification {
    /**
    * @Description: code
    */
    public String code {get;set;}
    /**
    * @Description: code
    */
    public String description {get;set;}
    /**
    * @Description: Empty Constructor
    **/
    public Notification() {}

    /**
    * @Description: Constructor
    **/
    public Notification(String code, String description) {
      this.code = code;
      this.description = description;
    }
  }
  /**
  * @Description : Wrapper of IndicatorsProd
  */
  public class IndicatorsProd {
    /**
    * @Description: price
    */
    public IndicatorsDetails details {get;set;}

    /**
    * @Description: Empty Constructor
    **/
    public IndicatorsProd() {}

    /**
    * @Description: Constructor
    **/
    public IndicatorsProd(IndicatorsDetails details) {
      this.details = details;
    }
  }

  /**
  * @Description : Wrapper of Tier
  */
  public class Tier {
    /**
    * @Description: price
    */
    public String id_y {get;set;}

    /**
    * @Description: Constructor
    **/
    public Tier(String id_y) {
      this.id_y = id_y;
    }
  }

  /**
  * @Description : Wrapper of IndicatorsPricing
  */
  public class IndicatorsPricing {

    /**
    * @Description: id
    */
    public String id_y {get;set;}

    /**
    * @Description: value
    */
    public String value {get;set;}

    /**
    * @Description: Constructor
    **/
    public IndicatorsPricing(String id_y, String value) {
      this.id_y = id_y;
      this.value = value;
    }
  }
}