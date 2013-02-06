#!/usr/bin/perl

use POSIX;
use DBI;
use Text::Template;
use Template;
use LaTeX::Encode;
use Encode;
use Data::Dumper;

# States to build
#$tstates="'ME'";
$tstates="'CO','ME','MI','MN','MT','NH','NV','OH','PA','WI'";
if ( length $ARGV[0] > 0 ) {
	$tstates="'$ARGV[0]'";
}

### Config stuff here
# Paths
$basepath="/data/scripts/onepagers";
$imagepath="${basepath}/images";
$districtpath="${imagepath}/district";
$insetpath ="${imagepath}/inset";
$tmplpath = "${basepath}/templates";
$outputpath = "/var/www/html/pdfs";

# Scratch file for maps
$scratchfile = "${basepath}/scratch.map";

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

# Database

# Get data on states we care about
$query="SELECT state,box2d(st_transform(the_geom,96954)) as extent FROM maps.states s JOIN maps.fips f ON f.fips=s.state_fips WHERE f.state IN ( $tstates ) ORDER BY f.state";
my $sgqh = $dbh->prepare($query)
	or die "Couldn't prepare statement: " . $dbh->errstr;
$sgqh->execute()
	or die "Couldn't execute statement: " . $sgqh->errstr;


# Okay, we now have the states and their extents and can set up our state variables.

while ( ($state,$stextent) = $sgqh->fetchrow_array() ) {
	# Reprocess the extent to be usable by Mapserver
	$stextent=msextent($stextent);
	# Get the list of state senate districts for this state
	$query="SELECT gid,sldust as district,namelsad as distname,box2d(st_transform(geom,96954)) as extent FROM maps.sd s JOIN maps.fips f ON f.fips=s.statefp WHERE f.state='${state}'";
	my $sdqh = $dbh->prepare($query)
		or die "Couldn't prepare statement: " . $dbh->errstr;
	$sdqh->execute()
		or die "Couldn't execute statement: " . $sgqh->errstr;
	# Now we iterate our districts and crank out the files.
	$chamber="SD";
	while ( ($gid,$district,$distname,$sdextent) = $sdqh->fetchrow_array() ) {
		makemap($state,$chamber,$district,$sdextent,$stextent);
		makepdf($state,$chamber,$district,$basepath);
		print "\n";
	}

	# And now we do it for house districts

	# Special handling for NH. Because they're SPEEEESHUL
	if ( $state eq 'NH' ) {
		$hddistrict = '(upper(substring(namelsad from 22 for 3)) || substring(sldlst FROM 2))';
	} else { 
		$hddistrict = 'sldlst'
	}
	$query="SELECT gid,${hddistrict} as district,namelsad as distname,box2d(st_transform(geom,96954)) as extent FROM maps.hd s JOIN maps.fips f ON f.fips=s.statefp WHERE f.state='${state}'";
	my $hdqh = $dbh->prepare($query)
		or die "Couldn't prepare statement: " . $dbh->errstr;
	$hdqh->execute()
		or die "Couldn't execute statement: " . $hdqh->errstr;
	# Now we iterate our districts and crank out the files.
	$chamber="HD";
	while ( ($gid,$district,$distname,$sdextent) = $hdqh->fetchrow_array() ) {
		makemap($state,$chamber,$district,$sdextent,$stextent);
		makepdf($state,$chamber,$district,$basepath);
		print "\n";
	}
}


#
# Clean things up
#close(TEMPLATE);

# Function to convert the SQL output extent into something mapserver can understand.
sub msextent {
	if ( $_[0] =~ /\((.*?)\)/ ) {
		$extent=$1;
		$extent =~ s/,/ /g;
	}
	return $extent;
}

