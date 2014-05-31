#!/usr/bin/perl

use ElkM1::Control;
use Switch;
use Log::Log4perl qw(:easy);
use HTTP::Date;
use strict;
use File::Basename;
use File::Spec;

unshift (@INC, File::Spec->catfile(dirname(__FILE__), 'lib'));

require 'elkm1_db.pl';
require 'file_tickler.pl';

# to trap ctrl-c and exit gracefully closing the db connection and the
# connection to th ekl
$SIG{'INT'} = 'cleanup';
$SIG{'TERM'} = 'cleanup';
$SIG{'KILL'} = 'cleanup';

Log::Log4perl->easy_init( { level    => $INFO,
                            file     => ">>/home/your_name/path/to/elk_monitor.log",
                            layout   => '[%d{dd MMM HH:mm:ss}] %m%n' } );

&file_tickler_init( File::Spec->catfile(dirname(__FILE__), 'elk_monitor_active'), 60);

my $elkhost = '192.168.0.6';
my $elkport = '2101';
my $elkssl = 0;
my $elkdebug = 0;

my $units = 'F';
				
my %zonelist = (
     1 => { name => 'Laundry Room Door',	track_in_db => 1 },
     2 => { name => 'Front Door',			track_in_db => 1 },
     3 => { name => 'Back Patio Door',		track_in_db => 1 },
     4 => { name => 'Dining Room Window',	track_in_db => 1 },
     5 => { name => 'Front Bed Window',		track_in_db => 1 },
     6 => { name => 'Front Bath Window',	track_in_db => 1 },
     7 => { name => 'Boys Room Window',		track_in_db => 1 },
     8 => { name => 'Living Room WandS',	track_in_db => 1 },
     9 => { name => 'LRSEWin',				track_in_db => 1 },
    10 => { name => 'Kitchen Windows',		track_in_db => 1 },
    11 => { name => 'FamRmHallWins',		track_in_db => 1 },
    12 => { name => 'Master North Win',		track_in_db => 1 },
    13 => { name => 'FamilyRoomPIR',		track_in_db => 0 },
    14 => { name => 'LivingRoomPIR',		track_in_db => 0 },
    15 => { name => 'MasterBedPIR',			track_in_db => 0 },
    16 => { name => 'zone16',				track_in_db => 0 }
	);
				
my %outputs = (
	17	=> { name => 'Garage Door Opener',	track_in_db => 1 },
	21	=> { name => 'Drip Front',			track_in_db => 1 },
	22	=> { name => 'Drip Rear',			track_in_db => 1 },
	23	=> { name => 'Drip East In Fence',	track_in_db => 1 },
	24	=> { name => 'Drip East Out Fence',	track_in_db => 1 },
	29	=> { name => 'Hot Water',			track_in_db => 1 }
	);
	
my %areas = (
	1	=> { name => 'Smith House',	track_in_db => 1 }
	);

&logInfo("STARTING");

my $elk = ElkM1::Control->new('host' => $elkhost, 'port' => $elkport, 'use_ssl' => $elkssl, 'debug' => $elkdebug);
my $msg;

# setup all the zones and get their current status
&init;

