/**
* ------------------------------------------------------------------------------------------------
* @Name     Arc_Gen_Sort_Sobs
* @Author   david.crespo.bordoncontractor@bbva.com
* @Date     Created: 2023-01-30
* @Group    ARCE
* ------------------------------------------------------------------------------------------------
* @Description Sort List objects
* ------------------------------------------------------------------------------------------------
* @Changes
* -----------------------------------------------------------------------------------------------
*/
@SuppressWarnings('sf:UseSingleton, sf:TooManyMethods, sf:NullAssignment, sf:ExcessiveMethodLength')
public class Arc_Gen_Sort_Sobs {// NOSONAR

    /**
      * @description        Sort SOBS ascending using a relationship
      * @param sobs         SObjects to sort
      * @param sortFields   List of SObjectField to capture sorting field.
                                The last item will be the value sorted on.
                                All preceeding items must be relationship fields
      */
    public static void ascending(SObject[] sobs, SObjectField[] sortFields) {
        sort(sobs, sortFields, false);
    }


    /**
      * @description        Sort SOBS descending using a relationship
      * @param sobs         SObjects to sort
      * @param sortFields   List of SObjectField to capture sorting field.
                                The last item will be the value sorted on.
                                All preceeding items must be relationship fields
    */
    public static void descending(SObject[] sobs, SObjectField[] sortFields) {
        sort(sobs, sortFields, true);
    }

    /**
      * @description        Sort SOBS ascending using a field
      * @param sobs         SObjects to sort
      * @param sortField    Field to sort on
    */
    public static void ascending(SObject[] sobs, SObjectField sortField) {
        sort(sobs, new SObjectField[]{ sortField }, false);
    }

    /**
      * @description        Sort SOBS descending using a field
      * @param sobs         SObjects to sort
      * @param sortField    Field to sort on
    */
    public static void descending(SObject[] sobs, SObjectField sortField) {
        sort(sobs, new SObjectField[]{ sortField }, true);
    }

    /** HELPERS **/

    //extracts values, determines type, runs sort
    private static void sort(SObject[] sobs, SObjectField[] sortFields, Boolean reverse) {
        final SObjectField sortField = sortFields.remove(sortFields.size()-1);

        final Object[] values = new Object[]{};
        for (SObject sob : sobs) {
            values.add(getValueFromRelationship(sob, sortFields, sortField));
        }
        sortContinue(sobs,sortField, reverse,values);
    }

    private static void sortContinue(SObject[] sobs, SObjectField sortField, Boolean reverse, Object[] values) {// NOSONAR
        //infer sort type
        BaseSOBQuickSort quickSort;
        final Schema.SoapType sType = sortField.getDescribe().getSoapType();
        if (sType == Schema.SoapType.Integer || sType == Schema.SoapType.Double || sType == Schema.SoapType.Time) {
            quickSort = new DecimalSOBQuicksort();
        } else if (sType == Schema.SoapType.String || sType == Schema.SoapType.Id || sType == Schema.SoapType.Base64binary) {
            quickSort = new StringSOBQuicksort();
        } else if (sType == Schema.SoapType.Date || sType == Schema.SoapType.DateTime) {
            quickSort = new DatetimeSOBQuicksort();
        } else if (sType == Schema.SoapType.Boolean) {
            quickSort = new BooleanSOBQuicksort();
        }
        quickSort.sort(values, sobs, reverse);
    }

    //extracts value from sob
    private static Object getValueFromRelationship(SObject sob, SObjectField[] relationships, SObjectField sortField) {
        Object ret;
        if (relationships.size() == 0) {
            ret = sob.get(sortField);
        } else {
            SObject parentSob = sob;
            for (Integer i = 0; i < relationships.size(); i++) {
                parentSob = parentSob.getSObject(relationships[i]);
                if (parentSob == null) {
                    ret = null;
                }
            }
            if (ret != null) {
                ret = parentSob.get(sortField);
            }
        }
        return ret;
    }

    /** QUICKSORT TYPE IMPLEMENTATIONS **/

    private class DecimalSOBQuicksort extends BaseSOBQuickSort {
    /**
      * @description        Sort SOBS descending using a field
      * @param value         SObjects to sort
      * @param pivot    Field to sort on
    */
        protected override Integer compareToPivot(Object value, Object pivot) {
            final Decimal val = (Decimal) value;
            final Decimal piv = (Decimal) pivot;
            Integer rep;
            if (val == piv) {
                rep = 0;
            } else if (val > piv) {
                rep = 1;
            } else {
                rep = -1;
            }
            return rep ;
        }
    }

