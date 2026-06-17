public with sharing class NONC_MatchMaker {

    /** @return lexical similarity value in the range [0,1] */
    public static double compareStrings(String str1, String str2) {
        List<String> pairs1 = wordLetterPairs(str1.toUpperCase());//NOSONAR
        List<String> pairs2 = wordLetterPairs(str2.toUpperCase());//NOSONAR
        Integer intersection = 0;
        Integer union = pairs1.size() + pairs2.size();

        for (Integer i=0; i<pairs1.size(); i++) {

            Object pair1=pairs1.get(i);

            for(Integer j=0; j<pairs2.size(); j++) {

                Object pair2=pairs2.get(j);

                if (pair1.equals(pair2)) {

                    intersection++;
                    pairs2.remove(j);

                    break;
                }
            }
        }
        return ((2.0*intersection)/union)*100;
    }

    /** @return an List<String> of 2-character Strings. */
    private static List<String> wordLetterPairs(String str) {
        List<String> allPairs = new List<String>();
        if (String.isBlank(str)) {
            return allPairs;
        }

        String[] words = str.split('\\s');

        for (String word : words) {
            if (String.isBlank(word)) continue; // saltar palabras vacías
            String[] pairsInWord = letterPairs(word);
            for (String p : pairsInWord) {
                allPairs.add(p);
            }
        }
        return allPairs;
    }

    /** @return an array of adjacent letter pairs contained in the input string */
    private static String[] letterPairs(String str) {
        if (String.isBlank(str) || str.length() < 2) {
            return new String[0];
        }

        Integer numPairs = str.length() - 1;
        String[] pairs = new String[numPairs];

        for (Integer i = 0; i < numPairs; i++) {
            pairs[i] = str.substring(i, i+2);
        }

        return pairs;
    }

    /** @return a Boolean if the string comparison meets the set percentage. */
    public static Boolean coincidentString(String masterField, String fieldToCompare, Double percentage) {
        Boolean isCoincident = (compareStrings(masterField,fieldToCompare)>=percentage)? true : false;
        return isCoincident;
    }

    /** @return a Boolean if number is equal. */
    public static Boolean coincidentNumber(Long masterNumber, Long numberToCompare) {
        Boolean isCoincident = (masterNumber==numberToCompare)? true : false;
        return isCoincident;
    }
}