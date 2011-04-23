global with sharing class sObjectUtils {
    /**
     * This method accepts the ID of any object type and returns the full name, including prefix of the sObject
     * type to which it belongs.
     * @author cpeterson
     **/
    public static Schema.SObjectType getObjectType(id subject){
        Schema.SObjectType result;
        string target = subject;
        Map<String, Schema.SObjectType> gd = Schema.getGlobalDescribe();
        string keyPrefix;
        
        for(Schema.SObjectType describe: gd.values() ){
            keyPrefix = describe.getDescribe().getKeyPrefix();
            if(keyPrefix != null && target.startsWith(keyPrefix)){
                result = describe;
                break; //no need to keep looking
            }
        }
        return result;
    }
    
    public static sObject getAllFields(id subject){
        Schema.SObjectType objectType = getObjectType(subject);
        Map<String, Schema.SObjectField> fields = objectType.getDescribe().fields.getMap();
        string queryString = 'SELECT ';
        for(Schema.sObjectField field:fields.values()){
            queryString += ' '+field.getDescribe().getName()+', ';
        }
        queryString = queryString.substring(0, queryString.length()-2)+' FROM '+objectType.getDescribe().getName()+' WHERE id = \''+subject+'\' LIMIT 1';
        sObject result = Database.query(queryString);
        return result;
    }
    
}