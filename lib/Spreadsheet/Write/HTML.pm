package Spreadsheet::Write::HTML;

our $VERSION = '0.101_01';

use 5.008;
use base qw'Spreadsheet::Write::XHTML';
use common::sense;

use HTML::HTML5::Writer;

sub _make_output
{
	my $self   = shift;
	my $writer = HTML::HTML5::Writer->new;
	return $writer->document($self->{'document'});
}

1;