sub makemap($state,$chamber,$district,$sdextent,$stextent) {
	$sdextent=msextent($sdextent);
	# Use the templating to create a mapfile
	$districttmpl = Text::Template->new(TYPE =>'FILE', SOURCE => "$tmplpath/district.tmpl");
	if ( $state eq 'NH' && $chamber eq 'HD' ) {
		$temphash = { sdextent => $sdextent, state => $state, district => $district, hddistrict => '(upper(substring(namelsad from 22 for 3)) || substring(sldlst FROM 2))' };
	} else {
		$temphash = { sdextent => $sdextent, district => $district, state => $state, hddistrict => 'sldlst'};
	}
	$distmf = $districttmpl->fill_in($temphash);
	# Write the mapfile out.
	open(MAPFILE, '>', $scratchfile);
	print MAPFILE sprintf $distmf;
	close(MAPFILE);
	# Call the mapserver and crank out an image.
	print "Making: ${state} ${chamber} ${district} (Zoom Map) ";
	$call = `shp2img -m $scratchfile -o ${districtpath}/${state}-${chamber}-${district}-d.png -l states -l cities -l ${chamber}`;
	# Create and write the inset map
	$insettmpl = Text::Template->new(TYPE => 'FILE', SOURCE => "${tmplpath}/inset.tmpl");
	if ( $state eq 'NH' && $chamber eq 'HD' ) {
		$temphash = { stextent => $stextent, state => $state, district => $district, hddistrict => 'trim(upper(substring(namelsad from 22 for 3)) || substring(sldlst FROM 2))' };
	} else {
		$temphash = { stextent => $stextent, state => $state, district => $district, hddistrict => 'sldlst' };
	}
	$insetmf = $insettmpl->fill_in($temphash);
	open(MAPFILE, '>', $scratchfile);
	print MAPFILE sprintf $insetmf;
	close(MAPFILE);
	print "(Inset) ";
	$call = `shp2img -m $scratchfile -o ${insetpath}/${state}-${chamber}-${district}-i.png -l states -l ${chamber}`;
	# Call imagemagick to add a border
	$call = `mogrify -border 2 -bordercolor black  ${insetpath}/${state}-${chamber}-${district}-i.png`;
	# Now call Imagemagick to composite them together.
	print "(Composite) ";
	$call = `composite -gravity southwest ${insetpath}/${state}-${chamber}-${district}-i.png ${districtpath}/${state}-${chamber}-${district}-d.png ${imagepath}/${state}-${chamber}-${district}.png`;
	# add border to main image
	$call = `mogrify -border 2 -bordercolor black ${imagepath}/${state}-${chamber}-${district}.png`;
}


