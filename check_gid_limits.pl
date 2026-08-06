#!/usr/bin/perl

use utf8;

my $MAX_GLYPHS = 65528; # GID上限 (65535から安全マージンを除いた値)
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

  # 1. codepoint.txt のパース（makefont.pl の条件判定を再現）
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

  # 例外的に追加される基底文字
  $glyphlist{"u4e00"} = "u4e00" if ($arg eq "2" || $arg eq "3");[cite: 2]

  # 2. IVS 統合（diff 判定による PUA 割り当て個数の試算）
  my $pua_count = 0;
  if (scalar(keys(%ivslist)) > 0) {
    my %base_to_ivs = ();
    foreach my $ucswithivs (keys %ivslist) {
      my @temp = split(/-/, $ucswithivs);
      push @{$base_to_ivs{$temp[0]}}, $ucswithivs;
    }

    foreach my $ucswithoutivs (keys %base_to_ivs) {
      my %seen_svgs = ();
      my $base_dir = "$GLYPH_DIR/" . substr($ucswithoutivs, 0, length($ucswithoutivs)-3) . "/" . substr($ucswithoutivs, 0, length($ucswithoutivs)-2);
      my $base_svg = "$base_dir/$ucswithoutivs.svg";

      foreach my $ucswithivs (sort @{$base_to_ivs{$ucswithoutivs}}) {
        my $target_name = $ivslist{$ucswithivs};
        my $dir = "$GLYPH_DIR/" . substr($target_name, 0, length($target_name)-10) . "/" . substr($target_name, 0, length($target_name)-9);
        my $target_svg = "$dir/$ucswithivs.svg";

        # A. 基底文字の SVG と一致するか
        next if (-e $target_svg && -e $base_svg && !`diff $target_svg $base_svg`);[cite: 2]

        # B. 既出 IVS の SVG と一致するか
        my $matched = 0;
        foreach my $prev_svg (keys %seen_svgs) {
          if (-e $target_svg && !`diff $target_svg $prev_svg`) {[cite: 2]
            $matched = 1;
            last;
          }
        }

        # C. 新規字形なら PUA カウントを増やす
        unless ($matched) {
          $seen_svgs{$target_svg} = 1;
          $pua_count++;
        }
      }
    }
  }

  # 3. 概算 Total GID Calculation (.notdef = 1)
  my $base_count = scalar(keys(%glyphlist));
  my $total_gid  = $base_count + $pua_count + 1;

  if ($total_gid > $MAX_GLYPHS) {
    my $over = $total_gid - $MAX_GLYPHS;
    printf(" [ERROR] %-12s : Total GID = %6d  (OVER BY %d!)\n", $name, $total_gid, $over);
    $has_error = 1;
  } else {
    printf(" [OK]    %-12s : Total GID = %6d  (Base: %d, PUA: %d)\n", $name, $total_gid, $base_count, $pua_count);
  }
}

print "--------------------------------------------------\n";

if ($has_error) {
  exit 1; # エラー終了（呼び出し元のシェルで検知）
} else {
  exit 0; # 正常終了
}