while(1) {
	$msg = $elk->readMessage();
	&tickle_me;

	if(!defined($msg)) {
		sleep 1;
		

	} else {
	  my $logged = "";
	
      switch(ref($msg)) {
		case 'ElkM1::Control::Message::EthernetModuleTest' {
			# &logInfo($logged . "EthernetModuleTest: got one!");
			
		}
		
        case 'ElkM1::Control::Message::ZoneChangeUpdateReport' {
            my $zonenumber = $msg->getZone;
            my $zonename = $zonelist{$zonenumber}{'name'};
            my $zonestate = $msg->getState;
			my $zone_status = ($msg->isOpen) ? 'open' : 'closed';
			
			&hs_db_connect;
			&updateZoneStatus($zonenumber, $zone_status);

			if ($zonelist{$zonenumber}{'track_in_db'}) {
				&insertZoneStatusInDb($zonenumber, $zonename, $zone_status);
				$logged = "[LOGGED]";
			}
			
			&hs_db_disconnect;
			&logInfo($logged . $zonename . ' zone (' . $zonenumber . ') is now ' . $zonestate);
			
        }
		 
		case 'ElkM1::Control::Message::OutputChangeUpdate' {
			my $output_number = $msg->getOutput;
			my $output_name = $outputs{$output_number}{'name'};
			my $output_status = $msg->isOn ? 'on' : 'off';
			
			&hs_db_connect;
			&updateOutputStatus($output_number, $output_status);

			if ($outputs{$output_number}{'track_in_db'}) {
				&insertOutputStatusInDb($output_number, $output_name, $output_status);			
				$logged = "[LOGGED]";
			}
			
			&hs_db_disconnect;
			&logInfo($logged . 'Output ' . $output_name . '(' . $output_number . ') has just turned ' . $output_status);
			
		}
		
        case 'ElkM1::Control::Message::TemperatureReply' {
            my $groupname = $msg->getGroupName;
            my $groupnumber = $msg->getGroup;
            my $groupdevice = $msg->getDevice;
            my $temperature = $msg->getTemperature;
			&logInfo($logged . $groupname . ' ' . $groupnumber . ' ' . $groupdevice . ': ' . $temperature . $units);

        }
		
		case 'ElkM1::Control::Message::ArmingStatusReport' {
			my $area_number = 1;
			my $area_name = $areas{$area_number}{'name'};
			my $area_status = $msg->getArmedStatusName($area_number);
			my $area_alarm = $msg->getAlarmStatusName($area_number);
			
			&hs_db_connect;
			&updateAreaStatus($area_number, $area_status, $area_alarm);

			if ($areas{$area_number}{'track_in_db'}) {
				&updateAreaLog($area_number, $area_name, $area_status, $area_alarm);			
				$logged = "[LOGGED]";
			}
			
			&hs_db_disconnect;
			&logInfo($logged . 'Area ' . $area_name . '(' . $area_number . ') is ' . $area_status . '/' . $area_alarm);
			
		}
        
		else {
			&logInfo('Message not tracked.  ' . $msg->toString . '  ' . ref($msg));

        }
      }
   }

}

$elk->disconnect;


sub init {
	&logInfo("ZONE/OUTPUT/AREA INITIALIZATION -> BEGIN");
	&hs_db_connect;
	&zoneInitialization;
	&outputInitialization;
	&areaInitialization;
	&hs_db_connect;
	#print '>>>>>>>>>>>>>>> ElkM1::Control ' . $ElkM1::Control::VERSION . " <<<<<<<<<<<<<<<\n";
	&logInfo("ZONE/OUTPUT/AREA INITIALIZATION -> END");
}



sub zoneInitialization {
	my $zone_status = $elk->requestZoneStatus;
	#&logInfo("ZONE INITIALIZATION -> BEGIN");

	foreach my $zone_number (keys %zonelist) {
		my $status = logicalStatusNumberToString($zone_status->getLogicalStatus($zone_number));
		#print '   Zone: '. $zone_number . ', name: ' . $zonelist{$zone_number}{'name'} . ' = '. $status . "\n";
		&hs_db_execute("INSERT IGNORE INTO zone_statuses (zone_number, name) VALUES ($zone_number,'$zonelist{$zone_number}{'name'}')");
		&updateZoneStatus($zone_number, $status);
	}
	#&logInfo("ZONE INITIALIZATION -> END");
}


sub outputInitialization {
	my $output_status = $elk->requestControlOutputStatus;
	#&logInfo("OUTPUT INITIALIZATION -> BEGIN");

	foreach my $output_number (keys %outputs) {
		my $status = $output_status->isOn($output_number) ? 'on' : 'off';
		#print '   Output: '. $output_number . ', name: ' . $outputs{$output_number}{'name'} . ' = '. $status . "\n";
		&hs_db_execute("INSERT IGNORE INTO output_statuses (output_number, name) VALUES ($output_number,'$outputs{$output_number}{'name'}')");
		&updateOutputStatus($output_number, $status);
	}
	#&logInfo("OUTPUT INITIALIZATION -> END");
}



sub areaInitialization {
	my $area_status = $elk->requestArmingStatus;
	#&logInfo("AREA INITIALIZATION -> BEGIN");

	foreach my $area_number (keys %areas) {
		my $status = $area_status->getArmedStatusName($area_number);
		my $alarm = $area_status->getAlarmStatusName($area_number);
		#print '   Area: '. $area_number . ', name: ' . $areas{$area_number}{'name'} . ' = '. $status . '/' . $alarm . "\n";
		&hs_db_execute("INSERT IGNORE INTO area_statuses (area_number, name) VALUES ($area_number,'$areas{$area_number}{'name'}')");
		&updateAreaStatus($area_number, $status, $alarm);
	}
	#&logInfo("AREA INITIALIZATION -> END");
}



