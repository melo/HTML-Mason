use strict;
use warnings;
use Test::More tests => 1;
use Log::Any::Test;
use Log::Any qw($log);
use Test::Deep;
use File::Temp qw(tempdir);
use File::Path;
use HTML::Mason::Interp;

sub write_file {
  my ($file, $content) = @_;
  open(my $fh, ">$file");
  $fh->print($content);
}

my $comp_root = tempdir('mason-log-t-XXXX', TMPDIR => 1, CLEANUP => 1);
mkpath("$comp_root/bar", 0, 0775);

my $interp = HTML::Mason::Interp->new(comp_root => $comp_root);
write_file("$comp_root/foo",     "% \$m->log->debug('in foo');\n<& /bar/baz &>");
write_file("$comp_root/bar/baz", "% \$m->log->error('in bar/baz')");
$interp->exec('/foo');

cmp_deeply(
  $log->msgs,
  [ { category => "HTML::Mason::Request",
      level    => "debug",
      message  => "top path is '/foo'"
    },
    { category => "HTML::Mason::Interp",
      level    => "debug",
      message  => "resolve comp_path '/foo' to a source"
    },
    { category => "HTML::Mason::Interp",
      level    => "trace",
      message  => re(qr{\Qcheck comp_path '/foo' in root}),
    },
    { category => "HTML::Mason::Resolver::File",
      level    => "trace",
      message  => re(qr{\Qfound comp_path '/foo' on '}),
    },
    { category => "HTML::Mason::Interp",
      level    => "debug",
      message  => "Found source for comp_path '/foo'"
    },
    { category => "HTML::Mason::Interp",
      level    => "debug",
      message  => "loading component '/foo', comp_id '/foo'"
    },
    { category => "HTML::Mason::Interp",
      level    => "debug",
      message  => re(qr{Got comp HTML::Mason::Component::FileBased=HASH\(.+?\) for comp_path '/foo'}),
    },
    { category => "HTML::Mason::Request",
      level    => "debug",
      message  => "starting request for '/foo'"
    },
    { category => "HTML::Mason::Interp",
      level    => "debug",
      message  => "resolve comp_path '/autohandler' to a source"
    },
    { category => "HTML::Mason::Interp",
      level    => "trace",
      message  => re(qr{\Qcheck comp_path '/autohandler' in root}),
    },
    { category => "HTML::Mason::Interp",
      level    => "debug",
      message  => "No source found for comp '/autohandler'"
    },
    { category => "HTML::Mason::Interp",
      level    => "debug",
      message  => "Failed to load comp '/autohandler', no source found"
    },
    { category => "HTML::Mason::Request",
      level    => "debug",
      message  => "entering component '/foo' [depth 0]"
    },
    { category => "HTML::Mason::Component::foo",
      level    => "debug",
      message  => "in foo"
    },
    { category => "HTML::Mason::Interp",
      level    => "debug",
      message  => "resolve comp_path '/bar/baz' to a source"
    },
    { category => "HTML::Mason::Interp",
      level    => "trace",
      message  => re(qr{\Qcheck comp_path '/bar/baz' in root}),
    },
    { category => "HTML::Mason::Resolver::File",
      level    => "trace",
      message  => re(qr{\Qfound comp_path '/bar/baz' on}),
    },
    { category => "HTML::Mason::Interp",
      level    => "debug",
      message  => "Found source for comp_path '/bar/baz'"
    },
    { category => "HTML::Mason::Interp",
      level    => "debug",
      message  => "loading component '/bar/baz', comp_id '/bar/baz'"
    },
    { category => "HTML::Mason::Interp",
      level    => "debug",
      message  => re(qr{Got comp HTML::Mason::Component::FileBased=HASH\(.+?\) for comp_path '/bar/baz'}),
    },
    { category => "HTML::Mason::Request",
      level    => "debug",
      message  => "entering component '/bar/baz' [depth 1]"
    },
    { category => "HTML::Mason::Component::bar::baz",
      level    => "error",
      message  => "in bar/baz"
    },
    { category => "HTML::Mason::Request",
      level    => "debug",
      message  => "exiting component '/bar/baz' [depth 1]"
    },
    { category => "HTML::Mason::Request",
      level    => "debug",
      message  => "exiting component '/foo' [depth 0]"
    },
    { category => "HTML::Mason::Request",
      level    => "debug",
      message  => "finishing request for '/foo'"
    }
  ]
);
