package Wardrobe::Controller::Clothes;
use Moose;
use namespace::autoclean;

BEGIN {extends 'Catalyst::Controller'; }

=head1 NAME

Wardrobe::Controller::Clothes - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut


=head2 index

=cut

sub clo_root :Chained('/root') :PathPart('clothes') :CaptureArgs(0) {
	my ($self, $c) = @_;
	
	my $breadcrumbs = $c->stash->{'breadcrumb'};
	$breadcrumbs->push('clothes', 'clothes');
}

sub index :Chained('clo_root') :PathPart('') :Args(0) {
    my ( $self, $c ) = @_;

	my %clothes_by_cat = ();
	my %categories = ();
	my @clothes = ();
	my $search_qry = '';

	$c->log->debug("method = $c->req->method");
	if (lc $c->req->method eq 'post') {
		$search_qry = $c->req->params->{"name_filter"};
		$c->log->debug("search query: $search_qry.");
		@clothes = $c->model('Bindings::Clothing')->get_clothes_by_name($search_qry);
	} else {
		@clothes = $c->model('Bindings::Clothing')->get_all_clothes();
	}
	
	$c->log->debug("There are " . scalar @clothes . " clothing items: " . join(@clothes,', '));

	# Possibly replaceable with DBIx::Class grouping function?
	my $result_count = 0;

	foreach my $item (@clothes) {
		if (exists $clothes_by_cat{$item->category_id}) {
			push(@{ $clothes_by_cat{$item->category_id} }, $item);
		} else {
			$clothes_by_cat{$item->category_id} = [ $item ];
			$categories{$item->category_id} = $item->category->name;
		}
		$result_count++;
	}

	use Data::Dump qw(pp);
	pp (\%clothes_by_cat);

	$c->stash(
		template    => 'clothes/list.tt',
		clothes     => \%clothes_by_cat,
		categories  => \%categories,
		rs_count    => $result_count,
		name_filter => $search_qry
	);
}

sub clothing :Chained('clo_root') :PathPart('clothing') :Args(2) {
	my ($self, $c, $clothing_id, $clothing_name) = @_;

	my $item = $c->model('Clothing')->get_clothing_by_id($clothing_id);

	my $breadcrumbs = $c->stash->{'breadcrumb'};
	$breadcrumbs->push('clothing', "clothing/$clothing_id/$clothing_name");

	$c->stash(
		'template' => 'clothes/clothing.tt',
		'item'     => $item
	);

}

=head1 AUTHOR

PTaylor,,,

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
