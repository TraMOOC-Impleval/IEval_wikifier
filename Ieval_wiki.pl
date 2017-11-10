

use warnings;
use strict;
use open qw(:std :utf8);
use lib '/Users/irishendrickx/perl5/lib/perl5/';
use MediaWiki::API;
use JSON;
#use JSON::MaybeXS; #faster
use Data::Dumper; #for debugging only
# script to run the Implicit eval module using wikifiction



my $LANG= $ARGV[0]; #nl it
my $INPATH = $ARGV[1];
my $EN_sentence_FILE = $ARGV[2];
my $LANG_sentence_FILE = $ARGV[3];
my $runtype= $ARGV[4] || "all";


#if($#ARGV <2){die "this scripts needs 4 arguments: language-code dir-path file-with-engish file-with-targetlanguage [all|-1]";}

#("BG", "ZH", "CS", "DE", "EL", "HR", "IT", "NL", "PL", "PT", "RU")
# $LANG ("BG", "CS", "DE", "HR", "IT")  #these language are handled by lemmagen

my $DEBUG=0;
#my $LANG="PT";
print "$LANG\n";

#my $EN_sentence_FILE = "$LANG.prep.en.sentences";
#my $LANG_sentence_FILE = "$LANG.prep.".lc($LANG).".sentences";
#my $INPATH = "/vol/bigdata2/datasets2/TraMOOC/Data/Wikifier2017/Tune/wikiconfig/$LANG/$type/";
#my $INPATH = "/vol/bigdata2/datasets2/TraMOOC/Data/Wikifier2017/Tune/$LANG";


my $mw = MediaWiki::API->new( { api_url => 'https://en.wikipedia.org/w/api.php' }  );
my $mw_LANG = MediaWiki::API->new( { api_url => "https://$LANG.wikipedia.org/w/api.php" }  );


my $Wikifier_outputFILE = "$INPATH/$EN_sentence_FILE".".wikification.tagged.flat.html";  #file produced by wikifier/
my $wikititles_FILE = "$INPATH/$EN_sentence_FILE".".wikititles"; #list of wikipedia titles
my $LANG_lemfile = "$INPATH/$LANG_sentence_FILE.lem";  #lemmatized version of target sentences
my $synoFILE = "$INPATH/$LANG_sentence_FILE.synonyms";
my $scorefile = "$INPATH/$LANG_sentence_FILE.scores";
#input:
#1) EN-sentence file
#2) paralell TARGET lang-sentence-file
#3) Language code


#step 1 wikification of EN-sentence file
#1a run wikifier (slow process)
#1b and convert wikifier-output to simple format
if($runtype eq "all"){
 my $effepath = "$INPATH/";
 print "run_wikifier.sh $effepath  $EN_sentence_FILE $\n";
 system(" ./run_wikifier.sh $effepath $EN_sentence_FILE "); &convert_wikititles($Wikifier_outputFILE,  $wikititles_FILE);
}
#step 2 create lemmatized version of lang-sentence-file

print "perl run_lemmatizer.pl $LANG $INPATH/$LANG_sentence_FILE $LANG_lemfile \n";
#system(" perl run_lemmatizer.pl $LANG $INPATH/$LANG_sentence_FILE $LANG_lemfile ");

#step 3 do wikipedia-lookup

#wikipedia_lookup(en-wikititles, output-target-titles-and-its-synomyms)
 &wikipedia_lookup( $wikititles_FILE, $synoFILE);

#match_target(synonyms_file targetsentence_file $lemma_file )
my $scores =  &match_target($synoFILE,"$INPATH/$LANG_sentence_FILE", $LANG_lemfile);

print "score file $scorefile\n";
open(SCORES, ">",$scorefile);
print SCORES  $scores;
close(SCORES);



#compute scores:

# compute entity translation recall (no gold-data needed)
#match_target($SYNOfile, $LANG_sentence_FILE, $LANG_lemfile );
#assumption: we assume each topic and name is used unambiguously within one sentence and therefor do not need the step of full word-alignment (which in itself is already a crucial part of MT )
# we solve it by cheking which of the target wikititles match with a phrase in the target sentece.
# this prevents contamination of aplied method with parts of the to be evaluated results
# makes it a lot faster
# might lead to loss of certain items (but this will not be measuable in our tune set).

#input: synonym list = wikipedia lang-link concepts that were retrieved by wikifier.
#-for every synonym, check if it is present in LANG-sentence
#   ;needed, a fast checking  (seems index is faster than regex)




