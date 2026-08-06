#!/usr/bin/perl

use utf8;

my $MAX_GLYPHS = 65528; # GID上限 (.notdef 等を除いた安全値)
my $WORK_DIR   = "work";
my $GLYPH_DIR  = "$WORK_DIR/glyph";
my $codepoint_file = "$WORK_DIR/codepoint.txt";

unless (-e $codepoint_file) {
  die "[ERROR] $codepoint_file が見つかりません。\n";
}

my @modes = (
  { id => "",   name => "Nesztamoj" },
  { id => "2a", name => "Nesztamoj2a" },
  { id => "2b", name => "Nesztamoj2b" },
  { id => "3",  name => "Nesztamoj3" }
);

my $has_error = 0;

print "--------------------------------------------------\n";
print " GID Over-limit Pre-check (Max Allowed: $MAX_GLYPHS)\n";
print "--------------------------------------------------\n";

foreach my $mode (@modes) {
  my $arg  = $mode->{id};
  my $name = $mode->{name};

  my %glyphlist = ();
  my %ivslist   = ();

  # 1. codepoint.txt のパース
  open my $fh, "<:utf8", $codepoint_file or die "Cannot open $codepoint_file: $!";
  while (my $line = <$fh>) {
    $line =~ s/[\r\n]+$//; # 改行コード（CRLF / LF）を完全に除去
    next if $line eq "";   # 空行スキップ

    if ($arg eq "2a") {
      $glyphlist{$line} = $line if $line =~ /^u00[0-9a-f]{2}$/i;
      $glyphlist{$line} = $line if $line =~ /^u2[0-7]{1}[0-9a-f]{3}$/i;
      $ivslist{$line}   = $line if $line =~ /^u2[0-7]{1}[0-9a-f]{3}-uf8[0-9a-f]{2}$/i;
      $ivslist{$line}   = $line if $line =~ /^u2[0-7]{1}[0-9a-f]{3}-ue01[0-9a-f]{2}$/i;
    } elsif ($arg eq "2b") {
      $glyphlist{$line} = $line if $line =~ /^u00[0-9a-f]{2}$/i;
      $glyphlist{$line} = $line if $line =~ /^u2[8-9a-f]{1}[0-9a-f]{3}$/i;
      $ivslist{$line}   = $line if $line =~ /^u2[8-9a-f]{1}[0-9a-f]{3}-uf8[0-9a-f]{2}$/i;
      $ivslist{$line}   = $line if $line =~ /^u2[8-9a-f]{1}[0-9a-f]{3}-ue01[0-9a-f]{2}$/i;
    } elsif ($arg eq "3") {
      $glyphlist{$line} = $line if $line =~ /^u00[0-9a-f]{2}$/i;
      $glyphlist{$line} = $line if $line =~ /^u3[0-9a-f]{4}$/i;
      $ivslist{$line}   = $line if $line =~ /^u3[0-9a-f]{4}-uf8[0-9a-f]{2}$/i;
      $ivslist{$line}   = $line if $line =~ /^u3[0-9a-f]{4}-ue01[0-9a-f]{2}$/i;
    } else {
      # 標準モード: BMP(4桁 hex) および Plane 1 (10000-1FFFF)
      $glyphlist{$line} = $line if $line =~ /^u[0-9a-f]{4}$/i;
      $glyphlist{$line} = $line if $line =~ /^u1[0-9a-f]{4}$/i;
      $ivslist{$line}   = $line if $line =~ /^u[0-9a-f]{4}-uf8[0-9a-f]{2}$/i;
      $ivslist{$line}   = $line if $line =~ /^u[0-9a-f]{4}-ue01[0-9a-f]{2}$/i;
    }
  }
  close $fh;

  $glyphlist{"u4e00"} = "u4e00" if ($arg eq "2a" || $arg eq "2b" || $arg eq "3");

  # カウント初期化（.notdef 分で +1）
  my $current_gid = 1;
  my $exceeded_flag = 0;
  my $overflow_file = "";

  # A. 基底文字のカウント
  my @base_keys = sort keys %glyphlist;
  my $base_count = scalar(@base_keys);

  foreach my $gname (@base_keys) {
    $current_gid++;
    if ($current_gid > $MAX_GLYPHS && !$exceeded_flag) {
      $exceeded_flag = 1;
      my $dir = "$GLYPH_DIR/" . substr($gname, 0, length($gname)-3) . "/" . substr($gname, 0, length($gname)-2);
      $overflow_file = "$dir/$gname.svg (Base CodePoint: $gname)";
    }
  }

  # B. IVS (PUA) のカウント
  my $pua_count = 0;
  if (scalar(keys(%ivslist)) > 0) {
    my %base_to_ivs = ();
    foreach my $ucswithivs (keys %ivslist) {
      my @temp = split(/-/, $ucswithivs);
      push @{$base_to_ivs{$temp[0]}}, $ucswithivs;
    }

    foreach my $ucswithoutivs (sort keys %base_to_ivs) {
      my %seen_svgs = ();
      my $base_dir = "$GLYPH_DIR/" . substr($ucswithoutivs, 0, length($ucswithoutivs)-3) . "/" . substr($ucswithoutivs, 0, length($ucswithoutivs)-2);
      my $base_svg = "$base_dir/$ucswithoutivs.svg";

      foreach my $ucswithivs (sort @{$base_to_ivs{$ucswithoutivs}}) {
        my @temp = split(/-/, $ucswithivs);
        my $base_part = $temp[0];
        my $dir = "$GLYPH_DIR/" . substr($base_part, 0, length($base_part)-3) . "/" . substr($base_part, 0, length($base_part)-2);
        my $target_svg = "$dir/$ucswithivs.svg";

        # 基底文字のSVGと同一なら差分なし（PUA追加不要）
        next if (-e $target_svg && -e $base_svg && !`diff "$target_svg" "$base_svg" 2>/dev/null`);

        my $matched = 0;
        foreach my $prev_svg (keys %seen_svgs) {
          if (-e $target_svg && !`diff "$target_svg" "$prev_svg" 2>/dev/null`) {
            $matched = 1;
            last;
          }
        }

        unless ($matched) {
          $seen_svgs{$target_svg} = 1;
          $pua_count++;
          $current_gid++;

          if ($current_gid > $MAX_GLYPHS && !$exceeded_flag) {
            $exceeded_flag = 1;
            $overflow_file = "$target_svg (IVS Sequence: $ucswithivs)";
          }
        }
      }
    }
  }

  # 結果の出力
  if ($exceeded_flag) {
    my $over = $current_gid - $MAX_GLYPHS;
    printf("[ERROR] %-12s : Total GID = %6d (OVER BY %d!)\n", $name, $current_gid, $over);
    print  "        └─ Exceeded limit at: $overflow_file\n";
    $has_error = 1;
  } else {
    printf("[OK]    %-12s : Total GID = %6d (Base: %d, PUA: %d)\n", $name, $current_gid, $base_count, $pua_count);
  }
}

print "--------------------------------------------------\n";

if ($has_error) {
  exit 1;
} else {
  exit 0;
}