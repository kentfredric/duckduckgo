#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;

use FindBin qw($Bin);
use lib "$Bin/lib";

use DDG::Block::Any;
use DDG::Block::Regexp;
use DDG::Block::Words;
use DDG::Request;
use DDG::ZeroClickInfo;

sub zci {
	my ( $answer, $answer_type, $is_cached, %extra_attributes ) = @_;
	DDG::ZeroClickInfo->new(
		answer => $answer,
		answer_type => $answer_type,
		is_cached => $is_cached ? 1 : 0,
		%extra_attributes,
	);
}

BEGIN {

	my $re_block = DDG::Block::Regexp->new({
		plugins => [qw(
			DDGTest::Goodie::ReBlockOne
		)],
	});

	isa_ok($re_block,'DDG::Block::Regexp');

	my $words_block = DDG::Block::Words->new({
		plugins => [qw(
			DDGTest::Goodie::WoBlockBang
			DDGTest::Goodie::WoBlockOne
			DDGTest::Goodie::WoBlockTwo
			DDGTest::Goodie::WoBlockThree
			DDGTest::Goodie::WoBlockArr
		)],
	});

	isa_ok($words_block,'DDG::Block::Words');

	my @queries = (
		'aROUNd two' => {
			wo => [zci('two','woblockone')],
			re => [],
		},
		'wikipedia blub' => {
			wo => [],
			re => [],
		},
		'bla !wikipedia blub' => {
			wo => [zci('bla blub','woblockbang')],
			re => [],
		},
		'whatever around two around whatever' => {
			wo => [zci('whatever around around whatever','woblocktwo')],
			re => [],
		},
		'        whatever around three around whatever           ' => {
			wo => [zci('whatever around three around whatever','woblockthree')],
			re => [],
		},
		'whatever !ArouND' => {
			wo => [zci('whatever','woblockone')],
			re => [],
		},
		'regexp xxxxx xxxxx' => {
			wo => [],
			re => [zci('xxxxx xxxxx','reblockone')],
		},
		'  rEGExp		xXXXx aFTEr  ' => {
			wo => [zci('  rEGExp		xXXXx','woblockone')],
			re => [zci('	xXXXx aFTEr  ','reblockone')],
		},
		'  a    or     b   or        c  ' => {
			wo => [zci('a|or|b|or|c','woblockarr')],
			re => [],
		},
	);
	
	while (@queries) {
		my $query = shift @queries;
		my $expect = shift @queries;
		my $request = DDG::Request->new({ query_raw => $query });
		my @words_result = $words_block->request($request);
		is_deeply(\@words_result,$expect->{wo} ? $expect->{wo} : [],'Testing words block result of query "'.$query.'"');
		my @re_result = $re_block->request($request);
		is_deeply(\@re_result,$expect->{re} ? $expect->{re} : [],'Testing regexp block result of query "'.$query.'"');
	}
	
}

done_testing;
