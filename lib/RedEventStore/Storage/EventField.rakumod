use Red:api<2> <refreshable>;

unit model RedEventStore::Storage::EventField is table<field>;

has UInt $.event-id is column{ :id, :references{ .id }, :model-name<RedEventStore::Storage::Event> };
has Str  $.field    is required is id;
has      $.value    is column{ :id, :nullable };
has      $.event    is relationship( *.event-id, :model<RedEventStore::Storage::Event> );
