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
  { id => "",  name => "Nesztamoj" },
  { id => "2", name => "Nesztamoj2" },
  { id => "3", name => "Nesztamoj3" }
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
  while (<$fh>) {
    if ($arg eq "2") {
      $glyphlist{$1} = $1 if /^u00[0-9a-f]{2}$/i;
      $glyphlist{$1} = $1 if /^u2[0-9a-f]{4}$/i;
      $ivslist{$1}   = $1 if /^u2[0-9a-f]{4}-uf8[0-9a-f]{2}$/i;
      $ivslist{$1}   = $1 if /^u2[0-9a-f]{4}-ue01[0-9a-f]{2}$/i;
    } elsif ($arg eq "3") {
      $glyphlist{$1} = $1 if /^u00[0-9a-f]{2}$/i;
      $glyphlist{$1} = $1 if /^u3[0-9a-f]{4}$/i;
      $ivslist{$1}   = $1 if /^u3[0-9a-f]{4}-uf8[0-9a-f]{2}$/i;
      $ivslist{$1}   = $1 if /^u3[0-9a-f]{4}-ue01[0-9a-f]{2}$/i;
    } else {
      $glyphlist{$1} = $1 if /^u[0-9a-f]{4}$/i;
      $glyphlist{$1} = $1 if /^u1[0-9a-f]{4}$/i;
      $ivslist{$1}   = $1 if /^u[0-9a-f]{4}-uf8[0-9a-f]{2}$/i;
      $ivslist{$1}   = $1 if /^u[0-9a-f]{4}-ue01[0-9a-f]{2}$/i;
    }
  }
  close $fh;

  $glyphlist{"u4e00"} = "u4e00" if ($arg eq "2" || $arg eq "3");

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
        my $target_name = $ivslist{$ucswithivs};
        my $dir = "$GLYPH_DIR/" . substr($target_name, 0, length($target_name)-10) . "/" . substr($target_name, 0, length($target_name)-9);
        my $target_svg = "$dir/$ucswithivs.svg";

        next if (-e $target_svg && -e $base_svg && !`diff $target_svg $base_svg`);

        my $matched = 0;
        foreach my $prev_svg (keys %seen_svgs) {
          if (-e $target_svg && !`diff $target_svg $prev_svg`) {
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