    /**
      * @description        Sort SOBS ascending using a field
    */
    private class StringSOBQuicksort extends BaseSOBQuickSort {
    /**
      * @description        Sort SOBS ascending using a field
      * @param value        Objects to sort
      * @param pivot        Field to sort on
    */
        protected override Integer compareToPivot(Object value, Object pivot) {
            final String val = (String) value;
            final String piv = (String) pivot;
            Integer rep;
            if (val == piv) {
                rep = 0;
            } else if(val > piv) {
                rep = 1;
            } else {
                rep = -1;
            }
            return rep;
        }
    }

    /**
      * @description        Sort SOBS ascending using a field
    */
    private class DatetimeSOBQuicksort extends BaseSOBQuickSort {
    /**
      * @description        Sort SOBS ascending using a field
      * @param value        Objects to sort
      * @param pivot        Field to sort on
    */
        protected override Integer compareToPivot(Object value, Object pivot) {
            final DateTime val = (DateTime) value;
            final DateTime piv = (DateTime) pivot;
            Integer res;
            if (val == piv) {
                res = 0;
            } else if (val > piv) {
                res = 1;
            } else {
                res = -1;
            }
            return res;
        }
    }
    /**
      * @description        Sort SOBS ascending using a field
    */
    private class BooleanSOBQuicksort extends BaseSOBQuickSort {
    /**
      * @description        Sort SOBS ascending using a field
      * @param value         SObjects to sort
      * @param pivot    Field to sort on
    */
        protected override Integer compareToPivot(Object value, Object pivot) {
            final Boolean val = (Boolean) value;
            final Boolean piv = (Boolean) pivot;
            Integer intg;
            if(val && piv || !val && !piv) {
                intg = 0;
            } else if(val) {
                intg = 1;
            } else {
                intg = -1;
            }
            return intg;
        }
    }

    /** QUICKSORT BASE CLASS **/
    private abstract class BaseSOBQuickSort {
        /**
        *   array of SObject
        * @author DCB
        */
        private SObject[] sobs;
        /**
        *   integer
        * @author DCB
        */
        private Integer length;
        /**
        *   array of SObject
        * @author DCB
        */
        private Object[] values;
        /**
        *  Boolean
        * @author DCB
        */
        private Boolean reverse;

    /**
      * @description        Sort SOBS descending using a field
      * @param inputValues         SObjects to sort
      * @param sobs    Field to sort on
      * @param reverse    Field to sort on
    */
        public void sort(Object[] inputValues, SObject[] sobs, Boolean reverse) {
            this.reverse = reverse;

            // check for empty or null array
            if (inputValues == null || inputValues.size()==0) {
                return;
            }

            this.sobs = sobs;
            values = inputValues;

            length = values.size();
            quicksort(0, length - 1);
        }

        // returns 1 if greater, -1 if less than, 0 if equals
        private abstract Integer compareToPivot(Object value, Object pivot);// NOSONAR

        private void quicksort(Integer low, Integer high) {
            Integer intg = low, jnt = high;

            // into two array
            while (intg <= jnt) {
                final Object pivot = values[low + (high-low)/2];
                final Integer negator = reverse == true ? -1 : 1;
                // if current item from left array < pivot
                while (compareToPivot(values[intg], pivot) * negator == -1) {
                    //get the next item in left array
                    intg++;
                }
                // if current item from right array > pivot
                while (compareToPivot(values[jnt], pivot) * negator == 1) {
                    //get the next item in right array
                    jnt--;
                }

                //if left is larger than pivot and right is smaller, exchange
                if (intg <= jnt) {
                    exchangeObject(intg, jnt);
                    intg++;
                    jnt--;
                }
            }

            // recursion
            if (low < jnt) {
                quicksort(low, jnt);
            }
            if (intg < high) {
                quicksort(intg, high);
            }
        }

        private void exchangeObject(Integer intg, Integer jnt) {
            final Object temp = values[intg];
            values[intg] = values[jnt];
            values[jnt] = temp;

            exchangeSob(intg, jnt);
        }

        private void exchangeSob(Integer intg, Integer jnt) {
            final SObject temp = sobs[intg];
            sobs[intg] = sobs[jnt];
            sobs[jnt] = temp;
        }
    }
}