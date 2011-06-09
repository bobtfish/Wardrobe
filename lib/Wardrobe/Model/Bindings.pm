package Wardrobe::Model::Bindings;
use Moose;
extends 'Catalyst::Model::DBIC::Schema';

__PACKAGE__->config (
    schema_class => 'WardrobeModel::WardrobeORM',
);
