/*
add map of child name of query string
build query in fetch method
then parse
*/

/**
 * This class is used to model a full history timeline for an sObject
 * pulling data from most available sources, and showing a unified view.
 * Think of this as an enhanced version of the history related list.
 * @author cpeterson
 **/
public with sharing class History {
	private static final integer SUBQUERYCOUNT = 10; //the number of subqueries to run per SOQL query. Lower this if you get query too complex errors.
	
	public sObject subject {get; set;}
	public boolean includeChatter {get; private set;}
	public List<HistoryEvent> events {get; set;}
	public transient Schema.DescribesObjectResult objectType {get; set;}
	public List<FieldHistory> injectedResults {get; set{
			System.assert(Test.isRunningTest(),'injectedResults may only be set inside of test methods.');
			injectedResults = value;
		}
	}
	private Map<string,Schema.sObjectField> fields;
	
	public History(sObject subject){
		this.subject = subject;
		this.events = new List<HistoryEvent>();
		this.includeChatter = false;
		
		objectType = subject.getsObjectType().getDescribe();
		fields = new Map<String,Schema.sObjectField>();
		fields = SchemaUtil.getFieldDescribes(objectType.getSObjectType());
	}
	public History(sObject subject, boolean includeChatter){
		this.subject = subject;
		this.events = new List<HistoryEvent>();
		this.includeChatter = includeChatter;
		
		objectType = subject.getsObjectType().getDescribe();
		fields = new Map<String,Schema.sObjectField>();
		Map<String,Schema.sObjectField> caseSensitiveFields = SchemaUtil.getFieldDescribes( subject.getSObjectType() );
		for(String key:caseSensitiveFields.keySet()){
			fields.put(
				key.toLowerCase(),
				caseSensitiveFields.get(key)
			);
		}
	}
	
	public void buildEntries(){
		events = new List<HistoryEvent>();
		Schema.Describesobjectresult r = subject.getSObjectType().getDescribe();
		List<Schema.ChildRelationship> C = R.getChildRelationships();
		
		if(includeChatter)
			addChatter();
		HistoryEvent event;
		Map<String,String> subqueries = new Map<String,String>();
		for(Schema.Childrelationship child:C){
			string childName = child.getChildsObject().getDescribe().getName();
			String relName = child.getRelationshipName();
			String subqueryString = '';
			if(child.getChildSObject().getDescribe().isQueryable()){
				String objectName = child.getChildSObject().getDescribe().getName();
				if(relName == null){ //removes relationships that aren't retrievable with a subquery
					continue;
				} else if(objectName.endsWith('History')){
					if(injectedResults != null ){
						//this is from inside a test - run some special logic
						addHistory( injectedResults , 'Record Edited');
					} else {
						String query = 'SELECT id, field, oldValue, newValue, CreatedById, CreatedDate FROM '+child.getChildsObject().getDescribe().getName()+' WHERE '+child.getField()+' = \''+subject.id+'\'';
						addHistory( uglyHack( Database.Query(query) ), 'Record Edited' );
						continue;
					}
				}else if(objectName.contains('PartnerNetwork') 
					|| objectName == 'ProcessInstance'
					|| objectName.contains('__Tag')
					|| objectName == 'EntitySubscription'){ //Some sObjects are there just to make life hard...
					continue;
				}else{
					Schema.sObjectField nameField = SchemaUtil.getLabelField( child.getChildSObject() );
					if(nameField == null){
						System.debug(LoggingLevel.Error,'No label field found for '+child.getChildSObject());
						continue; //no label - we can't display the object
					}
					subqueryString += '(SELECT id, '+nameField.getDescribe().getName()+', CreatedById, CreatedDate FROM '+relName+')';
					//addGeneric( Database.Query(query) );
				}
			} else {
				System.debug(child.getChildsObject().getDescribe().getLabel()+' is not queryable.');
				continue;
			}
			subqueries.put(relName,subqueryString);
			if(subqueries.size() >= SUBQUERYCOUNT){
				fetchHistory(subqueries);
				subqueries.clear();
			}
		}
		if(subqueries.size() > 0)
			fetchHistory(subqueries);
		
		quicksort(events, 0, events.size() -1 );
	}
	
	private void fetchHistory(Map<String,String> subqueries){
		String query = 'SELECT id, ';
		for(String key:subqueries.keySet()){
			query += subqueries.get(key) + ', ';
		}
		query = query.substring(0, query.length() - 2); //chop off the final space and comma
		query += ' FROM '+subject.getSObjectType().getDescribe().getName()+' WHERE id = \''+subject.id+'\'';
		System.debug('Running query: '+query);
		sObject result = Database.query(query);
		addSObjects(result,subQueries.keySet());
		System.debug(LoggingLevel.Error, 'Ran queries!'+ result);
	}

	private void addChatter(){
		String feedName;
		Schema.DescribeSObjectResult describe = subject.getSObjectType().getDescribe();
		
		if(describe.isCustom()){ //feeds have different naming schemes for standard vs custom objects
			feedName = describe.getName().replace('__c', '__Feed');
		}else{
			feedName = describe.getName() + 'Feed'; 
		}
		List<FieldHistory> histories = new List<FieldHistory>();
		String queryString = 'SELECT id, CreatedDate, CreatedById, (SELECT id, fieldName, oldValue, newValue FROM FeedTrackedChanges) FROM '+feedName+' WHERE parentId = \''+subject.id+'\' AND Type = \'TrackedChange\'';
		System.debug('Running query: '+queryString);
		for(sObject item:Database.query(queryString)){
			for(FeedTrackedChange fieldChange:item.getSObjects('FeedTrackedChanges')){
				histories.add( 
					new FieldHistory(
						(id) item.get('createdById'),
						fieldChange.get('oldValue')+'',
						fieldChange.get('newValue')+'',
						(DateTime) item.get('createdDate'),
						(''+fieldChange.get('FieldName')).replaceFirst('.+\\.','') //chatter tracked fields start with the object name, so we cut off up to the .
					)
				);
			}
		}
		this.addHistory(histories, 'Chatter Tracking');
	}	
	
	private void addSObjects(sObject queryResult, Set<String> relNames){
		//TODO
		for(String relName:relNames){
			List<sObject> objs = queryResult.getSObjects(relName);
			if(objs == null){
				System.debug(LoggingLevel.Error,'FAILED! got no objects out of '+queryResult+' for '+relName);
				continue;	
			}
			Set<id> userIds = new Set<id>();
			for(sObject obj:objs)
				userIds.add((id)obj.get('CreatedById'));
			Map<id,User> users = new Map<id,User>([SELECT id, name FROM User WHERE id IN :userIds]);
			Schema.sObjectType objType = objs.get(0).getSObjectType();
			Schema.sObjectField labelField = SchemaUtil.getLabelField(objType);
			if(labelField == null)
				continue;
			for(sObject obj:objs){
				try{HistoryEvent event = new HistoryEvent(
					(User) users.get( (id) obj.get('CreatedById') ), 
					DateTime.valueOf( obj.get('CreatedDate') ), 
					String.valueOf( obj.get(labelField) ), 
					'New '+objType.getDescribe().getName()
				);
				event.detailId = obj.id;
				events.add(event);
				}catch(Exception e){
					System.assert(false,'Fatal: '+obj+' label:'+labelField);
				}
			}
		}
	}
	
	private void addHistory(List<FieldHistory> fieldChanges, String eventType){
		HistoryEvent event;
		Set<id> userIds = new Set<id>();
		for(FieldHistory fieldChange:fieldChanges){
			userIds.add(fieldChange.CreatedById);
		}
		Map<id,User> users = new Map<id,User>([SELECT id, name FROM User WHERE id IN :userIds]);
		
		for(FieldHistory fieldChange:fieldChanges){
			String oldValue = fieldChange.oldValue;
			boolean isJunk = true;
			try{
				id thisId = oldValue;
			}catch(System.StringException e){
				//A junk row with IDs rather than names is inserted for every change, we want to ignore that one.
				isJunk = false;
			}
			
			if(!isJunk){
				String description = parseFieldHistory(fieldChange);
				event = new HistoryEvent(
					users.get( fieldChange.CreatedById ),
					fieldChange.CreatedDate, 
					description, eventType);
				events.add(event);
			}
		}
	}
	private void addGeneric(List<sObject> objects){
		HistoryEvent event;
		string objectType;
		Map<id,User> users = new Map<id,User>([SELECT id, name FROM User WHERE id IN :Util.getIdFields(objects,'CreatedById')]);
		
		for(sObject thisObject:objects){
			if( objectType == null ) { objectType = thisObject.getSObjectType().getDescribe().getLabel(); } 
			event = new HistoryEvent(
				(User) users.get( (id) thisObject.get('CreatedById') ), 
				DateTime.valueOf( thisObject.get('CreatedDate') ), 
				String.valueOf( thisObject.get('name') ), 
				'New '+objectType);
			event.detailId = thisObject.id;
			events.add(event);
		}
	}
	
	
    private string parseFieldHistory(FieldHistory fieldHistory){
    	string result = 'this is a bad value';
    	string oldValue = fieldHistory.oldValue;
    	string newValue = fieldHistory.newValue;
    	
    	string fieldLabel;
    	
    	if(String.ValueOf( fieldHistory.Field ) == 'created'){
    		return 'Created';
    	} //special case for the special created field
    	
    	//Get the label for the related field. We don't want to show the developerName in the UI
    	Schema.sObjectField F = fields.get( fieldHistory.Field.toLowerCase() );
    	
    	if( F == null ||  (!F.getDescribe().isCustom() && F.getDescribe().isIdLookup()) ){
    		F = fields.get( fieldHistory.Field.toLowerCase()+'id' ); //standard lookup fields have to be queried with Id at the end just to make life hard.
    		for(String key: fields.keySet()){
    			System.debug(key);
    		}
    		fieldLabel = F.getDescribe().getLabel();
    		fieldLabel = fieldLabel.substring(0,fieldLabel.length() - 3); //Cut off the space ID part of the label.
    	}else{
    		fieldLabel = F.getDescribe().getLabel();
    	}
    		
    	System.assert(F != null, fieldHistory);
    	
    	if(oldValue == null && newValue == null){
    		result = fieldLabel+' modified';
    	} else {
    		result = 'Field '+fieldLabel+' changed from '+oldValue+' to '+newValue;
    	}
    	
    	return result;
    }
    
    /**
     * From http://blog.sforce.com/sforce/2008/09/sorting-collect.html
     * Modified to our needs by cpeterson
     **/
    private static void quicksort(List<HistoryEvent> a, Integer lo0, Integer hi0) {
        Integer lo = lo0;
        Integer hi = hi0;
        
        if (lo >= hi) {
            return;
        } else if( lo == hi - 1 ) {
        
            if (a[lo].timestamp > a[hi].timestamp) {
                HistoryEvent o = a[lo];
                a[lo]         = a[hi];
                a[hi]         = o;
            }
            return;
        }
        HistoryEvent pivot = a[(lo + hi) / 2];
        a[(lo + hi) / 2] = a[hi];
        a[hi] = pivot;
        while( lo < hi ) {
            while (a[lo].timestamp <= pivot.timestamp && lo < hi) { lo++; }
            while (pivot.timestamp <= a[hi].timestamp && lo < hi ) { hi--; }
            
            if( lo < hi ){
                HistoryEvent o = a[lo];
                a[lo]         = a[hi];
                a[hi]         = o;
            }
        }
        
        a[hi0] = a[hi];
        a[hi] = pivot;
        
        quicksort(a, lo0, lo-1);
        quicksort(a, hi+1, hi0);
    }
	public void invertList(){
		Integer lo = 0;
		Integer hi = events.size() - 1;
		while(lo < hi){
			HistoryEvent o = events[lo];
			events[lo] = events[hi];
			events[hi] = o;
			lo++;
			hi--;
		}
	}
	
	public class HistoryEvent{
		public String description {get; set;}
		public String eventType {get; set;}
		public DateTime timestamp {get; set;}
		public User modifiedBy {get; set;}
		public id detailId {get; set;}
		
		public HistoryEvent(User modifiedBy, DateTime timestamp, String description, String eventType){
			this.modifiedBy = modifiedBy;
			this.timestamp = timestamp;
			this.description = description;
			this.eventType = eventType;
		}
		
		public string getShortDate(){
			return timestamp.format('MM/dd hh:mm'); //short format used for accordion pannel
		}
		public string getFormatted(){
			return timestamp.format(); //timestamp localized to current user
		}
		
	}
	
	public class FieldHistory{
		//So this class is stupid, almost usless, but mandatory to test field history
		
		public id parentId;
		public string oldValue;
		public string newValue;
		public string field;
		public id createdByid;
		public DateTime createdDate;
		
		public FieldHistory(sObject subject){
			createdById = (id) subject.get('CreatedById');
			//parentId = (id) subject.get('parentId');
			oldValue = String.valueOf( subject.get('oldValue') );
			newValue = String.valueOf( subject.get('newValue') );
			createdDate = (DateTime) subject.get('CreatedDate');
			field = String.valueOf( subject.get('field') );
		}
		public FieldHistory(id createdById, string oldValue, string newValue, DateTime createdDate, string field){
			this.createdById = createdById;
			this.oldValue = oldValue;
			this.newValue = newValue;
			this.createdDate = createdDate;
			this.field = field;
		}
	}
	
	public static List<FieldHistory> uglyHack(List<sObject> subjects){
		List<FieldHistory> result = new List<FieldHistory>();
		for(sObject subject:subjects){
			result.add( new FieldHistory(subject) );
		}
		return result;
	}
	
	
}