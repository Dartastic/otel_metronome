// Licensed under the Apache License, Version 2.0
// Copyright 2025, Mindful Software LLC, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';

import 'otel_metronome_suppression.dart';

const _tracerName = 'dartastic_otel_libs_metronome';

Tracer _tracer() => OTel.tracerProvider().getTracer(_tracerName);

class MetronomeResult {
  const MetronomeResult({
    this.customerId,
    this.entityKind,
    this.entityId,
    this.contractId,
    this.contractType,
    this.ingestAliasId,
    this.eventType,
    this.transactionId,
    this.eventsAccepted,
    this.eventsRejected,
    this.billableMetricId,
    this.productId,
    this.invoiceId,
    this.invoiceStatus,
    this.totalCents,
    this.creditTypeId,
    this.commitsUsedCents,
    this.statusCode,
  });

  final String? customerId;

  /// `customer` / `contract` / `invoice` / `usage` / `event` /
  /// `billable_metric` / `product` / `rate_card` / `commit` /
  /// `credit` / `audit_log`.
  final String? entityKind;

  final String? entityId;

  final String? contractId;

  /// `prepaid` / `usage` / `commit` / `subscription`.
  final String? contractType;

  /// Metronome aliases let customers ingest under business-friendly
  /// ids (e.g., AWS account id, Auth0 tenant).
  final String? ingestAliasId;

  /// User-defined event type ingested into Metronome.
  final String? eventType;

  /// Idempotency transaction_id.
  final String? transactionId;

  /// Accepted + rejected counts from `events.ingest`.
  final int? eventsAccepted;
  final int? eventsRejected;

  final String? billableMetricId;

  final String? productId;

  final String? invoiceId;

  /// `DRAFT` / `FINALIZED` / `VOIDED`.
  final String? invoiceStatus;

  /// Invoice total in minor units (Metronome surfaces decimal amounts;
  /// we expose minor-unit integer for consistency).
  final int? totalCents;

  /// Credit type id (different from currency — could be a custom
  /// credit type like "tokens" or "compute units").
  final String? creditTypeId;

  /// Commit amount drawn down by this invoice in cents.
  final int? commitsUsedCents;

  final int? statusCode;
}

class MetronomeCallResult<T> {
  const MetronomeCallResult({required this.value, this.result});
  final T value;
  final MetronomeResult? result;
}

/// Wraps a Metronome API call in a CLIENT span. [operation] is one of
/// `events.ingest`, `customers.create`, `customers.list`,
/// `customers.aliases.set`, `contracts.create`, `contracts.list`,
/// `contracts.amend`, `invoices.list`, `invoices.get`,
/// `usage.list`, `billable_metrics.create`, `rate_cards.list`,
/// `credits.list`.
Future<T> tracedMetronome<T>({
  required String operation,
  required Future<MetronomeCallResult<T>> Function() invoke,
}) async {
  if (metronomeInstrumentationSuppressed()) {
    final r = await invoke();
    return r.value;
  }
  final m = <String, Object>{
    'rpc.system': 'metronome',
    'rpc.method': operation,
    'metronome.operation': operation,
  };

  final span = _tracer().startSpan(
    'metronome $operation',
    kind: SpanKind.client,
    attributes: OTel.attributesFromMap(m),
  );
  try {
    final r = await invoke();
    if (r.result != null) {
      final extras = <Attribute<Object>>[];
      if (r.result!.customerId != null) {
        extras.add(OTel.attributeString(
          'metronome.customer.id',
          r.result!.customerId!,
        ));
      }
      if (r.result!.entityKind != null) {
        extras.add(OTel.attributeString(
          'metronome.entity.kind',
          r.result!.entityKind!,
        ));
      }
      if (r.result!.entityId != null) {
        extras.add(OTel.attributeString(
          'metronome.entity.id',
          r.result!.entityId!,
        ));
      }
      if (r.result!.contractId != null) {
        extras.add(OTel.attributeString(
          'metronome.contract.id',
          r.result!.contractId!,
        ));
      }
      if (r.result!.contractType != null) {
        extras.add(OTel.attributeString(
          'metronome.contract.type',
          r.result!.contractType!,
        ));
      }
      if (r.result!.ingestAliasId != null) {
        extras.add(OTel.attributeString(
          'metronome.ingest_alias.id',
          r.result!.ingestAliasId!,
        ));
      }
      if (r.result!.eventType != null) {
        extras.add(OTel.attributeString(
          'metronome.event.type',
          r.result!.eventType!,
        ));
      }
      if (r.result!.transactionId != null) {
        extras.add(OTel.attributeString(
          'metronome.event.transaction_id',
          r.result!.transactionId!,
        ));
      }
      if (r.result!.eventsAccepted != null) {
        extras.add(OTel.attributeInt(
          'metronome.events.accepted',
          r.result!.eventsAccepted!,
        ));
      }
      if (r.result!.eventsRejected != null) {
        extras.add(OTel.attributeInt(
          'metronome.events.rejected',
          r.result!.eventsRejected!,
        ));
        if (r.result!.eventsRejected! > 0 &&
            r.result!.eventsAccepted != null &&
            r.result!.eventsAccepted == 0) {
          span.setStatus(
            SpanStatusCode.Error,
            'Metronome batch all-rejected',
          );
        }
      }
      if (r.result!.billableMetricId != null) {
        extras.add(OTel.attributeString(
          'metronome.billable_metric.id',
          r.result!.billableMetricId!,
        ));
      }
      if (r.result!.productId != null) {
        extras.add(OTel.attributeString(
          'metronome.product.id',
          r.result!.productId!,
        ));
      }
      if (r.result!.invoiceId != null) {
        extras.add(OTel.attributeString(
          'metronome.invoice.id',
          r.result!.invoiceId!,
        ));
      }
      if (r.result!.invoiceStatus != null) {
        extras.add(OTel.attributeString(
          'metronome.invoice.status',
          r.result!.invoiceStatus!,
        ));
      }
      if (r.result!.totalCents != null) {
        extras.add(OTel.attributeInt(
          'metronome.total.cents',
          r.result!.totalCents!,
        ));
      }
      if (r.result!.creditTypeId != null) {
        extras.add(OTel.attributeString(
          'metronome.credit_type.id',
          r.result!.creditTypeId!,
        ));
      }
      if (r.result!.commitsUsedCents != null) {
        extras.add(OTel.attributeInt(
          'metronome.commits.used_cents',
          r.result!.commitsUsedCents!,
        ));
      }
      if (r.result!.statusCode != null) {
        extras.add(OTel.attributeInt(
          'http.response.status_code',
          r.result!.statusCode!,
        ));
        if (r.result!.statusCode! >= 400) {
          span.setStatus(
            SpanStatusCode.Error,
            'Metronome HTTP ${r.result!.statusCode}',
          );
        }
      }
      if (extras.isNotEmpty) span.addAttributes(OTel.attributes(extras));
    }
    return r.value;
  } catch (e, st) {
    span.addAttributes(OTel.attributes([
      OTel.attributeString(
        ErrorResource.errorType.key,
        e.runtimeType.toString(),
      ),
    ]));
    span.recordException(e, stackTrace: st);
    span.setStatus(SpanStatusCode.Error, e.toString());
    rethrow;
  } finally {
    span.end();
  }
}
