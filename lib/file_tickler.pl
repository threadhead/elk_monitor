#!/usr/bin/perl

my ($tickle_file);
my ($tickle_interval_seconds);
my ($last_tickle);

sub file_tickler_init {
	$tickle_file = shift;
	$tickle_interval_seconds = shift;
	$last_tickle = 0;
	&tickle_me;
}


sub tickle_me {
	if ((time - $last_tickle) > $tickle_interval_seconds) {
		my $return = `touch $tickle_file`;
		$last_tickle = time;
	}
	
}


sub delete_tickle_file {
	if (-e $tickle_file) {
		unlink $tickle_file;
	}	
}


sub file_tickler_close {
	&delete_tickle_file;
}

1;