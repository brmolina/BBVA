/**
* ────────────────────────────────────────────────────────────────────
* CucoConstructor
* ────────────────────────────────────────────────────────────────────
* @author      CuCo CIB <globalhub_components.group@bbva.com>
* @modifiedBy
* @version     1.0
* @created     July 2021
* @modified
* @systemLayer
* ────────────────────────────────────────────────────────────────────
* @changes
*
* ────────────────────────────────────────────────────────────────────
*/
public with sharing class CucoConstructor {

    /**
    * SINGLETON PATTERN
    */
    private static CucoConstructor instance;

    /**
    * Constructor
    */
    private CucoConstructor() {
    }

    /**
    * getInstance
    */
    public static CucoConstructor gtInstance() {
        if(instance == null) {
            instance = new CucoConstructor();
        }
        return instance;
    }

    /**
    * Constructor
    */
    public class DataBooks {
        /**
        * Constructor
        */
        public Set<Id> idUser {get;set;}
        /**
        * Constructor
        */
        public List<String> lstCurrentPP {get;set;}
        /**
        * Constructor
        */
        public sObject book {get;set;}
    }
}