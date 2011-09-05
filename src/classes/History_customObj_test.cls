@isTest
private class History_customObj_test {
	
	static testmethod void testNotes(){
		Custom_Object__c customObject = new Custom_Object__c();
		insert customObject;
		
		History objHistory = new History(customObject);
		objHistory.buildEntries();
		System.assertEquals(0,objHistory.events.size());
		
		Note newNote = new Note(parentId = customObject.id, title = 'a new note');
		insert newNote;
		objHistory.buildEntries();
		System.assertEquals(1,objHistory.events.size());
		
	}
	
	static testmethod void testActivities(){
		Custom_Object__c customObject = new Custom_Object__c();
		insert customObject;
		
		History objHistory = new History(customObject);
		objHistory.buildEntries();
		System.assertEquals(0,objHistory.events.size());
		
		Task newTask = new Task(whatId = customObject.id, subject='a new Task');
		insert newTask;
		
		Event newEvent = new Event(whatId = customObject.id,  subject='a new event', DurationInMinutes = 30, ActivityDateTime = Datetime.now() );
		insert newEvent;
		
		objHistory.buildEntries();
		System.assertEquals(2,objHistory.events.size());
		
	}
	
	static testmethod void testHistory(){
		//This method contains no assertions because we cannot assert that customers have field history tracking set a specific way.
		Contact newContact = new Contact(LastName = 'Bob');
		
		insert newContact;
		Custom_Object__c customObject = new Custom_Object__c();
		insert customObject;
		
		History objHistory = new History(customObject);
		objHistory.buildEntries();
		System.assertEquals(0,objHistory.events.size());
		
		customObject.Text_field__c = 'new subject';
		update customObject;
		
		Custom_Object__history thisHistory = new Custom_Object__history(parentId = customObject.id, field = 'created');
		insert thisHistory;
		
		History.FieldHistory thisUpdate = new History.FieldHistory(null, 'oldVal', 'newVal', DateTime.now(), 'text_field__c');
		objHistory.injectedResults = new List<History.FieldHistory>{ thisUpdate };
		
		objHistory.buildEntries(); 
		System.debug('\nIncident History: '+objHistory.events);
		
	}

}