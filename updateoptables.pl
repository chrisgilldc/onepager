#!/usr/bin/perl

use POSIX;
use DBI;
use Text::Template;
use Benchmark;

# States to build
$tstates="'CO','FL','ME','MI','MN','MT','NC','NH','NM','NV','OH','PA','WI'";
if ( length $ARGV[0] > 0 ) {
	$tstates="'$ARGV[0]'";
}

### Config stuff here
# Database setup
$dbname=avdt;
$dbhost="10.1.1.20";
$dbuser=avmaps;
$dbpw=carto;

### End config stuff. Time to do it!

# Setup
# Open the database handle
my $dbh = DBI->connect("DBI:Pg:dbname=$dbname;host=$dbhost",$dbuser,$dbpw)
	or die "Couldn't connect to database: " . DBI->errstr;

print "Preparing all states... (";
$t0 = Benchmark->new;
# Get data on states we care about
$query="SELECT state,col_gov,col_ussen,col_ncecsd,col_ncechd,ncec_sumlvl_sd,ncec_sumlvl_hd FROM reporting.op_notes WHERE state IN (${tstates}) GROUP BY state,col_gov,col_ussen,col_ncecsd,col_ncechd,ncec_sumlvl_sd,ncec_sumlvl_hd ORDER BY state";
my $stqh = $dbh->prepare($query)
	or die "Couldn't prepare statement: " . $dbh->errstr;
$stqh->execute()
	or die "Couldn't execute statement: " . $stqh->errstr;
$t1 = Benchmark->new;
$td = timediff($t1,$t0);
print timestr($td),")\n";

print "Beginning state by state processing...\n";

# Okay, we now have the states and their extents and can set up our state variables.

