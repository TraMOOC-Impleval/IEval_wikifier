use utf8;
use strict;

my $LANG = $ARGV[0];
my $infile =$ARGV[1];
my $outfile =$ARGV[2];


my $DIR="/vol/bigdata2/datasets2/TraMOOC/Tools/Lemmatizers/cst_lemmatizer/cstlemma";



 if($LANG eq "ZH")
 {
   system("cp $infile $outfile\n");

 }else{

  my $lang = lc($LANG);
  my $lexicon;

  if($LANG eq "NL")
  {
  #do frog and rewrite format


  }

  elsif($LANG eq "PL")
  {
    system("$DIR/src/cstlemma -L -eU -p -q- -t- -U- -H2  -m0 -l -B'\$w' -b'\$w' -u- -c'\$b[[\$b0]?\$B]\$s'  -f  $DIR/pretrained_models/polish/flexrules -d $DIR/pretrained_models/polish/dict -i $infile  -o mijntempje") ;

    rewrite_cstlemma($infile,$outfile);

  }elsif
  ($LANG eq "EL")
  {
    system("$DIR/src/cstlemma -L -eU -p -q- -t- -U- -H2  -m0 -l -B'\$w' -b'\$w' -u- -c'\$b[[\$b0]?\$B]\$s'  -f  $DIR/pretrained_models/greek/greek_flexrules -d $DIR/pretrained_models/greek/greek_dict -i $infile  -o mijntempje") ;

    rewrite_cstlemma($infile,$outfile);

  }elsif($LANG eq "PT")
  {
   system("$DIR/src/cstlemma -L -eU -p -q- -t- -U- -H2  -m0 -l -B'\$w' -b'\$w' -u- -c'\$b[[\$b0]?\$B]\$s'  -f  $DIR/pretrained_models/portuguese/flexrules-supplement-with-dict -d $DIR/pretrained_models/portuguese/dict -i $infile  -o mijntempje") ;

    rewrite_cstlemma($infile,$outfile);

  }
  elsif($LANG eq "RU")
  {
    system("$DIR/src/cstlemma -L -eU -p -q- -t- -U- -H2  -m0 -l -B'\$w' -b'\$w' -u- -c'\$b[[\$b0]?\$B]\$s'  -f  $DIR/pretrained_models/russian/flexrules0 -d $DIR/pretrained_models/russian/dict -i $infile  -o mijntempje") ;

    rewrite_cstlemma($infile,$outfile);

  }
    #how annoying that these lexicons do not have uniform names.
    elsif($LANG =~ /IT/ )  #if($LANG =~ /(BG|CS|DE|IT|HR|ZH)/ )
    {
      $lexicon = "/vol/bigdata2/datasets2/TraMOOC/Tools/Lemmatizers/lemmagen/v2/data/lemmatizer/lem-m-$lang.bin";
        print "./run_lemmagen.sh $lexicon $infile $outfile\n";
        system("./run_lemmagen.sh $lexicon $infile $outfile");
  }
  elsif($LANG =~ /HR/ )    #we use serbian for Croatian text
  {
      $lang = "sr"; #we use serbian for Croatian text
      $lexicon = "/vol/bigdata2/datasets2/TraMOOC/Tools/Lemmatizers/lemmagen/v2/data/lemmatizer/lem-me-$lang.bin";
      system("./run_lemmagen.sh $lexicon $infile $outfile");

  }elsif($LANG =~ /DE/ )    #german needs extra conversion,
{
    $lang = "ge";
    $lexicon = " Lemmatizers/lemmagen/v2/data/lemmatizer/lem-m-$lang.bin";
    system("iconv  -c -f utf-8 -t WINDOWS-1250 <$infile >$infile.temp");
    system("./run_lemmagen.sh $lexicon $infile.temp $infile.temp.lem");
    system("iconv  -c -f WINDOWS-1250 -t utf-8  < $infile.temp.lem > $outfile");
}else{   #BG and CS
    $lexicon = "/vol/bigdata2/datasets2/TraMOOC/Tools/Lemmatizers/lemmagen/v2/data/lemmatizer/lem-me-$lang.bin";
    system("./run_lemmagen.sh $lexicon $infile $outfile");
  }

}



sub rewrite_cstlemma{

my $infile = $_[0];
my $outfile= $_[1];

open(OUT, ">$outfile")|| die "cant open $outfile\n";
open(FILE, "mijntempje" || die "cannot open file: mijntempje");
while(<FILE>)
{
  my $line =$_;
  chomp($line);
  my @parts = split /\s+/, $line;
  #in case of words without lemma, we take the wordform itself
  #in case of multiple lemmas, we take the first one.
  foreach my $el (@parts)
  {
    my $lemma="$el";
    if($el =~ /(.*?)\|+.*/){$lemma = $1;}

    print OUT "$lemma ";
  }

    print OUT "\n";

}
close(FILE);
close(OUT);

}
