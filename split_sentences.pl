use open qw(:std :utf8);
use warnings;

#nb --skips the first line of file!

#foreach my $LANG ("BG", "ZH", "CS", "DE", "EL", "HR", "IT", "NL", "PL", "PT", "RU")
  my $LANG="EL";
{

  print "$LANG\n";


  my $INPATH = "/vol/bigdata2/datasets2/TraMOOC/Data/Wikifier2017/Tune/$LANG";

    my $EN_sentence_FILE = "$INPATH/$LANG.prep.en.sentences";
    my $LANG_sentence_FILE = "$INPATH/$LANG.prep.".lc($LANG).".sentences";

$filename = "$INPATH/$LANG.prep.tab_tune.tab";

print "$filename\n";


$nbr_s=0;
$teller =0;

open(EOUT,">", $EN_sentence_FILE );
open(TOUT,">", $LANG_sentence_FILE );
open(FILE, $filename);
while(<FILE>)
{
 $line =$_;
 $teller++;
 if($teller>1) ##NB the test and tune data has a first line that is the legenda
  {
  @parts = split /\t+/, $line;
  $ID=$parts[0];
  $en_s =$parts[2];
  $lang_s =$parts[3];


  #count: nbr of stences en length
  if($en_s =~ /\w\w+/ ){
    $nbr_s++;


    print EOUT "$en_s\n";
    print TOUT "$lang_s\n";

#
#   $en_link =$parts[7];
#   $lang_link =$parts[8];
#   $en_topic =$parts[5];
#   $lang_topic =$parts[6];
#
#   if($en_topic =~ /NULL/){$en_topic =~ s /NULL/NULL(0)/g;}
#   if($lang_topic =~ /NULL/){$lang_topic =~ s /NULL/NULL(0)/g;}
#   if($en_topic =~ /NONE\(.*?\)/){$en_topic =~ s/NONE\(.*?\)/NONE(0)/g;}
#   if($lang_topic =~ /NONE\(.*?\)/){$lang_topic =~ s/NONE\(.*?\)/NONE(0)/g;}
# #print "LANGS $lang_s\n";
}


#print "EN TOPIC $en_topic\n";
# if($en_topic =~ /\(\d+\)/){
# $en_topic =~ s/\(\d+\),?\s?/@/g;
# @en_topics = split /@/,$en_topic;
# $lang_topic =~ s/\(\d+\),?\s?/@/g;
# @lang_topics = split /@/,$lang_topic;
#
# if($#lang_topics >0 && $#lang_topics ne $#en_topics){print STDERR "error in $ID with $#lang_topics ne $#en_topics\n";}
#
# $count_topics += $#en_topics+1;
# $count_lang_topics+= $#lang_topics+1;
#
# for($x=0;$x<=$#lang_topics;$x++)
# {
#   print OUT "$en_topics[$x]\t$lang_topics[$x]\n";
#
#   $lengthc_lang_topics += length($lang_topics[$x]);
#
#   my @effe =split /\s+/, $lang_topics[$x];
#   $length_lang_topics += ($#effe+1);
# #  print "$lang_topics[$x] heeft ",length($lang_topics[$x]), "chars and $#effe +1 words\n";
# }

#}
}
}
close(FILE);
close(TOUT);
close(EOUT);

}