sub makepdf($state,$chamber,$district,$basepath,"${tmplpath}/onepager.tmpl") {
	# Get the data for our onepager
	$query="SELECT d.*,c.*,n.notes 
		FROM reporting.op_data d 
		JOIN reporting.op_notes n ON d.state=n.state AND d.chamber=n.chamber AND lpad(d.district,5,'0')=lpad(n.district,5,'0')
		LEFT JOIN reporting.op_candidates c ON d.state=c.state AND d.chamber=c.chamber AND d.district=c.district
		WHERE d.state='${state}' AND upper(d.chamber)=upper('${chamber}') AND d.district='${district}'";
#	print "\n$query\n";
	my $opqh = $dbh->prepare($query)
		or die "Couldn't prepare statement: " . $dbh->errstr;
	$opqh->execute()
		or die "Couldn't execute statement: " . $opqh->errstr;
	if ( $opqh->rows > 0 ) { 
		# Create a hashref that contains our result. We're presuming there's only one!
		$opdata = $opqh->fetchrow_hashref();
	
		# Set up the template
		$onepagetmpl = Template->new({
			INCLUDE_PATH => $tmplpath,
			OUTPUT_PATH => $tmplpath,
			INTERPOLATE => 1,
			POST_CHOMP => 1,
			EVAL_PERL => 1, });
	
		# Trap divide by zero for pct_avev
		if ( $$opdata{'turnout_2012'} == 0 ) {
			$turnout = "No data";
			$avev = "No data";
		} else {
			$turnout = $$opdata{'turnout_2012'} . " (" . sprintf("%.1f",$$opdata{'turnout_2012'}/($$opdata{'voters'}) * 100) . "\\%)";
			$avev = $$opdata{'early_2012'}+$$opdata{'absentee_2012'} . " (" . sprintf("%.1f",($$opdata{'early_2012'}+$$opdata{'absentee_2012'})/$$opdata{'turnout_2012'} * 100) . "\\%)";
		}
		# Scrub the data for characterset and stray returns.
		foreach $opdatakey(keys %$opdata) {
			$$opdata{$opdatakey} = encode("latin1",$$opdata{$opdatakey});
			$$opdata{$opdatakey} =~ s/\R/ /g;
		}
		eval {
		$temphash = { 
			statename => $$opdata{'statename'}, 
			distname => $$opdata{'distname'},
			state => $state,
			chamber => $chamber, 
			district => $district, 
			gender_f => commify($$opdata{'gender_m'}),
			gender_m => commify($$opdata{'gender_f'}),
			pct_gender_m => sprintf("%.1f",$$opdata{'gender_m'}/($$opdata{'gender_m'}+$$opdata{'gender_f'}) * 100),
			pct_gender_f => sprintf("%.1f",$$opdata{'gender_f'}/($$opdata{'gender_m'}+$$opdata{'gender_f'}) * 100),
			race_b => commify($$opdata{'race_b'}),
			race_c => commify($$opdata{'race_c'}),
			race_h => commify($$opdata{'race_h'}),
			race_a => commify($$opdata{'race_a'}),
			race_o => commify($$opdata{'race_o'}),
			pct_race_b => sprintf("%.1f",$$opdata{'race_b'}/($$opdata{'race_u'}+$$opdata{'race_b'}+$$opdata{'race_c'}+$$opdata{'race_h'}+$$opdata{'race_a'}+$$opdata{'race_o'}) * 100),
			pct_race_c => sprintf("%.1f",$$opdata{'race_c'}/($$opdata{'race_u'}+$$opdata{'race_b'}+$$opdata{'race_c'}+$$opdata{'race_h'}+$$opdata{'race_a'}+$$opdata{'race_o'}) * 100),
			pct_race_h => sprintf("%.1f",$$opdata{'race_h'}/($$opdata{'race_u'}+$$opdata{'race_b'}+$$opdata{'race_c'}+$$opdata{'race_h'}+$$opdata{'race_a'}+$$opdata{'race_o'}) * 100),
			pct_race_a => sprintf("%.1f",$$opdata{'race_a'}/($$opdata{'race_u'}+$$opdata{'race_b'}+$$opdata{'race_c'}+$$opdata{'race_h'}+$$opdata{'race_a'}+$$opdata{'race_o'}) * 100),
			pct_race_o => sprintf("%.1f",$$opdata{'race_o'}/($$opdata{'race_u'}+$$opdata{'race_b'}+$$opdata{'race_c'}+$$opdata{'race_h'}+$$opdata{'race_a'}+$$opdata{'race_o'}) * 100),
			age_18_30 => commify($$opdata{'age_18_30'}),
			age_31_40 => commify($$opdata{'age_31_40'}),
			age_41_50 => commify($$opdata{'age_41_50'}),
			age_51_65 => commify($$opdata{'age_51_65'}),
			age_66_up => commify($$opdata{'age_66_up'}),
			pct_age_18_30 => sprintf("%.1f",$$opdata{'age_18_30'}/($$opdata{'age_18_30'}+$$opdata{'age_31_40'}+$$opdata{'age_41_50'}+$$opdata{'age_51_65'}+$$opdata{'age_66_up'}) * 100),
			pct_age_31_40 => sprintf("%.1f",$$opdata{'age_31_40'}/($$opdata{'age_18_30'}+$$opdata{'age_31_40'}+$$opdata{'age_41_50'}+$$opdata{'age_51_65'}+$$opdata{'age_66_up'}) * 100),
			pct_age_41_50 => sprintf("%.1f",$$opdata{'age_41_50'}/($$opdata{'age_18_30'}+$$opdata{'age_31_40'}+$$opdata{'age_41_50'}+$$opdata{'age_51_65'}+$$opdata{'age_66_up'}) * 100),
			pct_age_51_65 => sprintf("%.1f",$$opdata{'age_51_65'}/($$opdata{'age_18_30'}+$$opdata{'age_31_40'}+$$opdata{'age_41_50'}+$$opdata{'age_51_65'}+$$opdata{'age_66_up'}) * 100),
			pct_age_66_up => sprintf("%.1f",$$opdata{'age_66_up'}/($$opdata{'age_18_30'}+$$opdata{'age_31_40'}+$$opdata{'age_41_50'}+$$opdata{'age_51_65'}+$$opdata{'age_66_up'}) * 100),
			party_d => commify($$opdata{'party_d'}),
			party_r => commify($$opdata{'party_r'}),
			party_o => commify($$opdata{'party_o'}),
			pct_party_d => sprintf("%.1f",$$opdata{'party_d'}/($$opdata{'party_d'}+$$opdata{'party_r'}+$$opdata{'party_o'}) * 100),
			pct_party_r => sprintf("%.1f",$$opdata{'party_r'}/($$opdata{'party_d'}+$$opdata{'party_r'}+$$opdata{'party_o'}) * 100),
			pct_party_o => sprintf("%.1f",$$opdata{'party_o'}/($$opdata{'party_d'}+$$opdata{'party_r'}+$$opdata{'party_o'}) * 100),
			pres12margin => $$opdata{'pres12margin'},
			pres08margin => $$opdata{'pres08margin'},
			govmargin => $$opdata{'govmargin'},
			contacts_total => commify($$opdata{'contacts_total'}),
			contacts_district => commify($$opdata{'contacts_district'}),
			expvote => commify($$opdata{'expvote'}),
#			demperfidx => commify($$opdata{'demperfidx'}),
			votegoal => commify(ceil($$opdata{'expvote'} * 0.52)),
			votedeficit => commify(ceil($$opdata{'expvote'} * 0.52) - $$opdata{'dembaseidx'}),
			demperfpct => $$opdata{'demperfpct'},
			party => $$opdata{'party'},
			turnout => $turnout,
			avev => $avev,
			notes => length($$opdata{'notes'}) > 0 ? latex_encode($$opdata{'notes'}) : "",
			first_name => length($$opdata{'first_name'}) > 0 ? latex_encode($$opdata{'first_name'}) : "",
			last_name => length($$opdata{'last_name'}) > 0 ? latex_encode($$opdata{'last_name'}) : "",
			committees => length($$opdata{'committees'}) > 0 ? latex_encode($$opdata{'committees'}) : "",
			address => length($$opdata{'address'}) > 0 ? latex_encode($$opdata{'address'}) : "",
			email => length($$opdata{'email'}) > 0 ? latex_encode($$opdata{'email'}) : "",
			phone => length($$opdata{'phone'}) > 0 ? latex_encode($$opdata{'phone'}) : "",
			website => length($$opdata{'website'}) > 0 ? latex_encode($$opdata{'website'}) : "",
			twitter => length($$opdata{'twitter'}) > 0 ? latex_encode($$opdata{'twitter'}) : ""
			};
		};
		$onepagetmpl->process('onepager.tmpl',$temphash,'onepager.tex')
			or die $onepagetmpl->error();
		print "(PDF)";
		$call = `pdflatex -output-directory=${outputpath} -jobname=${state}-${chamber}-${district} ${tmplpath}/onepager.tex`;
	} else {
		print "(No PDF Data)";
	}
}

sub commify {
    my $text = reverse $_[0];
    $text =~ s/(\d\d\d)(?=\d)(?!\d*\.)/$1,/g;
    return scalar reverse $text;
}
