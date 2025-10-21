import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:notes/data/models/todo_model.dart';
import 'package:notes/data/services/todo_api_service.dart';

// Generate mocks
@GenerateMocks([http.Client])
import 'todo_api_service_test.mocks.dart';

void main() {
  group('TodoApiService', () {
    late TodoApiService todoApiService;
    late MockClient mockClient;

    setUp(() {
      mockClient = MockClient();
      todoApiService = TodoApiService(client: mockClient);
    });

    group('getTodos', () {
      test('returns list of todos when API call is successful', () async {
        // Arrange
        final mockResponse = [
          {'id': 1, 'userId': 1, 'title': 'Test Todo 1', 'completed': false},
          {'id': 2, 'userId': 1, 'title': 'Test Todo 2', 'completed': true},
        ];

        when(mockClient.get(
          Uri.parse('https://jsonplaceholder.typicode.com/todos'),
          headers: {'Content-Type': 'application/json'},
        )).thenAnswer((_) async => http.Response(
              json.encode(mockResponse),
              200,
            ));

        // Act
        final result = await todoApiService.getTodos();

        // Assert
        expect(result, isA<List<TodoModel>>());
        expect(result.length, 2);
        expect(result[0].title, 'Test Todo 1');
        expect(result[0].completed, false);
        expect(result[1].title, 'Test Todo 2');
        expect(result[1].completed, true);
      });

      test('throws exception when API call fails', () async {
        // Arrange
        when(mockClient.get(
          Uri.parse('https://jsonplaceholder.typicode.com/todos'),
          headers: {'Content-Type': 'application/json'},
        )).thenAnswer((_) async => http.Response('Not Found', 404));

        // Act & Assert
        expect(
          () async => await todoApiService.getTodos(),
          throwsA(isA<Exception>()),
        );
      });

      test('throws exception when response body is invalid JSON', () async {
        // Arrange
        when(mockClient.get(
          Uri.parse('https://jsonplaceholder.typicode.com/todos'),
          headers: {'Content-Type': 'application/json'},
        )).thenAnswer((_) async => http.Response('Invalid JSON', 200));

        // Act & Assert
        expect(
          () async => await todoApiService.getTodos(),
          throwsA(isA<FormatException>()),
        );
      });
    });

    group('createTodo', () {
      test('returns created todo when API call is successful', () async {
        // Arrange
        const newTodo = TodoModel(
          id: 0,
          userId: 1,
          title: 'New Todo',
          completed: false,
        );

        final expectedResponse = {
          'id': 201,
          'userId': 1,
          'title': 'New Todo',
          'completed': false,
        };

        when(mockClient.post(
          Uri.parse('https://jsonplaceholder.typicode.com/todos'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode(newTodo.toJson()),
        )).thenAnswer((_) async => http.Response(
              json.encode(expectedResponse),
              201,
            ));

        // Act
        final result = await todoApiService.createTodo(newTodo);

        // Assert
        expect(result, isA<TodoModel>());
        expect(result.id, 201);
        expect(result.title, 'New Todo');
        expect(result.completed, false);
      });

      test('throws exception when create API call fails', () async {
        // Arrange
        const newTodo = TodoModel(
          id: 0,
          userId: 1,
          title: 'New Todo',
          completed: false,
        );

        when(mockClient.post(
          Uri.parse('https://jsonplaceholder.typicode.com/todos'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode(newTodo.toJson()),
        )).thenAnswer((_) async => http.Response('Server Error', 500));

        // Act & Assert
        expect(
          () async => await todoApiService.createTodo(newTodo),
          throwsA(isA<Exception>()),
        );
      });
    });
  });
}
