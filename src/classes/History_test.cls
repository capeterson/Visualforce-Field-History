@isTest
private class History_test {
	static testmethod void testNotes(){
		itil_b__Incident__c thisIncident = new itil_b__Incident__c();
		insert thisIncident;
		
		History incidentHistory = new History(thisIncident);
		incidentHistory.buildEntries();
		System.assertEquals(0,incidentHistory.events.size());
		
		Note newNote = new Note(parentId = thisIncident.id, title = 'a new note');
		insert newNote;
		incidentHistory.buildEntries();
		System.assertEquals(1,incidentHistory.events.size());
		
	}
	
	static testmethod void testActivities(){
		itil_b__Incident__c thisIncident = new itil_b__Incident__c();
		insert thisIncident;
		
		History incidentHistory = new History(thisIncident);
		incidentHistory.buildEntries();
		System.assertEquals(0,incidentHistory.events.size());
		
		Task newTask = new Task(whatId = thisIncident.id, subject='a new Task');
		insert newTask;
		
		Event newEvent = new Event(whatId = thisIncident.id,  subject='a new event', DurationInMinutes = 30, ActivityDateTime = Datetime.now(), RecordTypeId = itil_b.Util.getRecordType('Event','ChangeWindow').id );
		insert newEvent;
		
		incidentHistory.buildEntries();
		System.assertEquals(2,incidentHistory.events.size());
		
	}
	
	static testmethod void testHistory(){
		//This method contains no assertions because we cannot assert that customers have field history tracking set a specific way.
		Contact newContact = new Contact(LastName = 'Bob');
		
		insert newContact;
		itil_b__Incident__c thisIncident = new itil_b__Incident__c();
		insert thisIncident;
		
		History incidentHistory = new History(thisIncident);
		incidentHistory.buildEntries();
		System.assertEquals(0,incidentHistory.events.size());
		
		thisIncident.itil_b__subject__c = 'new subject';
		update thisIncident;
		
		thisIncident.itil_b__Contact__c = newContact.id;
		update thisIncident;
		
		itil_b__Incident__history thisHistory = new itil_b__Incident__history(parentId = thisIncident.id, field = 'created');
		insert thisHistory;
		
		History.FieldHistory thisUpdate = new History.FieldHistory(null, 'oldVal', 'newVal', DateTime.now(), 'itil_b__subject__c');
		incidentHistory.injectedResults.add(thisUpdate);
		
		incidentHistory.buildEntries(); 
		System.debug('\nIncident History: '+incidentHistory.events);
		
	}
	
	static testmethod void testGeneric(){
		Contact newContact = new Contact(LastName = 'Bob');
		insert newContact;
		itil_b__Incident__c thisIncident = new itil_b__Incident__c(itil_b__Contact__c = newContact.id);
		insert thisIncident;
		
		History incidentHistory = new History(thisIncident);
		incidentHistory.buildEntries();
		System.assertEquals(0,incidentHistory.events.size());
		
		itil_b__Worklog__c newWorklog = new itil_b__Worklog__c(itil_b__incident__c = thisIncident.id, name = 'a new worklog');
		insert newWorklog;
		
		incidentHistory.buildEntries();
		System.assertEquals(1,incidentHistory.events.size());
	}
}