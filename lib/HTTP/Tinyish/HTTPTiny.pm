package HTTP::Tinyish::HTTPTiny;
use strict;
use parent qw(HTTP::Tinyish::Base);
use HTTP::Tiny;

my %supports = (http => 1);

sub configure {
    my %meta = ("HTTP::Tiny" => $HTTP::Tiny::VERSION);

    if (eval { HTTP::Tiny::Handle->_assert_ssl; 1 }) {
        $supports{https} = 1;
    }

    \%meta;
}

sub supports { $supports{$_[1]} }

sub new {
    my($class, %attrs) = @_;
    bless {
        tiny => HTTP::Tiny->new(%attrs),
    }, $class;
}

sub request {
    my $self = shift;
    $self->{tiny}->request(@_);
}

sub mirror {
    my $self = shift;
    $self->{tiny}->mirror(@_);
}

1;

