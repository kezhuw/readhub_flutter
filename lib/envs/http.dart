import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:http/http.dart';
import 'package:meta/meta.dart';

import 'envs.dart';

class _ProxyClient implements Client {
  factory _ProxyClient({
    @required Client client,
    String baseUrl,
  }) {
    if (baseUrl == null || baseUrl == '') {
      return client;
    }
    if (baseUrl.endsWith('/')) {
      baseUrl = baseUrl.substring(0, baseUrl.length - 1);
    }
    return new _ProxyClient._(client: client, baseUrl: baseUrl);
  }

  _ProxyClient._({this.client, this.baseUrl});

  final Client client;

  final String baseUrl;

  String _mergeUrl(String url) {
    return baseUrl + url;
  }

  @override
  Future<Response> head(url, {Map<String, String> headers}) =>
    client.head(_mergeUrl(url), headers: headers);

  Future<Response> get(url, {Map<String, String> headers}) =>
    client.get(_mergeUrl(url), headers: headers);

  Future<Response> post(url, {Map<String, String> headers, body, Encoding encoding}) =>
    client.post(_mergeUrl(url), headers: headers, body: body, encoding: encoding);

  Future<Response> put(url, {Map<String, String> headers, body, Encoding encoding}) =>
    client.put(_mergeUrl(url), headers: headers, body: body, encoding: encoding);

  Future<Response> patch(url, {Map<String, String> headers, body, Encoding encoding}) =>
    client.patch(_mergeUrl(url), headers: headers, body: body, encoding: encoding);

  Future<Response> delete(url, {Map<String, String> headers}) =>
    client.delete(_mergeUrl(url), headers: headers);

  Future<String> read(url, {Map<String, String> headers}) =>
    client.read(_mergeUrl(url), headers: headers);

  Future<Uint8List> readBytes(url, {Map<String, String> headers}) =>
    client.readBytes(_mergeUrl(url), headers: headers);

  Future<StreamedResponse> send(BaseRequest request) => client.send(request);

  void close() => client.close();
}

Client createApiClient([String profile = "production"]) {
  Client client = createHttpClient();
  Environment env = resolveEnvironment(profile);
  return new _ProxyClient(client: client, baseUrl: env?.apiAddress);
}
