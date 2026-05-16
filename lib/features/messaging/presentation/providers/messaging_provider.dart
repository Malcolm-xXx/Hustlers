import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/chat_model.dart';

final messagingProvider =
    NotifierProvider<MessagingNotifier, MessagingState>(
        MessagingNotifier.new);

class MessagingState {
  final List<ChatModel> activeChats;
  final List<ChatModel> resolvedChats;
  final Map<String, List<MessageModel>> conversations;
  final bool isResolvedExpanded;
  final bool isLoading;

  const MessagingState({
    this.activeChats = const [],
    this.resolvedChats = const [],
    this.conversations = const {},
    this.isResolvedExpanded = false,
    this.isLoading = false,
  });

  bool get hasChats => activeChats.isNotEmpty || resolvedChats.isNotEmpty;

  MessagingState copyWith({
    List<ChatModel>? activeChats,
    List<ChatModel>? resolvedChats,
    Map<String, List<MessageModel>>? conversations,
    bool? isResolvedExpanded,
    bool? isLoading,
  }) {
    return MessagingState(
      activeChats: activeChats ?? this.activeChats,
      resolvedChats: resolvedChats ?? this.resolvedChats,
      conversations: conversations ?? this.conversations,
      isResolvedExpanded: isResolvedExpanded ?? this.isResolvedExpanded,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class MessagingNotifier extends Notifier<MessagingState> {
  @override
  MessagingState build() => MessagingState(
        activeChats: ChatModel.mockActiveChats,
        resolvedChats: ChatModel.mockResolvedChats,
        conversations: {
          'c1': MessageModel.mockConversation,
        },
      );

  void toggleResolvedSection() {
    state = state.copyWith(
        isResolvedExpanded: !state.isResolvedExpanded);
  }

  void markAllAsRead() {
    state = state.copyWith(
      activeChats: state.activeChats
          .map((c) => c.copyWith(unreadCount: 0))
          .toList(),
    );
  }

  void markAsResolved(String chatId) {
    final chat = state.activeChats.where((c) => c.id == chatId).firstOrNull;
    if (chat == null) return;

    state = state.copyWith(
      activeChats:
          state.activeChats.where((c) => c.id != chatId).toList(),
      resolvedChats: [
        chat.copyWith(isResolved: true, unreadCount: 0),
        ...state.resolvedChats,
      ],
    );
  }

  void sendMessage(String chatId, String text) {
    final conversations =
        Map<String, List<MessageModel>>.from(state.conversations);
    final existing = conversations[chatId] ?? [];
    final newMessage = MessageModel(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      text: text,
      time: _currentTime(),
      isMe: true,
    );
    conversations[chatId] = [...existing, newMessage];

    // Update last message in chat list
    state = state.copyWith(
      conversations: conversations,
      activeChats: state.activeChats
          .map((c) => c.id == chatId
              ? c.copyWith(lastMessage: text, time: _currentTime())
              : c)
          .toList(),
    );
  }

  void clearResolvedHistory() {
    state = state.copyWith(resolvedChats: []);
  }

  List<MessageModel> getMessages(String chatId) {
    return state.conversations[chatId] ?? [];
  }

  ChatModel? getChat(String chatId) {
    final all = [...state.activeChats, ...state.resolvedChats];
    return all.where((c) => c.id == chatId).firstOrNull;
  }

  String _currentTime() {
    final now = DateTime.now();
    return '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
  }
}

// Search provider
final chatSearchProvider =
    NotifierProvider<ChatSearchNotifier, ChatSearchState>(
        ChatSearchNotifier.new);

class ChatSearchState {
  final String query;
  final List<String> recentSearches;
  final List<ChatSearchSuggestion> suggestions;
  final List<ChatSearchResult> results;
  final bool hasSearched;

  const ChatSearchState({
    this.query = '',
    this.recentSearches = const [],
    this.suggestions = const [],
    this.results = const [],
    this.hasSearched = false,
  });

  ChatSearchState copyWith({
    String? query,
    List<String>? recentSearches,
    List<ChatSearchSuggestion>? suggestions,
    List<ChatSearchResult>? results,
    bool? hasSearched,
  }) {
    return ChatSearchState(
      query: query ?? this.query,
      recentSearches: recentSearches ?? this.recentSearches,
      suggestions: suggestions ?? this.suggestions,
      results: results ?? this.results,
      hasSearched: hasSearched ?? this.hasSearched,
    );
  }
}

class ChatSearchNotifier extends Notifier<ChatSearchState> {
  @override
  ChatSearchState build() => ChatSearchState(
        recentSearches: MessageModel.recentSearches,
        suggestions: MessageModel.suggestedChats,
      );

  void updateQuery(String query) {
    state = state.copyWith(query: query, hasSearched: false);
  }

  void search() {
    if (state.query.isEmpty) return;

    final recent = [
      state.query,
      ...state.recentSearches
          .where((s) => s.toLowerCase() != state.query.toLowerCase()),
    ].take(5).toList();

    // Search against live chats from messagingProvider
    final allChats = [
      ...ref.read(messagingProvider).activeChats,
      ...ref.read(messagingProvider).resolvedChats,
    ];
    final q = state.query.toLowerCase();
    final results = allChats
        .where((c) =>
            c.buyerName.toLowerCase().contains(q) ||
            c.orderNumber.toLowerCase().contains(q) ||
            c.lastMessage.toLowerCase().contains(q))
        .map((c) => ChatSearchResult(
              name: c.buyerName,
              orderNumber: c.orderNumber,
              message: c.lastMessage,
              timeAgo: c.time,
            ))
        .toList();

    state = state.copyWith(
      recentSearches: recent,
      results: results,
      hasSearched: true,
    );
  }

  void clearSearch() {
    state = state.copyWith(query: '', hasSearched: false, results: []);
  }

  void clearHistory() {
    state = state.copyWith(recentSearches: []);
  }

  void selectRecentSearch(String search) {
    state = state.copyWith(query: search);
    this.search();
  }
}
