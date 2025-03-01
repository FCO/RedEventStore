#!/usr/bin/env raku

use Nats;
use Nats::Client;
use Nats::Subscriptions;
use RedEventStore::Storage;


sub MAIN(:$driver = "SQLite", *%pars) {
    my RedEventStore::Storage $storage .= new: :$driver, :%pars;

    my $nats = Nats.new;

    my $subscriptions = subscriptions {
        subscribe -> "add_event" {
            my :(:@types, :%data) := message.json;
            my $id = $storage.add-event: :@types, :%data;
            $nats.publish: "new_event", $id;
            message.reply-json: $id
        }
        subscribe -> "get_events" {
            my :(:@types, *%data) := message.json;
            message.reply-json: $storage.get-events: :@types, |%data;
        }
        subscribe -> "get_events", Int() $seq {
            my :(:@types, *%data) := message.json;
            message.reply-json: $storage.get-events: $seq, :@types, |%data;
        }
    }

    my $client = Nats::Client.new: :$nats, :$subscriptions;

    my $prom = $client.start;

    react {
            whenever signal(SIGINT) { $client.stop; exit }
    }
}
