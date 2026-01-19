/**
* ------------------------------------------------------------------------------------------------
* @Name     PRW_Margin_Service
* @Author   Global Hub
* @Date     Created: 2022-04-27
* ------------------------------------------------------------------------------------------------
* @Description Wrapper Class for request volume service
* ------------------------------------------------------------------------------------------------
*/
@SuppressWarnings('sf:ShortVariable,sf:ShortClassName,sf:VariableNamingConventions,sf:LongVariable,sf:VariableDeclarationHidesAnothe')
public with sharing class PRW_Margin_Service {

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
  * @Description : Wrapper of request
  */
  public class Request {

    /**
    * @Description: PetitionBy
    */
    public PetitionBy petitionBy {get;set;}
    /**
    * @Description: startDate
    */
    public Date startDate {get;set;}
    /**
    * @Description: vision
    */
    public String vision {get;set;}
    /**
    * @Description: publication
    */
    public String publication {get;set;}

    /**
    * @Description: endDate
    */
    public Date endDate {get;set;}

    /**
    * @Description: endDate
    */
    public List<GroupBy> groupBy {get;set;}

    /**
    * @Description: Empty Constructor
    **/
    public Request() {}

    /**
    * @Description: Constructor
    **/
    public Request(PetitionBy petitionBy, Date startDate, Date endDate, List<GroupBy> groupBy , String vision, String publication) {
      this.petitionBy = petitionBy;
      this.startDate = startDate;
      this.endDate = endDate;
      this.groupBy = groupBy;
      this.vision = vision;
      this.publication = publication;
    }
  }

  /**
  * @Description : Wrapper of response
  */
  public class Response {

    /**
    * @Description: PetitionBy
    */
    public PetitionBy petitionBy {get;set;}

    /**
    * @Description: participant
    */
    public Participant participant {get;set;}

    /**
    * @Description: product
    */
    public ProductAux product {get;set;}

    /**
    * @Description: publication
    */
    public String publication {get;set;}
    /**
    * @Description: channel
    */
    public List<Channel> channels {get;set;}

    /**
    * @Description: dateRangeBlocks
    */
    public List<DateBlocks> dateRangeBlocks {get;set;}

    /**
    * @Description: acumulativeBlocks
    */
    public List<AcumulativeBlocks> acumulativeBlocks {get;set;}

    /**
    * @Description: maximumDateInformation
    */
    public Date maximumDateInformation {get;set;}


    /**
    * @Description: Empty Constructor
    **/
    public Response() {}

    /**
    * @Description: Constructor
    **/
    public Response(PetitionBy petitionBy, Participant participant, ProductAux product,String publication,  List<Channel> channels, List<DateBlocks> dateRangeBlocks, List<AcumulativeBlocks> acumulativeBlocks,Date maximumDateInformation) {
      this.petitionBy = petitionBy;
      this.product = product;
      this.publication = publication;
      this.participant = participant;
      this.channels = channels;
      this.dateRangeBlocks = dateRangeBlocks;
      this.acumulativeBlocks = acumulativeBlocks;
      this.maximumDateInformation = maximumDateInformation;
    }
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
    public List<String> id_y {get;set;}

    /**
    * @Description: Empty Constructor
    **/
    public PetitionBy() {}

    /**
    * @Description: Constructor
    **/
    public PetitionBy(String petitionType, List<String> id_y) {
      this.petitionType = petitionType;
      this.id_y = id_y;
    }
  }

  /**
  * @Description : Wrapper of Channel
  */
  public class Channel {

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
    public Channel() {}

    /**
    * @Description: Constructor
    **/
    public Channel(String id_y, String description) {
      this.id_y = id_y;
      this.description = description;
    }
  }

  /**
  * @Description : Wrapper of GroupBy
  */
  public class GroupBy {

    /**
    * @Description: groupType
    */
    public String groupType {get;set;}

    /**
    * @Description: Empty Constructor
    **/
    public GroupBy() {}

    /**
    * @Description: Constructor
    **/
    public GroupBy(String groupType) {
      this.groupType = groupType;
    }
  }



  ////RESPONSE

  /**
  * @Description : Wrapper of IdName
  */
  public class IdName {

    /**
    * @Description: id_y
    */
    public String id_y {get;set;}

    /**
    * @Description: name
    */
    public String name {get;set;}

    /**
    * @Description: Empty Constructor
    **/
    public IdName() {}

    /**
    * @Description: Constructor
    **/
    public IdName(String id_y, String name) {
      this.id_y = id_y;
      this.name = name;
    }
  }

  /**
  * @Description : Wrapper of ProductAux
  */
  public class ProductAux {

    /**
    * @Description: classification
    */
    public ProductClassification classification {get;set;}
    
    /**
    * @Description: Empty Constructor
    **/
    public ProductAux() {}

    /**
    * @Description: Constructor
    **/
    public ProductAux(ProductClassification classification) {
      this.classification = classification;
    }
  }

    /**
  * @Description : Wrapper of ProductClassification
  */
  public class ProductClassification {
    /**
    * @Description: classificationtype
    */
    public IdName classificationType {get;set;}
        /**
    * @Description: firstLevel
    */
    public IdName firstLevel {get;set;}
        /**
    * @Description: secondLevel
    */
    public IdName secondLevel {get;set;}
        /**
    * @Description: thirdLevel
    */
    public IdName thirdLevel {get;set;}
        /**
    * @Description: fourthLevel
    */
    public IdName fourthLevel {get;set;}
        /**
    * @Description: specificType
    */
    public IdName fifthLevel {get;set;}
    
    /**
    * @Description: Empty Constructor
    **/
    public ProductClassification() {}

     /**
    * @Description: Constructor
    **/
    public ProductClassification(IdName classificationtype,IdName firstLevel,IdName secondLevel,IdName thirdLevel,IdName fourthLevel,IdName fifthLevel) {
      this.classificationtype = classificationtype;
      this.firstLevel = firstLevel;
      this.secondLevel = secondLevel;
      this.thirdLevel = thirdLevel;
      this.fourthLevel = fourthLevel; 
      this.fifthLevel = fifthLevel;
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
    * @Description: fullName
    */
    public String fullName {get;set;}

    /**
    * @Description: Empty Constructor
    **/
    public Participant() {}

    /**
    * @Description: Constructor
    **/
    public Participant(String id_y, String fullName) {
      this.id_y = id_y;
      this.fullName = fullName;
    }
  }

  /**
  * @Description : Wrapper of Datavalue
  */
  public class Datavalue {

    /**
    * @Description: value
    */
    public String value {get;set;}

    /**
    * @Description: variation
    */
    public String variation {get;set;}

    /**
    * @Description: variation
    */
    public String valueLastPeriod {get;set;}

    /**
    * @Description: Empty Constructor
    **/
    public Datavalue() {}

    /**
    * @Description: Constructor
    **/
    public Datavalue(String value, String variation) {
      this.value = value;
      this.variation = variation;
    }

    public Datavalue(String value, String variation, String valueLastPeriod) {
      this.value = value;
      this.variation = variation;
      this.valueLastPeriod = valueLastPeriod;
    }
  }

  /**
  * @Description : Wrapper of AcumulativeBlocks
  */
  public class AcumulativeBlocks {
    /**
    * @Description: frequency
    */
    public String frequency {get;set;}
    /**
    * @Description: dataValue
    */
    public Datavalue dataValue {get;set;}

    /**
    * @Description: Empty Constructor
    **/
    public AcumulativeBlocks() {}

    /**
    * @Description: Constructor
    **/
    public AcumulativeBlocks(String frequency, Datavalue dataValue) {
        this.frequency = frequency;
      this.dataValue = dataValue;
    }
  }

  /**
  * @Description : Wrapper of AcumBlocks
  */
  public class Month {

    /**
    * @Description: id_y
    */
    public String id_y {get;set;}

    /**
    * @Description: year
    */
    public String year {get;set;}

    /**
    * @Description: Empty Constructor
    **/
    public Month() {}

    /**
    * @Description: Constructor
    **/
    public Month(String id_y, String year) {
      this.id_y = id_y;
      this.year = year;
    }
  }

  /**
  * @Description : Wrapper of AcumBlocks
  */
  public class DateBlocks {

    /**
    * @Description: month
    */
    public Month month {get;set;}

    /**
    * @Description: dataValue
    */
    public Datavalue dataValue {get;set;}

    /**
    * @Description: Empty Constructor
    **/
    public DateBlocks() {}

    /**
    * @Description: Constructor
    **/
    public DateBlocks(Month month, Datavalue dataValue) {
      this.month = month;
      this.dataValue = dataValue;
    }
  }

  /**
  * @Description : Wrapper of petition
  */
  public class TableDataWrap {
    /**
    * @Description: percentYoYL12M
    */
    public String percentYoYL12M {get;set;}
    /**
    * @Description: revenuesL12M
    */
    public String revenuesL12M {get;set;}
    /**
    * @Description: percentYoY_YTD
    */
    public String percentYoY_YTD {get;set;}
    /**
    * @Description: revenuesYTD
    */
    public String revenuesYTD {get;set;}
    /**
    * @Description: product
    */
    public String product {get;set;}
    /**
    * @Description: channel
    */
    public String channel {get;set;}
    /**
    * @Description: revenues
    */
    public String revenues {get;set;}
    /**
    * @Description: subFamily
    */
    public String subFamily {get;set;}
    /**
    * @Description: valueLastPeriod
    */
    public String valueLastPeriod {get;set;}
    /**
    * @Description: Empty Constructor
    **/
    public TableDataWrap() {}

    /**
    * @Description: Empty Constructor
    **/
    public TableDataWrap(String subFamily ,String revenues, String revenuesYTD, String percentYoY_YTD, String revenuesL12M, String product, String channel, String percentYoYL12M , String valueLastPeriod) {
      this.revenues=revenues;
      this.revenuesYTD=revenuesYTD;
      this.percentYoY_YTD=percentYoY_YTD;
      this.revenuesL12M=revenuesL12M;
      this.channel=channel;
      this.product=product;
      this.percentYoYL12M=percentYoYL12M;
      this.subFamily=subFamily;
      this.valueLastPeriod = valueLastPeriod;
    }

  }

}