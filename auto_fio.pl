#!/usr/bin/perl
##############################################################################
#
#****h* auto_fio.pl
#
# NAME
#              auto_fio.pl
#               DongpoLiu
#               9/22/2011
#
# DESCRIPTION
#              IOzone auto test script
#
#
#******
#
#############################################################################

use strict;
use Term::ANSIColor;
use Data::Dumper;

my ($test_file) = @ARGV;
print colored ("FIO test file size is $test_file\n", 'bold yellow');
if ($test_file eq 0)
{
	die "test file size can not be zero!\n";
}

my @rw_var = ("read", "write", "rw", "randread", "randwrite", "randrw");
my @bs_var = ("512", "1k", "2k", "4k", "8k", "16k", "32k", "64k", "128k", "256k", "512k", "1m", "2m", "4m", "8m", "16m","32m");
my @iodepth_var = ("1", "16", "32", "64");
my $runtime_var = $test_file/@bs_var/@rw_var/@iodepth_var;
my $ramp_time = 5; #in second
my $error_flag = 0;
my $test_file_name =join (" --name=/mnt/", $test_file);

system("rm *log* -fr");
system("mkdir log");
open (FIO_LOG, ">>fio_auto_$test_file.log") || die ("fail to open FIO Throughput log file");
foreach my $rw_item (@rw_var)
{
	foreach my $bs_item (@bs_var)
	{
		foreach my $iodepth_item (@iodepth_var)
		{
			my $present_time = join ("_", split(" ", localtime));
			$present_time =~s/\:/_/g;
			print colored ("\nRW: $rw_item   Block Size: $bs_item  IO Depth: $iodepth_item\n", 'bold yellow');
			my $fio_opt = sprintf (" --name=$test_file_name --size=$test_file --ioengine=libaio --prio=0 --numjobs=1 --direct=1");
			$fio_opt .= sprintf (" --rw=%s", $rw_item);
			$fio_opt .= sprintf (" --bs=%s", $bs_item);
			$fio_opt .= sprintf (" --iodepth=%s", $iodepth_item);
			$fio_opt .= sprintf (" --runtime=%s", $runtime_var);
			#$fio_opt .= sprintf (" --output=log/%s_%s_%s_%s.txt", $present_time, $rw_item, $bs_item, $iodepth_item);
			#print "fio option $fio_opt \n";
			#my $fio_return=system("fio $fio_opt");
			my $fio_return=`fio $fio_opt`;
                        print Dumper $fio_return;
			if ($fio_return)
			{
                             my $throughput = undef;
                             my $test_type  = undef;
                             foreach my $p (split(/\n/, $fio_return))  
                             {
                                next if $p !~ /aggrb=/;
                                if ($p =~ /^(\s{2,3})(\w{4,}:\sio)/)
                                {     
                                    $test_type = $2;
                                    $test_type  =~ s/:\sio//;                      
                                    $test_type  =~ s/^\s+//;                      
				}
				if ( $p =~ /(aggrb=.*\sminb=)/)
                                {
                                    my $value  = $1;
                                    $value     =~ s/aggrb=//;
                                    $value     =~ s/,\sminb=//;
                                    $value     =~ s/,//;
                                    if ($value =~ /MiB\/s/)
                                    {
                                        $value  =~ s/MiB\/s//;
                                        $value *= 1024;
                                    }
                                    else 
                                    {
                                        $value  =~ s/KiB\/s//;
                                    }   
                                    $throughput = $value;
                                } 
		                #open (FIO_LOG, ">>fio_auto_$test_file.log") || die ("fail to open FIO Throughput log file");
			        print FIO_LOG "RW: $rw_item   Block Size: $bs_item  IO Depth: $iodepth_item, IO Test Type: $test_type, Throughput: $throughput KiB\/s \n\n";
			        #close FIO_LOG;
                             }
			}
			sleep($ramp_time);
		}
	}
}
close FIO_LOG;
if ($error_flag)
{
	print colored ("there are $error_flag errors during fio run, please check error_log.txt for details", "bold red");
}