sub cleanup {
	&logInfo("EXITING - GRACEFULLY");
	&hs_db_disconnect;
	$elk->disconnect;
	&file_tickler_close;
	die 'stopped';
}



sub insertZoneStatusInDb {
	my $zone_number = shift;
	my $zone = shift;
	my $status = shift;
   
	if ($status eq 'open'){
	   &hs_db_execute("INSERT INTO zone_log (zone, time_open) VALUES ('$zone',NOW())");
	}

	else {
	    #find the corresponding open entry and set its close time
	    # SETS THE MOST RECENT OPEN ENTRY ONLY
	    &hs_db_execute("UPDATE zone_log SET time_close = NOW() WHERE zone = '$zone' AND time_open IS NOT NULL AND time_close IS NULL ORDER BY time_open DESC LIMIT 1");

	    #find any lost entries and set their close time to five seconds after the open time
	    # this should prevent future problems
	    &hs_db_execute("UPDATE zone_log SET time_close=(time_open + INTERVAL 5 SECOND) WHERE zone = '$zone' AND time_open IS NOT NULL AND time_close IS NULL");
	}
}


sub insertOutputStatusInDb {
	my $output_number = shift;
	my $output_name = shift;
	my $status = shift;
   
	if ($status eq 'on'){
	   &hs_db_execute("INSERT INTO output_log (output_number, output_name, time_open) VALUES ('$output_number', '$output_name', NOW())");
	}

	else {
	    #find the corresponding open entry and set its close time
	    # SETS THE MOST RECENT OPEN ENTRY ONLY
	    &hs_db_execute("UPDATE output_log SET time_close = NOW() WHERE output_number = '$output_number' AND time_open IS NOT NULL AND time_close IS NULL ORDER BY time_open DESC LIMIT 1");

	    #find any lost entries and set their close time to five seconds after the open time
	    # this should prevent future problems
	    &hs_db_execute("UPDATE output_log SET time_close=(time_open + INTERVAL 5 SECOND) WHERE output_number = '$output_number' AND time_open IS NOT NULL AND time_close IS NULL");
	}
}



sub updateAreaLog {
	my $area_number = shift;
	my $area_name = shift;
	my $status = shift;
	my $alarm = shift;
	
	#look for most recent record with the same status and alarm
	my $sth = &hs_db_execute("SELECT status,alarm_status FROM area_log WHERE area_number = $area_number ORDER BY updated_at DESC LIMIT 1");
   	my @data = $sth->fetchrow_array();
	$sth->finish;

	if (@data[0] ne $status || @data[1] ne $alarm ){
		&hs_db_execute("INSERT INTO area_log (area_number, area_name, status, alarm_status) VALUES ($area_number,'$area_name','$status','$alarm')");
	}
}



sub updateZoneStatus {
	my $zone_number = shift;
	my $status = shift;
	
	&hs_db_execute("UPDATE zone_statuses SET status = '$status' WHERE zone_number = $zone_number");
}



sub updateOutputStatus {
	my $output_number = shift;
	my $status = shift;
	
	&hs_db_execute("UPDATE output_statuses SET status = '$status' WHERE output_number = $output_number");
}



sub updateAreaStatus {
	my $area_number = shift;
	my $status = shift;
	my $alarm = shift;

	&hs_db_execute("UPDATE area_statuses SET status = '$status', alarm_status = '$alarm' WHERE area_number = $area_number");
}



# sub timestamp {
# 	use HTTP::Date;
# 	return '[' . HTTP::Date::time2iso() . '] '; 
# }



sub logicalStatusNumberToString {
	my $status = shift;
	switch($status) {
		case 0 { $status = 'undef'; }
		case 1 { $status = 'open'; }
		case 2 { $status = 'closed'; }
		case 3 { $status = 'closed'; }
	}
	return $status;
}


sub logInfo {
	my $msg = shift;
	my $logger = get_logger();
	# print $msg;
	$logger->info($msg);
}