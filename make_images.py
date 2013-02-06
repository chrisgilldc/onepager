#!/usr/bin/python
import psycopg2
import matplotlib
matplotlib.use('Agg') #necessary for unix - we need to tell matplotlib what kind of imaging nonsense to use before we can import pyplot
import matplotlib.pyplot as plt
import os, sys



basepath = "/data/scripts/onepagers/images/partgraph/"

#connect to the database
conn = psycopg2.connect("dbname=avdt user=avmaps password=carto host=10.1.1.20")
#create a cursor object - the daemon that goes and does stuff
cursor = conn.cursor()

#x series
x_series = [x for x in range(1, 101)] #1 through 100, but shifted because of python's starting at 0 quirk

#build the conditional for the queries
#get command line arguments we care about
#note that the first one is the name of this script
states = sys.argv[1:]
#if there are any states passed to this function, we need to add a condition on to all of our queries
if len(states)==0:
	query_coda = ""
else:
	#build the query coda
	query_coda = " and state in ("
	#add in all the states
	for st in range(len(states)):
		query_coda = query_coda + "'%s'," % states[st]
	#chop off the trailing comma and close the parenth
	query_coda = query_coda[:-1] + ")"



#get statewide results
query = "select * from reporting.op_partgraph  where chamber = 'SW'" + query_coda
print query
cursor.execute(query)
ySTATES = cursor.fetchall()
#cram this into a dictionary 
ySW = {}
for state in ySTATES:
	ySW[state[0]] = state[3:103]
	print state[0] 
	


#get district results
query = "select * from reporting.op_partgraph where chamber in ('SD', 'HD')" + query_coda 
print query
cursor.execute(query)
yDISTRICTS = cursor.fetchall()


#make pretty pictures!
for yDISTRICT_series in yDISTRICTS:

	#get the statewide series
	ySW_series = ySW[yDISTRICT_series[0]]
		
	#get the total and average of the y series for the district
	yDISTRICT_tot = sum(yDISTRICT_series[3:103])
	#yDISTRICT_avg = yDISTRICT_tot / float(len(yDISTRICT_series[3:103]))
	
	#get the total average if the statewide series
	ySW_tot = sum(ySW_series)
	#ySW_avg = ySW_tot / float(len(ySW_series))
	
	#scale the district down to percentages
	y1_series = [1000*x / yDISTRICT_tot for x in yDISTRICT_series[3:103]]
	#scale the statewide series down to percentages
	y2_series = [1000*x / ySW_tot for x in ySW_series]
	
	#plot district the series
	plt.plot(x_series, y1_series, color='black', label="District", linewidth=5)
	
	#plot the statewide series
	plt.plot(x_series, y2_series, linestyle = ':', color='blue', label='Statewide', linewidth=5)
	
	#make a legend
	plt.legend(('District', 'Statewide'), 'upper center')
	
	#call x partisanship
	plt.xlabel("Partisanship Score")
	#stretch the x axis so that it is larger than our data
	plt.xlim(-5, 105)
	#assign the axes to a avariable
	frame = plt.gca()
	#hide the y axis
	frame.axes.get_yaxis().set_visible(False)

	#plt.axis('off')


	#ok, have to pad the district number with zeros

	dist_num = yDISTRICT_series[2]
	if dist_num is not None:
		
		
		if len(dist_num)==1:
			dist_num = "00%s" % dist_num
		elif len(dist_num)==2:
			dist_num = "0%s" % dist_num
			


		#get the name of the district out of the data
		file_name = "%s_%s_%s.png" % (yDISTRICT_series[0], yDISTRICT_series[1], dist_num)	
		full_name = basepath
		full_name += file_name
	
		#save it
		plt.savefig(full_name, bbox_inches='tight')

		# Set group properly
		try:
			os.lchown(full_name, -1, 506)
		except:
			print "You don't have permission to change the group of %s" % file_name

	#clear the canvas in preparation of the next plot
	plt.clf()
