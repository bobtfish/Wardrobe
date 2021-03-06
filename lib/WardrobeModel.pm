
package WardrobeModel;
use Moose;
use MooseX::Types::Moose qw/ HashRef Object /;
use MooseX::Types::LoadableClass qw/ LoadableClass /;
use Text::CSV::Encoded;
use Log::Log4perl qw(get_logger);
my $log = Log::Log4perl->get_logger();

has connect_info => (
    isa => HashRef,
    is => 'ro',
    required => 1,
);

has schema_class => (
    isa => LoadableClass,
    is => 'ro',
    default => ' WardrobeModel::WardrobeORM',
);

has schema => (
    isa => Object,
    is => 'ro',
    lazy => 1,
    default => sub {
        my $self = shift;
        $self->schema_class->connect($self->connect_info)
    },
    handles => [qw/ resultset /],
);


sub get_clothes_by_category {
	my ($self, $category_id) = @_;

	my $clothing_rs = $self->resultset('Clothing');
	return $clothing_rs->search_by_category($category_id);
}

sub get_all_clothes {
	my $self = shift;

	my $clothing_rs = $self->resultset('Clothing');
	return $clothing_rs->all();
}

sub get_clothes_by_name {
	my ($self, $search_qry) = @_;

	my $clothing_rs = $self->resultset('Clothing');
	return $clothing_rs->search_by_name_query($search_qry);
}

sub get_clothing_by_id {
	my ($self, $clothing_id) = @_;

	my $clothing_rs = $self->resultset('Clothing');
	return $clothing_rs->find_by_id($clothing_id);

}

# create_from_csv_file (str filename, bool header_record);
sub create_from_csv_file {
	my ($self, $csv_filename, $header_record) = @_;

	my $parser = Text::CSV::Encoded->new({
		encoding_in      => "utf8",
		encoding_out     => "utf8",
		escape_char      => '"',
		sep_char         => ',',
		allow_whitespace => 1
	});

	open my $fh, "<", $csv_filename;

	my $line_no   = 0;
	my $bad       = 0;
	my $dupes     = 0;

	while (my $raw_line = $parser->getline($fh)) {
		my $line = $parser->string($raw_line);
		chomp($line);

		if (!$parser->parse($line)) {
			$bad++;
			$log->debug("LINE: $line - BAD");
		} else {

			if ($line_no == 0 && $header_record) {
				$line_no++;
				$log->debug("LINE: $line - HEADER RECORD");
				next;
			} else {
				my @cols = $parser->fields($line);

				if (@cols < 2) {
					$bad++;
					$line_no++;
					$log->debug("LINE: $line - MISSING FIELDS");
					next;
				}

				(my $clothing_name, my $category_name) = @cols;

				if ($clothing_name eq '' || $category_name eq '') {
					$bad++;
					$line_no++;
					$log->debug("LINE: $line - EMPTY STRING FIELD");
					next;
				}

				my $is_new = $self->create_clothing_and_category($clothing_name, $category_name);

				if ($is_new) {
					$log->debug("LINE: $line - ADDED");
				} else {
					$log->debug("LINE: $line - DUPE");
					$dupes++;
				}

			}
		}

		$line_no++;
	}

	close $fh;

	# ensure record count is accurate.
	$line_no-- unless !$header_record;

	return ($line_no, $bad, $dupes);
}

sub create_clothing_and_category {
	my ($self, $clothing_name, $category_name) = @_;
	
	my $clothing_rs = $self->resultset('Clothing');
	return $clothing_rs->create_with_category($clothing_name, $category_name);

}

sub get_all_outfits {
	my $self = shift;

	my $outfit_rs = $self->resultset("Outfit");
	return $outfit_rs->all();

}

sub get_outfit_by_id {
	my ($self, $outfit_id) = @_;

	my $outfit_rs = $self->resultset("Outfit");
	return $outfit_rs->find_by_id($outfit_id);

}

# create_outfit( clothing_name );
sub find_or_create_outfit {
	my ($self, $outfit_name, $clothing_id) = @_;

	my $outfit_rs = $self->resultset("Outfit");
	return $outfit_rs->find_or_create_by_name($outfit_name);

}

sub tag_clothing_to_outfit {
	my ($self, $outfit_id, $clothing_id) = @_;

	# add the clothes to the outfit.
	my $tagged_clothing = $self->resultset('TaggedClothing')->find_or_create({
		clothing_id => $clothing_id,
		outfit_id   => $outfit_id
	});

	return $tagged_clothing;
}

1;
