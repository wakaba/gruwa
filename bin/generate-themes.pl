use strict;
use warnings;
use Path::Tiny;
use JSON::PS;
use Web::Encoding;

my $Data = {};
my $Meta = {default_names => []};

sub css_rule ($%) {
  my ($theme, %prop) = @_;
  my $p = join ";\n", map {
    if (defined $prop{$_} and length $prop{$_}) {
      '--' . $_ . ':' . $prop{$_};
    } else {
      ();
    }
  } sort { $a cmp $b } keys %prop;
  return qq{html[data-theme="$theme"] {$p}};
} # css_rule

{
  my $dir_name = shift or die "Usage: perl $0 gruwa-themes-path";
  my $GruwaThemesPath = path ($dir_name);

  {
    my $data_path = $GruwaThemesPath->child ('src/defs.json');
    my $data = json_bytes2perl $data_path->slurp;
    for my $theme (sort { $a cmp $b } keys %{$data->{themes}}) {
      my $def = $data->{themes}->{$theme};
      $Meta->{themes}->{$theme}->{license} = $def->{info}->{license};
      $Meta->{themes}->{$theme}->{copyright} = $def->{info}->{copyright};
      $Meta->{themes}->{$theme}->{author} = $def->{info}->{author};
      $Meta->{themes}->{$theme}->{label} = $def->{info}->{label};
      $Meta->{themes}->{$theme}->{score} = $def->{score};
      $Meta->{themes}->{$theme}->{url} = $def->{info}->{url};
      push @{$Meta->{default_names}}, $theme
          if $def->{info}->{default_ok};
    }
  }
  
  my $imported_path = $GruwaThemesPath->child ('src/imported/dstyles.json');
  my $imported = json_bytes2perl $imported_path->slurp;
  for my $theme (sort { $a cmp $b } keys %{$imported->{themes}}) {
    my $def = $imported->{themes}->{$theme};
    my $license = $def->{info}->{license};
    die "Bad license |$license|" unless {
      GPL => 1,
      'GFDL 1.1+' => 1,
      'AGPL3+' => 1,
    }->{$license};
    $Data->{$license}->{label} = $license;
    $Meta->{themes}->{$theme}->{license} = $license;
    if (length ($def->{info}->{copyright} // '')) {
      $Meta->{themes}->{$theme}->{copyright} = $def->{info}->{copyright};
      push @{$Data->{$license}->{copyrights} ||= []}, $def->{info}->{copyright};
    }
    if (length ($def->{info}->{author} // '')) {
      $Meta->{themes}->{$theme}->{author} = $def->{info}->{author};
      push @{$Data->{$license}->{authors} ||= []}, $def->{info}->{author};
    }
    $Meta->{themes}->{$theme}->{url} = q<http://d.hatena.ne.jp/theme/>.$theme.q</README>;
    $Meta->{themes}->{$theme}->{label} = $def->{info}->{title} // $theme;
    $Meta->{themes}->{$theme}->{score} = 10;

    my $ss = $def->{styles};
    my %p;

    my $c_bg = sub {
      my ($key, $type) = @_;
      $p{$type.'-color'} = $ss->{$key}->{color};
      $p{$type.'-background'} = $ss->{$key}->{backgroundColor};
      unless ($ss->{$key}->{backgroundImage} eq 'none') {
        $p{$type.'-background'}
            .= ' ' . $ss->{$key}->{backgroundImage}
             . ' ' . $ss->{$key}->{backgroundPositionX}
             . ' ' . $ss->{$key}->{backgroundPositionY}
             . ' ' . $ss->{$key}->{backgroundRepeat};
        $p{$type.'-background'} =~ s{url\("https://themesource/theme/}{url("https://wakaba.github.io/gruwa-themes/images/}g;
        if (length ($ss->{$key}->{minHeight} // '')) {
          $p{$type.'-min-height'} = $ss->{$key}->{minHeight};
        }
      }
    }; # $c_bg
    my $borders = sub {
      my ($key, $type) = @_;

      my $ta = $ss->{$key}->{textAlign} // '';
      if ($ta eq 'center') {
        $p{$type.'-align'} = 'center';
      }
      
      my $bs = join ' ',
          $ss->{$key}->{borderTopStyle} // 'none',
          $ss->{$key}->{borderRightStyle} // 'none',
          $ss->{$key}->{borderBottomStyle} // 'none',
          $ss->{$key}->{borderLeftStyle} // 'none';
      return if $bs eq 'none none none none';
      $p{$type.'-border-style'} = $bs;
      $p{$type.'-border-color'} = join ' ',
          $ss->{$key}->{borderTopColor} // 'currentcolor',
          $ss->{$key}->{borderRightColor} // 'currentcolor',
          $ss->{$key}->{borderBottomColor} // 'currentcolor',
          $ss->{$key}->{borderLeftColor} // 'currentcolor';
      $p{$type.'-border-width'} = join ' ',
          $ss->{$key}->{borderTopWidth} // '0',
          $ss->{$key}->{borderRightWidth} // '0',
          $ss->{$key}->{borderBottomWidth} // '0',
          $ss->{$key}->{borderLeftWidth} // '0';
    }; # $borders
    my $padding = sub {
      my ($key, $type) = @_;
      return if ($p{$type.'-border-style'} // 'none none none none') eq 'none none none none' and
                ($p{$type.'-background'} // 'none') eq 'none';
      $p{$type.'-padding'} = join ' ',
          $ss->{$key}->{paddingTop} // '0.3em',
          $ss->{$key}->{paddingRight} // '0.3em',
          $ss->{$key}->{paddingBottom} // '0.3em',
          $ss->{$key}->{paddingLeft} // '0.3em';
    }; # $padding
    
    $p{'main-color'} = $ss->{main}->{color};
    $p{'main-background-color'} = $ss->{main}->{backgroundColor};
    if (length ($ss->{main}->{borderBottomColor} // '')) {
      $p{'main-border-color'} = $ss->{main}->{borderBottomColor};
    }
    #shadow-color

    $p{'small-color'} = $ss->{commentnote}->{color};
    $p{'small-background-color'} = $ss->{commentnote}->{backgroundColor};

    $p{'link-color'} = $ss->{link}->{color};
    $p{'link-background-color'} = $ss->{link}->{backgroundColor};

    $p{'visited-color'} = $ss->{visited}->{color};
    $p{'visited-background-color'} = $ss->{visited}->{backgroundColor};

    $p{'hover-color'} = $ss->{hover}->{color};
    $p{'hover-background-color'} = $ss->{hover}->{backgroundColor};

    $p{'dark-color'} = $ss->{'simple-header'}->{color};
    $p{'dark-background-color'} = $ss->{'simple-header'}->{backgroundColor};

    {
      my @alt;
      my $found = {};
      $found->{$ss->{main}->{backgroundColor}}++;
      for (qw(blockquote profile calendar comment)) {
        unless ($found->{$ss->{$_}->{backgroundColor}}++) {
          push @alt, $_;
        }
      }

      @alt[0] = 'main' unless @alt >= 1;
      @alt[1] = 'main' unless @alt >= 2;
      
      $p{'light-1-color'} = $ss->{$alt[0]}->{color};
      $p{'light-1-background-color'} = $ss->{$alt[0]}->{backgroundColor};
      # shadow-color
      
      $p{'light-2-color'} = $ss->{$alt[1]}->{color};
      $p{'light-2-background-color'} = $ss->{$alt[1]}->{backgroundColor};
      # shadow-color
    }

    $c_bg->('bg' => 'wall');
    $padding->('bg' => 'wall');

    $c_bg->('pageTitle' => 'pageheader');
    $borders->('pageTitle' => 'pageheader');
    $padding->('pageTitle' => 'pageheader');

    $c_bg->('header1' => 'header1');
    $borders->('header1' => 'header1');
    $padding->('header1' => 'header1');

    $c_bg->('header2' => 'header2');
    $borders->('header2' => 'header2');
    $padding->('header2' => 'header2');

    $c_bg->('header3' => 'header3');
    $borders->('header3' => 'header3');
    $padding->('header3' => 'header3');

    {
      my $skip = {'' => 1};
      $skip->{$ss->{$_}->{color}} = 1 for qw(main bg);
      for (qw(header2 header1 header3 pageTitle)) {
        unless ($skip->{$ss->{$_}->{borderLeftColor} // ''}) {
          $p{'accented-color'} = $ss->{$_}->{color};
          $p{'accented-background-color'} = $ss->{$_}->{backgroundColor};
          $p{'accented-border-color'} = $ss->{$_}->{borderLeftColor};
          last;
        }
      }
      last if defined $p{'accented-color'};
      for (qw(header2 header1 header3 pageTitle)) {
        unless ($skip->{$ss->{$_}->{color}}) {
          $p{'accented-color'} = $ss->{$_}->{color};
          $p{'accented-background-color'} = $ss->{$_}->{backgroundColor};
          $p{'accented-border-color'} = $ss->{$_}->{borderLeftColor};
          last;
        }
      }
    }
    
    push @{$Data->{$license}->{styles} ||= []}, css_rule $theme, %p;

=pod

XXX

  --error-color: red;
  --error-background-color: transparent;

  --success-color: green;
  --success-background-color: transparent;

  --disabled-color: gray;
  --disabled-background-color: transparent;

=cut

  }
}

sub usort (@) {
  my $found = {};
  return sort { $a cmp $b } grep { not $found->{$_}++ } @_;
} # usort

my $RootPath = path (__FILE__)->parent->parent;
{
  my $Out = q{
/*
gruwa-themes
~~~~~~~~~~~~

See <https://github.com/wakaba/gruwa-themes>.
*/
  };
  for my $license (sort { $a cmp $b } keys %{$Data}) {
    my $def = $Data->{$license};
    $Out .= sprintf q{
    /* ------ ------ */
    /* License: %s */
    /* Authors: %s */
    %s
    /* ------ ------*/},
        (join "\n",
            $def->{label},
            '',
            usort @{$def->{copyrights} or []}),
        (join ', ', usort @{$def->{authors} or []}),
        (join "\n", @{$def->{styles} or []});
  }
  $RootPath->child ('css/themes.css')->spew (encode_web_utf8 $Out);
}

{
  push @{$Meta->{default_names}}, qw(
    270b 270g 270or 270pk
    3minutes 3pink 90 aoikuruma artnouveau-red artnouveau-blue artnouveau-green
    bluegrad bright-green cards DEN easy flower gardenia
    haru hatena hatena2-brown hatena2-darkgray hatena2-green hatena2-lightblue
    hatena2-lightgray hatena2-pink hatena2-purple hatena2-red 
    hatena2-sepia hatena2-tea hatena2-white
    hatena_light-blue hatena_light-green hatena_light-orange
    hatena_simple2 hydrangea iris madrascheck mintblue monotone-flower
    pale precision puppy sagegreen seam-line snake spring summer_wave
    tag apollo 
    asterisk-blue asterisk-lightgray asterisk-maroon asterisk-orange
    asterisk-pink hatena_christmas coloredleaves-green
    coloredleaves-red coloredleaves-yellow delta 
    hatena_fabric-blue hatena_fabric-green hatena_fabric-red 
    hatena_flower hatena_flower-blue hatena_flower-orange
    hatena_flat-brown hatena_flat-green hatena_flat-lightblue
    hatena_flat-orange hatena_flat-pink hatena_flat-purple
    himawari inka-red inka-green inka-blue kanshin
    kitchen-classic kitchen-french loose-leaf lovely_pink
    memo memo2 memo3 pain pastelpink purple_sun query000
    query011 query101 query110 query111or hatena_rainyseason 
    rim-daidaiiro rim-fujiiro rim-mizuiro rim-sakurairo
    rim-tanpopoiro rim-wakabairo sakura sakuramochi
    savanna sepia hatena_simple-black hatena_simple-blue
    hatena_simple-red smoking_gray smoking_white soft-carrot
    soft-kiwi soft-mocha tuki vitamin wani hatena
    hatena-brown hatena-darkgray hatena-green hatena-lightblue
    hatena-lightgray hatena-lime hatena-orange
    hatena-pink hatena-purple hatena-red hatena-sepia
    hatena-tea hatena-white clover silver kaki flower-tree-bird
  );
  my $found = {};
  @{$Meta->{default_names}} = grep {
    not $found->{$_}++;
  } @{$Meta->{default_names}};
  for (@{$Meta->{default_names}}) {
    unless ($Meta->{themes}->{$_}) {
      die "Bad theme name |$_|";
    }
    $Meta->{themes}->{$_}->{score} += 50;
  }
}

{
  my $has_name = {};
  for my $theme (keys %{$Meta->{themes}}) {
    $has_name->{$Meta->{themes}->{$theme}->{label}}++;
  }
  for my $theme (keys %{$Meta->{themes}}) {
    if ($has_name->{$Meta->{themes}->{$theme}->{label}} > 1) {
      $Meta->{themes}->{$theme}->{label} .= ' ('.$theme.')';
    }
  }
  $Meta->{names} = [sort {
    $Meta->{themes}->{$b}->{score}
        <=>
    $Meta->{themes}->{$a}->{score}
        or
    $Meta->{themes}->{$a}->{label}
        cmp
    $Meta->{themes}->{$b}->{label}
  } keys %{$Meta->{themes}}];
  
  $RootPath->child ('themes.json')->spew (perl2json_bytes_for_record $Meta);
}

## License: Public Domain.
