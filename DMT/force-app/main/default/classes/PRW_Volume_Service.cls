/**
* ------------------------------------------------------------------------------------------------
* @Name     PRW_Volume_Service
* @Author   Global Hub
* @Date     Created: 2022-01-13
* ------------------------------------------------------------------------------------------------
* @Description Wrapper Class for request volume service
* ------------------------------------------------------------------------------------------------
*/
@SuppressWarnings('sf:ShortVariable,sf:ShortClassName,sf:VariableNamingConventions,sf:LongVariable,sf:VariableDeclarationHidesAnothe')
public with sharing class PRW_Volume_Service {

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
    public Request(PetitionBy petitionBy, Date startDate, Date endDate, List<GroupBy> groupBy) {
      this.petitionBy = petitionBy;
      this.startDate = startDate;
      this.endDate = endDate;
      this.groupBy = groupBy;
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
    * @Description: transaction
    */
    public TransactionAux transaction_y {get;set;}

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
    public Response(PetitionBy petitionBy, Participant participant, TransactionAux transaction_y, List<Channel> channels, List<DateBlocks> dateRangeBlocks, List<AcumulativeBlocks> acumulativeBlocks, Date maximumDateInformation) {
      this.petitionBy = petitionBy;
      this.participant = participant;
      this.transaction_y = transaction_y;
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
  * @Description : Wrapper of TransactionAux
  */
  public class TransactionAux {

    /**
    * @Description: classification
    */
    public IdName classification {get;set;}

    /**
    * @Description: category
    */
    public IdName categorization {get;set;}

    /**
    * @Description: specificType
    */
    public IdName specificType {get;set;}

    /**
    * @Description: destinationBankType
    */
    public String destinationBankType {get;set;}

    /**
    * @Description: Empty Constructor
    **/
    public TransactionAux() {}

    /**
    * @Description: Constructor
    **/
    public TransactionAux(IdName classification, IdName categorization, IdName specificType, String destinationBankType) {
      this.classification = classification;
      this.categorization = categorization;
      this.specificType = specificType;
      this.destinationBankType = destinationBankType;
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
    * @Description: traytd
    */
    public String traytd {get;set;}
    /**
    * @Description: perytd
    */
    public String perytd {get;set;}
    /**
    * @Description: tral12
    */
    public String tral12 {get;set;}
    /**
    * @Description: perl12
    */
    public String perl12 {get;set;}
    /**
    * @Description: product
    */
    public String product {get;set;}
    /**
    * @Description: channel
    */
    public String channel {get;set;}
    /**
    * @Description: transacc
    */
    public String transacc {get;set;}

    /**
    * @Description: maxDate
    */
    public Date maxDate {get;set;}


    /**
    * @Description: Empty Constructor
    **/
    public TableDataWrap() {}

    /**
    * @Description: Empty Constructor
    **/
    public TableDataWrap(String traytd, String perytd, String tral12, String perl12, String product, String channel, String transacc,Date maxDate) {
      this.traytd=traytd;
      this.perytd=perytd;
      this.tral12=tral12;
      this.perl12=perl12;
      this.channel=channel;
      this.product=product;
      this.transacc=transacc;
      this.maxDate=maxDate;
    }

  }

}