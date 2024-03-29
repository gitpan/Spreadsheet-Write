package Spreadsheet::Write::OpenDocumentXML;

our $VERSION = '0.101_01';

use 5.008;
use base qw'Spreadsheet::Write';
use constant {
	OFFICE_NS => "urn:oasis:names:tc:opendocument:xmlns:office:1.0",
	STYLE_NS  => "urn:oasis:names:tc:opendocument:xmlns:style:1.0",
	TEXT_NS   => "urn:oasis:names:tc:opendocument:xmlns:text:1.0",
	TABLE_NS  => "urn:oasis:names:tc:opendocument:xmlns:table:1.0",
	META_NS   => "urn:oasis:names:tc:opendocument:xmlns:meta:1.0",
	NUMBER_NS => "urn:oasis:names:tc:opendocument:xmlns:datastyle:1.0",
	};
use common::sense;

use XML::LibXML;

sub new
{
	my ($class, %args) = @_;
	
	my $self = bless { 'options' => \%args }, $class;
	
	my $filename = $args{'file'} || $args{'filename'} || die "Need filename.";
	$self->{'_FILENAME'}    = $filename;

	return $self;
}

sub _prepare
{
	my $self = shift;
	
	return $self if $self->{'document'};
	
	my $namespaces = {
		office  => OFFICE_NS,
		style   => STYLE_NS,
		text    => TEXT_NS,
		table   => TABLE_NS,
		meta    => META_NS,
		number  => NUMBER_NS,
		};
	
	$self->{'document'} = XML::LibXML->createDocument;
	$self->{'document'}->setDocumentElement(
		$self->{'document'}->createElement('root')
		);
	while (my ($prefix, $nsuri) = each %$namespaces)
	{
		$self->{'document'}->documentElement->setNamespace($nsuri, $prefix, $prefix eq 'office' ? 1 : 0);
	}
	$self->{'document'}->documentElement->setNodeName('office:document-content');
	$self->{'document'}->documentElement->setAttribute(OFFICE_NS, 'version', '1.0');
	$self->{'body'} = $self->{'document'}->documentElement
		->addNewChild(OFFICE_NS, 'body')
		->addNewChild(OFFICE_NS, 'spreadsheet');
	$self->addsheet($self->{'options'}->{'sheet'} || 'Sheet 1');
	
	return $self;
}

sub addsheet
{
	my ($self, $caption) = @_;

	$self->{'tbody'} = $self->{'body'}->addNewChild(TABLE_NS, 'table');

	if (defined $caption)
	{
		$self->{'tbody'}->setAttributeNS(TABLE_NS, 'name', $caption);
	}
	
	return $self;
}

sub _add_prepared_row
{
	my $self = shift;

	my $tr = $self->{'tbody'}->addNewChild(TABLE_NS, 'table-row');
	
	foreach my $cell (@_)
	{
		my $tcell = $tr->addNewChild(TABLE_NS, 'table-cell');
		$tcell->setAttributeNS(OFFICE_NS, 'value-type', 'string');
		
		my $td = $tcell->addNewChild(TEXT_NS, 'p');
		
		my $content = $cell->{'content'};
		$content = sprintf($cell->{'sprintf'}, $content)
			if defined $cell->{'sprintf'};
		
		$td->appendText($content);
		
		if ($cell->{'font_weight'} eq 'bold'
		&&  $cell->{'font_style'} eq 'italic')
		{
			$td->setAttributeNS(TEXT_NS, 'style-name', 'BoldItalic');
		}
		elsif ($cell->{'font_weight'} eq 'bold')
		{
			$td->setAttributeNS(TEXT_NS, 'style-name', 'Bold');
		}
		elsif ($cell->{'font_style'} eq 'italic')
		{
			$td->setAttributeNS(TEXT_NS, 'style-name', 'Italic');
		}
	}
}

sub close
{
	my $self=shift;
	return if $self->{'_CLOSED'};
	$self->{'_FH'}->print( $self->_make_output );
	$self->{'_FH'}->close;
	$self->{'_CLOSED'}=1;
	return $self;
}

sub _make_output
{
	my $self = shift;
	return $self->{'document'}->toString;
}

1;