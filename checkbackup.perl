#!/usr/bin/perl
#
# purpose:	simple script to see if the backup script runs smooethly.
#
#	example usage: perl checkbackup.perl  --datasets=puddle --snapshotinterval=300
#
#	this will check if the dataset puddle has a snapshot made within the last 10 minutes since wake/boot
#



use JNX::Configuration;

my %commandlineoption = JNX::Configuration::newFromDefaults( {
																	'host'					=>	['','string'],
																	'hostoptions'			=>	['-c blowfish -C -l root','string'],

																	'datasets'				=>	['puddle','string'],
																	'snapshotinterval'		=>	[300,'number'],
																	'snapshottime'			=>	[10,'number'],
																	'anyBarPortNumber'		=> 	[1738,'number'],

																	'verbose'				=>	[0,'flag'],
																	'debug'					=>	[0,'flag'],
																	'anybarFailureColor'	=> 	['red', 'string'],
															 }, __PACKAGE__ );

$commandlineoption{verbose}=1 if $commandlineoption{debug};

use strict;
use JNX::ZFS;
use JNX::System;


my %host 		= (	host => $commandlineoption{host}, hostoptions => $commandlineoption{hostoptions}, debug=>$commandlineoption{debug},verbose=>$commandlineoption{verbose});

JNX::System::checkforrunningmyself($commandlineoption{'datasets'}) || die "Already running which means lookup for snapshots is too slow";

my $lastwaketime 	= JNX::System::lastwaketime();
my @datasetstotest	= split(/,/,$commandlineoption{'datasets'});

my $anyBarPortNumber = $commandlineoption{'anyBarPortNumber'};

my $anybarFailureColor = $commandlineoption{'anybarFailureColor'};

for my $datasettotest (@datasetstotest)
{
	print STDERR "Testing dataset: $datasettotest\n";

	my @snapshots		= JNX::ZFS::getsnapshotsfordataset(%host,dataset=>$datasettotest);
	# print STDERR "Snapshots: @snapshots\n";

	my $snapshottime	= JNX::ZFS::timeofsnapshot( pop @snapshots );

	my $snapshotoffset	= (2 * $commandlineoption{'snapshotinterval'}) + $commandlineoption{'snapshottime'};

	if( $snapshottime + $snapshotoffset < time() )
	{
		if( $lastwaketime + $snapshotoffset < time() )
		{
			print STDERR "Last snapshot for dataset (".$datasettotest."):".localtime($snapshottime)." - too old\n";
			system("/bin/echo -n ".$anybarFailureColor." | nc -4u -w0 localhost ".$anyBarPortNumber);
			exit 1;
		}
		else
		{
			print STDERR "Not long enough after reboot\n";
			system("/bin/echo -n orange | nc -4u -w0 localhost ".$anyBarPortNumber);
			exit 0;
		}
	}
	print STDERR "Last snapshot for dataset (".$datasettotest."):".localtime($snapshottime)." - ok\n";
	system("/bin/echo -n black | nc -4u -w0 localhost ".$anyBarPortNumber);
}
exit 0;

