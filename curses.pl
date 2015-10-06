#!/usr/bin/env perl
use v5.22;
use feature qw(signatures say);
no warnings qw(experimental::signatures);

open my $pipe, '-|', 'du -a';

my $files = Local::files->new;

while( <$pipe> ) {
	chomp;
	my( $size, $file ) = split /\s+/, $_, 2;
	next if -d $file;
	next if $file eq ".";
	$files->add( $size, "$file" );
	}

sleep(10);

package Local::files {
	use Curses;
	use vars qw($win);

	use constant MAX  =>   24;
	use constant SIZE =>    0;
	use constant NAME =>    1;
	use constant KB   => 1024;

	sub new ($class, @args) {
		my $self = bless [], $class;
		$self->init;
		return $self;
		}
	
	sub init ($self) {	
		initscr;
		curs_set(0); # hide cursor
		$win = Curses->new;
	
		for( my $i = MAX; $i >= 0; $i-- ) {
			$self->size_at( $i, undef );
			$self->name_at( $i, '' );
			}
		}
	
	sub DESTROY { endwin; }
	
	sub add ($self, $size, $name) {	
		# add new entries at the end and sort after
		if( $size > $self->size_at( MAX ) ) {
			$self->replace_last( $size, $name );
			$self->sort;
			}

		$self->draw;
		}
			
	sub sort ($self) {
		no warnings;
	
		$self->elements( 
			sort { $b->[SIZE] <=> $a->[SIZE] } $self->elements 
			);
		}

	sub elements ($self, @args) {	
		if( @args ) { @$self = @args }
		@$self;
		}
	
	sub size_at ($self, $index=-1, $size=undef) {
		$self->[$index][SIZE] = $size if $size;
		$self->[$index][SIZE];
		}

	sub name_at ($self, $index=-1, $name=undef) {	
		$self->[$index][NAME] = $name if $name;
		$self->[$index][NAME];
		}
	
	sub replace_last ($self, $size, $name) {
		$self->size_at( -1, $size );
		$self->name_at( -1, $name );			
		}
	
	sub draw ($self) {
		for( my $i = 0; $i < MAX; $i++ ) {
			next if $self->size_at( $i ) == 0 or $self->name_at( $i ) eq '';
			$win->addstr( $i,  1, " " x $Curses::COLS );
			$win->addstr( $i,  1, sprintf( "%8d", $self->[$i][SIZE] || '' )  );
			$win->addstr( $i, 10, $self->name_at( $i ) );
			$win->refresh;
			}
		}
}
