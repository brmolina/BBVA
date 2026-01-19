/**
* ------------------------------------------------------------------------------------------------
* @Name     PRW_Catalog_Service
* @Author   Iván Garcés
* @Date     Created: 2022-10-27
* ------------------------------------------------------------------------------------------------
* @Description Wrapper Class for request catalog service
* ------------------------------------------------------------------------------------------------
*/
@SuppressWarnings('sf:ShortVariable,sf:ShortClassName,sf:VariableNamingConventions,sf:LongVariable,sf:VariableDeclarationHidesAnothe')

  
public with sharing class PRW_Catalog_Service {
  /**
  * @Description : Wrapper of petition
  */
    public class Data {
        /**
        * @Description: petitionType
        */
        public List<Levels> data {get;set;}
    
        /**
        * @Description: Empty Constructor
        **/
        public Data() {}
    
        /**
        * @Description: Constructor
        **/
        public Data(List<Levels> data) {
          this.data = data;
        }
      }

      public class Levels {
        /**
        * @Description: levels
        */
        public List<Level> levels {get;set;}
    
        /**
        * @Description: Empty Constructor
        **/
        public Levels() {}
    
        /**
        * @Description: Constructor
        **/
        public Levels(List<Level> levels) {
          this.levels = levels;
        }
      }
      public class Level {
        /**
         * @Description : firstLevel
         */

         public Levelwrap firstLevel{get;set;}
         /**
         * @Description : secondLevel
         */

        public Levelwrap secondLevel {get;set;}
        /**
         * @Description : thirdLevel
         */

        public Levelwrap thirdLevel{get;set;}
        /**
         * @Description : fourthLevel
         */

        public Levelwrap fourthLevel{get;set;}
        /**
         * @Description : fifthLevel
         */

        public Levelwrap fifthLevel{get;set;}
        
        /**
         * @Description : Empty Constructor
         */
        public Level(){}
        /**
         * @Description : Constructor
         */
        public Level(Levelwrap firstLevel){
            this.firstLevel = firstLevel;
        }
        /**
         * @Description : Constructor
         */
        public Level(Levelwrap firstLevel,Levelwrap secondLevel){
            this.firstLevel = firstLevel;
            this.secondLevel = secondLevel;
        }
        /**
         * @Description : Constructor
         */
        public Level(Levelwrap firstLevel,Levelwrap secondLevel,Levelwrap thirdLevel){
            this.firstLevel = firstLevel;
            this.secondLevel = secondLevel;
            this.thirdLevel = thirdLevel;
        }
        /**
         * @Description : Constructor
         */
        public Level(Levelwrap firstLevel,Levelwrap secondLevel,Levelwrap thirdLevel,Levelwrap fourthLevel){
            this.firstLevel = firstLevel;
            this.secondLevel = secondLevel;
            this.thirdLevel = thirdLevel;
            this.fourthLevel = fourthLevel;
        }
        /**
         * @Description : Constructor
         */
        public Level(Levelwrap firstLevel,Levelwrap secondLevel,Levelwrap thirdLevel,Levelwrap fourthLevel,Levelwrap fifthLevel){
            this.firstLevel = firstLevel;
            this.secondLevel = secondLevel;
            this.thirdLevel = thirdLevel;
            this.fourthLevel = fourthLevel;
            this.fifthLevel = fifthLevel;
        }
      }
      public class Levelwrap {

        /**
        * @Description: id_y
        */
    
        public String id_y {get;set;}

        /**
        * @Description: value
        */
    
        public Decimal value {get;set;}
       
        /**
        * @Description: Empty Constructor
        **/
        public Levelwrap() {}
    
        /**
        * @Description: Constructor
        **/
        public Levelwrap(String id_y) {
          this.id_y = id_y;
        }

        public Levelwrap(String id_y,Decimal value) {
            this.id_y = id_y;
            this.value = value;
          }
      }
    //     /**
    //      * @Description : Wrapper of LevelsDataWrap
    //     */
    //   public class LevelsDataWrap{
    //     /**
    //      * @Description : levels
    //     */
    //     public List<LevelDataWrap> levels{get;set;}
    //     /**
    //      * @Description : empty constructor
    //     */
    //     public LevelsDataWrap (){}
    //     /**
    //      * @Description : LevelsDataWrap constructor
    //     */
    //     public LevelsDataWrap (List<LevelDataWrap> levels){
    //         this.levels = levels;
    //     }
    //   }
      /**
      * @Description : Wrapper of LevelDataWrap
      */
      public class LevelDataWrap{
        /**
        * @Description: firstLevel
        */
        public String firstLevel {get;set;}
        /**
        * @Description: secondLevel
        */
        public String secondLevel {get;set;}
        /**
        * @Description: thirdLevel
        */
        public String thirdLevel {get;set;}
        /**
        * @Description: fourthLevel
        */
        public String fourthLevel {get;set;}
        /**
        * @Description: fifthLevel
        */
        public String fifthLevel {get;set;}
        /**
         * @Description: Empty constructor
         */
        public LevelDataWrap(){}
        /**
         * @Description: Constructor
         */
        public LevelDataWrap(String firstLevel, String secondLevel , String thirdLevel, String fourthLevel , String fifthLevel){
            this.firstLevel = firstLevel;
            this.secondLevel = secondLevel;
            this.thirdLevel = thirdLevel;
            this.fourthLevel = fourthLevel;
            this.fifthLevel = fifthLevel;
        }
    }
}