### ####  ####
sub wikipedia_lookup
{
  my $inputfile = $_[0];
  my $outfile = $_[1];

#my $inputfile = "/Users/irishendrickx/Work/TraMOOC/Wikification/Dev1/testq_july2016.en-nl.en.wikititles.txt";
#my #$outfile="/Users/irishendrickx/Work/TraMOOC/Wikification/Dev1/testq_july2016.en-nl.nl.wikititles.lookupeffe.txt";

#input file = list of ENGLISH wikipedia titles or urls
#we get the translated equivalent title AND
#we lookup the synonyms in Target languages

open(FILE, $inputfile) || die "can open inputfile $inputfile\n";
open(OUT, ">$outfile") || die "cannot open $outfile\n";
while(<FILE>){

  my $line = $_;
  chomp $line;
  my @wikititles = split /\s+/,$line;
  foreach my $ENtitle (@wikititles)
  {

    my $translation = &get_wikilinks(lc($LANG),"$ENtitle");
    print "translation $translation of $ENtitle\n";
 	  my $found_alts = &get_wiki_redirects("$translation");
    print OUT " $found_alts\t";
  }
  print OUT "\n";
 }
 close(FILE);
 close(OUT);

}



#my $ENtitle="Greenhouse_effect";   Japan

### ####  ####

#module to get wikilink for a specific language
sub get_wikilinks{

my $wikititle =$_[1];
my $langcode = $_[0];
my $translation = "";


#  print "EN title ($wikititle)";
# list of titles for "Albert Einstein" in different languages.
    my $titles = $mw->api( {
    action => 'query',
    titles => $wikititle,
    prop => 'langlinks',
    utf8 => 1,
    format => 'json',
    lllimit => 'max',
    lllang => $langcode
    } )
    || die $mw->{error}->{code} . ': ' . $mw->{error}->{details};

  if($DEBUG){ print Dumper($titles);}

   my ($pageid,$langlinks) = each ( %{ $titles->{query}->{pages} } );

  #this returns the lang-link
  foreach ( @{ $langlinks->{langlinks} } ) {
     $translation .= "$_->{'*'}";
     if($DEBUG){print "translation: ($translation)\n";}
  }

  return $translation;

}



### ### ####  ####
#module to get wikilink for a specific language
sub get_wiki_redirects{

my $wikititle =$_[0];
my $found_synonyms = "$wikititle|";
$found_synonyms =~ s/\s+/\_/g;

my $alltitles = $mw_LANG->api( {
    action => 'query',
    titles => $wikititle,
    prop => 'redirects',
    format => 'json',

    } )
    || die $mw_LANG->{error}->{code} . ': ' . $mw_LANG->{error}->{details};

#Debug just print to know how the structure looks like
#print Dumper($alltitles);

#The query returns a hashref. One of the entries in this structure is query which points to another hashref which contains pages. The pages hashref contains keys which are page ids. Each of these point to another hashref which contains a redirects entry which is a reference to an array containing all the pages to which this page redirects.

for my $pageid ( keys %{ $alltitles->{query}{pages} } ) {
    my $r = $alltitles->{query}{pages}{$pageid};
    #printf "Redirects for page %d with title '%s'\n", @{$r}{qw(pageid title)};
    for my $redirect ( @{ $r->{redirects} }) {
        if($DEBUG){printf "\t%d: '%s'\n", @{$redirect}{qw(pageid title)};}
        my $synonym = @{$redirect}{'title'};
        $synonym =~ s/\s+/\_/g;
        $found_synonyms .= "$synonym|";
    }
}

 return $found_synonyms;
}





### ####  ####
### convert Wikifier output to simple list of wiki titles per sentence line
sub convert_wikititles{

my $infile = $_[0];
my $outfile = $_[1];


open(OUT, ">$outfile")|| die "cant open $outfile\n";

open(FILE, $infile) || die "cannot open file: $infile";
while(<FILE>)
{
  my $line =$_;
  chomp($line);
  my @sentences = split '<br>' , $line;

  foreach my $el (@sentences){
    #sprint "$el\n\n";
    #wiki links have <a>
    while($el =~ /<a\sclass="wiki"\s+href="(.*?)"\s+cat=".*?">(.*?)<\/a>/g)
    {
      my $url=$1;
      my $wikiwords =$2;
      my $wikititle ="";
      if($url=~ /http:\/\/en.wikipedia.org\/wiki\/(.*)\s*/){ $wikititle = $1; }
      print OUT "$wikititle\t";
    }

    print OUT "\n";
}
}
close(FILE);
close(OUT);

}