while ( ($state,$col_gov,$col_ussen,$col_ncecsd,$col_ncechd,$ncec_sumlvl_sd,$ncec_sumlvl_hd) = $stqh->fetchrow_array() ) {
	print "State: ${state}\n\tDeleting... (";

	$t0 = Benchmark->new;
	# Delete rows for the state we're re-running
	$drstmt = "DELETE FROM reporting.op_data WHERE state='${state}'";
	$sth = $dbh->prepare($drstmt);
	$sth->execute
		or die "Couldn't execute statement: " . $sth->errstr;
	$drstmt = "DELETE FROM reporting.op_partgraph WHERE state='${state}'";
	$sth = $dbh->prepare($drstmt);
	$sth->execute
		or die "Couldn't execute statement: " . $sth->errstr;
	$t1 = Benchmark->new;
	$td = timediff($t1,$t0);
	print timestr($td),")\n";

	# Okay, we've got our plan, so now we do it twice, once for senate, once for house.
	print "\tStatewide\n\t\tPartgraph...(";
	$query="INSERT INTO reporting.op_partgraph
		select
		'${state}' as state,
		'SW' as chamber,
		NULL as district,
		sum(CASE WHEN partisanscore2012 >= 0 AND partisanscore2012 < 1 THEN 1 ELSE 0 END) as b0,
		sum(CASE WHEN partisanscore2012 >= 1 AND partisanscore2012 < 2 THEN 1 ELSE 0 END) as b1,
		sum(CASE WHEN partisanscore2012 >= 2 AND partisanscore2012 < 3 THEN 1 ELSE 0 END) as b2,
		sum(CASE WHEN partisanscore2012 >= 3 AND partisanscore2012 < 4 THEN 1 ELSE 0 END) as b3,
		sum(CASE WHEN partisanscore2012 >= 4 AND partisanscore2012 < 5 THEN 1 ELSE 0 END) as b4,
		sum(CASE WHEN partisanscore2012 >= 5 AND partisanscore2012 < 6 THEN 1 ELSE 0 END) as b5,
		sum(CASE WHEN partisanscore2012 >= 6 AND partisanscore2012 < 7 THEN 1 ELSE 0 END) as b6,
		sum(CASE WHEN partisanscore2012 >= 7 AND partisanscore2012 < 8 THEN 1 ELSE 0 END) as b7,
		sum(CASE WHEN partisanscore2012 >= 8 AND partisanscore2012 < 9 THEN 1 ELSE 0 END) as b8,
		sum(CASE WHEN partisanscore2012 >= 9 AND partisanscore2012 < 10 THEN 1 ELSE 0 END) as b9,
		sum(CASE WHEN partisanscore2012 >= 10 AND partisanscore2012 < 11 THEN 1 ELSE 0 END) as b10,
		sum(CASE WHEN partisanscore2012 >= 11 AND partisanscore2012 < 12 THEN 1 ELSE 0 END) as b11,
		sum(CASE WHEN partisanscore2012 >= 12 AND partisanscore2012 < 13 THEN 1 ELSE 0 END) as b12,
		sum(CASE WHEN partisanscore2012 >= 13 AND partisanscore2012 < 14 THEN 1 ELSE 0 END) as b13,
		sum(CASE WHEN partisanscore2012 >= 14 AND partisanscore2012 < 15 THEN 1 ELSE 0 END) as b14,
		sum(CASE WHEN partisanscore2012 >= 15 AND partisanscore2012 < 16 THEN 1 ELSE 0 END) as b15,
		sum(CASE WHEN partisanscore2012 >= 16 AND partisanscore2012 < 17 THEN 1 ELSE 0 END) as b16,
		sum(CASE WHEN partisanscore2012 >= 17 AND partisanscore2012 < 18 THEN 1 ELSE 0 END) as b17,
		sum(CASE WHEN partisanscore2012 >= 18 AND partisanscore2012 < 19 THEN 1 ELSE 0 END) as b18,
		sum(CASE WHEN partisanscore2012 >= 19 AND partisanscore2012 < 20 THEN 1 ELSE 0 END) as b19,
		sum(CASE WHEN partisanscore2012 >= 20 AND partisanscore2012 < 21 THEN 1 ELSE 0 END) as b20,
		sum(CASE WHEN partisanscore2012 >= 21 AND partisanscore2012 < 22 THEN 1 ELSE 0 END) as b21,
		sum(CASE WHEN partisanscore2012 >= 22 AND partisanscore2012 < 23 THEN 1 ELSE 0 END) as b22,
		sum(CASE WHEN partisanscore2012 >= 23 AND partisanscore2012 < 24 THEN 1 ELSE 0 END) as b23,
		sum(CASE WHEN partisanscore2012 >= 24 AND partisanscore2012 < 25 THEN 1 ELSE 0 END) as b24,
		sum(CASE WHEN partisanscore2012 >= 25 AND partisanscore2012 < 26 THEN 1 ELSE 0 END) as b25,
		sum(CASE WHEN partisanscore2012 >= 26 AND partisanscore2012 < 27 THEN 1 ELSE 0 END) as b26,
		sum(CASE WHEN partisanscore2012 >= 27 AND partisanscore2012 < 28 THEN 1 ELSE 0 END) as b27,
		sum(CASE WHEN partisanscore2012 >= 28 AND partisanscore2012 < 29 THEN 1 ELSE 0 END) as b28,
		sum(CASE WHEN partisanscore2012 >= 29 AND partisanscore2012 < 30 THEN 1 ELSE 0 END) as b29,
		sum(CASE WHEN partisanscore2012 >= 30 AND partisanscore2012 < 31 THEN 1 ELSE 0 END) as b30,
		sum(CASE WHEN partisanscore2012 >= 31 AND partisanscore2012 < 32 THEN 1 ELSE 0 END) as b31,
		sum(CASE WHEN partisanscore2012 >= 32 AND partisanscore2012 < 33 THEN 1 ELSE 0 END) as b32,
		sum(CASE WHEN partisanscore2012 >= 33 AND partisanscore2012 < 34 THEN 1 ELSE 0 END) as b33,
		sum(CASE WHEN partisanscore2012 >= 34 AND partisanscore2012 < 35 THEN 1 ELSE 0 END) as b34,
		sum(CASE WHEN partisanscore2012 >= 35 AND partisanscore2012 < 36 THEN 1 ELSE 0 END) as b35,
		sum(CASE WHEN partisanscore2012 >= 36 AND partisanscore2012 < 37 THEN 1 ELSE 0 END) as b36,
		sum(CASE WHEN partisanscore2012 >= 37 AND partisanscore2012 < 38 THEN 1 ELSE 0 END) as b37,
		sum(CASE WHEN partisanscore2012 >= 38 AND partisanscore2012 < 39 THEN 1 ELSE 0 END) as b38,
		sum(CASE WHEN partisanscore2012 >= 39 AND partisanscore2012 < 40 THEN 1 ELSE 0 END) as b39,
		sum(CASE WHEN partisanscore2012 >= 40 AND partisanscore2012 < 41 THEN 1 ELSE 0 END) as b40,
		sum(CASE WHEN partisanscore2012 >= 41 AND partisanscore2012 < 42 THEN 1 ELSE 0 END) as b41,
		sum(CASE WHEN partisanscore2012 >= 42 AND partisanscore2012 < 43 THEN 1 ELSE 0 END) as b42,
		sum(CASE WHEN partisanscore2012 >= 43 AND partisanscore2012 < 44 THEN 1 ELSE 0 END) as b43,
		sum(CASE WHEN partisanscore2012 >= 44 AND partisanscore2012 < 45 THEN 1 ELSE 0 END) as b44,
		sum(CASE WHEN partisanscore2012 >= 45 AND partisanscore2012 < 46 THEN 1 ELSE 0 END) as b45,
		sum(CASE WHEN partisanscore2012 >= 46 AND partisanscore2012 < 47 THEN 1 ELSE 0 END) as b46,
		sum(CASE WHEN partisanscore2012 >= 47 AND partisanscore2012 < 48 THEN 1 ELSE 0 END) as b47,
		sum(CASE WHEN partisanscore2012 >= 48 AND partisanscore2012 < 49 THEN 1 ELSE 0 END) as b48,
		sum(CASE WHEN partisanscore2012 >= 49 AND partisanscore2012 < 50 THEN 1 ELSE 0 END) as b49,
		sum(CASE WHEN partisanscore2012 >= 50 AND partisanscore2012 < 51 THEN 1 ELSE 0 END) as b50,
		sum(CASE WHEN partisanscore2012 >= 51 AND partisanscore2012 < 52 THEN 1 ELSE 0 END) as b51,
		sum(CASE WHEN partisanscore2012 >= 52 AND partisanscore2012 < 53 THEN 1 ELSE 0 END) as b52,
		sum(CASE WHEN partisanscore2012 >= 53 AND partisanscore2012 < 54 THEN 1 ELSE 0 END) as b53,
		sum(CASE WHEN partisanscore2012 >= 54 AND partisanscore2012 < 55 THEN 1 ELSE 0 END) as b54,
		sum(CASE WHEN partisanscore2012 >= 55 AND partisanscore2012 < 56 THEN 1 ELSE 0 END) as b55,
		sum(CASE WHEN partisanscore2012 >= 56 AND partisanscore2012 < 57 THEN 1 ELSE 0 END) as b56,
		sum(CASE WHEN partisanscore2012 >= 57 AND partisanscore2012 < 58 THEN 1 ELSE 0 END) as b57,
		sum(CASE WHEN partisanscore2012 >= 58 AND partisanscore2012 < 59 THEN 1 ELSE 0 END) as b58,
		sum(CASE WHEN partisanscore2012 >= 59 AND partisanscore2012 < 60 THEN 1 ELSE 0 END) as b59,
		sum(CASE WHEN partisanscore2012 >= 60 AND partisanscore2012 < 61 THEN 1 ELSE 0 END) as b60,
		sum(CASE WHEN partisanscore2012 >= 61 AND partisanscore2012 < 62 THEN 1 ELSE 0 END) as b61,
		sum(CASE WHEN partisanscore2012 >= 62 AND partisanscore2012 < 63 THEN 1 ELSE 0 END) as b62,
		sum(CASE WHEN partisanscore2012 >= 63 AND partisanscore2012 < 64 THEN 1 ELSE 0 END) as b63,
		sum(CASE WHEN partisanscore2012 >= 64 AND partisanscore2012 < 65 THEN 1 ELSE 0 END) as b64,
		sum(CASE WHEN partisanscore2012 >= 65 AND partisanscore2012 < 66 THEN 1 ELSE 0 END) as b65,
		sum(CASE WHEN partisanscore2012 >= 66 AND partisanscore2012 < 67 THEN 1 ELSE 0 END) as b66,
		sum(CASE WHEN partisanscore2012 >= 67 AND partisanscore2012 < 68 THEN 1 ELSE 0 END) as b67,
		sum(CASE WHEN partisanscore2012 >= 68 AND partisanscore2012 < 69 THEN 1 ELSE 0 END) as b68,
		sum(CASE WHEN partisanscore2012 >= 69 AND partisanscore2012 < 70 THEN 1 ELSE 0 END) as b69,
		sum(CASE WHEN partisanscore2012 >= 70 AND partisanscore2012 < 71 THEN 1 ELSE 0 END) as b70,
		sum(CASE WHEN partisanscore2012 >= 71 AND partisanscore2012 < 72 THEN 1 ELSE 0 END) as b71,
		sum(CASE WHEN partisanscore2012 >= 72 AND partisanscore2012 < 73 THEN 1 ELSE 0 END) as b72,
		sum(CASE WHEN partisanscore2012 >= 73 AND partisanscore2012 < 74 THEN 1 ELSE 0 END) as b73,
		sum(CASE WHEN partisanscore2012 >= 74 AND partisanscore2012 < 75 THEN 1 ELSE 0 END) as b74,
		sum(CASE WHEN partisanscore2012 >= 75 AND partisanscore2012 < 76 THEN 1 ELSE 0 END) as b75,
		sum(CASE WHEN partisanscore2012 >= 76 AND partisanscore2012 < 77 THEN 1 ELSE 0 END) as b76,
		sum(CASE WHEN partisanscore2012 >= 77 AND partisanscore2012 < 78 THEN 1 ELSE 0 END) as b77,
		sum(CASE WHEN partisanscore2012 >= 78 AND partisanscore2012 < 79 THEN 1 ELSE 0 END) as b78,
		sum(CASE WHEN partisanscore2012 >= 79 AND partisanscore2012 < 80 THEN 1 ELSE 0 END) as b79,
		sum(CASE WHEN partisanscore2012 >= 80 AND partisanscore2012 < 81 THEN 1 ELSE 0 END) as b80,
		sum(CASE WHEN partisanscore2012 >= 81 AND partisanscore2012 < 82 THEN 1 ELSE 0 END) as b81,
		sum(CASE WHEN partisanscore2012 >= 82 AND partisanscore2012 < 83 THEN 1 ELSE 0 END) as b82,
		sum(CASE WHEN partisanscore2012 >= 83 AND partisanscore2012 < 84 THEN 1 ELSE 0 END) as b83,
		sum(CASE WHEN partisanscore2012 >= 84 AND partisanscore2012 < 85 THEN 1 ELSE 0 END) as b84,
		sum(CASE WHEN partisanscore2012 >= 85 AND partisanscore2012 < 86 THEN 1 ELSE 0 END) as b85,
		sum(CASE WHEN partisanscore2012 >= 86 AND partisanscore2012 < 87 THEN 1 ELSE 0 END) as b86,
		sum(CASE WHEN partisanscore2012 >= 87 AND partisanscore2012 < 88 THEN 1 ELSE 0 END) as b87,
		sum(CASE WHEN partisanscore2012 >= 88 AND partisanscore2012 < 89 THEN 1 ELSE 0 END) as b88,
		sum(CASE WHEN partisanscore2012 >= 89 AND partisanscore2012 < 90 THEN 1 ELSE 0 END) as b89,
		sum(CASE WHEN partisanscore2012 >= 90 AND partisanscore2012 < 91 THEN 1 ELSE 0 END) as b90,
		sum(CASE WHEN partisanscore2012 >= 91 AND partisanscore2012 < 92 THEN 1 ELSE 0 END) as b91,
		sum(CASE WHEN partisanscore2012 >= 92 AND partisanscore2012 < 93 THEN 1 ELSE 0 END) as b92,
		sum(CASE WHEN partisanscore2012 >= 93 AND partisanscore2012 < 94 THEN 1 ELSE 0 END) as b93,
		sum(CASE WHEN partisanscore2012 >= 94 AND partisanscore2012 < 95 THEN 1 ELSE 0 END) as b94,
		sum(CASE WHEN partisanscore2012 >= 95 AND partisanscore2012 < 96 THEN 1 ELSE 0 END) as b95,
		sum(CASE WHEN partisanscore2012 >= 96 AND partisanscore2012 < 97 THEN 1 ELSE 0 END) as b96,
		sum(CASE WHEN partisanscore2012 >= 97 AND partisanscore2012 < 98 THEN 1 ELSE 0 END) as b97,
		sum(CASE WHEN partisanscore2012 >= 98 AND partisanscore2012 < 99 THEN 1 ELSE 0 END) as b98,
		sum(CASE WHEN partisanscore2012 >= 99 AND partisanscore2012 < 100 THEN 1 ELSE 0 END) as b99
		FROM dm_national.person_${state} p
		JOIN dm_national.district_${state} d USING (districtid)
		JOIN scores.partisanscore2012 ps ON p.state=ps.state AND p.dwid=ps.dwid";
	$t0 = Benchmark->new;
	my $swpgh = $dbh->prepare($query)
		or die "Couldn't prepare statement: " . $dbh->errstr;
	$swpgh->execute()
		or die "Couldn't execute statement: " . $swpgh->errstr;
	$t1 = Benchmark->new;
	$td = timediff($t1,$t0);
	print timestr($td)," )\n";

	foreach $chamber (statesenatedistrict, statehousedistrict, district1) {
		if ( !(($chamber eq 'district1') && ($state ne 'NH')) ) {
			print "\t${chamber}\n\t\tData...(";
			$chamber_ncec=$chamber;
			if ( $chamber eq "statesenatedistrict" ) {
				$sumlevel=$ncec_sumlvl_sd;
				$cabbr="SD";
				$ncecch=$col_ncecsd;
				$msq=575;
				$mdc="sldust";
				$ot_number="9"
			} elsif ( $chamber eq "statehousedistrict" ) {
				$sumlevel=$ncec_sumlvl_hd;
				$cabbr="HD";
				$ncecch=$col_ncechd;
				$msq="574";
				if ( $state eq "NH" ) {
					$mdc="(UPPER(SUBSTRING(namelsad FROM 22 FOR 3)) || SUBSTRING(sldlst FROM 2 FOR 2))";
					$chamber_ncec="(SUBSTRING(statehousedistrict FROM 1 FOR 2) || SUBSTRING(statehousedistrict FROM 4 FOR 2))";
				} else {
					$mdc="sldlst";
				}
				$ot_number="10";
			} elsif ( $chamber eq "district1" ) {
				$sumlevel=$ncec_sumlvl_hd;
				$cabbr="HD";
				$ncecch=$col_ncechd;
				$msq="574";
				if ( $state eq "NH" ) {
					$mdc="(UPPER(SUBSTRING(namelsad FROM 22 FOR 3)) || SUBSTRING(sldlst FROM 2 FOR 2))";
					$chamber_ncec="(SUBSTRING(district1 FROM 1 FOR 2) || SUBSTRING(district1 FROM 4 FOR 2))";
				} else {
					$mdc="sldlst";
				}
				$ot_number="10";
			}
			$query="INSERT INTO reporting.op_data
				(state,chamber,district,voters,gender_m,gender_f,gender_u,race_u,race_b,race_c,race_h,race_a,race_o,age_18_30,age_31_40,age_41_50,age_51_65,age_66_up,
				votestat_i,votestat_a,votestat_u,party_d,party_r,party_o,partisan_avg,partisan_stddev,expvote,expvoteshr,demperfpct,demperfidx,dembaseidx,
				pres12margin,pres08margin,govmargin,ussenmargin,contacts_total,contacts_district,statename,distname,turnout_2012,absentee_2012,early_2012)
				SELECT
				'${state}' as state,
				'${cabbr}' as chamber,
				CASE WHEN CHAR_LENGTH(${chamber}) > 3 THEN ${chamber} ELSE LPAD(${chamber},3,'0') END AS district,
				count(*) as voters
				, sum(case when gender='male' then 1 else 0 end) as gender_m
				, sum(case when gender='female' then 1 else 0 end) as gender_f
				, sum(case when gender='unknown' then 1 else 0 end) as gender_u
				, sum(case when race='unknown' then 1 else 0 end) as race_u
				, sum(case when race='black' then 1 else 0 end) as race_b
				, sum(case when race='caucasian' then 1 else 0 end) as race_c
				, sum(case when race='hispanic' then 1 else 0 end) as race_h
				, sum(case when race='asian' then 1 else 0 end) as race_a
				, sum(case when race NOT IN ('black','caucasian','hispanic','asian') then 1 else 0 end) as race_o
				, sum(case when age>= 18 and age <= 30 then 1 else 0 end) as age_18_30
				, sum(case when age>= 31 and age <= 40 then 1 else 0 end) as age_31_40
				, sum(case when age>= 41 and age <= 50 then 1 else 0 end) as age_41_50
				, sum(case when age>= 51 and age <= 65 then 1 else 0 end) as age_51_65
				, sum(case when age>= 66 then 1 else 0 end) as age_66_up
				, sum(case when voterstatus = 'inactive' then 1 else 0 end) as votestat_i
				, sum(case when voterstatus = 'active' then 1 else 0 end) as votestat_a
				, sum(case when voterstatus = 'unregistered' then 1 else 0 end) as votestat_u
				, sum(case when partyaffiliation = 'DEM' then 1 else 0 end) as party_d
				, sum(case when partyaffiliation = 'REP' then 1 else 0 end) as party_r
				, sum(case when partyaffiliation NOT IN ('DEM','REP') then 1 else 0 end) as party_o
				, round(avg(d.partisanscore2012), 1) as partisan_avg
				, round(stddev(d.partisanscore2012), 1) as partisan_stddev
				, expvote
				, expvoteshr
				, demperfpct
				, demperfidx
				, dembaseidx
				, '-' as pres12margin
				, CASE WHEN ( pres08pct2way - 50 ) < 0 THEN 'R + ' || abs(pres08pct2way - 50) ELSE 'D + ' || abs(pres08pct2way - 50) END as pres08margin
				, CASE WHEN ( ${col_gov} - 50 ) < 0 THEN 'R + ' || abs(${col_gov} - 50) ELSE 'D + ' || abs(${col_gov} - 50) END as govmargin
				, CASE WHEN ( ${col_ussen} - 50 ) < 0 THEN 'R + ' || abs(${col_ussen} - 50) ELSE 'D + ' || abs(${col_ussen} - 50) END ussenmargin
				, sum(CASE WHEN datecanvassed IS NOT NULL THEN 1 ELSE 0 END) as contacts_total
				, sum(CASE WHEN mastersurveyquestionid=${msq} THEN 1 ELSE 0 END) as contacts_district
				, statename
				, namelsad
				, sum(CASE WHEN e2012g IS NOT NULL THEN 1 ELSE 0 END) as turnout_2012
				, sum(CASE WHEN e2012g='A' THEN 1 ELSE 0 END) as absentee_2012
				, sum(CASE WHEN e2012g='E' THEN 1 ELSE 0 END) as early_2012
				FROM dm_national.person_${state} a
				JOIN dm_national.district_${state} b USING ( districtid )
				JOIN scores.partisanscore2012 d on a.state=d.state AND a.dwid=d.dwid
				JOIN dm_national.votehistorysummary USING ( votehistorysummaryid )
				LEFT JOIN ( select * from scores.ncec_${state} WHERE summary_level='${sumlevel}' ) s ON lpad(${chamber_ncec},4,'0')=lpad(s.${ncecch},4,'0')
				JOIN ( select ${mdc} as district,statename,namelsad FROM maps.${cabbr} m JOIN maps.fips f ON m.statefp=f.fips WHERE f.state='${state}' ) na ON lpad(na.district,5,'0')=lpad(${chamber},5,'0')
				LEFT JOIN van.state_surveyresponses sr ON a.dwid=sr.dwid
				JOIN van.surveyquestions sq USING ( surveyquestionid )
				WHERE voterstatus IN ('active','inactive')
				GROUP BY ${chamber},expvote,expvoteshr,demperfpct,demperfidx,dembaseidx,
				pres08margin,govmargin,ussenmargin,statename,namelsad ORDER BY ${chamber}";
			$t0 = Benchmark->new;
			my $opduh = $dbh->prepare($query)
				or die "Couldn't prepare statement: " . $dbh->errstr;
			$opduh->execute()
				or die "Couldn't execute statement: " . $opduh->errstr;
			$t1 = Benchmark->new;
			$td = timediff($t1,$t0);
			print timestr($td)," )";
		#
		# Build our graph data
			print "\n\t\tPartgraph Statewide...(";
			$query="INSERT INTO reporting.op_partgraph
				select
				'${state}' as state,
				'${cabbr}' as chamber,
				CASE WHEN CHAR_LENGTH(${chamber}) > 3 THEN ${chamber} ELSE LPAD(${chamber},3,'0') END AS district,
				sum(CASE WHEN partisanscore2012 >= 0 AND partisanscore2012 < 1 THEN 1 ELSE 0 END) as b0,
				sum(CASE WHEN partisanscore2012 >= 1 AND partisanscore2012 < 2 THEN 1 ELSE 0 END) as b1,
				sum(CASE WHEN partisanscore2012 >= 2 AND partisanscore2012 < 3 THEN 1 ELSE 0 END) as b2,
				sum(CASE WHEN partisanscore2012 >= 3 AND partisanscore2012 < 4 THEN 1 ELSE 0 END) as b3,
				sum(CASE WHEN partisanscore2012 >= 4 AND partisanscore2012 < 5 THEN 1 ELSE 0 END) as b4,
				sum(CASE WHEN partisanscore2012 >= 5 AND partisanscore2012 < 6 THEN 1 ELSE 0 END) as b5,
				sum(CASE WHEN partisanscore2012 >= 6 AND partisanscore2012 < 7 THEN 1 ELSE 0 END) as b6,
				sum(CASE WHEN partisanscore2012 >= 7 AND partisanscore2012 < 8 THEN 1 ELSE 0 END) as b7,
				sum(CASE WHEN partisanscore2012 >= 8 AND partisanscore2012 < 9 THEN 1 ELSE 0 END) as b8,
				sum(CASE WHEN partisanscore2012 >= 9 AND partisanscore2012 < 10 THEN 1 ELSE 0 END) as b9,
				sum(CASE WHEN partisanscore2012 >= 10 AND partisanscore2012 < 11 THEN 1 ELSE 0 END) as b10,
				sum(CASE WHEN partisanscore2012 >= 11 AND partisanscore2012 < 12 THEN 1 ELSE 0 END) as b11,
				sum(CASE WHEN partisanscore2012 >= 12 AND partisanscore2012 < 13 THEN 1 ELSE 0 END) as b12,
				sum(CASE WHEN partisanscore2012 >= 13 AND partisanscore2012 < 14 THEN 1 ELSE 0 END) as b13,
				sum(CASE WHEN partisanscore2012 >= 14 AND partisanscore2012 < 15 THEN 1 ELSE 0 END) as b14,
				sum(CASE WHEN partisanscore2012 >= 15 AND partisanscore2012 < 16 THEN 1 ELSE 0 END) as b15,
				sum(CASE WHEN partisanscore2012 >= 16 AND partisanscore2012 < 17 THEN 1 ELSE 0 END) as b16,
				sum(CASE WHEN partisanscore2012 >= 17 AND partisanscore2012 < 18 THEN 1 ELSE 0 END) as b17,
				sum(CASE WHEN partisanscore2012 >= 18 AND partisanscore2012 < 19 THEN 1 ELSE 0 END) as b18,
				sum(CASE WHEN partisanscore2012 >= 19 AND partisanscore2012 < 20 THEN 1 ELSE 0 END) as b19,
				sum(CASE WHEN partisanscore2012 >= 20 AND partisanscore2012 < 21 THEN 1 ELSE 0 END) as b20,
				sum(CASE WHEN partisanscore2012 >= 21 AND partisanscore2012 < 22 THEN 1 ELSE 0 END) as b21,
				sum(CASE WHEN partisanscore2012 >= 22 AND partisanscore2012 < 23 THEN 1 ELSE 0 END) as b22,
				sum(CASE WHEN partisanscore2012 >= 23 AND partisanscore2012 < 24 THEN 1 ELSE 0 END) as b23,
				sum(CASE WHEN partisanscore2012 >= 24 AND partisanscore2012 < 25 THEN 1 ELSE 0 END) as b24,
				sum(CASE WHEN partisanscore2012 >= 25 AND partisanscore2012 < 26 THEN 1 ELSE 0 END) as b25,
				sum(CASE WHEN partisanscore2012 >= 26 AND partisanscore2012 < 27 THEN 1 ELSE 0 END) as b26,
				sum(CASE WHEN partisanscore2012 >= 27 AND partisanscore2012 < 28 THEN 1 ELSE 0 END) as b27,
				sum(CASE WHEN partisanscore2012 >= 28 AND partisanscore2012 < 29 THEN 1 ELSE 0 END) as b28,
				sum(CASE WHEN partisanscore2012 >= 29 AND partisanscore2012 < 30 THEN 1 ELSE 0 END) as b29,
			sum(CASE WHEN partisanscore2012 >= 30 AND partisanscore2012 < 31 THEN 1 ELSE 0 END) as b30,
			sum(CASE WHEN partisanscore2012 >= 31 AND partisanscore2012 < 32 THEN 1 ELSE 0 END) as b31,
			sum(CASE WHEN partisanscore2012 >= 32 AND partisanscore2012 < 33 THEN 1 ELSE 0 END) as b32,
			sum(CASE WHEN partisanscore2012 >= 33 AND partisanscore2012 < 34 THEN 1 ELSE 0 END) as b33,
			sum(CASE WHEN partisanscore2012 >= 34 AND partisanscore2012 < 35 THEN 1 ELSE 0 END) as b34,
			sum(CASE WHEN partisanscore2012 >= 35 AND partisanscore2012 < 36 THEN 1 ELSE 0 END) as b35,
			sum(CASE WHEN partisanscore2012 >= 36 AND partisanscore2012 < 37 THEN 1 ELSE 0 END) as b36,
			sum(CASE WHEN partisanscore2012 >= 37 AND partisanscore2012 < 38 THEN 1 ELSE 0 END) as b37,
			sum(CASE WHEN partisanscore2012 >= 38 AND partisanscore2012 < 39 THEN 1 ELSE 0 END) as b38,
			sum(CASE WHEN partisanscore2012 >= 39 AND partisanscore2012 < 40 THEN 1 ELSE 0 END) as b39,
			sum(CASE WHEN partisanscore2012 >= 40 AND partisanscore2012 < 41 THEN 1 ELSE 0 END) as b40,
			sum(CASE WHEN partisanscore2012 >= 41 AND partisanscore2012 < 42 THEN 1 ELSE 0 END) as b41,
			sum(CASE WHEN partisanscore2012 >= 42 AND partisanscore2012 < 43 THEN 1 ELSE 0 END) as b42,
			sum(CASE WHEN partisanscore2012 >= 43 AND partisanscore2012 < 44 THEN 1 ELSE 0 END) as b43,
			sum(CASE WHEN partisanscore2012 >= 44 AND partisanscore2012 < 45 THEN 1 ELSE 0 END) as b44,
			sum(CASE WHEN partisanscore2012 >= 45 AND partisanscore2012 < 46 THEN 1 ELSE 0 END) as b45,
			sum(CASE WHEN partisanscore2012 >= 46 AND partisanscore2012 < 47 THEN 1 ELSE 0 END) as b46,
			sum(CASE WHEN partisanscore2012 >= 47 AND partisanscore2012 < 48 THEN 1 ELSE 0 END) as b47,
			sum(CASE WHEN partisanscore2012 >= 48 AND partisanscore2012 < 49 THEN 1 ELSE 0 END) as b48,
			sum(CASE WHEN partisanscore2012 >= 49 AND partisanscore2012 < 50 THEN 1 ELSE 0 END) as b49,
			sum(CASE WHEN partisanscore2012 >= 50 AND partisanscore2012 < 51 THEN 1 ELSE 0 END) as b50,
			sum(CASE WHEN partisanscore2012 >= 51 AND partisanscore2012 < 52 THEN 1 ELSE 0 END) as b51,
			sum(CASE WHEN partisanscore2012 >= 52 AND partisanscore2012 < 53 THEN 1 ELSE 0 END) as b52,
			sum(CASE WHEN partisanscore2012 >= 53 AND partisanscore2012 < 54 THEN 1 ELSE 0 END) as b53,
			sum(CASE WHEN partisanscore2012 >= 54 AND partisanscore2012 < 55 THEN 1 ELSE 0 END) as b54,
			sum(CASE WHEN partisanscore2012 >= 55 AND partisanscore2012 < 56 THEN 1 ELSE 0 END) as b55,
			sum(CASE WHEN partisanscore2012 >= 56 AND partisanscore2012 < 57 THEN 1 ELSE 0 END) as b56,
			sum(CASE WHEN partisanscore2012 >= 57 AND partisanscore2012 < 58 THEN 1 ELSE 0 END) as b57,
			sum(CASE WHEN partisanscore2012 >= 58 AND partisanscore2012 < 59 THEN 1 ELSE 0 END) as b58,
			sum(CASE WHEN partisanscore2012 >= 59 AND partisanscore2012 < 60 THEN 1 ELSE 0 END) as b59,
			sum(CASE WHEN partisanscore2012 >= 60 AND partisanscore2012 < 61 THEN 1 ELSE 0 END) as b60,
				sum(CASE WHEN partisanscore2012 >= 61 AND partisanscore2012 < 62 THEN 1 ELSE 0 END) as b61,
				sum(CASE WHEN partisanscore2012 >= 62 AND partisanscore2012 < 63 THEN 1 ELSE 0 END) as b62,
				sum(CASE WHEN partisanscore2012 >= 63 AND partisanscore2012 < 64 THEN 1 ELSE 0 END) as b63,
				sum(CASE WHEN partisanscore2012 >= 64 AND partisanscore2012 < 65 THEN 1 ELSE 0 END) as b64,
				sum(CASE WHEN partisanscore2012 >= 65 AND partisanscore2012 < 66 THEN 1 ELSE 0 END) as b65,
				sum(CASE WHEN partisanscore2012 >= 66 AND partisanscore2012 < 67 THEN 1 ELSE 0 END) as b66,
				sum(CASE WHEN partisanscore2012 >= 67 AND partisanscore2012 < 68 THEN 1 ELSE 0 END) as b67,
				sum(CASE WHEN partisanscore2012 >= 68 AND partisanscore2012 < 69 THEN 1 ELSE 0 END) as b68,
				sum(CASE WHEN partisanscore2012 >= 69 AND partisanscore2012 < 70 THEN 1 ELSE 0 END) as b69,
				sum(CASE WHEN partisanscore2012 >= 70 AND partisanscore2012 < 71 THEN 1 ELSE 0 END) as b70,
				sum(CASE WHEN partisanscore2012 >= 71 AND partisanscore2012 < 72 THEN 1 ELSE 0 END) as b71,
				sum(CASE WHEN partisanscore2012 >= 72 AND partisanscore2012 < 73 THEN 1 ELSE 0 END) as b72,
				sum(CASE WHEN partisanscore2012 >= 73 AND partisanscore2012 < 74 THEN 1 ELSE 0 END) as b73,
				sum(CASE WHEN partisanscore2012 >= 74 AND partisanscore2012 < 75 THEN 1 ELSE 0 END) as b74,
				sum(CASE WHEN partisanscore2012 >= 75 AND partisanscore2012 < 76 THEN 1 ELSE 0 END) as b75,
				sum(CASE WHEN partisanscore2012 >= 76 AND partisanscore2012 < 77 THEN 1 ELSE 0 END) as b76,
				sum(CASE WHEN partisanscore2012 >= 77 AND partisanscore2012 < 78 THEN 1 ELSE 0 END) as b77,
				sum(CASE WHEN partisanscore2012 >= 78 AND partisanscore2012 < 79 THEN 1 ELSE 0 END) as b78,
				sum(CASE WHEN partisanscore2012 >= 79 AND partisanscore2012 < 80 THEN 1 ELSE 0 END) as b79,
				sum(CASE WHEN partisanscore2012 >= 80 AND partisanscore2012 < 81 THEN 1 ELSE 0 END) as b80,
				sum(CASE WHEN partisanscore2012 >= 81 AND partisanscore2012 < 82 THEN 1 ELSE 0 END) as b81,
				sum(CASE WHEN partisanscore2012 >= 82 AND partisanscore2012 < 83 THEN 1 ELSE 0 END) as b82,
				sum(CASE WHEN partisanscore2012 >= 83 AND partisanscore2012 < 84 THEN 1 ELSE 0 END) as b83,
				sum(CASE WHEN partisanscore2012 >= 84 AND partisanscore2012 < 85 THEN 1 ELSE 0 END) as b84,
				sum(CASE WHEN partisanscore2012 >= 85 AND partisanscore2012 < 86 THEN 1 ELSE 0 END) as b85,
				sum(CASE WHEN partisanscore2012 >= 86 AND partisanscore2012 < 87 THEN 1 ELSE 0 END) as b86,
				sum(CASE WHEN partisanscore2012 >= 87 AND partisanscore2012 < 88 THEN 1 ELSE 0 END) as b87,
				sum(CASE WHEN partisanscore2012 >= 88 AND partisanscore2012 < 89 THEN 1 ELSE 0 END) as b88,
				sum(CASE WHEN partisanscore2012 >= 89 AND partisanscore2012 < 90 THEN 1 ELSE 0 END) as b89,
				sum(CASE WHEN partisanscore2012 >= 90 AND partisanscore2012 < 91 THEN 1 ELSE 0 END) as b90,
				sum(CASE WHEN partisanscore2012 >= 91 AND partisanscore2012 < 92 THEN 1 ELSE 0 END) as b91,
				sum(CASE WHEN partisanscore2012 >= 92 AND partisanscore2012 < 93 THEN 1 ELSE 0 END) as b92,
				sum(CASE WHEN partisanscore2012 >= 93 AND partisanscore2012 < 94 THEN 1 ELSE 0 END) as b93,
				sum(CASE WHEN partisanscore2012 >= 94 AND partisanscore2012 < 95 THEN 1 ELSE 0 END) as b94,
				sum(CASE WHEN partisanscore2012 >= 95 AND partisanscore2012 < 96 THEN 1 ELSE 0 END) as b95,
				sum(CASE WHEN partisanscore2012 >= 96 AND partisanscore2012 < 97 THEN 1 ELSE 0 END) as b96,
				sum(CASE WHEN partisanscore2012 >= 97 AND partisanscore2012 < 98 THEN 1 ELSE 0 END) as b97,
			sum(CASE WHEN partisanscore2012 >= 98 AND partisanscore2012 < 99 THEN 1 ELSE 0 END) as b98,
				sum(CASE WHEN partisanscore2012 >= 99 AND partisanscore2012 < 100 THEN 1 ELSE 0 END) as b99
				FROM dm_national.person_${state} p
				JOIN dm_national.district_${state} d USING (districtid)
				JOIN scores.partisanscore2012 ps ON p.state=ps.state AND p.dwid=ps.dwid
				GROUP BY p.state,chamber,${chamber};";
			$t0 = Benchmark->new;
			my $oppsh = $dbh->prepare($query)
				or die "Couldn't prepare statement: " . $dbh->errstr;
			$oppsh->execute()
				or die "Couldn't execute statement: " . $oppsh->errstr;
			$t1 = Benchmark->new;
			$td = timediff($t1,$t0);
			print timestr($td)," )\n";
		}
		print "\n";
	}
}
