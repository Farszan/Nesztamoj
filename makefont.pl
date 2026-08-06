#!/usr/bin/perl

use utf8;

my $version = "2026-08-06";
my $author = "Farszan";

my $fontname;
if($ARGV[0] eq "2a"){
  $fontname = "Nesztamoj2a";
} elsif($ARGV[0] eq "2b"){
  $fontname = "Nesztamoj2b";
} elsif($ARGV[0] eq "3"){
  $fontname = "Nesztamoj3";
} else {
  $fontname = "Nesztamoj";
}

$FONTFORGE = "fontforge";
$PERL = "perl";
$TTX = "ttx";

$WORK_DIR = "work";
$GLYPH_DIR = "$WORK_DIR/glyph";
$FONT_DIR = "$WORK_DIR/font";
mkdir($FONT_DIR);

if(-e "$FONT_DIR/$fontname.ttf"){
  print(".ttf File exists.");
  exit;
}

$hankaku_data = `wget -nv https://raw.githubusercontent.com/Farszan/Chelzas-GlyphWiki/main/Group/HalfwidthGlyphs-BMP.txt -O- 2>> $WORK_DIR/stderr.txt`;
utf8::decode($hankaku_data);
$temp = `wget -nv https://raw.githubusercontent.com/Farszan/Chelzas-GlyphWiki/main/Group/HalfwidthGlyphs-SMP.txt -O- 2>> $WORK_DIR/stderr.txt`;
utf8::decode($temp);
$hankaku_data = $hankaku_data."\n".$temp;
$temp = `wget -nv https://raw.githubusercontent.com/Farszan/Chelzas-GlyphWiki/main/Group/farszanov_Halfwidth-Nech.txt -O- 2>> $WORK_DIR/stderr.txt`;
utf8::decode($temp);
$hankaku_data = $hankaku_data."\n".$temp;

$nsgh = `wget -nv https://raw.githubusercontent.com/Farszan/Chelzas-GlyphWiki/main/Group/NonSpacingGlyphs-Halfwidth.txt -O- 2>> $WORK_DIR/stderr.txt`;
utf8::decode($nsgh);
$nsgf = `wget -nv https://raw.githubusercontent.com/Farszan/Chelzas-GlyphWiki/main/Group/NonSpacingGlyphs-Fullwidth.txt -O- 2>> $WORK_DIR/stderr.txt`;
utf8::decode($nsgf);

my $baseline = 30;

my %glyphlist = ();
my %ivslist = ();
open my $fh, "<:utf8", "$WORK_DIR/codepoint.txt";
while(<$fh>){
  if($ARGV[0] eq "2a"){
    if($_ =~ m/^(u00[0-9a-f]{2})\n$/){
      $glyphlist{$1} = $1;
    }
    if($_ =~ m/^(u2[0-7]{1}[0-9a-f]{3})\n$/){
      $glyphlist{$1} = $1;
    }
    if($_ =~ m/^(u2[0-7]{1}[0-9a-f]{3}-uf8[0-9a-f]{2})\n$/){
      $ivslist{$1} = $1;
    }
    if($_ =~ m/^(u2[0-7]{1}[0-9a-f]{3}-ue01[0-9a-f]{2})\n$/){
      $ivslist{$1} = $1;
    }
  } elsif($ARGV[0] eq "2b"){
    if($_ =~ m/^(u00[0-9a-f]{2})\n$/){
      $glyphlist{$1} = $1;
    }
    if($_ =~ m/^(u2[8-9a-f]{1}[0-9a-f]{3})\n$/){
      $glyphlist{$1} = $1;
    }
    if($_ =~ m/^(u2[8-9a-f]{1}[0-9a-f]{3}-uf8[0-9a-f]{2})\n$/){
      $ivslist{$1} = $1;
    }
    if($_ =~ m/^(u2[8-9a-f]{1}[0-9a-f]{3}-ue01[0-9a-f]{2})\n$/){
      $ivslist{$1} = $1;
    }
  } elsif($ARGV[0] eq "3"){
    if($_ =~ m/^(u00[0-9a-f]{2})\n$/){
      $glyphlist{$1} = $1;
    }
    if($_ =~ m/^(u3[0-9a-f]{4})\n$/){
      $glyphlist{$1} = $1;
    }
    if($_ =~ m/^(u3[0-9a-f]{4}-uf8[0-9a-f]{2})\n$/){
      $ivslist{$1} = $1;
    }
    if($_ =~ m/^(u3[0-9a-f]{4}-ue01[0-9a-f]{2})\n$/){
      $ivslist{$1} = $1;
    }
  } else {
    if($_ =~ m/^(u[0-9a-f]{4})\n$/){
      $glyphlist{$1} = $1;
    }
    if($_ =~ m/^(u1[0-9a-f]{4})\n$/){
      $glyphlist{$1} = $1;
    }
    if($_ =~ m/^(u[0-9a-f]{4}-uf8[0-9a-f]{2})\n$/){
      $ivslist{$1} = $1;
    }
    if($_ =~ m/^(u[0-9a-f]{4}-ue01[0-9a-f]{2})\n$/){
      $ivslist{$1} = $1;
    }
  }
}
close $fh;

