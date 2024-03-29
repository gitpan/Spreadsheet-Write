package Spreadsheet::Write::CSV;

our $VERSION = '0.101_01';

use 5.008;
use base qw'Spreadsheet::Write';
use common::sense;

use Encode;
use Text::CSV;

sub new
{
	my ($class, %args) = @_;
	my $self = bless {}, $class;
	
	my $filename = $args{'file'} || $args{'filename'} || die "Need filename.";
	$self->{'_FILENAME'}    = $filename;

	$args{'csv_options'}->{'eol'}       ||= "\r\n";
	$args{'csv_options'}->{'sep_char'}  ||= ",";	
	$self->{'_CSV_OPTIONS'} = $args{'csv_options'};
	
	return $self;
}

sub _prepare
{
	my $self = shift;
	$self->{'_CSV_OBJ'}||=Text::CSV->new($self->{'_CSV_OPTIONS'});
	return $self;
}

sub close
{
	my $self=shift;
	return if $self->{'_CLOSED'};
	$self->{'_FH'}->close if $self->{'_FH'};
	$self->{'_CLOSED'}=1;
	return $self;
}

sub _add_prepared_row
{
	my $self = shift;
	
	my @texts;
	foreach (@_)
	{
		my $content = $_->{'content'};
		
		$content = sprintf($content, $_->{'sprintf'})
			if $_->{'sprintf'};
		
		# Hide non-ASCII characters from Unicode-unaware Text::CSV.
		$content =~ s/([^\x20-\x7e]|[\r\&\n\t])/sprintf('&#%d;', ord($1))/esg;
		
		push @texts, $content;
	}

	my $string;
	$self->{'_CSV_OBJ'}->combine(@texts) ||
	die "csv_combine failed at ".$self->{'_CSV_OBJ'}->error_input();
	$string = $self->{'_CSV_OBJ'}->string();
	
	# Restore non-ASCII characters.
	$string =~ s/&#(\d+);/chr($1)/esg;
	$string = Encode::decode('utf8',$string) unless Encode::is_utf8($string);
	$string = Encode::encode($self->{'_ENCODING'} || 'utf8',$string);
	
	# Output to file.
	$self->{'_FH'}->print($string);

	return $self;
}

1;