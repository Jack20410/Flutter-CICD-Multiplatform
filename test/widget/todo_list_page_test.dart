import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:notes/data/services/todo_api_service.dart';
import 'package:notes/presentation/pages/todo_list_page.dart';
import 'package:notes/presentation/providers/todo_provider.dart';
import 'dart:convert';

// Generate mocks
@GenerateMocks([http.Client])
import 'todo_list_page_test.mocks.dart';

void main() {
  group('TodoListPage Widget Tests', () {
    late MockClient mockClient;
    late TodoApiService todoApiService;
    late TodoProvider todoProvider;

    setUp(() {
      mockClient = MockClient();
      todoApiService = TodoApiService(client: mockClient);
      todoProvider = TodoProvider(apiService: todoApiService);
    });

    testWidgets('displays loading indicator when loading todos',
        (WidgetTester tester) async {
      // Arrange - Create a delayed response
      when(mockClient.get(
        Uri.parse('https://jsonplaceholder.typicode.com/todos'),
        headers: {'Content-Type': 'application/json'},
      )).thenAnswer((_) async {
        await Future.delayed(const Duration(milliseconds: 100));
        return http.Response('[]', 200);
      });

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<TodoProvider>.value(
            value: todoProvider,
            child: const TodoListPage(),
          ),
        ),
      );

      // Give it a frame to show loading
      await tester.pump();

      // The loading should show immediately
      expect(find.byKey(const Key('loading_indicator')), findsOneWidget);

      // Wait for it to finish
      await tester.pumpAndSettle();
    });

    testWidgets('displays empty state when there are no todos',
        (WidgetTester tester) async {
      // Arrange
      when(mockClient.get(
        Uri.parse('https://jsonplaceholder.typicode.com/todos'),
        headers: {'Content-Type': 'application/json'},
      )).thenAnswer((_) async => http.Response('[]', 200));

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<TodoProvider>.value(
            value: todoProvider,
            child: const TodoListPage(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Assert
      expect(find.byKey(const Key('empty_state')), findsOneWidget);
      expect(find.text('No todos yet. Add one!'), findsOneWidget);
    });

    testWidgets('displays correct number of todos in ListView',
        (WidgetTester tester) async {
      // Arrange - Mock data with 3 todos
      final mockResponse = [
        {'id': 1, 'userId': 1, 'title': 'Todo 1', 'completed': false},
        {'id': 2, 'userId': 1, 'title': 'Todo 2', 'completed': true},
        {'id': 3, 'userId': 1, 'title': 'Todo 3', 'completed': false},
      ];

      when(mockClient.get(
        Uri.parse('https://jsonplaceholder.typicode.com/todos'),
        headers: {'Content-Type': 'application/json'},
      )).thenAnswer((_) async => http.Response(
            json.encode(mockResponse),
            200,
          ));

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<TodoProvider>.value(
            value: todoProvider,
            child: const TodoListPage(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Assert - Check ListView is displayed
      expect(find.byKey(const Key('todo_list')), findsOneWidget);

      // Check all 3 todo items are displayed
      expect(find.byKey(const Key('todo_item_0')), findsOneWidget);
      expect(find.byKey(const Key('todo_item_1')), findsOneWidget);
      expect(find.byKey(const Key('todo_item_2')), findsOneWidget);

      // Check todo titles are displayed
      expect(find.text('Todo 1'), findsOneWidget);
      expect(find.text('Todo 2'), findsOneWidget);
      expect(find.text('Todo 3'), findsOneWidget);
    });

    testWidgets('displays error message when API call fails',
        (WidgetTester tester) async {
      // Arrange
      when(mockClient.get(
        Uri.parse('https://jsonplaceholder.typicode.com/todos'),
        headers: {'Content-Type': 'application/json'},
      )).thenAnswer((_) async => http.Response('Server Error', 500));

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<TodoProvider>.value(
            value: todoProvider,
            child: const TodoListPage(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Assert
      expect(find.byKey(const Key('error_text')), findsOneWidget);
      expect(find.byKey(const Key('retry_button')), findsOneWidget);
      expect(
          find.text('Error: Exception: Failed to load todos'), findsOneWidget);
    });

    testWidgets('opens add todo dialog when FAB is tapped',
        (WidgetTester tester) async {
      // Arrange
      when(mockClient.get(
        Uri.parse('https://jsonplaceholder.typicode.com/todos'),
        headers: {'Content-Type': 'application/json'},
      )).thenAnswer((_) async => http.Response('[]', 200));

      // Act
      await tester.pumpWidget(
        ChangeNotifierProvider<TodoProvider>.value(
          value: todoProvider,
          child: const MaterialApp(
            home: TodoListPage(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap the FAB
      await tester.tap(find.byKey(const Key('add_todo_fab')));
      await tester.pumpAndSettle();

      // Assert - Dialog is shown
      expect(find.text('Add New Todo'), findsOneWidget);
      expect(find.byKey(const Key('todo_input_field')), findsOneWidget);
      expect(find.byKey(const Key('cancel_button')), findsOneWidget);
      expect(find.byKey(const Key('add_button')), findsOneWidget);
    });

    testWidgets('can add new todo through dialog', (WidgetTester tester) async {
      // Arrange
      when(mockClient.get(
        Uri.parse('https://jsonplaceholder.typicode.com/todos'),
        headers: {'Content-Type': 'application/json'},
      )).thenAnswer((_) async => http.Response('[]', 200));

      when(mockClient.post(
        Uri.parse('https://jsonplaceholder.typicode.com/todos'),
        headers: {'Content-Type': 'application/json'},
        body: anyNamed('body'),
      )).thenAnswer((_) async => http.Response(
            json.encode({
              'id': 201,
              'userId': 1,
              'title': 'New Test Todo',
              'completed': false,
            }),
            201,
          ));

      // Act - Wrap everything in a single provider for the whole app
      await tester.pumpWidget(
        ChangeNotifierProvider<TodoProvider>.value(
          value: todoProvider,
          child: const MaterialApp(
            home: TodoListPage(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Open dialog
      await tester.tap(find.byKey(const Key('add_todo_fab')));
      await tester.pumpAndSettle();

      // Enter text
      await tester.enterText(
          find.byKey(const Key('todo_input_field')), 'New Test Todo');
      await tester.pumpAndSettle();

      // Tap add button
      await tester.tap(find.byKey(const Key('add_button')));
      await tester.pumpAndSettle();

      // Assert - Dialog is closed
      expect(find.text('Add New Todo'), findsNothing);

      // Assert - New todo is added to the list
      expect(find.text('New Test Todo'), findsOneWidget);
    });

    testWidgets('can toggle todo completion status',
        (WidgetTester tester) async {
      // Arrange
      final mockResponse = [
        {'id': 1, 'userId': 1, 'title': 'Test Todo', 'completed': false},
      ];

      when(mockClient.get(
        Uri.parse('https://jsonplaceholder.typicode.com/todos'),
        headers: {'Content-Type': 'application/json'},
      )).thenAnswer((_) async => http.Response(
            json.encode(mockResponse),
            200,
          ));

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<TodoProvider>.value(
            value: todoProvider,
            child: const TodoListPage(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Get the checkbox
      final checkbox = tester.widget<Checkbox>(
        find.byKey(const Key('checkbox_1')),
      );

      // Assert - Initially unchecked
      expect(checkbox.value, false);

      // Toggle the checkbox
      await tester.tap(find.byKey(const Key('checkbox_1')));
      await tester.pumpAndSettle();

      // Get the updated checkbox
      final updatedCheckbox = tester.widget<Checkbox>(
        find.byKey(const Key('checkbox_1')),
      );

      // Assert - Now checked
      expect(updatedCheckbox.value, true);
    });

    testWidgets('can delete todo', (WidgetTester tester) async {
      // Arrange
      final mockResponse = [
        {'id': 1, 'userId': 1, 'title': 'Todo to Delete', 'completed': false},
      ];

      when(mockClient.get(
        Uri.parse('https://jsonplaceholder.typicode.com/todos'),
        headers: {'Content-Type': 'application/json'},
      )).thenAnswer((_) async => http.Response(
            json.encode(mockResponse),
            200,
          ));

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<TodoProvider>.value(
            value: todoProvider,
            child: const TodoListPage(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Assert - Todo is displayed
      expect(find.text('Todo to Delete'), findsOneWidget);

      // Delete the todo
      await tester.tap(find.byKey(const Key('delete_1')));
      await tester.pumpAndSettle();

      // Assert - Todo is removed and empty state is shown
      expect(find.text('Todo to Delete'), findsNothing);
      expect(find.byKey(const Key('empty_state')), findsOneWidget);
    });

    testWidgets('retry button reloads todos after error',
        (WidgetTester tester) async {
      // Arrange - First call fails
      when(mockClient.get(
        Uri.parse('https://jsonplaceholder.typicode.com/todos'),
        headers: {'Content-Type': 'application/json'},
      )).thenAnswer((_) async => http.Response('Server Error', 500));

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<TodoProvider>.value(
            value: todoProvider,
            child: const TodoListPage(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Assert - Error is displayed
      expect(find.byKey(const Key('error_text')), findsOneWidget);

      // Setup successful response for retry
      when(mockClient.get(
        Uri.parse('https://jsonplaceholder.typicode.com/todos'),
        headers: {'Content-Type': 'application/json'},
      )).thenAnswer((_) async => http.Response(
            json.encode([
              {
                'id': 1,
                'userId': 1,
                'title': 'Retry Success',
                'completed': false
              }
            ]),
            200,
          ));

      // Tap retry button
      await tester.tap(find.byKey(const Key('retry_button')));
      await tester.pumpAndSettle();

      // Assert - Todos are loaded successfully
      expect(find.byKey(const Key('error_text')), findsNothing);
      expect(find.text('Retry Success'), findsOneWidget);
    });

    testWidgets('validates empty input in add todo dialog',
        (WidgetTester tester) async {
      // Arrange
      when(mockClient.get(
        Uri.parse('https://jsonplaceholder.typicode.com/todos'),
        headers: {'Content-Type': 'application/json'},
      )).thenAnswer((_) async => http.Response('[]', 200));

      // Act
      await tester.pumpWidget(
        ChangeNotifierProvider<TodoProvider>.value(
          value: todoProvider,
          child: const MaterialApp(
            home: TodoListPage(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Open dialog
      await tester.tap(find.byKey(const Key('add_todo_fab')));
      await tester.pumpAndSettle();

      // Try to add without entering text
      await tester.tap(find.byKey(const Key('add_button')));
      await tester.pumpAndSettle();

      // Assert - Error message is displayed
      expect(find.text('Please enter a todo title'), findsOneWidget);
      // Dialog should still be open
      expect(find.text('Add New Todo'), findsOneWidget);
    });
  });
}