if($ARGV[0] eq "2a"){
  $glyphlist{"u4e00"} = "u4e00";
} elsif($ARGV[0] eq "2b"){
  $glyphlist{"u4e00"} = "u4e00";
} elsif($ARGV[0] eq "3"){
  $glyphlist{"u4e00"} = "u4e00";
}

open my $fh, ">:utf8", "$FONT_DIR/$fontname.scr";
print $fh qq|Open("basefont.ttf")\n|;

print $fh qq|Reencode("UnicodeFull")\n|;
print $fh qq|SetTTFName(0x411,0,"$author")\n|;
print $fh qq|SetTTFName(0x411,1,"$fontname")\n|;
print $fh qq|SetTTFName(0x411,2,"Regular")\n|;
print $fh qq|SetTTFName(0x411,4,"$fontname Regular")\n|;
print $fh qq|SetTTFName(0x411,5,"$version")\n|;
print $fh qq|SetTTFName(0x411,6,"$fontname")\n|;
print $fh qq|SetTTFName(0x409,0,"$author")\n|;
print $fh qq|SetTTFName(0x409,1,"$fontname")\n|;
print $fh qq|SetTTFName(0x409,2,"Regular")\n|;
print $fh qq|SetTTFName(0x409,4,"$fontname Regular")\n|;
print $fh qq|SetTTFName(0x409,5,"$version")\n|;
print $fh qq|SetTTFName(0x409,6,"$fontname")\n|;
print $fh qq|SetFontHasVerticalMetrics(1)\n|;

foreach(sort(keys(%glyphlist))){
  my $name = $glyphlist{$_};
  my $dir = "$GLYPH_DIR/".substr($name,0,length($name)-3)."/".substr($name,0,length($name)-2);
  print $fh qq|Print(0$_)\n|;
  print $fh qq|Select(0$_)\n|;
  print $fh qq|Import("$dir/$glyphlist{$_}.svg")\n|;
#  print $fh qq|Simplify()\n|;
  print $fh qq|Scale(105,105,512,307)\n|;
  if(index($nsgh.$nsgf, "\[\[$name\]\]") != -1){
    print $fh qq|SetWidth(0)\n|;
  } elsif(index($hankaku_data, "\[\[$name\]\]") != -1){
    print $fh qq|SetWidth(512)\n|;
  } else {
    print $fh qq|SetWidth(1024)\n|;
  }
  if(index($nsgh, "\[\[$name\]\]") != -1){
    print $fh qq|Move(-512, $baseline)\n|;
  } elsif(index($nsgf, "\[\[$name\]\]") != -1){
    print $fh qq|Move(-1024, $baseline)\n|;
  } else {
    print $fh qq|Move(0, $baseline)\n|;
  }
  print $fh qq|SetVWidth(1024)\n|;
  print $fh qq|RoundToInt()\n|;
  print $fh qq|DontAutoHint()\n|;
  print $fh qq|ClearHints()\n|;
  print $fh qq|AutoInstr()\n|;
}

