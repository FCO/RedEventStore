use Red:api<2> <refreshable>;

unit model RedEventStore::Storage::EventClass is table<type>;

has Str $.type   is id;
has Str $.parent is id;
