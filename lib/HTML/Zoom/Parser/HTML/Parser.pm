package HTML::Zoom::Parser::HTML::Parser;

use strictures 1;
use base qw(HTML::Zoom::SubObject);

use HTML::TokeParser;
use HTML::Entities;

sub html_to_events {
    my ($self, $text) = @_;
    my @events;
    _toke_parser($text => sub {
        #p @_;
        push @events, $_[0];
    });
    return \@events;
}

sub html_to_stream {
    my ($self, $text) = @_;
    return $self->_zconfig->stream_utils
                ->stream_from_array(@{$self->html_to_events($text)});
}

sub _toke_parser {
    my ($text, $handler) = @_;

    # die?? warn??
    my $parser = HTML::TokeParser->new(\$text) or return $!;
    # HTML::Parser downcases by default

    while (my $token = $parser->get_token) {
        my $type = shift @$token;

        # we essentially break down what we emit to stream handler by type
        # start tag
        if ($type eq 'S') {
            my ($tag, $attr, $attrseq, $text) = @$token;
            my $in_place = delete $attr->{'/'}; # val will be '/' if in place
            $attrseq = [ grep { $_ ne '/' } @$attrseq ] if $in_place;
            if (substr($tag, -1) eq '/') {
                $in_place = '/';
                chop $tag;
            }

            $handler->({
              type => 'OPEN',
              name => $tag,
              # is_in_place_close => $in_place_close, TODO : WHAT TO DO ABOUT THIS?
              attrs => $attr,
              is_in_place_close => $in_place,
              attr_names => $attrseq,
              # raw_attrs => $attributes || '', TODO : WHAT TO DO ABOUT THIS?
              raw => $text,
            });

            # if attr '/' exists, assume an inplace close, and emit a CLOSE as well
            if ($in_place) {
                $handler->({
                    type => 'CLOSE',
                    name => $tag,
                    raw => '', # don't emit $text for raw, match builtin behavior
                    is_in_place_close => 1,
                });
            }
        }

        # end tag
        if ($type eq 'E') {
            my ($tag, $text) = @$token;
            $handler->({
                type => 'CLOSE',
                name => $tag,
                raw => $text,
                # is_in_place_close => 1  for br/> ??
            });
        }

        # text
        if ($type eq 'T') {
            my ($text, $is_data) = @$token;
            $handler->({
                type => 'TEXT',
                raw => $text
            });
        }

        # comment
        if ($type eq 'C') {
            my ($text) = @$token;
            $handler->({
                type => 'SPECIAL',
                raw => $text
            });
        }

        # declaration
        if ($type eq 'D') {
            my ($text) = @$token;
            $handler->({
                type => 'SPECIAL',
                raw => $text
            });
        }

        # process instructions
        if ($type eq 'PI') {
            my ($token0, $text) = @$token;
        }
    }
}

sub html_escape { encode_entities($_[1]) }

sub html_unescape { decode_entities($_[1]) }

1;