if(scalar(keys(%ivslist)) > 0){
  $ivs_offset = 0x90000;
  open my $fh2, ">$FONT_DIR/$fontname.ivs";
  print $fh2 "<cmap_format_14 platformID=\"0\" platEncID=\"5\" format=\"14\" length=\"0\" numVarSelectorRecords=\"0\">\n";

  # 1. 基底文字ごとに IVS リストをグループ化
  my %base_to_ivs = ();
  foreach my $ucswithivs (keys %ivslist) {
    my @temp = split(/-/, $ucswithivs);
    my $base = $temp[0];
    push @{$base_to_ivs{$base}}, $ucswithivs;
  }

  # 2. 基底文字ごとに判定・処理
  foreach my $ucswithoutivs (sort keys %base_to_ivs) {
    # 同一基底文字内における既出 SVG との対応表 (SVG絶対パス => 割り当て済み cpname)
    my %seen_svgs = ();
    
    # 基底文字のデフォルト cpname
    my $base_cpname = (length($ucswithoutivs) > 5) ? "u".uc(substr($ucswithoutivs, 1)) : "uni".uc(substr($ucswithoutivs, 1));
    
    # 基底文字の SVG パス
    my $base_dir = "$GLYPH_DIR/".substr($ucswithoutivs,0,length($ucswithoutivs)-3)."/".substr($ucswithoutivs,0,length($ucswithoutivs)-2);
    my $base_svg = "$base_dir/$ucswithoutivs.svg";

    # IVS を昇順ソートして順番に評価
    foreach my $ucswithivs (sort @{$base_to_ivs{$ucswithoutivs}}) {
      my @temp = split(/-/, $ucswithivs);
      my $uv = "0x".substr($temp[0], 1);
      my $uvs = "0x".substr($temp[1], 1);
      
      # IVSの基底文字名 (u9089) からディレクトリ階層を計算
      my $base_part = $temp[0];
      my $dir = "$GLYPH_DIR/".substr($base_part,0,length($base_part)-3)."/".substr($base_part,0,length($base_part)-2);
      my $target_svg = "$dir/$ucswithivs.svg";

      # A. 基底文字と比較（一致していれば基底文字の cpname を利用）
      if (-e $target_svg && -e $base_svg && !`diff "$target_svg" "$base_svg" 2>/dev/null`) {
        print $fh2 "<map uvs=\"$uvs\" uv=\"$uv\" name=\"$base_cpname\"/>\n";
        next;
      }

      # B. 同一基底文字の先行 IVS と比較（一致していればその GID/cpname を再利用）
      my $matched_cpname = undef;
      foreach my $prev_svg (keys %seen_svgs) {
        if (-e $target_svg && !`diff "$target_svg" "$prev_svg" 2>/dev/null`) {
          $matched_cpname = $seen_svgs{$prev_svg};
          last;
        }
      }

      if (defined $matched_cpname) {
        print $fh2 "<map uvs=\"$uvs\" uv=\"$uv\" name=\"$matched_cpname\"/>\n";
      } else {
        # C. 過去のいずれとも異なる新規字形の場合（新しい PUA GID を割り当て）
        my $cp = sprintf("0u%x", $ivs_offset);
        my $cpname = "u".uc(substr($cp, 2));
        
        print $fh qq|Print($cp)\n|;
        print $fh qq|Select($cp)\n|;
        print $fh qq|Import("$dir/$ivslist{$ucswithivs}.svg")\n|;
#       print $fh qq|Simplify()\n|;
        print $fh qq|Scale(105,105,512,307)\n|;
        print $fh qq|SetWidth(1024)\n|;
        print $fh qq|Move(0, $baseline)\n|;
        print $fh qq|SetVWidth(1024)\n|;
        print $fh qq|RoundToInt()\n|;
        print $fh qq|DontAutoHint()\n|;
        print $fh qq|ClearHints()\n|;
        print $fh qq|AutoInstr()\n|;
        
        print $fh2 "<map uvs=\"$uvs\" uv=\"$uv\" name=\"$cpname\"/>\n";
        
        # 既出リストに登録
        $seen_svgs{$target_svg} = $cpname;
        $ivs_offset++;
      }
    }
  }
  print $fh2 "</cmap_format_14>\n";
  close $fh2;
}

