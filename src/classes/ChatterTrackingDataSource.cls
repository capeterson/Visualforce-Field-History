public with sharing class ChatterTrackingDataSource implements DataSource.Provider{
	private sObject subject;
	
	public ChatterTrackingDataSource(sObject subject){
		if(!SchemaUtil.isOrgChatterEnabled())
			System.assert(false,'Cannot create a ChatterTrackingDataSource if chatter is disabled!');
		this.subject = subject;
	}
	
	public String getProviderName(){
		return 'ChatterTracking';
	}
	public String getProviderLabel(){
		return 'Chatter';
	}
	
	public List<DataSource.Event> getEvents(DateTime startTime,DateTime endTime){
		List<DataSource.Event> result = new List<DataSource.Event>();
		String feedName;
		Schema.DescribeSObjectResult describe = subject.getSObjectType().getDescribe();
		
		if(describe.isCustom()){ //feeds have different naming schemes for standard vs custom objects
			feedName = describe.getName().replace('__c', '__Feed');
		}else{
			feedName = describe.getName() + 'Feed'; 
		}
		String queryString = 'SELECT id, CreatedDate, CreatedById, (SELECT id, fieldName, oldValue, newValue FROM FeedTrackedChanges) FROM '+feedName+' WHERE parentId = \''+subject.id+'\' AND Type = \'TrackedChange\'';
		System.debug('Running query: '+queryString);
		for(sObject item:Database.query(queryString)){
			for(FeedTrackedChange fieldChange:item.getSObjects('FeedTrackedChanges')){
				String fieldName = (''+fieldChange.get('FieldName')).replaceFirst('.+\\.','').toLowerCase();
				String fieldLabel = SchemaUtil.getFieldDescribes(subject.getSObjectType()).get( fieldName ).getDescribe().getLabel();
				result.add( 
					new DataSource.Event(
						this,
						(DateTime) item.get('createdDate'),
						fieldLabel + ' changed from "' + fieldChange.get('oldValue') + '" to "' + fieldChange.get('newValue')+ '".',
						(Id) item.get('CreatedById'),
						null
					)
				);
			}
		}
		return result;
	}
	
}