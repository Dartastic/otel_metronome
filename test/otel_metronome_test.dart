// Licensed under the Apache License, Version 2.0
// Copyright 2025, Mindful Software LLC, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';
import 'package:dartastic_opentelemetry/testing.dart';
import 'package:otel_metronome/otel_metronome.dart';
import 'package:test/test.dart';

void main() {
  late TestHarness harness;
  late InMemorySpanExporter spans;

  setUpAll(() async {
    harness = await maybeInitializeOtelForTest(
      serviceName: 'otel_metronome-test',
    );
    spans = harness.spans;
  });

  setUp(() => harness.clear());

  Map<String, Object> attrsOf(Span s) =>
      {for (final a in s.attributes.toList()) a.key: a.value};

  test('events.ingest records alias + event + counts', () async {
    await tracedMetronome<String>(
      operation: 'events.ingest',
      invoke: () async => const MetronomeCallResult(
        value: 'ok',
        result: MetronomeResult(
          ingestAliasId: 'aws-account-1234',
          eventType: 'compute_minutes',
          transactionId: 'txn_abc',
          eventsAccepted: 99,
          eventsRejected: 1,
          statusCode: 200,
        ),
      ),
    );
    final a = attrsOf(spans.findSpanByName('metronome events.ingest')!);
    expect(a['metronome.ingest_alias.id'], 'aws-account-1234');
    expect(a['metronome.event.type'], 'compute_minutes');
    expect(a['metronome.events.accepted'], 99);
    expect(a['metronome.events.rejected'], 1);
  });

  test('contracts.create records type + customer', () async {
    await tracedMetronome<String>(
      operation: 'contracts.create',
      invoke: () async => const MetronomeCallResult(
        value: 'ok',
        result: MetronomeResult(
          customerId: 'cust_1',
          contractId: 'ct_1',
          contractType: 'commit',
          statusCode: 201,
        ),
      ),
    );
    final a = attrsOf(spans.findSpanByName('metronome contracts.create')!);
    expect(a['metronome.customer.id'], 'cust_1');
    expect(a['metronome.contract.type'], 'commit');
  });

  test('invoices.get records status + total + commit drawdown', () async {
    await tracedMetronome<String>(
      operation: 'invoices.get',
      invoke: () async => const MetronomeCallResult(
        value: 'ok',
        result: MetronomeResult(
          invoiceId: 'inv_1',
          invoiceStatus: 'FINALIZED',
          totalCents: 125000,
          creditTypeId: 'usd',
          commitsUsedCents: 75000,
          statusCode: 200,
        ),
      ),
    );
    final a = attrsOf(spans.findSpanByName('metronome invoices.get')!);
    expect(a['metronome.invoice.status'], 'FINALIZED');
    expect(a['metronome.total.cents'], 125000);
    expect(a['metronome.commits.used_cents'], 75000);
  });

  test('all-rejected batch sets span error', () async {
    await tracedMetronome<String>(
      operation: 'events.ingest',
      invoke: () async => const MetronomeCallResult(
        value: 'ok',
        result: MetronomeResult(
          eventsAccepted: 0,
          eventsRejected: 50,
        ),
      ),
    );
    expect(
      spans.findSpanByName('metronome events.ingest')!.status,
      SpanStatusCode.Error,
    );
  });

  test('suppression skips spans', () async {
    await runWithoutMetronomeInstrumentationAsync(() async {
      await tracedMetronome<String>(
        operation: 'usage.list',
        invoke: () async => const MetronomeCallResult(value: 'v'),
      );
    });
    expect(spans.findSpansStartingWith('metronome '), isEmpty);
  });
}
