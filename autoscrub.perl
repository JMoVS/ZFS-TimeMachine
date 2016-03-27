#!/usr/bin/perl
#
# purpose:	simple script to automatically scub zpools when needed
#
#	example usage: perl autoscrub.perl  --scrubinterval=7
#
#	this will start a scrub on all pools if the last scrub was 7 days or longer ago
#



use JNX::Configuration;

my %commandlineoption = JNX::Configuration::newFromDefaults( {																	

																	'host'					=>	['','string'],
																	'hostoptions'			=>	['-c blowfish -C -l root','string'],

																	'pools'					=>	['allavailablepools','string'],

																	'scrubinterval'			=>	[7,'number'],
																	'verbose'				=>	[0,'flag'],
																	'debug'					=>	[0,'flag'],
															 }, __PACKAGE__ );

$commandlineoption{verbose}=1 if $commandlineoption{debug};

my %host 		= (	host => $commandlineoption{host}, hostoptions => $commandlineoption{hostoptions} , debug=>$commandlineoption{debug},verbose=>$commandlineoption{verbose});


use strict;

use JNX::ZFS;
use JNX::System;

my %pools	= %{ JNX::ZFS::pools( %host ) };
my @scrubpools;

if( $commandlineoption{pools} eq 'allavailablepools' )
{
	@scrubpools = (keys %pools);
}
else
{
	@scrubpools = split( /[,\s]/,$commandlineoption{pools} );
}



for my $pool (@scrubpools )
{
	if( defined $pools{$pool} )
	{
		if ($pools{$pool}{scanerrors} > 0) {
			print STDERR "errors in pool ".$pool;
			system("/bin/echo -n red | nc -4u -w0 localhost 1740");
		}
		else
		{
			if( $pools{$pool}{lastscrub} < ( time() - (86400*$commandlineoption{scrubinterval})) ) 
			{
				if (!defined(JNX::System::executecommand(%host, command=> 'zpool scrub '.$pool)))
				{
					system("/bin/echo -n red | nc -4u -w0 localhost 1740");
					die "could not start scrub: $!";
				}
				print "$pool: starting scrub \n";
				system("/bin/echo -n black | nc -4u -w0 localhost 1740");
			}
			else
			{
				print "$pool: no scrub needed\n";
				system("/bin/echo -n black | nc -4u -w0 localhost 1740");
			}
		}
		}
	}
}


