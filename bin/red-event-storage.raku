#!/usr/bin/env raku

use Nats;
use Nats::Client;
use Nats::Subscriptions;
use RedEventStore::Storage;

my RedEventStore::Storage $storage .= new;

my $nats = Nats.new;

my $subscriptions = subscriptions {
    subscribe -> "add_event", *@types {
        my %data := message.json;
        my $id = $storage.add-event: :@types, :%data;
        message.reply-json: $id
    }
    subscribe -> "get_events" {
        my %values := message.json;
        message.reply-json: $storage.get-events: |%values;
    }
    subscribe -> "get_events", Int() $seq {
        my %values := message.json;
        message.reply-json: $storage.get-events: $seq, |%values;
    }
    subscribe -> "get_events", Int() $seq, *@types {
        my %values := message.json;
        message.reply-json: $storage.get-events: $seq, :@types, |%values;
    }
}

my $client = Nats::Client.new: :$nats, :$subscriptions;

my $prom = $client.start;

react {
	whenever signal(SIGINT) { $client.stop; exit }
}
