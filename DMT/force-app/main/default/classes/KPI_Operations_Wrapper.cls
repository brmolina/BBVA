/**
* ------------------------------------------------------------------------------------------------
* @Name     KPI_Operations_Service
* @Author   ivan.garces@bosonit.com
* @Date     Created: 2023-01-25
* ------------------------------------------------------------------------------------------------
* @Description Wrapper Class for request operations service
* ------------------------------------------------------------------------------------------------
*/
@SuppressWarnings('sf:AvoidFinalLocalVariable, sf:LogicInversion, sf:DUDataflowAnomalyAnalysis, sf:NcssMethodCount, sf:NPathComplexity, sf:CyclomaticComplexity, sf:TooManyMethods')
public with sharing class KPI_Operations_Wrapper {
    /**
     * @Description : Wrapper of petition
    */
    public class Wrapper {
        /**
        * @Description: petitionType
        */
        public List<Response> data {get;set;}
        /**
        * @Description: Empty Constructor
        **/
        public Wrapper() {}
        /**
        * @Description: Constructor
        **/
        public Wrapper(List<Response> data) {
            this.data = data;
        }
    }
    
    /**
    * @Description : Wrapper of response
    */
    public class Response {

        /**
        * @Description: code
        */

        public String code {get;set;}
        /**
        * @Description: name
        */

        public String name {get;set;}
        /**
        * @Description: group_y
        */
        public Group_y group_y {get;set;}

        /**
        * @Description: managerId
        */
        public String managerId {get;set;}

        /**
        * @Description: country
        */
        public Country country {get;set;}

        /**
        * @Description: contracts
        */
        public List<Contracts> contracts {get;set;}


        /**
        * @Description: Empty Constructor
        **/
        public Response() {}

        /**
        * @Description: Constructor
        **/
        public Response(String code,String name ,Group_y group_y, String managerId,  Country country,List<Contracts> contracts) {
        this.code = code;
        this.name = name;
        this.group_y = group_y;
        this.managerId = managerId;
        this.country = country;
        this.contracts = contracts;
        }
    }
    /**
    * @Description : Wrapper of Group 
    */
    public class Group_y {
        /**
        * @Description: id_y
        */
        public String id_y {get;set;}
        /**
        * @Description: description
        */
        public String description {get;set;}
        /**
        * @Description: country
        */
        public Country country {get;set;}
        /**
        * @Description: sector
        */
        public Sector sector {get;set;}
        /**
        * @Description: segment
        */
        public Segment segment {get;set;}
        /**
        * @Description: Empty Constructor
        **/
        public Group_y() {}
    }
    /**
    * @Description : Wrapper of Country 
    */
    public class Country {
        /**
        * @Description: id_y
        */
        public String id_y {get;set;}
        /**
        * @Description: id
        */
        public String description {get;set;}
        /**
        * @Description: Empty Constructor
        **/
        public Country() {}
    }
    /**
    * @Description : Wrapper of Sector 
    */
    public class Sector {
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
        public Sector() {}
    }
    /**
    * @Description : Wrapper of Activity 
    */
    public class Activity {
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
        public Activity() {}
    }
    /**
    * @Description : Wrapper of Segment 
    */
    public class Segment {
        /**
        * @Description: id_y
        */
        public String id_y {get;set;}
        /**
        * @Description: description
        */
        public String description {get;set;}

        /**
        * @Description: subSegment
        */
        public SubSegment subSegment {get;set;}
        /**
        * @Description: Empty Constructor
        **/
        public Segment() {}
    }
    /**
    * @Description : Wrapper of SubSegment 
    */
    public class SubSegment {
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
        public SubSegment() {}
    }

    /**
    * @Description : Wrapper of Contracts 
    */
    public class Contracts {
        /**
        * @Description: id_y
        */
        public String id_y {get;set;}
        /**
        * @Description: codeLocal
        */
        public String codeLocal {get;set;}
        /**
        * @Description: nameOriginSystem
        */
        public String nameOriginSystem {get;set;}
        /**
        * @Description: entity
        */
        public Entity entity {get;set;}
        /**
        * @Description: country
        */
        public Country country {get;set;}
        /**
        * @Description: codeOfficeBooking
        */
        public String codeOfficeBooking {get;set;}
        /**
        * @Description: initialDate
        */
        public String initialDate {get;set;}
        /**
        * @Description: expirationDate
        */
        public String expirationDate {get;set;}
        /**
        * @Description: sustainabilityDate
        */
        public String sustainabilityDate {get;set;}
        /**
        * @Description: businessArea
        */
        public String businessArea {get;set;}
        /**
        * @Description: product
        */
        public Product product {get;set;}
        /**
        * @Description: validYears
        */
        public Double validYears {get;set;}
        /**
        * @Description: initialMainAmount
        */
        public Double initialMainAmount {get;set;}
        /**
        * @Description: currency
        */
        public String currency_y {get;set;}
        /**
        * @Description: sustainabilityFamily
        */
        public SustainabilityFamily sustainabilityFamily {get;set;}
        /**
        * @Description: operationIndicatorType
        */
        public Boolean operationIndicatorType {get;set;}
        /**
        * @Description: dataValue
        */
        public DataValue dataValue {get;set;}
        /**
        * @Description: agencyIndicatorType
        */
        public Boolean agencyIndicatorType {get;set;}
        /**
        * @Description: project
        */
        public Project project {get;set;}
        /**
        * @Description: codeOfficeBooking
        */
        public Tranch tranch {get;set;}        
        /**
        * @Description: Empty Constructor
        **/
        public Contracts() {}
    }
    /**
    * @Description : Wrapper of Entity 
    */
    public class Entity {
        /**
        * @Description: id
        */
        public String id_y {get;set;}
        
        /**
        * @Description: Empty Constructor
        **/
        public Entity() {}
    }
    /**
    * @Description : Wrapper of Product 
    */
    public class Product {
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
        public Product() {}
    }
    /**
    * @Description : Wrapper of SustainabilityFamily 
    */
    public class SustainabilityFamily {
        /**
        * @Description: id_y
        */
        public String id_y {get;set;}
        /**
        * @Description: description
        */
        public String description {get;set;}
        /**
        * @Description: SustainabilityCategory
        */
        public SustainabilityCategory sustainabilityCategory {get;set;}
        
        /**
        * @Description: Empty Constructor
        **/
        public SustainabilityFamily() {}
    }
    /**
    * @Description : Wrapper of SustainabilityFamily 
    */
    public class SustainabilityCategory {
        /**
        * @Description: id_y
        */
        public String id_y {get;set;}
        /**
        * @Description: description
        */
        public String description {get;set;}
        /**
        * @Description: SustainabilityCategory
        */
        public SubSustainabilityCategory subsustainabilityCategory {get;set;}
        
        /**
        * @Description: Empty Constructor
        **/
        public SustainabilityCategory() {}
    }
    /**
    * @Description : Wrapper of SubSustainabilityCategory 
    */
    public class SubSustainabilityCategory {
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
        public SubSustainabilityCategory() {}
    }
    /**
    * @Description : Wrapper of DataValue 
    */
    public class DataValue {
        /**
        * @Description: id
        */
        public String variation {get;set;}
        /**
        * @Description: description
        */
        public String value {get;set;}
        /**
        * @Description: Empty Constructor
        **/
        public DataValue() {}
    }
    /**
    * @Description : Wrapper of Project 
    */
    public class Project {
        /**
        * @Description: id_y
        */
        public String id_y {get;set;}
        /**
        * @Description: Empty Constructor
        **/
        public Project() {}
    }
    /**
    * @Description : Wrapper of Tranch 
    */
    public class Tranch {
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
        public Tranch() {}
    }

    /**
    * @Description : Wrapper of Pagination 
    */
    public class Pagination {
        /**
        * @Description: Links
        */
        public Links links {get;set;}
        /**
        * @Description: page
        */
        public Decimal page {get;set;}
        /**
        * @Description: totalPage
        */
        public Decimal totalPage {get;set;}
        /**
        * @Description: totalElements
        */
        public Decimal totalElements {get;set;}
        /**
        * @Description: pageSize
        */
        public Decimal pageSize {get;set;}
        /**
        * @Description: Empty Constructor
        **/
        public Pagination() {}
    }

     /**
    * @Description : Wrapper of Links 
    */
    public class Links {
        /**
        * @Description: first
        */
        public String first {get;set;}

        /**
        * @Description: last
        */
        public String last {get;set;}
        /**
        * @Description: previous
        */
        public String previous {get;set;}
        /**
        * @Description: next
        */
        public String next {get;set;}
        /**
        * @Description: Empty Constructor
        **/
        public Links() {}
    }
  /**
  * @Description : Wrapper of petition
  */
  public class TableDataWrap {
    /**
    * @Description: businessArea
    */
    public String businessArea {get;set;}
    /**
    * @Description: operationId
    */
    public String operationId {get;set;}
    /**
    * @Description: client
    */
    public String client {get;set;}
    /**
    * @Description: initialDate
    */
    public Date initialDate {get;set;}
    /**
    * @Description: finalDate
    */
    public Date finalDate {get;set;}
    /**
    * @Description: initialAmount
    */
    public Double initialAmount {get;set;}
    /**
    * @Description: currency_y
    */
    public String currency_y {get;set;}

    /**
    * @Description: bookingCountry
    */
    public String bookingCountry {get;set;}
    /**
    * @Description: sustainableSubCategory
    */
    public String sustainableSubCategory {get;set;}
    /**
    * @Description: sustainableSubCategoryId
    */
    public String sustainableSubCategoryId {get;set;}
    /**
    * @Description: contractId
    */
    public String contractId {get;set;}


    /**
    * @Description: Empty Constructor
    **/
    public TableDataWrap() {}

    /**
    * @Description: Empty Constructor
    **/
    public TableDataWrap( String businessArea, String operationId, String client, Date initialDate, Date finalDate,
     Double initialAmount, String currency_y,String bookingCountry ,String sustainableCategory ,String sustainableSubCategory ,String sustainableSubCategoryId,
     String contractId) {
      this.businessArea=businessArea;
      this.operationId=operationId;
      this.client=client;
      this.initialDate=initialDate;
      this.finalDate=finalDate;
      this.initialAmount=initialAmount;
      this.currency_y=currency_y;
      this.bookingCountry=bookingCountry;
      this.sustainableSubCategory=sustainableSubCategory;
      this.sustainableSubCategoryId=sustainableSubCategoryId;
      this.contractId=contractId;
    }
  }
  
}