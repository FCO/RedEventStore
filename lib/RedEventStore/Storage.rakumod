use Red:api<2> <refreshable>;
use Red::Driver;
use RedEventStore::Storage::Event;
use RedEventStore::Storage::EventField;
use RedEventStore::Storage::EventClass;

unit class RedEventStore::Storage;

has Str         $.driver = "SQLite";
has             %.pars;
has Red::Driver $.db = database $!driver, |%!pars;

method TWEAK(|) {
	my $*RED-DB = $!db;
	schema(
		RedEventStore::Storage::Event,
		RedEventStore::Storage::EventField,
		RedEventStore::Storage::EventClass,
	).create;
}

method add-event(:@types, :%data) {
	my $type = @types.head;
	#say "add-event: ", $event;
	my $*RED-DB = $!db;

	red-do :transaction, {
		my $entry = RedEventStore::Storage::Event.^create: :$type, :%data;

		unless RedEventStore::Storage::EventClass.^all.first: { .type eq $type } {
			for @types -> $parent {
			RedEventStore::Storage::EventClass.^create: :$type, :$parent
			}
		}

		for %data.kv -> Str $field, $value {
			next if $value ~~ Positional|Associative;
			RedEventStore::Storage::EventField.^create: :event-id($entry.id), :$field, :$value
		}

		$entry.^refresh.id
	}
}

method get-events(Int $index = 0, :@types, Instant :$from-timestamp, Instant :$to-timestamp, *%pars) {
	my $*RED-DB = $!db;

	my $events = do if %pars {
		my $fields = RedEventStore::Storage::EventField.^all;
		for %pars.kv -> $key, $value {
			FIRST {
				$fields .= grep: {
					.field eq $key
					&& .value eqv $value
				}
				next
			}
			$fields .= join-model:
				:name("field_$key"),
				RedEventStore::Storage::EventField, -> $prev, $field {
					$prev.event-id == $field.event-id
					&& $field.field eq $key
					&& $field.value eqv $value
				}
		}
		$fields.map: { .event }
	} else {
		RedEventStore::Storage::Event.^all
	}

	$events .= grep(*.id > $index);


	if @types {
		$events .= grep: { .type in RedEventStore::Storage::EventClass.^all.grep({ .parent in @types }).map: *.type };
	}

	with $from-timestamp -> $from {
		$events .= grep: { .timestamp > $from }
	}

	with $to-timestamp -> $to {
		$events .= grep: { .timestamp <= $to }
	}

	my @events = $events.sort(*.id).Seq;

	@events.map: { .to-event }
}
