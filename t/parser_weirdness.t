use strictures 1;
use HTML::Zoom;
use Test::More;

my $html = <<EOHTML;
<body>
  <p><br/></p>
  <p><br /></p>
</body>
EOHTML

HTML::Zoom->new( { zconfig => { parser => 'HTML::Zoom::Parser::HTML::Parser' } } )->from_html($html)
          ->select('body')
          ->collect_content({
              into => \my @body
            })
          ->run;

is(HTML::Zoom->new( { zconfig => { parser => 'HTML::Zoom::Parser::HTML::Parser' } } )->from_events(\@body)->to_html, <<EOHTML,

  <p><br/></p>
  <p><br /></p>
EOHTML
  'Parses cuddled in place close ok');

done_testing;
