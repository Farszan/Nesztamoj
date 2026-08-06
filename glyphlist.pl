#!/usr/bin/perl

use utf8;
binmode STDOUT, ":utf8";

my @code = ();
my %ivs_map = (); # IVS (ue01xx / uf8xx 問わず一元管理)
my $blank = "<span style=\"background-color:#ccc;\"> </span>";
my $kana = "イ";
my $hangul = "가";

open FH, "<:utf8", "work/codepoint.txt" or die "Cannot open work/codepoint.txt: $!";
while(<FH>){
  s/[\r\n]+$//;
  
  # A. 単一コードポイント (Base)
  if($_ =~ m/^u([0-9a-f]+)$/i){
    $code[hex($1)]++;
  }
  # B. IVSシーケンス (ue01xx および uf8xx / Rod)
  elsif($_ =~ m/^u([0-9a-f]+)-u([0-9a-f]+)$/i){
    my $base = lc($1);
    my $vs   = uc($2); # 例: E0100, F800
    push @{$ivs_map{$base}}, $vs;
  }
}
close FH;

print "<!DOCTYPE html><html><head><meta charset='utf8'>";
print "<style>body{font-family:Nesztamoj,Nesztamoj2a,Nesztamoj2b,Nesztamoj3;}span:hover{color:red;background-color:yellow;}</style></head><body>";
print "<h1>Nesztamoj fonts</h1>font version: 2026-08-06<br><br>";

# 1. 基底文字の一覧表示
foreach(0x00 .. 0xfff){
  $high = $_;
  $buffer = "";
  $count = 0;
  foreach(0x00 .. 0xff){
    $low = $_;
    $code = $high * 256 + $low;
    if($low % 32 == 0){ $buffer .= "<br>"; }
    if($code[$code]){
      if(0x302a <= $code && $code <= 0x302d || $code == 0x3099 || $code == 0x309a){
        $buffer .= $kana;
      }
      if($code == 0x302e || $code == 0x302f){
        $buffer .= $hangul;
      }
      $buffer .= "<span title=\"".sprintf("U+%04X", $code)."\">".pack('U', $code)."</span>";
      $count++;
    } else {
      $buffer .= $blank;
    }
  }
  if($count > 0){
    printf("U+%02Xxx ($count glyphs)\n", $high);
    print "<div>$buffer</div><br>\n";
  }
}

print "<h2>IVS / Rod Variants List</h2>\n";

# 2. IVS (IVD + Rod) の一覧表示
foreach my $base (sort { hex($a) <=> hex($b) } keys(%ivs_map)){
  my $base_dec = hex($base);
  
  # 基底文字 (U+XXXX) とその文字自体を表示
  print pack('U', $base_dec) . sprintf(" (U+%04X) ", $base_dec);

  # 重複排除と昇順ソート (E0100系, F800系順)
  my %seen = ();
  my @vs_list = grep { !$seen{$_}++ } @{$ivs_map{$base}};
  @vs_list = sort { hex($a) <=> hex($b) } @vs_list;

  foreach my $vs (@vs_list) {
    my $vs_dec = hex($vs);
    
    # 基底文字 + 異体字セレクタ の結合文字を出力
    print "<span title=\"" . sprintf("U+%04X U+%04X", $base_dec, $vs_dec) . "\">";
    print pack('U', $base_dec) . pack('U', $vs_dec);
    print "</span>";
  }
  print "<br>\n";
}

print "</body></html>\n";