#compute entity translation recall
#how many of the LANG entities for which we actually know that there exists a corresponding Wikipedia page
#practical implementation is this:
#how many of the entities that have an corresponding LANGLINK wikidia page (so matching found pairs), can we actually find in the LANG text/lemmas?
sub match_target{

my $synonyms_file= $_[0]; #nl it
my $sentence_file = $_[1];
my $lemma_file = $_[2];
my $str=0;
my $VERBOSE=0;

my $foundpairs=0;
my $nbrSynsets=0;
my $missed=0;

open my $SF, '<', $synonyms_file || die "cant open $synonyms_file\n";
chomp(my @synlist = <$SF>);
close $SF;

open my $TF, '<', $sentence_file || die " cant open $sentence_file\n";
chomp(my @sentences = <$TF>);
close $TF;

open my $LF, '<', $lemma_file || die " cannt open $lemma_file\n";
chomp(my @lemmas = <$LF>);
close $LF;

if($#synlist ne $#sentences){print "different nbr of items: $#synlist synonyms vs $#sentences sentences\n";}
if($#lemmas ne $#sentences){print "different nbr of items: $#lemmas lemmas vs $#sentences sentences\n";}

#fore every LANG sentence
#check foreach synonym  if it is present in the LANG sentence or lemmatized version
for(my $n =0;$n<=$#synlist;$n++)
{
#  print "\n$n ";
 my @synsets = split /\s+/, $synlist[$n];
 # lowercase alles
 my $current_sentence = lc($sentences[$n]);
 my $current_lemmas = lc($lemmas[$n]);
#    print "current sentence: $current_sentence\n";
 foreach my $sss (@synsets){
   #count empty elements in synonymlist -> english wiki-pages that did not have an equivalent in target wikipedia
    if($sss eq "|")
    {
        $missed++;
    }
    elsif($sss =~ /\w+/)
    {
      $nbrSynsets++;
      my @synonyms = split '\|', $sss;
      LOOP: foreach my $el (@synonyms){

       if($el =~ /(.*?)\_\(.*\)/)
       {
         $el = $1;
       }
       $el =~ s/\_/ /g;
       $el = lc($el);
       if($VERBOSE){print "EN? [$el] -?--- \n";}
       #oke so index is fast but i want to use \b to avoid erroneuous substring matching
       #not sure this double check is good idea
       if (index( $current_sentence, $el) > -1) {
             if($current_sentence =~ /\b$el\b/i){
         if($VERBOSE){print "\nFound [$el]"; }#//in [$current_sentence];
          $foundpairs++;
          last LOOP;
        }}
        elsif (index( $current_lemmas, $el ) > -1) {
          if($current_lemmas =~ /\b$el\b/i){
          if($VERBOSE) {print "\nFoundLEMMA [$el]";} #//in [$current_sentence];
          $foundpairs++;
          last LOOP;
        }}


#Argomentazione  -> andere zin

    }
  }
 }
}


#computing wikipedia target language coverage
my $wiki_target_coverage = $nbrSynsets / ($nbrSynsets+$missed);
#scoring of entity translation recall
my $entity_translation_recall= $foundpairs / ($nbrSynsets);

if($VERBOSE)
{
print "how many of the found Engish topics have an equivalent page in target language?\n";
print "$LANG wiki-target coverage=  $wiki_target_coverage = $nbrSynsets / ($nbrSynsets+$missed) \n";

print "entity_translation_recall: $entity_translation_recall  = $foundpairs found pairs / $nbrSynsets total possible pairs\n";


  print " in ",($#sentences+1),"  sentences\n";
 $str = sprintf("%s\t%d\t%.3f\t%.3f\n",$LANG, ($#sentences+1), $wiki_target_coverage, $entity_translation_recall);
}else{

  printf("%s\t%d\t%.3f\t%.3f\n",$LANG, ($#sentences+1), $wiki_target_coverage, $entity_translation_recall);

   $str  = sprintf("%s\t%d\t%.3f\t%.3f\n",$LANG, ($#sentences+1), $wiki_target_coverage, $entity_translation_recall);
   $str .= "$LANG wiki-target coverage=  $wiki_target_coverage = $nbrSynsets / ($nbrSynsets+$missed) \n";
   $str .=
  "entity_translation_recall: $entity_translation_recall  = $foundpairs found pairs / $nbrSynsets total possible pairs\n";
    $str .=  " in ($#sentences+1)  sentences\n";

}

return $str;
}