my $flag;
if(scalar(keys(%ivslist)) > 0){
  $flag = 0b111111111111111111111111 & 0x80;
} else {
  $flag = 0b111111111111111111111111 & (0x4 | 0x80);
}
print $fh qq|Generate("$FONT_DIR/$fontname.raw.ttf", "", $flag)\n|;
print $fh qq|Quit()\n|;
close $fh;

if(scalar(keys(%ivslist)) > 0){
  my $dummy = `$FONTFORGE -script $FONT_DIR/$fontname.scr 2>> $WORK_DIR/stderr.txt`;
  $dummy .= `$TTX -t cmap -t OS\\/2 -t post $FONT_DIR/$fontname.raw.ttf 2>> $WORK_DIR/stderr.txt`;
  $dummy .= `$PERL divide_ttx.pl $FONT_DIR/$fontname.raw`;
  $dummy .= `cat $FONT_DIR/$fontname.raw.pre > $FONT_DIR/$fontname.ivs.ttx`;
  $dummy .= `cat $FONT_DIR/$fontname.ivs >> $FONT_DIR/$fontname.ivs.ttx`;
  $dummy .= `cat $FONT_DIR/$fontname.raw.post >> $FONT_DIR/$fontname.ivs.ttx`;
  $dummy .= `$TTX -m $FONT_DIR/$fontname.raw.ttf $FONT_DIR/$fontname.ivs.ttx 2>> $WORK_DIR/stderr.txt`;
  $dummy .= `cp gsub_dummy.txt $FONT_DIR/$fontname.ttx`;
  $dummy .= `$TTX -m $FONT_DIR/$fontname.ivs.ttf $FONT_DIR/$fontname.ttx 2>> $WORK_DIR/stderr.txt`;
  
  my $filesize = -s "$FONT_DIR/$fontname.ttf";
  my $padding = (4 - $filesize % 4) % 4;
  if($padding > 0){
    $dummy .= `head -c $padding /dev/zero >> $FONT_DIR/$fontname.ttf`;
  }
} else {
  my $dummy = `$FONTFORGE -script $FONT_DIR/$fontname.scr 2>> $WORK_DIR/stderr.txt`;
  $dummy .= `$TTX -t cmap -t OS\\/2 -t post $FONT_DIR/$fontname.raw.ttf 2>> $WORK_DIR/stderr.txt`;
  $dummy .= `$PERL divide_ttx.pl $FONT_DIR/$fontname.raw`;
  $dummy .= `cat $FONT_DIR/$fontname.raw.pre > $FONT_DIR/$fontname.ttx`;
  $dummy .= `cat $FONT_DIR/$fontname.raw.post >> $FONT_DIR/$fontname.ttx`;
  $dummy .= `$TTX -m $FONT_DIR/$fontname.raw.ttf $FONT_DIR/$fontname.ttx 2>> $WORK_DIR/stderr.txt`;
  
  my $filesize = -s "$FONT_DIR/$fontname.ttf";
  my $padding = (4 - $filesize % 4) % 4;
  if($padding > 0){
    $dummy .= `head -c $padding /dev/zero >> $FONT_DIR/$fontname.ttf`;
  }
}

unlink("$FONT_DIR/$fontname.raw.ttf");
unlink("$FONT_DIR/$fontname.raw.ttx");
unlink("$FONT_DIR/$fontname.raw.pre");
unlink("$FONT_DIR/$fontname.raw.post");
unlink("$FONT_DIR/$fontname.ivs.ttf");