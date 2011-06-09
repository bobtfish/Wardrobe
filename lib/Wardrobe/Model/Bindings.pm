package Wardrobe::Model::Bindings;
use Moose;
extends 'Catalyst::Model::Adaptor';

__PACKAGE__->config (
    class => 'WardrobeModel',
);
