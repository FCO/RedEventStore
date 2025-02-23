use Red:api<2> <refreshable>;
use Red::Type::Json;

unit model RedEventStore::Storage::Event is table<event>;

has UInt      $.id        is serial;
has Instant() $.timestamp is column = now;
has Str       $.type      is column;
has Json      $.data      is column;
has           @.fields    is relationship( *.event-id, :model<RedEventStore::Storage::EventField> );

method to-event(--> Map()) {
	:seq($!id),
	:$!type,
	:$!data,
}
