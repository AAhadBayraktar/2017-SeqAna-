#Chr	Start	End	Ref	Alt			
#chr1	1020217	1020217	G	T
@iranome_columns=("Iranome/Total",
				  "Iranome/Lur",
				  "Iranome/Baloch",
				  "Iranome/Azeri",
				  "Iranome/Kurd",
				  "Iranome/Persian Gulf Islander",
				  "Iranome/Arab",
				  "Iranome/Persian",
				  "Iranome/Turkmen"
				  );

use LWP::Simple;
use Cwd 'abs_path';
use File::Basename;
open DB,dirname(abs_path($0))."/iranome.cache";
open DB_NEW,">".dirname(abs_path($0))."/iranome.cache.tmp";
while(<DB>){
	chomp;
	@arr=split(/\t/,$_);
	print DB_NEW "$_\n";
	$iranome_entry{$arr[0]}=join("\t",@arr[1..$#arr]);
}
close DB;
close DB_NEW;

open ANNOVAR,$ARGV[0];
while(<ANNOVAR>){
	chomp;
	if($_ =~ /^chr([0-9A-Z]+)\s+([0-9]+)\s+([0-9]+)\s+([A-Z\-]+)\s+([A-Z\-]+)/){
		$chr=$1;
		$coord=$2;
		$wt=$4;
		$mt=$5;
		if($wt eq "-"){$wt="_"};
		if($mt eq "-"){$mt="_"};
		$iranome_query{$chr."-".$coord."-".$wt."-".$mt}=$_;
	}
	elsif($_=~ /^Chr\s+Start/){
		$header=$_."\t".join("\t",@iranome_columns);
		print $header,"\n";
	}
}
close ANNOVAR;

%additional_iranome_entries=();
foreach $q (keys %iranome_query){
	if(defined $iranome_entry{$q}){
		print $iranome_query{$q},$iranome_entry{$q},"\n";
	}
	else{
		my $url = 'http://www.iranome.com/variant/'.$q;
		my $content = get $url;
		if($content!~ /not found in the Iranome Database/i){
			 @lines=split(/\n/,(split(/\s*<div\s+id=\"frequency_info_container\"\>/,$content))[1]);
			 $table="";
			 $table_start=0;
			 foreach $line (@lines){
				if($line=~ /<table/){
					$table_start=1;
				}
				if($table_start){
					$table.=$line;
				}
				last if($line=~ /<\/table/);
			 }
			$table =~ s/<\/?tbody>/\n/g;
			$table =~  s/\<\/thead>/\n/g;
			$table =~ s/<td>//g;
			$table =~ s/<\/td>\s*/\t/g;
			$table =~ s/\t+/\t/g;
			$table =~ s/<tr>/ /g;
			$table =~ s/<\/tr>/\n/g;
			$table =~ s/<\/?tfoot>//g;
			$table =~ s/<\/?b>/\t/g;
			@lines=split(/\n/,$table);
			%freq_table=();
			foreach $line (@lines){
				if($line !~ /[<>]/ && $line =~ /[0-9]/){
					$line =~ s/^\s+//;
					$line=~ s/\t+/\t/g;
					$line=~ s/([0-9]+)\s+([0-9]+)/$1\t$2/g;
					@arr=split(/\t/,$line);
					$freq_table{"Iranome/".$arr[0]}=$arr[7];
					#print $line,"\n";
				}
			}   
			print $iranome_query{$q};
			$additional_iranome_entries{$q}=$q;
			foreach $column (@iranome_columns){
					print "\t",$freq_table{$column};
					$additional_iranome_entries{$q}.="\t".$freq_table{$column};
			}
			print "\n";
		}
		else{
			print $iranome_query{$q};
			$additional_iranome_entries{$q}.=$q;
			foreach $column (@iranome_columns){
					print "\t-1";
					$additional_iranome_entries{$q}.="\t-1";
			}
			print "\n";
		}
		sleep(1);
	}
}
open DB_NEW,">>".dirname(abs_path($0))."/iranome.cache.tmp";
foreach $key (keys %additional_iranome_entries){
	print DB_NEW $additional_iranome_entries{$key},"\n";
}
close DB_NEW;
$file1=dirname(abs_path($0))."/iranome.cache.tmp";
$file2=dirname(abs_path($0))."/iranome.cache";
use File::Copy qw(copy);
copy ($file1,$file2);