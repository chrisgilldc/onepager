#!/usr/bin/python
import psycopg2
import gdata.docs
import gdata.docs.service
import gdata.spreadsheet.service
#regex stuff
import re

key= "0AgnoU1aB0owMdDRFNlM5NVpSMXRrcHNIZlN5YXc4MUE"
sheet = 'od6'

#connect to the database
conn = psycopg2.connect("dbname=avdt user=avmaps password=carto host=10.1.1.20")
#create a cursor object - the daemon that goes and does stuff
cursor = conn.cursor()



#login info
email = 'amervoteedaypython@gmail.com'
password = 'electionday'

client = gdata.spreadsheet.service.SpreadsheetsService()
client.email = email
client.password = password
#client.source = "a program running on the server"
client.ProgrammaticLogin()

ids = [['oe0', 'OH'],
['oe3', 'FL'],
['oe1', 'CO'],
['oe6', 'NM'],
['oe7', 'NC'],
['oe5', 'PA'],

['odt', 'MI'],
['ody', 'MN'],
['odz', 'WI'],
['odw', 'UT'],
['ode', 'NH'],
['odq', 'MT'],
['odo', 'NV']]
#['odu', 'WA'],

ids = [['ode', 'NH']]

#get the unnamed spreadsheet id
q = gdata.spreadsheet.service.DocumentQuery()
q['title'] = 'state leg records'
q['title-exact'] = 'true'
feed = client.GetSpreadsheetsFeed(query=q)
spreadsheet_id = feed.entry[0].id.text.rsplit('/',1)[1]


#ok, now the heavy lifting.  get a feed from each spreadsheet and turn it into useful stuff
for worksheet_id in ids:
	print worksheet_id
	#get the rows
	rows = client.GetListFeed(spreadsheet_id, worksheet_id[0]).entry
	#make a query out of the first row
	for row in rows:
		#we know the headers on the worksheet, so go ahead and use them
		#process results
		#chamber
		chamber = row.custom['chamber'].text
		if chamber is None:
			chamber = 'NA'
		elif 'House' in chamber or 'Assembly' in chamber:
			chamber = 'HD'
		elif 'Senate' in chamber:
			chamber = 'SD'
		else:
			chamber = 'NA'
		#district number
		district = row.custom['districtnumber'].text
		if len(district)==1:
			district = '00' + district
		elif len(district)==2:
			district = '0' + district
		
		#names
		firstname = row.custom['incumbentfirstname'].text
		if firstname is None:
			firstname = ''
		else:
			firstname = firstname.replace("'", "''")
			
		lastname = row.custom['incumbentlastname'].text
		if lastname is None:
			lastname = ''
		else:
			lastname = lastname.replace("'", "''")
		#party	
		if row.custom['incumbentparty'].text is None and firstname == '' and lastname == '':
			party = 'V'
		elif row.custom['incumbentparty'].text is None:
			party = ''
		elif '+' in row.custom['incumbentparty'].text: #NH is a weird state
			party = party = row.custom['incumbentparty'].text[0]
		else:
			party = row.custom['incumbentparty'].text 
		
		#phone nummber - clearing chaff
		raw_phone = row.custom['phone'].text
		if raw_phone is not None:
			number_filter = re.compile('\D') #set the regex to filter out anything that's not a digit
			filtered_phone = number_filter.sub('', raw_phone)[0:10] #replace everything besides digits with nothing, then take the leftmost ten digits
			#print filtered_phone
			
			phone = "(%s) %s-%s" % (filtered_phone[0:3], filtered_phone[3:6], filtered_phone[6:10])
			#print phone
		else:
			phone = ""

		#email
		email = row.custom['email'].text
		if email is None:
			email = ""
		else:
			email = email.replace("'", "")
		
		#address
		address = row.custom['address'].text
		if address is None:
			address = ""
		else:
			address = address.replace("'", "")
		
		#twitter
		twitter = row.custom['twitter'].text
		if twitter is None:
			twitter = ""
		
		#website
		website = row.custom['twitter'].text
		if website is None:
			website = ""
		
		#committees
		committees = row.custom['committees'].text
		if committees is None:
			committees = ""
		else:
			committees = committees.replace("'", "''")
		
		#notes
		notes = row.custom['notes'].text
		if notes is None:
			notes = ''
		else:
			notes = notes.replace("'", "''")
			#notes = notes.replace("\\", "\\\\")

		#check the character length of notes
		if len(notes) > 250:
			notes = notes[0:250]
			print "query truncated for %s %s %s" % (row.custom['state'].text, chamber, district)	
		#query = """insert into reporting.op_candidates values 
		#('%s', '%s', '%s', '%s', '%s', '%s', '%s', '%s', '%s', '%s', '%s', '%s'	)
		#""" % (row.custom['state'].text, chamber, district, firstname.replace("'", ""), lastname.replace("'", ""), party, row.custom['committees'].text, row.custom['address'].text, row.custom['email'].text, row.custom['phone'].text, row.custom['website'].text, row.custom['twitter'].text,)
		
		query = """update reporting.op_candidates set
		first_name = '%s'
		, last_name = '%s'
		, party = '%s'
		, committees = '%s'
		, address = '%s'
		, email = '%s'
		, phone = '%s'
		, website = '%s'
		, twitter = '%s'
		, notes = '%s'
		where
		state = '%s' and chamber = '%s' and district = '%s'
		""" % (firstname, lastname, party, committees, address, email, phone, website, twitter, notes, row.custom['state'].text, chamber, district)
		#print query
		cursor.execute(query)

		#then write to the notes table
		query = """update reporting.op_notes set
		notes = '%s'
		where state = '%s' and chamber = '%s' and district = '%s'
		""" % (notes, row.custom['state'].text, chamber, district)
		cursor.execute(query)


#commit my changes
conn.commit()
conn.close()


