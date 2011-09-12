@isTest
private class History_test {
	static testmethod void testNotes(){
		Contact con = new Contact(LastName = 'apex test');
		insert con;
		
		History objHistory = new History(con);
		objHistory.buildEntries();
		System.assertEquals(0,objHistory.events.size());
		
		Note newNote = new Note(parentId = con.id, title = 'a new note');
		insert newNote;
		objHistory.buildEntries();
		System.assertEquals(1,objHistory.events.size());
		
	}
	
	static testmethod void testActivities(){
		Account acct = new Account(Name = 'apex test');
		insert acct;
		
		History objHistory = new History(acct);
		objHistory.buildEntries();
		System.assertEquals(0,objHistory.events.size());
		
		Task newTask = new Task(whatId = acct.id, subject='a new Task');
		insert newTask;
		
		Event newEvent = new Event(whatId = acct.id,  subject='a new event', DurationInMinutes = 30, ActivityDateTime = Datetime.now() );
		insert newEvent;
		
		objHistory.buildEntries();
		System.assertEquals(2,objHistory.events.size(), 'Expected a single task and event, got :'+objHistory.events);
		
	}
	
	static testmethod void testHistory(){
		//This method contains no assertions because we cannot assert that customers have field history tracking set a specific way.
		Contact newContact = new Contact(LastName = 'apex test');
		insert newContact;
		
		History objHistory = new History(newContact);
		objHistory.buildEntries();
		System.assertEquals(0,objHistory.events.size());
		
		newContact.firstName = 'new subject';
		update newContact;
		
		ContactHistory thisHistory = new ContactHistory( ContactId = newContact.id, field = 'created');
		insert thisHistory;
		
		History.FieldHistory thisUpdate = new History.FieldHistory(null, 'oldVal', 'newVal', DateTime.now(), 'firstName');
		objHistory.injectedResults = new List<History.FieldHistory>{ thisUpdate };
		
		objHistory.buildEntries(); 
		System.debug('\nIncident History: '+objHistory.events);
		
	}
	
	static testmethod void testContactHistory(){
		Contact newContact = new Contact(LastName = 'Bob');
		
		insert newContact;
		
		History objHistory = new History(newContact);
		objHistory.buildEntries();
		System.assertEquals(0,objHistory.events.size());
		
		newContact.firstName = 'first name';
		update newContact;
		
		ContactHistory thisHistory = new ContactHistory(ContactId = newContact.id, field = 'created');
		insert thisHistory;
		
		History.FieldHistory thisUpdate = new History.FieldHistory(null, 'oldVal', 'newVal', DateTime.now(), 'firstName');
		objHistory.injectedResults = new List<History.FieldHistory>{ thisUpdate };
		
		objHistory.buildEntries(); 
		System.debug('\nContact History: '+objHistory.events);
		
	}
}